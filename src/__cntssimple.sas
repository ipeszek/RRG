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
        show0cnt noshow0cntvals pct4total ordervar;
        



proc sql noprint;
select
  trim(left(decode))                       ,
  trim(left(where))                        ,
  trim(left(popwhere))                     ,
  trim(left(popgrp))                       ,
  trim(left(totalwhere))                   ,
  trim(left(totalgrp))                     ,
  trim(left(name))                         ,
  trim(left(fmt))                          ,
  trim(left(denom))                        ,
  trim(left(denomwhere))                   ,
  upcase(trim(left(denomincltrt)))         ,
  trim(left(stat))                         ,
  dequote(trim(left(totaltext)))           ,
  dequote(trim(left(totalpos)))            ,
  dequote(trim(left(misstext)))            ,
  dequote(trim(left(misspos)))             ,
  dequote(trim(left(showmissing)))         ,
  dequote(trim(left(pct4missing)))         ,
  dequote(trim(left(pct4total)))           ,
  trim(left(pctfmt))                       ,
  trim(left(countwhat))                    ,
  trim(left(show0cnt))                     ,
  trim(left(noshow0cntvals))               ,
  trim(left(ordervar))            
into
  :decode                                   separated by ' ' ,
  :where                                    separated by ' ' ,
  :popwhere                                 separated by ' ' ,
  :popgrp                                   separated by ' ' ,
  :totalwhere                               separated by ' ' ,
  :totalgrp                                 separated by ' ' ,
  :var                                      separated by ' ' ,
  :fmt                                      separated by ' ' ,
  :denomvars                                separated by ' ' ,
  :denomwhere                               separated by ' ' ,
  :denomincltrt                             separated by ' ' ,
  :allstat                                  separated by ' ' ,
  :totaltext                                separated by ' ' ,
  :totalpos                                 separated by ' ' ,
  :misstext                                 separated by ' ' ,
  :misspos                                  separated by ' ' ,
  :showmiss                                 separated by ' ' ,
  :pct4missing                              separated by ' ' ,
  :pct4total                                separated by ' ' ,
  :pctfmt                                   separated by ' ' ,
  :countwhat                                separated by ' ' ,  
  :show0cnt                                 separated by ' ' ,
  :noshow0cntvals                           separated by ' ' ,
  :ordervar                                 separated by ' ' 
  
from &vinfods;  
/*
  select trim(left(decode))                 into:decode          separated by ' '     from &vinfods;
  select trim(left(where))                  into:where           separated by ' '     from &vinfods;
  select trim(left(popwhere))               into:popwhere        separated by ' '     from &vinfods;
  select trim(left(popgrp))                 into:popgrp          separated by ' '    from &vinfods;
  select trim(left(totalwhere))             into:totalwhere      separated by ' '     from &vinfods;
  select trim(left(totalgrp))               into:totalgrp        separated by ' '    from &vinfods;
  select trim(left(name))                   into:var             separated by ' '     from &vinfods;
  select trim(left(fmt))                    into:fmt             separated by ' '     from &vinfods;
  select trim(left(denom))                  into:denomvars       separated by ' '     from &vinfods;
  select trim(left(denomwhere))             into:denomwhere      separated by ' '     from &vinfods;
  select upcase(trim(left(denomincltrt)))   into:denomincltrt    separated by ' '     from &vinfods;
  select trim(left(stat))                   into:allstat         separated by ' '     from &vinfods;
  select dequote(trim(left(totaltext)))     into:totaltext       separated by ' '     from &vinfods;
  select dequote(trim(left(totalpos)))      into:totalpos        separated by ' '     from &vinfods;
  select dequote(trim(left(misstext)))      into:misstext        separated by ' '     from &vinfods;
  select dequote(trim(left(misspos)))       into:misspos         separated by ' '     from &vinfods;
  select dequote(trim(left(showmissing)))   into:showmiss        separated by ' '     from &vinfods;
  select dequote(trim(left(pct4missing)))   into:pct4missing     separated by ' '     from &vinfods;
  select dequote(trim(left(pct4total)))     into:pct4total       separated by ' '     from &vinfods;
  select trim(left(pctfmt))                 into:pctfmt          separated by ' '                       from &vinfods;
  select trim(left(countwhat))              into:countwhat       separated by ' '     from &vinfods;
  select trim(left(show0cnt))               into:show0cnt        separated by ' '     from &vinfods;
  select trim(left(noshow0cntvals))         into:noshow0cntvals  separated by ' '     from &vinfods;
  select trim(left(ordervar))               into:ordervar        separated by ' '     from &vinfods;
 */
quit;  

%if %length(&popgrp)=0 %then %let popgrp=&by4pop &groupvars4pop;
%if %length(&denomvars)=0 %then %let denomvars=&by4pop &groupvars4pop;
%if %length(&totalgrp)=0 %then %let totalgrp = &groupvars;
%if %length(&totalwhere)=0 %then %let totalwhere = %str(not missing(&var));



%let stat=&allstat;  

%if %length(&where)=0  %then %let where=%str(1=1);
%if %length(&popwhere)=0  %then %let popwhere=%str(1=1);
%if %length(&denomwhere)=0  %then %let denomwhere=%str(1=1);


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
   
%if %upcase(&showmiss)=Y or %upcase(&showmiss)=A or %length(&totaltext) %then %do;
        %local dsid rc vnum vtype vlen;
        %let dsid = %sysfunc(open(&defreport_dataset));
        %let vnum = %sysfunc(varnum(&dsid,&var));
        %let vtype=%sysfunc(vartype(&dsid, &vnum));
        %let vlen = %sysfunc(varlen(&dsid, &vnum));
        %let rc = %sysfunc(close(&dsid));
%end;   
   
*********************************************************************;   

data rrgpgmtmp;
length record $ 2000;
keep record;
set &vinfods end=eof;

if _n_=1 then do;
    record=" ";


    %if %upcase(&countwhat)=MAX %then %do;
        record="proc sort data=&ds4var (where=(not missing(&var)));"; output;
        record="  by  __tby __trtid &by &groupvars &unit  __order &var ;"; output;
        record="run;"; output;
        record=" "; output;
        record="data &ds4var;"; output;
        record="  set &ds4var;"; output;
        record="  by __tby __trtid &by &groupvars &unit  __order &var ;"; output;
        record="  if last.%scan(&unit,-1, %str( ));"; output;
        record="run;"; output;
    %end;
    record=" "; output;
    record=" "; output;
    record="*------------------------------------------------------------------;"; output;
    record="* CALCULATE COUNT OF SUBJECTS IN EACH NONMISSING MODALITY OF &VAR;"; output;
    record="*------------------------------------------------------------------;"; output;

    record="*-------------------------------------------------------------------;"; output;
    record="* CALCULATE TOTAL COUNT OF SUBJECTS WITH NONMISSING &VAR;"; output;
    record="*-------------------------------------------------------------------;"; output;



    %__getcntg(
           datain = &ds4var (where=(not missing(&var))), 
             unit =  &unit, 
            group = __tby &groupvars  __order &var &decode &by __trtid &trtvars ,
              cnt = __cnt, 
          dataout = __catcnt);



  
    %__getcntg(
          datain = &ds4var (where=(&totalwhere)), 
            unit = &unit, 
           group = __tby &totalgrp &by __trtid &trtvars  ,
             cnt = __cntnmiss, 
         dataout = __catcntnmiss);


    record=" "; output;
    record="  proc sort data=__catcntnmiss;"; output;
    record="    by &by   &totalgrp __tby;"; output;
    record="  run;"; output;
    record=" "; output;
    record="proc transpose data=__catcntnmiss "; output;
    record="    out=__catcntmiss2 prefix=__cntnmiss_;"; output;
    record="    by &by   &totalgrp __tby;"; output;
    record="    id __trtid;"; output;
    record="    var __cntnmiss;"; output;
    record="  run;"; output;
    record=" "; output;
    record='%if %sysfunc(exist(__grptemplate)) %then %do;'; output;
    record=' proc sort data=__grptemplate;'; output;
    record="  by &by  &totalgrp;"; output;
    record=" run;"; output;
    record=" ";  output;
    record=' data  __catcntmiss2;'; output;
    record="  merge __catcntmiss2 (in=__a )"; output;
    record="    __grptemplate (in=__b keep=&by &groupvars);"; output;
    record="  by &by &totalgrp;"; output;
    record='  __tby=1;'; output;
    record='run; ';    output;
    record='%end;'; output;
    record="*-----------------------------------------------------------;"; output;
    record="* CALCULATE TOTAL COUNT OF SUBJECTS IN VARIABLE POPULATION;"; output;
    record="*-----------------------------------------------------------;"; output;
    record=" "; output;

    %__getcntg(
           datain = &ds4pop (where=(&popwhere)) ,
             unit = &unit, 
            group = __tby __trtid &trtvars &popgrp ,
              cnt = __cntpop, 
          dataout = __catcntpop);
          
    record=" "; output;
    record="    proc sort data=__catcntpop;"; output;
    record="     by  __tby &popgrp ;"; output;
    record="    run;"; output;
    record=" "; output;
    record="    proc transpose data=__catcntpop "; output;
    record="     out=__catcntpop2 prefix=__cntpop_;"; output;
    record="     by  __tby  &popgrp;"; output;
    record="     id __trtid;"; output;
    record="     var __cntpop;"; output;
    record="    run;"; output;
    record=" "; output;
    record="*------------------------------------------------------------------;"; output;
    record="* DETERMINE NUMBER OF MISSING = POPULATION COUNT - NONMISSING COUNT;"; output;
    record="*------------------------------------------------------------------;"; output;
    record=" "; output;

    %if %upcase(&showmiss)=Y or %upcase(&showmiss)=A or %length(&totaltext) %then %do;
       
        %__joinds(
             data1 = __catcntmiss2,
             data2 = __catcntpop2,
                by =  __tby &popgrp,
         mergetype = LEFT,
           dataout = __catcntnmiss3);



        record="data __catcntnmiss3;"; output;
        record="  set __catcntnmiss3;"; output;
        record="  drop __i __cntpop: __cntnmiss: _name_;"; output;
        record='  array  cntpop{*} __cntpop_1-__cntpop_&maxtrt;'; output;
        record='  array  cntnmiss{*} __cntnmiss_1-__cntnmiss_&maxtrt;'; output;
        record='  array  cnt{*} __cnt_1-__cnt_&maxtrt;'; output;
        record='  array  col{*} $ 2000 __col_1-__col_&maxtrt;'; output;
        %if &vtype=C %then %do;
            record="  length &var $ &vlen;"; output;
            record=" if 0 then &var='';"; output;
        %end;
        %else %do;
            record=" if 0 then &var=.;"; output;
        %end;
        record="  __grpid=999;"; output;
        record="  do __i=1 to dim(cnt);"; output;
        record="    if cntnmiss[__i]=. then cntnmiss[__i]=0;"; output;
        record="    cnt[__i]=cntpop[__i]-cntnmiss[__i];"; output;
        record="    col[__i]=compress(put(cnt[__i],12.));"; output;
        record="  end;"; output;
        record=" ";   output;

        %if %upcase(&showmiss)=Y or %upcase(&showmiss)=A %then %do;
            record="  call missing(&var);"; output;
            record=" ";   output;
            record="  __total=0;"; output;
            record="  __missing=1;"; output;
            record="  output;"; output;
        %end;
        record=" ";   output;
        %if %length(&totaltext) %then %do;
            record="    __missing=0;"; output;
            record="    do __i=1 to dim(cnt);"; output;
            record="      if cntnmiss[__i]=. then cntnmiss[__i]=0;"; output;
            record="      cnt[__i]=cntnmiss[__i];"; output;
            record="      col[__i]=compress(put(cnt[__i],12.));"; output;
            record="    end;"; output;
            record="    __total=1;"; output;
            record="    output;"; output;
        %end;
        record=" ";   output;
        record="run;"; output;
        record=" "; output;
    %end;
    record=" "; output;
    record="*------------------------------------------------------------;"; output;
    record="* CALCULATE DENOMINATOR;"; output;
    record="*------------------------------------------------------------;"; output;
    record=" "; output;

      
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
       


    record=" "; output;
    %if &denomincltrt=Y %then %do;   
        record="proc transpose data=__catdenom out=__catdenom2 prefix=__den_;"; output;
        record="    by __tby  &denomvars;"; output;
        record="    id __trtid;"; output;
        record="    var __denom;"; output;
        record="run;"; output;
    %end;

    %else %do;
        record="proc transpose data=__catdenom out=__catdenom2 prefix=__sden_;"; output;
        record="    by __tby  &denomvars;"; output;
        record="    var __denom;"; output;
        record="run;";  output;
    %end;

    record=" "; output;
    record="data &outds.2;"; output;
    record="  set __catcnt;"; output;
    record="  if 0 then __total=0;"; output;
    record="run;"; output;
    record=" "; output;
    record="proc sort data=&outds.2;"; output;
    record="  by &by __tby &groupvars __order &var __grpid &decode __total;"; output;
    record="run;"; output;
    record=" "; output;
    record='%local dsid rc numobs;'; output;
    record='%let dsid = %sysfunc(open('|| "&outds.2));"; output;
    record='%let numobs = %sysfunc(attrn(&dsid, NOBS));'; output;
    record='%let rc = %sysfunc(close(&dsid));'; output;
    record='%if &numobs=0 %then %do;'; output;
    record='  %put -----------------------------------------------------------;'; output;
    record='  %put NO RECORDS IN RESULT DATASET : SKIP REST OF MANIPULATION;  '; output;
    record='  %put -----------------------------------------------------------;'; output;
    record='  %goto '||"excs&varid;"; output;
    record='%end;'; output;
    record=" "; output;
    record="*-------------------------------------------------;"; output;
    record="* TRANSPOSE DATA SET WITH COUNTS OF SUBJECTS;"; output;
    record="*-------------------------------------------------;"; output;
    record=" "; output;
    record="proc transpose data=&outds.2 out=__catcnt3 prefix=__cnt_;"; output;
    record="  by &by __tby &groupvars __order  &var __grpid &decode __total;"; output;
    record="  id __trtid;"; output;
    record="  var __cnt;"; output;
    record="run;"; output;
    record=" "; output;
end;


length __stat0 $ 20;

%if %upcase(&showmiss)=Y or %upcase(&showmiss)=A or %length(&totaltext) %then %do;
    record=" "; output;
    record="*------------------------------------------------------------;"; output;
    record="* ADD DATASET WITH 'TOTAL' COUNT;"; output;
    record="*------------------------------------------------------------;"; output;
    record=" "; output;
    record="data __catcnt3;"; output;
    record="  set __catcnt3 __catcntnmiss3 (in=__a);"; output;
    record=" if 0 then __missing=.;"; output;
    record="  if __a then __totmiss=1;"; output;
    record="  if __total=1 then do;"; output;
    totaltext=quote(cats(totaltext)); 
    record="     __col_0 = "||strip(totaltext)|| ";"; output;
    record="     __order = &totorder;"; output;
    record="  end;"; output;
    record="  if __missing=1 then do;"; output;
    record="    __order = &missorder;"; output;
    record="  end;"; output;
    record=" ";   output;
    record="run;"; output;
    record=" "; output;
%end;
record="*------------------------------------------------------------;"; output;
record="* MERGE DENOMINATOR WITH COUNT DATASET;"; output;
record="* CREATE DISPLAY OF STATISTICS;"; output;
record="*------------------------------------------------------------;"; output;
record=" "; output;
record="proc sort data=__catcnt3;"; output;
record="by __tby  &denomvars;"; output;
record="run;"; output;
record=" "; output;
record="proc sort data=__catdenom2;"; output;
record="by __tby  &denomvars;"; output;
record="run;"; output;
record=" "; output;
record="data &outds;"; output;
record="length __col_0  $ 2000 __stat $ 20;"; output;
record="merge __catcnt3 (in=__a) __catdenom2;"; output;
record="by __tby  &denomvars;"; output;
record="if __a;"; output;
record="drop _name_;"; output;
record=" "; output;
record='array cnt{*} __cnt_1-__cnt_&maxtrt;'; output;
record='array pct{*} __pct_1-__pct_&maxtrt;'; output;
record='array denom{*} __den_1-__den_&maxtrt;'; output;
record='array col{*} $ 2000 __col_1-__col_&maxtrt;'; output;
record=" "; output;


%if &denomincltrt ne Y %then %do;
    record=" "; output;
    record='  do i=1 to dim(denom);'; output;
    record='    denom[i]=__sden_1;'; output;
    record='end;'; output;
%end;  

record=" "; output;
record="if 0 then __total=0;"; output;
record=" "; output;
%local i s0 sord0;
%do i=1 %to %sysfunc(countw(&simplestats,%str( )));
    %let s0 = %scan(&simplestats,&i,%str( ));
    %let sord0 = %scan(&simpleorder,&i,%str( ));
    __stat0 = quote("&s0");
    record="if __total ne 1 then __col_0 = put("||strip( __stat0 )|| ", &statf.);"; output;
    record="__stat=" ||strip(__stat0)|| ";"; output;

    

    %if &pct4missing ne Y and &pct4total ne Y %then %do;
        record="if (not missing(&var) and __total ne 1 )  then do;";  output;   
    %end;
    %else %if &pct4missing ne Y and &pct4total = Y %then %do;
        record="if (not missing(&var) or __total = 1 )  then do;";    output; 
    %end; 
    %else %if &pct4missing = Y and &pct4total ne Y %then %do;
        record="if ( __total ne 1 )  then do;";     output;
    %end; 
    %else %if &pct4missing = Y and &pct4total = Y %then %do;
        record="if 1  then do;";     output;
    %end;  
    record="do __i=1 to dim(cnt);"; output;
    %__fmtcnt(cntvar=cnt[__i], pctvar=pct[__i], 
        denomvar=denom[__i], stat=&s0, outvar=col[__i], pctfmt=&pctfmt);
         
    record="end;  "; output;
    record="end;  "; output;
    record="else do;"; output;
    record="do __i=1 to dim(cnt);"; output;
      %__fmtcnt(cntvar=cnt[__i], pctvar=pct[__i], 
          denomvar=denom[__i], stat=N, outvar=col[__i], pctfmt=&pctfmt);
    record="end;"; output;
    record="end;";     output;
    record="__sid=&sord0;"; output;
    record="output;  "; output;
%end;
record=" "; output;
record="run;"; output;

record="data &outds;"; output;
record="  set &outds;"; output;
record="if 0 then __fordelete=.;"; output;
record='array cnt{*} __cnt_1-__cnt_&maxtrt;'; output;
record='__isdata=0;'; output;

%if %upcase(&show0cnt)= N %then %do;
    %if %length(&noshow0cntvals) %then %do;
        record='      do __i=1 to dim(cnt);'; output;
        record='        if cnt[__i]>0 then __isdata=1;'; output;
        record='      end;  '; output;
        record="  if __isdata=0 and &var in (&noshow0cntvals) then __fordelete=1;"; output;
    %end;
    %else %do;
        record='      do __i=1 to dim(cnt);'; output;
        record='        if cnt[__i]>0 then __isdata=1;'; output;
        record='      end;'; output;
        record='  if __isdata=0 then __fordelete=1;'; output;
    %end;
%end;


record='run;'; output;
if eof then do;

    record=" "; output;
    record='%excs'||strip("&varid.:"); output;
    record=" "; output;
    
end;
run;

proc append data=rrgpgmtmp base=rrgpgm;
run;


%mend;

