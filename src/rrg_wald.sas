%macro rrg_wald(
  dataset=,
  where=,
  trtvar=,
  groupvars=,
  refvals=,
  subjid=,
  label = %str(_ALPHA_% CI for Percent Difference),
  pctfmt=6.1

  )/store;

%*-------------------------------------------------------------------------------

* PARAMETERS:
*  DATASET         =  input dataset
*  WHERE           =  where clause to apply to input dataset
*  TRTVAR          =  name of treatment variable
*  GROUPVARS       =  names of grouping variables
*  REFVALS         =  the value(s) of treatment variable(s) which is reference 
*                     (for pairwise comp)
*  SUBJID          = name of variable denoting unique subject id
*  LABEL_          = label for differnce in percentages
*  pctfmt          = format to display percentages


%*-------------------------------------------------------------------------------;

%local dataset where trtvar groupvars    refvals subjid 
       label pctfmt;
       
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


%* -------------------------------------------------;
%* we use precalculated cnt and pct;
%* instead of original &dataset;
%* -------------------------------------------------;


proc sort data=__pop nodupkey out=__trt0;
  by __trtid;
run;

proc sql noprint;
  select max(__trtid) into:maxtrt separated by ''
  from __trt0;
run;


data __rrg_wald;
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

proc sort data=__rrg_wald;
  by &groupvars __trtid;
run;

 data rrg_wald;
  if 0;
run;
  
  ods output close;
  ods output riskdiffcol1=rrg_wald;
  
  
  
  proc freq data=__for_wald order=internal alpha=&alpha;
  %if %length(&groupvars) %then %do;   
  by &groupvars;
  %end;
  tables __trtid*__condok/riskdiff(cl=wald) ;
  weight __wt/zeros;
  run;


proc print data=rrg_wald;
  title 'wald from proc freq';
run;

data rrg_wald;
  set rrg_wald;
  where row='Difference';
  
  length __stat_name __stat_label __stat_value __stat_align $ 200;
  __overall=0;
  __stat_order=1;
  
  __stat_name="DIFFCI";
  __stat_label=symget("label");
  __stat_align='C';
  
  length  riskc lowerclc upperclc $ 10;
  array vals risk lowercl uppercl;
  array valsc riskc lowerclc upperclc;

  do over vals;
    if missing(vals) then valc='NE';
    else do;
      vals=round(100*vals, 0.0001);
      valsc=strip(put(vals, &pctfmt.));
    end;
  end;
__stat_value=strip(riskc)||' ('||strip(lowerclc)||", "||strip(upperclc)||")";



  
keep __overall __stat_value __stat_order __stat_name __stat_label __stat_align 
     &groupvars &trtvar;
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

data  rrg_wald;
  set rrg_wald;
  if _n_=1 then set __trts0;
run;
   

proc print data=rrg_wald;
  title 'rrg_wald';
run;




%mend;
