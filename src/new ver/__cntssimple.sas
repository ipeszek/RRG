/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __cntssimple (
vinfods=,
ds4var=,
ds4pop=,
ds4denom=,
outds=,
varid=,
unit=,
missorder=,
totorder=)/store;

%* NOTE: CHANGED DEFAULT POPWHERE TO BE 1=1;

%local  vinfods ds4var ds4pop ds4denom  outds varid unit  
        decode where popwhere var fmt denomvars denomwhere allstat totaltext
        totalpos stat popgrp pctfmt showmiss pct4missing totalgrp totalwhere
        misstext misspos missorder totorder countwhat denomincltrt maxtrt
        show0cnt noshow0cntvals pct4total;
        
%__rrgpd(ds=&vinfods, title2=vinfods)



proc sql noprint;
  select trim(left(decode))             into:decode     separated by ' ' 
    from &vinfods;
  select trim(left(where))              into:where      separated by ' '
     from &vinfods;
  select trim(left(popwhere))           into:popwhere   separated by ' ' 
    from &vinfods;
  select trim(left(popgrp))             into:popgrp     separated by ' '
    from &vinfods;
  select trim(left(totalwhere))         into:totalwhere   separated by ' ' 
    from &vinfods;
  select trim(left(totalgrp))           into:totalgrp     separated by ' '
    from &vinfods;

  select trim(left(name))               into:var        separated by ' ' 
    from &vinfods;
  select trim(left(fmt))                into:fmt        separated by ' ' 
    from &vinfods;
  select trim(left(denom))              into:denomvars  separated by ' ' 
    from &vinfods;
  select trim(left(denomwhere))         into:denomwhere separated by ' ' 
    from &vinfods;
  select upcase(trim(left(denomincltrt)))       into:denomincltrt separated by ' ' 
    from &vinfods;
    
    

  select trim(left(stat))               into:allstat    separated by ' ' 
    from &vinfods;
  select dequote(trim(left(totaltext))) into:totaltext  separated by ' ' 
    from &vinfods;
  select dequote(trim(left(totalpos)))  into:totalpos   separated by ' ' 
    from &vinfods;
  select dequote(trim(left(misstext))) into:misstext  separated by ' ' 
    from &vinfods;
  select dequote(trim(left(misspos)))  into:misspos   separated by ' ' 
    from &vinfods;
      
  select dequote(trim(left(showmissing)))  into:showmiss  separated by ' ' 
    from &vinfods;
  select dequote(trim(left(pct4missing)))  into:pct4missing  separated by ' ' 
    from &vinfods;
   select dequote(trim(left(pct4total)))  into:pct4total  separated by ' ' 
    from &vinfods;
  select trim(left(pctfmt))  into:pctfmt   separated by ' ' 
    from &vinfods;
  select trim(left(countwhat))  into:countwhat separated by ' ' 
    from &vinfods;
    
    select trim(left(show0cnt))  into:show0cnt separated by ' ' 
    from &vinfods;
    
    select trim(left(noshow0cntvals))  into:noshow0cntvals separated by ' ' 
    from &vinfods;
    
   /* %put 4iza show0cnt=&show0cnt;
    %put 4iza noshow0cntvals=&noshow0cntvals;
    */
    
  


%if %length(&popgrp)=0 %then %let popgrp=&by4pop &groupvars4pop;
%if %length(&denomvars)=0 %then %let denomvars=&by4pop &groupvars4pop;



%let stat=&allstat;  

%if %length(&where)=0  %then %let where=%str(1=1);
%if %length(&popwhere)=0  %then %let popwhere=%str(1=1);
%if %length(&denomwhere)=0  %then %let denomwhere=%str(1=1);


data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;


%if %upcase(&countwhat)=MAX %then %do;
put @1 "proc sort data=&ds4var (where=(not missing(&var)));";
put @1 "  by  __tby __trtid &by &groupvars &unit  __order &var ;";
put @1 "run;";
put;
put @1 "data &ds4var;";
put @1 "  set &ds4var;";
put @1 "  by __tby __trtid &by &groupvars &unit  __order &var ;";
put @1 "  if last.%scan(&unit,-1, %str( ));";
put @1 "run;";
%end;
put;
put;
put @1 "*------------------------------------------------------------------;";
put @1 "* CALCULATE COUNT OF SUBJECTS IN EACH NONMISSING MODALITY OF &VAR;";
put @1 "*------------------------------------------------------------------;";

  %__getcntg(
       datain = &ds4var (where=(not missing(&var))), 
         unit =  &unit, 
        group = __tby &groupvars  __order &var &decode &by __trtid &trtvars ,
          cnt = __cnt, 
      dataout = __catcnt);


data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put @1 "*-------------------------------------------------------------------;";
put @1 "* CALCULATE TOTAL COUNT OF SUBJECTS WITH NONMISSING &VAR;";
put @1 "*-------------------------------------------------------------------;";

%if %length(&totalgrp)=0 %then %let totalgrp = &groupvars;
%if %length(&totalwhere)=0 %then %let totalwhere = %str(not missing(&var));

  %__getcntg(
      datain = &ds4var (where=(&totalwhere)), 
        unit = &unit, 
       group = __tby &totalgrp &by __trtid &trtvars  ,
         cnt = __cntnmiss, 
     dataout = __catcntnmiss);

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put @1 "  proc sort data=__catcntnmiss;";
put @1 "    by &by   &totalgrp __tby;";
put @1 "  run;";
put;
put @1 "proc transpose data=__catcntnmiss ";
put @1 "    out=__catcntmiss2 prefix=__cntnmiss_;";
put @1 "    by &by   &totalgrp __tby;";
put @1 "    id __trtid;";
put @1 "    var __cntnmiss;";
put @1 "  run;";
put;
put @1 '%if %sysfunc(exist(__grptemplate)) %then %do;';
put @1 ' proc sort data=__grptemplate;';
put @1 "  by &by  &totalgrp;";
put @1 " run;";
put; 
put @1 ' data  __catcntmiss2;';
put @1 "  merge __catcntmiss2 (in=__a )";
put @1 "    __grptemplate (in=__b keep=&by &groupvars);";
put @1 "  by &by &totalgrp;";
put @1 '  __tby=1;';
put @1 'run; ';   
put @1 '%end;';
put @1 "*-----------------------------------------------------------;";
put @1 "* CALCULATE TOTAL COUNT OF SUBJECTS IN VARIABLE POPULATION;";
put @1 "*-----------------------------------------------------------;";
put;

  
  %__getcntg(
       datain = &ds4pop (where=(&popwhere)) ,
         unit = &unit, 
        group = __tby __trtid &trtvars &popgrp ,
          cnt = __cntpop, 
      dataout = __catcntpop);
        
data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put @1 "    proc sort data=__catcntpop;";
put @1 "     by  __tby &popgrp ;";
put @1 "    run;";
put;
put @1 "    proc transpose data=__catcntpop ";
put @1 "     out=__catcntpop2 prefix=__cntpop_;";
put @1 "     by  __tby  &popgrp;";
put @1 "     id __trtid;";
put @1 "     var __cntpop;";
put @1 "    run;";
put;
put @1 "*------------------------------------------------------------------;";
put @1 "* DETERMINE NUMBER OF MISSING = POPULATION COUNT - NONMISSING COUNT;";
put @1 "*------------------------------------------------------------------;";
put;
%if %upcase(&showmiss)=Y or %upcase(&showmiss)=A or %length(&totaltext) %then %do;
%local dsid rc vnum vtype vlen;
%let dsid = %sysfunc(open(&dataset));
%let vnum = %sysfunc(varnum(&dsid,&var));
%let vtype=%sysfunc(vartype(&dsid, &vnum));
%let vlen = %sysfunc(varlen(&dsid, &vnum));
%let rc = %sysfunc(close(&dsid));

%__joinds(
     data1 = __catcntmiss2,
     data2 = __catcntpop2,
        by =  __tby &popgrp,
 mergetype = LEFT,
   dataout = __catcntnmiss3);

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;

put @1 "data __catcntnmiss3;";
put @1 "  set __catcntnmiss3;";
put @1 "  drop __i __cntpop: __cntnmiss: _name_;";
put @1 '  array  cntpop{*} __cntpop_1-__cntpop_&maxtrt;';
put @1 '  array  cntnmiss{*} __cntnmiss_1-__cntnmiss_&maxtrt;';
put @1 '  array  cnt{*} __cnt_1-__cnt_&maxtrt;';
put @1 '  array  col{*} $ 2000 __col_1-__col_&maxtrt;';
%if &vtype=C %then %do;
put @1 "  length &var $ &vlen;";
put @1 " if 0 then &var='';";
%end;
%else %do;
put @1 " if 0 then &var=.;";
%end;
put @1 "  __grpid=999;";
put @1 "  do __i=1 to dim(cnt);";
put @1 "    if cntnmiss[__i]=. then cntnmiss[__i]=0;";
put @1 "    cnt[__i]=cntpop[__i]-cntnmiss[__i];";
put @1 "    col[__i]=compress(put(cnt[__i],12.));";
put @1 "  end;";
put;  

%if %upcase(&showmiss)=Y or %upcase(&showmiss)=A %then %do;
put @1 "  call missing(&var);";
put;  
put @1 "  __total=0;";
put @1 "  __missing=1;";
put @1 "  output;";
%end;
put;  
%if %length(&totaltext) %then %do;
put @1 "    __missing=0;";
put @1 "    do __i=1 to dim(cnt);";
put @1 "      if cntnmiss[__i]=. then cntnmiss[__i]=0;";
put @1 "      cnt[__i]=cntnmiss[__i];";
put @1 "      col[__i]=compress(put(cnt[__i],12.));";
put @1 "    end;";
put @1 "    __total=1;";
put @1 "    output;";
%end;
put;  
put @1 "run;";
put;
%end;
put;
put @1 "*------------------------------------------------------------;";
put @1 "* CALCULATE DENOMINATOR;";
put @1 "*------------------------------------------------------------;";
put;
  
%* default denominator is population count;

%if &denomincltrt=Y %then %do;    

  %__getcntg(
          datain = &ds4denom (where=(&denomwhere)),
            unit = &unit, 
           group = __tby &denomvars __trtid,
             cnt = __denom, 
         dataout = __catdenom);
%end;

%else %do;
  %__getcntg(
          datain = &ds4denom (where=(&denomwhere)),
            unit = &unit, 
           group = __tby &denomvars ,
             cnt = __denom, 
         dataout = __catdenom);
%end;

** todo: currently &denomvars are on top of trtvars;
   

%local simplestats simpleorder;
data _null_;
  length __allstat __fname __name __modelname __simple __simpord $ 2000;
  __allstat = upcase(trim(left(symget("stat"))));
  __overall=0;
  __simple='';
  do __i =1 to countw(__allstat, ' ');
    __fname = scan(__allstat,__i,' ');
    if index(__fname,'.')>0 then do;
      __modelname = scan(__fname, 1, '.');
      __name =  scan(__fname, 2, '.');
      __model=1;
    end;
    else do;
      __name = __fname;
      __model=0;
      __simple = trim(left(__simple))||' '||trim(left(__name));
      __simpord= trim(left(__simpord))||' '||cats(__i);
    end;
    __sorder=__i;
    output;
  end;
  call symput('simplestats', cats(__simple));
  call symput('simpleorder', cats(__simpord));

run;

%local statf;
%let statf=%str($__rrgbl.);
%if %sysfunc(countw(&simplestats, %str( )))>1 %then %do;
%let statf = %str($__rrgsf.);
%end;
   
   
data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
%if &denomincltrt=Y %then %do;   
    put @1 "proc transpose data=__catdenom out=__catdenom2 prefix=__den_;";
    put @1 "    by __tby  &denomvars;";
    put @1 "    id __trtid;";
    put @1 "    var __denom;";
    put @1 "run;";
 
%end;

%else %do;
    put @1 "proc transpose data=__catdenom out=__catdenom2 prefix=__sden_;";
    put @1 "    by __tby  &denomvars;";
    put @1 "    var __denom;";
    put @1 "run;"; 
    
 
    
%end;


put;
put @1 "data &outds.2;";
put @1 "  set __catcnt;";
put @1 "  if 0 then __total=0;";
put @1 "run;";
put;
put @1 "proc sort data=&outds.2;";
put @1 "  by &by __tby &groupvars __order &var __grpid &decode __total;";
put @1 "run;";
put;
put @1 '%local dsid rc numobs;';
put @1 '%let dsid = %sysfunc(open(' "&outds.2));";
put @1 '%let numobs = %sysfunc(attrn(&dsid, NOBS));';
put @1 '%let rc = %sysfunc(close(&dsid));';
put @1 '%if &numobs=0 %then %do;';
put @1 '  %put -----------------------------------------------------------;';
put @1 '  %put NO RECORDS IN RESULT DATASET : SKIP REST OF MANIPULATION;  ';
put @1 '  %put -----------------------------------------------------------;';
put @1 '  %goto ' "excs&varid;";
put @1 '%end;';
put;
put @1 "*-------------------------------------------------;";
put @1 "* TRANSPOSE DATA SET WITH COUNTS OF SUBJECTS;";
put @1 "*-------------------------------------------------;";
put;
put @1 "proc transpose data=&outds.2 out=__catcnt3 prefix=__cnt_;";
put @1 "  by &by __tby &groupvars __order  &var __grpid &decode __total;";
put @1 "  id __trtid;";
put @1 "  var __cnt;";
put @1 "run;";
put;

run;


data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
length __stat0 $ 20;
set &vinfods;

%if %upcase(&showmiss)=Y or %upcase(&showmiss)=A or %length(&totaltext) %then %do;
put;
put @1 "*------------------------------------------------------------;";
put @1 "* ADD DATASET WITH 'TOTAL' COUNT;";
put @1 "*------------------------------------------------------------;";
put;
put @1 "data __catcnt3;";
put @1 "  set __catcnt3 __catcntnmiss3 (in=__a);";
put @1 " if 0 then __missing=.;";
put @1 "  if __a then __totmiss=1;";
put @1 "  if __total=1 then do;";
totaltext=quote(cats(totaltext));
put @1 "     __col_0 = " totaltext ";";
put @1 "     __order = &totorder;";
put @1 "  end;";
put @1 "  if __missing=1 then do;";
put @1 "    __order = &missorder;";
put @1 "  end;";
put;  
put @1 "run;";
put;
%end;
put @1 "*------------------------------------------------------------;";
put @1 "* MERGE DENOMINATOR WITH COUNT DATASET;";
put @1 "* CREATE DISPLAY OF STATISTICS;";
put @1 "*------------------------------------------------------------;";
put;
put @1 "proc sort data=__catcnt3;";
put @1 "by __tby  &denomvars;";
put @1 "run;";
put;
put @1 "proc sort data=__catdenom2;";
put @1 "by __tby  &denomvars;";
put @1 "run;";
put;

put @1 "proc print data = &outds;";
put @1 "title '4iza cntsimple 4 total;";
put @1 "run;";

put @1 "data &outds;";
put @1 "length __col_0  $ 2000 __stat $ 20;";
put @1 "merge __catcnt3 (in=__a) __catdenom2;";
put @1 "by __tby  &denomvars;";
put @1 "if __a;";
put @1 "drop _name_;";
put;
put @1 'array cnt{*} __cnt_1-__cnt_&maxtrt;';
put @1 'array pct{*} __pct_1-__pct_&maxtrt;';

put @1 'array denom{*} __den_1-__den_&maxtrt;';

put @1 'array col{*} $ 2000 __col_1-__col_&maxtrt;';
put;


%if &denomincltrt ne Y %then %do;
  put;
  put @1 '  do i=1 to dim(denom);';
  put @1 '    denom[i]=__sden_1;';
  put @1 'end;';
 
  
%end;  

put;
put @1 "if 0 then __total=0;";
put;
%local i s0 sord0;
%do i=1 %to %sysfunc(countw(&simplestats,%str( )));
  %let s0 = %scan(&simplestats,&i,%str( ));
  %let sord0 = %scan(&simpleorder,&i,%str( ));
  __stat0 = quote("&s0");
  put @1 "if __total ne 1 then __col_0 = put(" __stat0  ", &statf.);";
  put @1 "__stat=" __stat0 ";";

 %if &pct4missing ne Y and &pct4total ne Y %then %do;
  put @1 "if (not missing(&var) and __total ne 1 )  then do;";    
%end;
%else %if &pct4missing ne Y and &pct4total = Y %then %do;
  put @1 "if (not missing(&var) or __total = 1 )  then do;";    
%end; 
%else %if &pct4missing = Y and &pct4total ne Y %do;
  put @1 "if ( __total ne 1 )  then do;";    
%end; 
%else %if &pct4missing = Y and &pct4total = Y %do;
  put @1 "if 1  then do;";    
%end;  
  put @1 "do __i=1 to dim(cnt);";
   %__fmtcnt(cntvar=cnt[__i], pctvar=pct[__i], 
        denomvar=denom[__i], stat=&s0, outvar=col[__i], pctfmt=&pctfmt);
         
  put @1 "end;  ";
  put @1 "end;  ";
  put @1 "else do;";
  put @1 "do __i=1 to dim(cnt);";
    %__fmtcnt(cntvar=cnt[__i], pctvar=pct[__i], 
        denomvar=denom[__i], stat=N, outvar=col[__i], pctfmt=&pctfmt);
  put @1 "end;";
  put @1 "end;";    
  put @1 "__sid=&sord0;";
  put @1 "output;  ";
%end;
put;
put @1 "run;";

put @1 "data &outds;";
put @1 "  set &outds;";
put @1 "if 0 then __fordelete=.;";
put @1 'array cnt{*} __cnt_1-__cnt_&maxtrt;';
put @1 '__isdata=0;';

  %if %upcase(&show0cnt)= N %then %do;
    %if %length(&noshow0cntvals) %then %do;
        put @1 '      do __i=1 to dim(cnt);';
        put @1 '        if cnt[__i]>0 then __isdata=1;';
        put @1 '      end;  ';
        put @1 "  if __isdata=0 and 
          &var in (&noshow0cntvals) 
          then __fordelete=1;";
    %end;
    %else %do;
        put @1 '      do __i=1 to dim(cnt);';
        put @1 '        if cnt[__i]>0 then __isdata=1;';
        put @1 '      end;';
        put @1 '  if __isdata=0 then __fordelete=1;';
      
    %end;
  %end;


put @1 'run;';


put @1 "proc print data = &outds;";
put "title '__cntssimple';";
put "run;";



data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;

put;
put @1 '%excs' "&varid.:";
put;
run;


%mend;

