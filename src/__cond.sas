/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __cond(
outds=,
varid=,
tabwhere=,
unit=,
groupvars4pop=, 
groupvarsn4pop=,
by4pop=,
byn4pop=,
events=N,
trtvars=)/store;

/*

NOTE: labelvar was added to __rrgaddgenvar and seems to be utilized below but it was never added to 
rrg_addcond macro. It was supposed to be the name of the variable which value was to be used as "label"


*/

%local outds varid tabwhere  unit groupvars by  events  trtvars 
       denomvars denomwhere stat allstat indent skipline label 
       templateds  grouping  showfirst where pctfmt labelline 
       keepwithnext asubjid templatewhere show0cnt notcondition labelvar
       groupvars4pop groupvarsn4pop by4pop byn4pop countwhat denomincltrt;

%let by = &by4pop &byn4pop;
%if %length(&by) %then %let by = %sysfunc(compbl(&by));
%let groupvars = &groupvars4pop &groupvarsn4pop;
%if %length(&groupvars) %then %let groupvars = %sysfunc(compbl(&groupvars));

 

data __condv;
set __varinfo (where=(varid=&varid));
run;

%let indent=0;


proc sql noprint;
  select trim(left(templateds)) into:templateds separated by ' ' from  __condv;
  select trim(left(templatewhere)) into:templatewhere separated by ' ' from  __condv;
  select trim(left(where))      into:where      separated by ' ' from  __condv;
  select trim(left(denom))      into:denomvars  separated by ' ' from  __condv;
  select trim(left(denomwhere)) into:denomwhere separated by ' ' from  __condv;
  select labelline              into:labelline  separated by ' ' from  __condv;
  select trim(left(stat))       into:allstat    separated by ' ' from  __condv;
  select trim(left(ovstat))     into:ovstat     separated by ' ' from  __condv;
  select indent                 into:indent     separated by ' ' from  __condv;
  select upcase(skipline)       into:skipline   separated by ' ' from  __condv;
  select trim(left(label))      into:label      separated by ' ' from  __condv;
  select trim(left(labelvar))   into:labelvar   separated by ' ' from  __condv;
  select trim(left(grouping))   into:grouping   separated by ' ' from  __condv;
  select trim(left(pctfmt))     into:pctfmt     separated by ' ' from  __condv;
  select trim(left(subjid))     into:asubjid    separated by ' ' from  __condv;
  select trim(left(show0cnt))   into:show0cnt   separated by ' ' from  __condv;
  select trim(left(keepwithnext)) into:keepwithnext separated by ' ' from  __condv;
  select trim(left(notcondition)) into:notcondition separated by ' ' from  __condv;
  select trim(left(countwhat))  into:countwhat separated by ' ' from  __condv;
  select trim(left(denomincltrt))  into:denomincltrt separated by ' ' from  __condv;
  
 
quit;


%let notcondition=%upcase(&notcondition);
%if &notcondition ne Y %then %let notcondition=N;

%if %length(&asubjid)>0 %then %let unit=&asubjid;

%let stat=&allstat;


%if %length(&where)=0  %then %let where=%str(1=1);
%if %length(&denomwhere)=0  %then %let denomwhere=%str(1=1);
%if %upcase(&grouping)=N %then %do;
    %if %length(&groupvars)>0 %then %let showfirst=Y;
    %let groupvars=;
%end;

%*else %do;
    %if %length(&denomvars)=0 %then %let denomvars=&by4pop &groupvars4pop;
%*end;


data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
length __where $ 2000;
__where = trim(left(symget("where")));

%if %length(&labelvar) %then %do;
put;
put @1 "*-----------------------------------------------------------------------;" ;
put @1 "* DETERMINE LABEL FOR CONDITION;"; 
put @1 "*-----------------------------------------------------------------------;" ;
PUT;
put @1 '%local label4cond;';
put;
put @1 " proc sql noprint;";
put @1 " select distinct &labelvar into: label4cond separated by ' ' ";
put @1 " from __dataset (where=(&tabwhere and &where));";
put @1 "quit;";
put;
%end;

put;
put @1 "*-----------------------------------------------------------------------;" ;
put @1 "* COUNT SUBJECTS SATISFYING CONDITION " __where ";"; 
put @1 "*-----------------------------------------------------------------------;" ;

run;




%if %upcase(&countwhat)=EVENTS %then %do;

    %let events=N;
    
    %__getcntg(datain=__dataset (where=(&tabwhere and &where)), 
              unit=__eventid, 
              group=__tby &groupvars &by __trtid &trtvars, 
              cnt=__cnt, 
              dataout=__condcnt);

%end;

%else %do;

    %__getcntg(datain=__dataset (where=(&tabwhere and &where)), 
              unit=&unit, 
              group=__tby &groupvars &by __trtid &trtvars, 
              cnt=__cnt, 
              dataout=__condcnt);
              
    %if %index(&events,EVENTS) >0  %then %do;
      %__getcntg(datain=__dataset (where=(&tabwhere and &where)), 
                unit=__eventid, 
                group=__tby &groupvars &by __trtid  &trtvars , 
                cnt=__cntevt, 
                dataout=__condcntevt);
    
      %__joinds(data1=__condcnt,
                data2=__condcntevt (drop=__grpid),
            by = &by __trtid &trtvars __tby &groupvars,
              mergetype=INNER,
                dataout=__condcnt);
    
    %end;

%end;

%if %upcase(&grouping)=Y %then %do;

  data _null_;
  file "&rrgpgmpath./&rrguri..sas" mod;
  put;
  put @1 "*-----------------------------------------------------------------------;" ;
  PUT @1 "* ENSURE THAT ALL MODALITIES OF GROUPING VARIABLE ARE REPRESENTED;";
  put @1 "*-----------------------------------------------------------------------;" ;
  put;
  run;
  
  %__getcntg(datain=__dataset (where=(&tabwhere)), 
            unit=&unit, 
            group=__tby &groupvars &by __trtid &trtvars, 
            cnt=__cnt_tmp, 
            dataout=__condcnt_tmplt);
  
  
  
  data _null_;
  file "&rrgpgmpath./&rrguri..sas" mod;
  put;
  put;
  put @1 "proc sort data=__condcnt;";
  put @1 "  by __tby &groupvars &by __trtid &trtvars;";
  put @1 "run;";
  put;
  put @1 "data __condcnt;";
  put @1 "  merge __condcnt(drop=__grpid in =__incc)";
  put @1 "  __condcnt_tmplt (drop=__cnt_tmp);";
  put @1 "  by __tby &groupvars &by __trtid &trtvars;";
  %if %index(&events,EVENTS) >0  %then %do;
  put @1 " if not __incc then do;";
  put @1 "  __cnt=0;";
  put @1 "  __cntevt=0;";
  put @1 "end;";
  %end;
  %else %do;
  put @1 "  if not __incc then __cnt=0;";
  %end;
  put @1 "run;";
  put;
  put;
  run;

%end;

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put @1 "*----------------------------------------------------;";
put @1 "* CALCULATE DENOMINATOR;";
put @1 "*----------------------------------------------------;";
put;
run;


%if &denomincltrt=Y %then %do;
  
    %__getcntg(datain=__dataset (where=(&denomwhere)), 
              unit=&unit, 
              group=__tby  __trtid &trtvars &denomvars, 
              cnt=__denom, 
          dataout=__conddenom);
%end;

%else %do;
    %__getcntg(datain=__dataset (where=(&denomwhere)), 
              unit=&unit, 
              group=__tby   &denomvars, 
              cnt=__denom, 
          dataout=__conddenom);
  
%end;            
      


data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;      
put @1 '%local dsid rc nobs nobsd;';
put @1 '%let dsid=%sysfunc(open(__condcnt));';
put @1 '%let nobs=%sysfunc(attrn(&dsid, NOBS));';
put @1 '%let rc = %sysfunc(close(&dsid));';
put @1 '%let dsid=%sysfunc(open(__conddenom));';
put @1 '%let nobsd=%sysfunc(attrn(&dsid, NOBS));';
put @1 '%let rc = %sysfunc(close(&dsid));';

put;
put @1 '%if &nobs=0 %then %do;';
put @1 "  *----------------------------------------------------;";
put @1 "  * NO RECORDS SATISFYING CONDITION;";
put @1 "  *----------------------------------------------------;";
put;   
put @1 '  %if &nobsd>0 %then %do;';
put @1 "    data __condcnt;";
%if &denomincltrt=Y %then %do;
    put @1 "    set __conddenom (keep= &denomvars __trtid &trtvars __tby);";
%end;
%else %do;
    put @1 "    set __conddenom (keep= &denomvars __tby);";
%end;  
put @1 "    __cnt=0;";
put @1 "    __tby=1;";
put @1 "    __cntevt=0;";

put @1 "    run;";
put @1 '  %end;';
put;
put @1 '  %else %do;';

put @1 "    proc sort data=__dataset (where=(&tabwhere))";
put @1 "     out= __condcnt (keep = &denomvars __trtid &trtvars __tby) ";
put @1 "     nodupkey;";
put @1 "     by  &denomvars __trtid &trtvars __tby;";
put @1 "    run;";
put;
put @1 "    data __conddenom;";
put @1 "      set __condcnt;";
put @1 "      __denom=0;";
put @1 "    run;";
put;
put @1 "    data __condcnt;";
put @1 "      set __condcnt;";
put @1 "      __cnt=0;";
put @1 "      __cntevt=0;";
put @1 "    run;";
put @1 '  %end;';
put;



%if %upcase(&grouping)=Y and %length(&groupvars) %then %do;
 
  %if %length(&groupvars) %then %do;
    %local gvsql ;
    %let gvsql = %sysfunc(compbl(&groupvars));
    %let gvsql = %sysfunc(tranwrd(&gvsql,%str( ),%str(,)));

    put ;
    put @1 "    proc sql noprint nowarn;";
    put @1 "      create table __tmp as select * from __condcnt ";
    put @1 "      cross join (select distinct &gvsql ";
    put @1 "      from __dataset (where=(&tabwhere)));";
    put @1 "      create table __condcnt as select * from __tmp;";
    put @1 "    quit;";
  %end;
%end;
put @1 '%end;';

%* merge ____conddenom with __groupcodes;
%if %sysfunc(exist(__grpcodes_exec)) and %upcase(&grouping)=Y %then %do;
  put @1 'proc sql noprint nowarn;';
  put @1 '  create table __tmp1 as select * from __grpcodes ';
  %if %length(&templatewhere) %then %do;
   put @1 " (where=(&templatewhere))";
  %end;
  put @1 'cross join __pop;';
  put @1 '  create table __tmp as select * from __condcnt';
  put @1 '  natural right join __tmp1;';
  put @1 'create table __condcnt as select * from __tmp;';

  put @1 'quit;';
  put;
  put @1 ' data __condcnt;';
  put @1 ' set __condcnt;';
  put @1 '__tby=1;';
  put @1 'run;';
  put;

%end;

put;
put @1 "*----------------------------------------------------;";
put @1 "* MERGE DENOMINATOR WITH COUNT DATASET;";
put @1 "*----------------------------------------------------;";
put;
run;

%local mtype;
%let mtype=right;
%if %sysfunc(exist(__grpcodes_exec)) and %upcase(&grouping)=Y %then 
  %let mtype=left;

%if &denomincltrt=Y %then %do;

    %__joinds(data1=__condcnt,
              data2=__conddenom,
          by = __tby  &denomvars __trtid &trtvars,
            mergetype=&mtype,
              dataout=__condcnt2);
%end;

%else %do;
    %__joinds(data1=__condcnt,
          data2=__conddenom,
      by = __tby  &denomvars ,
        mergetype=&mtype,
          dataout=__condcnt2);
  
%end;
  
data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put @1 "*----------------------------------------------------;";
put @1 "*TRANSPOSE DATA SET;";
put @1 "*----------------------------------------------------;";
put;
run;

%__joinds(data1=__condcnt2,
          data2=__pop,
      by = &varby &trtvars,
        mergetype=INNER,
          dataout=__condcnt2);

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put @1 "proc sort data=__condcnt2;";
put @1 "by &varby __tby &groupvars;";
put @1 "run;";
put;
put @1 '%local dsid rc numobs;';
put @1 '%let dsid = %sysfunc(open(__condcnt2));';
put @1 '%let numobs = %sysfunc(attrn(&dsid, NOBS));';
put @1 '%let rc = %sysfunc(close(&dsid));';
put;
put @1 '%if &numobs=0 %then %do;';
put @1 "  data &outds;";
put @1 "  if 0;";
put @1 "  run;";
put @1 '  %put -----------------------------------------------------------;';
put @1 '  %put NO RECORDS IN RESULT DATASET : SKIP REST OF MANIPULATION;  ';
put @1 '  %put -----------------------------------------------------------;';
put @1 '  %goto ' "excd&varid.;";
put @1 '%end;';
put;
run;

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
%if %index(&events,EVENTS) >0  %then %do;
put @1 "proc transpose data=__condcnt2 out=__condcnt3 prefix=__cntevt_;";
put @1 "by &by __tby &groupvars ;";
put @1 "id __trtid;";
put @1 "var __cntevt;";
put @1 "run;";
%end;
put;
put @1 "proc transpose data=__condcnt2 out=__condcnt2a prefix=__den_;";
put @1 "by &by __tby &groupvars;";
put @1 "id __trtid;";
put @1 "var __denom;";
put @1 "run;";
put;
put @1 "proc transpose data=__condcnt2 out=__condcnt2 prefix=__cnt_;";
put @1 "by &by __tby &groupvars ;";
put @1 "id __trtid;";
put @1 "var __cnt;";
put @1 "run;";
put;
put @1 "data __condcnt2;";
put @1 "merge __condcnt2 __condcnt2a " @;
%if %index(&events,EVENTS) >0  %then %do;
put "__condcnt3;";
%end;
%else %do;
put ";";
%end;
put @1 "by &by __tby &groupvars ;";
put @1 "run;";
put;
%if %length(&by) %then %do;
%local sqlby;
%let sqlby = %sysfunc(compbl(&by &groupvars));
%let sqlby = %sysfunc(tranwrd(&sqlby, %str( ), %str(,)));

put @1 " *--------------------------------------------;   ";
put @1 " * CROSS JOIN RESULTS WITH ALL &BY MODALITIES;    ";
put @1 " *--------------------------------------------;   ";
put;
put @1 "proc sql noprint;                                 ";
put @1 "create table __bymods as select distinct &sqlby   ";
put @1 "from __dataset (where=(&tabwhere))                "; 
put @1 "order by &sqlby;                                  ";
put @1 "quit;                                             ";   
put;
put @1 "proc sort data = __condcnt2;                      ";
put @1 "by &by &groupvars;                                ";
put @1 "run;                                              ";
put;
put @1 "data __condcnt2;                                  ";
put @1 "merge __condcnt2 (in=__a) __bymods;               ";  
put @1 "by &by &groupvars;                                ";
put @1 "__tby=1;                                          ";
put @1 "run;                                              ";
put;
%end;

%* templateds is not used currently;
%if %length(&templateds) %then %do;
put;
put @1 "data __templateds;";
put @1 "set &templateds;";
put @1 "__tby=1;";
put @1 "run;";
put;
put @1 "proc sort data=__templateds nodupkey;";
put @1 "by &by &groupvars __tby;";
put @1 "run;";
put;
put @1 "data __condcnt2;";
put @1 "merge  __templateds (in=__a) __condcnt2;";
put @1 "by &by &groupvars __tby;";
put @1 "if __a;";
put @1 "__order=1;";
put @1 "run;";
%end;
put;
put;
run;

%local simplestats simpleorder;
data __modelstat;
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
    __order=__i;
    output;
  end;
  call symput('simplestats', cats(__simple));
  call symput('simpleorder', cats(__simpord));

  __overall=1;
  __allstat = upcase(trim(left(symget("ovstat"))));
  do __i =1 to countw(__allstat, ' ');
    __fname = scan(__allstat,__i,' ');
    if index(__fname,'.')>0 then do;
      __modelname = scan(__fname, 1, '.');
      __name =  scan(__fname, 2, '.');
      __model=1;
    end;
    __order=__i;
    output;
  end;
  
run;

%local statf;
%let statf=%str($__rrgbl.);
%if %length(&simplestats) %then %do;
  %if %sysfunc(countw(&simplestats,%str( )))>1 %then %do;
  %let statf = %str($__rrgsf.);
  %end;
%end;

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
length __stat0 $ 20;
put @1 "*----------------------------------------------------;";
put @1 "* CALCULATE CNT AND PERCENT;";
put @1 "*----------------------------------------------------;";
put;
put @1 "data __condcnt2; ";
put @1 "length __col_0 $ 2000 __stat $ 20;";
put @1 "set __condcnt2;";
put @1 'array cnt{*} __cnt_1-__cnt_&maxtrt;';
put @1 'array pct{*} __pct_1-__pct_&maxtrt;';
put @1 'array den{*} __den_1-__den_&maxtrt;';
put @1 'array col{*} $ 2000 __col_1-__col_&maxtrt;';
%if %index(&events,EVENTS) >0  %then %do;
  put @1 'array colevt{*} $ 2000 __colevt_1-__colevt_&maxtrt;';
  put @1 'array cntevt{*} __cntevt_1-__cntevt_&maxtrt;';
  put @1 'array pctevt{*} __pctevt_1-__pctevt_&maxtrt;';
%end;


%local i s0 sord0;
%let sord0=.;
%if %length(&simplestats) %then %do;
  %let s0 = %scan(&simplestats,1,%str( ));
  %let sord0 = %scan(&simpleorder,1,%str( ));
%end;
%else %do;
  %let s0 = N;
  %let sord0 = .;
%end;

put @1 "do __i=1 to dim(cnt);";

%if &notcondition = Y %then %do;
    put @1 "cnt[__i] = den[__i]-cnt[__i];";
%end;


%__fmtcnt(cntvar=cnt[__i], pctvar=pct[__i], 
          denomvar=den[__i], stat=&s0, outvar=col[__i], 
          pctfmt=&pctfmt);
put @1 "end;";

%if %index(&events,EVENTS) >0  %then %do;
  put @1 "do __i=1 to dim(cnt);";      
  %__fmtcnt(cntvar=cntevt[__i], pctvar=pctevt{__i], 
          denomvar=den[__i], stat=N, outvar=colevt[__i],
          pctfmt=&pctfmt);
          
  %if &notcondition = Y %then %do;  
    put @1 "colevt[__i]='';";
  %end;        
  put @1 "end;";
%end;

__stat0 = quote("&s0");
put @1 "__order=&sord0;";
put @1 "__col_0 = put(" __stat0  ", &statf.);";
put @1 "__stat=" __stat0 ";";
%* NOTE: currently, event count will be always placed next to first non-model based statistics;
put @1 "output;";

%if %length(&simplestats) %then %do;
%do i=2 %to %sysfunc(countw(&simplestats, %str( )));
  %let s0 = %scan(&simplestats,&i,%str( ));
  %let sord0 = %scan(&simpleorder,&i,%str( ));

  put @1 "do __i=1 to dim(cnt);"; 
  %__fmtcnt(cntvar=cnt[__i], pctvar=pct[__i], 
            denomvar=den[__i], stat=&s0, outvar=col[__i], 
            pctfmt=&pctfmt);
  put @1 "end;";
  put @1 "__order=&sord0;";
  __stat0 = quote("&s0");
  put @1 "__col_0 = put(" __stat0  ", &statf.);";
  put @1 "__stat=" __stat0 ";";
  put @1 "output;";
%end;
%end;
put @1 "run;";
put;
run;

%*ADD MODEL-BASED STATISTICS;

data __modelstat;
  set __modelstat;
  if __model=1;
run;


%local dsid rc nobs i nmodels;
%let dsid =%sysfunc(open(__modelstat));;
%let nobs = %sysfunc(attrn(&dsid, NOBS));;
%let rc=%sysfunc(close(&dsid));;

%if &nobs>0  %then %do;
  proc sort data=__modelstat;
    by __modelname;
  run;
  
  data __modelstat;
    set __modelstat end=eof;
    by __modelname;
    retain __modelnum ;
    if _n_=1 then __modelnum=0;
    if first.__modelname then __modelnum+1;
    if eof then call symput("nmodels", cats(__modelnum));
  run;


  data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    set __modelstat end=eof;
    if _n_=1 then do;      
      %if %length(&ovstat) %then %do;
      put @1 "  data __overallstats0;";
      put @1 "  if 0;";
      put @1 "  run;";
      %end;
      put;
      put @1 "  data __modelstatr;";
      put @1 "  if 0;";
      put @1 "  run;";
      put;
      put @1 "*-----------------------------------------------------;";
      put @1 "* CREATE A LIST OF REQUESTED MODEL-BASED STATISTICS   ;";
      put @1 "*-----------------------------------------------------;";
      put;
      put @1 "  data __modelstat;";
      put @1 "    length __fname __name   $ 2000;";
      put;
    end;
    
    put @1 "    __overall = " __overall ";";      
    put @1 "    __fname = '" __fname "';";
    put @1 "     __name = '" __name "';";
    put @1 "    __order = " __order ";";
    put @1 "  output;";
    put;
    if eof then do;
      put;
      put @1 "  run;";
      put;
      put;
    end;
    put;
  run;



    data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    put;
    put @1 "*-------------------------------------------------------------;";
    put @1 "* PREPARE DATASET FOR CUSTOM MODEL, REMOVING POOLED TREATMENTS;";
    put @1 "*-------------------------------------------------------------;";
    put;
    put @1 "data __datasetp;";
    /*put @1 "set __dataset(where=(&tabwhere and &where &pooledstr));";*/
    put @1 "set __dataset(where=(&tabwhere &pooledstr));";
    put @1 "  if &where then __condok=1;";
    put @1 "  else __condok=0;";
    put @1 "run;";
    put;
    put @1 "data __bincntds;";
    put @1 "set __condcnt2;";
    put @1 "run;";
    put;
  run;
    


  %do i = 1 %to &nmodels;
  
    data __modelstat0;
      set __modelstat;
      if __modelnum=&i;
      length __fname $ 2000;
      call symput("currentmodel", cats(__modelname));
    run; 
     
    %local nmoddef; 
    %let nmoddef=0;
    
    data __modelp;
      set __varinfo
      (where=  (model = upcase("&currentmodel")));
    run;

    proc sql noprint;
      select count(*) into:nmoddef from __modelp;
    quit;
    
    %if &nmoddef>0 %then %do;
    proc sort data=__modelp nodupkey;
      by model;
    run;  
    %end;
    %else %do;
    data __modelp;
      length name $ 2000;
      name = "&currentmodel";
      parms='';
    run;
    %end;
      
    %local modelds;
    
    data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    length __macroname2  $ 2000;
    set __modelp;
    __macroname2 = cats('%', name,'(');
    put;
    put @1 __macroname2;
    
    put @1 "   trtvar = &trtvars,";

    %if %upcase(&grouping) ne N %then %do; 
       put @1 "   groupvars = &by &groupvars ," ;
    %end;
    %else %do;
       put @1 "   groupvars = &by ," ;
    %end;
 
    put @1 "   dataset = __datasetp,";
    if parms ne '' then do;
      put @1 parms ",";
    end;
    put @1 "   subjid = &subjid);";
    put;
    %local modelds;
    call symput ('modelds', cats(name));
    run;
    
    data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    
    %* collect overall statistics;
    %if %length(&ovstat) %Then %do;
    
    put @1 "*---------------------------------------------------------;";
    put @1 "* ADD OVERALL STATISTICS TO DATASET THAT COLLECTS THEM;";
    put @1 "*---------------------------------------------------------;";
    put;
    put @1 'data __overallstats0;';
    put @1 "length __fname $ 2000;";
    put @1 "set __overallstats0 &modelds(in=__a where=(__overall=1));";
    put @1 "__blockid = &varid;";
    put @1 "if __a then do;";
    put @1 "  __fname = upcase(cats('" "&currentmodel" "','.',__stat_name));";
    /*put @1 "  __grpid=999;";*/
    put @1 "end;";
    put @1 'run;';
    put;
    %end;
    
    run;  
      
   data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    put; 
    put @1 "*---------------------------------------------------------;";
    put @1 "* MERGE LIST OF REQUESTED MODEL-BASED STATISTICS      ;";
    put @1 "* WITH DATASET CREATED BY PLUGIN;";
    put @1 "* KEEP ONLY REQUESTED STATISTICS FROM CURRENT MODEL;";
    put @1 "*---------------------------------------------------------;";
    put;
    put @1 "  data &modelds;";
    put @1 "    length __fname $ 2000;";
    put @1 "    set &modelds;";
    put @1 "    if __overall ne 1;";
    put @1 "    __fname = upcase(cats('" "&currentmodel" "', '.', __stat_name));";
    put @1 "  run;";
    put;
    put @1 "*---------------------------------------------------------;";
    put @1 "* CHECK IF PLUGIN PRODUCED ANY WITHIN-TREATMENT STATISTICS;";
    put @1 "*---------------------------------------------------------;";
    put;
    put @1 '%local dsid rc nobsmdl;';
    put @1 '%let dsid =';
    put @1 '  %sysfunc(open(' "&modelds ));;";
    put @1 '%let nobsmdl = %sysfunc(attrn(&dsid, NOBS));;';
    put @1 '%let rc=%sysfunc(close(&dsid));;';
    put;
    put @1 '%if &nobsmdl>0 %then %do;';    
    put;
    put @1 "  proc sort data=&modelds;";
    put @1 "    by __fname __overall;";
    put @1 "  run;";
    put @1 "  proc sort data=__modelstat;";
    put @1 "    by __fname __overall;";
    put @1 "  run;";
    put;
    put @1 "  data &modelds;";
    put @1 "    length __col_0 __col __tmpcol __tmpcol_0 $ 2000 __tmpalign __tmpal $ 8;";
    put @1 "    merge &modelds (in=__a) __modelstat (in=__b);";
    put @1 "    by __fname __overall;";
    put @1 "    __sid=__stat_order;";
    put @1 "    if __a and __b;";
    put @1 "    __tby=1;";
    put @1 "      __tmpal = __stat_align;";
    put @1 "      __tmpcol = cats(__stat_value);";
    put @1 "    __tmpcol_0 = cats(__stat_label);";
    put @1 "    __tmpal = tranwrd(__tmpal, '//', '-');";
    put @1 "    __nline = countw(__tmpal,'-');";
    put @1 "    if index(__tmpcol_0, '//')=1 then __tmpcol_0='~-2n'||substr(__tmpcol_0, 3);";    
    put @1 "    do __i =1 to __nline;";
    put @1 "       if index(__tmpcol_0, '//')>0 then do;";
    put @1 "         __col_0 = substr(__tmpcol_0, 1, index(__tmpcol_0, '//')-1); ";
    put @1 "         ____tmpcol_0 = substr(__tmpcol_0, index(__tmpcol_0, '//')+2); ";
    put @1 "       end;";
    put @1 "       else do;";
    put @1 "         __col_0 = trim(left(__tmpcol_0)); ";
    put @1 "       end;";
    put @1 "       if index(__tmpcol, '//')>0 then do;";
    put @1 "         __col = substr(__tmpcol, 1, index(__tmpcol, '//')-1); ";
    put @1 "         __tmpcol = substr(__tmpcol, index(__tmpcol, '//')+2); ";
    put @1 "       end;";
    put @1 "       else do;";
    put @1 "         __col = trim(left(__tmpcol)); ";
    put @1 "       end;";
    put @1 "       __sid = __sid + (__i-1)/__nline;";
    put @1 "       __tmpalign = scan(__tmpal,__i, '-');";
    put @1 "       output;";
    put @1 "    end;";
    put @1 "    drop __stat_align __stat_order __stat_label __overall __nline ";
    put @1 "         __tmpal __tmpcol __tmpcol_0;";
    put @1 "  run;";
    PUT;
    put @1 "  proc sort data=&modelds;";
    %if %upcase(&grouping) ne N %then %do; 
    put @1 "  by __order __sid __fname &trtvars &varby &groupby;";
    %end;
    %else %do;
    put @1 "  by __order __sid __fname &trtvars &by ;";
    %end;
    put @1 "  run;";
    put;
    put @1 "  data &modelds (drop = __order rename=(__tmporder=__order));";
    put @1 "  set &modelds;"; 
    %if %upcase(&grouping) ne N %then %do; 
    put @1 "  by __order __sid __fname &trtvars &varby &groupby;";  
    %end;
    %else %do;
    put @1 "  by __order __sid __fname &trtvars &by ;";
    %end;

    put @1 "    retain __tmporder;";
    put @1 "    if first.__order then __tmporder=__order;";
    put @1 "    if first.__sid then __tmporder+0.0001;";
    put @1 "  run;";
    PUT;
    put @1 "*---------------------------------------------------------;";
    put @1 "* ADD PLUGIN-GENERATED STATISTICS TO OTHER STATISTICS;";
    put @1 "*---------------------------------------------------------;";
    put;
    put @1 "  data __modelstatr;";
    put @1 "    set __modelstatr &modelds;";
    put @1 "  run;  ";
    put;
    put @1 '%end;';    
   run;
  %end;
  
   ** transpose model based statistics;
  data _null_;
  file "&rrgpgmpath./&rrguri..sas" mod;
  put;
  put @1 '%local dsid rc nobsmdl;';
  put @1 '%let dsid =';
  put @1 '  %sysfunc(open(' "__modelstatr ));;";
  put @1 '%let nobsmdl = %sysfunc(attrn(&dsid, NOBS));;';
  put @1 '%let rc=%sysfunc(close(&dsid));;';
  put;
  put @1 '%if &nobsmdl>0 %then %do;';     
  run;
 
%__joinds(data1=__modelstatr,
          data2=__poph(keep=&varby &trtvars __trtid),
      by = &varby &trtvars,
        mergetype=INNER,
          dataout=__modelstatr);
  data _null_;
  file "&rrgpgmpath./&rrguri..sas" mod;
  put;
  put @1 "*-----------------------------------------------------------;";
  put @1 "*  TRANSPOSE DATASET WITH MODEL-BASED STATISTICS;";
  put @1 "*-----------------------------------------------------------;";
  put;
  put @1 "proc sort data=__modelstatr ;";
  put @1 "by &by __tby &groupvars  __order __col_0 __fname __tmpalign;";
  put @1 "run;";
  put;
  put @1 "proc transpose data=__modelstatr out=__modelstatra prefix=__col_;";
  put @1 "by &by __tby &groupvars  __order __col_0 __fname __tmpalign;";
  put @1 "id __trtid;";
  put @1 "var __stat_value;";
  put @1 "run;";
  put;
  put;
  put @1 "data __modelstatr;";
  put @1 "set __modelstatra;";
  put @1 "by &by __tby &groupvars  __order __col_0 __fname;";
  put @1 "length __align $ 2000;";
  put @1 "__align ='L';";
  put @1 'do __i=1 to &maxtrt;';
  put @1 "   __align = trim(left(__align))||' '||__tmpalign;";
  put @1 "end;";
  put @1 "drop __i _NAME_;";
  put @1 "run;";
  %if %length(&simplestats) %then %do;
  put @1 "data __condcnt2;";
  put @1 "set __condcnt2 __modelstatr;";
  put @1 "run;";
  %end;
  %else %do;
  put @1 "data __condcnt2;";
  put @1 "set __modelstatr;";
  put @1 "run;";
  %end;
  put;
  put @1 '%end;';
  
  
  
  %if %length(&ovstat) %then %do;
  data _null_;
  file "&rrgpgmpath./&rrguri..sas" mod;
  put; 
  put;
  put @1 "*---------------------------------------------------------;";
  put @1 "* COLLECT REQUESTED OVERALL STATISTICS ;";
  put @1 "* ADD TO DATASETS __OVERALLSTAT;";
  put @1 "*---------------------------------------------------------;";
  put;
  put @1 "proc sort data=__modelstat;";
  put @1 "  by __fname __overall;";
  put @1 "run;";
  put;
  put @1 "proc sort data=__overallstats0;";
  put @1 "  by __fname __overall;";
  put @1 "run;";
  put;
  put @1 "data __overallstats0;";
  put @1 "  merge __overallstats0(in=__a) __modelstat (in=__b);";
  put @1 "  by __fname __overall;";
  put @1 "  if __a and __b;";
  put @1 "run;";
  put;
  put @1 "data __overallstats;";
  put @1 "  set __overallstats __overallstats0;";
  put @1 "run;";
  put;
  %end;
run;
%end;



data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put;


put @1 "proc sort data=__condcnt2;";
put @1 " by &by __tby &groupvars __order;";
put @1 "run;";
put;
put @1 "*----------------------------------------------------;";
put @1 "* DEFINE ALIGNMENT, INDENTATION AND SKIPLINES;";
put @1 "*    CREATE DISPLAY LABEL FOR CONDITION;";
put @1 "*----------------------------------------------------;";

put @1 "data &outds;";
put @1 "  length __col_0 __align $ 2000 __suffix __vtype $ 20 __varlabel $ 2000 __skipline $ 1;";
put @1 "  set __condcnt2 end=eof;";
put @1 "  by &by __tby &groupvars __order ;";
put @1 'array cols{*} $ 2000 __col_1-__col_&maxtrt;';
put @1 "if 0 then do; __i=.; __stat=''; _name_=''; end;";
put @1 "  __varlabel='';";
put @1 "  __suffix='';";
put @1 "  __labelline=&labelline;";
%if &skipline=Y %then %do;
put @1 "  if last.%scan(__tby &groupvars,-1, %str( )) then __suffix='~-2n';";
%end;
put @1 "  __tmprowid=_n_+1;";
put @1 "  __blockid=&varid;";
put @1 "  if __align ='' then do;";
put @1 "    if __stat in ('NPCT', 'NNPCT') then ";
put @1 "       __align = 'L'||repeat(' RD', dim(cols));";
put @1 "    else __align = 'L'||repeat(' D', dim(cols));";
put @1 "  end;";
put @1 "  __keepn=1;";
%if &keepwithnext=Y %then %do;
put @1 "if last.%scan(__tby &groupvars,-1,%str( )) then __keepn=1;";
%end;
%else %do;
put @1 "if last.%scan(__tby &groupvars,-1,%str( )) then __keepn=0;";
%end;
put @1 "  __rowtype=2;";
put @1 "  __order=1;";
put @1 "  __vtype='COND';";
%if &showfirst=Y %then %do;
%* if grouping variables are present but are not to be applied to condition;
%* this ensures that when final sort is applied, condition goes first;
put @1 "  __grptype=0;";
%end;
%else %do;
put @1 "  __grptype=1;";
%end;
put @1 "__grpid=999;";
put @1 "  __skipline=cats('" "&skipline" "');";
length __label $ 2000;
__label = quote(dequote(trim(left(symget("label")))));
%local ngrpv;
%let ngrpv=0;
%if %upcase(&grouping)=N %then %do; %let ngrpv=0; %end;
%else %do;
%if %length(&groupvars) %then 
  %let ngrpv = %sysfunc(countw(&groupvars,%str( )));
%end;

%if &show0cnt=N %then %do;
put @1 "  __iscnt=0;";
put @1 "  do __i=1 to dim(cols);";
put @1 "    if substr(left(cols[__i]),1,1) ne '0' then __iscnt=1;";
put @1 "  end;";
put @1 "  if __iscnt=0 then delete;";
put @1 "  else do;";
%end;

%if %length(&simplestats) %then %do;
  %if &labelline ne 0 %then %do;
  put @1 " if first.%scan(__tby &groupvars,-1, %str( )) then do;";
  %if %length(&labelvar) %then %do;
  put @1 "    __col_0 = strip(symget('label4cond'))||' '||trim(left(__col_0));";
  %end;
  %else %do;
    put @1 "    __col_0 = " __label "||' '||trim(left(__col_0));";
  %end;
  put @1 "  __indentlev=&indent+&ngrpv;";
  put @1 " end;";
  put @1 " else __indentlev=&indent+&ngrpv+1;";
  %end;
  %else %do;
  put @1 "  __indentlev=&indent+1+&ngrpv;";
  put @1 "if __col_0 = '' then __col_0 = put(__stat, $__rrgsf.);";
  put @1 "output;";
  put @1 " if __order=1 and first.%scan(__tby &groupvars,-1, %str( )) then do;";
  %if %length(&labelvar) %then %do;
  put @1 "  __col_0 = strip(symget('label4cond'));";
  %end;
  %else %do;
  put @1 "  __col_0 = " __label ";";
  %end;
  put @1 "  __order = 0.5;";
  put @1 "  __tmprowid = 1;";
  put @1 "  do __i=1 to dim(cols);";
  put @1 "     cols[__i]='';";
  put @1 "  end;";
  put @1 "  __suffix='';";
  put @1 "  __indentlev=&indent+&ngrpv;";
  put @1 "  __vtype='CONDLAB';";
  put @1 "  output;";
  put @1 "end;";
  %end;
%end;
%else %do;
  %if &labelline ne 0 %then %do;
  put @1 " if first.%scan(__tby &groupvars,-1, %str( )) then do;";
  %if %length(&labelvar) %then %do;
  put @1 "    __col_0 = strip(symget('label4cond'))||' '||trim(left(__col_0));";
  %end;
  %else %do;
  put @1 "    __col_0 = " __label "||' '||trim(left(__col_0));";
  %end;
  put @1 " end;";
  put @1 " __indentlev=&indent+&ngrpv+1;";
  %end;
  %else %do;
  put @1 "  __indentlev=&indent+1+&ngrpv;";
  put @1 "if __col_0 = '' then __col_0 = put(__stat, $__rrgsf.);";
  put @1 "output;";
  /*put @1 "if __order=1 and _n_=1 then do;";*/
  put @1 " if __order=1 and first.%scan(__tby &groupvars,-1, %str( )) then do;";
  %if %length(&labelvar) %then %do;
  put @1 "  __col_0 = strip(symget('label4cond'));";
  %end;
  %else %do;
  put @1 "  __col_0 = " __label ";";
  %end;
  put @1 "  __order = 0.5;";
  put @1 "  __tmprowid = 1;";
  put @1 "  do __i=1 to dim(cols);";
  put @1 "     cols[__i]='';";
  put @1 "  end;";
  put @1 "  __suffix='';";
  put @1 "  __indentlev=&indent+&ngrpv;";
  put @1 "  __vtype='CONDLAB';";
  put @1 "  output;";
  put @1 "end;";
  %end;
%end;
%if &show0cnt=N %then %do;
put @1 "  end;";
%end;


put @1 "drop _name_ __i;";
put @1 "run;";
put;
run;


  
data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;  
put '%excd'  "&varid.:";
run;
%mend;

