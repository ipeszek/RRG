/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro rrg_chiEv(
  dataset=,
  where=,
  trtvar=,
  groupvars=,
  pageby = ,
  var=,
  refvals=,
  subjid=,
  label_pval=%str(p-Value),
  label_opval=%str(p-Value),
  pvalf=__rrgpf.
  )/store;

%*-------------------------------------------------------------------------------
* RRG SUPPLEMENTAL MACRO FOR DISTRIBUTION ON SYSTEMS WITHOUT RRG INSTALLED
* THIS MACRO CALCULATES P-VALUE FROM CHI-SQUARE DISTRIBUTION

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
*  LABEL_PVAL      = display label for pairwise p-values
*  LABEL_OPVAL     = display label for pairwise p-value
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
%local dataset where  trtvar groupvars pageby var  refvals subjid label_pval 
       label_opval pvalf;


%if %length(&where)=0  %then %let where=%str(1=1);

data rrg_chiev;
  if 0;
run;

proc sort data=__bincntds(where=(&where))
     out=__f0 (keep = &pageby &groupvars &var __grpid) nodupkey;
  by &pageby &groupvars __grpid &var;
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


data __chisq;
  if 0;
  statistic='';
run;

ods output close;
ods output chisq=__chisq;



proc freq data=__fishtmp0 ;
  by __grpid &pageby &groupvars &var;
weight __wt;
tables __trtid*__out/chisq;
run;

data rrg_chiev;
set __chisq;
if upcase(statistic)='CHI-SQUARE';
run;

proc sort data=rrg_chiev;
  by &pageby &groupvars __grpid &var ;
run;

data rrg_chiev;
    merge rrg_chiev __f0;
    by &pageby &groupvars __grpid &var;
run;  

data rrg_chiev;
  set rrg_chiev;
length __stat_name __stat_label __stat_value __stat_align $ 200;
__stat_order=1;
__stat_name = 'OPVAL';
__stat_label = trim(left(symget('label_opval')));
__stat_align = 'D';
if prob ne . then __stat_value = put(prob, &pvalf.);
else __stat_value ='N/E';
__overall=1;

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

data  rrg_chiev;;
  set rrg_chiev;
  if _n_=1 then set __trts0;
run;

*** PAIRWISE P-VALUES;

%local i j ntrts nrefs;
%let nrefs=0;
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

      data __chisq;
        if 0;
        statistic='';
      run;

      ods output close;
      ods output chisq=__chisq;

        proc freq data=__fishtmp ;
          by &pageby &groupvars __grpid &var;

         weight __wt;
         tables __trtid*__out/chisq;
       run;
      
       data __chi;
        set __chisq;
        if upcase(statistic)='CHI-SQUARE';
       run;
       
        proc sort data=__chi;
          by &pageby &groupvars __grpid &var ;
        run;
        
        data __chi;
            merge __chi __f0;
            by &pageby &groupvars __grpid &var;
        run;  
        
       data __chi;
        set __chi;
        if _n_=1 then set __trts(keep=__trtid &trtvar where=(__trtid=&&trt&i));
       run;

       data __chi;
        set __chi;
        if _n_=1 then set __trts(
          keep=__trtid __dec_&trtvar
          where=(__trtid=&&ref&j));
      
       length __stat_name __stat_label __stat_value __stat_align $ 200;
      
        __stat_order=&&ref&j;
        __stat_name = 'PVAL';
        __stat_label = trim(left(symget('label_pval')))||' vs '||cats(__dec_&trtvar);
        __stat_align = 'D';
        if prob ne . then __stat_value = put(prob, &pvalf.);
        else __stat_value ='N/E';
        __overall=0;
        
        keep __overall __stat_value __stat_order __stat_name 
             __stat_label __stat_align 
             &pageby &groupvars &trtvar __grpid &var;
       run;
      
       data rrg_chiev;
        set rrg_chiev __chi;
       run;
    %end;

    %end;  
  
  %end;

 

%end;
    
  data rrg_chiev;
   set rrg_chiev;
   output;
   __stat_name = cats("//", __stat_name);
   __stat_label = cats("//", __stat_label);
   output;
  run;

%mend;
