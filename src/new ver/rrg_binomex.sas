/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */



%macro rrg_binomex(
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
  label_pctci=%str(CI for PCT),
  label_exact=N
  )/store;

%*-------------------------------------------------------------------------------
* RRG SUPPLEMENTAL MACRO FOR DISTRIBUTION ON SYSTEMS WITHOUT RRG INSTALLED
* THIS MACRO CALCULATES CI FOR BINOMIAL PROPORTION AND FOR DIFFERENCE BETWEEN
*   BINOMIAL PROPORTIONS, USING EXACT BINOMAL METHOD

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
*  LABEL_PCTCI     = display label for CI for percentages 

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


%local   dataset where cntds   trtvar  pageby groupvars   var   refvals 
    subjid alpha maxtrt pctfmt events label_pctci Label_pctdiff
    label_pctdiffci label_exact CONTCORR whereafter
    ;
%if %length(&where)=0  %then %let where=%str(1=1);


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

data __rrg_binom_EX;
  set __bincntds (where=(&where));
  array cnt{*} __cnt_1-__cnt_&maxtrt;  
  array den{*} __den_1-__den_&maxtrt;    
  
  do __i=1 to &maxtrt;
    __trtid=__i;
    __val=1;
    __wt = cnt[__i];
    output;
    __trtid=__i;
    __val=2;
    __wt = den[__i]-cnt[__i];
    output;
  end;
  keep &groupvars __trtid __val __wt;
run;  

proc sort data=__rrg_binom_EX;
  by &groupvars __trtid;
run;


ods output close;
ods output binomialProp=__rrg_binom_exci;

proc freq data=__rrg_binom_EX ;
by &groupvars __trtid;
tables __val/binomial alpha=&alpha;
weight __wt/zeros;
run;


data __rrg_binom_exci;
set __rrg_binom_exci;
if upcase(name1) in ('XL_BIN', 'XU_BIN');
keep &groupvars __trtid name1 nvalue1;
run;



proc sort data=__rrg_binom_exci;
by &groupvars __trtid;
run;

proc transpose data=__rrg_binom_exci out=__rrg_binom_exci ;
by &groupvars __trtid;
var nvalue1;
id name1;
run;



data __rrg_binom_exci;
set __rrg_binom_exci;
length __stat_value __stat_name __stat_label __stat_align $ 200;
xl_bin=100*xl_bin;
xu_bin=100*xu_bin;
__stat_value = "("||strip(put(xl_bin, &pctfmt.))||", "||strip(put(xu_bin, &pctfmt.))||")";
__overall=0;
__stat_order=0;
__stat_name='EXCIPCT';
alpha0 = 100*(1-&alpha);
   %if %upcase(&label_exact)=N %then %do;
    __stat_label = cats(alpha0,'%')||' '||trim(left(symget("label_pctci")));
    *__stat_label = tranwrd(__stat_label,'_ALPHA_', strip(put(alpha0, best.)));
    %end;
    %else %do;
    __stat_label = trim(left(symget("label_pctci")));
    %end;
__stat_align='C';
keep __overall __stat_value __stat_order __stat_name __stat_label __stat_align 
     &groupvars __trtid;

proc sort data=__rrg_binom_exci;
  by __trtid;
run;

data __rrg_binom_exci;
  merge __rrg_binom_exci __trt0 (keep=__trtid &trtvar);
  by __trtid;
  drop __trtid;
run;

 proc print data=__rrg_binom_exci;
  run; 
  
data rrg_binomex;
   set __rrg_binom_exci;
   output;
   __stat_name = cats("//", __stat_name);
   __stat_label = cats("//", __stat_label);
   output;
run;


data rrg_binomex;
   set rrg_binomex;
   output;
   __overall=1;
   __stat_name = strip(__stat_name);
   output;
  run;

%IF %LENGTH(&WHEREAFTER) %then %do;

 data rrg_binomex;
  set rrg_binomex;
  where &whereafter;
run;

%end;
   
 
%mend;
