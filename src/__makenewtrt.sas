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
   from __varinfo
  (where=(type='TRT' and name=''));
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


%local i dsid rc numtrt numntrt;
%let dsid=%sysfunc(open(__newtrtinfo));
%let numntrt = %sysfunc(attrn(&dsid,NOBS));
%let rc = %sysfunc(close(&dsid));
  
%* DETERMINE WHICH TREATMENT VARIABLE IS TO HAVE POOLED GROUP;
%* THE VALUE AND LABEL TO GIVE THIS NEW TREATMENT;
%* AND WHICH TREATMENTS TO POOL;

%* NUMOFTRT IS NUMBER OF TREATMENT VARIABLES;
%* IF THIS NUMBER IS 0 THEN WE NEED TO CREATE A TREATMENT;
%* VARIABLE (CONSTANT IN DATASET) __TRT WITH DECODE __TRTDEC;
%* IN THIS CASE NO NEED TO CHECK FOR OTHER "POOLED" TREATMENTS;

%if   &numntrt>0 %then %do;
  
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
    
%end;    


%if &numtrt=0 or &numdummy>0 %then %do;
    
    data rrgpgmtmp;
    length record $ 2000;
    keep record;
    record = " ";output;
    record =  "data &dsout;";output;
    __dsin = cats(symget("dsin"));
    wherein = cats(symget("wherein"));

    record =  "    set " ||strip(__dsin)|| ";";output;
    record =  "    where " ||strip(wherein)|| ";"; output;
    record =  "    length __dec___trt __suff___trt __prefix___trt $ 2000;";output;
    record =  "    __eventid=_n_;";output;
    record =  "    __tby=1;";output;
    record =  "    __theid=0;";output;
    record =  "    __grouped=0;";output;
    record =  "    __order=1;";output;
    record =  "    __trt=1;";output;
    record =  "    __prefix___trt = '';";output;
    record =  "    __suff___trt='';";output;
    record =  "    __autospan='N';";output;
    %if &numtrt=0 %then %do;
        record =  "    __dec___trt='Combined Total';";output;
        record =  "    __nline___trt='Y';";output;
    %end;
    %else %do;
        record =  "    __dec___trt='';";output;
        record =  "    __nline___trt='N';";output;
    %end;
    record =  "  run;";output;
    record = " ";output;
    run;
    
    proc append data=rrgpgmtmp base=rrgpgm;
    run;

    %goto exit;

%end;


data rrgpgmtmp;
length record $ 2000;
keep record;
record = " "; output;
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
    record =  "*------------------------------------------------------------------;";output;
    record =  "*  NO GROUPED TREATMENTS WERE REQUESTED;";output;
    record =  "*  JUST CREATE NECESSARY DUMMY VARIABLES;";output;
    record =  "*------------------------------------------------------------------;";output;
    record = " ";output;
    record =  "data &dsout;";output;
    record =  "    set " ||strip(__dsin)|| ";";output;
    record =  "    where " ||strip(wherein)|| ";"; output;
    record =  "    __eventid=_n_;";output;
    record =  "    __tby=1;";output;
    record =  "    __theid=0;";output;
    record =  "    __grouped=0;";output;
    record =  "    __order=1;";output;
    %do i=1 %to &numtrt;
        record =  "    __nline_&&trt&i=cats('"|| "&&trtnline&i"|| "');";output;
        record =  "    __autospan=cats('"|| "&&trtspan&i"|| "');";output;
        %if %length(&&trtdec&i) %then %do;
            record =  "    __dec_&&trt&i = cats(&&trtdec&i);";output;
        %end;
        %else %do;
            record =  "    __dec_&&trt&i = cats(&&trt&i);";output;
        %end;
        record =  "    __suff_&&trt&i = " ||strip(__trtsuff&i)|| ";";output;
        record =  "    __prefix_&&trt&i = " ||strip(__trtprefix&i)|| ";";output;
    %end;
    record =  "run;  ";output;
%end;

%else %do;
    record =  "*-------------------------------------------------------------------;";output;
    record =  "* CREATE POOLED TREATMENT GROUPS ;";output;
    record =  "*-------------------------------------------------------------------;";output;
    record = " ";    output;
    record =  "data &dsout;";output;
    record =  "  length __dec_&name1 $ 2000;";output;
    record =  "    set " ||strip(__dsin)|| ";";output;
    record =  "    where " ||strip(wherein)|| ";"; output;
    record =  "    __tby=1;";output;
    record =  "    __theid=0;";output;
    record =  "    __grouped=0;";output;
    record =  "    __order=1;";output;
    %do i=1 %to &numtrt;
        record =  "    __nline_&&trt&i=cats('"|| "&&trtnline&i"|| "');";output;
        record =  "    __autospan=cats('"|| "&&trtspan&i" ||"');";output;
        %if %length(&&trtdec&i) %then %do;
            record =  "    __dec_&&trt&i = cats(&&trtdec&i);";output;
        %end;
        %else %do;
            record =  "    __dec_&&trt&i = cats(&&trt&i);";output;
        %end;
        record =  "    __prefix_&&trt&i = " ||strip(__trtprefix&i)|| ";";output;
        record =  "    __suff_&&trt&i = " ||strip(__trtsuff&i )||";";output;
    %end;
        
    record =  "  output;";output;
    record =  "  if &name1 in (&components1) then do;";output;
    record =  "     &name1=&newval1;";output;
    record =  "     __dec_&name1 = " ||strip(__newdec1) ||";";output;
    record =  "     __grouped=1;";output;
    record =  "     output;";output;
    record =  "  end;  ";output;
    record =  "run;";output;
    record = " ";  output;
    %do i=2 %to &numntrt;
        record =  "data &dsout;";output;
        record =  "  set &dsout;";output;
        record =  "  length __dec_&&name&i $ 2000;";output;
        record =  "  output;";output;
        record =  "  if &&name&i in (&&components&i) then do;";output;
        record =  "     &&name&i=&&newval&i;";output;
        record =  "     __dec_&&name&i = " ||strip(__newdec&i)|| ";";output;
        record =  "     __grouped=1;";output;
        record =  "     output;";output;
        record =  "  end;  ";output;
        record =  "run;";output;
    %end;
    record = " ";output;

    record =  "data &dsout;";output;
    record =  "    set &dsout;";output;
    record =  "    __eventid=_n_;";output;
    record =  "run;  ";output;
%end; 

%do i=1 %to &numtrt;
    %if %length(&&trtremove&i)>0 %then %do;
 
        record = " ";output;
    		record =  "data &dsout;";output;
    		record =  "set &dsout;";output;
    		record =  " if &&trt&i in (&&trtremove&i) then delete;";output;
    		record =  "run;"; output;

    %end;
%end;
run;



proc append data=rrgpgmtmp base=rrgpgm;
run;

%exit:


%mend;    
