/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __rrg_cmh(
  dataset=,
  where=,
  trtvar=,
  groupvars=,
  var=,
  refvals=,
  subjid=,
  label_pvalga = %str(p-Value),
  label_opvalga = %str(p-Value), 
  label_pvalnc = %str(p-Value),
  label_opvalnc = %str(p-Value),
  label_pvalrmsd = %str(p-Value),
  label_opvalrmsd= %str(p-Value),
  pvalf=__rrgpf.
  )/store;

%*-------------------------------------------------------------------------------
* RRG SUPPLEMENTAL MACRO FOR DISTRIBUTION ON SYSTEMS WITHOUT RRG INSTALLED
* THIS MACRO CALCULATES P-VALUE FROM COCHRAN-MANTEL-HAENSZEL TEST

* PARAMETERS:
*  DATASET         =  input dataset
*  WHERE           =  where clause to apply to input dataset
*  TRTVAR          =  name of treatment variable
*  GROUPVARS       =  names of grouping variables
*  REFVALS         =  the value(s) of treatment variable which are reference 
*                     (for pairwise comp)
*  SUBJID          = name of variabel denoting unique subject id
*  LABEL_PVALGA    = display label for pairwise p-values (for general association)
*  LABEL_OPVALGA   = display label for pairwise p-value (for general association)
*  LABEL_PVALNC    = display label for pairwise p-values (for nonzero correlation)
*  LABEL_OPVALNC   = display label for pairwise p-values (for nonzero correlation)
*  LABEL_PVALRMSD  = display label for pairwise p-values (for row mean score differ)
*  LABEL_OPVALRMSD = display label for pairwise p-values (for row mean score differ)
*  pvalf           = format to display p-values

* DO NOT MODIFY THIS FILE IN ANY WAY

* 
* THIS PROGRAM IS PROVIDED "AS IS," WITHOUT A WARRANTY OF ANY KIND. ALL
* EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, INCLUDING
* ANY IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
* OR NON-INFRINGEMENT, ARE HEREBY EXCLUDED. IZABELLA PESZEK SHALL NOT
* BE LIABLE FOR ANY DAMAGES OR LIABILITIES SUFFERED BY LICENSEE AS A RESULT
* OF OR RELATING TO USE, MODIFICATION OR DISTRIBUTION OF THE SOFTWARE OR ITS
* DERIVATIVES. IN NO EVENT WILL IZABELLA PESZEK BE LIABLE FOR ANY LOST
* REVENUE, PROFIT OR DATA, OR FOR DIRECT, INDIRECT, SPECIAL, CONSEQUENTIAL,
* INCIDENTAL OR PUNITIVE DAMAGES, HOWEVER CAUSED AND REGARDLESS OF THE THEORY
* OF LIABILITY, ARISING OUT OF THE USE OF OR INABILITY TO USE SOFTWARE, EVEN
* IF IZABELLA PESZEK HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
 

%*-------------------------------------------------------------------------------;
%local dataset where trtvar groupvars  var  refvals subjid 
       label_pvalga label_opvalga pvalf
       label_pvalnc label_opvalnc label_pvalrmsd label_opvalrmsd;
       
%if %length(&where)=0  %then %let where=%str(1=1);

%if %length(&groupvars) %then %do;   
  proc sort data=&dataset(where=(&where )) 
    out=__f0 (keep = &groupvars ) nodupkey;
  by &groupvars ;
  run;

data __f0;
  set __f0;
  length althypothesis $ 22;
  althypothesis='Nonzero Correlation'; output;
  althypothesis='Row Mean Scores Differ'; output;
  althypothesis='General Association' ; output;
run;

%end;

data rrg_cmh;
  if 0;
run;


*** OVERALL P-VALUE;

%if %length(&groupvars) %then %do;
  proc sort data=&dataset (where=(&where)) out=__fishtmp;
    by &groupvars;
  run;
  
  data __cmh;
    if 0;
  run;
  
  ods output close;
  ods output cmh=__cmh;
  
  proc freq data=__fishtmp order=internal;
  by &groupvars;
  tables &trtvar*&var./cmh ;
  run;

%end;

%else %do;
  
  data __cmh;
    if 0;
  run;
  
  ods output close;
  ods output cmh=__cmh;
  
  proc freq data=&dataset (where=(&where)) order=internal;
  tables &trtvar*&var./cmh ;
  run;

%end;

%if %length(&groupvars) %then %do;
  proc sort data=__cmh;
    by &groupvars althypothesis;
  run;
  
  proc sort data=__f0;
    by &groupvars althypothesis;
  run;

  data __cmh;
    merge __cmh __f0;
    by &groupvars althypothesis;
  run;

%end;

data rrg_cmh;
  set __cmh;
  
  length __stat_name __stat_label __stat_value __stat_align $ 200;
  __overall=1;
  __stat_order=1;
  __stat_align = 'D';
  
  if prob ne . then __stat_value = put(prob, &pvalf.);
  else __stat_value ='N/E';
    
  if upcase(althypothesis)='NONZERO CORRELATION' then do;
    __stat_name = 'OPVALNC';
    __stat_label = trim(left(symget('label_opvalnc')));
    output;
  end;  
  else if upcase(althypothesis)='ROW MEAN SCORES DIFFER' then do;
     __stat_name = 'OPVALRMSD';
     __stat_label = trim(left(symget('label_opvalrmsd')));
     output;
     
  end;     
  if upcase(althypothesis)='GENERAL ASSOCIATION' then do;
     __stat_name = 'OPVALGA';
     __stat_label = trim(left(symget('label_opvalga')));
     output;
  end;     


  
keep __overall __stat_value __stat_order __stat_name __stat_label __stat_align 
     &groupvars ;
run;


 proc sort data=__pop(where=(__grouped ne 1)) 
      out=__trts (keep=&trtvar)
      nodupkey;
      by &trtvar __dec_&trtvar __trtid;
run;

data __trts0;
  set __trts;
  if _n_=1;
run;

data  rrg_cmh;
  set rrg_cmh;
  if _n_=1 then set __trts0;
run;
   

*** PAIRWISE P-VALUES;

%local i j ntrts nrefs;

%if %length(&refvals)>0 %then %do;

   proc sort data=__pop(where=(__grouped ne 1)) 
        out=__trts (keep=&trtvar __dec_&trtvar __trtid)
      nodupkey;
      by &trtvar __dec_&trtvar __trtid;
    run;

   proc sql noprint;
      select count(*) into:ntrts separated by ' ' from __trts;
      select count(*) into:nrefs separated by ' ' from __trts
      %if %length(&refvals) %then %do;
      (where =(&trtvar in (&refvals))) 
      %end;;
   quit;
   
   %do i=1 %to &ntrts;
   %local trt&i ;
   %end;

   %do i=1 %to &nrefs;
   %local ref&i ;
   %end;

   
  data __trts;
    set __trts;
    __id=_n_;
    call symput(cats("trt", __id), cats(__trtid));
  run;
  
 %if %length(&refvals) %then %do;
  data __refs;
    set __trts;
      if &trtvar in (&refvals);
  run;
  
  data __refs;
    set __refs;
    __id=_n_;
    call symput(cats("ref", __id), cats(__trtid));
  run;
  %end;

  %do i=1 %to &ntrts;
    %do j=1 %to &nrefs;
      %if &&trt&i ne &&ref&j %then %do;


      data __fishtmp;
        set &dataset (where=(&where));
        if __trtid in (&&trt&i, &&ref&j) and not missing(&var);
      run;

      %if %length(&groupvars) %then %do;
      proc sort data=__fishtmp;
        by &groupvars;
      run;
      %end;

      data __cmh;
        if 0;
      run;

      ods output close;
      ods output cmh=__cmh;


      proc freq data=__fishtmp order=internal;
      %if %length(&groupvars) %then %do;
      by &groupvars;
      %end;
      tables &trtvar*&var./cmh;
      run;

      %if %length(&groupvars) %then %do;
        proc sort data=__cmh;
          by &groupvars althypothesis;
        run;
        
        proc sort data=__f0;
          by &groupvars althypothesis;
        run;
      
        data __cmh;
          merge __cmh __f0;
          by &groupvars althypothesis;
        run;
      
      %end;     

      data __cmh;
        set __cmh;
        if _n_=1 then set __trts(keep=__trtid &trtvar where=(__trtid=&&trt&i));
      run;

      data __cmh;
        set __cmh;
        if _n_=1 then set __trts(
          keep=__trtid __dec_&trtvar
          where=(__trtid=&&ref&j));
      
      length __stat_name __stat_label __stat_value __stat_align $ 200;
      
      __stat_order=&&ref&j;
      __stat_align = 'D';
      if prob ne . then __stat_value = put(prob, &pvalf.);
      else __stat_value ='N/E';
      __overall=0;

    if upcase(althypothesis)='NONZERO CORRELATION' then do;
    __stat_name = 'PVALNC';
    __stat_label = trim(left(symget('label_pvalnc')))||' vs '||cats(__dec_&trtvar);;
    output;
  end;  
  else if upcase(althypothesis)='ROW MEAN SCORES DIFFER' then do;
     __stat_name = 'PVALRMSD';
     __stat_label = trim(left(symget('label_pvalrmsd')))||' vs '||cats(__dec_&trtvar);;
     output;
  end;     
  if upcase(althypothesis)='GENERAL ASSOCIATION' then do;
     __stat_name = 'PVALGA';
     __stat_label = trim(left(symget('label_pvalga')))||' vs '||cats(__dec_&trtvar);;
     output;
  end;     


            
      keep __overall __stat_value __stat_order __stat_name __stat_label __stat_align 
           &groupvars &trtvar;
      run;
      
      data rrg_cmh;
        set rrg_cmh __cmh;
      run;
    %end;

    %end;  
  
  %end;

%end;



%mend;
