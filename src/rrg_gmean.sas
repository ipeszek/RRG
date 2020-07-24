/*-----------------------------------------------------------------

Study:   N/A
Purpose: RRG plug-in macro to get geometric mean, geometric SE and combination stats
         
         
Author:  Iza Peszek
Date:    01May2020


Macros Used: none
Input data:  passed as maco parameter

NOTE: Assumes &var passed to the macro is >0


-------------------------------------------------------------------*/


%macro m_gmean(
  dataset=,         /* passed by RRG */
  where=%str(1=1),  /* passed by RRG */
  trtvar=,          /* passed by RRG */
  groupvars=,       /* passed by RRG */
  var=,             /* passed by RRG */
  decvar=,          /* passed by RRG */
  subjid=,          /* passed by RRG */
  gmlabel=          /* label for geometric mean */
)
;      
  
%local dataset  where  trtvar groupvars var decvar subjid gmlabel; 



data __gmean0;
  set &dataset;
  where &where ;
  logvar=log(&var);
run;

proc print data=__gmean0;
  var &subjid &var &decvar ;
  title "g_mean0";
run;
run;

proc sort data=__gmean0;
  by  &groupvars &trtvar &decvar ;
run;

proc means data=__gmean0 noprint;
  by &groupvars &trtvar &decvar;
  var logvar ;
  output out=m_gmean mean=mean stderr=se;
  run;
  
  data m_gmean;
    set m_gmean;
    length __stat_label $ 200 __stat_value __stat_name __stat_align  meanvalc sevalc $ 20;
  
    __overall=0;
    __stat_order=0;
    
    *** transform values of mean, se to original scale;
    if mean>0 then gmean=exp(mean);
    if se >0 then gse=exp(se);
    
    *** create character representation of gmean, gse according to specified number of decimals;
    length __decfmt $ 20;
    __decfmt = '12.'; 
    __basedec=&decvar;
    if __basedec>0 then __decfmt = cats(__decfmt, put(__basedec,best.));
    meanvalc = compress(putn(round(gmean, 10**(-1*__basedec)), __decfmt));
    sevalc = compress(putn(round(gse, 10**(-1*__basedec)), __decfmt));
    
    *** geometric mean;
    __stat_name="GMEAN";
    __stat_label="&gmlabel";
    __stat_align="C";
    __stat_value=strip(meanvalc);
    output;
    
    *** se of geometric mean;
    __stat_name="GSE";
    __stat_label="SE";
    __stat_align="C";
    __stat_value=strip(sevalc);
    output;

    *** geometric mean (SE);
    __stat_name="GMEANSE";
    __stat_label="&gmlabel (SE)";
    __stat_align="C";
    __stat_value=strip(meanvalc)||" ("||strip(sevalc)||")";
    output;
    
    *keep &trtvar &groupvars __overall __stat_label  __stat_value __stat_name __stat_align;
  run;
  
  proc print data=m_gmean width=min;
    title "m_gmean";
  run;
  
  title;
  
%mend m_gmean;
    
    
    
    
    
