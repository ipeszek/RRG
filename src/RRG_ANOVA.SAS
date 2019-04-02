/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro rrg_anova(
  dataset=,
  where=,
  trtvar=,
  groupvars=,
  var=,
  refvals=,
  covariates=,
  strata=,
  decvar=,
  interactions=,
  subjid=,
  pvalf=__rrgpf.,
  alpha=0.05)/store;
 
%*-------------------------------------------------------------------------------
* RRG SUPPLEMENTAL MACRO FOR DISTRIBUTION ON SYSTEMS WITHOUT RRG INSTALLED
* THIS MACRO CALCULATES STATISTICS FROM ANOVA/ANCOVA MODEL

* PARAMETERS:
*  DATASET         =  input dataset
*  WHERE           =  where clause to apply to input dataset
*  TRTVAR          =  name of treatment variable
*  GROUPVARS       =  names of grouping variables
*  VAR             =  name of analysis variable
*  REFVALS         =  the value(s) of analysis variables which are reference 
*                     (for pairwise comp)
*  COVARIATES      = list of variables used as continous covariates 
*  STRATA          = list of variables used as categorical (class) covariates 
*  INTERACTIONS    = list of all interaction terms
*  SUBJID          = name of variabel denoting unique subject id
*  DECVAR          = name of the variable storing base decimal precision
*  ALPHA           = alpha level for CIs
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
  %local dataset where trtvar groupvars var refvals covariates strata
   interactions alpha decvar war ning pvalf;
   
 
   
   %if %length(&where)=0  %then %let where=%str(1=1);

data rrg_anova;
  if 0;
run;


   %let war=WAR;
   %let ning=&NING;
   
   %if %sysfunc(countw(&trtvar, %str( )))>1 %then %do;
   %put;
   %PUT &WAR.&NING.: RRG_ANOVA MACRO DOES NOT SUPPORT MULTIPLE TREATMENT VARIABLES;
   %PUT ----------   REQUESTED MODEL WAS THEREFORE IGNORED;
   %put;
   %end;
   
   
   
    
   %if %length(&groupvars) %then %do;
   
   proc sort data=&dataset ;
    by &groupvars &decvar;
   run;
    
   %end; 
   
%*------------------------------------------------------------;   
%* DETANGLE INTERACTION TERMS;
%*------------------------------------------------------------;
   
   %local inter2;
   %if %length(&interactions) %then %do;
     %let inter2 = %tranwrd(%nrbquote(&interactions),%str(*), %str( ));
   %end;
   
%*------------------------------------------------------------;
%* DELETE GROUPS THAT HAVE DATA ON ONE TREATMENT GROUP ONLY;
%*------------------------------------------------------------;
   
   data __rrganv;
    set &dataset (where =(&var ne . and &where));
   run;
 
  
 %if %length(&groupvars)=0  %then %do;
 
     %* determine how many levels of treatment variable are in dataset;
     
     %local nt;
     proc sql noprint;
      select count(*) into:nt separated by ' ' from
      (select distinct &trtvar from __rrganv);
      quit;
      
      
     
     %*------------------------------------------------------------;
     %* CALL PROC GLM TO CALCULATE REQUESTED STATISTICS;
     %*------------------------------------------------------------;
          
        
      ods output close; 
      ods output modelanova = __anova_model 
                   lsmeancl = __anova_lsmean 
                   lsmeans  = __lsmeans
                   %if &nt>1 and %length(&refvals) %then %do;
               LSMeanDiffCL = __anova_lsmeand 
                       diff = __anova_lsdiff
                   %end;
                       ;
    
       proc glm data=__rrganv alpha=&alpha;
         %if %length(&groupvars) %then %do;
         by &groupvars &decvar;
         %end;
         %else %if %length(&decvar) %then %do;
         by &decvar;
         %end;
         class &trtvar &strata;
         model &var=&trtvar &strata &covariates &interactions/ss3;
        lsmeans &trtvar /cl stderr %if &nt>1 and %length(&refvals)  %then %do;
                  pdiff tdiff %end;  cov out=__anova_lsmse; 
       run;
       quit; 
       
       
       proc sql;
              CREATE TABLE __lsmeans_p as
            select
                 __anova_lsmean.*,
                 __lsmeans.probt as probt
            from
                 __anova_lsmean inner join
                 __lsmeans on __anova_lsmean.&trtvar=__lsmeans.&trtvar;
            create table  __anova_lsmean as select * from  __lsmeans_p;               
            quit;
         
      
         %if &nt>1 and %length(&refvals) %then %do;
            


        
            proc transpose data=__anova_lsdiff out=__anova_lsdiff_T;
            by RowName;
            var _:;
            run;
            
            proc sql;
              CREATE TABLE __anova_lsmeand_wse as
            select
                 __anova_lsmeand.*,
                 Difference/COL1 as diffStdErr label="Difference Std Err"
            from
                 __anova_lsmeand inner join
                 __anova_lsdiff_T on i = input(RowName,4.) and j = input(_LABEL_, 4.);
            quit;
            
            data __anova_lsmeand;
              set __anova_lsmeand_wse;
            run;
            
            
          %end;
 
 %end;
 
 %else %do;
 
     %local i numgrps;
     
     proc sort data=__rrganv out=__anvgrps(keep=&groupvars &decvar) nodupkey;
      by &groupvars &decvar;
     run; 
     
     proc sort data=__rrganv ;
      by &groupvars &decvar;
     run; 
     
     data __anvgrps;
      set __anvgrps end=eof;
      by &groupvars &decvar;
      __grpnum=_n_;
      if eof then call symput('numgrps', cats(__grpnum));
     run;
     
     data __rrganv;
      merge __rrganv __anvgrps;
      by &groupvars &decvar;
     run;
     
     
    data __anova_model;
      if 0;
    run;
    
    data __anova_lsmean;
      if 0;
    run;
    
    data __lsmeans;
      if 0;
    run;
    
    data __anova_lsmeand;
      if 0;
    run;
    
    data __anova_lsdiff;
      if 0;
    run;
    
    data __anova_lsmse;
      if 0;
    run;
     
    %do i=1 %to &numgrps;
     
      data __rrganv_;
        set __rrganv;
        if __grpnum=&i;
      run;
      
      proc sort data=__rrganv_;
        by  &groupvars &decvar;
      run;
       
      %local nt;
      proc sql noprint;
        select count(*) into:nt separated by ' ' from
        (select distinct &trtvar from __rrganv_);
      quit;   
       
       
      %*------------------------------------------------------------;
      %* CALL PROC GLM TO CALCULATE REQUESTED STATISTICS;
      %*------------------------------------------------------------;
          
        
      ods output close; 
      ods output modelanova = __anova_model_ 
                   lsmeancl = __anova_lsmean_ 
                   lsmeans  = __lsmeans_
                   %if &nt>1 and %length(&refvals) %then %do;
               LSMeanDiffCL = __anova_lsmeand_ 
                       diff = __anova_lsdiff_
                   %end;
                       ;
    
       proc glm data=__rrganv_ alpha=&alpha;
         %if &groupvars ne %then %do;
         by &groupvars &decvar;
         %end;
         %else %if &decvar ne %then %do;
         by &decvar;
         %end;
         class &trtvar &strata;
         model &var=&trtvar &strata &covariates &interactions/ss3;
        lsmeans &trtvar /cl stderr %if &nt>1 %then %do; pdiff tdiff  %end;
                    cov out=__anova_lsmse_; 
       run;
       quit;
       
       %if &nt>1 and %length(&refvals) %then %do;
         
    
    
        
            proc transpose data=__anova_lsdiff_ out=__anova_lsdiff_T;
            by RowName;
            var _:;
            run;
            
            proc sql;
              CREATE TABLE __anova_lsmeand_wse as
            select
                 __anova_lsmeand_.*,
                 Difference/COL1 as diffStdErr label="Difference Std Err"
            from
                 __anova_lsmeand_ inner join
                 __anova_lsdiff_T on i = input(RowName,4.) and j = input(_LABEL_, 4.);
            quit;
            
            
      %end;
      
       proc sql;
              CREATE TABLE __lsmeans_p as
            select
                 __anova_lsmean_.*,
                 __lsmeans.probt as probt
            from
                 __anova_lsmean_ inner join
                 __lsmeans on __anova_lsmean_.&trtvar=__lsmeans.&trtvar;
            quit;
           
       data __anova_model;
        set __anova_model __anova_model_;
       run;
    
       data __anova_lsmean;
        set __anova_lsmean __lsmeans_p;
       run;
       
      
      %if &nt>1 and %length(&refvals) %then %do;
         data __anova_lsmeand;
          set __anova_lsmeand __anova_lsmeand_wse;
         run;
      
         data __anova_lsdiff;
          set __anova_lsdiff __anova_lsdiff_;
         run;
      %end;
    
       data __anova_lsmse;
        set __anova_lsmse __anova_lsmse_;
       run;

   
    %end;
%end;
   
%*------------------------------------------------------------;
%* TRANSFORM ODS OUTPUT TO DECODE TREATMENT VARIABLES ;
%*------------------------------------------------------------;

  
%if %length(&refvals) %then %do;
  
  data __anova_lsdiff;
    set __anova_lsdiff;
    i = input(rowname, best.);
  run;
  
  
  %local max_i j;
  proc sql noprint;
    select max(i) into:max_i separated by ' ' from  __anova_lsdiff;
    quit;
    
  data  __anova_lsdiff2;
    set __anova_lsdiff;
    format p:;
    
    ppair=1;
    %do j=1 %to &max_i;
      ppval = p&j;  
      j=&j;
      if ppval >-1 then output;
    %end;   
    keep &groupvars ppval i j ppair; 
  run;    
  

  
%end;  

%*------------------------------------------------------------;
%** PREPARE OUTPUT DATASET;
%*------------------------------------------------------------;


%*------------------------------------------------------------;
%** OVERALL P-VALUE;
%*------------------------------------------------------------;

  data __pop0 ;
  set __pop(where=(__grouped ne 1)) ;
  length __tmptrtc $ 2000;
  __tmptrtc = cats(&trtvar);
  keep __tmptrtc &trtvar;
  run;
  
  proc sort data=__pop0 nodupkey;
    by __tmptrtc;
  run;
  
  data __fake_trt;
  set __pop0;
  if _n_=1;
  keep &trtvar;
  run;
  
  data __anova_model;
   set __anova_model;
   where upcase(source)=upcase("&trtvar");
   length __stat_name __stat_label __stat_value __stat_align $ 200;
   __stat_order=1;
   __stat_name = 'OPVAL';
   __stat_label = 'p-Value';
   __stat_align = 'D';
   if probf ne . then __stat_value = put(probf, &pvalf.);
   __overall=1;
   keep __overall __stat_name __stat_label __stat_align __stat_value &groupvars __stat_order;
   run; 

%*------------------------------------------------------------;
%** WITHIN-TREATMENT STATISTICS;
%*------------------------------------------------------------;   
   
   proc sort data=__anova_lsmse out=__trts
    (keep=&groupvars number &trtvar) nodupkey;
    by &groupvars &trtvar;
  run;
  
   
   data __trts;
    set __trts;
    length __tmptrtc $ 2000;
    __tmptrtid=number;
    __tmptrtc = cats(&trtvar);
    keep &groupvars __tmptrtc  __tmptrtid;
  run;
  
  data __anova_lsmean;
    length __tmptrtc $ 2000;
    set __anova_lsmean;
    __tmptrtc = cats(&trtvar);
    drop &trtvar;
  run;
  
  data __anova_lsmse;
    length __tmptrtc $ 2000;
    set __anova_lsmse;
    __tmptrtc = cats(&trtvar);
    drop &trtvar;
  run;
  
   
   proc sort data=__anova_lsmean;
   by &groupvars __tmptrtc;
   run;

   proc sort data=__trts;
   by &groupvars __tmptrtc;
   run;
   
   data __anova_lsmean;
    merge __anova_lsmean __trts;
    by &groupvars __tmptrtc;
   run;
   
   proc sort data=__anova_lsmse;
   by &groupvars __tmptrtc;
   run;


   data __anova_lsmse;
    merge __anova_lsmse __trts;
    by &groupvars __tmptrtc;
   run;
   
   proc sort data=__anova_lsmse;
   by &groupvars  &decvar __tmptrtid;
   run;

   proc sort data=__anova_lsmean;
   by &groupvars &decvar __tmptrtid;
   run;
 
%*------------------------------------------------------------; 
%** LSMEANS;
%*------------------------------------------------------------;  
  
  data __anova_lsmse;
  merge  __anova_lsmse __anova_lsmean;
  by &groupvars  &decvar __tmptrtid;
  keep  __tmptrtid __tmptrtc &groupvars &decvar &decvar stderr lsmean lowercl uppercl probt;
  run;

  proc sort data=__anova_lsmse;
    by __tmptrtc;
  run;
  
  data __pop0 ;
  set __pop(where=(__grouped ne 1)) ;
  length __tmptrtc $ 2000;
  __tmptrtc = cats(&trtvar);
  keep __tmptrtc &trtvar;
  run;
  
  proc sort data=__pop0 nodupkey;
    by __tmptrtc;
  run;
    


  data __anova_lsmse;
  merge __anova_lsmse (in=__a) __pop0;
  by __tmptrtc;
  if __a;
  length __stat_name __stat_label __stat_value __stat_align $ 200;
  __stat_order=1;
  %if %length(&decvar)=0 %then %do;
    __fmt1 = 12.1;
    __fmt2 = 12.2;
  %end;
  %else %do;
  __decvar1=&decvar+1;
  __decvar2=&decvar+2;
  __fmt1=cats('12.', __decvar1);
  __fmt2=cats('12.', __decvar2);
  %end;
  
  __overall=0;
   __stat_name = 'LSMEAN';
   __stat_label = 'LS Mean';
   __stat_align = 'D';
   __stat_value=cats(putn(LSMEAN, __fmt1)); 
   output;
   __stat_name = 'LSMEANSE';
   __stat_label = 'SE of LS Mean';
   __stat_align = 'D';
   __stat_value=cats(putn(STDERR, __fmt2)); 
   output;
   alpha0=100*(1-&alpha);
   __stat_name = 'LSMEANCI';
   __stat_label = cats(alpha0)||'% CI';
   __stat_align = 'D';
   __stat_value=cats('(',putn(lowercl, __fmt1),',')||' '||cats(putn(uppercl, __fmt1),')'); 
   output;
   __stat_name = 'LSMean+SE';
   __stat_label = 'LS Mean (SE)';
   __stat_align = 'D';
   __stat_value=cats(putn(lsmean, __fmt1))||" "||cats('(', putn(stderr,__fmt2),')');
   output;
   __stat_name = 'PROB0';
   __stat_label = 'p-value for LSM=0';
   __stat_align = 'D';
   __stat_value = put(probt, &pvalf.);
   output;
   keep __overall __stat_name __stat_label __stat_align __stat_value 
       &groupvars &trtvar __stat_order;
   run;
  
  /*
   data __anova_lsmse;
   set __anova_lsmse;
   output;
   __stat_name = cats("//", __stat_name);
   __stat_label = cats("//", __stat_label);
   output;
  run;
  */
  
%if %length(&refvals) %then %do;  
      %*------------------------------------------------------------;  
      %** DIFFERENCES BETWEEN LSMEANS;
      %*------------------------------------------------------------; 
         
        data __trts1;
          set __trts;
          i = __tmptrtid;
          keep i __tmptrtc &groupvars;
        run;
        
        proc sort data=__trts1;
          by &groupvars i;
        run;
        
        data __anova_lsmeandb(rename=(_i=i _j=j)) ;
          set __anova_lsmeand;
          difference = -1*difference;
          lowercl0=lowercl;
          uppercl0 = uppercl;
          uppercl = -1*lowercl0;
          lowercl = -1*uppercl0;
          _i=j;
          _j=i;
          drop i j uppercl0 lowercl0;
        run;
        
        data __anova_lsmeand;
          set __anova_lsmeandb __anova_lsmeand __anova_lsdiff2;
        run;
        
        proc sort data=__anova_lsmeand;
          by &groupvars i;
        run;
        
        data __anova_lsmeand;
          merge __anova_lsmeand(in=__a) __trts1;
          by &groupvars i;
          if __a;
          if ppair=1 and missing(&trtvar) then &trtvar = cats(__tmptrtc);
        run;
        
        
        
        proc sort data=__anova_lsmeand;
          by &groupvars j;
        run;
        
       data __anova_lsmeand;
          length __refc $ 2000;
          merge __anova_lsmeand(in=__b) __trts1 (rename=(i=j __tmptrtc=__ref));
          by &groupvars j;
          if __b;
          __refc = cats(__ref);
          drop __ref;
       run;
        
        
         
       proc sort data=__anova_lsmeand;
          by __refc;
       run;
       
       
        
       data __pop0 ;
        set __pop (where=(__grouped ne 1) rename=(&trtvar=__reforig)); 
        length __refc $ 2000;
        __refc = cats(__reforig);
        __refid = __trtid;
        keep __refid __refc __reforig __dec_&trtvar ;
      run;
      
      
       proc sort data=__pop0 nodupkey ;
          by __refc;
       run;
 
       data __anova_lsmeand;
          merge __anova_lsmeand(in=__b) 
              __pop0;
          by __refc;
          if __b;
       run;
      
        proc sort data=__anova_lsmeand;
          by __tmptrtc;
        run;
              

        data __anova_lsmeand;
          merge __anova_lsmeand(in=__b) 
              __pop0 (drop = __refid __dec_&trtvar 
              rename=(__refc=__tmptrtc __reforig=&trtvar));
          by __tmptrtc;
          if __b;
       run; 
       
       proc sort data=__anova_lsmeand;
        by __refid &trtvar;
       run;
             


       data   __anova_lsmeand;
        set __anova_lsmeand;
          length __stat_name __stat_label __stat_value __stat_align $ 200;
        
        alpha0=100*(1-&alpha);
        __overall=0;
        %if %length(&decvar)=0 %then %do;
          __fmt1 = 12.1;
          __fmt2 = 12.2;
        %end;
        %else %do;
          __decvar1=&decvar+1;
          __decvar2=&decvar+2;
          __fmt1=cats('12.', __decvar1);
          __fmt2=cats('12.', __decvar2);
        %end;
        
         __stat_order = __refid+100;
        
         if ppair ne 1 then do;
         __stat_name = 'LSMEANDIFF//CI';
         __stat_label = 'LS Mean Diff vs '||cats(__dec_&trtvar)||'//'||
             cats(alpha0)||'% CI';
         __stat_align = 'D//D';
         __stat_value=cats(putn(difference, __fmt1))||'//'|| 
                 cats("(", putn(lowercl, __fmt1),",")||" "||cats(putn(uppercl, __fmt1), ")");
         output; 
        
         __stat_name = 'LSMEANDIFF';
         __stat_label = 'LS Mean Diff vs '||cats(__dec_&trtvar);
         __stat_align = 'D';
         
         __stat_value=cats(putn(difference, __fmt1)); 
         output;    
         
         
         __stat_name = 'LSMEANDIFF+SE';
         __stat_label = 'LS Mean Diff vs '||cats(__dec_&trtvar)||" (SE)" ;
         __stat_align = 'C';
         
         __stat_value=cats(putn(difference, __fmt1))||" ("||cats(putn(diffStdErr, __fmt2))||")"; 
         output;    
         
         
         __stat_name = 'LSMEANDIFFSE';
         __stat_label = 'SE of LS Mean Diff vs '||cats(__dec_&trtvar) ;
         __stat_align = 'D';
         
         __stat_value=cats(putn(diffStdErr, __fmt2));
         output;    
         
         
        
         __stat_name = 'DIFFCI';
         __stat_label = cats(alpha0)||'% CI for LSM Diff vs '||cats(__dec_&trtvar);
         __stat_align = 'C';
         
         __stat_value=cats("(", putn(lowercl, __fmt1),",")||" "||cats(putn(uppercl, __fmt1), ")"); 
         output;    
        end;
        else do;
         __stat_name = 'PPAIR';
         __stat_label = 'p-Value for Difference in LS Means from '||cats(__dec_&trtvar);
         __stat_align = 'D';
         __stat_value = put(ppval, &pvalf.);
         output;
        end;
         keep __overall __stat_name __stat_label __stat_align __stat_value 
             &groupvars &trtvar __stat_order 
             %if %length(&refvals) %then %do; 
             __refid __refc __reforig 
             %end;
             ;
       run;

       
        data __anova_lsmeand;
        set  __anova_lsmeand ;
          %if %length(&refvals) %then %do;
          if __reforig in (&refvals);
          drop __reforig;
          %end;
        run;
       
       
       
 %end;
   
   data rrg_anova;
   set __anova_lsmse __anova_model 
     %if %length(&refvals)%then %do; __anova_lsmeand %end;;
   run;
 
  proc sort data=rrg_anova;
    by __overall &groupvars &trtvar __stat_name %if %length(&refvals) %then %do; __refid %end;;
  run;
  
  %if %length(&refvals) %then %do;
      proc sort data=__pop(where=(__grouped ne 1 and &trtvar in (&refvals))) 
        out=__pop0 (rename=(__trtid=__refid)) nodupkey;
        by __trtid;
      run;
      
  %end;
  
  %if %length(&groupvars) %then %do;
  
    proc sort data=__rrganv out=__tmpl1 (keep = &groupvars) nodupkey;
      by &groupvars;
    run;
    
    proc sql noprint;
      create table __tmpl3 as select * from __tmpl1 cross join
      (select distinct &trtvar, __trtid from __pop(where=(__grouped ne 1)));
      %if %length(&refvals) %then %do;
      create table __tmpl4 as select * from __tmpl3 (where =(&trtvar in (&refvals))) cross join 
      (select __refid, __dec_&trtvar from __pop0);
      %end;
    quit;
 %end;
 
 %else %do;
 
   data __tmpl1;
    if 0;
   run;
  
   proc sql noprint;
      create table __tmpl3 as select distinct &trtvar, __trtid from __pop(where=(__grouped ne 1));
      %if %length(&refvals) %then %do;
      create table __tmpl4 as select * from 
      __tmpl3 (where =(&trtvar in (&refvals)))     cross join   (select __refid, __dec_&trtvar from __pop0);
      %end;
    quit;
    
    
 %end;
 
 
 


 data __tmpl1;
  set __tmpl1;
  length __stat_name __stat_label __stat_align_ $ 200;
   __overall=1;
   __t4=0;
   __stat_order=1;
   __stat_name = 'OPVAL';
   __stat_label = 'p-Value';
   *__stat_align_ = 'C';  
   __stat_align_ = 'D';  
  output;
run;
  
  data  __tmpl3;
  set __tmpl3;
  __t4=0;
  alpha0=100*(1-&alpha);
  length __stat_name __stat_label __stat_align_ $ 200;
  
  __stat_order=1;
    __overall=0;
  
   __stat_name = 'LSMEAN';
   __stat_label = 'LS Mean';
   __stat_align_ = 'D';
   output;
   
   __stat_name = 'LSMEANSE';
   __stat_label = 'SE of LS Mean';
   __stat_align_ = 'D';
   output;
   
   __stat_name = 'LSMEANCI';
   __stat_label = cats(alpha0)||'% CI';
   __stat_align_ = 'D';
   output;
  
   __stat_name = 'LSMean+SE';
   __stat_label = 'LS Mean (SE)';
   __stat_align_ = 'D';
   output;
run;


%if %length(&refvals) %then %do;
     data  __tmpl4;
      set __tmpl4;
     * if __trtid ne __refid;
      __t4=1;
      length __stat_name __stat_label __stat_align_ $ 200;
      alpha0=100*(1-&alpha);
      __stat_order = __refid+100;
      
      __overall=0;
      
       __stat_name = 'LSMEANDIFF//CI';
       __stat_label = 'LS Mean Diff vs '||cats(__dec_&trtvar)||'//'||
           cats(alpha0)||'% CI';
       __stat_align_ = 'D//D';
       output;
    
       __stat_name = 'PPAIR'; 
       __stat_label = 'p-Value for Difference in LS Means from '||cats(__dec_&trtvar);
       __stat_align_ = 'D';
       output;
      
       __stat_name = 'LSMEANDIFF';
       __stat_label = 'LS Mean Diff vs '||cats(__dec_&trtvar);
       __stat_align_ = 'D';
       output;
     
       __stat_name = 'DIFFCI';
       __stat_label = cats(alpha0)||'% CI for LSM Diff vs '||cats(__dec_&trtvar);
       __stat_align_ = 'C';
       output;
       
        __stat_name = 'LSMEANDIFFSE';
       __stat_label = 'SE of LS Mean Diff vs '||cats(__dec_&trtvar);
       __stat_align_ = 'D';
       output;

        __stat_name = 'LSMEANDIFF+SE';
       __stat_label = 'LS Mean Diff vs '||cats(__dec_&trtvar)||" (SE)";
       __stat_align_ = 'C';
       output;
    

    run;
%end;



data __tmpl;
  set __tmpl1 __tmpl3 %if %length(&refvals) %then %do; __tmpl4 %end;;
run;




proc sort data=__tmpl;
  by __overall &groupvars &trtvar __stat_name %if %length(&refvals) %then %do; __refid %end;;
run;

data rrg_anova;
  merge __tmpl (in=__inrrg)  rrg_anova (in=__inanv);
  by __overall &groupvars &trtvar __stat_name %if %length(&refvals) %then %do; __refid %end;;
  if 0 then __refid=.;
  
  if __t4=1 then do;
    if __stat_value='' then do;
      if __refid ne __trtid then __stat_value='N/E';
      else __stat_value='_';
      __stat_align = __stat_align_;
    end;
  end;
  else do;
    if __stat_value='' then do;
      __stat_value='N/E';
      __stat_align = __stat_align_;
    end;
  end;
  drop __stat_align_ __t4 __trtid;
run;

data rrg_anova;
  set rrg_anova;
  output;
  __stat_label = "//"||cats(__stat_label);
  __stat_name = "//" ||cats(__stat_name);
  output;
  
run; 
/*
proc print data=rrg_anova;
  title "rrg_anova final";
  *where __stat_name in ('DIFFCI','LSMEANDIFF');
run;
*/

%mend;
