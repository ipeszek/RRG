/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro rrg_binom(
  dataset=,
  where=,
  whereafter=,
  cntds=,
  trtvar=,
  groupvars=,
  pageby=,
  var=,
  refvals=,
  alpha=0.05,
  pctfmt=6.1,
  subjid=,
  contcorr=y,
  label_pctci=%str(_ALPHA_% CI for PCT),
  Label_pctdiff=%str(Pct Difference vs _VS_),
  label_pctdiffci=%str(_ALPHA_% CI for Pct Diff vs _VS_),
  label_exact=n,
  print_stats=n
  )/store;

%*-------------------------------------------------------------------------------
* RRG SUPPLEMENTAL MACRO FOR DISTRIBUTION ON SYSTEMS WITHOUT RRG INSTALLED
* THIS MACRO CALCULATES CI FOR BINOMIAL PROPORTION AND FOR DIFFERENCE BETWEEN
*   BINOMIAL PROPORTIONS, BASEDON GREENWOOD FORMULA WITH CONTINUITY CORRECTION 

* PARAMETERS:
*  DATASET         =  input dataset
*  WHERE           =  where clause to apply to input dataset
*  WHEREAFTER      =  WHERE clause to apply to OUTPUT dataset
*  CNTDS           =  dataset with pre-calculated counts/percentages
*  TRTVAR          =  name of treatment variable
*  GROUPVARS       =  names of grouping variables
*  PAGEBY          =  names of grouping "pageby" variables 
*                     (defining population pools)
*  VAR             =  name of analysis variable
*  REFVALS         =  the value(s) of analysis variables which are reference 
*                     (for pairwise comp)
*  ALPHA           = alpha-level for CI
*  PCTFMT          = format to display CI for percentages
*  SUBJID          = name of variabel denoting unique subject id
*  CONTCORR        = if no, continuity correction is not applied for CI
*  LABEL_PCTCI     = display label for CI for percentages 
*  LABEL_PCTDIFF   = display label for difference between percentages 
*  LABEL_PCTDIFFCI = display label for CI for difference between percentages 
*  LABEL_EXACT     = if Y, labels are printed exactly as specified
*  PRINT_STATS     = if y, list of available statistics is printed

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
%* this macro is for binomial variable;  
%* CI for PCT (PCTCI);
%* diff between pct (PCTDIFF);  
%* CI for diff between pct (PCTDIFFCI);
%* Diff and CI for diff between percent (DIFF+PCTDIFFCI)


%local   dataset where cntds   trtvar  pageby groupvars   var   refvals 
    subjid alpha maxtrt pctfmt events label_pctci Label_pctdiff
    label_pctdiffci label_exact CONTCORR whereafter
    ;
%if %length(&where)=0  %then %let where=%str(1=1);
%if %upcase(&contcorr) ne N %then %let contcorr=Y;

%if %sysfunc(countw(&trtvar, %str( )))>1 %then %do;
   %put;
   %PUT &WAR.&NING.: RRG_BINOM MACRO DOES NOT SUPPORT MULTIPLE TREATMENT VARIABLES;
   %PUT ----------   REQUESTED MODEL WAS THEREFORE IGNORED;
   %put;
%end;
   
%if %length(&groupvars) %then %do;   
  proc sort data=__bincntds
     out=__f0 (keep = &groupvars ) nodupkey;
  by &groupvars ;
  run;
%end;

%* we use precalculated cnt and pct;
%* instead of original &dataset;
proc sort data=__pop nodupkey out=__trt0;
  by __trtid;
run;

proc sql noprint;
  select max(__trtid) into:maxtrt separated by ''
  from __trt0;
run;


data __rrg_binom;
  set __bincntds (where=(&where));
  length __stat_align __stat_name __stat_label __stat_value __tmp1 __tmp2 $ 2000;
  array cnt{*} __cnt_1-__cnt_&maxtrt;  
  array pct{*} __pct_1-__pct_&maxtrt;    
  array den{*} __den_1-__den_&maxtrt;    
  alpha0 = 100*(1-&alpha);
    __stat_order=0;
    %if %upcase(&label_exact)=N %then %do;
    
    __stat_label = cats(alpha0,'%')||' '||trim(left(symget("label_pctci")));
    __stat_label = trim(left(symget("label_pctci")));
    __stat_label = tranwrd(__stat_label,'_ALPHA_', strip(put(alpha0, best.)));
    *__stat_label = tranwrd(__stat_label,'_VS_', cats(__dec_&trtvar));
    
    
    
    %end;
    %else %do;
    __stat_label = trim(left(symget("label_pctci")));
    %end;
    __stat_name = 'PCTCI';
    __stat_align='C';
    __overall=0;

do __j=1 to dim(cnt);
  if den[__j]>0 then do;
    __trtid=__j;
     __se=sqrt((cnt[__j]/den[__j])*(1-cnt[__j]/den[__j])/den[__j]);
    %if &contcorr=Y %then %do;
    __contcorr=0.5*(1/den[__j]);
    %end;
    %else %do;
    __contcorr=0;
    %end;
    __lower = max(0, pct[__j]-100*(__se*probit(1-&alpha/2)+__contcorr));
    __upper = min(100, pct[__j]+100*(__se*probit(1-&alpha/2)+__contcorr));
    __tmp1 = cats(put(__lower, &pctfmt.));
    __tmp2 = cats(put(__upper, &pctfmt.));
    if compress(__tmp1,'-0.')='' then __tmp1 = tranwrd(__tmp1, '-',''); 
    if compress(__tmp2,'-0.')='' then __tmp2 = tranwrd(__tmp2, '-','');
     __stat_value = cats('(',__tmp1)||', '||cats(__tmp2,')');
    output;
  end;  
end;

keep __overall __stat_name __stat_label __stat_align __stat_value 
       &pageby &groupvars __trtid __stat_order &var 
      %if %length(&var)   %then %do; __grpid %end;;
run;
%* todo: CI if denominator is 0:N/A;
proc sort data=__rrg_binom;
  by __trtid;
run;

data __rrg_binom;
  merge __rrg_binom __trt0 (keep=__trtid &trtvar);
  by __trtid;
  drop __trtid;
run;

data rrg_binom;
  set __bincntds (where=(&where));
  
  array cnt{*} __cnt_1-__cnt_&maxtrt;  
  array pct{*} __pct_1-__pct_&maxtrt;    
  array den{*} __den_1-__den_&maxtrt;    
    
do __j=1 to dim(cnt);
  do __i=1 to dim(cnt);
    if __i ne __j and den[__j]>0 and den[__i]>0 then do;
      __trtid=__j;
      __refid = __i;  
      __diff=100*(cnt[__j]/den[__j]-cnt[__i]/den[__i]);
      __se=sqrt((cnt[__j]/den[__j])*(1-cnt[__j]/den[__j])/den[__j]
                    +(cnt[__i]/den[__i])*(1-cnt[__i]/den[__i])/den[__i]);
    %if &contcorr=Y %then %do;
    __contcorr=0.5*(1/den[__j]+1/den[__i]);
    %end;
    %else %do;
    __contcorr=0;
    %end;                    
      
      __lower = __diff-100*(__se*probit(1-&alpha/2)+__contcorr);
      __upper = __diff+100*(__se*probit(1-&alpha/2)+__contcorr);
    output;
  end;
  end;
end;
keep __trtid __refid __diff __lower __upper &pageby &groupvars &var 
%if %length(&var)   %then %do;__grpid %end;;
run; 
  

proc sort data=rrg_binom;
  by __trtid;
run;

data rrg_binom;
  merge rrg_binom(in=__b) __trt0(in=__a keep=__trtid &trtvar) ;
  by __trtid;
  if __a and __b;
run; 

proc sort data=rrg_binom;
  by __refid;
run;

data rrg_binom;
  merge rrg_binom(in=__b) __trt0( in=__a 
      keep=__trtid &trtvar __dec_&trtvar rename =(__trtid=__refid &trtvar=__refval));
    by __refid;
    if __a and __b;
    %if %length(&refvals) %then %do;
      if __refval not in (&refvals) then delete; 
    %end;
run;

proc sort data=rrg_binom;
  by __refval;
run;

data rrg_binom;
  length __stat_align __stat_name __stat_label __stat_value __tmp1 __tmp2 __tmp3 $ 2000;
  set rrg_binom;
  by __refval;
  __overall=0;
  __stat_order=0;
  retain __refvalid;
  if _n_=1 then __refvalid=0;
  %if %length(&refvals) %then %do;
  if first.__refval then __refvalid+1;
  %end;
  %else %do;
  __stat_order=__refid;
  %end;
  __stat_align='D';
  
      
    
  %if %upcase(&label_exact)=N %then %do;    
  *__stat_label =trim(left(symget("Label_pctdiff")))||' vs '||cats(__dec_&trtvar);;
  __stat_label = trim(left(symget("label_pctdiff")));
  __stat_label = tranwrd(__stat_label,'_ALPHA_', strip(put(alpha0, best.)));
  __stat_label = tranwrd(__stat_label,'_VS_', cats(__dec_&trtvar));
  
  %end;
  %else %do;
  __stat_label =trim(left(symget("Label_pctdiff")));
  %end;
  __stat_name = 'PCTDIFF';
  __stat_value = cats(put(__diff, &pctfmt.));
  if compress(__stat_value,'-0. ') ='' then __stat_value=tranwrd(__stat_value,'-',''); 
  __tmp3 = __stat_value;
  output;

  __stat_align='C';
  __stat_name = 'PCTDIFFCI';
  alpha0=100*(1-&alpha);
  %if %upcase(&label_exact)=N %then %do;    
  *__stat_label = cats(alpha0,'%')||" "||trim(left(symget("label_pctdiffci")))||" vs "||cats(__dec_&trtvar);
  __stat_label = trim(left(symget("label_pctdiffci")));
  __stat_label = tranwrd(__stat_label,'_ALPHA_', strip(put(alpha0, best.)));
  __stat_label = tranwrd(__stat_label,'_VS_', cats(__dec_&trtvar));
  %end;
  %else %do;
  __stat_label = trim(left(symget("label_pctdiffci")));
  %end;
    __tmp1 = cats(put(__lower, &pctfmt.));
    __tmp2 = cats(put(__upper, &pctfmt.));
    if compress(__tmp1,'-0.')='' then __tmp1 = tranwrd(__tmp1, '-',''); 
    if compress(__tmp2,'-0.')='' then __tmp2 = tranwrd(__tmp2, '-','');
     __stat_value = cats('(',__tmp1)||', '||cats(__tmp2,')');
    
  output;
    __stat_align='C';
    __stat_name = 'DIFF+PCTDIFFCI';
    __stat_value = trim(__tmp3)||' '||trim(__stat_value);
    
    output;
  

  keep __overall __stat_name __stat_label __stat_align __stat_value 
       &pageby &groupvars &trtvar __stat_order  &var __refvalid
       %if %length(&var)   %then %do; __grpid %end;;
run;

data rrg_binom;
  set rrg_binom __rrg_binom;
  __reforder=__refvalid;
  if __reforder=. then __reforder=0;
run; 

data rrg_binom;
   set rrg_binom;
   output;
   __stat_name = cats("//", __stat_name);
   __stat_label = cats("//", __stat_label);
   output;
run;


data rrg_binom;
   set rrg_binom;
   output;
   __overall=1;
   __stat_name = strip(__stat_name)||"_"||strip(put(__reforder,best.));
   output;
  run;

%IF %LENGTH(&WHEREAFTER) %then %do;

 data rrg_binom;;
  set rrg_binom;
  where &whereafter;
run;

%end;
   
%if %upcase(&print_stats)=Y %then %do;   
  title 'The following statistics are available from rrg_binom:';
  
  proc sql;
    select distinct __overall, __stat_name, __stat_label from rrg_binom;
    quit;
  title;   

%end;

%mend;
