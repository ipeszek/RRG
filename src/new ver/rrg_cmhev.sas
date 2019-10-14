/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro rrg_cmhEv(
  dataset=,
  where=,
  trtvar=,
  groupvars=,
  pageby = ,
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
*  PAGEBY          =  names of grouping "pageby" variables 
*                     (defining population pools)
*  VAR             =  name of analysis variable
*  REFVALS         =  the value(s) of analysis variables which are reference 
*                     (for pairwise comp)
*  SUBJID          = name of variabel denoting unique subject id
*  LABEL_PVALGA    = display label for pairwise p-values (for general association)
*  LABEL_OPVALGA   = display label for pairwise p-value (for general association)
*  LABEL_PVALNC    = display label for pairwise p-values (for nonzero correlation)
*  LABEL_OPVALNC   = display label for pairwise p-values (for nonzero correlation)
*  LABEL_PVALRMSD  = display label for pairwise p-values (for row mean score differ)
*  LABEL_OPVALRMSD = display label for pairwise p-values (for row mean score differ)
*  PVALF           = format to display p-values

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

%local dataset where trtvar groupvars pageby var  refvals subjid 
       label_pvalga label_opvalga pvalf
       label_pvalnc label_opvalnc label_pvalrmsd label_opvalrmsd;

%if %length(&where)=0  %then %let where=%str(1=1);

proc sort data=__bincntds(where=(&where))
     out=__f0 (keep = &pageby &groupvars &var __grpid) nodupkey;
  by &pageby &groupvars __grpid &var;
run;

data rrg_cmhev;
  if 0;
run;


*** OVERALL P-VALUE;


proc sort data=__pop(where=(__grouped=0)) nodupkey out=__trt0;
  by __trtid;
run;

proc sql noprint;
  select max(__trtid) into:maxtrt separated by ''
  from __trt0;
run;

data __fishtmp0;
  set __bincntds (where=(&where));
  array cnt{*} __cnt_1-__cnt_&maxtrt;  
  array den{*} __den_1-__den_&maxtrt;  

  __out=1;
  do __i=1 to dim(cnt);
     __out=1;
     __wt = cnt[__i];
     __trtid = __i;
     output;
     __out=0;
     __wt = den[__i]-cnt[__i];
     __trtid = __i;
     output;
  end;
  keep __grpid &pageby &groupvars &var __wt __out __trtid;
run;

proc sort data=__fishtmp0 ;
  by __trtid;
run;

data __fishtmp0;
  merge __fishtmp0 __trt0 (in=__a keep=__trtid &trtvar);
  by __trtid;
  if __a;
run;

proc sort data=__fishtmp0 ;
    by __grpid &pageby &groupvars &var;
run;


data __cmh;
  if 0;
run;

ods output close;
ods output cmh=__cmh;


proc freq data=__fishtmp0 order=internal;
  by __grpid &pageby &groupvars &var;
weight __wt;
tables __trtid*__out/cmh;
run;

data __f0;
  set __f0;
  length althypothesis $ 22;
  althypothesis='Nonzero Correlation'; output;
  althypothesis='Row Mean Scores Differ'; output;
  althypothesis='General Association' ; output;
run;

proc sort data=__f0;
  by &pageby &groupvars __grpid &var althypothesis;
run;


  
proc sort data=__cmh;
  by &pageby &groupvars __grpid &var althypothesis;
run;

data __cmh;
    merge __cmh __f0;
    by &pageby &groupvars __grpid &var althypothesis;
run;  


data rrg_cmhev;
set __cmh;

length __stat_name __stat_label __stat_value __stat_align $ 200;
__overall=1;
__stat_order=1;
__stat_label = 'p-Value';
__stat_align = 'D';
if prob ne . then __stat_value = put(prob, &pvalf.);
else __stat_value ='N/E';

__stat_name = 'OPVAL';

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
     &pageby &groupvars __grpid &var;
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

data  rrg_cmhev;;
  set rrg_cmhev;
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
        set __fishtmp0;
        if __trtid in (&&trt&i, &&ref&j);
       run;
       
       proc sort data=__fishtmp;
         by &pageby &groupvars __grpid &var;
       run;

      data __cmh;
        if 0;
      run;

      ods output close;
      ods output cmh=__cmh;


        proc freq data=__fishtmp order=internal;
          by &pageby &groupvars __grpid &var;

         weight __wt;
         tables __trtid*__out/cmh;
       run;
      
        proc sort data=__cmh;
          by &pageby &groupvars __grpid &var althypothesis;
        run;
        
        data __cmh;
            merge __cmh __f0;
            by &pageby &groupvars __grpid &var althypothesis;
        run;  
      
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

        keep __overall __stat_value __stat_order __stat_name 
             __stat_label __stat_align 
             &pageby &groupvars &trtvar __grpid &var;
       run;
      
       data rrg_cmhev;
        set rrg_cmhev __cmh;
       run;
    %end;

    %end;  
  
  %end;

 

%end;
    
  data rrg_cmhev;
   set rrg_cmhev;
   output;
   __stat_name = cats("//", __stat_name);
   __stat_label = cats("//", __stat_label);
   output;
  run;

%mend;
