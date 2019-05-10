/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __rrg_odds(
  dataset=,
  where=,
  trtvar=,
  groupvars=,
  var=,
  refvals=,
  subjid=,
  oddsfmt=6.2,
  alpha=0.05,
  label_or=,
  label_ci=,
  label_orci=
  )/store;

%*-------------------------------------------------------------------------------
* RRG SUPPLEMENTAL MACRO FOR DISTRIBUTION ON SYSTEMS WITHOUT RRG INSTALLED
* THIS MACRO CALCULATES SIMPLE ODDS RATIO BASED ON RELATIVE RISK

* PARAMETERS:
*  DATASET         =  input dataset
*  WHERE           =  where clause to apply to input dataset
*  TRTVAR          =  name of treatment variable
*  GROUPVARS       =  names of grouping variables
*  VAR             =  name of analysis variable
*  REFVALS         =  the value(s) of analysis variables which are reference 
*                     (for pairwise comp)
*  SUBJID          = name of variabel denoting unique subject id
*  ODDSFMT         = format to display odds ratio
*  ALPHA           = alpha level for confidence intervals
*  LABEL_OR        = display label for ods ratio
*  LABEL_CI        = display label for CI for odds ratio 
*  LABEL_ORCI      = display label for odds ratio and CI

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

%local dataset where trtvar groupvars  var  refvals subjid oddsfmt alpha 
label_or label_ci label_orci;

%if %length(&where)=0  %then %let where=%str(1=1);

data rrg_odds;
  if 0;
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

data  rrg_odds;
  if 0;
run;
   
%if %length(&groupvars) %then %do;   
  proc sort data=&dataset(where=(&where )) 
    out=__f0 (keep = &groupvars ) nodupkey;
  by &groupvars ;
  run;
%end;

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
        set &dataset (where=(&where ));
        if __trtid in (&&trt&i, &&ref&j) and not missing(&var) ;
        __tmpgb=1;
        if __trtid=&&ref&j then __tmptrt=0;
        else __tmptrt=1; 
      run;


       %* keep only cases where there is data in each of 4 cells;
  
        proc sort data=__fishtmp ;
          by &groupvars __tmpgb __tmptrt &var;
        run;

      
        proc sort data=__fishtmp nodupkey out=__cnttmp;
          by &groupvars __tmpgb __tmptrt &var;
        run;
        
        
        data __cnttmp;
          set __cnttmp;
          by &groupvars __tmpgb __tmptrt &var;
          retain __cnttmp;

          if first.__tmpgb then __cnttmp=0;
          __cnttmp+1;
          if last.__tmpgb then output;

          keep &groupvars __tmptrt &var __tmpgb __cnttmp;
        run;
     
          
        data __fishtmp;
          merge __fishtmp __cnttmp (keep=&groupvars __tmpgb __cnttmp) ;
          by &groupvars __tmpgb;
        run;

        data __fishtmp;
          set __fishtmp;
          if __cnttmp<4 then delete;          
        run;
        
     %local dsid rc nobsrr;
     %let dsid = %sysfunc(open(__fishtmp));
     %let nobsrr = %sysfunc(attrn(&dsid, NOBS));
     %let rc = %sysfunc(close(&dsid));        

     %if &nobsrr<=0 %then %do;
         
         
         %* nothing to estimate: create output dataset and skip to end;
         data __rr;
          studytype='CASE-CONTROL (ODDS RATIO)';
          value=.;
          lowercl=.;
          uppercl=.;
          __overall=0;
         run;
         
         %if %length(&groupvars) %then %do;
           proc sql noprint;
            create table __tmp as select * from __rr cross join __f0;
            create table __rr as select * from __tmp;
           quit;
         %end;
         
         %goto make_est;
         
     %end;
      

      %if %length(&groupvars) %then %do;
      proc sort data=__fishtmp;
        by &groupvars;
      run;
      %end;

      data __rr;
        if 0;
      run;

      ods output close;
      ods output  RelativeRisks=__rr;


      proc freq data=__fishtmp ;
      %if %length(&groupvars) %then %do;
      by &groupvars;
      %end;
      tables __tmptrt*&var./relrisk alpha=&alpha;
      run;

     
       data __rr;
       set __rr;
       if upcase(studytype)='CASE-CONTROL (ODDS RATIO)';
       run;
       
      %if %length(&groupvars) %then %do;
          proc sort data=__rr;
            by &groupvars ;
          run;
    
          /*
          proc sort data=&dataset(where=(&where )) out=__f0 (keep = &groupvars  &var) nodupkey;
            by &groupvars ;
          run;
          */
          
          data __rr;
            merge __rr __f0;
            by &groupvars ;
          run;  
      %end;
    
      %else %do;
         %local dsid rc nobsrr;
         %let dsid = %sysfunc(open(__rr));
         %let nobsrr = %sysfunc(attrn(&dsid, NOBS));
         %let rc = %sysfunc(close(&dsid));
         
         %if &nobsrr=0 %then %do;
            data __rr;
              studytype='CASE-CONTROL (ODDS RATIO)';
              value=.;
              lowercl=.;
              uppercl=.;
              __overall=0;
            run;
         
         %end;
      %end;  


      %make_est: 
      
      data __rr;
        set __rr;
        if _n_=1 then set __trts(keep=__trtid &trtvar where=(__trtid=&&trt&i));
      run;

      data __rr;
        set __rr;
        if _n_=1 then set __trts(
          keep=__trtid __dec_&trtvar
          where=(__trtid=&&ref&j));
      
      length __stat_name __stat_label __or __ci __stat_value __stat_align $ 200;
      alpha0=100*(1-&alpha);
      
      __overall=0;
      __stat_order=&&ref&j;
      
      __stat_name = 'OR';
      __stat_label = trim(left(symget("label_or")));
      __stat_label = tranwrd(__stat_label,'_VS_', cats(__dec_&trtvar));

      __stat_align = 'D';
      if value ne . then __stat_value = put(value, &oddsfmt);
      else __stat_value ="N/E";
      __or = __stat_value;
      output;
      
      if lowercl ne . then __stat_value = put(lowercl, &oddsfmt);
      else __stat_value ="N/E";
      if uppercl ne . then __stat_value = cats("(", __stat_value)||", "||cats(put(uppercl, &oddsfmt), ")");
      else __stat_value =cats("(", __stat_value)||", "||cats("N/E)");
      __stat_name = 'CI';
      __stat_label = trim(left(symget("label_ci")));
      __stat_label = tranwrd(__stat_label,'_ALPHA_', strip(put(alpha0, best.)));
      __stat_label = tranwrd(__stat_label,'_VS_', cats(__dec_&trtvar));
      
      __ci = __stat_value;
      output;
      
      __stat_name = 'OR+CI';
        __stat_label = trim(left(symget("label_orci")));
        __stat_label = tranwrd(__stat_label,'_ALPHA_', strip(put(alpha0, best.)));
        __stat_label = tranwrd(__stat_label,'_VS_', cats(__dec_&trtvar));

      __stat_value = cats(__or)||" "||cats(__ci);
      output;
      
      __stat_name = 'OR+//CI';
        __stat_label = trim(left(symget("label_orci")));
        __stat_label = tranwrd(__stat_label,'_ALPHA_', strip(put(alpha0, best.)));
        __stat_label = tranwrd(__stat_label,'_VS_', cats(__dec_&trtvar));

      __stat_value = cats(__or)||"//"||cats(__ci);
      output;
      
      
      
      keep __overall __stat_value __stat_order __stat_name __stat_label __stat_align 
           &groupvars &trtvar;
      run;
      
      data rrg_odds;
        set rrg_odds __rr;
      run;
    %end;

    %end;  
  
  %end;

%end;



%mend;
