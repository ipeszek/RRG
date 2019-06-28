/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __makecodeds (vinfods=, varid=, varname=,  dsin=, outds=, id=)/store;
/*
PURPOSE: TO CREATE A DATASET WITH LIST OF CODES OF A VARIABLE

MACRO PARAMETERS:
VINFODS  DATASET WITH PROPERTIES OF VARIABLE FOR WHICH CODELISTDS IS BEING MADE
VARNAME  NAME OF VARIABLE (IN __VARINFO) FOR WHICH CODELISTDS IS BEING MADE 
         USED TO CREATE CODELISTDS FOR GROUPING VARIABLES      
VARID    ID OF VARIABLE (IN __VARINFO) FOR WHICH CODELISTDS IS BEING MADE
         USED (IF VANAME IS LEFT BLANK) FOR ANA;YSIS VARIABLES
DSIN     ANALYSIS DATASET (TO GET TYPE AND LENGTH OF VARIABLE)          
OUTDS    OUTPUT DATASET
ID       FOR GROUPING VARIABLE, INDICATES ORDER OF THESE GROUPING VARIABLES

NOTES:  OUTPUT DATASET HAS THE FOLLOWING STRUCTURE
        __ORDER    &VAR    &DECODE
        (NUM)              (CHAR, $2000)
        
        IF DECODE WAS NOT SPECIFIED FOR &VAR THEN &DECODE=__DISPLAY_&VARID
        (IF VARNAME WAS GIVEN THEN &DECODE = __DISPLAY_&VARNAME)
        &VAR TYPE AND LENGTH ARE THE SAME AS VARIABLE TYPE IN &DATASET
        
        IF CODELISTDS IS SPECIFIED FOR VARIABLE, OR IF LIST OF CODES
        IS NOT PROVDED, THEN THIS MACRO  DOES NOTHING EXCEPT IF CODELIST WAS GIVEN
        THEN THIS MACRO CPIES IT IN RUNTUME INTO __&codelistds._exec AND __&codelistds
        DATASETS


__MAKECODEDS macro flow (2015-12-04)

inputs: 
&dsin specified in rrg_defreport
&varname: name of variable being processed
&varid:   id of variable being processes
&id:     a number passed to macro

If &codelistds is specified for the variable bein gprocessed, then at runtime
this macro copies &codelistds into __&codelistds._exec __&codelistds and exists.

If codelist is not provided in rrg_addcatvar or rrg_addgroup (for the variable being processed)
then macro exits

Otherwise:


AT RUNTIME:

create dataset &outds._exec with the following variables:
   
   &varname (of type and length the same as in input dataset). If &varname not given but varid given 
              then macro determines &varname from __varinfo dataset
   __display_&varname or __display_&varid (if &varname not given), Character length 2000
               this is decode from decodelist. If format was also specified, then 
               formatted value replaces "decoded" value from codelist 
   __order&varname (according to order of modalites in &codelist for the variable,
                   if in rrg_addcatvar desc=Y  then order is reversed (read from right to left)   
   
   If &varname was provided:                
       Updates __varinfo datset to specify decode="__display_&varname" for variable being processed
       Updates __rrgpgminfo dataset to specify  gtemplate="&outds", id=&id                             

   If &varname was not provided (as when calling this macro in cnts macro):
       Updates __catv (which is __varinfo subset on variable being processed)
        to set set codelistds="&outds" and decode="__display_&varid"
  
in GENERATED PROGRAM:

   creates dataset &outds with the same content as runtime dataset &outds._exec.
   But if decode was specified in rrg_addcatvar and it exists in input dataset 
   then length of __display_&varname / __display_&varid is the same as length of decode
   variable input dataset
   
   sorts this dataset by __order&varname



*/

%local vinfods varid varname outds decode name fmt codelist codes codelistds
       delimiter dsin id var recodemissing desc show0cnt
       noshow0cntvals;


/*** ----------------------------------------------------------------------------------------------
this macro is used in __cnts macro and in __rrg_generate macro;
in __cnts macro only &varid is passed to identify the variable (from rrg_addcatvar) 
   for which codelist is being created
   (outds = __catcodes&varid where &varid is id of the variable)
in rrg_generate, varname is passed to identify GROUPING variable for which 
  codelist is being created (outds=__grp_template_&tmp where Ttmp is name of grouping variable)
----------------------------------------------------------------------------------------------------*/


%if %length(&varname) %then %do;
  data __catv;
  set &vinfods (where=(upcase(name)=upcase("&varname")));
  run;
%end;
%else %do;
data __catv;
set &vinfods (where=(varid=&varid));
run;
%end;

proc sql noprint;
  select trim(left(name))      into:var    separated by ' ' from  __catv;
  select trim(left(fmt))       into:fmt    separated by ' ' from  __catv;
  select trim(left(desc))       into:desc    separated by ' ' from  __catv;
  select trim(left(codelist))  into:codes  separated by ' ' from  __catv;
  select trim(left(codelistds))into:codelistds separated by ' ' from  __catv;
  select trim(left(delimiter)) into:delimiter separated by ' ' from  __catv;
  select trim(left(show0cnt)) into:show0cnt separated by ' ' from  __catv;
  select trim(left(noshow0cntvals)) into:noshow0cntvals separated by ' ' from  __catv;
quit;



%if %length(&codelistds) %then %do;
  data __&codelistds._exec __&codelistds; 
    set &codelistds;
  run;
%end;

%if %length(&codes)=0 or %length(&codelistds) %then %goto exit;



%*-------------------------------------------------------------;
%* FIND OUT TYPE AND LENGTH OF CURRENT ANALYSIS VARIABLE;
%*-------------------------------------------------------------;
%*put dsin=&dsin var=&var;
%local dsid vlen vnum vtype vnumd vtyped vlend rc suff;
%let vnumd = 0;
%let vlend=2000;
%let  dsid = %sysfunc(open(&dsin));

%let  vnum = %sysfunc(varnum(&dsid,&var));
%let vtype = %sysfunc(vartype(&dsid, &vnum));
%let  vlen = %sysfunc(varlen(&dsid,&vnum));
%if %length (&decode) %then %do;
  %let  vnumd = %sysfunc(varnum(&dsid,&decode));
%end;  
%if &vnumd>0 %then %do;
  %let vtyped = %sysfunc(vartype(&dsid, &vnumd));
  %let  vlend = %sysfunc(varlen(&dsid,&vnumd));
%end;
%let    rc = %sysfunc(close(&dsid));


%if %length(&varname) %then %do;
    %let decode=__display_&varname;
    %let suff = _&varname;
%end;
%else %do;
    %let decode=__display_&varid;
%end;

data &outds._exec;
   length string  __tmp $ 2000 __del $ 1 ;
   string = symget("codes");
   retain __order&suff;
   __order&suff=0;
   __del = trim(left(symget("delimiter")));
   do i=1 to length(string);
      %if %upcase(&desc)=Y %then %do;
        __tmp = scan(string, -1*i, __del);
      %end;
      %else %do;
        __tmp = scan(string, i, __del);
      %end;  
      if __tmp ne '' then do; 
        __order&suff+1;
        output; 
      end;
    end;
run;

data &outds._exec;
  set &outds._exec;
  %if &vtype=C %then %do;
      length &var $ &vlen;
  %end;
  length &decode $ 2000;
  %if &vtype=C %then %do;
      &var = dequote(trim(left(scan(__tmp,1,'='))));
  %end;
  %else %do;
      &var = scan(__tmp,1,'=')+0;
  %end;
  &decode = dequote(trim(left(substr(__tmp, index(__tmp,'=')+1))));
  %if %length(&fmt) %then %do;
      &decode = put(&var, &fmt);
  %end;
  keep __order&suff &var &decode;
run;

%local tmp ;
%let tmp=%str(length);
%if &vtype=C %then %do;
      %let tmp = &tmp %str(&var $ &vlen);
%end;
%let tmp =&tmp %str (&decode $ &vlend);

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
set &outds._exec end=eof;
length __var $ 2000;
%if &vtype=C %then %do; 
__var = quote(&var);
%end;
%else %do;
__var=&var;
%end;
if _n_=1 then do;
  put;
  put @1 "*------------------------------------------------------------------;";
  put @1 "* CREATE A DATASET WITH LIST OF CODES FOR &var;";
  put @1 "*------------------------------------------------------------------;";
  put;
  put @1 "data &outds;";
  put @1 "&tmp ;";
  put;
end;
put @1 '__show0cnt="Y";';
 
%if %upcase(&show0cnt)= N %then %do;
   
    %if %length(&noshow0cntvals) %then %do;
      put @1 '__show0cnt="N";';
    %end;
    %else %do;
      put @1 '__show0cnt="N";';
      
    %end;
%end;


put "__order&suff = " __order&suff ";";
   
put "&var = " __var ";";
put "&decode = " '"' &decode '";';
put "output;";
put;
if eof then do;
  put "run;";
end;  
put;
run;
  
data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put @1 "proc sort data=&outds;";
put @1 "  by __order&suff;";
put @1 "run;";
put;

put @1 "proc print data=&outds;";
put @1 "title 'dataset from makecodesds';";
put @1 "run;";

run;

%* UPDATE &VINFODS SO NEXT STEPS KNOW ABOUT CREATED DATASET WITH CODES;

%if %length(&varname) %then %do;
  proc sql noprint;
  update  &vinfods set decode="&decode" where upcase(name)=upcase("&varname");
  insert into __rrgpgminfo (key, value, id) values ("gtemplate", "&outds", &id);
  quit;
%end;
%else %do;    
  proc sql noprint;
  update  &vinfods set codelistds="&outds" ;
  update  &vinfods set decode="&decode" ;
  quit;
%end;

%exit:

%mend ;

