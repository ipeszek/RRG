/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro rrg_generate/store;
%* TODO: test freqsort with codelist;
/*
Purpose:  this macro calculates summary statistics for continuous and 
          categorical   variables. 
          The list of variables for the table is created using
            %addvar(), %addcatvar(), %addcond() and %addlabel() macros.
          Variables are shown in table in order in which the above macros
            are called.
          The treatment variables are defined using %deftrt() macro.
          The grouping variables for the table are specified using
              &groupby macro parameter.
              The attributes of grouping variables (decode, label) are defined
              using %defgrp() macro
 
          For categorical variables, for each modality it counts number of 
             subjects counting subject once per 
             (treatment variables, grouping variables, modality) group
             (this way, if subject had >1 modality per group, 
              subject is counted under each modality)
          For continuous parameters, it collapses dataset selecting 
           distinct records per 
        (treatment variables, grouping variables, &subjid, analysis variable)
           and calculates statistics.
           Currently only statistics available in proc means are supported,
            with 2 special cases: meansd and minmax

Author: Iza Peszek, May 2008

Macro parameters:
  Dataset:  input dataset
  popWhere: population clause. This condition is applied before 
                any calculations are made
  tabwhere:   table body clause. This condition is applied after population
             count is obtained, but before any other statistics are
             calculated. Tabwhere IS NOT applied for calculation of denominator
  Colhead1:   The text of the column header for 1st column.
  subjid:     name of the variable holding unique subject id    
    groupby:    names of grouping variables. Grouoing is applied to all
                "variabes" defined using %addvar, %addcatvar, %addcond 
                and %addlabel macros
  Title1=,..., title6: tiles,
  footnot1=,...,  Footnot8: footnotes
    uri:        unique table identifier, also table name

*/



proc printto;
run;



%put;
%put;
%put ------------------------------------------------------------------------;;
%put  STARTING PROGRAM GENERATING STEP;;
%put ------------------------------------------------------------------------;;
%put;
%put;

%* PRINT GENERATED PROGRAM HEADER AND FORMATS;


%local Dataset datasetRRG popWhere tabwhere tablabel Colhead1 subjid 
       Title1 title2 title3 title4 title5 title6 
       Footnot1 Footnot2 Footnot3 Footnot4 Footnot5 Footnot6 
       Footnot7 footnot8 shead_l shead_r shead_m
       sfoot_l sfoot_r sfoot_m systitle
       By Statsincolumn statsacross aetable dest nodatamsg fontsize 
       orient colwidths  debug extralines print warnonnomatch
       libsearch tablepart varby4pop varbyn4pop groupby4pop groupbyn4pop;
%local i j k breakokat;
%local indata inmacros append appendable trtcnt java2sas;


proc sql noprint;
  select dataset into:dataset separated by ' ' from __repinfo;
  select tablepart into:tablepart separated by ' ' from __repinfo;
  select popWhere into:popWhere separated by ' ' from __repinfo;
  select tabwhere into:tabwhere separated by ' ' from __repinfo;
  select subjid into:subjid separated by ' ' from __repinfo;
  select aetable into:aetable separated by ' ' from __repinfo;
  select Statsacross into:Statsacross separated by ' ' from __repinfo;
  select warnonnomatch into:warnonnomatch separated by ' ' from __repinfo;
  select print into:print separated by ' ' from __repinfo;
  select debug into:debug separated by ' ' from __repinfo;
  select nodatamsg into:nodatamsg separated by ' ' from __repinfo;
  select append into:append separated by ' ' from __repinfo;
  select appendable into:appendable separated by ' ' from __repinfo;
  
  select upcase(java2sas) into:java2sas separated by ' ' from __repinfo;
  select name into: inmacros separated by ' ' from __varinfo (where=(type='MODEL'));
  select count(*) into:trtcnt separated by ' ' from __varinfo(where=(type='TRT'));
quit;

%LOCAL war ning;
%let war=WAR;
%let ning=NING;

%local pooled pooledstr;
proc sql noprint;
  select upcase(pooled4stats) into:pooled separated by ' ' from __repinfo;
quit;
%if  &pooled=N %then %do;
  %let pooledstr = and __grouped ne 1;
%end;

%if %upcase(&append)=Y or %upcase(&append)=TRUE %then %let append=Y;
%else %let append=N;
%if %upcase(&appendable)=Y or %upcase(&appendable)=TRUE %then %let appendable=Y;
%else %let appendable=N;

%if &append=N %then %do;

  proc sql noprint;
    select dataset into:indata separated by ' ' from __rrginlibs;
  quit;
  
  data __rrght;
    set __rrght ;
    length __tmp __tmp2 $ 200;
    __tmp = strip(symget("indata"));
    __tmp2 = strip(symget("inmacros"));
    record = tranwrd(strip(record), '_DATASETS_', strip(__tmp));
    record = tranwrd(strip(record), '_MACROS_', strip(__tmp2));
  run;

 
  %if &tablepart=FIRST or  %length(&tablepart)=0 %then %do;
  
    data _null_;
    file "&rrgpgmpath./&rrguri..sas" ;
    set __rrght ;
    put @1 record;
    run;
    
    data __drrght;
      x=1;
    run;
  %end;
  %else %do;
    data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    put;
    put;
    put @1 "*-------------------------------------------------------------------;";
    put @1 "*     NEXT PART OF THE TABLE                                        ;";
    put @1 "*-------------------------------------------------------------------;";
    put;
    put;
  run;
  %end;
  
%end;

%else %do;
  data _null_;
  file "&rrgpgmpath./&rrguri..sas" mod;
  put;
  put @1 "*-------------------------------------------------------------------;";
  %If &appendable=Y %then %do; 
  put @1 "*  CONTINUING WRITING PROGRAM (APPENDING NEXT PART);";
  %end;
  %else %do;
  put @1 "*  CONTINUING WRITING PROGRAM (APPENDING LAST PART);";
  %end;
  put @1 "*-------------------------------------------------------------------;";
  put;
  run;
%end;

%if &trtcnt>1 %then %do;
  %put &WAR.&NING.: more than one treatment variable was specified. Program aborted.;
  %goto exit;
%end;




%let datasetrrg=&dataset;  
  
proc sort data=__varinfo;
  by varid;
run;



%local i j grpinc trtacross;

proc sql noprint;
  select across into:grpinc separated by ' ' from
   __varinfo(where=(type='GROUP' and across='Y'));
  select across into:trtacross separated by ' ' from
   __varinfo(where=(type='TRT'));
quit;

%if %upcase(&trtacross)=N %then %do;
  data __varinfo;
    set __varinfo;
    if type='GROUP' then nline='N';
  run;
%end;
   
*----------------------------------------------------------------;
%* CREATE DUMMY WHERE CONDITIONS;
*----------------------------------------------------------------;

%if %length(&popwhere)=0  %then %do;
  %let popwhere=%str(1=1);
%end;
%if %length(&tabwhere)=0  %then %do;
  %let tabwhere=%str(1=1);
%end;


*----------------------------------------------------------------;
* DETERMINE TREATMENT VARIABLES ;
*----------------------------------------------------------------;


%local numtrt trtvar;
%let numtrt=0;

proc sql noprint;
select name into:trtvar separated by ' '
  from __varinfo(where=(type in ('TRT')));
quit;
%let trtvar=%scan(&trtvar,1,%str( ));

%* ensures only one trt variable;


%if %length(&trtvar)>0 %then %let numtrt = 1;

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put '%macro rrg;';
put ;

put @1 "*----------------------------------------------------------------;";
put @1 "* RRG Version %__version;";


put @1 "*----------------------------------------------------------------;";
put;
put @1 '%local maxtrt breakokat ;';
put;
put @1 "*----------------------------------------------------------------;";
put @1 "* APPLY POPWHERE CLAUSE TO DATASET;";
put @1 "* IF NECESSARY, CREATE COMBINED TREATMENTS;";
put @1 "*----------------------------------------------------------------;";
put;
run;



%__makenewtrt( 
      dsin=&datasetrrg,
      wherein = %nrbquote(&popwhere),  
     dsout=__dataset);
    
data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;   
put @1 "*-------------------------------------------------------------------;";
put @1 "* CHECK IF RESULTANT DATASET FROM PREVIOUS STEP HAS ANY OBSERVATIONS;";
put @1 "* IF NOT THEN SKIP TO MACRO GENERATING TABLE;";
put @1 "*-------------------------------------------------------------------;";
put;     
put @1 '%local dsid rc numobs;';
put @1 '%let dsid = %sysfunc(open(__dataset));';
put @1 '%let numobs = %sysfunc(attrn(&dsid, NOBS));';
put @1 '%let rc = %sysfunc(close(&dsid));';
put;
put @1 '%if &numobs=0 %then %do;';
put @1 '  %put  PASSED DATASET IS EMPTY;'; 
put @1 "  data __fall;";
put @1 '  if 0;';
put @1 "  __col_0 = '';";
put @1 "  __indentlev = 0;";
put @1 "  __ROWID = 0;";
put @1 '  run;';
put;
put @1 '  %let maxtrt=1;';
put;

put @1 '  %goto dotab;';
put @1 '%end;';
put;
run;    

%* IF NO TREATMENT VARS WERE PROVIDED THEN IN MACRO ABOVE ;
%* WE CREATED TREATMENT VARIABLE __trt;

%if &numtrt=0 %then %do;
  %let numtrt=1;
  %let trtvar=__trt;
%end;


*----------------------------------------------------------------;
* DETERMINE GROUPING VARIABLES;
%* NGRPV IS THE NUMBER OF GROUPING VARIABLES;
%* GRP1, GRP2, ETC ARE THE GROUPING VARIABLES;
*----------------------------------------------------------------;
%local groupby  ngrpv varby  nvarby i j k ;
%let nvarby=0;
%let ngrpv=0;


proc sql noprint;
  select count(*) into:ngrpv 
    from __varinfo(where=(upcase(type)='GROUP' and upcase(page) ne 'Y' ));    
  select name into:groupby separated by ' ' 
    from __varinfo(where=(upcase(type)='GROUP' and upcase(page) ne 'Y' ));    
  select count(*) into:nvarby
    from __varinfo(where=(upcase(type)='GROUP' and upcase(page) = 'Y'));
  select name into:varby separated by ' ' 
    from __varinfo(where=(upcase(type)='GROUP' and upcase(page) = 'Y'));
  select name into:varby4pop separated by ' ' 
    from __varinfo(where=(upcase(type)='GROUP' and upcase(page) = 'Y' and upcase(popsplit)='Y'));
  select name into:varbyn4pop separated by ' ' 
    from __varinfo(where=(upcase(type)='GROUP' and upcase(page) = 'Y' and upcase(popsplit) ne 'Y'));
  select name into:groupby4pop  separated by ' ' 
    from __varinfo(where=(upcase(type)='GROUP' and upcase(page) ne 'Y' and upcase(popsplit)='Y'));
  select name into:groupbyn4pop separated by ' ' 
    from __varinfo(where=(upcase(type)='GROUP' and upcase(page) ne 'Y' and upcase(popsplit) ne 'Y'));
    
   
quit;

%let ngrpv = %cmpres(&ngrpv);
%let nvarby = %cmpres(&nvarby);
%do i=1 %to &nvarby;
  %local vby&i;
  %let vby&i = %scan(&varby, &i, %str( ));
%end;


data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put @1 "*------------------------------------------------------------------;";
put @1 "* GET POPULATION COUNT;";
put @1 "*------------------------------------------------------------------;";
%local i j ;
%do i=1 %to &numtrt;
  %local trt&i;
  %let trt&i = %scan(&trtvar,&i, %str( ));
%end;
put;
run;

%__getcntg(datain=__dataset, 
        unit=&subjid, 
        group=&varby4pop __grouped &trt1 __dec_&trt1 __suff_&trt1 __prefix_&trt1
                  __nline_&trt1 __autospan,        
        cnt=__pop_1, 
        dataout=__pop);
        
/* %__makecodeds_t (vinfods=__VARINFO, dsin=&datasetrrg, outds=__CODES4TRT);  */  

        
%local tmptrt;
%let tmptrt=__grouped &trt1 __dec_&trt1 __suff_&trt1 __prefix_&trt1 __nline_&trt1 __autospan;        

%* MAKE SURE THAT EACH DISTINCT VARBY HAS ALL TREATMENTS;

%if %length(&varby)  %then %do;
  %if  %length(&varbyn4pop)>0 %then %do;
    %local tmp1 tmp2;
    %let tmp1=%sysfunc(tranwrd(&varbyn4pop , %str( ), %str(,)));
    %let tmp2=%sysfunc(tranwrd(&varby4pop  &tmptrt, %str( ), %str(,)));
    data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    put;
    put @1 "   proc sql noprint;";
    put @1 "   create table __poptmp as  select * from ";
    put @1 "    (select distinct &tmp1";
    put @1 "      from __dataset)";
    put @1 "      cross  join";
    put @1 "    (select distinct &tmp2";
    put @1 "      from __pop);";
    put @1 "   quit;";
    put;  
    put @1 "   proc sort data=__pop;";
    put @1 "     by &varby4pop &groupby4pop &tmptrt;";
    put @1 "   run;";
    put;
    put @1 "   proc sort data=__poptmp;";
    put @1 "     by &varby4pop  &tmptrt;";
    put @1 "   run;";
    put;
    put @1 "   data __pop;";
    put @1 "     merge __pop __poptmp;";
    put @1 "     by &varby4pop  &tmptrt;";
    put @1 "     if __grpid=. then __grpid=999;";
      %do i=1 %to &numtrt ;
          put @1 "       if __pop_&i=. then __pop_&i=0;";
      %end;  
    put @1 "   run;";
   
    run;
  %end;
  %else %do;
    %local tmp1 tmp2;
    %let tmp1=%sysfunc(tranwrd(&varby,  %str( ), %str(,)));
    %let tmp2=%sysfunc(tranwrd(&tmptrt, %str( ), %str(,)));
    data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    put;
    put @1 "   proc sql noprint;";
    put @1 "   create table __poptmp as  select * from ";
    put @1 "    (select distinct &tmp1";
    put @1 "      from __dataset)";
    put @1 "      cross join";
    put @1 "    (select distinct &tmp2";
    put @1 "      from __pop);";
    put @1 "   quit;";
    put;  
    put @1 "   proc sort data=__pop;";
    put @1 "     by &varby &trtvar;";
    put @1 "   run;";
    put;
    put @1 "   proc sort data=__poptmp;";
    put @1 "     by &varby &trtvar;";
    put @1 "   run;";
    put;
    put @1 "   data __pop;";
    put @1 "     merge __pop __poptmp;";
    put @1 "     by &varby &trtvar;";
    put @1 "     if __grpid=. then __grpid=999;";
      %do i=1 %to &numtrt ;
          put @1 "       if __pop_&i=. then __pop_&i=0;";
      %end;  
    put @1 "   run;";
    
    put;
   
  run;  
  %end;  
%end;


%if &numtrt>1 %then %do;

  data _null_;
  file "&rrgpgmpath./&rrguri..sas" mod;
  put;
  put @1 "proc sql noprint;";
  put @1 "drop table " %do i=2 %to &numtrt ; "__pop_&i " %end; ";" ;
  put @1 "quit;";
  put;
  run;
%end;

%__makecodeds_t (vinfods=__VARINFO, dsin=&datasetrrg); 

%if %sysfunc(exist(__CODES4TRT_exec)) %then %do;
  
    %local varby4sql;
     proc sql;
     select name into:varby4sql separated by ', ' 
     from __varinfo(where=(upcase(type)='GROUP' and upcase(page) = 'Y')); 
     quit;
      
         
    data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    put;
    put;
    
    %if &nvarby>0 %then %do;
        put "  proc sql;";
        put "  create table varbytbl"; 
        put "  as select distinct &varby4sql"; 
        put "  from __dataset; ";
        put "  quit;";
          
       
        
        put "proc sql;";
        put "  create table __CODES4TRT2 as";
        put "  select * from varbytbl cross join __CODES4TRT;";
        put "quit;";
        
        put " data __CODES4TRT; ";
        put "set __CODES4TRT2;";
        put "run;";
        
     
    %end;
      

    put "data __pop;";
    put "  set __pop;";
    put "  drop __dec_&trtvar;";
    put "run;";
    
    put "proc sql;";
    put "  create table __popx as select * from __pop natural full outer join __CODES4TRT;";
    put "quit;";
    
    
    put "%local __mod_nline __mod_autospan __mod_suff __mod_prefix;";
    put "proc sql noprint;";
    
    put "  select distinct __nline_&trtvar into: __mod_nline";
    put "  separated by ' ' from __popx (where=(not missing(__nline_&trtvar)));";
    
    put "  select distinct __suff_&trtvar into: __mod_suff";
    put "  separated by ' ' from __popx (where=(not missing(__suff_&trtvar)));";

    put "  select distinct __prefix_&trtvar into: __mod_prefix";
    put "  separated by ' ' from __popx (where=(not missing(__prefix_&trtvar)));";
     
    put "  select distinct __autospan into: __mod_autospan";
    put "  separated by ' ' from __popx (where=(not missing(__autospan)));";
        
    put "quit;";
    put ;
   
    put ;
    
    
    put "data __pop;";
    put "  set __popx;";
    put "  if missing(__grpid) then __grpid=999;";
    put "  if missing(__pop_1)  then __pop_1=0;";
    put "  if missing(__grouped)  then __grouped=0;";
    put '  if missing(__autospan)  then __autospan="' '&__mod_autospan' '";';
    put "  if missing(__suff_&trtvar)  then __suff_&trtvar=" '"' '&__mod_suff' '";';
    put "  if missing(__nline_&trtvar)  then __nline_&trtvar=" '"' '&__mod_nline' '";';
    put "  if missing(__prefix_&trtvar)  then __prefix_&trtvar=" '"' '&__mod_prefix' '";';
    put "  run;";


    
    
%end;    
    
data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;    
put @1 "*------------------------------------------------------------------;";
put @1 "* CREATE TREATMENT ID, ENUMERATING ALL TREATMENTS SEQUENTIALLY ;";
put @1 "*------------------------------------------------------------------;";
put;

%local tmp tmp1;
%let tmp =%sysfunc(tranwrd(%sysfunc(compbl(
      __grouped &trtvar /*&trtdec*/)), %str( ), %str(,)));
%let tmp1 = %sysfunc(tranwrd(%sysfunc(compbl(&trtvar)), %str( ), %str(,)));
put @1 "proc sql  noprint;";
put @1 "create table __trt as select distinct ";
put @1 "&tmp";
put @1 "from __pop";
put @1 "order by &tmp1;";
put @1 "quit;";


put;

put;
put @1 "data __trt;";
put @1 "set __trt ;";
put @1 "by &trtvar;";
put @1 "retain __trtid;";
put @1 "if _n_=1 then __trtid=0;";
put @1 "if first.&trtvar then __trtid+1;";
put @1 "run;";
put;
put @1 "*------------------------------------------------------------------;";
put @1 "* MAXTRT IS THE NUMBER OF TREATMENT GROUPS;";
put @1 "*------------------------------------------------------------------;";
put;
put;
put @1 "proc sql noprint;";
put @1 "   select max(__trtid) into:maxtrt separated by ' ' from __trt;";
put @1 "quit;";
put ;

put;
put @1 "*------------------------------------------------------------------;";
put @1 "%* ADD __TRTID VARIABLE TO DATASET WITH POPULATION COUNT;";
put @1 "*------------------------------------------------------------------;";
put;

run;



%__joinds(data1=__pop,
        data2=__trt,
          by = &trtvar,
      mergetype=INNER,
        dataout=__pop);


data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put @1 "data __pop;";
put @1 "set __pop;";
put @1 "__pop = __pop_&numtrt;";
put @1 "run;";


put;
put @1 "*-------------------------------------------------------------------;";
put @1 "* GET HEADER ENTRIES FOR THE TABLE;";
put @1 "*-------------------------------------------------------------------;";
put;
put @1 "data __poph;";
put @1 "set __pop;";
put @1 "length __col __prefix $ 2000;";
put @1 "__overall=0;";
put @1 "__trtvar=1;";

%do i=1 %to &numtrt;
  put @1 "  __rowid=&i;";
  put @1 "  __col='';";
  put @1 "  __prefix=__prefix_&&trt&i;";
  %if %length(&grpinc)=0 %then %do;
    put @1 "  if __nline_&&trt&i='Y' then ";
    put @1 "    __col = cats(__dec_&&trt&i, '//(N=',__pop_&i, ')', ";
    put @1 "      __suff_&&trt&i);";
    put @1 "  else  __col = cats(__dec_&&trt&i,  __suff_&&trt&i);";
  %end;
  %else %do;
    put @1 "  __col = cats(__dec_&&trt&i,  __suff_&&trt&i);";
  %end;
  put @1 "  output;";
%end;

put @1 "run;";
put;

put @1 "*-------------------------------------------------------------------;";
put @1 "* ADD __TRTID TO __DATASET;";
put @1 "*-------------------------------------------------------------------;";
put;

run;

%__joinds(data1=__dataset,
        data2=__trt,
          by = &trtvar,
    mergetype=INNER,
      dataout=__dataset);
      
%if &numtrt>1 %then %do;
  %local nt;
  %let nt = %eval(&numtrt-1);
  
  data _null_;
  file "&rrgpgmpath./&rrguri..sas" mod;
  put;
  put @1 "*------------------------------------------------------------------;";
  put @1 "* DEFINE BREAKOKAT VARIABLE, WHICH HOLD COLUMN NUMBERS;";
  put @1 "* WHERE TABLE IS ALLOWED TO BREAK;";
  put @1 "* THIS HAS EFFECT ONLY IF THERE ARE MORE THAN 1 TREATMENT; ";
  put @1 "*  VARIABLES, AND ALL VALUES OF LAST TREATMENT ARE TO BE KEPT; ";
  put @1 "*  TOGETHER;";
  put @1 "*------------------------------------------------------------------;";
  put ;
  put ;
  put @1 "proc sort data=__pop;";
  put @1 "by &trtvar;";
  put @1 "run;";
  put ;
  put @1 "data __pop;";
  put @1 "  set __pop;";
  put @1 "  by &trtvar;";
  put @1 "  if first.&&trt&nt then __cb=1;";
  put @1 "run;";
  put ;
  put @1 "proc sort data=__pop;";
  put @1 "  by __trtid;";
  put @1 "run;";
  put;
  put @1 "proc sql noprint;";
  put @1 "  select __trtid into:breakokat separated by ' ' ";
  put @1 "    from __pop(where=(__cb=1));";
  put @1 "quit;";
  put;
  run;
%end;


*------------------------------------------------------------------;
* IF CODELIST IS GIVEN FOR GROUPING VARIABLES, CREATE DATASETS
* WITH CODES;
*------------------------------------------------------------------;

/*
CREATE DATASET __GRPCODES_EXEC:
      this dataset contains variable names , decode values 
      (stored in __display_<variable name>), and order (stored in __order_<variable name>)
      of all grouping variables for which codelist was provided. 
      All values/decodes for grouping variables for which codelist was proveded are cross-joined.
      For those grouping variables for which codelist was not provided, dummy __order_<variable name>
      variables are created with null values.
      This dataset is then sorted by __order_vn1, __order__vn2 etc 
      and a variable __orderb=_n_ is added to it
      
      As a by-product, at runtime the datasets __grp_template_&tmp (&tmp is the name of
        grouping variable ) are created and indicated as "group template dataset"
        if __rrgpgminfo, so they are later used by generated program to generate
        "real time" __grpcodes dataset which is a copy of __grpcodes_exec
*/      




%do i=1 %to &ngrpv;
  %local tmp;
  %let tmp = %scan(&groupby,&i, %str( ));
      %__makecodeds (
      vinfods = __varinfo, 
      varname = &tmp, 
      dsin = &dataset, 
        outds = __grp_template_&tmp,
        id = &i);

%end;


*------------------------------------------------------------------;
* CROSS JOIN ALL CODELISTS DATASETS FOR GROUPING VARIABLES;
*------------------------------------------------------------------;
%local gdsset;

proc sql noprint;
  select value into:gdsset separated by ' ' from __rrgpgminfo
    (where=(key='gtemplate'));
quit;



%local ngs;
%let ngs=0;
%if %length(&gdsset)>0 %then 
  %let ngs=%sysfunc(countw(&gdsset, %str( )));

%* ngs is number of groupby variables for which codelist was given;


%if &ngs>0 %then %do;
  %local tmp;
  %let tmp = %scan(&gdsset,1,%str( ));
  
  data __grpcodes_exec;
    set &tmp._exec ;
  run;

  proc sql noprint;
  %do i=2 %to &ngs;
    %local tmp;
    %let tmp = %scan(&gdsset,&i,%str( ));
  
     create table __tmp as select * from __grpcodes_exec
       cross join &tmp._exec ;
     create table __grpcodes_exec as select * from __tmp;
  %end;  
  quit;

  data __grpcodes_exec;
    set __grpcodes_exec;
    if 0 then do;
  
  %do i=1 %to &ngrpv;
  __order_%scan(&groupby,&i, %str( ))=.;
  %end;
    end;
  run;

  proc sort data=__grpcodes_exec;
    by 
    %do i=1 %to &ngrpv; __order_%scan(&groupby,&i, %str( )) %end;;
    
  run;

  data __grpcodes_exec;
    set __grpcodes_exec;
    __orderg = _n_;
    
  run;  
  

  
  /* end of CREATE DATASET __GRPCODES_EXEC: */
  
  
  /* in generated program, CREATE DATASET __GRPCODES which is a copy of runtime dataset __grpcodes_exec */
  
  %local tmp;
  %let tmp = %scan(&gdsset,1,%str( ));
  data _null_;
  file "&rrgpgmpath./&rrguri..sas" mod;
  put;
  
  put; 
  put @1 "data __grpcodes;";
  put @1 "    set &tmp ;";
  put @1 "  run;";
  put;  
  put @1 "proc sql noprint;";
  %do i=2 %to &ngs;
    %local tmp;
    %let tmp = %scan(&gdsset,&i,%str( ));
  
      put @1 "     create table __tmp as select * from __grpcodes";
      put @1 "       cross join &tmp ;";
      put @1 "     create table __grpcodes as select * from __tmp;";
  %end;  
  put @1 "  quit;";
  put;
  put @1 "  data __grpcodes;";
  put @1 "    set __grpcodes;";
  put @1 "    if 0 then do;";
 
  %do i=1 %to &ngrpv;
  put @1 "__order_%scan(&groupby,&i, %str( ))=.;";
  %end;
  put @1 "    end;";
  put @1 "  run;";
  put;
  %local tmp;
  %let tmp=;
  %do i=1 %to &ngrpv;
    %let tmp=&tmp __order_%scan(&groupby,&i, %str( ));
  %end;
  
  put @1 "  proc sort data=__grpcodes;";
  
  put @1 "by &tmp;";
  put @1 "  run;";
  put;  
  put @1 "  data __grpcodes __grptemplate;";
  put @1 "    set __grpcodes;";
  put @1 "    __orderg = _n_;";
  put @1 "  run;  ";
  put;
run;
%end;

/* end of CREATE DATASET __GRPCODES */


*------------------------------------------------------------------------;
* RECORD ORIGINAL GROUPING VARIABLES IN __PGMINFO;
* NEXT STEPS MAY NEED TO UPDATE THEM;
*------------------------------------------------------------------------;

  proc sql noprint;
  insert into __rrgpgminfo (key, value, id) values ("newgroupby", "&groupby", 99);
  insert into __rrgpgminfo (key, value, id) values ("oldgroupby", "&groupby", 99);
  quit;

*------------------------------------------------------------------;
* OBTAIN LIST OF VARIABLES FOR THE TABLE AND THEIR TYPES;
*------------------------------------------------------------------;

%local numvar i  ;
%*  NUMVAR IS NUMBER OF VARIABLES IN __VARINFO;

proc sql noprint;
select count(*) into:numvar from __varinfo;
quit;

%do i=1 %to &numvar;
  %local name&i type&i;
%end;

data __varinfo;
set __varinfo;
call symput('name'||compress(put(varid,12.)), trim(left(name)));
call symput('type'||compress(put(varid,12.)), trim(left(type)));
run;


data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put @1 "*------------------------------------------------------------------;";
put @1 "* INITIALIZE DATASET WITH TABLE CONTENT;";
put @1 "*------------------------------------------------------------------;";
put;
put @1 "data __all;";
put @1 "if 0;";
put @1 "run;";
put;
put @1 "data __overallstats;";
put @1 "if 0;";
put @1 "run;";
put;
put @1 "*------------------------------------------------------------------;";
put @1 "* CACLULATE REQUESTED STATISTICS;";
put @1 "*------------------------------------------------------------------;";
put;
run;


%do i=1 %to &numvar;
  %if &&type&i=CAT %then %do;
  
    %__cnts (
         dsin  = __dataset,
      dsinrrg  = &datasetrrg,
      tabwhere = %nrbquote(&tabwhere), 
          unit = %nrbquote(&subjid), 
         varid = &i, 
 groupvars4pop = &groupby4pop, 
groupvarsn4pop = &groupbyn4pop,
       byn4pop = &varbyn4pop ,
        by4pop = &varby4pop ,       
       trtvars = %cmpres(&trtvar),
    %if %upcase(&warnonnomatch) ne Y %then %do;
     warn_on_nomatch=0,
    %end;     
       aetable = %upcase(&aetable),
         outds = __fcat&i);

    data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    put;

    put;
    put @1 "data __all;";
    put @1 "set __all __fcat&i (in=__a);";
    put @1 "if __a then __grptype=1;";
    put @1 "run;";
    put;
    run;

    %* NOTE: __GRPTYPE IS USED TO CORRECTLY SORT RECORDS, SINCE ;
    %* FOR CONDITION LINES USER HAS A CHOICE OF WHETHER OR NOT 
    %* APPLY GROUPING;
  
  %end;


  %if &&type&i=COND %then %do;
  
     %__cond(
         outds = __fcond&i,
         varid = &i,
      tabwhere = %nrbquote(&tabwhere),
          unit = &subjid,
 groupvars4pop = &groupby4pop, 
groupvarsn4pop = &groupbyn4pop,
       byn4pop = &varbyn4pop ,
        by4pop = &varby4pop ,       
        events = %upcase(&aetable),
       trtvars = &trtvar);
      


    data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    put;
    put @1 "data __all;";
    put @1 "set __all __fcond&i ;";
    put @1 "run;";
    put;
    run;

    %* NOTE: __GRPTYPE IS USED TO CORRECTLY SORT RECORDS, ;
    %* SINCE FOR CONDITION LINES;
    %* USER HAS A CHOICE OF WHETHER OR NOT APPLY GROUPING;
    %* MACRO __COND SETS __GRPTYPE TO 0 IF NO GROUPING IS TO BE APPLIED, ;
    %* AND TO 1 IF GROUPING IS TO BE APPLIED TO CONDITION LINE;

  %end;

  
  %if &&type&i=LABEL %then %do;

      %__label(
         outds=__flab&i,
         varid=&i,
     groupvars=&groupby,
            by=&varby ,
    indentbase=&ngrpv,
          dsin=__dataset);
        


    data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    put;    
    put @1 "data __all;";
    put @1 "set __all __flab&i (in=__a);";
    put @1 "if __a then __grptype=1;";
    put @1 "run;";
    put;
    run;

    %* NOTE: __GRPTYPE IS USED TO CORRECTLY SORT RECORDS, SINCE ;
    %* FOR CONDITION LINES USER HAS A CHOICE OF WHETHER OR NOT 
    %* APPLY GROUPING;

  %end;


  %if &&type&i=CONT %then %do;
  %__cont (
         varid=&i,
      tabwhere=%nrbquote(&tabwhere), 
          unit=&subjid, 
 groupvars4pop=&groupby4pop, 
groupvarsn4pop=&groupbyn4pop,
       byn4pop=&varbyn4pop ,
        by4pop=&varby4pop ,
     trtvars=&trtvar,
       outds=__fcont&i);


    data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    put;
    put @1 "data __all;";
    put @1 "set __all __fcont&i (in=__a);";
    put @1 "if __a then __grptype=1;";
    put @1 "run;";
    put;
    run;

  %end;

%end;


data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put @1 "data __all;";
put @1 "set __all;";
put @1 "__sid=1;";
put @1 "run;";
put;
put @1 "*------------------------------------------------------------------;";
put @1 "* CHECK IF DATASET WITH CALCULATED STATISTICS HAS ANY RECORDS;";
put @1 "*------------------------------------------------------------------;";
put;
put @1 '%local dsid rc numobs;';
put @1 '%let dsid = %sysfunc(open(__all));';
put @1 '%let numobs = %sysfunc(attrn(&dsid, NOBS));';
put @1 '%let rc = %sysfunc(close(&dsid));';
put;
put @1 '%if &numobs=0 %then %do;';
put @1 '  %put  DATASET WITH STATISTICS HAS NO RECORDS, ;';
put @1 '  %put  SKIP TO MACRO GENERATING TABLE;';
put @1 "     data __fall;";
put @1 "     if 0;";
put @1 "  __col_0 = '';";
put @1 "  __indentlev = 0;";
put @1 "  __ROWID = 0;";
put @1 "     run;";
put;
put @1 '  %let maxtrt=1;';
put;
put @1 '     %goto dotab;';
put @1 '%end;';
put;
run;

*------------------------------------------------------------------------;
* ADD OVERALL STATISTICS;
*------------------------------------------------------------------------;
%local ovorder;
%let ovorder=0;

data __varinfo;
  set __varinfo;
  numovs = countw(ovstat, ' ');
run;
proc sql noprint;
  select max(numovs) into:ovorder separated by ' ' from __varinfo;
quit; 

%if &ovorder>0 %then %do;

  %local catblocks numcatblocks condblocksg condblocksng;
  proc sql noprint;
    select varid into:catblocks separated by ' ' from __varinfo
    where upcase(type)='CAT';
    select count(*) into:numcatblocks separated by ' ' from __varinfo
    where upcase(type)='CAT';
    %do ii=1 %to &numcatblocks;
       %local cb&ii cbname&ii;
       %let cb&ii = %scan(&catblocks, &ii, %str( ));
       select name into:cbname&ii separated by ' '
         from __varinfo (where=(varid = &&cb&ii));
    %end;
    select varid into:condblocksg separated by ' ' from __varinfo
    where (upcase(type)='COND' and upcase(grouping)='Y') or upcase(type)='CONT';
    select varid into:condblocksng separated by ' ' from __varinfo
    where upcase(type)='COND' and upcase(grouping) ne 'Y';
  quit;

  data _null_;
  file "&rrgpgmpath./&rrguri..sas" mod;
  put;
  
  put @1 "*---------------------------------------------------------------;";
  put @1 "* ADD OVERALL STATISTICS TO DATASET __ALL;";
  put @1 "*---------------------------------------------------------------;";
  put;
 
  %if %upcase(&aetable) = N %then %do;
    %do i=1 %to &ovorder;
    
      %* MERGE IN CONDITION BLOCKS WITHOUT GROUPING;
      put @1 '%let k = %eval(&maxtrt' "+&i);";
      
      %if %length(&condblocksng) %then %do;      
      put @1 "proc sort data=__overallstats ";
      put @1 "  (where=(__order=&i and __blockid in (&condblocksng) ))";      
      put @1 "  out = __os&i;";
      put @1 "  by &varby __blockid;";
      put @1 "run;";
      put;
      put @1 "proc sort data=__all;";
      put @1 "  by &varby __blockid;";
      put @1 "run;";
      put;
      put @1 "data __all;";
      put @1 "  merge __all (in=__a) ";
      put @1 "       __os&i(keep = &varby  __blockid  __stat_value __stat_align);";
      put @1 "by &varby __blockid;";
      put @1 'length __col_&k $ 2000;';
      put @1 "if __a;";
      put @1 "__align = trim(left(__align))||' '||trim(left(__stat_align));";
      put @1 "if first.__blockid and __blockid in (&condblocksng) " 'then __col_&k=__stat_value;';
      put @1 'drop __stat_value;';
      put @1 "run;";
      put;
      %end;
     %* MERGE IN ALL OTHER BLOCKS;
     %if %length(&condblocksg.&catblocks) %then %do;      
     
      put @1 "proc sort data=__overallstats";
      put @1 "  (where=(__order=&i and __blockid in (&condblocksg &catblocks) ))";          
      put @1 "  out = __os&i;";
      put @1 "  by &varby &groupby __blockid;";
      put @1 "run;";
      put;
      put @1 "proc sort data=__all;";
      put @1 "  by &varby &groupby __blockid;";
      put @1 "run;";
      put;
      put @1 "data __all;";
      put @1 "  merge __all (in=__a) ";
      put @1 "       __os&i(keep = &varby &groupby __blockid  __stat_value __stat_align);";
      put @1 "by &varby &groupby __blockid;";
      put @1 'length __col_&k $ 2000;';
      put @1 "if __a;";
      put @1 "__align = trim(left(__align))||' '||trim(left(__stat_align));";
      put @1 "if first.__blockid and __blockid in (&condblocksg &catblocks) " 'then __col_&k=__stat_value;';
      put @1 'drop __stat_value;';
      put @1 "run;";
      put;
     %end;      
    %end;
  %end;  
  %else %do;
    %do i=1 %to &ovorder;
      put @1 '%let k = %eval(&maxtrt' "+&i);";
      %* MERGE IN CONDITION BLOCKS WITHOUT GROUPING;
      
      %if %length(&condblocksng) %then %do;
      put @1 "proc sort data=__overallstats ";
      put @1 "  (where=(__order=&i and __blockid in (&condblocksng) ))";
      put @1 "  out = __osa&i;";
      put @1 "  by &varby __blockid;";
      put @1 "run;";
      put;
      put @1 "proc sort data=__all;";
      put @1 "  by &varby __blockid;";
      put @1 "run;";
      put;
      put @1 "data __all;";
      put @1 "  merge __all (in=__a) ";
      put @1 "       __osa&i(keep = &varby  __blockid  __stat_value __stat_align);";
      put @1 "by &varby __blockid;";
      put @1 'length __col_&k $ 2000;';
      put @1 "if __a;";
      put @1 "__align = trim(left(__align))||' '||trim(left(__stat_align));";
      put @1 "if first.__blockid and __blockid in (&condblocksng) " 'then __col_&k=__stat_value;';
      put @1 'drop __stat_value;';
      put @1 "run;";
      put;
      %end;
      %if %length(&condblocksg) %then %do;
      %* MERGE IN CONT BLOCKS AND CONDITION BLOCKS WITH GROUPING;
      put @1 "proc sort data=__overallstats ";
      put @1 "  (where=(__order=&i and __blockid in (&condblocksg) ))";
      put @1 "  out = __osa&i;";
      put @1 "  by &varby &groupby __blockid;";
      put @1 "run;";
      put;
      put @1 "proc sort data=__all;";
      put @1 "  by &varby &groupby __blockid;";
      put @1 "run;";
      put;   
      put @1 "data __all;";
      put @1 "  merge __all (in=__a) ";
      put @1 "       __osa&i(keep = &varby &groupby __blockid  __stat_value __stat_align);";
      put @1 "by &varby &groupby __blockid;";
      put @1 'length __col_&k $ 2000;';
      put @1 "if __a;";
      put @1 "__align = trim(left(__align))||' '||trim(left(__stat_align));";
      put @1 "if first.__blockid and __blockid in (&condblocksg) " 'then __col_&k=__stat_value;';
      put @1 'drop __stat_value;';
      put @1 "run;";
      put;
      %end;
      %* MERGE IN CATEGORICAL VARIABLES BLOCKS ;
      %do ii=1 %to &numcatblocks;
      put @1 '%local hasdata;';
      put @1 '%let hasdata=0;';
      put;
      
      put @1 "data __tmp;";
      put @1 "  set __overallstats";
      put @1 "  (where=(__order=&i and __blockid = &&cb&ii ));";
      put @1 "if _n_=1 then call symput('hasdata','1');";
      put @1 "run;";  
      put;
      put @1 '%if &hasdata=1  %then %do;';
      put;
      put @1 "proc sort data=__all;";
      put @1 "  by &varby __grpid &groupby __blockid &&cbname&ii;";
      put @1 "run;";
      put;
      put @1 "proc sort data=__overallstats ";
      put @1 "  (where=(__order=&i and __blockid = &&cb&ii ))";
      put @1 "  out = __osb&i;";
      put @1 "  by &varby __grpid &groupby __blockid &&cbname&ii;";
      put @1 "run;";
      put;
      put @1 "data __all;";
      put @1 "  merge __all (in=__a) ";
      put @1 "       __osb&i(keep = &&cbname&ii __grpid &varby &groupby __blockid ";
      put @1 "       __stat_value __stat_align);";
      put @1 "by &varby __grpid &groupby __blockid &&cbname&ii;";
      put @1 'length __col_&k $ 2000;';
      put @1 "if __a;";
      put @1 "__align = trim(left(__align))||' '||trim(left(__stat_align));";
      put @1 "if first.&&cbname&ii and __blockid = &&cb&ii " 'and __col_1 ne "" then __col_&k=__stat_value;';
      put @1 'drop __stat_value;';
      put @1 "run;";
      put;
      put @1 '%end;';
      %end;
    %end;  
  %end;
  put;  
  put @1 "*---------------------------------------------------------------;";
  put @1 "* ADD OVERALL STATISTICS HEADER TO __POPH DATASET;";
  put @1 "*---------------------------------------------------------------;";
  put;
  put ;
  put @1 "proc sort data=__overallstats nodupkey;";
  put @1 "  by __order  ;";
  put @1 "run;";
  put;
  %if %length(&varby) %then %do;
  %local tmp;
  %let tmp = %sysfunc(tranwrd(&varby, %str( ), %str(,))) ;
  put @1 "proc sql noprint;";
  put @1 "    create table __tmp as ";
  put @1 "  select * from __overallstats (drop=&varby) cross join";
  put @1 "  (select distinct &tmp from __poph);";
  put @1 "  create table __overallstats as select * from __tmp;";
  put @1 "  quit;";
  put;  
  put @1 "  proc sort data=__overallstats;";
  put @1 "    by __order &varby;";
  put @1 "  run;";
  %end;
  put @1 "data __poph0;";
  put @1 "set __poph;";
  put @1 "if _n_=1;";
  put @1 "keep __autospan;";
  put @1 "run;";
  
  put;
  put @1 "data __overallstats;";
  put @1 "set __overallstats ;";
  put @1 "  by __order &varby;";
  put @1 '  retain __trtid &maxtrt;';
  put @1 "if first.__order  then __trtid+1;"; 
  put @1 "    __col = __stat_label;";
  put @1 "    __align = 'C';";
  put @1 "    __rowid = 1;";
  put @1 "    __grpid = 999;";
  put @1 "    __overall = 1;";
  put @1 "run;";
  put;
  put @1 "data __overallstats;";
  put @1 "  set __overallstats ;";
  put @1 "  if _n_=1 then set __poph (drop=__trtid __col __overall);";
  put @1 "  run;";
  put;
  put @1 "data __poph;";
  put @1 "  set __poph __overallstats;";
  put @1 "run;";
  put;

  put @1 '%let maxtrt=%eval(&maxtrt' "+&ovorder);";
  run;

%end;


*------------------------------------------------------------------------;
* ADD GROUPING VARIABLES LABELS;
*------------------------------------------------------------------------;
 
%if &ngrpv>0 or &nvarby>0 %then %do;


  %local decodestr  vbdecodestr  ;
  %* THIS IS LIST OF ALL DECODE VARIABLES FOR GROUPING VARIABLES;
  %* GRPDEC_&grp1, GRPDEC_&grp2, ETC ARE DECODES FOR &GRP1, &GRP2, ....;

  proc sql noprint;
  %do i=1 %to &ngrpv;
     %local grp&i  grplab&i tmp;
     %let grp&i = %scan(&groupby, &i, %str( ));
     %let tmp = &&grp&i;
     %local grpdec_&&grp&i;
     select distinct decode into:grpdec_&&grp&i separated by ' '
      from __varinfo where upcase(name)=upcase("&&grp&i") 
           and type='GROUP' and page ne 'Y';
     select distinct label into:grplab&i separated by ' '
      from __varinfo where upcase(name)=upcase("&&grp&i") 
           and type='GROUP' and page ne 'Y';
     %let decodestr=&decodestr &&grpdec_&tmp;
  %end;
 
  %do i=1 %to &nvarby;
     %local vby&i  vblabel&i;
     %let vby&i = %scan(&varby, &i, %str( ));
     %let tmp = &&vby&i;
     %local vbdec_&&vby&i;
     select distinct decode into:vbdec_&&vby&i separated by ' '
      from __varinfo where upcase(name)=upcase("&&vby&i") 
          and type='GROUP' and page='Y';
     select distinct label into:vblabel&i separated by ' '
      from __varinfo where upcase(name)=upcase("&&vby&i") 
         and type='GROUP' and page='Y';
     %let decodestr=&decodestr &&vbdec_&tmp;
     %let vbdecodestr=&vbdecodestr &&vbdec_&tmp;
   %end;
  quit;

  
   
  %local grps_w_cl grps_no_cl tmps;
  %* grps_w_cl: list of grouping variables with codelist;
  %* grps_no_cl: list of grouping variables without codelist;
  

  %if %sysfunc(exist(__grpcodes_exec)) %then %do;
  
   data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    put;
    put @1 "data __grpcodes;";
    put @1 "  set __grpcodes;";
    put @1 "  if 0 then do;";
        %do i=1 %to &ngrpv;
    put @1 "    __order_&&grp&i=.;";
        %end;
    put @1 "  end;";
    put @1 "run;";
    put;
   run;

    %local dsid rc varnum ;
    %let dsid = %sysfunc(open(__grpcodes_exec));
    %do i=1 %to &ngrpv;
      %let varnum = %sysfunc(varnum(&dsid, &&grp&i));
      %if &varnum>0 %then %let grps_w_cl=&grps_w_cl &&grp&i;
      %else %let grps_no_cl=&grps_no_cl &&grp&i;
    %end;
    %let rc = %sysfunc(close(&dsid));
  %end;
  %else %do;
    %let grps_no_cl=&groupby;
  %end;
  
  
   data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    put @1 "*------------------------------------------------------------;";
    put @1 "* GROUP VARIABLES  WITH CODELIST:&grps_w_cl ;";
    put @1 "* GROUP VARIABLES  WITH NO CODELIST:&grps_NO_cl &VARBY;";
    put @1 "*------------------------------------------------------------;";
    put;    
  RUN; 
  
  %* case 1: no grouping variables;
  %* Case 2: no grouping variable has codelist;
  %* Case 3: all grouping variables have codelist;  
  %* Case 4: some grouping variables have codelist, other do not;
  
  %*-------------------------------------------------------------------------;
  %* Case1: no grouping variables - only create __varbylab ;
  %if &ngrpv=0 %then %do;
   
    %local tmp tmp1;
    %let tmp = ;
    %let tmp1=;
    %if %length(&varby) %then %let tmp = &tmp __varbylab;
    %do i=1 %to &nvarby;
      %let tmp1=&tmp1  __vblabel&i;
    %end;
    %local tmpdec;
    %if %length(&decodestr)>0 %then %do;
      %let tmpdec = %sysfunc(tranwrd(&varby &decodestr, %str( ), %str(,))); 
    %end;
    data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
   
    put @1 "*------------------------------------------------------------;";
    put @1 "* CASE: NO GROUPING VARIABLES - ONLY CREATE __VARBYLAB ;";
    put @1 "*------------------------------------------------------------;";
    put;    
    %if %length(&tmp1) %then %do; length &tmp1 $ 2000; %end;
    put;
    %do j=1 %to &nvarby;
    __vblabel&j = quote(trim(left(symget("vblabel&j"))));
    %end;
    %if %length(&decodestr)>0 %then %do;
      put @1 "*---------------------------------------------------------;";
      put @1 "* ADD DECODES FROM __DATASET TO __ALL;";
      put @1 "*---------------------------------------------------------;";
      put;
      put @1 "proc sql noprint;";
      put @1 "  create table __tmpdec as select distinct &tmpdec";
      put @1 "    from __dataset;";
      put @1 "  create table __tmpdec2 as select * from";
      put @1 "    __tmpdec natural right join __all;";
      put @1 "  create table __all as select * from __tmpdec2;  ";
      put @1 "quit;";
      put;
    %end;
    put;
    put @1 "*---------------------------------------------------------;";
    put @1 "* CREATE __VARBYLAB WITH DECRIPTION OF PAGE-BY VARIABLES  ;";
    put @1 "*---------------------------------------------------------;";
    put;
    put @1 "data __all;";
    put @1 "set __all;";
    put @1 "length __varbylab $ 2000;";
    put;
    put @1 "   __varbylab='';";
    
    %do j=1 %to &nvarby;
       %let tmp = &&vby&j;
       %if %length(&&vblabel&j) %then %do;
            put @1 " __varbylab =strip(__varbylab)||' '||" __vblabel&j ";";
       %end;
       %if %length(&&vbdec_&tmp) %then %do;
            put @1 "   __varbylab = trim(left(__varbylab))||' '||&&vbdec_&tmp;";
       %end;
       %else %do;
            put @1 "   __varbylab=trim(left(__varbylab))||' '||&&vby&j;";
       %end;
    %end;
    put @1 "run;";
    put;
    run;
  
  %end;
 
 %*-------------------------------------------------------------------------;
 
  %if &ngrpv>0 and %length(&grps_w_cl)=0 %then %do; 
    %* Case2: no grouping variables have codelist;
    %* create __varbylab (if &varby present) and __grplabel_&&grp&i variables;

   
    %local tmp tmp1 tmpdec;
    %let tmp = ;
    %let tmp1=;
    %do i=1 %to &ngrpv;
      %let tmp = &tmp __grplabel_&&grp&i;
      %let tmp1 = &tmp1 __grplab&i;
    %end;
    %if %length(&varby) %then %let tmp = &tmp __varbylab;
    %do i=1 %to &nvarby;
      %*let tmp=&tmp  __vblabel&i;
      %let tmp1=&tmp1  __vblabel&i;
    %end;
    
    /*
    %if %length(&decodestr)>0 %then %do;
      %let tmpdec = %sysfunc(tranwrd(&varby &groupby &decodestr, %str( ), %str(,))); 
    %end;
    */
    
    
    
    data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    put @1 "*------------------------------------------------------------;";
    put @1 "* CASE: NO GROUPING VARIABLES HAVE CODELIST;";
    put @1 "*------------------------------------------------------------;";
    put;    
    %if %length(&tmp1) %then %do; length &tmp1 $ 2000; %end;
    %do i=1 %to &ngrpv;
      __grplab&i = quote(trim(left(symget("grplab&i"))));
    %end;
    %do j=1 %to &nvarby;
      __vblabel&j = quote(trim(left(symget("vblabel&j"))));
    %end;
    put;
/*
    %if %length(&decodestr)>0 %then %do;
      put @1 "*---------------------------------------------------------;";
      put @1 "* ADD DECODES FROM __DATASET TO __ALL;";
      put @1 "*---------------------------------------------------------;";
      put;
      put @1 "proc sql noprint;";
      put @1 "  create table __tmpdec as select distinct &tmpdec";
      put @1 "    from __dataset;";
      put @1 "  create table __tmpdec2 as select * from";
      put @1 "    __tmpdec natural right join __all;";
      put @1 "  create table __all as select * from __tmpdec2;  ";
      put @1 "quit;";
      put;
    %end;
*/

    %do i=1 %to &ngrpv;
      %local ttt;
      %let ttt=&&grp&i;
      %if %length(&&grpdec_&ttt)>0 %then %do;
        %let tmpdec = %sysfunc(tranwrd(&&grp&i &&grpdec_&ttt, %str( ), %str(,))); 
         put;
         put @1 "*-------------------------------------------------------------------------;";
         put @1 "* ADD DECODES FOR &&grp&i FROM __DATASET TO __ALL; ";
         put @1 "*-------------------------------------------------------------------------;";
         put;
         put @1 "proc sql noprint;";
         put @1 "create table __tmpdec as select distinct &tmpdec";
         put @1 " from __dataset;";
         put @1 "create table __tmpdec2 as select * from";
         put @1 " __tmpdec natural right join __all;";
         put @1 "create table __all as select * from __tmpdec2;  ";
         put @1 "quit;";
         put;
      %end;  
        put;  
    %end;
    put;    
    %if %length(&vbdecodestr) %then %do;
       put @1 "*-------------------------------------------------------------------------;";
       put @1 "* ADD DECODES FOR &varby FROM __DATASET TO __ALL; ";
       put @1 "*-------------------------------------------------------------------------;";
       put;
       %let tmpdec = %sysfunc(tranwrd(&varby &vbdecodestr, %str( ), %str(,))); 
       put @1 "proc sql noprint;";
       put @1 "   create table __tmpdec as select distinct &tmpdec";
       put @1 "     from __dataset;";
       put @1 "   create table __tmpdec2 as select * from";
       put @1 "     __tmpdec natural right join __all;";
       put @1 "   create table __all as select * from __tmpdec2;  ";
       put @1 " quit;     ";
       put;
    %end;
        
    
    %if %length(&varby) %then %do;
      put @1 "*---------------------------------------------------------;";
      put @1 "* CREATE __VARBYLAB WITH DECRIPTION OF PAGE-BY VARIABLES  ;";
    %end;
    %if %length(&groupby) %then %do;
      put @1 "*---------------------------------------------------------;";
      put @1 '* CREATE __grplabel_&grp1... __grplabel_&grpX;';
      put @1 "* WITH DISPLAY VALUES OF GROUPING VARIABLES  ;";
    %end;
    put @1 "*---------------------------------------------------------;";  
    put;
    put @1 "data __all;";
    put @1 "length &tmp $ 2000;";
    put @1 "set __all;";
    put;
    put @1 "if 0 then do;";
    %do i=1 %to &ngrpv;
        put @1 "   __grplabel_&&grp&i='';";
        put @1 "   __order_&&grp&i =.;";
        put @1 "   call missing(&&grp&i);";
    %end;
    put @1 "end;";
    put;
    put @1 "   __varbylab='';";
    %do i=1 %to &ngrpv;
       %let tmp = &&grp&i;
       put @1 " __grplabel_&&grp&i =" __grplab&i ";";
       %if %length(&&grpdec_&tmp) %then %do;
         put @1 " __grplabel_&&grp&i = strip(__grplabel_&&grp&i)||' '||strip(&&grpdec_&tmp);";
       %end;
       %else %do;
         put @1 " __grplabel_&&grp&i = strip(__grplabel_&&grp&i)||' '||strip(&&grp&i);";
       %end;
    %end;    
  
    %if %length(&varby) %then %do;
      
      %do j=1 %to &nvarby;
         %let tmp = &&vby&j;
         %if %length(&&vblabel&j) %then %do;
              put @1 " __varbylab =strip(__varbylab)||' '||" __vblabel&j ";";
         %end;
         %if %length(&&vbdec_&tmp) %then %do;
              put @1 "   __varbylab = trim(left(__varbylab))||' '||&&vbdec_&tmp;";
         %end;
         %else %do;
              put @1 "   __varbylab=trim(left(__varbylab))||' '||&&vby&j;";
         %end;
      %end;
    %end;
    put @1 "run;";
    put;
    run;
    
  %end;
  
  %*-------------------------------------------------------------------------;
 
  %if &ngrpv>0 and %length(&grps_no_cl)=0 %then %do; 
    %* Case3: all grouping variables have codelist;
  
    
    %local tmp tmp1 tmpdec tmp2 vdecodestr;
    %let tmp = ;
    %let tmp1=;
    
    %do i=1 %to &ngrpv;
      %let tmp = &tmp __grplabel_&&grp&i;
      %let tmp1 = &tmp1 __grplab&i;
    %end;
    
    %if %length(&varby) %then %let tmp = &tmp __varbylab;
    
    %do i=1 %to &nvarby;
      %let tmp1=&tmp1  __vblabel&i;
      %let tmp2 = &&vby&i;
      %let vdecodestr=&vdecodestr &&vbdec_&tmp2;
    %end;
    
    %if %length(&vdecodestr)>0 %then %do;
      %let tmpdec = %sysfunc(tranwrd(&varby &vdecodestr, %str( ), %str(,))); 
    %end;
   
    data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    put @1 "*------------------------------------------------------------;";
    put @1 "* CASE: ALL GROUPING VARIABLES HAVE CODELIST;";
    put @1 "*------------------------------------------------------------;";
    put;     
    %if %length(&tmp1) %then %do; length &tmp1 $ 2000; %end;
    %do i=1 %to &ngrpv;
      __grplab&i = quote(trim(left(symget("grplab&i"))));
    %end;
    %do j=1 %to &nvarby;
      __vblabel&j = quote(trim(left(symget("vblabel&j"))));
    %end;
    %if %length(&vdecodestr)>0 %then %do;
      put @1 "*---------------------------------------------------------;";
      put @1 "* ADD DECODES FOR BY-PAGE VARIABLES FROM __DATASET TO __ALL;";
      put @1 "*---------------------------------------------------------;";
      put;
      put @1 "proc sql noprint;";
      put @1 "  create table __tmpdec as select distinct &tmpdec";
      put @1 "    from __dataset;";
      put @1 "  create table __tmpdec2 as select * from";
      put @1 "    __tmpdec natural right join __all;";
      put @1 "  create table __all as select * from __tmpdec2;  ";
      put @1 "quit;";
      put;
    %end;    
    put;
    %* todo: need to fix this?;
    /*
    put @1 "*---------------------------------------------------------------------;";
    put @1 "* MERGE __ALL DATASET WITH __GRPCODES DATASET TO GET ORDER AND ;";
    put @1 "*   DECODES FOR GROUPING VARIABLES;";
    put @1 "*---------------------------------------------------------------------;";
    put;
    put;
    %if %length(&varby.&vdecodestr) %then %do;
    put @1 "proc sql noprint;";
    put @1 "create table __tmp1 as select * from (select distinct ";
    put @1 "%sysfunc(tranwrd( %sysfunc(compbl(&varby &vdecodestr)), %str( ), %str(,))) ";
    put @1 " from __all) cross join";
    put @1 "(select * from __grpcodes);";
    put @1 "quit;";
    %end;
    %else %do;
    put @1 "data __tmp1;";
    put @1 "set __grpcodes;";
    put @1 "run;";
    put;
    %end;
    put;
    put @1 "proc sort data=__all;";
    put @1 "  by  &varby &groupby;";
    put @1 "run;";
    put;
    put @1 "proc sort data=__tmp1  nodupkey;";
    put @1 "  by &varby &groupby;";
    put @1 "run;";
    put;
    put @1 "data __all;";
    put @1 "  merge __tmp1  __all (in=__a) ;";
    put @1 "  by  &varby &groupby;";
    put @1 "  if __a;";
    put @1 "run;";
    put;
    */
    /*
    %if %length(&vdecodestr) %then %do;
    put;
    put @1 "*---------------------------------------------------------------------;";
    put @1 "* GET DECODES FOR &varby;";
    put @1 "*---------------------------------------------------------------------;";    
    put;
    put @1 " proc sort data=__all;";
    put @1 "   by &varby;";
    put @1 " run;";
    put;    
    put @1 "    proc sort data=__grpcodes out=__tmpgrpcodes (keep=&varby &vdecodestr);";
    put @1 "       by &varby;";
    put @1 "    run;";
    put;    
    put @1 "    data __all;";
    put @1 "      merge __tmpgrpcodes __all (in=__a) ;";
    put @1 "      by &varby;";
    put @1 "      if __a;";
    put @1 "    run;    ";
    put;
    %end;    
    */
    %do i=1 %to &ngrpv;
    PUT;
    put @1 "*---------------------------------------------------------------------;";
    put @1 "* GET DECODES FOR &&GRP&I;";
    put @1 "*---------------------------------------------------------------------;";    
      %local ttt;
      %let ttt=&&grp&i;
 
    put @1 "    proc sort data=__all;";
    put @1 "      by &&grp&i;";
    put @1 "    run;";
    put;    
    put;
    put @1 "    proc sort data=__grpcodes out=__tmpgrpcodes (keep=&&grp&i &&grpdec_&ttt __order_&&grp&i) nodupkey;";
    put @1 "      by &&grp&i;";
    put @1 "    run;";
    put;    
    put @1 "    data __all;";
    put @1 "      merge __tmpgrpcodes __all (in=__a) ;";
    put @1 "      by &&grp&i;";
    put @1 "      if __a;";
    put @1 "    run;    ";
    put;    
    %end;
    
    
    
    %if %length(&varby) %then %do;
      put @1 "*---------------------------------------------------------;";
      put @1 "* CREATE __VARBYLAB WITH DECRIPTION OF PAGE-BY VARIABLES  ;";
    %end;
    %if %length(&groupby) %then %do;
      put @1 "*---------------------------------------------------------;";
      put @1 '* CREATE __grplabel_&grp1... __grplabel_&grpX;';
      put @1 "* WITH DISPLAY VALUES OF GROUPING VARIABLES  ;";
    %end;
    put @1 "*---------------------------------------------------------;";  
    put;
    put @1 "data __all;";
    put @1 "length &tmp $ 2000;";    
    put @1 "set __all;";
    put;
    put @1 "if 0 then do;";
        %do i=1 %to &ngrpv;
          put @1 "   __grplabel_&&grp&i='';";
          put @1 "   __order_&&grp&i='';";
          put @1 "   call missing(&&grp&i);";
        %end;
    put @1 "end;";
    put;
    put @1 "   __varbylab='';";
    %do i=1 %to &ngrpv;
       %let tmp = &&grp&i;
       put @1 " __grplabel_&&grp&i =" __grplab&i ";";
       %if %length(&&grpdec_&tmp) %then %do;
         put @1 " __grplabel_&&grp&i = strip(__grplabel_&&grp&i)||' '||strip(&&grpdec_&tmp);";
       %end;
       %else %do;
         put @1 " __grplabel_&&grp&i = strip(__grplabel_&&grp&i)||' '||strip(&&grp&i);";
       %end;
    %end;    

    %if %length(&varby) %then %do;
      
      %do j=1 %to &nvarby;
         %let tmp = &&vby&j;
         %if %length(&&vblabel&j) %then %do;
              put @1 " __varbylab =strip(__varbylab)||' '||" __vblabel&j ";";
         %end;
         %if %length(&&vbdec_&tmp) %then %do;
              put @1 "   __varbylab = trim(left(__varbylab))||' '||&&vbdec_&tmp;";
         %end;
         %else %do;
              put @1 "   __varbylab=trim(left(__varbylab))||' '||&&vby&j;";
         %end;
      %end;
    %end;
    put @1 "run;";
    put;
    run;  
  
  
    %let groupby=;
    %do i=1 %to &ngrpv;
      %let groupby = &groupby __order_&&grp&i &&grp&i;
    %end;


    proc sql noprint;
      update __rrgpgminfo set value="&groupby" where key = "newgroupby";
    quit;

  %end;
  
  %*-------------------------------------------------------------------------;
  
  %if &ngrpv>0 and  %length(&grps_w_cl)>0 and %length(&grps_no_cl)>0 %then %do; 
    %* Case4: some grouping variables have codelist other do not;
  
      
    %local tmp tmp1 tmp2 tmp3 tmpdec tmpd;
    
    %let tmp = ;
    %let tmp1=;
    %let tmpdec=;
    
    %do i=1 %to &ngrpv;
      %let tmp = &tmp __grplabel_&&grp&i;
      %let tmp1 = &tmp1 __grplab&i;
    %end;
    
    %if %length(&varby) %then %let tmp = &tmp __varbylab;
    
    %do i=1 %to &nvarby;
      %*let tmp=&tmp  &&vblabel&i;
      %let tmp1=&tmp1  __vblabel&i;
    %end;
    
    %let tmp3 = %sysfunc(tranwrd(&grps_no_cl,%str( ), %str(,)));
    
    %local vdecodestr tmpd ;
    %do i=1 %to &nvarby;
      %let tmp2 = &&vby&i;
      %let vdecodestr=&vdecodestr &&vbdec_&tmp2;
    %end;
    
    %local vdecodestr2;
    %do i=1 %to %sysfunc(countw(&grps_no_cl, %str( )));
        %let tmpd = %scan(&grps_no_cl, &i, %str( ));
        %let vdecodestr2=&vdecodestr2 &&grpdec_&tmpd; 
    %end;
    
    %if %length(&varby.&&grps_no_cl.&vdecodestr.&vdecodestr2)>0 %then %do;
      %local tmpdec2;
      %let tmpdec2=%sysfunc(compbl(&varby &&grps_no_cl &vdecodestr &vdecodestr2));
      %let tmpdec = %sysfunc(tranwrd(&tmpdec2, %str( ), %str(,))); 
    %end;
 
    %*put tmp3=&tmp3;
    %*put tmp2=&tmp2;
    %*put vdecodestr=&vdecodestr;

    data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    put @1 "*------------------------------------------------------------;";
    put @1 "* CASE: SOME GROUPING VARIABLES HAVE CODELIST, OTHERS DO NOT;";
    put @1 "*------------------------------------------------------------;";
    put;     
    %if %length(&tmp1) %then %do; length &tmp1 $ 2000; %end;
    %do i=1 %to &ngrpv;
      __grplab&i = quote(trim(left(symget("grplab&i"))));
    %end;
    %do j=1 %to &nvarby;
      __vblabel&j = quote(trim(left(symget("vblabel&j"))));
    %end;
    put;
    %if %length(&tmpdec)>0 %then %do;
    put;
    put @1 "*-------------------------------------------------------------;";
    put @1 "* CROSSJOIN __GRPCODES DATASET ;";
    put @1 "* (CONTAINING ALL COMBOS OF GROUPING VARIABLES WITH CODELIST);";
    put @1 "* WITH ALL COMBOS OF GROUPING VARIABLES WITHOUT CODELIST);";
    put @1 "*-------------------------------------------------------------;";
    put;
    put @1 "proc sql noprint;";
    put @1 "  create table __tmp1g as select distinct &tmpdec from __dataset;";
    put @1 "  create table __tmp2g as select * from";
    put @1 "    __grpcodes cross join __tmp1g;";
    put @1 "   create table __grpcodes as select * from __tmp2g;";
    put @1 "quit;";
    put;      
    %end;
    /*
    put @1 "*---------------------------------------------------------------------;";
    put @1 "* MERGE __ALL DATASET WITH __GRPCODES DATASET TO GET ORDER AND ;";
    put @1 "*   DECODES FOR GROUPING VARIABLES WITH CODELISTDS;";
    put @1 "*---------------------------------------------------------------------;";
    put;
    put @1 "proc sort data=__all;";
    put @1 "  by &varby &groupby;";
    put @1 "run;";
    put;
    put @1 "proc sort data=__grpcodes nodupkey;";
    put @1 "  by &varby &groupby;";
    put @1 "run;";
    put;
    put @1 "data __all;";
    put @1 "  merge  __grpcodes __all (in=__a) ;";
    put @1 "  by &varby &groupby;";
    put @1 "  if __a;";
    put @1 "run;";
    */
   %if %length(&vdecodestr) %then %do;
    put;
    put @1 "*---------------------------------------------------------------------;";
    put @1 "* GET DECODES FOR &varby;";
    put @1 "*---------------------------------------------------------------------;";    
    put;
    put @1 " proc sort data=__all;";
    put @1 "   by &varby;";
    put @1 " run;";
    put;    
    put @1 "    proc sort data=__tmp1g out=__tmp1g2 nodupkey;";
    put @1 "       by &varby;";
    put @1 "    run;";
    put;    
    put @1 "    data __all;";
    put @1 "      merge __tmp1g2 (keep = &varby &vdecodestr) __all (in=__a ) ;";
    put @1 "      by &varby;";
    put @1 "      if __a;";
    put @1 "    run;    ";
    put;
    %end;    
    %do i=1 %to &ngrpv;
    PUT;
    put @1 "*---------------------------------------------------------------------;";
    put @1 "* GET DECODES FOR &&GRP&I;";
    put @1 "*---------------------------------------------------------------------;";    
      %local ttt;
      %let ttt=&&grp&i;
 
    put @1 "    proc sort data=__all;";
    put @1 "      by &&grp&i;";
    put @1 "    run;";
    put;    
    put @1 "    proc sort data=__grpcodes nodupkey out=__tmpgrpcodes (keep=&&grp&i &&grpdec_&ttt __order_&&grp&i);";
    put @1 "      by &&grp&i;";
    put @1 "    run;";
    put;    
    put @1 "    data __all;";
    put @1 "      merge __tmpgrpcodes __all (in=__a) ;";
    put @1 "      by &&grp&i;";
    put @1 "      if __a;";
    put @1 "    run;    ";
    put;    
    %end;
    

    
    put;
    %if %length(&varby) %then %do;
      put @1 "*---------------------------------------------------------;";
      put @1 "* CREATE __VARBYLAB WITH DECRIPTION OF PAGE-BY VARIABLES  ;";
    %end;
    %if %length(&groupby) %then %do;
      put @1 "*---------------------------------------------------------;";
      put @1 '* CREATE __grplabel_&grp1... __grplabel_&grpX;';
      put @1 "* WITH DISPLAY VALUES OF GROUPING VARIABLES  ;";
    %end;
    put @1 "*---------------------------------------------------------;";  
    put;
    put @1 "data __all;";
    put @1 "length &tmp $ 2000;";
    put @1 "set __all;";
    put;
    put @1 "if 0 then do;";
    %do i=1 %to &ngrpv;
       put @1 "   __grplabel_&&grp&i='';";
       put @1 "   __order_&&grp&i='';";
       put @1 "   call missing(&&grp&i);";
    %end;
    put @1 "end;";
    put;
    put @1 "   __varbylab='';";
    %do i=1 %to &ngrpv;
       %let tmp = &&grp&i;
       put @1 " __grplabel_&&grp&i =" __grplab&i ";";
       %if %length(&&grpdec_&tmp) %then %do;
         put @1 " __grplabel_&&grp&i = strip(__grplabel_&&grp&i)||' '||strip(&&grpdec_&tmp);";
       %end;
       %else %do;
         put @1 " __grplabel_&&grp&i = strip(__grplabel_&&grp&i)||' '||strip(&&grp&i);";
       %end;
    %end;    
  
    %if %length(&varby) %then %do;
      
      %do j=1 %to &nvarby;
         %let tmp = &&vby&j;
         %if %length(&&vblabel&j) %then %do;
              put @1 " __varbylab =strip(__varbylab)||' '||" __vblabel&j ";";
         %end;
         %if %length(&&vbdec_&tmp) %then %do;
              put @1 "   __varbylab = trim(left(__varbylab))||' '||strip(&&vbdec_&tmp);";
         %end;
         %else %do;
              put @1 "   __varbylab=trim(left(__varbylab))||' '||strip(&&vby&j);";
         %end;
      %end;
    %end;
    put @1 "run;";
    put;
    run;  
    
  
  %end;
  
    %let groupby=;
    %do i=1 %to &ngrpv;
      %let groupby = &groupby __order_&&grp&i &&grp&i;
    %end;
  
  
    proc sql noprint;
      update __rrgpgminfo set value="&groupby" where key = "newgroupby";
    quit;
    
%end; 

%**************************************************************;
%*** IF SOME GROUPING VARIABLES HAD "IN=COLUMNS" SPECIFIED;
%*** PERFORM APPRORIATE TRANSFORMATION;
%**************************************************************;



%__transposeg(
  dsin=__ALL, 
  varby=&varby,
  groupby=&groupby,
  trtvar=&trtvar);



%**************************************************************;
%*** IF TREATMENT VARIABLE HAD "IN-COLUMNS=N" SPECIFIED;
%*** PERFORM APPRORIATE TRANSFORMATION;
%**************************************************************;

%__transposet(
  varby=&varby,
  groupby=&groupby,
  trtvar=&trtvar,
  sta=%upcase(&statsacross));

%*****************************************************************;
%* RETRIEVE MODIFFIED LIST OF GROUPING VARIABLES FROM __PGMINFO;
%* (IF SOME GROUPING VARS HAD ACROSS=Y); 
%*****************************************************************;

%local ntrtvar;
%let ntrtvar=1;
proc sql noprint;
  select value into:groupby separated by ' '
    from __rrgpgminfo(where =(key="newgroupby"));
select value into:ntrtvar separated by ' '
    from __rrgpgminfo(where =(key="newtrt"));
quit;  
%if &ntrtvar=1 %then %let ntrtvar=&trtvar;

** todo: if no trtvar due to last step;



%*-------------------------------------------------------------------;
%* IF STATISTICS ARE TO BE PLACED IN-COLUMNS;
%* PERFORM APPRORIATE TRANSFORMATION;
%*-------------------------------------------------------------------;

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;

run;


%if %upcase(&Statsacross)=Y %then %do;


%__transposes(
  dsin=__ALL, 
  varby=&varby,
  groupby=&groupby,
  trtvar=&ntrtvar,
  overall=&ovorder);

%end;

/*
data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
%__rrgpd(ds=__poph);
run;
*/

%local i tmp tmp2 numg;
%let tmp=0;
%let numg=%sysfunc(countw(&groupby,%str( ))); 
%do i=1 %to &numg;
  %let tmp2 = %upcase(%scan(&groupby, &i, %str( )));
  %if %index(&tmp2,%str(__ORDER))=0 and %index(&tmp2,%str(__FORDER))=0 %then %do;
    %let tmp = %eval(&tmp+1);
    %let grp&tmp = &tmp2;
  %end;  
%end;
%let ngrpv=&tmp;  

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put @1 "*-----------------------------------------------------------------;";
put @1 "* SORT TABLE AND ASSIGN ROW ID;";
put @1 "*-----------------------------------------------------------------;";
put;

put @1 "proc sort data=__all;";
put @1 "  by &varby __grptype __tby &groupby __grpid __blockid ";
put @1 "     __order __tmprowid;";
put @1 "run;";
put;
%if %upcase(aetable) ne N %then %do;
PUT @1 "* IF >1 CATVAR SPECIFIED FOR AE TABLE, ;";
put @1 "*   GROUPING VARIABLES ARE REP EATED.;";
put @1 "data __all;";
put @1 "  set __all;";
put @1 "  by &varby __grptype __tby &groupby __grpid __blockid ";
put @1 "     __order __tmprowid;";
put @1 "  if __grpid ne ceil(__grpid) and last.__grpid ";
put @1 "       and not first.__grpid then delete;";
put @1 "run;  ";
put;
put @1 "proc sort data=__all;";
put @1 "  by &varby __grptype __tby &groupby __grpid __blockid ";
put @1 "     __order __tmprowid;";
put @1 "run;";
put;
%end;

run;

%local nn;
%let nn=&ngrpv;
%if %upcase(&Statsacross)=Y %then %let nn=%eval(&ngrpv-1);

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;

put @1 "data __all ;";
put @1 "length __suffix $ 2000;";
put @1 "  set __all;";
put @1 " drop __i __nindentlev;";
put @1 "  if 0 then do; __varlabel=''; __grplabel_0=''; end;";
put @1 "  by &varby __grptype __tby &groupby __grpid __blockid ";
put @1 "     __order __tmprowid;";
put @1 "  array cols{*} __col_:;";
%if &ngrpv>0 %then %do;
put @1 "  array grpl{*} " %do i=1 %to &ngrpv; " __grplabel_&&grp&i " %end;" ;";  
%end;
%else %do;
put "   array grpl{*} __grplabel_0;";
%end;
put @1 "  do __i=1 to dim(cols);";
put @1 "    cols[__i]=trim(left(cols[__i]));";
put @1 "    if compress(cols[__i],'().,:')='' then cols[__i]='';";
put @1 "  end;";
put;  
put @1 "  __ntmprowid=_n_;";
put @1 "  __sid = 1;";
put;

put @1 "    __oldind=__indentlev;";
put @1 "  if __labelline ne 1 and dequote(__varlabel) ne '' ";
put @1 "    and __vtype ne 'COND' then ";
put @1 "    __indentlev=__indentlev+1;";
put @1 "    __nindentlev=__indentlev;";

run;

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
%if %upcase(&aetable) ne N %then %do;
  put @1 "    * ASSIGN CORRECT DISPLAY VALUES TO ROWS ";
  put @1 "         REPRESENTING GROUPING VARIABLES;";
  put @1 "    if __vtype not in ('COND','CONDS','CONDLAB') then do;";
  
  put @1 "      if __grpid ne ceil(__grpid)  then do;";
  put @1 "           __ind = floor(__grpid);";
  put @1 "           if __ind=998 then __ind = &ngrpv;";
  %if %upcase(&Statsacross)=Y and &ngrpv>0 %then %do;
    put @1 "           __indentlev = max(__ind-1,0);";
  %end;
  %else %do;
  put @1 "           __indentlev = max(__ind-1+__oldind-&ngrpv,0);";
  
  %end;
  
  put @1 "           __sid = -&ngrpv+__ind-1;";
  
  put @1 "           __vtype=cats('GLABEL', __ind);";
  put @1 "           __suffix='';";
  put @1 "           __keepn=1;";
  put @1 "           if __ind>0 then __col_0=grpl[__ind];";
  put @1 "       end;";
  put @1 "       else do;";
      %do i=&ngrpv %to 1 %by -1;
        put @1 "         if first.&&grp&i  then do;";
        
          %if %upcase(&Statsacross)=Y and &ngrpv>0 %then %do;
             put @1 "          if __grpid ne 999 then __nindentlev = __indentlev-&ngrpv+__grpid-1;";
             put @1 "          else __nindentlev = __indentlev;";
          %end;
          %else %do;
             put @1 "          __nindentlev = __grpid-2+__indentlev-&ngrpv;";
          %end;
          
          put @1 "          __sid = -&ngrpv+&i-1;";
          put @1 "          __vtype=CATS('GLABEL',&i);";
          put @1 "          if not last.&&grp&i then do;";
          put @1 "          __suffix='';"; 
          put @1 "          __keepn=1;";
          put @1 "          end;";
          put @1 "          __col_0=trim(left(__grplabel_&&grp&i));";
          put @1 "         end;";
      %end;   
      %if &ngrpv>0 %then %do;
  put @1 "                 if __nindentlev ne . then __indentlev = max(0,__nindentlev);";     
      %end;
  put @1 "       end;    ";          
  put @1 "    end;";
  put @1 "    else do;";
  
  put @1 "         __indentlev=max(__oldind,0);";
  put @1 "    end;";
  put;
  
  
  %if &ngrpv>0 %then %do;
  put @1 "    if __col_0='' then __col_0 = 'Missing';";
  %end;
  %else %do;
  put @1 "    if __col_0='' and __vtype ne 'GLABEL0' then __col_0 = 'Missing';";
  %end;
  
  put @1 "    if last.__blockid and __skipline='Y' then __suffix = '~-2n';";
%end;

%else %do;
  %if %upcase(&Statsacross)=Y and &ngrpv>0 %then %do;
    %if &ngrpv>1 %then %do;
       put @1 "     __col_0 = trim(left(__grplabel_&&grp&ngrpv));";
    %end;
  %end;
%end;

run;


data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;

put;
put @1 "  output;";
  
put @1 "  do __i=1 to dim(cols);";
put @1 "    cols[__i]='';";
put @1 "  end;";
put;
run;

%if %upcase(&aetable)=N %then %do;
  data _null_;
  file "&rrgpgmpath./&rrguri..sas" mod;
  
  put @1 "    * CREATE ROWS FOR DISPLAY OF GROUPING VARIABLES;";
  put @1 "    * ASSIGN CORRECT DISPLAY VALUES TO THESE ROWS ;";
    %do i=1 %to &nn;
        put @1 "      if first.&&grp&i then do;";
       %if %upcase(&Statsacross)=Y and &ngrpv>0 %then %do;
           put @1 "     __indentlev=max(&i-1+__oldind-&nn,0);";
       %end;        
       %else %do;
           put @1 "     __indentlev = max(&i-1+__oldind-&ngrpv,0);";** 2009-07-08;       
       %end;
          
        put @1 "        __sid = -&ngrpv+&i-1;";
        put @1 "        __vtype=CATS('GLABEL',&i);";
        put @1 "        __suffix='';";
        put @1 "        __keepn=1;";
        put @1 "        __col_0=trim(left(__grplabel_&&grp&i));";
        put @1 "        output;";
        put @1 "      end;";

    %end;
  run;
%end;

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;

put @1 "  * CREATE ROWS WITH DESCRIPTION OF ANALYSIS VARIABLE;";
put @1 "  if first.__blockid then do;";
put @1 "     if __labelline ne 1 then do;";
put @1 "        __sid=0;";
put @1 "        __suffix='';"; 
%if %upcase(&Statsacross)=Y and &ngrpv>1 %then %do;
  put @1 "        if last.%scan(&groupby,-2, %str( )) then do;";
  put @1 "          __suffix = '~-2n';";
  put @1 "          __keepn=0;";
  put @1 "        end;;";
%end;
%else %do;
  put @1 "        __keepn=1;";
%end;
put @1 "        __indentlev=max(__oldind,0);";

put @1 "        __vtype='VLABEL';";
put @1 "        __col_0 =dequote(__varlabel);";
put @1 "        __align = 'L '||repeat('L '," '&maxtrt);' ;
put @1 "        if __col_0 ne '' then output;";
put @1 "     end;";
put @1 "  end;";
put;
put @1 "run;";
put;
%if &ngrpv=0 and %upcase(&aetable) ne N %then %do;   
  put;
  put @1 "data __all;";
  put @1 "set __all;";
  put @1 "if __vtype='GLABEL0' then delete;";
  put @1 "run;;";
%end;

put @1 "proc sort data=__all;";
put @1 "by __ntmprowid __sid;";
put @1 "run;";
put;
put;
put @1 '%local numobsinall;';
put; 
put @1 "data __all;";
put @1 "set __all end=eof;";
put @1 "if eof then call symput ('numobsinall', cats(_n_));";
put @1 "__tmprowid=_n_;";
%if %upcase(&Statsacross) ne Y /*or &ngrpv<=1*/ %then %do;
  put @1 "if index(__vtype,'GLABEL')>0 then __suffix='';";
%end;
put @1 "drop __ntmprowid;";
put @1 "run;";
put;

put @1 "data __fall;";
put @1 "length __datatype $ 8;";
put @1 "set __all;";
put @1 "__datatype='TBODY';";
put @1 "__rowid=_n_;";
put @1 "array cols {*} __col_:;";
put @1 "  do __i=1 to dim(cols);";
put @1 "     cols[__i]=strip(cols[__i]);";
put @1 "  end;  ";
put @1 "__dis=.; _n=.; __rowt=.; __ord=.; __old=.;";
put @1 "drop __tmprowid  __tby __skipline __rowt: __ord: __label: __grp: ";
put @1 '    __dis: _n: __varlabel __i __old:;';
put @1 "run;";
put;
put;
put @1 "*----------------------------------------------------------------;";
put @1 "  * IF LABEL IS TO SPAN WHOLE TABLE, CREATE __TCOL VARIABLE;";
put @1 "*----------------------------------------------------------------;";
PUT;
put @1 "data __fall;";
put @1 "set __fall;";
put @1 "length __tcol __tmptcol $ 2000;";
put @1 "retain __tcol;";
put @1 "if 0 then do; __wholerow=''; __tcol=''; __tmptcol=''; end;";
put @1 "__oldwr = lag(__wholerow);";
put @1 "__tmptcol = lag(__col_0);";
put @1 "if __oldwr = 'Y' then do;";
put @1 "  __tcol=strip(__tmptcol);";
put @1 "  __fospan=1;";
put @1 "end;";
put @1 "if __wholerow ne 'Y' then output;";
put @1 "drop __oldwr __tmptcol;";
put @1 "run;";
put;
put;
run;



%if %upcase(&aetable)=EVENTSE %then %do;
  
  data _null_;
  file "&rrgpgmpath./&rrguri..sas" mod;
  
  put @1 "*----------------------------------------------------------------;";
  put @1 "  * ADD EVENT COUNT TO TABLE;";
  put @1 "*----------------------------------------------------------------;";
  put;

  put @1 '  data __fall ;';
  put @1 "  set __fall;"; 
  put;
  put @1 '  %do i=1 %to &maxtrt;';
  put @1 '  __col_&i = __colevt_&i ;';
  put @1 '  %end;';
  put ;
  put @1 "  length __nalign $ 2000;";
  put @1 "  __nalign = scan(__align,1,' ');";
  put @1 '  do __i=1 to &maxtrt;';
  put @1 "     __nalign = left(trim(__nalign))||' D';";
  put @1 '  end;';
  put @1 '  __align = trim(left(__nalign));';
  put @1 '  drop __i __nalign; ';
  put @1 "run;";
  
%end;



%if %upcase(&aetable)=EVENTS %then %do;
  
  data _null_;
  file "&rrgpgmpath./&rrguri..sas" mod;
  
  put @1 "*----------------------------------------------------------------;";
  put @1 "  * ADD EVENT COUNT TO TABLE;";
  put @1 "*----------------------------------------------------------------;";
  put;
  put @1 '  data __fall (rename=(%do i=1 %to %eval(2*&maxtrt);';
  put @1 '           __ncol_&i=__col_&i %end;));';
  put @1 "  set __fall (rename=(";
  put @1 '  %do i=1 %to &maxtrt;';
  put @1 '  __col_&i = __ncol_%eval(2*&i-1)';
  put @1 '  __colevt_&i =__ncol_%eval(2*&i)';
  put @1 '  %end;';
  put @1 "  ));";
  put @1 "  length __nalign $ 2000;";
  put @1 "    __nalign = scan(__align,1,' ');";
  put @1 '  do __i=1 to &maxtrt;';
  put @1 "        __nalign = left(trim(__nalign))||' '||";
  put @1 "            trim(left(scan(__align, __i+1, ' ')))||' D';";
  put @1 '  end;';
  put @1 '  __align = trim(left(__nalign));';
  put @1 '  drop __i __nalign; ';
  put @1 "run;";
%end;




%if %upcase(&aetable)=EVENTSES %then %do;
  data _null_;
  file "&rrgpgmpath./&rrguri..sas" mod;
  
  put @1 "*----------------------------------------------------------------;";
  put @1 "  * ADD EVENT COUNT TO TABLE;";
  put @1 "*----------------------------------------------------------------;";
  put;
  put @1 '  data __fall (rename=(%do i=1 %to %eval(2*&maxtrt);';
  put @1 '           __ncol_&i=__col_&i %end;));';
  put @1 "  set __fall (rename=(";
  put @1 '  %do i=1 %to &maxtrt;';
  put @1 '  __colevt_&i = __ncol_%eval(2*&i-1)';
  put @1 '  __col_&i =__ncol_%eval(2*&i)';
  put @1 '  %end;';
  put @1 "  ));";
  put @1 "  length __nalign $ 2000;";
  put @1 "    __nalign = scan(__align,1,' ');";
  put @1 '  do __i=1 to &maxtrt;';
  put @1 "        __nalign = left(trim(__nalign))||' D '||";
  put @1 "            trim(left(scan(__align, __i+1, ' ')));";
  put @1 '  end;';
  put @1 '  __align = trim(left(__nalign));';
  put @1 '  drop __i __nalign; ';
  put @1 "run;";
%end;

run;

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put @1 '%if &numobsinall>1 %then %do;';
put;
put @1 "data __fall;";
put @1 "  merge __fall __fall(firstobs=2 keep=__col_0 __vtype rename=(__col_0=__newcol0 __vtype=__nvtype));";
put @1 "  if index(__newcol0, '~-2n')=1 then do;";
put @1 "    __suffix='~-2n';";
put @1 "  end;";
put @1 "  if index(__col_0, '~-2n')=1 then do;";
put @1 "    __col_0=substr(__col_0,5);";
put @1 "  end;";
put @1 "drop __newcol0;";
put @1 "run;";
put;
put @1 '%end;';
put;
run;

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;

put;
put @1 "*----------------------------------------------------------------;";
put @1 "* GET HEADER FOR THE TABLE;";
put @1 "*----------------------------------------------------------------;";
put;
put @1 "proc sort data=__poph;";
put @1 "by &varby __rowid __trtvar __autospan __prefix;";
put @1 "run;";
put;
put @1 "proc transpose data=__poph out=__head prefix=__col_;";
put @1 "by &varby __rowid __trtvar __autospan __prefix;";
put @1 "id __trtid;";
put @1 "var __col;";
put @1 "run;";
put;
run;

data _null_;
set __repinfo;
file "&rrgpgmpath./&rrguri..sas" mod;
set __repinfo;
colhead1=quote(strip(colhead1));
colhead1   = tranwrd(strip(colhead1),"#lpar","(");
colhead1   = tranwrd(strip(colhead1),"#rpar",")");
colhead1   = tranwrd(strip(colhead1),"#squot","'");

put @1 "data __head;";
put @1 '  length __datatype $ 8 __align __col_0 - __col_&maxtrt $ 2000;';
put @1 "  set __head end=eof;";
put @1 "  by &varby __rowid;";
put @1 '  array __col{*} __col_1-__col_&maxtrt;';
put @1 "  __col_0='';";
%if &nvarby=0 %then %do;
  put @1 "  if eof then __col_0 = " colhead1 ";";
%end;
%else %do;
  put @1 "  if last.&&vby&nvarby then __col_0 = " colhead1 ";";
%end;
put @1 "  __datatype='HEAD';";
put @1 "  __align ='L'||repeat(' C', dim(__col));";
put @1 "  drop  _name_;";
put @1 "run;";
put;
put @1 "*--------------------------------------------------------------------;";
put @1 "* EXTRACT COMMON HEADER TEXT;";
put @1 "*--------------------------------------------------------------------;";
put;
run;


%__spanh(dsin=__head);

%if %upcase(&aetable)=EVENTS   %then %do;

  data _null_;
  file "&rrgpgmpath./&rrguri..sas" mod;
  put;
  put @1 "*--------------------------------------------------------------------;";  
  put @1 "* CREATE EVENT COUNT HEADINGS ;";
  put @1 "*--------------------------------------------------------------------;";
  put;
  %if &nvarby>0 %then %do;
    put @1 "proc sort data=__head;";
    put @1 "by &varby;";
    put @1 "run;";
    put;
  %end;

  put @1 "  data __head ;";
  put @1 "  set __head end=eof ;";
  %if &nvarby>0 %then %do;
    put @1 "by &varby;";
  %end;
  put @1 '  length __ncol_0 %do i=1 %to &maxtrt;  __colevt_&i %end; $ 2000;';
  put @1 "  retain __ncol_0;";
  put @1 '    %do i=1 %to &maxtrt;  ';
  put @1 '    __colevt_&i=__col_&i;';
  put @1 '  %end;';
  put;  
  %if &nvarby=0 %then %do;
    put @1 "    if eof then do;";
    put @1 "    __ncol_0=__col_0;";
    put @1 "    __col_0='';";
    put @1 "    output;";
  %end;
  %else %do;
    put @1 "      if last.&&vby&nvarby then do;";
    put @1 "    __ncol_0=__col_0;";
    put @1 "    __col_0='';";
    put @1 "    output;";
  %end;
  put @1 "     __col_0 = __ncol_0;";
  put @1 "     __rowid+1;";
  put @1 '    %do i=1 %to &maxtrt;  ';
  put @1 '      __col_&i= "Number of Subjects";';
  put @1 '      __colevt_&i = "Number of Events";';
  put @1 '    %end;';
  put @1 "        output;";
  put @1 "  end;";
  put @1 "  else output;";
  put @1 "  run;";

  put @1 "  data __head (drop=__align rename=(__nalign=__align ";
  put @1 '      %do i=1 %to %eval(2*&maxtrt); __ncol_&i=__col_&i %end;));';
  put @1 "  set __head (rename=(";
  put @1 '  %do i=1 %to &maxtrt;';
  put @1 '  __col_&i = __ncol_%eval(2*&i-1)';
  put @1 '  __colevt_&i =__ncol_%eval(2*&i)';
  put @1 '  %end;';
  put @1 "  )) end=eof ;";
  put @1 "  length __nalign $ 2000;";
  put @1 "    __nalign = scan(__align,1,' ');";
  put @1 '  do __i=1 to &maxtrt;';
  put @1 "        __nalign = left(trim(__nalign))||' C C';";
  put @1 '  end;';
  put @1 "  run;";
  put @1 '  %let maxtrt = %eval(2*&maxtrt);';
%end;


%if %upcase(&aetable)=EVENTSES %then %do;

  data _null_;
  file "&rrgpgmpath./&rrguri..sas" mod;
  put;
  put @1 "*--------------------------------------------------------------------;";  
  put @1 "* CREATE EVENT COUNT HEADINGS ;";
  put @1 "*--------------------------------------------------------------------;";
  put;
  %if &nvarby>0 %then %do;
      put @1 "proc sort data=__head;";
      put @1 "by &varby;";
      put @1 "run;";
      put;
  %end;

  put @1 "  data __head ;";
  put @1 "  set __head end=eof ;";
  %if &nvarby>0 %then %do;
    put @1 "by &varby;";
  %end;
  put @1 '  length __ncol_0 %do i=1 %to &maxtrt;  __colevt_&i %end; $ 2000;';
  put @1 "  retain __ncol_0;";
  put @1 '    %do i=1 %to &maxtrt;  ';
  put @1 '    __colevt_&i=__col_&i;';
  put @1 '  %end;';
  put;  
  %if &nvarby=0 %then %do;
    put @1 "    if eof then do;";
    put @1 "    __ncol_0=__col_0;";
    put @1 "    __col_0='';";
    put @1 "    output;";
  %end;
  %else %do;
    put @1 "      if last.&&vby&nvarby then do;";
    put @1 "    __ncol_0=__col_0;";
    put @1 "    __col_0='';";
    put @1 "    output;";
  %end;
  put @1 "     __col_0 = __ncol_0;";
  put @1 "     __rowid+1;";
  put @1 '    %do i=1 %to &maxtrt;  ';
  put @1 '      __col_&i= "Number of  Subjects";';
  put @1 '      __colevt_&i = "Number of Events";';
  put @1 '    %end;';
  put @1 "        output;";
  put @1 "  end;";
  put @1 "  else output;";
  put @1 "  run;";

  put @1 "  data __head (drop=__align rename=(__nalign=__align ";
  put @1 '      %do i=1 %to %eval(2*&maxtrt); __ncol_&i=__col_&i %end;));';
  put @1 "  set __head (rename=(";
  put @1 '  %do i=1 %to &maxtrt;';
  put @1 '  __colevt_&i = __ncol_%eval(2*&i-1)';
  put @1 '  __col_&i =__ncol_%eval(2*&i)';
  put @1 '  %end;';
  put @1 "  )) end=eof ;";
  put @1 "  length __nalign $ 2000;";
  put @1 "    __nalign = scan(__align,1,' ');";
  put @1 '  do __i=1 to &maxtrt;';
  put @1 "        __nalign = left(trim(__nalign))||' C C';";
  put @1 '  end;';
  put @1 "  run;";
  put @1 '  %let maxtrt = %eval(2*&maxtrt);';
%end;

%* errant above?;
run;

%local splitrow;
proc sql noprint;
  select splitrow into:splitrow separated by ' '
    from __varinfo(where=(type='TRT'));
quit;    

%if %length(&splitrow) %then %do;

    data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    put @1 "  data __head(drop=__rowid __i __ncol: __split __issplit: ";
    put @1 "             rename=(__newrowid=__rowid));";
    put @1 '    length __split $ 1 __ncol_0 - __ncol_&maxtrt $ 200;';
    put @1 "    set __head;";
    put @1 "    retain __newrowid;";
    put @1 "    if _n_=0 then __newrowid=0;";
    put;    
    put @1 '    array cols{*} __col_1-__col_&maxtrt;';
    put @1 '    array ncols{*} __ncol_1-__ncol_&maxtrt;';
    put @1 '    __split =cats("' "&splitrow" ' ");';
    put @1 "    __issplit=0;";
    put @1 "    __ncol_0=__col_0;";
    put;
    put @1 "    if __trtvar ne 1 then do;";
    put @1 "      __newrowid+1;";
    put @1 "      output;";
    put @1 "    end;";
    put @1 "    else do;";
    put @1 "    do __i=1 to dim(cols);";
    put @1 "      ncols[__i]=cols[__i]; ";
    put @1 "        if index(ncols[__i],__split)>0 then __issplit=1; ";
    put @1 "    end;    ";
    put @1 "    do while (__issplit=1);";
    put @1 "      __issplit=0;";
    put @1 "      do __i=1 to dim(cols);";
    put;        
    put @1 "        __ind = index(ncols[__i],__split);";
    put @1 "        if __ind=1 then do;";
    put @1 "          cols[__i]='';";
    put @1 "          ncols[__i]=substr(ncols[__i],__ind+1);";
    put @1 "        end;";
    put @1 "        else if __ind>0 and __ind<length(ncols[__i]) then do;";
    put @1 "          cols[__i]=substr(ncols[__i],1,__ind-1);";
    put @1 "          ncols[__i]=substr(ncols[__i],__ind+1);";
    put @1 "        end;";
    put;        
    put @1 "        else if __ind=length(ncols[__i]) then do;";
    put @1 "          cols[__i]=substr(ncols[__i],1,__ind-1);";
    put @1 "          ncols[__i]='';";
    put @1 "        end;";
    put @1 "      else do;";
    put @1 "           cols[__i]=ncols[__i];";
    put @1 "         ncols[__i]='';";
    put @1 "      end;";
    put @1 "      __issplit2 = index(ncols[__i],__split);";
    put @1 "        if __issplit2>0 then __issplit=1;";
    put @1 "      put cols[__i]= ncols[__i]=;";
    put @1 "      end;  ";
    put @1 "      __newrowid+1;";
    put @1 "      __col_0='';";
    put @1 "      output;  ";
    put @1 "      put __issplit=;";
    put @1 "    end;";
    put @1 "    __newrowid+1;";
    put @1 "    do __i=1 to dim(cols);";
    put @1 "      cols[__i]=ncols[__i];";
    put @1 "      __col_0=__ncol_0;";
    put @1 "    end;";
    put;
    put @1 "    output;";
    put @1 "  end;";
    put @1 "  run;";
    put;
    run;

%end;

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put @1 "proc sort data=__head;";
put @1 "  by &varby __rowid;";
put @1 "run;";
put;
put @1 "data __head (drop = __rowid rename=(__nrowid=__rowid));";
put @1 "  set __head end=eof;  ";
put @1 "  by &varby __rowid;";
put @1 "  retain __nrowid;";
%if %length(&varby) %then %do;
  put @1 "if first.&&vby&nvarby then __nrowid=0;";
  put @1 "  if not last.&&vby&nvarby then do;";
  put @1 "    __align = tranwrd(__align, 'R', 'C');";
  put @1 "    __align = tranwrd(__align, 'D', 'C');";
  put @1 "  end;";
%end;
%else %do;
  put @1 "if _n_=1 then __nrowid=0;";  
  put @1 "  if not eof then do;";
  put @1 "    __align = tranwrd(__align, 'R', 'C');";
  put @1 "    __align = tranwrd(__align, 'D', 'C');";
  put @1 "  end;";
%end;
put @1 "  __nrowid+1;";
put @1 "run;";
put;
run;



%local rrgoutpathlazy;
%let rrgoutpathlazy=&rrgoutpath;




data _null_;
file "&rrgpgmpath./&rrguri..sas" mod ;
set __repinfo;

%if &nvarby>0 %then %do;
  %let varby=%sysfunc(compbl(&varby)); 
  
  %local tmp;
  %let tmp=%sysfunc(tranwrd(&varby,%str( ), %str(,)));
  put;
  put @1 "*--------------------------------------------------------;";
  put @1 "* ADD <PAGE BY> VARIABLE LABEL TO HEADER RECORDS;";
  put @1 "*--------------------------------------------------------;";
  put;
  put @1 "proc sql noprint;";
  put @1 "create table __varlab as select distinct ";
  put @1 "&tmp   ,";
  /*put @1 "   __varbylab from __fall where __varbylab ne '';";*/
  /* CODE CHANGE IP 21AUG2010 */
  put @1 "   __varbylab from __fall ;";
  put @1 " quit;";
  put;   
  put @1 "  proc sort data=__head;";
  put @1 "  by &varby;";
  put @1 "  run;";
  put;  
  put @1 "proc sort data=__varlab;";
  put @1 "  by &varby;";
  put @1 "  run;";
  put;
  put @1 "  data __head;";
  put @1 "  merge __head __varlab (in=__invb);";
  put @1 "  by &varby;";
  put @1 " if __invb;";
  put @1 "  run;";
%end;
put;
put;
put;

put;
put @1 "*------------------------------------------------------------------;";
put @1 "* JOIN TABLE BODY AND TABLE HEADER;";
put @1 "*------------------------------------------------------------------;";
put;

put @1 "data __fall;";
put @1 "  set __head __fall;";
put @1 '  format %do i=0 %to &maxtrt; __col_&i %end;;';
put @1 '  informat %do i=0 %to &maxtrt; __col_&i %end;;';
put @1 'run;';


%if &nvarby>0 %then %do;


  put;
  put @1 "*--------------------------------------------------------;";
  put @1 "* CREATE A SINGLE __VARBYGRP VARIABLE;";
  put @1 "*--------------------------------------------------------;";
  put;
  put @1 "  proc sort data=__fall;";
  put @1 "  by &varby;";
  put @1 "  run;";
  put;  
  put @1 "  data __fall;";
  put @1 "  set __fall;";
  put @1 "  by &varby;";
  put @1 "  retain __varbygrp ;";
  put @1 "  if _n_=1 then __varbygrp=0;";
  put @1 "  if first.&&vby&nvarby then do;";
  put @1 "        __varbygrp+1;";
  put @1 "  end;";
  put @1 "  run;";
  put;
  put @1 "   proc sql noprint;";
  put @1 "    create table __falltmp as select * from __fall where";
  put @1 "      __varbygrp in (select distinct __varbygrp from __fall (where=(__datatype='TBODY')));";
  put @1 "    create table __fall as select * from __falltmp;  ";
  put @1 "    quit;";
  put;
  put;
%end;
put;
put '*--------------------------------------------------------------;';
put '* if RCD has only __vtype=LABEL, generate "no data" report;';
put '*--------------------------------------------------------------;';
put;
put @1 '%local vtypes;';
put @1 'proc sql noprint;';
put @1 "  select distinct __vtype into:vtypes separated by ' ' ";
put @1 "    from __fall (where=(__vtype not in ('VLABEL','LABEL')));";
put @1 ' quit; ';
put;
put @1 '%if %length(&vtypes)=0 %then %do;';
put @1 "  data __fall;";
put @1 "    if 0;";
put @1 "  __col_0='';";
put @1 "  __indentlev = 0;";
put @1 "  run;  ";
put @1 '  %let maxtrt=1;';
put @1 '%end;';
put;

put;
put;
put '%dotab:';
put;
run;

data __repinfo;
  set __repinfo;
  rtype='';
  dist2next='';
  lastcheadid='0';
  gcols='';
run;  


%__makerepinfo(outds=&rrguri..sas);


data _null_;
file "&rrgpgmpath./&rrguri..sas" mod ;
put;
put @1 "data &rrguri;";
put @1 "  set __report __fall ;";
put @1 "run;";


put;
/*
%if &append=N and &appendable=Y %then %do;
put;
put @1 "data &rrguri._final;";
put @1 "set  &rrguri;";
put @1 "run;";
%end;
%if &append=Y %then %do;
put;
put @1 "data &rrguri._final;";
put @1 "set &rrguri._final &rrguri;";
put @1 "run;";
%end;
%if &append=N %then %do;
put;
put @1 "data &rrguri._final;";
put @1 "set &rrguri;";
put @1 "run;";
%end;
*/
put;
run;

**** PUT REQUESTED GROUPING VARIABLES IN COLUMNS;

%local isincol;

proc sql noprint;
  select count(*) into: isincol separated by ' '
  from __varinfo (where=(type='GROUP' and upcase(incolumn)='Y'));
  quit;
  

%if &isincol>0 %then %do;

  %__rrg_unindent(indentlev=%eval(&isincol-1));
%end;


**** PUT REQUESTED STATISTICS IN SEPARATE COLUMN;

%local isincolv;

proc sql noprint;
  select upcase(statsincolumn) into: isincolv separated by ' '
  from __repinfo;
  quit;
  

%if &isincolv=Y %then %do;
 
  %__rrg_unindentv;
%end;


**** start modification 30Oct2015 - to create variable to indicate next indent level (__next_indentlev);


data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put;

put @1 "* -----------------------------------------------------------------------;";
put @1 "* CREATE VARIABLE __NEXT_INDENTLEV TO INDICATE NEXT INDENT LEVEL;";
put @1 "* -----------------------------------------------------------------------;";
put;



put @1 "proc sort data=&rrguri;";
put @1 "  by  __datatype __varbygrp descending __rowid;";
put @1 "run;";
put;


put @1 "data &rrguri;";
put @1 "  set &rrguri;";
put @1 "  by  __datatype __varbygrp descending __rowid;";
put @1 "  length __cellfonts __cellborders  __title1_cont __label_cont $ 500 __topborderstyle __bottomborderstyle $ 2;";
put @1 "  __cellfonts = '';";
put @1 "  __cellborders = '';";
put @1 "  __topborderstyle='';";
put @1 "  __bottomborderstyle='';";
put @1 "  __label_cont='';";
put @1 "  __title1_cont='';";


put @1 "  __next_indentlev=lag(__indentlev);";
put @1 "  if first.__datatype then __next_indentlev=.;";
put @1 "run;";
put;  
/*
put @1 'proc sort data=&rrguri;';
put @1 "  by  __datatype __varbygrp __rowid;";
put @1 "run;";
put;
*/
put;
run;

**** end of modification om 30Oct2015;


data _null_;
file "&rrgpgmpath./&rrguri..sas " mod ;   
put;

put @1 '%mend;';
put;
put;
put @1 '%rrg;';
/*
%if &append=Y and &appendable=N %then %do;
put;
put @1 "data &rrguri._tmp;";
put @1 "set &rrguri._final;";
put @1 "run;";
put;
%end;
%else %do;
put;
put @1 "data &rrguri._tmp;";
put @1 "set &rrguri;";
put @1 "run;";
put;
%end;
*/




run;


%exit:




%put;
%put;
%put ------------------------------------------------------------------------;;
%put  FINISHED PROGRAM GENERATING STEP;;
%put ------------------------------------------------------------------------;;
%put;
%put;

proc optload 
   data=__sasoptions(where=(
    lowcase(optname) in 
    ( 'mprint',
      'notes',
      'mlogic', 
      'symbolgen', 
      'macrogen', 
      'mfile', 
      'source', 
      'source2', 
      'byline',
      'orientation',
      'date', 
      'number', 
      'center', 
      'byline',
      'missing')));
run;


/*
data __RRG_timer;
	set __timer;
run;
*/



%mend;