/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __cnts (
dsin =,
dsinrrg=,
varid=,
tabwhere=, 
unit=, 
groupvars4pop=, 
groupvarsn4pop=,
by4pop=,
byn4pop=,
aetable=N,
trtvars=,
warn_on_nomatch=1,
outds=)/store;

%* STARTING __CNTS FOR VARIABLE &VARID;

%local allgrpcnt i j lastms;


%local dsin varid tabwhere unit groupvars by aetable  
           outds dsinrrg
       tabwhere where   unit var  by trtvars 
       fmt    indent skipline   label 
       outds labelline  decode  countwhat outds  codes codesds
       warn_on_nomatch indent stats ovstat codes codesds totalpos
       tmpcodes tmpcodesds asubjid missorder totorder misspos misstext
       showmiss keepn groupvars4pop groupvarsn4pop by4pop byn4pop
       delmods
       ;



%let by = &by4pop &byn4pop;
%if %length(&by) %then %let by = %sysfunc(compbl(&by));
%let groupvars = &groupvars4pop &groupvarsn4pop;
%if %length(&groupvars) %then %let groupvars = %sysfunc(compbl(&groupvars));


%*-------------------------------------------------------------;
%* determine attributes of current variable;
%*-------------------------------------------------------------;

data __catv;
set __varinfo (where=(varid=&varid));
run;

%let indent=0;
%let codesds=0;
%let codes=0;
%local tmpcodes tmpcodesds desc;

proc sql noprint;
  select trim(left(decode))    into:decode    separated by ' '  from __catv;
  select trim(left(where))     into:where     separated by ' ' from __catv;
  select trim(left(name))      into:var       separated by ' ' from __catv;
  select trim(left(fmt))       into:fmt       separated by ' ' from __catv;
  select indent into:          indent         separated by ' ' from __catv;
  select upcase(skipline)      into:skipline  separated by ' ' from __catv;
  select trim(left(dequote(label))) into:label separated by ' ' from __catv;
  select labelline             into:labelline separated by ' ' from __catv;
  select trim(left(countwhat)) into:countwhat separated by ' ' from __catv;
  select codelist              into:tmpcodes  separated by ' ' from __catv;
  select codelistds            into:tmpcodesds separated by ' ' from __catv;
  select delmods               into:delmods   separated by ' ' from __catv;
  select stat                  into:stat       separated by ' ' from __catv;
  select ovstat                into:ovstat     separated by ' ' from __catv;
  select trim(left(subjid))    into:asubjid    separated by ' ' from  __catv;
  select dequote(trim(left(misstext))) into:misstext  separated by ' ' 
    from __catv;
  select dequote(trim(left(misspos)))  into:misspos   separated by ' ' 
    from __catv;
  select dequote(trim(left(totalpos)))  into:totalpos   separated by ' ' 
    from __catv;

  select dequote(trim(left(showmissing)))  into:showmiss  separated by ' ' 
    from __catv;
  select trim(left(keepwithnext))   into:keepn  separated by ' ' from  __catv;    
  select desc                  into:desc       separated by ' ' from __catv;
  
quit;

%if %length(&tmpcodes) %then %let codes=1;
%if %length(&tmpcodesds) %then %let codesds=1;
%if %length(&asubjid)>0 %then %let unit=&asubjid;




%if %length(&where)=0  %then %let where=%str(1=1);

%if %length (&misspos)>0 %then %let missorder = &misspos;
%if %upcase(&misspos)=LAST %then %let missorder = 999998;
%if %upcase(&misspos)=FIRST %then %let missorder=-999999;
%if %length(&missorder)=0 %then %let missorder=999999;

%if %length (&totalpos)>0 %then %let totorder = &totalpos;
%if %upcase(&totalpos)=LAST %then %let totorder = 999997;
%if %upcase(&totalpos)=FIRST %then %let totorder=0;
%if %length(&totorder)=0 %then %let totorder=0;

%let mistext=%nrbquote(&misstext);
%if %length(&misstext)=0 %then %let misstext=Missing;


data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
__tabwhere = cats(symget("tabwhere"));
__where = cats(symget("where"));
put;
put @1 "*-------------------------------------------------------------;";
put @1 "*  CALCULATE STATISTICS FOR &VAR      ;";
put @1 "*-------------------------------------------------------------;";
put;
put;
put @1 "data &outds;";
put @1 " if 0;";
put @1 "run;";
put;
put @1 "*-------------------------------------------------------------;";
put @1 "* CREATE A TEMPORARY DATASET AND SORT NODUPKEY BY NECESSARY ;";
put @1 "* VARIABLES;";
put @1 "*-------------------------------------------------------------;";
put;
put @1 "proc sql noprint;";
put @1 "  create table __datasetc as select * ";
put @1 "     from __dataset (where=(" __tabwhere " and " __where "));";
put @1 "quit;";
put;
put @1 '%local dsid rc nobs ;';
put @1 '%let dsid =%sysfunc(open(__datasetc));;';
put @1 '%let nobs = %sysfunc(attrn(&dsid, NOBS));;';
put @1 '%let rc=%sysfunc(close(&dsid));;';
put;
put @1 '%if &nobs<=0  %then %do;';
put @1 '%goto exit' "c&varid;";
put @1 '%end;';

put;
put;

%if %index(&aetable, EVENTS)<=0 %then %do;
  put @1 "proc sort data=__datasetc nodupkey ;";
  put @1 "  by  &by &groupvars &var &unit &trtvars ;";
  put @1 "run;";
  put;
%end;
%else %do;
  put @1 "proc sort data=__datasetc nodupkey ;";
  put @1 "by  &by &groupvars &var &unit &trtvars __eventid;";
  put @1 "run;";
  put;
%end;

put;
put @1 "data __catcnt4;";
put @1 "if 0;";
put @1 "run;";
run;




%local simplestats simpleorder ;
data __modelstat;
  length __allstat __fname __name __modelname __simple __simpord  $ 2000;
  __allstat = upcase(trim(left(symget("stat"))));
  __overall=0;
  __simple='';
  do __i =1 to countw(__allstat, ' ');
    __fname = scan(__allstat,__i,' ');
    if index(__fname,'.')>0 then do;
      __modelname = scan(__fname, 1, '.');
      __name =  scan(__fname, 2, '.');
      __model=1;
      __order=999999+__i;
      call symput('lastms', cats(__fname));
    end;
    else do;
      __name = __fname;
      __model=0;
      __simple = trim(left(__simple))||' '||trim(left(__name));
      __simpord= trim(left(__simpord))||' '||cats(__i);
      __order=__i;      
    end;

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

%if %length(&simplestats)=0 %then %goto skipcnt;

*-------------------------------------------------------------;
* PROCESS LIST OF CODES (IF GIVEN);
*-------------------------------------------------------------;

%__makecodeds(
  vinfods=__catv, varid=&varid,  dsin=&dsinrrg, outds=__catcodes&varid);

 /* 
 at runtime, this creates dataset __catcodes&varid_exec whic h contains variable name , decode values 
      (stored in __display_&varid), and order (stored in __order_<variable name>)
      for the variable being processed , if codelistds does not exist for this variable,
      and if codelist was provided. If format was also provided
      then format superseeds the values from codelist 
      
      In generated program, the dataset __catcodes&varid is also created, and s a copy
      of __catcodes&varid_exec
      
*/

proc print data=__catcodes&varid._exec;
  title"__catcodes&varid._exec after __makecodeds ";
run;

%*-------------------------------------------------------------;
%* PROCESS DATASET WITH LIST OF CODES (IF GIVEN);
%*-------------------------------------------------------------;


%__usecodesds(
  vinfods=__varinfo, 
  varid=&varid, 
  outds=__catcodes&varid, 
  dsin=__datasetc, 
  trtvars=&trtvars, 
  by=&by &groupvars);
  

*-----------------------------------------------------------------------;
* CREATE DATSET WITH TRANSPOSED COUNTS AND PERCENTS;
*-----------------------------------------------------------------------;


%if %upcase(&aetable)=N %then %do;

    %__cntssimple (
            varid = &varid,
          vinfods = __catv,
           ds4var = __datasetc,
           ds4pop = &dsin ,
         ds4denom = &dsin ,
             unit = &unit __theid,
            outds = __catcnt4,
        missorder = &missorder,
         totorder = &totorder);

%end;

%else %do;

    %__cntsae (
          vinfods = __catv,
            varid = &varid,
           ds4var = __datasetc,
         ds4denom = &dsin ,
        groupvars = &groupvars,
             unit = &unit __theid,
          aetable = &aetable, 
            outds = __catcnt4,
        missorder = &missorder,
         totorder = &totorder);

%end;



data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put @1 '%if %sysfunc(exist(__catcnt4)) = 0 %then %do;';
put @1 '  %put -----------------------------------------------------------;';
put @1 '  %put NO RECORDS IN RESULT DATASET : SKIP REST OF MANIPULATION;  ';
put @1 '  %put -----------------------------------------------------------;';
put @1 '  %goto ' "exitc&varid;";
put @1 '%end;';
put;


*-----------------------------------------------------------------------;
* APPLY TEMPLATE: KEEP ONLY MODALITIES FROM TEMPLATE;
*-----------------------------------------------------------------------;


proc sql noprint;
  select trim(left(decode)) into:decode from __catv;
quit;



%__applycodesds(
   codelistds = __catcodes&varid,
        codes = &codes,
      codesds = &codesds,
grptemplateds = __grptemplate,
      countds = __catcnt42,
         dsin = __catcnt4,
           by = &by,
warn_on_nomatch = &warn_on_nomatch,           
    groupvars = &groupvars,
          var = &var,
       decode = &decode,
          fmt = &fmt,
    missorder = &missorder,
     misstext = %nrbquote(&misstext),
     showmiss = &showmiss,
       remove = %nrbquote(&delmods)
   
);

%*-----------------------------------------------------------------;
%* APPLY FREQUENCY-BASED SORTING;
%*-----------------------------------------------------------------;


%__freqsort(
   vinfods = __catv,
      dsin = __catcnt4,
   trtvars = &trtvars,
     trtds = __trt,
 trtinfods = __trtinfo,
        by = &by,
 groupvars = &groupvars,
       var = &var
);

%local ngrp;
%let ngrp=0;
%if %length(&groupvars) %then %let ngrp = %sysfunc(countw(&groupvars, %str( )));
%do i=1 %to &ngrp;
  %local j ngrpvars currgrp;
  %let currgrp = %scan(&groupvars, &i, %str( ));
  %let ngrpvars=;
  %do j=1 %to %eval(&i-1);
    %let ngrpvars = &ngrpvars %scan(&groupvars, &j, %str( ));
  %end;
  
  data __catv_&i;
    set __varinfo;
    if  upcase(name) = upcase("&currgrp") and type='GROUP';
  run;
    
  %__freqsort(
     vinfods = __catv_&i,
        dsin = __catcnt4,
     trtvars = &trtvars,
       trtds = __trt,
   trtinfods = __trtinfo,
          by = &by,
   groupvars = &ngrpvars,
         var = &currgrp,
    ordervar = __order_&currgrp,
     analvar = &var
  );


%end;


%*-----------------------------------------------------------------;
%* APPLY COUNT CUT-OF AND/OR PERCENT CUT-OFF;
%*-----------------------------------------------------------------;

%__cutoff(
       dsin = __catcnt4,
    vinfods = __catv,
         by = &by,
  trtinfods = __trtinfo,   
      trtds = __trt,      
  groupvars = &groupvars);

%skipcnt:



%*-----------------------------------------------------------------;
%* ADD MODEL BASED STATISTICS;
%*-----------------------------------------------------------------;

%local statf;
%let statf=%str($__rrgbl.);
%if %length(&simplestats)>0 %then %do;
  %if %sysfunc(countw(&simplestats, %str( )))>1 %then %do;
    %let statf = %str($__rrgsf.);
  %end;
%end;



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
    put @1 "    __name = '" __name "';";
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
    put @1 "set __dataset(where=(&tabwhere and &where &pooledstr));";
    put @1 "run;";
    put;
    put @1 "data __bincntds;";
    put @1 "set __catcnt4;";
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
    put @1 "       var = &var,";
    put @1 "   trtvar  = &trtvars,";
    %if %upcase(&aetable) = N %then %do;
    put @1 " groupvars = &by &groupby,";
    %end;
    %else %do;    
    put @1 "    pageby = &by,";
    put @1 " groupvars = &groupby,";
    %end;
    put @1 "   dataset = __datasetp,";
    if parms ne '' then do;
      put @1 parms ",";
    end;
    put @1 "   subjid=&subjid);";
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
    put @1 "if __a then __fname = upcase(cats('" "&currentmodel" "','.',__stat_name));";
    put @1 'run;';
    put;
    %end;
    put; 
    put @1 "*---------------------------------------------------------;";
    put @1 "* MERGE LIST OF REQUESTED MODEL-BASED STATISTICS      ;";
    put @1 "* WITH DATASET CREATED BY PLUGIN;";
    put @1 "* KEEP ONLY REQUESTED STATISTICS FROM CURRENT MODEL;";
    put @1 "*---------------------------------------------------------;";
    put;
    put @1 "  data __mdl_&modelds;";
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
    put @1 '%local dsid rc nobs;';
    put @1 '%let dsid =';
    put @1 '  %sysfunc(open(' "__mdl_&modelds ));";
    put @1 '%let nobs = %sysfunc(attrn(&dsid, NOBS));;';
    put @1 '%let rc=%sysfunc(close(&dsid));;';
    put;
    put @1 '%if &nobs>0 %then %do;';
    put;
    put @1 "  proc sort data=__mdl_&modelds;";
    put @1 "    by __fname __overall;";
    put @1 "  run;";
    put @1 "  proc sort data=__modelstat;";
    put @1 "    by __fname __overall;";
    put @1 "  run;";
    put;
    put @1 "  data __mdl_&modelds;";
    put @1 "    length __col_0 __col __tmpcol_0 __tmpcol $ 2000 __tmpalign __tmpal $ 8;";
    put @1 "    merge __mdl_&modelds (in=__a) __modelstat (in=__b);";
    put @1 "    by __fname __overall;";
    put @1 "    __sid=__stat_order;";
    put @1 "    if __a and __b;";
    put @1 "    __tby=1;";
    put @1 "    __tmpal = __stat_align;";
    put @1 "    __tmpcol = cats(__stat_value);";
    put @1 "    __tmpcol_0 = cats(__stat_label);";
    put @1 "    __tmpal = tranwrd(__tmpal, '//', '-');";
    put @1 "    __nline = countw(__tmpal,'-');";
    put @1 "    if index(__tmpcol_0, '//')=1 then __tmpcol_0='~-2n'||substr(__tmpcol_0, 3);";        
    put @1 "    do __i =1 to __nline;";
    put @1 "     if index(__tmpcol_0, '//')>0 then do;";
    put @1 "       __col_0 = substr(__tmpcol_0, 1, index(__tmpcol_0, '//')-1); ";
    put @1 "       __tmpcol_0 = substr(__tmpcol_0, index(__tmpcol_0, '//')+2); ";
    put @1 "     end;";
    put @1 "     else do;";
    put @1 "       __col_0 = trim(left(__tmpcol_0)); ";
    put @1 "     end;";
    put @1 "     if index(__tmpcol, '//')>0 then do;";
    put @1 "       __col = substr(__tmpcol, 1, index(__tmpcol, '//')-1); ";
    put @1 "       __tmpcol = substr(__tmpcol, index(__tmpcol, '//')+2); ";
    put @1 "     end;";
    put @1 "     else do;";
    put @1 "       __col = trim(left(__tmpcol)); ";
    put @1 "     end;";
    put @1 "     __sid = __sid + (__i-1)/__nline;";
    put @1 "     __tmpalign = scan(__tmpal,__i, '-');";    
    put @1 "     output;";
    put @1 "    end;";
    put @1 "    drop __stat_align __stat_order __stat_label __overall __nline ";
    put @1 "         __tmpal __tmpcol __tmpcol_0;";
    put @1 "   run;";
    PUT;
    put @1 "  proc sort data=__mdl_&modelds;";
    put @1 "  by __order __sid __fname &trtvars &by &groupby;";
    put @1 "  run;";
    put;
    put @1 "  data __mdl_&modelds (drop = __order ";
    %if %upcase(&aetable) ne N %then %do;
    put @1 "              rename=(__tmporder=__morder));";
    %end;
    %else %do;
    put @1 "              rename=(__tmporder=__order));";
    %end;
    put @1 "  set __mdl_&modelds;"; 
    put @1 "  by __order __sid __fname &trtvars &by &groupby;";  
    put @1 "    retain __tmporder;";
    put @1 "    if first.__order then __tmporder=__order+1000000;";
    put @1 "    if first.__sid then __tmporder+0.0001;";
    %if %upcase(&aetable) = N %then %do;
    put @1 "    __grpid=999;";
    %end;
    /*
    %else %do;
    put @1 " if __grpid ne 999 then __grpid = __grpid+1;";
    %end;
    */
    put @1 "  run;";
    put @1 "*---------------------------------------------------------;";
    put @1 "* ADD PLUGIN-GENERATED STATISTICS TO OTHER STATISTICS;";
    put @1 "*---------------------------------------------------------;";
    put;
    put @1 "  data __modelstatr;";
    put @1 "    set __modelstatr __mdl_&modelds;";
    put @1 "  run;  ";
    put;
    put @1 '%end;';
    put;
   run;
  %end;
 
  data _null_;
  file "&rrgpgmpath./&rrguri..sas" mod;
  put;
  put @1 '%local dsid rc nobs;';
  put @1 '%let dsid =';
  put @1 '  %sysfunc(open(' "__modelstatr));";
  put @1 '%let nobs = %sysfunc(attrn(&dsid, NOBS));;';
  put @1 '%let rc=%sysfunc(close(&dsid));;';
  put;
  put;
  put @1 '%if &nobs>0 %then %do;';
  put;
  
  run;
 
    
  %__joinds(data1=__modelstatr,
          data2=__poph(keep=&by &trtvars __trtid),
      by = &by &trtvars,
        mergetype=INNER,
          dataout=__modelstatr);
          
  %local ngb;
  proc sql noprint;
    select value into:ngb separated by ' '
    from __rrgpgminfo(where=(key = "newgroupby"));
  quit;
  %if %length(&ngb)=0 %then %let ngb= &groupvars;
         
  data _null_;
  file "&rrgpgmpath./&rrguri..sas" mod;
  put;
  put @1 "*-----------------------------------------------------------;";
  put @1 "*  TRANSPOSE DATASET WITH MODEL-BASED STATISTICS;";
  put @1 "*-----------------------------------------------------------;";
  put;
  put;
  put @1 "data __modelstatr;";
  put @1 "length __fname $ 2000;";
  put @1 "set __modelstatr;";
  put @1 " if 0 then __fname='';";
  put @1 "run;";
  put; 
  
  put @1 "proc sort data=__modelstatr ;";
  %if %upcase(&aetable) ne N %then %do;
  put @1 "by &by __tby &groupvars __grpid &var __morder  __col_0 __tmpalign __fname;";
  %end;
  %else %do;
  put @1 "by &by __tby &groupvars __order  __col_0 __tmpalign __grpid __fname;";
  %end;
  
  put @1 "run;";
  put;
  

  
  put @1 "proc transpose data=__modelstatr out=__modelstatr(drop=_name_) prefix=__col_;";
  %if %upcase(&aetable) ne N %then %do;
  put @1 "by &by __tby &groupvars __grpid &var __morder  __col_0 __tmpalign __fname;";
  %end;
  %else %do;
  put @1 "by &by __tby &groupvars __order  __col_0 __tmpalign __grpid __fname;";
  %end;
  put @1 "id __trtid;";
  put @1 "var __stat_value;";
  put @1 "run;";
  put;
  put;
  put @1 "*-----------------------------------------------------------;";
  put @1 "*  KEEP ONLY REQUESTED MODALITIES FOR MODEL-BASED STATISTICS;";
  put @1 "*-----------------------------------------------------------;";
  put;
  %if %upcase(&aetable) ne N %then %do;
  
  put @1 "data __catcnt4m;";
  put @1 "set __catcnt4;";
  
  put @1 "if __col_1 ne '';";
  
  put @1 "keep &by __tby &ngb &var __order __grpid;";
  put @1 "run;";
  put;
  put @1 "proc sql noprint;";
  put @1 "create table __tmp as select * from ";
  put @1 "__modelstatr natural right join __catcnt4m;";
  put @1 "create table __modelstatr as select * from __tmp;";
  put @1 "quit;";
  
  %end;
  put;
  put;
  put @1 "data __catcnt4;";
  put @1 "set __catcnt4 __modelstatr(in=__a);";
  put @1 "if __a then do; ";
  put @1 "  __vtype='CATS';";
  put @1 "end;";
  put @1 "run;";
%if %upcase(&aetable) ne N %then %do;
%* sort by grouping variable and modalities of &var;
%* inherit  __grptype, assign order from there;
%* sort later is done by &varby __grptype __tby &groupby __grpid __blockid ;
%* __order __tmprowid;
  put;
  put @1 "proc sort data=__catcnt4 ;";
  put @1 "by &by &groupvars __tby  __order  __vtype  __morder;";
  put @1 "run;";
  put;
  put @1 "data __catcnt4(drop=__order rename=(__norder=__order));";
  put @1 "set __catcnt4;";
  put @1 "by &by &groupvars __tby  __order  __vtype ;";
  put @1 "  retain __norder;";
  put @1 "  if first.__tby then __norder=0;";
  put @1 "  __norder+1;";
  put @1 "run;";
  
  put;

%end;

put @1 '%end;';
run;
  
  
  %if %length(&ovstat)  %then %do;
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


%*-----------------------------------------------------------------;
     

%local newgrvars;     
proc sql noprint;
  select value into:newgrvars from __rrgpgminfo
   (where =(key = "newgroupby"));
quit;   

%local tmp;
%let tmp = %scan(__tby &groupvars, -1, %str( ));

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
set __catv;
label=quote(cats(label));
put;
put @1 "*--------------------------------------------------------;";
put;
put @1 "*--------------------------------------------------------;";
put @1 "* DEFINE ALIGNMENTS, SKIPLINES AND INDENTATION;";
put @1 "*--------------------------------------------------------;";
put;
put;
put @1 "data __catcnt4;";
put @1 "length __fname $ 2000;";
put @1 " set __catcnt4;";
put @1 " if 0 then do; __fname=''; __stat=''; end;";
put @1 " run;";
put;
put @1 "proc sort data=__catcnt4;";
%if %length(&simplestats) %then %do;
put @1 "  by &by __tby &groupvars __grpid   __order &var __fname;";
%end;
%else %do;
put @1 "  by &by __tby &groupvars __grpid   __order __fname;";
%end;
put @1 "run;";
put;

put @1 "data __catcnt4 ;";
put @1 "  length __varlabel __col_0 __align __tmpl1 $ 2000 ";
put @1 "         __suffix __vtype $ 20 __tmpalign $ 8;";
put @1 "  set __catcnt4 end=eof;";
%if %length(&simplestats) %then %do;
put @1 "  by &by __tby &groupvars __grpid  __order &var __fname;";
%end;
%else %do;
put @1 "  by &by __tby &groupvars __grpid  __order __fname;";
%end;
put @1 "if 0 then __tmpalign=''; ";
put @1 '  array cols{*} __col_1-__col_&maxtrt;';
put;  
put;  
put @1 "  __tmpl1 =  " label ";";
put @1 "  if __tmpl1 ne '' then __varlabel = __tmpl1;   ";
put;  
put @1 "__keepnvar='" "&keepn" "';";
put;
%if %upcase(&Statsacross)=Y and &ngrpv>0 %then %do;
put @1 "  __indentlev=max(&indent+&ngrpv-1,0);";
%end;
%else %do;
put @1 "  __indentlev=&indent+&ngrpv;";
%end;
put @1 "  if __vtype='CATS' then do;";
put @1 "    __indentlev+1;";
put @1 "    __align = 'L';";
put @1 '    do __i=1 to &maxtrt;';
put @1 "      __align = trim(left(__align))||' '||__tmpalign;";
put @1 "    end;";
put @1 "  end;";
put @1 "  else do;";
put @1 "    __align = 'L';";
put @1 '    do __i=1 to &maxtrt;';
put @1 "    if __stat in ('NPCT', 'NNPCT') then ";
put @1 "       __align = trim(left(__align))||' RD';";
put @1 "    else __align = trim(left(__align))||' D';";

put @1 "    end;";
put @1 "  end;";
put @1 "  __suffix='';";
put @1 "  __tmprowid=_n_;";
put @1 "  __blockid=&varid;";
%if %upcase(&aetable) = N or %upcase(&countwhat)=MAX %then %do;
put @1 "  __keepn=1;";
%end;
%else %do;
%if %length(&lastms)=0 %then %do;
put @1 "  __keepn=0;";
%end;
%else %do;
put @1 "  __keepn=1;";
put @1 "  if last.__fname and trim(upcase(__fname))=trim(upcase('" "&lastms" "')) then __keepn=0;";
%end;
%end;
put;  
put @1 "  if last.&tmp then do;";
%if &skipline=Y %then %do;
put @1 "     __suffix='~-2n';";
%end;
%if %upcase(&aetable) = N or %upcase(&countwhat)=MAX %then %do;
put @1 "    if __keepnvar ne 'Y' then  __keepn=0;";
%end;
put @1 "  end;";
put; 

put; 
 
put @1 "  __labelline=&labelline;";
put;  
%if &labelline=1 %then %do;
put @1 "  if first.&tmp  then do;";
put @1 "     * PUT 1ST STATISTICS ON THE SAME LINE AS LABEL;";
put @1 "     __col_0 = trim(left(dequote(__varlabel)))||' '";
put @1 "     ||trim(left(__col_0));";
put @1 "  end;";
%end;
put;
put @1 "  if __vtype='' then __vtype='CAT';";
put; 
put @1 "  drop  __i __tmpl1;";
put @1 "run;";

put;

%if %upcase(&countwhat)=MAX %then %do;
  
put @1 "  %*----------------------------------------------------------;";
put @1 "  %* ADD RECORDS FOR GROUPING VARIABLES;";
put @1 "  %*----------------------------------------------------------;";

put @1 "  proc sort data=__catcnt4;";
%if %length(&simplestats) %then %do;
put @1 "    by &by __tby &groupvars  __grpid __order &var;";
%end;
%else %do;
put @1 "    by &by __tby &groupvars  __grpid __order;";
%end;
put @1 "  run;";

put @1 "  data __catcnt4;";
put @1 "  set __catcnt4;";
%if %length(&simplestats) %then %do;
put @1 "  by &by __tby &groupvars __grpid __order &var;";
%end;
%else %do;
put @1 "    by &by __tby &groupvars  __grpid __order;";
%end;
put @1 "  if 0 then __colev_='';";  
put @1 "  array cols{*} $ 2000 __col_:;";
put @1 "  array cole{*} $ 2000 __colev:;";

put @1 "  output;";
put @1 "  do __i=1 to dim(cols);";
put @1 "    cols[__i]='';";
put @1 "  end;";
put @1 "  do __i=1 to dim(cole);";
put @1 "    cole[__i]='';";
put @1 "  end;";
put @1 "  __tmprowid=-1;";
put @1 "  __grpid=__grpid-0.1;";
put @1 "  if first.__grpid then output;";

put @1 "  run;";
put;
%end;
  

put @1 "data &outds;";
put @1 "  set __catcnt4;";
put @1 "length __skipline $ 1;";
  %if %upcase(&aetable) ne N %then %do;
put @1 "     if ceil(__grpid)=1 then delete;";
  %end;
put @1 "  __col__1='';";
put @1 "  __skipline=cats('" "&skipline" "');";
put @1 "  drop __col__:;";
  %* IN CASE FAKE TRATMENTS WERE ADDED, DROP COLUMN FOR FAKE TRT;
     
put @1 "run;";
put;
put;
put @1 '%exit' "c&varid:";
put;
run;


%exit:

%mend;
