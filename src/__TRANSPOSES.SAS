/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __transposes(
  dsin=, 
  varby=,
  groupby=,
  trtvar=,
  overall=0)/store;

%local dsin  varby groupby trtvar overall;
%local i grpstuff ngrp ngrpw tmp tmp2 lastgrplab;
%let ngrp=0;
%let groupby = %lowcase(&groupby);
%let ngrpw=0;
%if %length(&groupby) %then %let ngrpw = %sysfunc(countw(&groupby, %str( )));
%do i=1 %to &ngrpw;
  %let tmp = %scan(&groupby, &i, %str( ));
  %if %index(&tmp, __order_)ne 1 %then %do;
     %let ngrp=%eval(&ngrp+1);
     %let grpstuff=&grpstuff __grplabel_&tmp;
     %let lastgrplab = __grplabel_&tmp;
  %end;
%end;

%local  ntrt;
%if %length(&trtvar)=0 %then %let ntrt=1;
%else %let ntrt = %sysfunc(countw(&trtvar, %str( )));

%* IP 2009-10-06;
  
%* determine skiplines for grouping variables;
proc sql noprint;
  %local grpvar tmp2 numog someskips lastgrpskip;
  %let tmp2=0;
  %let numog=0;
  %let someskips=0;
  %do i=1 %to &ngrpw;
    %let grpvar = %upcase(%scan(&groupby, &i, %str( )));
    %let tmp=;
    select upcase(skipline) into:tmp separated by ' ' from __varinfo
        where upcase(name)="&grpvar";
    %if %length(&tmp) %then %do;
      %let tmp2 = %eval(&tmp2+1);
      %let numog =%eval(&numog+1);
      %local skip&tmp2 grp&tmp2;
      %let skip&tmp2 = &tmp;
      %let grp&tmp2=&grpvar;
      %if "&tmp"="Y" %then %do;
        %let someskips=1;
        %let lastgrpskip=&grpvar;
      %end;  
    %end;  
  %end;
quit;  

 

*** MAKE DATASET LONG AND SKINNY - RECREATE __TRTID ;

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;

%if &overall>0 %then %do;
put '%local i regtrt  ovtrt colovtrt;';
put;
put;

put @1 "proc sql noprint;";
put @1 "  select distinct __trtid into:regtrt separated by ' '";
put @1 "    from __poph(where=(__overall=0));";
put @1 "  select distinct __trtid into:ovtrt separated by ' '";
put @1 "    from __poph(where=(__overall=1));";
put @1 "  select distinct cats('__col_', __trtid) into:colovtrt ";
put @1 "    separated by ' ' from __poph(where=(__overall=1));";
put @1 "quit;";
put;
put;
put @1 "data __all2o;";
put @1 "set __all;";
put @1 "if 0 then __varbylab='';";
put @1 "keep &varby  __varbylab __tby __align";
put @1 "   &groupby ";
put @1 "   &grpstuff ";
put @1 "    __grpid __grptype ";
put @1 '   &colovtrt;';
put @1 "run;";
%end;
put;
put;
put @1 "data __all2;";
put @1 "set &dsin  (where = (__vtype in ('CAT','COND','CONT','OV','CATS')";
put @1 '   and __grpid=ceil(__grpid)));';
put @1 "if 0 then __varbylab='';";
put @1 "length __colx __col0 $ 2000;";
put @1 'array cols{*} __col_1-__col_&maxtrt;';
put @1 'array cnts{*} __cnt_1-__cnt_&maxtrt;';
put @1 'array pcts{*} __pct_1-__pct_&maxtrt;';
put @1 'array cevs{*} __colevt_1-__colevt_&maxtrt;';
put @1 '  __col0=__col_0;';
put @1 '%do i=1 %to &maxtrt;';
put @1 '__trtid=&i;';
put @1 '__colx = cats(__col_&i);';
put @1 '__cnt = __cnt_&i;';
put @1 '__pct = __pct_&i;';
put @1 '__colevt = __colevt_&i;';
put @1 '__nalign = scan(__align, &i+1, ' "' ');";
%if &overall>0 and %length(&trtvar) %then %do;
put @1 ' if __trtid in (&regtrt) then output;';
%end;
%else %do;
put @1 ' output;';
%end;
put @1 '%end;';
put @1 "drop __col_: __pct_: __cnt_: __colevt_:;";
put @1 "run;";
put;
put;
put @1 '***************************************************************;';
put @1 '*** GET ALL COMBINATIONS OF __TRTID AND ALL STATS VARIABLES ;';
put @1 '*** THAT ARE TO BE PLACED IN COLUMNS;';
put @1 '*** --- DATASET __ALL5;';
put @1 '***************************************************************;';
put;
put;
put @1 "proc sort data=__all2 ";
put @1 "    (where = (__vtype in ('CAT','COND','CONT','OV','CATS')))";
put @1 '  nodupkey out = __all3';
put @1 " (keep=__blockid __order __vtype __col0 __varlabel __keepn ) ;";
put @1 'by __blockid __order __col0;';
put @1 'run;';
put;
put @1 'proc sort data=__all2 nodupkey out = __all4(keep=__trtid) ;';
put @1 'by __trtid;';
put @1 'run;';
put;
put @1 'proc sql noprint;';
put @1 'create table __all5 as select * from';
put @1 '__all3 cross join __all4;';
put @1 'quit;';
put;
put;
put @1 'proc sort data=__all5;';
put @1 'by __trtid __blockid __order __vtype __col0;';
put @1 'run;';
put;
put @1 '*** CREATE NEW __NTRTID (COLUMN INDICATOR);';
put;
put @1 'data __all5;';
put @1 'set __all5 end=eof;';
put @1 'by __trtid  __blockid __order  __vtype __col0;';
put @1 '__ntrtid=_n_;';
put @1 "if eof then call symput('maxtrt', cats(__ntrtid));";
put @1 'run;';
put;
put;
put;
put @1 '*** MERGE __NTRTID INTO __ALL2 DATASET;';
put;
put @1 'proc sort data=__all2;';
put @1 'by __trtid __blockid __order __vtype __col0;';
put @1 'run;';
put;
put @1 'data __all6;';
put @1 'merge __all2 __all5(in=__a);';
put @1 'by __trtid __blockid __order __vtype __col0;';
put @1 'if __a;';
put @1 'run;';
put;
put @1 'proc sort data=__all6 out=__all6a (keep=__blockid __vtype )';
put @1 'nodupkey;';
put @1 'by __blockid __vtype ;';
put @1 'run;';
put;
put @1 'proc sort data=__all6 out=__all6b (keep=__blockid __vtype __ntrtid)';
put @1 '  nodupkey;';
put @1 'by __blockid __ntrtid;';
put @1 'run;';
put;
put @1 'data __all6c;';
put @1 'merge __all6a __all6b;';
put @1 'by __blockid __vtype;';
put @1 'run;';
put;
put @1 'proc transpose data=__all6c out=__all7b prefix=__vt_;';
put @1 'var __vtype;';
put @1 'id __ntrtid;';
put @1 'run;';
put;
put @1 'proc sort data=__all6;';
put @1 "by &varby  __varbylab __tby ";
put @1 "  &groupby &grpstuff __grpid  ";
put @1 '  __grptype __indentlev ;';
put @1 'run;';
put;

put @1 'proc transpose data=__all6 out=__all7 prefix=__col_;';
put @1 'var __colx;';
put @1 " by  &varby  __varbylab __tby ";
put @1 "   &groupby &grpstuff  __grpid  ";
put @1 '  __grptype __indentlev ;';
put @1 'id __ntrtid;';
put @1 'run;';
put;


put @1 'proc transpose data=__all6 out=__all7c prefix=__colevt_;';
put @1 'var __colevt;';
put @1 " by  &varby  __varbylab __tby ";
put @1 "   &groupby &grpstuff  __grpid  ";
put @1 '  __grptype __indentlev ;';
put @1 'id __ntrtid;';
put @1 'run;';
put;
put @1 'proc transpose data=__all6 out=__all7a prefix=__al_;';
put @1 'var __nalign;';
put @1 " by  &varby  __varbylab __tby ";
put @1 "  &groupby &grpstuff __grpid  ";
put @1 '  __grptype __indentlev ;';
put @1 'id __ntrtid;';
put @1 'run;';
put;

put;
put @1 "data &dsin;";
put @1 'merge  __all7 __all7a __all7c;';
put @1 "by &varby  __varbylab __tby ";
put @1 "  &groupby &grpstuff __grpid  ";
put @1 '  __grptype __indentlev ;';
put @1 'run;';
put;
/*put "proc print data=__all;  ; title '4iza __all - before'; run;";*/

put @1 "data &dsin;";
put @1 "set &dsin;";
put @1 'length __align $ 2000;';
put @1 'if _n_=1 then set __all7b;';
put @1 'array cols{*} __col_1-__col_&maxtrt;  ';
put @1 'array colevt{*} __colevt_1-__colevt_&maxtrt;  ';
put @1 'array al{*} __al_1-__al_&maxtrt;  ';
put @1 'array vt{*} __vt_1-__vt_&maxtrt;  ';
put @1 "__align = 'L';";
put @1 'do __i=1 to dim(cols);';
%if &overall<=0 or %length(&trtvar) %then %do;
  put @1 "  if vt[__i] in ('CAT', 'COND') and cols[__i]='' ";
  put @1 "     then cols[__i]='0';";
  put @1 "  if vt[__i] in ('CAT', 'COND') and colevt[__i]='' ";
  put @1 "     then colevt[__i]='0';";
%end;
put @1 "  if vt[__i] in ('CONT') and compress(cols[__i],' ,(.)')= '' ";
put @1 "     then cols[__i]='';";
put @1 "  if al[__i]='' then al[__i]='RD';";
put @1 "  __align = trim(left(__align))||' '||trim(left(al[__i]));";
put @1 'end;';
put @1 'run;';
put;
/*put "proc print data=__all;  ; title '4iza __all - after'; run;";*/
put @1 "proc sort data=&dsin;";
put @1 "  by &varby __grptype __tby ";
put @1 "     &groupby &grpstuff __grpid ;";
put @1 'run;';
put;
%if &overall>0 and %length(&trtvar) %then %do;
put;
put @1 '%local i ovrename ovnemiss;';
put @1 '%let ovnemiss=%str(1=0);';
put @1 '%if %length(&colovtrt)>0 %then %do;';
put @1 '%do i=1 %to %sysfunc(countw(&colovtrt,%str( )));';
put @1 '  %let ovrename = &ovrename %scan(&colovtrt,&i, %str( )) %str(=) __col_%eval(&maxtrt+&i);';
put @1 '  %let ovnemiss = &ovnemiss %str(or) %scan(&colovtrt,&i, %str( )) ne ' "'';";
put @1 '%end;';
put @1 '%end;';
put;
put @1 'proc sort data=__all2o (where=(&ovnemiss));';
put @1 "  by &varby __grptype __tby ";
put @1 "     &groupby &grpstuff __grpid ;";
put @1 'run;';
%end;
put @1 "data &dsin ;";
%if &overall>0 and %length(&trtvar) %then %do;
put @1 "  merge &dsin ";
put @1 '   __all2o(rename=(__align = __oldalign &ovrename));';
%do i=1 %to &overall;
%local j;
%let j = %eval(&overall-&i+1);
put @1 "   __align = cats(__align)||' '||cats(scan(__oldalign,-&j,' '));"; 
%end;
%end;
%else %do;
put @1 "  set &dsin;";
%end;
put @1 '  length __col_0 $ 2000 __vtype $ 20;';
put @1 "  by &varby __grptype __tby ";
put @1 "     &groupby &grpstuff __grpid;";
put @1 '  __tmprowid=_n_;';
%if &ngrp>1 %then %do;
put @1 "  if last.%scan(&groupby,-2,%str( )) then __keepn=0;";
put @1 '  else __keepn=1;';
%end;
%else %do;
put @1 '  __keepn=0;';
%end;

put @1 '  __blockid=1;';
put @1 '  __order=1;';
%* IP 2015_04_19;
%* take care of case when there is no groping variables;
put @1 "  __col_0=' ';";
%if %length(&lastgrplab) %then %do;
put @1 "  __col_0=" "&lastgrplab" ";";
%end;
/*put @1 "  __col_0=" "&lastgrplab" ";";*/
** end of IP 2015_04_19;
put @1 '  __labelline=1;';
put @1 "  __skipline='';";
put @1 "  __vtype='MIXED';";
put @1 "  __tmprid = _n_;";
put @1 'drop __al_: __vt_:;';
put @1 'run;';
put;
%if %upcase(&aetable) ne N %then %do;
%if &someskips=1 %then %do;
put @1 "proc sort data=&dsin;";
put @1 "by descending __tmprid;";
put @1 "run;";
put;
put @1 "data &dsin;";
put @1 "set &dsin end=eof;";
put @1 "by descending __tmprid;";
put @1 "__prevgrpid = lag(__grpid);";
%do i=1 %to %eval(&numog-1);
%if &&skip&i=Y %then %do;
put @1 "if  __prevgrpid = %eval(&i+1) and __prevgrpid < __grpid then __skipline='Y';";
put @1 "if  eof and __prevgrpid ne 999 then __skipline='Y';";
%end;
%end;
%if &&skip&numog=Y %then %do;
put @1 "if  __grpid=999  then __skipline='Y';";
%end;
put @1 "run;";
%end;
%end;

%else %do;
  %if &someskips=1 %then %do;
    put @1 "data &dsin;";
    put @1 "set &dsin;";
    %do i=1 %to &numog;
      %if &&skip&i=Y %then %do;
        put @1 "__grplabel_&&grp&i = '~-2n'||cats(__grplabel_&&grp&i);";
      %end;
    %end;  
    put @1 "run;";
  %end;
%end;
put;
put @1 '*** MERGE GROUPING VARIABLE LABELS  INTO UNTRANSPOSED HEADER DATASET;';
put;
put;

put @1 'proc sort data=__all5 out=__all5a(keep=__trtid __ntrtid) nodupkey;';
put @1 'by __trtid __ntrtid;';
put @1 'run;';
put;
%if %length(&varby) %then %do;
put @1 "proc sql noprint;";
put @1 "  create table __all5a as select * from ( select * from __all5)";
put @1 "  cross join ";
put @1 "  (select distinct &varby from __poph);";
put @1 "create table __all5 as select * from __all5a;";
put @1 "quit;";
put;
put @1 "proc sort data=__all5a;";
put @1 "by &varby __trtid;";
put @1 "run;";
put;
%end;
put @1 'data __poph0;';
put @1 'if 0;';
put @1 'run;';
put;
%if &overall>0 and %length(&trtvar) %then %do;
  put @1 'proc sort data=__poph(where=(__trtid in (&ovtrt)))';
  put @1 '  out=__pophov;';
  put @1 'by __trtid;';
  put @1 'run;';

  put;
  put @1 'data __pophov;';
  put @1 'set __pophov;';
  put @1 ' by __trtid;';
  put @1 ' retain __cnt;';
  put @1 ' if _n_=1 then __cnt=0;';
  put @1 ' if first.__trtid then __cnt= __cnt+1;';
  put @1 ' __ntrtid =&maxtrt+__cnt;';
  /*put @1 "__autospan='N';";*/
  /*put @1 "if __rowid=1 then do; __rowid =  &ntrt+2; __nospanh=1; end;";*/
  %* todo: above: if __rowid corresponds to trt column;
  put @1 ' drop __cnt;';
  put @1 'run;';
  put;

  put @1 '%let maxtrt = %eval(&maxtrt+' "&overall);";
%end;
put;


%local i;
%do i=1 %to &ntrt;
%if &overall>0 and %length(&trtvar) %then %do;
  put @1 "proc sort data=__poph(where=(__rowid=&i " ' and __trtid in (&regtrt) )) ';
%end;
%else %do;
put @1 "proc sort data=__poph(where=(__rowid=&i )) ";
%end;
put @1 "    out=__poph&i;";
put @1 "by &varby __trtid;";
put @1 'run;';
put;
put @1 "data __poph&i;";
put @1 "merge __poph&i __all5a;";
put @1 "by &varby __trtid;";
put @1 "run;";
put;
put @1 'data __poph0;';
put @1 "set __poph0 __poph&i;";
/*put @1 '__nospanh=0;';*/
put @1 "run;";
put;
%end; 
put @1 'proc sort data=__all5;';
put @1 'by __blockid;';
put @1 'run;';
put;
put @1 'data __all5;';
put @1 'length __col $ 2000;';
put @1 'set __all5;';
put @1 'by __blockid;';
put @1 'retain __tmp;';
put @1 'if _n_=1 then __tmp=0;';
put @1 "__autospan='N';";
put @1 "__rowid =  &ntrt+1;";
put @1 "__col=cats(dequote(__varlabel));";
put @1 "output;";
put @1 "__rowid =  &ntrt+2;";
put @1 "__col=cats(dequote(__col0));";
put @1 "__autospan='N';";
put @1 "output;";
/*put @1 "__col=cats(dequote(__varlabel))||'__ '||cats(__col0);";*/
/*put @1 '__nospanh=1;';*/
put @1 'run;';
put;
put;
put @1 'data __poph (rename=(__ntrtid=__trtid));';
%if &overall>0 and %length(&trtvar) %then %do;
put @1 'set __poph0 __all5 __pophov;';
%end;
%else %do;
put @1 'set __poph0 __all5;';
%end;
put @1 'drop __trtid;';
put @1 'run;';
put;
put;
put @1 'proc sort data=__poph;';
put @1 'by __rowid __trtid ;';
put @1 'run;';
put;



put @1 '*** UPDATE BREAKOKAT MACRO PARAMETER;';
put;
put @1 'proc sort data=__poph;';
put @1 " by &trtvar __blockid  __order;";
put @1 'run;';
put;
put @1 'data __poph;';
put @1 '  set __poph;';
put @1 "  by &trtvar __blockid __order;";
put @1 '  __cb=.;';
put @1 '  if first.__blockid then __cb=1;';
put @1 'run;';
put;
put @1 "proc sort data=__poph;";
put @1 "  by __trtid;";
put @1 "run;";
put;
put @1 'proc sql noprint;';
put @1 '  select __trtid into:breakokat separated by " " ';
put @1 '    from __poph(where=(__cb=1));';
put @1 'quit;';
put;

run;


%mend;
