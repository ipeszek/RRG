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


%local dsin varid  unit groupvars by aetable  
           outds dsinrrg
        where   unit var  by trtvars 
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
select
  trim(left(decode))                               ,
  trim(left(where))                                ,
  trim(left(name))                                 ,
  trim(left(fmt))                                  ,
  indent                                           ,
  upcase(skipline)                                 ,
  trim(left(dequote(label)))                       ,
  labelline                                        ,
  trim(left(countwhat))                            ,
  codelist                                         ,
  codelistds                                       ,
  delmods                                          ,
  stat                                             ,
  ovstat                                           ,
  trim(left(subjid))                               ,
  dequote(trim(left(misstext)))                    ,
  dequote(trim(left(misspos)))                     ,
  dequote(trim(left(totalpos)))                    ,
  dequote(trim(left(showmissing)))                 ,
  trim(left(keepwithnext))                         ,
  desc                                             ,
  codelist
into
  :decode                                           separated by ' ' ,
  :where                                            separated by ' ' ,
  :var                                              separated by ' ' ,
  :fmt                                              separated by ' ' ,
  :indent                                           separated by ' ' ,
  :skipline                                         separated by ' ' ,
  :label                                            separated by ' ' ,
  :labelline                                        separated by ' ' ,
  :countwhat                                        separated by ' ' ,
  :tmpcodes                                         separated by ' ' ,
  :tmpcodesds                                       separated by ' ' ,
  :delmods                                          separated by ' ' ,
  :stat                                             separated by ' ' ,
  :ovstat                                           separated by ' ' ,
  :asubjid                                          separated by ' ' ,
  :misstext                                         separated by ' ' ,
  :misspos                                          separated by ' ' ,
  :totalpos                                         separated by ' ' ,
  :showmiss                                         separated by ' ' ,
  :keepn                                            separated by ' ' ,
  :desc                                             separated by ' ' ,
  :tmpcodes                                         separated by ' '  
  from __catv;            

/*
proc sql noprint;
  select trim(left(decode))    into:decode    separated by ' '  from __catv;
  select codelist              into:tmpcodes  separated by ' ' from __catv;
                                       

  select trim(left(decode))                into:decode      separated by ' '  from __catv;
  select trim(left(where))                 into:where       separated by ' ' from __catv;
  select trim(left(name))                  into:var         separated by ' ' from __catv;
  select trim(left(fmt))                   into:fmt         separated by ' ' from __catv;
  select indent                            into:indent         separated by ' ' from __catv;
  select upcase(skipline)                  into:skipline    separated by ' ' from __catv;
  select trim(left(dequote(label)))        into:label       separated by ' ' from __catv;
  select labelline                         into:labelline   separated by ' ' from __catv;
  select trim(left(countwhat))             into:countwhat   separated by ' ' from __catv;
  select codelist                          into:tmpcodes    separated by ' ' from __catv;
  select codelistds                        into:tmpcodesds   separated by ' ' from __catv;
  select delmods                           into:delmods     separated by ' ' from __catv;
  select stat                              into:stat        separated by ' ' from __catv;
  select ovstat                            into:ovstat      separated by ' ' from __catv;
  select trim(left(subjid))                into:asubjid     separated by ' ' from  __catv;
  select dequote(trim(left(misstext)))     into:misstext    separated by ' '     from __catv;
  select dequote(trim(left(misspos)))      into:misspos     separated by ' '     from __catv;
  select dequote(trim(left(totalpos)))     into:totalpos    separated by ' '     from __catv;
  select dequote(trim(left(showmissing)))  into:showmiss    separated by ' '     from __catv;
  select trim(left(keepwithnext))          into:keepn        separated by ' ' from  __catv;    
  select desc                              into:desc        separated by ' ' from __catv;
*/  
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


data rrgpgmtmp;
length record $ 2000;
keep record;
record= " "; output;
record= "*-------------------------------------------------------------;"; output;
record= "*  CALCULATE STATISTICS FOR &VAR      ;";                         output;
record= "*-------------------------------------------------------------;"; output;
record= " "; output;
record= " "; output;
record= "data &outds;";                                                    output;
record= " if 0;";                                                          output;
record= "run;";                                                            output;
record= " "; output;
record= "*-------------------------------------------------------------;"; output;
record= "* CREATE A TEMPORARY DATASET AND SORT NODUPKEY BY NECESSARY ;";   output;
record= "* VARIABLES;";                                                    output;
record= "*-------------------------------------------------------------;"; output;
record= " "; output;
record= "proc sql noprint;";                                               output;
record= "  create table __datasetc as select * ";                          output;
record= "     from __dataset (where=("||strip(symget("defreport_tabwhere"))||" and "||strip(symget("where")) || "));";   output;     
record= "quit;";                                                           output;
record= " "; output;
record= '%local dsid rc nobs ;';                                           output;
record= '%let dsid =%sysfunc(open(__datasetc));';                         output;
record= '%let nobs = %sysfunc(attrn(&dsid, NOBS));';                      output;
record= '%let rc=%sysfunc(close(&dsid));';                                output;
record= " "; output;
record= '%if &nobs<=0  %then %do;';                                        output;
record= '  %goto '||"exitc&varid;";                                                 output;
record= '%end;';                                                           output;

record= " "; output;
record= " "; output;

%if %index(&aetable, EVENTS)<=0 %then %do;
    record= "proc sort data=__datasetc nodupkey ;";                         output;
    record= "  by  &by &groupvars &var &unit &trtvars ;";                   output;
    record= "run;";                                                         output;
    record= " "; output;
%end;
%else %do;
    record= "proc sort data=__datasetc nodupkey ;";                         output;
    record= "by  &by &groupvars &var &unit &trtvars __eventid;";            output;
    record= "run;";                                                         output;
    record= " "; output;
%end;

record= " "; output;                                                        output;
record= "data __catcnt4;";                                                  output;
record= "if 0;";                                                            output;
record= "run;";                                                             output;
run;

proc append data=rrgpgmtmp base=rrgpgm;
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

/**** get new decode;*/


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



data rrgpgmtmp;
length record $ 2000;
keep record;
record=" "; output;
record= '%if %sysfunc(exist(__catcnt4)) = 0 %then %do;';                           output;
record= '  %put -----------------------------------------------------------;';     output;
record= '  %put NO RECORDS IN RESULT DATASET : SKIP REST OF MANIPULATION;  ';      output;
record= '  %put -----------------------------------------------------------;';     output;
record= '  %goto '||"exitc&varid;";                                                 output;
record= '%end;';                                                                   output;
record=" "; output;
run;


proc append data=rrgpgmtmp base=rrgpgm;
run;

*-----------------------------------------------------------------------;
* APPLY TEMPLATE: KEEP ONLY MODALITIES FROM TEMPLATE;
*-----------------------------------------------------------------------;




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


proc append data=rrgpgmtmp base=rrgpgm;
run;

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

   data rrgpgmtmp;
   length record $ 2000;
   keep record;
   set __modelstat end=eof;
   if _n_=1 then do;      
     %if %length(&ovstat) %then %do;
         record= "  data __overallstats0;";                                output;
         record= "  if 0;";                                                output;
         record= "  run;";                                                 output;
     %end;                                                                 
     record=" ";   output;                                                               
     record= "  data __modelstatr;";                                       output;
     record= "  if 0;";                                                    output;
     record= "  run;";                                                     output;
     record=" ";  output;                                                                
     record= "*-----------------------------------------------------;";    output;
     record= "* CREATE A LIST OF REQUESTED MODEL-BASED STATISTICS   ;";    output;
     record= "*-----------------------------------------------------;";    output;
     record=" ";                                                                  output;
     record= "  data __modelstat;";                                        output;
     record= "    length __fname __name   $ 2000;";                        output;
     record=" ";     output;                                                               
   end;                                                                    
                                                                           
   record= "    __overall = " || put(__overall, best.)|| ";";                   output;
   record= "    __fname = '"||strip(__fname)|| "';";                       output;
   record= "    __name = '" ||strip(__name)|| "';";                        output;
   record= "    __order = "||put(__order, best.)|| ";";                         output;
   record= "  output;";                                                    output;
   record=" "; output;                                                                    
   if eof then do;                                                         
       record=" "; output;                                                                  
       record= "  run;";                                                     output;
       record=" "; output;
       record=" "; output;
   
       record=" "; output;

       record= "*-------------------------------------------------------------;";    output;
       record= "* PREPARE DATASET FOR CUSTOM MODEL, REMOVING POOLED TREATMENTS;";    output;
       record= "*-------------------------------------------------------------;";    output;
        record=" "; output;                                                                          
        record= "data __datasetp;";                                                   output;
        record= "set __dataset(where=( ";
        record=strip(record)|| strip(symget("defreport_tabwhere")) || " and ";
        record=strip(record)|| strip(symget("where")) || " &pooledstr));";            output;
        record= "run;";                                                               output;
        record=" "; output;                                                                          
        record= "data __bincntds;";                                                   output;
        record= "set __catcnt4;";                                                     output;
        record= "run;";                                                               output;
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
          
        %local modelds;
        
       /* data _null_;
          set __modelp end=eof;
          if eof then call symput(modelds, cats(name));
        run;
        */
      
        data rrgpgmtmp;
        length record $ 2000;
        keep record;
       
        set __modelp end=eof;
       
        record=" "; output;
        record= strip(cats('%', name,'('));                       output;
        record= "       var = &var,";               output;
        record= "   trtvar  = &trtvars,";           output;
        %if %upcase(&aetable) = N %then %do;        
            record= " groupvars = &by &groupby,";   output;
        %end;                                       
        %else %do;                                  
            record= "    pageby = &by,";            output;
            record= " groupvars = &groupby,";       output;
        %end;                                       
        record= "   dataset = __datasetp,";         output;
        if parms ne '' then do;                     
           record= strip(parms)|| ",";                       output;
        end;                                        
        record= "   subjid=&defreport_subjid);";              output;
        record=" "; output;                                        output;
        %local modelds;                             
        call symput ('modelds', cats(name));        
        run;                                        
                
        proc append data=rrgpgmtmp base=rrgpgm;
        run;
                                     
        data rrgpgmtmp;                                
        length record $ 2000;    
        keep record;                                            
        %* collect overall statistics;              
        %if %length(&ovstat) %then %do;
        
            record= "*---------------------------------------------------------;";                       output;
            record= "* ADD OVERALL STATISTICS TO DATASET THAT COLLECTS THEM;";                           output;
            record= "*---------------------------------------------------------;";                       output;
            record=" "; output;                                                                                         
            record= 'data __overallstats0;';                                                             output;
            record= "length __fname $ 2000;";                                                            output;
            record= "set __overallstats0 &modelds(in=__a where=(__overall=1));";                         output;
            record= "__blockid = &varid;";                                                               output;
            record= "if __a then __fname = upcase(cats('"||strip("&currentmodel")||"','.',__stat_name));";        output;
            record= 'run;';                                                                              output;
            record=" "; output;                                                                                         
        %end;                                                                                            
        record=" "; output;                                                                                             
        record= "*---------------------------------------------------------;";                           output;
        record= "* MERGE LIST OF REQUESTED MODEL-BASED STATISTICS      ;";                               output;
        record= "* WITH DATASET CREATED BY PLUGIN;";                                                     output;
        record= "* KEEP ONLY REQUESTED STATISTICS FROM CURRENT MODEL;";                                  output;
        record= "*---------------------------------------------------------;";                           output;
        record=" "; output;                                                                                             
        record= "  data __mdl_&modelds;";                                                                output;
        record= "    length __fname $ 2000;";                                                            output;
        record= "    set &modelds;";                                                                     output;
        record= "    if __overall ne 1;";                                                                output;
        record= "    __fname = upcase(cats('"||strip("&currentmodel")|| "', '.', __stat_name));";        output;
        record= "  run;";                                                                                output;
        record=" "; output;                                                                                          
        record= "*---------------------------------------------------------;";                           output;
        record= "* CHECK IF PLUGIN PRODUCED ANY WITHIN-TREATMENT STATISTICS;";                           output;
        record= "*---------------------------------------------------------;";                           output;
        record=" "; output;                                                                                             
        record= '%local dsid rc nobs;';                                                                  output;
        record= '%let dsid =';                                                                           output;
        record= '  %sysfunc(open('||"__mdl_&modelds ));";                                                output;
        record= '%let nobs = %sysfunc(attrn(&dsid, NOBS));;';                                            output;
        record= '%let rc=%sysfunc(close(&dsid));;';                                                      output;
        record=" "; output;                                                                                             
        record= '%if &nobs>0 %then %do;';                                                                output;
        record=" "; output;                                                                                             
        record= "  proc sort data=__mdl_&modelds;";                                                      output;
        record= "    by __fname __overall;";                                                             output;
        record= "  run;";                                                                                output;
        record= "  proc sort data=__modelstat;";                                                         output;
        record= "    by __fname __overall;";                                                             output;
        record= "  run;";                                                                                output;
        record=" "; output;                                                                                             
        record= "  data __mdl_&modelds;";                                                                output;
        record= "    length __col_0 __col __tmpcol_0 __tmpcol $ 2000 __tmpalign __tmpal $ 8;";           output;
        record= "    merge __mdl_&modelds (in=__a) __modelstat (in=__b);";                               output;
        record= "    by __fname __overall;";                                                             output;
        record= "    __sid=__stat_order;";                                                               output;
        record= "    if __a and __b;";                                                                   output;
        record= "    __tby=1;";                                                                          output;
        record= "    __tmpal = __stat_align;";                                                           output;
        record= "    __tmpcol = cats(__stat_value);";                                                    output;
        record= "    __tmpcol_0 = cats(__stat_label);";                                                  output;
        record= "    __tmpal = tranwrd(__tmpal, '//', '-');";                                            output;
        record= "    __nline = countw(__tmpal,'-');";                                                    output;
        record= "    if index(__tmpcol_0, '//')=1 then __tmpcol_0='~-2n'||substr(__tmpcol_0, 3);";       output; 
        record= "    do __i =1 to __nline;";                                                             output;
        record= "     if index(__tmpcol_0, '//')>0 then do;";                                            output;
        record= "       __col_0 = substr(__tmpcol_0, 1, index(__tmpcol_0, '//')-1); ";                   output;
        record= "       __tmpcol_0 = substr(__tmpcol_0, index(__tmpcol_0, '//')+2); ";                   output;
        record= "     end;";                                                                             output;
        record= "     else do;";                                                                         output;
        record= "       __col_0 = trim(left(__tmpcol_0)); ";                                             output;
        record= "     end;";                                                                             output;
        record= "     if index(__tmpcol, '//')>0 then do;";                                              output;
        record= "       __col = substr(__tmpcol, 1, index(__tmpcol, '//')-1); ";                         output;
        record= "       __tmpcol = substr(__tmpcol, index(__tmpcol, '//')+2); ";                         output;
        record= "     end;";                                                                             output;
        record= "     else do;";                                                                         output;
        record= "       __col = trim(left(__tmpcol)); ";                                                 output;
        record= "     end;";                                                                             output;
        record= "     __sid = __sid + (__i-1)/__nline;";                                                 output;
        record= "     __tmpalign = scan(__tmpal,__i, '-');";                                             output;
        record= "     output;";                                                                          output;
        record= "    end;";                                                                              output;
        record= "    drop __stat_align __stat_order __stat_label __overall __nline ";                    output;
        record= "         __tmpal __tmpcol __tmpcol_0;";                                                 output;
        record= "   run;";                                                                               output;
        record=" "; output;                                                                                             
        record= "  proc sort data=__mdl_&modelds;";                                                      output;
        record= "  by __order __sid __fname &trtvars &by &groupby;";                                     output;
        record= "  run;";                                                                                output;
        record=" "; output;                                                                                             
        record= "  data __mdl_&modelds (drop = __order ";                                                output;
        %if %upcase(&aetable) ne N %then %do;                                                            
            record= "              rename=(__tmporder=__morder));";                                      output;
        %end;                                                                                            
        %else %do;                                                                                      
            record= "              rename=(__tmporder=__order));";                                       output;
        %end;                                                                                            
        record= "  set __mdl_&modelds;";                                                                 output;
        record= "  by __order __sid __fname &trtvars &by &groupby;";                                     output;
        record= "    retain __tmporder;";                                                                output;
        record= "    if first.__order then __tmporder=__order+1000000;";                                 output;
        record= "    if first.__sid then __tmporder+0.0001;";                                            output;
        %if %upcase(&aetable) = N %then %do;                                                             
            record= "    __grpid=999;";                                                                  output;
        %end;                                                                                            
        record= "  run;";                                                                                output;
        record= "*---------------------------------------------------------;";                           output;
        record= "* ADD PLUGIN-GENERATED STATISTICS TO OTHER STATISTICS;";                                output;
        record= "*---------------------------------------------------------;";                           output;
        record=" "; output;                                                                                             
        record= "  data __modelstatr;";                                                                  output;
        record= "    set __modelstatr __mdl_&modelds;";                                                  output;
        record= "  run;  ";                                                                              output;
        record=" "; output;                                                                                             
        record= '%end;';                                                                                 output;
        record=" "; output;
       run;
       
       proc append data=rrgpgmtmp base=rrgpgm;
       run;

   
    %end;
 
    data rrgpgmtmp;
      length record $ 2000;
      keep record;
    record=" "; output;
    record= '%local dsid rc nobs;'; output;
    record= '%let dsid ='; output;
    record= '  %sysfunc(open('|| "__modelstatr));"; output;
    record= '%let nobs = %sysfunc(attrn(&dsid, NOBS));;'; output;
    record= '%let rc=%sysfunc(close(&dsid));;'; output;
    record=" "; output;
    record=" "; output;
    record= '%if &nobs>0 %then %do;'; output;
    record=" "; output;
    

   
    
    %__joinds(data1=__modelstatr,
            data2=__poph(keep=&by &trtvars __trtid),
        by = &by &trtvars,
          mergetype=INNER,
            dataout=__modelstatr);
      
      run;
  
    proc append data=rrgpgmtmp base=rrgpgm;
    run;
  
      
    %local ngb;
    proc sql noprint;
      select value into:ngb separated by ' '
      from __rrgpgminfo(where=(key = "newgroupby"));
    quit;
    %if %length(&ngb)=0 %then %let ngb= &groupvars;
           
    data rrgpgmtmp;
    length record $ 2000;
    keep record;
    record=" "; output;
    record= "*-----------------------------------------------------------;"; output;
    record= "*  TRANSPOSE DATASET WITH MODEL-BASED STATISTICS;"; output;
    record= "*-----------------------------------------------------------;"; output;
    record=" "; output;
    record=" "; output;
    record= "data __modelstatr;"; output;
    record= "length __fname $ 2000;"; output;
    record= "set __modelstatr;"; output;
    record= " if 0 then __fname='';"; output;
    record= "run;"; output;
    record=" "; output; 

    record= "proc sort data=__modelstatr ;"; output;
    %if %upcase(&aetable) ne N %then %do;
        record= "by &by __tby &groupvars __grpid &var __morder  __col_0 __tmpalign __fname;"; output;
    %end;
    %else %do;
        record= "by &by __tby &groupvars __order  __col_0 __tmpalign __grpid __fname;"; output;
    %end;

    record= "run;"; output;
    record=" "; output;



    record= "proc transpose data=__modelstatr out=__modelstatr(drop=_name_) prefix=__col_;"; output;
    %if %upcase(&aetable) ne N %then %do;
        record= "by &by __tby &groupvars __grpid &var __morder  __col_0 __tmpalign __fname;"; output;
    %end;
    %else %do;
        record= "by &by __tby &groupvars __order  __col_0 __tmpalign __grpid __fname;"; output;
    %end;
    record= "id __trtid;"; output;
    record= "var __stat_value;"; output;
    record= "run;"; output;
    record=" "; output;
    record=" "; output;
    record= "*-----------------------------------------------------------;"; output;
    record= "*  KEEP ONLY REQUESTED MODALITIES FOR MODEL-BASED STATISTICS;"; output;
    record= "*-----------------------------------------------------------;"; output;
    record=" "; output;
    %if %upcase(&aetable) ne N %then %do;

        record= "data __catcnt4m;"; output;
        record= "set __catcnt4;"; output;

        record= "if __col_1 ne '';"; output;
        record= "keep &by __tby &ngb &var __order __grpid;"; output;
        record= "run;"; output;
        record=" "; output;
        record= "proc sql noprint;"; output;
        record= "create table __tmp as select * from "; output;
        record= "__modelstatr natural right join __catcnt4m;"; output;
        record= "create table __modelstatr as select * from __tmp;"; output;
        record= "quit;"; output;

    %end;
    record=" "; output;
    record=" "; output;
    record= "data __catcnt4;"; output;
    record= "set __catcnt4 __modelstatr(in=__a);"; output;
    record= "if __a then do; "; output;
    record= "  __vtype='CATS';"; output;
    record= "end;"; output;
    record= "run;"; output;
    %if %upcase(&aetable) ne N %then %do;
        %* sort by grouping variable and modalities of &var;
        %* inherit  __grptype, assign order from there;
        %* sort later is done by &varby __grptype __tby &groupby __grpid __blockid ;
        %* __order __tmprowid;
          record=" "; output;
        record= "proc sort data=__catcnt4 ;"; output;
        record= "by &by &groupvars __tby  __order  __vtype  __morder;"; output;
        record= "run;"; output;
        record=" "; output;
        record= "data __catcnt4(drop=__order rename=(__norder=__order));"; output;
        record= "set __catcnt4;"; output;
        record= "by &by &groupvars __tby  __order  __vtype ;"; output;
        record= "  retain __norder;"; output;
        record= "  if first.__tby then __norder=0;"; output;
        record= "  __norder+1;"; output;
        record= "run;"; output;
        record=" "; output;

    %end;

    record= '%end;'; output;
    run;
  
    proc append data=rrgpgmtmp base=rrgpgm;
    run;

  
  
    %if %length(&ovstat)  %then %do;
        data rrgpgmtmp;
        length record $ 2000;
        keep record;
        record=" "; output; 
        record=" "; output;
        record= "*---------------------------------------------------------;"; output;
        record= "* COLLECT REQUESTED OVERALL STATISTICS ;"; output;
        record= "* ADD TO DATASETS __OVERALLSTAT;"; output;
        record= "*---------------------------------------------------------;"; output;
        record=" "; output;
        record= "proc sort data=__modelstat;"; output;
        record= "  by __fname __overall;"; output;
        record= "run;"; output;
        record=" "; output;
        record= "proc sort data=__overallstats0;"; output;
        record= "  by __fname __overall;"; output;
        record= "run;"; output;
        record=" "; output;
        record= "data __overallstats0;"; output;
        record= "  merge __overallstats0(in=__a) __modelstat (in=__b);"; output;
        record= "  by __fname __overall;"; output;
        record= "  if __a and __b;"; output;
        record= "run;"; output;
        record=" "; output;
        record= "data __overallstats;"; output;
        record= "  set __overallstats __overallstats0;"; output;
        record= "run;"; output;
        record=" "; output;

        run;
        
        proc append data=rrgpgmtmp base=rrgpgm;
        run;

   %end;

%end;


%*-----------------------------------------------------------------;
     

%local newgrvars;     
proc sql noprint;
  select value into:newgrvars from __rrgpgminfo
   (where =(key = "newgroupby"));
quit;   

%local tmp;
%let tmp = %scan(__tby &groupvars, -1, %str( ));

data rrgpgmtmp;
length record $ 2000;
keep record;
set __catv;
label=quote(cats(label));
record=" "; output;
record= "*--------------------------------------------------------;"; output;
record=" "; output;
record= "*--------------------------------------------------------;"; output;
record= "* DEFINE ALIGNMENTS, SKIPLINES AND INDENTATION;"; output;
record= "*--------------------------------------------------------;"; output;
record=" "; output;
record=" "; output;
record= "data __catcnt4;"; output;
record= "length __fname $ 2000;"; output;
record= " set __catcnt4;"; output;
record= " if 0 then do; __fname=''; __stat=''; end;"; output;
record= " run;"; output;
record=" "; output;
record= "proc sort data=__catcnt4;"; output;
%if %length(&simplestats) %then %do;
    record= "  by &by __tby &groupvars __grpid   __order &var __fname;"; output;
%end;
%else %do;
    record= "  by &by __tby &groupvars __grpid   __order __fname;"; output;
%end;
record= "run;"; output;
record=" "; output;

record= "data __catcnt4 ;"; output;
record= "  length __varlabel __col_0 __align __tmpl1 $ 2000 "; output;
record= "         __suffix __vtype $ 20 __tmpalign $ 8;"; output;
record= "  set __catcnt4 end=eof;"; output;
%if %length(&simplestats) %then %do;
    record= "  by &by __tby &groupvars __grpid  __order &var __fname;"; output;
%end;
%else %do;
    record= "  by &by __tby &groupvars __grpid  __order __fname;"; output;
%end;
record= "if 0 then __tmpalign=''; "; output;
record= '  array cols{*} __col_1-__col_&maxtrt;'; output;
record=" "; output;  
record=" "; output;  
record= "  __tmpl1 =  "||strip(label)|| ";"; output;
record= "  if __tmpl1 ne '' then __varlabel = __tmpl1;   "; output;
record=" "; output;  
record= "__keepnvar='"||strip("&keepn")|| "';"; output;
record=" "; output;
%if %upcase(&defreport_statsacross)=Y and &ngrpv>0 %then %do;
    record= "  __indentlev=max(&indent+&ngrpv-1,0);"; output;
%end;
%else %do;
    record= "  __indentlev=&indent+&ngrpv;"; output;
%end;
record= "  if __vtype='CATS' then do;"; output;
record= "    __indentlev+1;"; output;
record= "    __align = 'L';"; output;
record= '    do __i=1 to &maxtrt;'; output;
record= "      __align = trim(left(__align))||' '||__tmpalign;"; output;
record= "    end;"; output;
record= "  end;"; output;
record= "  else do;"; output;
record= "    __align = 'L';"; output;
record= '    do __i=1 to &maxtrt;'; output;
record= "    if __stat in ('NPCT', 'NNPCT') then "; output;
record= "       __align = trim(left(__align))||' RD';"; output;
record= "    else __align = trim(left(__align))||' D';"; output;

record= "    end;"; output;
record= "  end;"; output;
record= "  __suffix='';"; output;
record= "  __tmprowid=_n_;"; output;
record= "  __blockid=&varid;"; output;
%if %upcase(&aetable) = N or %upcase(&countwhat)=MAX %then %do;
    record= "  __keepn=1;"; output;
%end;
%else %do;
    %if %length(&lastms)=0 %then %do;
        record= "  __keepn=0;"; output;
    %end;
    %else %do;
        record= "  __keepn=1;"; output;
        record= "  if last.__fname and trim(upcase(__fname))=trim(upcase('"||trim("&lastms")|| "')) then __keepn=0;"; output;
    %end;
%end;
record=" "; output;  
record= "  if last.&tmp then do;"; output;
%if &skipline=Y %then %do;
    record= "     __suffix='~-2n';"; output;
%end;
%if %upcase(&aetable) = N or %upcase(&countwhat)=MAX %then %do;
    record= "    if __keepnvar ne 'Y' then  __keepn=0;"; output;
%end;
record= "  end;"; output;
record=" "; output; 

record=" "; output; 
 
record= "  __labelline=&labelline;"; output;
record=" "; output;  
%if &labelline=1 %then %do;
    record= "  if first.&tmp  then do;"; output;
    record= "     * PUT 1ST STATISTICS ON THE SAME LINE AS LABEL;"; output;
    record= "     __col_0 = trim(left(dequote(__varlabel)))||' '"; output;
    record= "     ||trim(left(__col_0));"; output;
    record= "  end;"; output;
%end;
record=" "; output;
record= "  if __vtype='' then __vtype='CAT';"; output;
record=" "; output; 
record= "  drop  __i __tmpl1;"; output;
record= "run;"; output;

record=" "; output;

%if %upcase(&countwhat)=MAX %then %do;
  
    record= "  %*----------------------------------------------------------;"; output;
    record= "  %* ADD RECORDS FOR GROUPING VARIABLES;"; output;
    record= "  %*----------------------------------------------------------;"; output;

    record= "  proc sort data=__catcnt4;"; output;
    %if %length(&simplestats) %then %do;
        record= "    by &by __tby &groupvars  __grpid __order &var;"; output;
    %end;
    %else %do;
        record= "    by &by __tby &groupvars  __grpid __order;"; output;
    %end;
    record= "  run;"; output;

    record= "  data __catcnt4;"; output;
    record= "  set __catcnt4;"; output;
    %if %length(&simplestats) %then %do;
        record= "  by &by __tby &groupvars __grpid __order &var;"; output;
    %end;
    %else %do;
        record= "    by &by __tby &groupvars  __grpid __order;"; output;
    %end;
    record= "  if 0 then __colev_='';";   output;
    record= "  array cols{*} $ 2000 __col_:;"; output;
    record= "  array cole{*} $ 2000 __colev:;"; output;

    record= "  output;"; output;
    record= "  do __i=1 to dim(cols);"; output;
    record= "    cols[__i]='';"; output;
    record= "  end;"; output;
    record= "  do __i=1 to dim(cole);"; output;
    record= "    cole[__i]='';"; output;
    record= "  end;"; output;
    record= "  __tmprowid=-1;"; output;
    record= "  __grpid=__grpid-0.1;"; output;
    record= "  if first.__grpid then output;"; output;

    record= "  run;"; output;
    record=" "; output;
%end;
  

record= "data &outds;"; output;
record= "  set __catcnt4;"; output;
record= "length __skipline $ 1;"; output;
%if %upcase(&aetable) ne N %then %do;
    record= "     if ceil(__grpid)=1 then delete;"; output;
%end;
record= "  __col__1='';"; output;
record= "  __skipline=cats('"||"&skipline"|| "');"; output;
record= "  drop __col__:;"; output;

%* IN CASE FAKE TRATMENTS WERE ADDED, DROP COLUMN FOR FAKE TRT;
     
record= "run;"; output;
record=" "; output;
record=" "; output;
record= '%exitc'||"&varid.:"; output;
record=" "; output;
run;

proc append data=rrgpgmtmp base=rrgpgm;
run;



%exit:

%mend;
