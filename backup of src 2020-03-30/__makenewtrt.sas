/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __makenewtrt
  (dsin=, wherein=, dsout=)/store;
  
%local trtinfods dsin dsout numoftrt i wherein ;

proc sort data=__varinfo
  (where=(type='TRT'))
   out=__trtinfo;
by varid;
run;


%local  numdummy;
%let numdummy=0;
proc sql noprint;
  select count(*) into:numdummy separated by ' '
   from __trtinfo
  (where=(name=''));
quit;

proc sort data=__varinfo(where=(type ='NEWTRT')) out=__newtrtinfo;
by varid;
run;


%local dsid rc numtrt;
%local trtvar trtdec;
%local trt1 trtdec1 trtsuff1;

proc sql noprint;
  select count(*) into:numtrt from __varinfo(where=(type='TRT'));
quit;  

%do i=1 %to &numtrt;
  %local trt&i trtdec&i trtsuff&i trtnline&i trtspan&i trtprefix&i trtremove&i;
%end;

data __trtinfo;
set __trtinfo end=eof;
call symput ('trt'||compress(put(_n_,12.)), trim(left(name)));
call symput ('trtdec'||compress(put(_n_,12.)), trim(left(decode)));
call symput ('trtsuff'||compress(put(_n_,12.)), trim(left(suffix)));
call symput ('trtnline'||compress(put(_n_,12.)), trim(left(nline)));
call symput ('trtspan'||compress(put(_n_,12.)), trim(left(autospan)));
call symput ('trtprefix'||compress(put(_n_,12.)), trim(left(label)));
call symput ('trtremove'||compress(put(_n_,12.)), trim(left(delmods)));
run;

%do i=1 %to &numtrt;
  %let trtvar=&trtvar &&trt&i;
  %let trtdec=&trtdec &&trtdec&i;
%end;


%* NUMOFTRT IS NUMBER OF TREATMENT VARIABLES;
%* IF THIS NUMBER IS 0 THEN WE NEED TO CREATE A TREATMENT;
%* VARIABLE (CONSTANT IN DATASET) __TRT WITH DECODE __TRTDEC;
%* IN THIS CASE NO NEED TO CHECK FOR OTHER "POOLED" TREATMENTS;


%if &numtrt=0 or &numdummy>0 %then %do;
data __null;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put @1 "data &dsout;";
__dsin = cats(symget("dsin"));
wherein = cats(symget("wherein"));

put @1 "    set " __dsin ";";
put @1 "    where " wherein ";"; 
put @1 "    length __dec___trt __suff___trt __prefix___trt $ 2000;";
put @1 "    __eventid=_n_;";
put @1 "    __tby=1;";
put @1 "    __theid=0;";
put @1 "    __grouped=0;";
put @1 "    __order=1;";
put @1 "    __trt=1;";
put @1 "    __prefix___trt = '';";
put @1 "    __suff___trt='';";
put @1 "    __autospan='N';";
%if &numtrt=0 %then %do;
put @1 "    __dec___trt='Combined Total';";
put @1 "    __nline___trt='Y';";
%end;
%else %do;
put @1 "    __dec___trt='';";
put @1 "    __nline___trt='N';";
%end;
put @1 "  run;";
put;
run;

%goto exit;

%end;

%local i dsid rc numtrt numntrt;
%let dsid=%sysfunc(open(__newtrtinfo));
%let numntrt = %sysfunc(attrn(&dsid,NOBS));
%let rc = %sysfunc(close(&dsid));
  
%* DETERMINE WHICH TREATMENT VARIABLE IS TO HAVE POOLED GROUP;
%* THE VALUE AND LABEL TO GIVE THIS NEW TREATMENT;
%* AND WHICH TREATMENTS TO POOL;
  
%do i=1 %to &numntrt;
  %local name&i components&i newdec&i newval&i; 
%end; 


data __newtrtinfo;
set __newtrtinfo end=eof;
call symput ('name'||compress(put(_n_,12.)), trim(left(name)));
call symput ('newval'||compress(put(_n_,12.)), trim(left(newvalue)));
call symput ('newdec'||compress(put(_n_,12.)), trim(left(dequote(newlabel))));
call symput ('components'||compress(put(_n_,12.)), trim(left(values)));
run;


data __null;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
__dsin = cats(symget("dsin"));
wherein = cats(symget("wherein"));
%do i=1 %to &numtrt;
length __trtsuff&i __trtprefix&i $ 2000;
__trtsuff&i = symget("trtsuff&i");
__trtsuff&i=quote(trim(left(__trtsuff&i)));
__trtprefix&i = symget("trtprefix&i");
__trtprefix&i=quote(trim(left(__trtprefix&i)));

%end;
%do i=1 %to &numntrt;
length __newdec&i $ 2000;
__newdec&i = symget("newdec&i");
__newdec&i=quote(trim(left(__newdec&i)));
%end;

%if &numntrt=0 %then %do;
put @1 "*------------------------------------------------------------------;";
put @1 "*  NO GROUPED TREATMENTS WERE REQUESTED;";
put @1 "*  JUST CREATE NECESSARY DUMMY VARIABLES;";
put @1 "*------------------------------------------------------------------;";
put;
put @1 "data &dsout;";
put @1 "    set " __dsin ";";
put @1 "    where " wherein ";"; 
put @1 "    __eventid=_n_;";
put @1 "    __tby=1;";
put @1 "    __theid=0;";
put @1 "    __grouped=0;";
put @1 "    __order=1;";
%do i=1 %to &numtrt;
put @1 "    __nline_&&trt&i=cats('" "&&trtnline&i" "');";
put @1 "    __autospan=cats('" "&&trtspan&i" "');";
    %if %length(&&trtdec&i) %then %do;
put @1 "    __dec_&&trt&i = cats(&&trtdec&i);";
    %end;
    %else %do;
put @1 "    __dec_&&trt&i = cats(&&trt&i);";
    %end;
put @1 "    __suff_&&trt&i = " __trtsuff&i ";";
put @1 "    __prefix_&&trt&i = " __trtprefix&i ";";
%end;
put @1 "run;  ";
%end;

%else %do;
put @1 "*-------------------------------------------------------------------;";
put @1 "* CREATE POOLED TREATMENT GROUPS ;";
put @1 "*-------------------------------------------------------------------;";
PUT;    
put @1 "data &dsout;";
put @1 "  length __dec_&name1 $ 2000;";
put @1 "    set " __dsin ";";
put @1 "    where " wherein ";"; 
put @1 "    __tby=1;";
put @1 "    __theid=0;";
put @1 "    __grouped=0;";
put @1 "    __order=1;";
%do i=1 %to &numtrt;
put @1 "    __nline_&&trt&i=cats('" "&&trtnline&i" "');";
put @1 "    __autospan=cats('" "&&trtspan&i" "');";
    %if %length(&&trtdec&i) %then %do;
put @1 "    __dec_&&trt&i = cats(&&trtdec&i);";
    %end;
    %else %do;
put @1 "    __dec_&&trt&i = cats(&&trt&i);";
    %end;
    put @1 "    __prefix_&&trt&i = " __trtprefix&i ";";
    put @1 "    __suff_&&trt&i = " __trtsuff&i ";";
%end;
    
put @1 "  output;";
put @1 "  if &name1 in (&components1) then do;";
put @1 "     &name1=&newval1;";
put @1 "     __dec_&name1 = " __newdec1 ";";
put @1 "     __grouped=1;";
put @1 "     output;";
put @1 "  end;  ";
put @1 "run;";
put;  
%do i=2 %to &numntrt;
put @1 "data &dsout;";
put @1 "  set &dsout;";
put @1 "  length __dec_&&name&i $ 2000;";
put @1 "  output;";
put @1 "  if &&name&i in (&&components&i) then do;";
put @1 "     &&name&i=&&newval&i;";
put @1 "     __dec_&&name&i = " __newdec&i ";";
put @1 "     __grouped=1;";
put @1 "     output;";
put @1 "  end;  ";
put @1 "run;";
%end;
put;

put @1 "data &dsout;";
put @1 "    set &dsout;";
put @1 "    __eventid=_n_;";
put @1 "run;  ";
%end; 
run;

%do i=1 %to &numtrt;
  %if %length(&&trtremove&i)>0 %then %do;
    data __null;
    file "&rrgpgmpath./&rrguri..sas" mod;
    put;
			put @1 "data &dsout;";
			put @1 "set &dsout;";
			put @1 " if &&trt&i in (&&trtremove&i) then delete;";
			put @1 "run;"; 
		run;
  %end;
%end;


%exit:


%mend;    
