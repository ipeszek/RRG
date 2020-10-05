/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __usecodesds_t(
  vinfods=, 
  varid=, 
  outds=, 
  dsin=, 
  trtvars=, 
  by=
  )/store;
  

/*
PURPOSE: TO PROCESS DATASET WITH LIST OF CODES OF A VARIABLE
         ADD FAKE RECORDS TO &dsin SO ALL CODES FROM
           CODEDS ARE INCLUDED
         CRETAE TEMPLATE DATASET FOR ALL GROUPING VARIABLES  

MACRO PARAMETERS:
VINFODS  (DEFAULTS TO __VARINFO): DATASET WITH PROPERTIES OF VARIABLE
          FOR WHICH CODELISTDS IS BEING MADE
VARID    ID OF VARIABLE (IN __VARINFO) FOR WHICH CODELISTDS IS BEING MADE (NOT USED IN THIS MACRO)
DSIN     ANALYSIS DATASET          
OUTDS    OUTPUT DATASET  -- later used by __applycodesds macro
GRPTMPDS DATASET WITH ALL MODALITIES (AND DECODES IF GIVEN) OF GROUPING
          VARIABLES, TAKING THEM FROM CODELISTDS IF THEY ARE THERE
          OF FROM &dsin IF THEY ARE NOT IN &CODELISTDS
BY       LIST FO GROUPING VARIABLES
TRTVARS  LIST OF TREATMENT VARIABLES          
          
NOTES:   IF CODELISTDS WAS NOT SPECIFIED FOR A VARIABLE, THIS MACRO DOES 
            NOTHING

*/



%local vinfods varid outds dsin  trtvars by;
%local decode var codes codelistds countwhat ;
      

%* assumes that &dsin exists and has all needed variables;
%* assumes that &dsin is sorted properly;


proc sql noprint;
  select trim(left(decode))     into:decode     separated by ' ' from __catv;
  select trim(left(name))       into:var        separated by ' ' from __catv;
  select trim(left(codelist))   into:codes      separated by ' ' from __catv;
  select trim(left(codelistds)) into:codelistds separated by ' ' from __catv;
  select trim(left(countwhat))  into:countwhat  separated by ' ' from __catv;
quit;

/* catv is__varinfo subset on where varid=&varid */

%if %length(&codelistds)=0 %then %goto exit;

%local execcl;
%* this is the name of the dataset into which codelistds will be copied;

%if %index(&codelistds,%str(__))=1 %then %let execcl=&codelistds._exec;
%else %let execcl=__&codelistds._exec;


%local order var2 dsid rc varnum;
%let dsid = %sysfunc(open(&execcl));
%let varnum= %sysfunc(varnum(&dsid, __order));
%if &varnum>0 %then %let order=__order;
%let varnum= %sysfunc(varnum(&dsid, &var));
%if &varnum>0 %then %let var2=&var;
%let rc = %sysfunc(close(&dsid));








%* IF LIST OF CODES WERE GIVEN FOR ONE OR MORE GROUPING VARIABLE;
%* THEN DATASET __GRPCODES WAS CREATED WITH ALL COMBINATIONS OF CODES;
%* FOR THESE GROUPING VARIABLES. wE NEED TO CROSS JOIN IT WITH LIST OF CODES;
%* FOR CURRENT ANALYSIS VARIABLE;


%local i dsid rc vnum tmp tmp2 missgrp  missgrpdecode alldecodes; 
%local numgroups vtype isvar isorder num_decodes;

%let missgrp= ;
%let isorder=0;
%let isvar=0;   
%let num_decodes=0;


*-----------------------------------------------------------------------;
* DETERMINE WHICH GROUPING VARIABLES ARE NOT IN CODELIST DATASET;
* save THEIR LIST IN &MISSGRP ;
* IF CURRENT ANALYSIS VARIABLE IS NOT IN CODELIST DATASET THEN ADD IT;
*   AND ITS DECODE, IF PROVIDED, TO &MISSGRP;
* &MISSGRPDECODE IS THE LIST OF DECODES FOR THESE VARIABLES ;
* &ALLDECODES = ALL DECODES FOR GROUPIGN VARIABLES (INCLUDING VARBY);
*-----------------------------------------------------------------------;         

%let dsid=%sysfunc(open(&execcl));
%if %sysfunc(varnum(&dsid, __order))>0 %then %do;
    %let isorder=1;
%end;  

%let numgroups  =%sysfunc(countw(&by, %str ( )));
%local tmp i;   
%do i=1 %to &numgroups;
    %let tmp = %scan(&by,&i, %str( ));
    
    proc sql noprint;
        select decode into:tmp2 from &vinfods
           (where=(upcase(name)=upcase("&tmp")));
    quit;
    %let alldecodes=&alldecodes &tmp2;
        
    %if %sysfunc(varnum(&dsid, &tmp))=0 %then %do;
            %let missgrp=&missgrp &tmp &tmp2;
            %let missgrpdecode=&missgrpdecode &tmp2;
    %end;
    %else %do;
            %let num_decodes=%eval(&num_decodes+1);
            %local dec&num_decodes;
            %let dec&num_decodes=&tmp2;
    %end;      
%end;
%if %length(&decode) %then %do;
    %if %sysfunc(varnum(&dsid, &decode))>0 %then %do;
          %let num_decodes=%eval(&num_decodes+1);
          %local dec&num_decodes;
          %let dec&num_decodes=&decode;
    %end;
    %else %do;
      %let missgrp=&missgrp &decode;
      %let missgrpdecode=&missgrpdecode &decode;
    %end;
%end;     
%if %sysfunc(varnum(&dsid, &var))=0 %then %do;
    %let missgrp=&missgrp &var ;
%end;
%else %do;
    %let isvar=1;
%end;

%let rc=%sysfunc(close(&dsid));     



%* CHECK WHICH DECODES FROM CODELIST EXIST IN &DATASET-THEY NEED TO BE DROPPED;
%local decodes2drop;
%let dsid=%sysfunc(open(%scan(&datasetrrg,1,%str(%())));
%do i=1 %to &num_decodes;
   %if %length(&&dec&i) %then %do; %* IP 2009-03-02;
    %if %sysfunc(varnum(&dsid, &&dec&i))>0 %then 
      %let decodes2drop=&decodes2drop &&dec&i;
   %end;   %* IP 2009-03-02;
%end;
%let rc=%sysfunc(close(&dsid));

%if &isvar=1 %then %do;
    %if &isorder=0 %then %do; 
        
        proc sort data=&execcl out=&outds._exec;
        by &var;
        run;
           
        data &outds._exec;
          set &outds._exec;
          by &var;
          retain __order;
          if _n_=0 then __order=0;
          if first.&var then __order+1;
        run;   
         
    %end;

    %else %do;
        data &outds._exec; 
        set &execcl;
        run;
    %end;        
*** note: &var SHOULD BE in &codelistds;

%end;

data rrgpgmtmp;
length record $ 2000;
keep record;
record = " "; output;
record =  "*---------------------------------------------------------------;"; output;
record =  "* APPLY TEMPLATE FOR MODALITIES OF VARIABLE; "; output;
record =  "*---------------------------------------------------------------;"; output;
record = " "; output;

        
%if &isvar=1 %then %do;
    %if &isorder=0 %then %do;

        %* IF CODELISTDS DATASET DOES NOT HAVE __ORDER VARIABEL THEN CREATE IT;

        record = " ";    output;
        record =  "proc sort data=&codelistds out=&outds;"; output;
        record =  "      by &var;"; output;
        record =  "     run;"; output;
        record = " ";      output;
        record =  "     data &outds;"; output;
        record =  "      set &outds;"; output;
        record =  "      by &var;"; output;
        record =  "      retain __order;"; output;
        record =  "      if _n_=0 then __order=0;"; output;
        record =  "      if first.&var then __order+1;"; output;
        record =  "     run;"; output;
        record = " ";      output;
        record =  "     data &outds.2;"; output;
        record =  "      set &outds;"; output;
        record =  "    run;"; output;
        record = " "; output;
    %end;
    %else %do;
        record = " ";    output;
        record =  "     data &outds &outds.2; "; output;
        record =  "       set &codelistds;"; output;
        record =  "     run;"; output;
        record = " "; output;
    %end;
%end;
        
%else %do;

    record = " ";    output;
    record =  "  data &outds &outds.2; "; output;
    record =  "  set &codelistds;"; output;
    record =  "   __order=_n_;"; output;
    record =  "  run;"; output;
    record = " "; output;


%end;


*-----------------------------------------------------------------------;
* NOTE: IF DECODE IS SPECIFIED FOR A VARIABLE IN CODELISTDS, ;
*   THEN CODELISTDS MUST HAVE DECODE VARIABLE;
*-----------------------------------------------------------------------;
     


record =  '*-------------------------------------------------------------------;'; output;
record =  '* CROSS-JOINN CODELIST DATASET WITH ALL VALUES OF GROUPING VARIABLES' ; output;
record =  '*   THAT ARE NOT IN CODELINES DATASET - TO GET FULL DISPLAY TEMPLATE;'; output;
record =  '*-------------------------------------------------------------------;'; output;
record = " "; output;
%if %length(&missgrp) %then %do;
    %local tmp;
    %let tmp = %sysfunc(tranwrd(%sysfunc(compbl(&missgrp)),%str( ),%str(,)));
    record =  "proc sql noprint nowarn;"; output;
    record =  "      create table &outds.2 as  select * from "; output;
    record =  "       (select distinct "; output;
    record =  "         &tmp"; output;
    record =  "          from  &dsin (drop=__order &decodes2drop))"; output;
    record =  "         cross join (select * from &outds);"; output;
    record =  "    quit;"; output;
%end;
record = " "; output;
record =  "*-------------------------------------------------------------------;"; output;
record =  "* ADD DECODES FROM &CODELISTDS TO &dsin;"; output;
record =  "*-------------------------------------------------------------------;"; output;
record = " ";     output;
record = " "; output;
record =  "proc sort data=&outds.2;"; output;
record =  "by  &by &var ;"; output;
record =  "run;"; output;
record = " "; output;
record =  "proc sort data=&dsin;"; output;
record =  "by  &by &var ;"; output;
record =  "run;"; output;
record = " "; output;
record =  "data &dsin;"; output;
record =  "  merge &dsin(in=__a drop=__order) &outds.2;"; output;
record =  "  by  &by  &var  ;"; output;
record =  "  if __a;"; output;
record =  "run;"; output;
record = " "; output;
record = " "; output;
record =  "*--------------------------------------------------------------------;"; output;
record =  "* ADD MODALITIES FROM USER-PROVIDED LIST TO &dsin "; output;
record =  "*--------------------------------------------------------------------;"; output;
record = " "; output;
record =  "data &outds.2;"; output;
record =  "  set &outds.2;"; output;
record =  "  __theid=_n_;"; output;
record =  "  __tby=1;"; output;
record =  "run;"; output;
record = " "; output;
record =  "data &outds.3;"; output;
record =  "  set &dsin;"; output;
record =  "  __order=1;"; output;
record =  "  __tby=1;"; output;
record =  "  drop &by  &alldecodes &var &decode &trtvars __order;"; output;
record =  "run;"; output;
record = " "; output;
record =  "data &outds.3;"; output;
record =  "  set &outds.3;"; output;
record =  "  if _n_=1;"; output;
record =  "run;"; output;
record = " "; output;
record =  "proc sort data=&outds.3;"; output;
record =  "  by __tby;"; output;
record =  "run;"; output;
record = " ";     output;
record =  "proc sort data=&outds.2;"; output;
record =  "  by __tby;"; output;
record =  "run;"; output;
record = " "; output;
record =  "data &outds.4;"; output;
record =  "  merge &outds.2 &outds.3;"; output;
record =  "  by __tby;"; output;
record =  "  __trtid=-1*_n_;"; output;
record =  "run;"; output;
record = " "; output;
record =  "data &dsin;"; output;
record =  "  set &dsin (in=__a) &outds.4;"; output;
record =  "  if __a then __theid=0;"; output;
record =  "  __tby=1;"; output;
record =  "run;"; output;
record = " "; output;
record =  "*-------------------------------------------------------------------;"; output;
record =  "* CREATE 'TEMPLATE' FOR ALL GROUPING VARIABLES;"; output;
record =  "*-------------------------------------------------------------------;"; output;




%local tmp;

%if %length(&by.&alldecodes) %then %do;
  %let tmp =  %sysfunc(tranwrd(%sysfunc(compbl(&by &alldecodes )),
           %str( ), %str(,)));
%end;
%if %length(&tmp) %then %do;

    record =  "    proc sql noprint;"; output;
    record =  "      create table __grptemplate as"; output;
    record =  "      select distinct "; output;
    record =  "        &tmp "; output;
    record =  "      from &outds.2;"; output;
    record =  "      quit;"; output;
    record = " "; output;

%end;

run;



proc append data=rrgpgmtmp base=rrgpgm;
run;

%exit:


%mend ;

