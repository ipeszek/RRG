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


data rrgpgmtmp;
length record $ 2000;
keep record;
length __where $ 2000;
__where = trim(left(symget("where")));

%if %length(&labelvar) %then %do;
    record=" "; output;
    record="*-----------------------------------------------------------------------;" ; output;
    record="* DETERMINE LABEL FOR CONDITION;";  output;
    record="*-----------------------------------------------------------------------;" ; output;
    record=" "; output;
    record='%local label4cond;'; output;
    record=" "; output;
    record=" proc sql noprint;"; output;
    record=" select distinct &labelvar into: label4cond separated by ' ' "; output;
    record=" from __dataset (where=(&tabwhere and &where));"; output;
    record="quit;"; output;
    record=" "; output;
%end;

record=" "; output;
record="*-----------------------------------------------------------------------;" ; output;
record="* COUNT SUBJECTS SATISFYING CONDITION "||strip(__where)|| ";";  output;
record="*-----------------------------------------------------------------------;" ; output;

record=" "; output;



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

   
  
    %__getcntg(datain=__dataset (where=(&tabwhere)), 
            unit=&unit, 
            group=__tby &groupvars &by __trtid &trtvars, 
            cnt=__cnt_tmp, 
            dataout=__condcnt_tmplt);
  
  
  
    
    record=" "; output;
    record=" "; output;
    record="proc sort data=__condcnt;"; output;
    record="  by __tby &groupvars &by __trtid &trtvars;"; output;
    record="run;"; output;
    record=" "; output;
    record="data __condcnt;"; output;
    record="  merge __condcnt(drop=__grpid in =__incc)"; output;
    record="  __condcnt_tmplt (drop=__cnt_tmp);"; output;
    record="  by __tby &groupvars &by __trtid &trtvars;"; output;
    %if %index(&events,EVENTS) >0  %then %do;
        record=" if not __incc then do;"; output;
        record="  __cnt=0;"; output;
        record="  __cntevt=0;"; output;
        record="end;"; output;
    %end;
    %else %do;
        record="  if not __incc then __cnt=0;"; output;
    %end;
    record="run;"; output;
    record=" "; output;
    record=" "; output;
   

%end;


record=" "; output;
record="*----------------------------------------------------;"; output;
record="* CALCULATE DENOMINATOR;"; output;
record="*----------------------------------------------------;"; output;
record=" "; output;



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
      



record=" ";       output;
record='%local dsid rc nobs nobsd;'; output;
record='%let dsid=%sysfunc(open(__condcnt));'; output;
record='%let nobs=%sysfunc(attrn(&dsid, NOBS));'; output;
record='%let rc = %sysfunc(close(&dsid));'; output;
record='%let dsid=%sysfunc(open(__conddenom));'; output;
record='%let nobsd=%sysfunc(attrn(&dsid, NOBS));'; output;
record='%let rc = %sysfunc(close(&dsid));'; output;

record=" "; output;
record='%if &nobs=0 %then %do;'; output;
record="  *----------------------------------------------------;"; output;
record="  * NO RECORDS SATISFYING CONDITION;"; output;
record="  *----------------------------------------------------;"; output;
record=" ";    output;
record='  %if &nobsd>0 %then %do;'; output;
record="        data __condcnt;"; output;
%if &denomincltrt=Y %then %do;
    record="        set __conddenom (keep= &denomvars __trtid &trtvars __tby);"; output;
%end;
%else %do;
    record="        set __conddenom (keep= &denomvars __tby);"; output;
%end;  
record="       __cnt=0;"; output;
record="       __tby=1;"; output;
record="       __cntevt=0;"; output;

record="      run;"; output;
record='  %end;'; output;
record=" "; output;
record='  %else %do;'; output;

record="    proc sort data=__dataset (where=(&tabwhere))"; output;
record="     out= __condcnt (keep = &denomvars __trtid &trtvars __tby) "; output;
record="     nodupkey;"; output;
record="     by  &denomvars __trtid &trtvars __tby;"; output;
record="    run;"; output;
record=" "; output;
record="    data __conddenom;"; output;
record="      set __condcnt;"; output;
record="      __denom=0;"; output;
record="    run;"; output;
record=" "; output;
record="    data __condcnt;"; output;
record="      set __condcnt;"; output;
record="      __cnt=0;"; output;
record="      __cntevt=0;"; output;
record="    run;"; output;
record='  %end;'; output;
record=" "; output;



%if %upcase(&grouping)=Y and %length(&groupvars) %then %do;
 
    %if %length(&groupvars) %then %do;
        %local gvsql ;
        %let gvsql = %sysfunc(compbl(&groupvars));
        %let gvsql = %sysfunc(tranwrd(&gvsql,%str( ),%str(,)));

       
        record="    proc sql noprint nowarn;"; output;
        record="      create table __tmp as select * from __condcnt "; output;
        record="      cross join (select distinct &gvsql "; output;
        record="      from __dataset (where=(&tabwhere)));"; output;
        record="      create table __condcnt as select * from __tmp;"; output;
        record="    quit;"; output;
    %end;
%end;

record='%end;'; output;

%* merge ____conddenom with __groupcodes;
%if %sysfunc(exist(__grpcodes_exec)) and %upcase(&grouping)=Y %then %do;
    record='proc sql noprint nowarn;'; output;
    record='  create table __tmp1 as select * from __grpcodes '; output;
    %if %length(&templatewhere) %then %do;
        record=" (where=(&templatewhere))"; output;
    %end;
    record='cross join __pop;'; output;
    record='  create table __tmp as select * from __condcnt'; output;
    record='  natural right join __tmp1;'; output;
    record='create table __condcnt as select * from __tmp;'; output;

    record='quit;'; output;
    record=" "; output;
    record=' data __condcnt;'; output;
    record=' set __condcnt;'; output;
    record='__tby=1;'; output;
    record='run;'; output;
    record=" "; output;

%end;

record=" "; output;
record="*----------------------------------------------------;"; output;
record="* MERGE DENOMINATOR WITH COUNT DATASET;"; output;
record="*----------------------------------------------------;"; output;
record=" "; output;


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
  

record=" "; output;
record="*----------------------------------------------------;"; output;
record="*TRANSPOSE DATA SET;"; output;
record="*----------------------------------------------------;"; output;
record=" "; output;


%__joinds(data1=__condcnt2,
          data2=__pop,
      by = &varby &trtvars,
        mergetype=INNER,
          dataout=__condcnt2);


record=" "; output;
record="proc sort data=__condcnt2;"; output;
record="by &varby __tby &groupvars;"; output;
record="run;"; output;
record=" "; output;
record='%local dsid rc numobs;'; output;
record='%let dsid = %sysfunc(open(__condcnt2));'; output;
record='%let numobs = %sysfunc(attrn(&dsid, NOBS));'; output;
record='%let rc = %sysfunc(close(&dsid));'; output;
record=" "; output;
record='%if &numobs=0 %then %do;'; output;
record="  data &outds;"; output;
record="  if 0;"; output;
record="  run;"; output;
record='  %put -----------------------------------------------------------;'; output;
record='  %put NO RECORDS IN RESULT DATASET : SKIP REST OF MANIPULATION;  '; output;
record='  %put -----------------------------------------------------------;'; output;
record='  %goto '|| "excd&varid.;"; output;
record='%end;'; output;

%if %index(&events,EVENTS) >0  %then %do;
    record="proc transpose data=__condcnt2 out=__condcnt3 prefix=__cntevt_;"; output;
    record="by &by __tby &groupvars ;"; output;
    record="id __trtid;"; output;
    record="var __cntevt;"; output;
    record="run;"; output;
%end;
record=" "; output;
record="proc transpose data=__condcnt2 out=__condcnt2a prefix=__den_;"; output;
record="by &by __tby &groupvars;"; output;
record="id __trtid;"; output;
record="var __denom;"; output;
record="run;"; output;
record=" "; output;
record="proc transpose data=__condcnt2 out=__condcnt2 prefix=__cnt_;"; output;
record="by &by __tby &groupvars ;"; output;
record="id __trtid;"; output;
record="var __cnt;"; output;
record="run;"; output;
record=" "; output;
record="data __condcnt2;"; output;

%if %index(&events,EVENTS) >0  %then %do;
record="merge __condcnt2 __condcnt2a __condcnt3;"; output;
%end;
%else %do;
record="merge __condcnt2 __condcnt2a ;"; output;
%end;

record="by &by __tby &groupvars ;"; output;
record="run;"; output;
record=" "; output;
%if %length(&by) %then %do;
    %local sqlby;
    %let sqlby = %sysfunc(compbl(&by &groupvars));
    %let sqlby = %sysfunc(tranwrd(&sqlby, %str( ), %str(,)));

    record=" *--------------------------------------------;   "; output;
    record=" * CROSS JOIN RESULTS WITH ALL &BY MODALITIES;    "; output;
    record=" *--------------------------------------------;   "; output;
    record=" "; output;
    record="proc sql noprint;                                 "; output;
    record="create table __bymods as select distinct &sqlby   "; output;
    record="from __dataset (where=(&tabwhere))                ";  output;
    record="order by &sqlby;                                  "; output;
    record="quit;                                             ";  output;  
    record=" "; output;
    record="proc sort data = __condcnt2;                      "; output;
    record="by &by &groupvars;                                "; output;
    record="run;                                              "; output;
    record=" "; output;
    record="data __condcnt2;                                  "; output;
    record="merge __condcnt2 (in=__a) __bymods;               ";   output;
    record="by &by &groupvars;                                "; output;
    record="__tby=1;                                          "; output;
    record="run;                                              "; output;
    record=" "; output;
%end;

%* templateds is not used currently;
%if %length(&templateds) %then %do;
    record=" "; output;
    record="data __templateds;"; output;
    record="set &templateds;"; output;
    record="__tby=1;"; output;
    record="run;"; output;
    record=" "; output;
    record="proc sort data=__templateds nodupkey;"; output;
    record="by &by &groupvars __tby;"; output;
    record="run;"; output;
    record=" "; output;
    record="data __condcnt2;"; output;
    record="merge  __templateds (in=__a) __condcnt2;"; output;
    record="by &by &groupvars __tby;"; output;
    record="if __a;"; output;
    record="__order=1;"; output;
    record="run;"; output;
%end;
record=" "; output;
record=" "; output;

length __stat0 $ 20;
record="*----------------------------------------------------;"; output;
record="* CALCULATE CNT AND PERCENT;"; output;
record="*----------------------------------------------------;"; output;
record=" "; output;
record="data __condcnt2; "; output;
record="length __col_0 $ 2000 __stat $ 20;"; output;
record="set __condcnt2;"; output;
record='array cnt{*} __cnt_1-__cnt_&maxtrt;'; output;
record='array pct{*} __pct_1-__pct_&maxtrt;'; output;
record='array den{*} __den_1-__den_&maxtrt;'; output;
record='array col{*} $ 2000 __col_1-__col_&maxtrt;'; output;
%if %index(&events,EVENTS) >0  %then %do;
    record='array colevt{*} $ 2000 __colevt_1-__colevt_&maxtrt;'; output;
    record='array cntevt{*} __cntevt_1-__cntevt_&maxtrt;'; output;
    record='array pctevt{*} __pctevt_1-__pctevt_&maxtrt;'; output;
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

record="do __i=1 to dim(cnt);"; output;

%if &notcondition = Y %then %do;
    record="cnt[__i] = den[__i]-cnt[__i];"; output;
%end;


%__fmtcnt(cntvar=cnt[__i], pctvar=pct[__i], 
          denomvar=den[__i], stat=&s0, outvar=col[__i], 
          pctfmt=&pctfmt);
record="end;"; output;

%if %index(&events,EVENTS) >0  %then %do;
    record="do __i=1 to dim(cnt);";   output;    
    %__fmtcnt(cntvar=cntevt[__i], pctvar=pctevt{__i], 
            denomvar=den[__i], stat=N, outvar=colevt[__i],
            pctfmt=&pctfmt);
            
    %if &notcondition = Y %then %do;  
        record="colevt[__i]='';"; output;
    %end;        
    record="end;"; output;
%end;

__stat0 = quote("&s0"); 
record="__order=&sord0;"; output;
record="__col_0 = put(" ||strip(__stat0)||  ", &statf.);"; output;
record="__stat="||strip(__stat0)|| ";"; output;
%* NOTE: currently, event count will be always placed next to first non-model based statistics;
record="output;"; output;

%if %length(&simplestats) %then %do;
    %do i=2 %to %sysfunc(countw(&simplestats, %str( )));
        %let s0 = %scan(&simplestats,&i,%str( ));
        %let sord0 = %scan(&simpleorder,&i,%str( ));

        record="do __i=1 to dim(cnt);";  output;
        %__fmtcnt(cntvar=cnt[__i], pctvar=pct[__i], 
                  denomvar=den[__i], stat=&s0, outvar=col[__i], 
                  pctfmt=&pctfmt);
        record="end;"; output;
        record="__order=&sord0;"; output;
        __stat0 = quote("&s0"); 
        record="__col_0 = put("||strip(__stat0)||  ", &statf.);"; output;
        record="__stat=" ||strip(__stat0)|| ";"; output;
        record="output;"; output;
    %end;
%end;
record="run;"; output;
record=" "; output;
run;

proc append data=rrgpgmtmp base=rrgpgm;
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


    data rrgpgmtmp;
    length record $ 2000;
    keep record;
    set __modelstat end=eof;
    if _n_=1 then do;      
      %if %length(&ovstat) %then %do;
          record="  data __overallstats0;"; output;
          record="  if 0;"; output;
          record="  run;"; output;
      %end;
      record=" "; output;
      record="  data __modelstatr;"; output;
      record="  if 0;"; output;
      record="  run;"; output;
      record=" "; output;
      record="*-----------------------------------------------------;"; output;
      record="* CREATE A LIST OF REQUESTED MODEL-BASED STATISTICS   ;"; output;
      record="*-----------------------------------------------------;"; output;
      record=" "; output;
      record="  data __modelstat;"; output;
      record="    length __fname __name   $ 2000;"; output;
      record=" "; output;
    end;
    
    record="    __overall = " ||put(__overall,best.)|| ";";       output;
    record="    __fname = '"||strip(__fname)|| "';"; output;
    record="     __name = '" ||strip(__name)|| "';"; output;
    record="    __order = "||put( __order, best.)|| ";"; output;
    record="  output;"; output;
    record=" "; output;
    if eof then do;
      record=" "; output;
      record="  run;"; output;
      record=" "; output;
      record=" "; output;
      
      record=" "; output;
      record="*-------------------------------------------------------------;"; output;
      record="* PREPARE DATASET FOR CUSTOM MODEL, REMOVING POOLED TREATMENTS;"; output;
      record="*-------------------------------------------------------------;"; output;
      record=" "; output;
      record="data __datasetp;"; output;
      record="set __dataset(where=(&tabwhere &pooledstr));"; output;
      record="  if &where then __condok=1;"; output;
      record="  else __condok=0;"; output;
      record="run;"; output;
      record=" "; output;
      record="data __bincntds;"; output;
      record="set __condcnt2;"; output;
      record="run;"; output;
      record=" "; output;
    end;
    run;
    
    proc append data=rrgpgmtmp base=rrgpgm;
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
      

    
        data rrgpgmtmp;
        length record $ 2000;
        keep record;
        set __modelp end=eof;
        record=" "; output;
        record=strip(cats('%', name,'(')); output;
        
        record="   trtvar = &trtvars,"; output;

        %if %upcase(&grouping) ne N %then %do; 
            record="   groupvars = &by &groupvars ," ; output;
        %end;
        %else %do;
            record="   groupvars = &by ," ; output;
        %end;
 
        record="   dataset = __datasetp,"; output;
        if parms ne '' then do;
         record=strip(parms)|| ","; output;
        end;
        record="   subjid = &subjid);"; output;
        record=" "; output;
       
        
        %* collect overall statistics;
        
        %if %length(&ovstat) %Then %do;
        
            record="*---------------------------------------------------------;"; output;
            record="* ADD OVERALL STATISTICS TO DATASET THAT COLLECTS THEM;"; output;
            record="*---------------------------------------------------------;"; output;
            record=" "; output;
            record='data __overallstats0;'; output;
            record="length __fname $ 2000;"; output;
            record="set __overallstats0 "||strip(name)||"(in=__a where=(__overall=1));"; output;
            record="__blockid = &varid;"; output;
            record="if __a then do;"; output;
            record="  __fname = upcase(cats('"||strip("&currentmodel")|| "','.',__stat_name));"; output;
            record="end;"; output;
            record='run;'; output;
            record=" "; output;
        %end;
    
        record=" ";  output;
        record="*---------------------------------------------------------;"; output;
        record="* MERGE LIST OF REQUESTED MODEL-BASED STATISTICS      ;"; output;
        record="* WITH DATASET CREATED BY PLUGIN;"; output;
        record="* KEEP ONLY REQUESTED STATISTICS FROM CURRENT MODEL;"; output;
        record="*---------------------------------------------------------;"; output;
        record=" "; output;
        record="  data "||strip(name)||";"; output;
        record="    length __fname $ 2000;"; output;
        record="    set "||strip(name)||";"; output;
        record="    if __overall ne 1;"; output;
        record="    __fname = upcase(cats('"||strip("&currentmodel")|| "', '.', __stat_name));"; output;
        record="  run;"; output;
        record=" "; output;
        record="*---------------------------------------------------------;"; output;
        record="* CHECK IF PLUGIN PRODUCED ANY WITHIN-TREATMENT STATISTICS;"; output;
        record="*---------------------------------------------------------;"; output;
        record=" "; output;
        record='%local dsid rc nobsmdl;'; output;
        record='%let dsid ='; output;
        record='  %sysfunc(open('||strip(name)||" ));;"; output;
        record='%let nobsmdl = %sysfunc(attrn(&dsid, NOBS));;'; output;
        record='%let rc=%sysfunc(close(&dsid));;'; output;
        record=" "; output;
        record='%if &nobsmdl>0 %then %do;';     output;
        record=" "; output;
        record="  proc sort data="||strip(name)||";"; output;
        record="    by __fname __overall;"; output;
        record="  run;"; output;
        record="  proc sort data=__modelstat;"; output;
        record="    by __fname __overall;"; output;
        record="  run;"; output;
        record=" "; output;
        record="  data "||strip(name)||";"; output;
        record="    length __col_0 __col __tmpcol __tmpcol_0 $ 2000 __tmpalign __tmpal $ 8;"; output;
        record="    merge "||strip(name)||" (in=__a) __modelstat (in=__b);"; output;
        record="    by __fname __overall;"; output;
        record="    __sid=__stat_order;"; output;
        record="    if __a and __b;"; output;
        record="    __tby=1;"; output;
        record="      __tmpal = __stat_align;"; output;
        record="      __tmpcol = cats(__stat_value);"; output;
        record="    __tmpcol_0 = cats(__stat_label);"; output;
        record="    __tmpal = tranwrd(__tmpal, '//', '-');"; output;
        record="    __nline = countw(__tmpal,'-');"; output;
        record="    if index(__tmpcol_0, '//')=1 then __tmpcol_0='~-2n'||substr(__tmpcol_0, 3);";    output; 
        record="    do __i =1 to __nline;"; output;
        record="       if index(__tmpcol_0, '//')>0 then do;"; output;
        record="         __col_0 = substr(__tmpcol_0, 1, index(__tmpcol_0, '//')-1); "; output;
        record="         ____tmpcol_0 = substr(__tmpcol_0, index(__tmpcol_0, '//')+2); "; output;
        record="       end;"; output;
        record="       else do;"; output;
        record="         __col_0 = trim(left(__tmpcol_0)); "; output;
        record="       end;"; output;
        record="       if index(__tmpcol, '//')>0 then do;"; output;
        record="         __col = substr(__tmpcol, 1, index(__tmpcol, '//')-1); "; output;
        record="         __tmpcol = substr(__tmpcol, index(__tmpcol, '//')+2); "; output;
        record="       end;"; output;
        record="       else do;"; output;
        record="         __col = trim(left(__tmpcol)); "; output;
        record="       end;"; output;
        record="       __sid = __sid + (__i-1)/__nline;"; output;
        record="       __tmpalign = scan(__tmpal,__i, '-');"; output;
        record="       output;"; output;
        record="    end;"; output;
        record="    drop __stat_align __stat_order __stat_label __overall __nline "; output;
        record="         __tmpal __tmpcol __tmpcol_0;"; output;
        record="  run;"; output;
        record=" "; output;
        record="  proc sort data="||strip(name)||";"; output;
        %if %upcase(&grouping) ne N %then %do; 
            record="  by __order __sid __fname &trtvars &varby &groupby;"; output;
        %end;
        %else %do;
            record="  by __order __sid __fname &trtvars &by ;"; output;
        %end;
        record="  run;"; output;
        record=" "; output;
        record="  data "||strip(name)||" (drop = __order rename=(__tmporder=__order));"; output;
        record="  set "||strip(name)||";";  output;
        %if %upcase(&grouping) ne N %then %do; 
            record="  by __order __sid __fname &trtvars &varby &groupby;";   output;
        %end;
        %else %do;
            record="  by __order __sid __fname &trtvars &by ;"; output;
        %end;

        record="    retain __tmporder;"; output;
        record="    if first.__order then __tmporder=__order;"; output;
        record="    if first.__sid then __tmporder+0.0001;"; output;
        record="  run;"; output;
        record=" "; output;
        record="*---------------------------------------------------------;"; output;
        record="* ADD PLUGIN-GENERATED STATISTICS TO OTHER STATISTICS;"; output;
        record="*---------------------------------------------------------;"; output;
        record=" "; output;
        record="  data __modelstatr;"; output;
        record="    set __modelstatr "||strip(name)||";"; output;
        record="  run;  "; output;
        record=" "; output;
        record='%end;';     output;
        
    
        run;
  
        proc append data=rrgpgmtmp base=rrgpgm;
        run;                                   
    %end;
    ** transpose model based statistics;
    
    data rrgpgmtmp;
    length record $ 2000;
    keep record;
    record=" "; output;
    record='%local dsid rc nobsmdl;'; output;
    record='%let dsid ='; output;
    record='  %sysfunc(open(' ||"__modelstatr ));"; output;
    record='%let nobsmdl = %sysfunc(attrn(&dsid, NOBS));;'; output;
    record='%let rc=%sysfunc(close(&dsid));;'; output;
    record=" "; output;
    record='%if &nobsmdl>0 %then %do;';      output;

   
    %__joinds(data1=__modelstatr,
              data2=__poph(keep=&varby &trtvars __trtid),
          by = &varby &trtvars,
            mergetype=INNER,
              dataout=__modelstatr);
    
    
    record=" "; output;
    record="*-----------------------------------------------------------;"; output;
    record="*  TRANSPOSE DATASET WITH MODEL-BASED STATISTICS;"; output;
    record="*-----------------------------------------------------------;"; output;
    record=" "; output;
    record="proc sort data=__modelstatr ;"; output;
    record="by &by __tby &groupvars  __order __col_0 __fname __tmpalign;"; output;
    record="run;"; output;
    record=" "; output;
    record="proc transpose data=__modelstatr out=__modelstatra prefix=__col_;"; output;
    record="by &by __tby &groupvars  __order __col_0 __fname __tmpalign;"; output;
    record="id __trtid;"; output;
    record="var __stat_value;"; output;
    record="run;"; output;
    record=" "; output;
    record=" "; output;
    record="data __modelstatr;"; output;
    record="set __modelstatra;"; output;
    record="by &by __tby &groupvars  __order __col_0 __fname;"; output;
    record="length __align $ 2000;"; output;
    record="__align ='L';"; output;
    record='do __i=1 to &maxtrt;'; output;
    record="   __align = trim(left(__align))||' '||__tmpalign;"; output;
    record="end;"; output;
    record="drop __i _NAME_;"; output;
    record="run;"; output;
    %if %length(&simplestats) %then %do;
        record="data __condcnt2;"; output;
        record="set __condcnt2 __modelstatr;"; output;
        record="run;"; output;
    %end;
    %else %do;
        record="data __condcnt2;"; output;
        record="set __modelstatr;"; output;
        record="run;"; output;
    %end;
    record=" "; output;
    record='%end;'; output;
    
    
    
    %if %length(&ovstat) %then %do;
       
        record=" ";  output;
        record=" "; output;
        record="*---------------------------------------------------------;"; output;
        record="* COLLECT REQUESTED OVERALL STATISTICS ;"; output;
        record="* ADD TO DATASETS __OVERALLSTAT;"; output;
        record="*---------------------------------------------------------;"; output;
        record=" "; output;
        record="proc sort data=__modelstat;"; output;
        record="  by __fname __overall;"; output;
        record="run;"; output;
        record=" "; output;
        record="proc sort data=__overallstats0;"; output;
        record="  by __fname __overall;"; output;
        record="run;"; output;
        record=" "; output;
        record="data __overallstats0;"; output;
        record="  merge __overallstats0(in=__a) __modelstat (in=__b);"; output;
        record="  by __fname __overall;"; output;
        record="  if __a and __b;"; output;
        record="run;"; output;
        record=" "; output;
        record="data __overallstats;"; output;
        record="  set __overallstats __overallstats0;"; output;
        record="run;"; output;
        record=" "; output;
    %end;
    run;
    proc append data=rrgpgmtmp base=rrgpgm;
    run;

%end;



data rrgpgmtmp;
length record $ 2000;
keep record;
record=" "; output;
record=" "; output;


record="proc sort data=__condcnt2;"; output;
record=" by &by __tby &groupvars __order;"; output;
record="run;"; output;
record=" "; output;
record="*----------------------------------------------------;"; output;
record="* DEFINE ALIGNMENT, INDENTATION AND SKIPLINES;"; output;
record="*    CREATE DISPLAY LABEL FOR CONDITION;"; output;
record="*----------------------------------------------------;"; output;

record="data &outds;"; output;
record="  length __col_0 __align $ 2000 __suffix __vtype $ 20 __varlabel $ 2000 __skipline $ 1;"; output;
record="  set __condcnt2 end=eof;"; output;
record="  by &by __tby &groupvars __order ;"; output;
record='array cols{*} $ 2000 __col_1-__col_&maxtrt;'; output;
record="if 0 then do; __i=.; __stat=''; _name_=''; end;"; output;
record="  __varlabel='';"; output;
record="  __suffix='';"; output;
record="  __labelline=&labelline;"; output;
%if &skipline=Y %then %do;
    record="  if last.%scan(__tby &groupvars,-1, %str( )) then __suffix='~-2n';"; output;
%end;
record="  __tmprowid=_n_+1;"; output;
record="  __blockid=&varid;"; output;
record="  if __align ='' then do;"; output;
record="    if __stat in ('NPCT', 'NNPCT') then "; output;
record="       __align = 'L'||repeat(' RD', dim(cols));"; output;
record="    else __align = 'L'||repeat(' D', dim(cols));"; output;
record="  end;"; output;
record="  __keepn=1;"; output;
%if &keepwithnext=Y %then %do;
    record="if last.%scan(__tby &groupvars,-1,%str( )) then __keepn=1;"; output;
%end;
%else %do;
    record="if last.%scan(__tby &groupvars,-1,%str( )) then __keepn=0;"; output;
%end;
record="  __rowtype=2;"; output;
record="  __order=1;"; output;
record="  __vtype='COND';"; output;
%if &showfirst=Y %then %do;
    %* if grouping variables are present but are not to be applied to condition;
    %* this ensures that when final sort is applied, condition goes first;
    record="  __grptype=0;"; output;
%end;
%else %do;
    record="  __grptype=1;"; output;
%end;
record="__grpid=999;"; output;
record="  __skipline=cats('" ||strip("&skipline")|| "');"; output;
length __label $ 2000;
__label = quote(dequote(trim(left(symget("label"))))); output;
%local ngrpv;
%let ngrpv=0;
%if %upcase(&grouping)=N %then %do; 
    %let ngrpv=0; 
%end;
%else %do;
    %if %length(&groupvars) %then %let ngrpv = %sysfunc(countw(&groupvars,%str( )));
%end;

%if &show0cnt=N %then %do;
    record="  __iscnt=0;"; output;
    record="  do __i=1 to dim(cols);"; output;
    record="    if substr(left(cols[__i]),1,1) ne '0' then __iscnt=1;"; output;
    record="  end;"; output;
    record="  if __iscnt=0 then delete;"; output;
    record="  else do;"; output;
%end;

%if %length(&simplestats) %then %do;
    %if &labelline ne 0 %then %do;
        record=" if first.%scan(__tby &groupvars,-1, %str( )) then do;"; output;
        %if %length(&labelvar) %then %do;
            record="    __col_0 = strip(symget('label4cond'))||' '||trim(left(__col_0));"; output;
        %end;
        %else %do;
            record="    __col_0 = " ||strip(__label)|| "||' '||trim(left(__col_0));"; output;
        %end;
        record="  __indentlev=&indent+&ngrpv;"; output;
        record=" end;"; output;
        record=" else __indentlev=&indent+&ngrpv+1;"; output;
    %end;
    %else %do;
        record="  __indentlev=&indent+1+&ngrpv;"; output;
        record="if __col_0 = '' then __col_0 = put(__stat, $__rrgsf.);"; output;
        record="output;"; output;
        record=" if __order=1 and first.%scan(__tby &groupvars,-1, %str( )) then do;"; output;
        %if %length(&labelvar) %then %do;
            record="  __col_0 = strip(symget('label4cond'));"; output;
        %end;
        %else %do;
            record="  __col_0 = "||strip(__label)|| ";"; output;
        %end;
        record="  __order = 0.5;"; output;
        record="  __tmprowid = 1;"; output;
        record="  do __i=1 to dim(cols);"; output;
        record="     cols[__i]='';"; output;
        record="  end;"; output;
        record="  __suffix='';"; output;
        record="  __indentlev=&indent+&ngrpv;"; output;
        record="  __vtype='CONDLAB';"; output;
        record="  output;"; output;
        record="end;"; output;
    %end;
%end;
%else %do;
    %if &labelline ne 0 %then %do;
        record=" if first.%scan(__tby &groupvars,-1, %str( )) then do;"; output;
        %if %length(&labelvar) %then %do;
            record="    __col_0 = strip(symget('label4cond'))||' '||trim(left(__col_0));"; output;
        %end;
        %else %do;
            record="    __col_0 = " ||strip(__label)|| "||' '||trim(left(__col_0));"; output;
        %end;
        record=" end;"; output;
        record=" __indentlev=&indent+&ngrpv+1;"; output;
    %end;
    %else %do;
        record="  __indentlev=&indent+1+&ngrpv;"; output;
        record="if __col_0 = '' then __col_0 = put(__stat, $__rrgsf.);"; output;
        record="output;"; output;
        record=" if __order=1 and first.%scan(__tby &groupvars,-1, %str( )) then do;"; output;
        %if %length(&labelvar) %then %do;
            record="  __col_0 = strip(symget('label4cond'));"; output;
        %end;
        %else %do;
          record="  __col_0 = " ||strip(__label)|| ";"; output;
        %end;
        record="  __order = 0.5;"; output;
        record="  __tmprowid = 1;"; output;
        record="  do __i=1 to dim(cols);"; output;
        record="     cols[__i]='';"; output;
        record="  end;"; output;
        record="  __suffix='';"; output;
        record="  __indentlev=&indent+&ngrpv;"; output;
        record="  __vtype='CONDLAB';"; output;
        record="  output;"; output;
        record="end;"; output;
     %end;
%end;
%if &show0cnt=N %then %do;
  record="  end;"; output;
%end;


record="drop _name_ __i;"; output;
record="run;"; output;
record=" "; output;

record= '%excd'||"&varid.:"; output;
run;

proc append data=rrgpgmtmp base=rrgpgm;
run;

%mend;

