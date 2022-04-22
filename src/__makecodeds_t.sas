/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __makecodeds_t (vinfods=, dsin=)/store;


%local vinfods varid varname  decode name fmt codelist codes codelistds
       delimiter dsin id var recodemissing desc ID;



data __catv_t;
  set &vinfods (where=(upcase(type)='TRT'));
  run;

proc sql noprint;  
select
  trim(left(name))                 ,
  trim(left(fmt))                  ,
  trim(left(desc))                 ,
  trim(left(codelist))             ,
  trim(left(codelistds))           ,
  trim(left(delimiter))            ,
  VARID                            ,
  trim(left(decode))               
into
  :var                              separated by ' ' ,
  :fmt                              separated by ' ' ,
  :desc                             separated by ' ' ,
  :codes                            separated by ' ' ,
  :codelistds                       separated by ' ' ,
  :delimiter                        separated by ' ' ,
  :ID                               separated by ' ' ,
  :decode                           separated by ' ' from  __catv_t;
quit;

/*
  
  select trim(left(name))        into:var        separated by ' ' from  __catv_t;
  select trim(left(fmt))         into:fmt        separated by ' ' from  __catv_t;
  select trim(left(desc))        into:desc       separated by ' ' from  __catv_t;
  select trim(left(codelist))    into:codes      separated by ' ' from  __catv_t;
  select trim(left(codelistds))  into:codelistds separated by ' ' from  __catv_t;
  select trim(left(delimiter))   into:delimiter   separated by ' ' from  __catv_t;
  select VARID                   into:ID          separated by ' ' from  __catv_t;
  select trim(left(decode))      into:decode      separated by ' ' from  __catv_t;
quit;
*/
%if %length(&codelistds) %then %do;
    data __&codelistds._exec __&codelistds; 
      set &codelistds;
    run;
%end;

%if %length(&codes)=0 or %length(&codelistds) %then %do;
  %goto exit;
%end;



%*-------------------------------------------------------------;
%* FIND OUT TYPE AND LENGTH OF CURRENT ANALYSIS VARIABLE;
%*-------------------------------------------------------------;

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



data __CODES4TRT_exec;
   length string  __tmp $ 2000 __del $ 1 ;
   string = symget("codes");
   retain __order&suff;
   __order&suff=0;
   __del = trim(left(symget("delimiter")));
   do i=1 to length(string);
      %if %upcase(&desc)=Y %then %do;
        __tmp = strip(scan(string, -1*i, __del));
      %end;
      %else %do;
        __tmp = strip(scan(string, i, __del));
      %end;  
      if __tmp ne '' then do; 
        __order&suff+1;
        __trtid=__order&suff;
        output; 
      end;
    end;
run;

%if &rrg_debug=1 %then %do;
  
proc print data=__CODES4TRT_exec;
  title '__CODES4TRT_exec';
run;

%end;



data __CODES4TRT_exec;
  set __CODES4TRT_exec;
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
  keep &var &decode __order&suff  __trtid;
run;


%local tmp ;
%if &vtype=C or %length (&decode) %then %do;
    %let tmp=%str(length);
    %if &vtype=C %then %do;
        %let tmp = &tmp %str(&var $ &vlen);
    %end;
    %if %length (&decode) %then %do;
        %let tmp =&tmp %str (__dec_&trtvar $ &vlend);
    %end;
%end;

data rrgpgmtmp;
length record $ 2000;
keep record;
set __CODES4TRT_exec end=eof;
length __var $ 2000;
%if &vtype=C %then %do; 
    __var = quote(&var);
%end;
%else %do;
    __var=&var;
%end;
if _n_=1 then do;
    record = " "; output;
    record =  "*------------------------------------------------------------------;"; output;
    record =  "* CREATE A DATASET WITH LIST OF CODES FOR &var;"; output;
    record =  "*------------------------------------------------------------------;"; output;
    record = " "; output;
    record =  "data  __CODES4TRT;"; output;
    
    record =  "&tmp ;"; output;
    record = " "; output;

end;


record= "&var = "||strip(__var)|| ";"; output;
%if %length (&decode) %then %do;
     record= "__dec_&trtvar = "|| '"'||strip(&decode)|| '";'; output;
%end;
record= "output;"; output;
record = " "; output;
if eof then do;
   record= "run;"; output;
end;  

run;

proc append data=rrgpgmtmp base=rrgpgm;
run;


%exit:

%mend ;

