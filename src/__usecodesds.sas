/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __usecodesds(
  vinfods=, varid=, outds=, dsin=, 
  /*grptmpds=,*/
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



%local vinfods varid outds dsin /*grptmpds */ trtvars by;
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

%if %length(&codelistds)=0 %then %do;
 
  %goto exit;
%end;



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

%if %sysfunc(exist(__grpcodes_exec)) %then %do;

  %* CROSS-JOIN __GRPCODES WITH CODELISTDS;    
  proc sql noprint nowarn;
    create table __tmp as select * from __grpcodes_exec
       cross join &execcl;
     create table &execcl as select * from __tmp;
    create table __grpcodes_exec as select distinct * from 
      &execcl(drop=&var2 &decode &order);
  quit;  
  
  data _null_;
  file "&rrgpgmpath./&rrguri..sas" mod;
  put;
  *----------------------------------------------------;
  * CROSS-JOIN __GRPCODES WITH CODELISTDS;
  *----------------------------------------------------;
  put @1 "proc sql noprint nowarn;";
  put @1 "    create table __tmp as select * from __grpcodes";
  put @1 "       cross join &codelistds;";
  put @1 "     create table &codelistds as select * from __tmp;";
  put @1 "  create table __grpcodes as select distinct * from ";
  put @1 "    &codelistds (drop=&var2 &decode &order);";
  put @1 "quit;";  
  put;
  run;

%end;

%else %do;
  ** if &codelistds has grouping variables then we need to create __grpcodesds;
  
  data __tmp;
    set &execcl;
    drop &var2 &decode &order;
  run;
  
  
  %local dsid numvar numobs rc;
  %let dsid = %sysfunc(open(__tmp));
  %let numvar = %sysfunc(attrn(&dsid, nvars));
  %let numobs = %sysfunc(attrn(&dsid, nobs));
  %let rc = %sysfunc(close(&dsid));
 
  %if &numvar>0 and &numobs>0 %then %do;
  
    %local grpnames grpdec allgrp tmp;
    proc sql noprint;
      select name into:grpnames separated by ' ' 
        from __varinfo (where=(type='GROUP'));
      select decode into:grpdec separated by ' ' 
        from __varinfo (where=(type='GROUP'));
    quit;
    
    %local dsid numvar numobs rc;
    %let dsid = %sysfunc(open(__tmp));
    %do i=1 %to %sysfunc(countw(&grpnames, %str( )));
      %let tmp = %scan(&grpnames, &i, %str( ));
      %if %sysfunc(varnum(&dsid, &tmp))>0 %then
        %let allgrp = &allgrp &tmp;
      %if %sysfunc(varnum(&dsid, __order_&tmp))>0 %then
        %let allgrp = &allgrp __order_&tmp;
    %end;    
    %do i=1 %to %sysfunc(countw(&grpdec, %str( )));
      %let tmp = %scan(&grpdec, &i, %str( ));
      %if %sysfunc(varnum(&dsid, &tmp))>0 %then
        %let allgrp = &allgrp &tmp;
    %end;    
    %let rc= %sysfunc(close(&dsid));
  
    %if %length(&allgrp) %then %do;%* IP 2009-03-01;
      %let tmp = %sysfunc(tranwrd(&allgrp, %str( ), %str(,)));
    %end;

      proc sql noprint;
      create table __grpcodes_exec as select 
         distinct &tmp from __tmp;
      quit;
    
      data _null_;
      file "&rrgpgmpath./&rrguri..sas" mod;
      put;
      *----------------------------------------------------;
      * CREATE TEMPLATE FOR DISPLAY OF GROUPING VARIABLES;
      *----------------------------------------------------;
      put @1 "data __tmp;";
      put @1 "set &codelistds;";
      put @1 "drop &var2 &decode &order;";
      put @1 "run;";
      
      put @1 "proc sql noprint;";
      put @1 "  create table __grpcodes as select distinct ";
      put @1 " &tmp from __tmp;";
      put @1 "quit;  ";
      put;
      run;
  %end;

%end;



data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put @1 "*---------------------------------------------------------------;";
put @1 "* APPLY TEMPLATE FOR MODALITIES OF VARIABLE; ";
put @1 "*---------------------------------------------------------------;";
put;
run;

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



data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;

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

*** note: &var SHOULD BE in &codelistds;
%* IF CODELISTDS DATASET DOES NTO HAVE __ORDER VARIABEL THEN CREATE IT;

%if &isvar=1 %then %do;
   %if &isorder=0 %then %do;

      data _null_;
      file "&rrgpgmpath./&rrguri..sas" mod;
      put;   
      put @1 "proc sort data=&codelistds out=&outds;";
      put @1 "      by &var;";
      put @1 "     run;";
      put;     
      put @1 "     data &outds;";
      put @1 "      set &outds;";
      put @1 "      by &var;";
      put @1 "      retain __order;";
      put @1 "      if _n_=0 then __order=0;";
      put @1 "      if first.&var then __order+1;";
      put @1 "     run;";
      put;     
      put @1 "     data &outds.2;";
      put @1 "      set &outds;";
      put @1 "    run;";
      put;
      run;
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
    data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    put;   
    put @1 "     data &outds &outds.2; ";
    put @1 "       set &codelistds;";
    put @1 "     run;";
    put;
    run;
    
    data &outds._exec; 
    set &execcl;
    run;

   %end;
 %end;
        
%else %do;
data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;   
put @1 "  data &outds &outds.2; ";
put @1 "  set &codelistds;";
put @1 "   __order=_n_;";
put @1 "  run;";
put;
run;

data &outds._exec; 
set &execcl;
run;

%end;


*-----------------------------------------------------------------------;
* NOTE: IF DECODE IS SPECIFIED FOR A VARIABLE IN CODELISTDS, ;
*   THEN CODELISTDS MUST HAVE DECODE VARIABLE;
*-----------------------------------------------------------------------;
     


data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put @1 '*-------------------------------------------------------------------;';
put @1 '* CROSS-JOINN CODELIST DATASET WITH ALL VALUES OF GROUPING VARIABLES' ;
put @1 '*   THAT ARE NOT IN CODELINES DATASET - TO GET FULL DISPLAY TEMPLATE;';
put @1 '*-------------------------------------------------------------------;';
put;
%if %length(&missgrp) %then %do;
    %local tmp;
    %let tmp = %sysfunc(tranwrd(%sysfunc(compbl(&missgrp)),%str( ),%str(,)));
    put @1 "proc sql noprint nowarn;";
    put @1 "      create table &outds.2 as  select * from ";
    put @1 "       (select distinct ";
    put @1 "         &tmp";
    put @1 "          from  &dsin (drop=__order &decodes2drop))";
    put @1 "         cross join (select * from &outds);";
    put @1 "    quit;";
    %end;
put;
put @1 "*-------------------------------------------------------------------;";
put @1 "* ADD DECODES FROM &CODELISTDS TO &dsin;";
put @1 "*-------------------------------------------------------------------;";
put;    
put;
put @1 "proc sort data=&outds.2;";
put @1 "by  &by &var ;";
put @1 "run;";
put;
put @1 "proc sort data=&dsin;";
put @1 "by  &by &var ;";
put @1 "run;";
put;
put @1 "data &dsin;";
put @1 "  merge &dsin(in=__a drop=__order) &outds.2;";
put @1 "  by  &by  &var  ;";
put @1 "  if __a;";
put @1 "run;";
put;
put;
put @1 "*--------------------------------------------------------------------;";
put @1 "* ADD MODALITIES FROM USER-PROVIDED LIST TO &dsin ";
put @1 "*--------------------------------------------------------------------;";
put;
put @1 "data &outds.2;";
put @1 "  set &outds.2;";
put @1 "  __theid=_n_;";
put @1 "  __tby=1;";
put @1 "run;";
put;
put @1 "data &outds.3;";
put @1 "  set &dsin;";
put @1 "  __order=1;";
put @1 "  __tby=1;";
put @1 "  drop &by  &alldecodes &var &decode &trtvars __order;";
put @1 "run;";
put;
put @1 "data &outds.3;";
put @1 "  set &outds.3;";
put @1 "  if _n_=1;";
put @1 "run;";
put;
put @1 "proc sort data=&outds.3;";
put @1 "  by __tby;";
put @1 "run;";
put;    
put @1 "proc sort data=&outds.2;";
put @1 "  by __tby;";
put @1 "run;";
put;
put @1 "data &outds.4;";
put @1 "  merge &outds.2 &outds.3;";
put @1 "  by __tby;";
put @1 "  __trtid=-1*_n_;";
put @1 "run;";
put;
put @1 "data &dsin;";
put @1 "  set &dsin (in=__a) &outds.4;";
put @1 "  if __a then __theid=0;";
put @1 "  __tby=1;";
put @1 "run;";
put;
put @1 "*-------------------------------------------------------------------;";
put @1 "* CREATE 'TEMPLATE' FOR ALL GROUPING VARIABLES;";
put @1 "*-------------------------------------------------------------------;";
run;



%local tmp;

%if %length(&by.&alldecodes) %then %do;
  %let tmp =  %sysfunc(tranwrd(%sysfunc(compbl(&by &alldecodes )),
           %str( ), %str(,)));
%end;
%if %length(&tmp) %then %do;


data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put @1 "    proc sql noprint;";
put @1 "      create table __grptemplate as";
put @1 "      select distinct ";
put @1 "        &tmp ";
put @1 "      from &outds.2;";
put @1 "      quit;";
put;
run;
%end;
/*%end;*/

%exit:


%mend __usecodesds;

