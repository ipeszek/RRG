/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

/* %macro __makecodeds_t (vinfods=, varid=, varname=,  dsin=, outds=, id=)/store;*/

%macro __makecodeds_t (vinfods=, dsin=, outds=)/store;


%local vinfods varid varname outds decode name fmt codelist codes codelistds
       delimiter dsin id var recodemissing desc ID;



data __catv_t;
  set &vinfods (where=(upcase(type)='TRT'));
  run;

proc sql noprint;
  select trim(left(name))      into:var    separated by ' ' from  __catv_t;
  select trim(left(fmt))       into:fmt    separated by ' ' from  __catv_t;
  select trim(left(desc))       into:desc    separated by ' ' from  __catv_t;
  select trim(left(codelist))  into:codes  separated by ' ' from  __catv_t;
  select trim(left(codelistds))into:codelistds separated by ' ' from  __catv_t;
  select trim(left(delimiter)) into:delimiter separated by ' ' from  __catv_t;
  select VARID into:ID separated by ' ' from  __catv_t;
  select trim(left(decode))into:decode separated by ' ' from  __catv_t;
quit;

%if %length(&codelistds) %then %do;
  data __&codelistds._exec __&codelistds; 
    set &codelistds;
  run;
%end;

%if %length(&codes)=0 or %length(&codelistds) %then %do;
  %put 4iza codes nor codelistds for TRT not found;
  %goto exit;
%end;



%*-------------------------------------------------------------;
%* FIND OUT TYPE AND LENGTH OF CURRENT ANALYSIS VARIABLE;
%*-------------------------------------------------------------;
%*put 4iza dsin=&dsin var=&var;
%local dsid vlen vnum vtype vnumd vtyped vlend rc suff;
%let vnumd = 0;
%let vlend=2000;
%let  dsid = %sysfunc(open(&dsin));
%PUT 4IZA in __makecodeds_t dsin=&dsin dsid=&dsid;

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

%put 4iza in __makecodeds codes=&codes;

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
        __trtid=__order&suff;
        output; 
      end;
    end;
run;

proc print data=&outds._exec;
  title "4iza &outds._exec in makecodeds_t";
run;

data &outds._exec;
  set &outds._exec;
  %if &vtype=C %then %do;
      length &var $ &vlen;
  %end;
  %if %length (&decode) %then %do;
    length &decode $ 2000;
  %end;
  %if &vtype=C %then %do;
      &var = dequote(trim(left(scan(__tmp,1,'='))));
  %end;
  %else %do;
      &var = scan(__tmp,1,'=')+0;
  %end;
  %if %length (&decode) %then %do;
    &decode = dequote(trim(left(substr(__tmp, index(__tmp,'=')+1))));
  %end;
  %if %length(&fmt) and %length (&decode) %then %do;
      &decode = put(&var, &fmt);
  %end;
  keep __order&suff &var &decode __trtid;
run;

proc print data=__CODES4TRT_EXEC;
  title '4iza __CODES4TRT_EXEC';
run;

%local tmp ;
%let tmp=%str(length);
%if &vtype=C %then %do;
      %let tmp = &tmp %str(&var $ &vlen);
%end;
%if %length (&decode) %then %do;
  %let tmp =&tmp %str (&decode $ &vlend);
%end;

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

put "__order&suff = " __order&suff ";";
put "__trtid = " __order&suff ";";  
put "&var = " __var ";";
%if %length (&decode) %then %do;
  put "&decode = " '"' &decode '";';
%end;
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
put "proc print data=__CODES4TRT;";
put " title '4iza __CODES4TRT';";
put "run;";
put;
put '*** 4iza finished &__CODES4TRT;';
run;

/*
data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    put;
    put @1 "   proc sql noprint;";
    put @1 "   create table __poptmp as  select * from ";
    put @1 "    (select distinct &tmp1";
    put @1 "      from __dataset)";
    put @1 "      cross  join";
    put @1 "    (select distinct &tmp2";
    put @1 "      from __pop);";
    put @1 "   quit;";
    put;  
*/


%exit:

%mend ;

