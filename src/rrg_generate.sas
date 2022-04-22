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
  footnot1=,...,  Footnot14: footnotes
    uri:        unique table identifier, also table name

*/


%put;
%put;
%put ------------------------------------------------------------------------;;
%put  STARTING PROGRAM GENERATING STEP;;
%put ------------------------------------------------------------------------;;
%put;
%put;

%* PRINT GENERATED PROGRAM HEADER AND FORMATS;


%local  datasetRRG   tablabel
       Title1 title2 title3 title4 title5 title6
       Footnot1 Footnot2 Footnot3 Footnot4 Footnot5 Footnot6
       Footnot7 footnot8 footnot9 footnot10
       footnot11 footnot12 footnot13 footnot14 shead_l shead_r shead_m
       sfoot_l sfoot_r sfoot_m systitle
       By    dest  fontsize nodatamsg
       orient colwidths   extralines
       libsearch  varby4pop varbyn4pop groupby4pop groupbyn4pop;
%local i j k breakokat;
%local indata inmacros  trtcnt ;


proc sql noprint;
  select name into: inmacros separated by ' ' from __varinfo (where=(type='MODEL'));
  select count(*) into:trtcnt separated by ' ' from __varinfo(where=(type='TRT'));
        
quit;



%LOCAL war ning;
%let war=WAR;
%let ning=NING;



%local  pooledstr;


%if  &defreport_pooled4stats=N %then     %let pooledstr = and __grouped ne 1;

%if &trtcnt>1 %then %do;
    %put &WAR.&NING.: more than one treatment variable was specified. Program aborted.;
    %goto exit;
%end;


%let datasetrrg=&defreport_dataset;


proc sort data=__varinfo;
  by varid;
run;



%local i j grpinc trtacross;
%let trtacross=Y;

proc sql noprint;
  select across into:grpinc separated by ' ' from
   __varinfo(where=(type='GROUP' and across='Y'));
  select upcase(across), name into :trtacross, :trtvar separated by ' ' from
   __varinfo(where=(type='TRT'));
quit;

%let trtvar=%scan(&trtvar,1,%str( ));

%if %upcase(&trtacross)=N %then %do;
    data __varinfo;
      set __varinfo;
      if type='GROUP' then nline='N';
    run;
%end;

*----------------------------------------------------------------;
%* CREATE DUMMY WHERE CONDITIONS;
*----------------------------------------------------------------;

%if %length(&defreport_popwhere)=0  %then  %let defreport_popwhere=%str(1=1);
%if %length(&defreport_tabwhere)=0  %then   %let defreport_tabwhere=%str(1=1);


*----------------------------------------------------------------;
* DETERMINE TREATMENT VARIABLES ;
*----------------------------------------------------------------;


%local numtrt trtvar;
%let numtrt=0;



%* ensures only one trt variable;

/*  */
/* %if &rrgsasfopen=0 %then %do; */
/* 	sasfile work.rrgpgm.data open; */
/* 	%let rrgsasfopen =1; */
/* %end; */
/* run; */
/*  */
/* %let rrgsasfopen=1; */

%if %length(&trtvar)>0 %then %let numtrt = 1;

data rrgpgmtmp;
length record $ 2000;
keep record;
record=  " "; output;
record='%macro rrg;';output;
record=" "  ;output;

record=  "*----------------------------------------------------------------;";output;
record=  "* RRG Version %__version;";output;
record=  "*----------------------------------------------------------------;";output;
record=  " ";output;
record=  '%local maxtrt breakokat ;';output;
record=  " ";output;
record=  "*----------------------------------------------------------------;";output;
record=  "* APPLY POPWHERE CLAUSE TO DATASET;";output;
record=  "* IF NECESSARY, CREATE COMBINED TREATMENTS;";output;
record=  "*----------------------------------------------------------------;";output;
record=  " ";output;
run;

proc append base=rrgpgm data=rrgpgmtmp;
run;


%__makenewtrt(
      dsin=&datasetrrg,
      wherein = %nrbquote(&defreport_popwhere),
     dsout=__dataset);



data rrgpgmtmp;
length record $ 2000;
keep record;
record=  " ";   output;
record=  "*-------------------------------------------------------------------;";output;
record=  "* CHECK IF RESULTANT DATASET FROM PREVIOUS STEP HAS ANY OBSERVATIONS;";output;
record=  "* IF NOT THEN SKIP TO MACRO GENERATING TABLE;";output;
record=  "*-------------------------------------------------------------------;";output;
record=  " ";     output;
record=  '%local dsid rc numobs;';output;
record=  '%let dsid = %sysfunc(open(__dataset));';output;
record=  '%let numobs = %sysfunc(attrn(&dsid, NOBS));';output;
record=  '%let rc = %sysfunc(close(&dsid));';output;
record=  " ";output;
record=  '%if &numobs=0 %then %do;';output;
record=  '  %put  PASSED DATASET IS EMPTY;'; output;
record=  "  data __fall;";output;
record=  '  if 0;';output;
record=  "  __col_0 = '';";output;
record=  "  __indentlev = 0;";output;
record=  "  __ROWID = 0;";output;
record=  '  run;';output;
record=  " ";output;
record=  '  %let maxtrt=1;';output;
record=  " ";output;

record=  '  %goto dotab;';output;
record=  '%end;';output;
record=  " ";output;
run;

proc append base=rrgpgm data=rrgpgmtmp;
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


    select count(*) , name    into :ngrpv , :groupby separated by ' '
    from __varinfo(where=(upcase(type)='GROUP' and upcase(page) ne 'Y' ));

    select count(*), name into:nvarby,:varby  separated by ' '
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


data rrgpgmtmp;
length record $ 2000;
keep record;
record=  " "; output;
record=  "*------------------------------------------------------------------;";output;
record=  "* GET POPULATION COUNT;";output;
record=  "*------------------------------------------------------------------;";output;
%local i j ;
%do i=1 %to &numtrt;
    %local trt&i;
    %let trt&i = %scan(&trtvar,&i, %str( ));
%end;
record=  " ";output;
run;


proc append base=rrgpgm data=rrgpgmtmp;
run;

data rrgpgmtmp;
length record $ 2000;
keep record;

%__getcntg(datain=__dataset,
        unit=&defreport_subjid,
        group=&varby4pop __grouped &trt1 __dec_&trt1 __suff_&trt1 __prefix_&trt1
                  __nline_&trt1 __autospan,
        cnt=__pop_1,
        dataout=__pop);

proc append base=rrgpgm data=rrgpgmtmp;
run;


%local tmptrt;
%let tmptrt=__grouped &trt1 __dec_&trt1 __suff_&trt1 __prefix_&trt1 __nline_&trt1 __autospan;

%* MAKE SURE THAT EACH DISTINCT VARBY HAS ALL TREATMENTS;

%if %length(&varby)  %then %do;
    %if  %length(&varbyn4pop)>0 %then %do;
        %local tmp1 tmp2;
        %let tmp1=%sysfunc(tranwrd(&varbyn4pop , %str( ), %str(,)));
        %let tmp2=%sysfunc(tranwrd(&varby4pop  &tmptrt, %str( ), %str(,)));

        data rrgpgmtmp;
        length record $ 2000;
        keep record;
        record=  " "; output;
        record=  "   proc sql noprint;";output;
        record=  "   create table __poptmp as  select * from ";output;
        record=  "    (select distinct &tmp1";output;
        record=  "      from __dataset)";output;
        record=  "      cross  join";output;
        record=  "    (select distinct &tmp2";output;
        record=  "      from __pop);";output;
        record=  "   quit;";output;
        record=  " ";  output;
        record=  "   proc sort data=__pop;";output;
        record=  "     by &varby4pop &groupby4pop &tmptrt;";output;
        record=  "   run;";output;
        record=  " ";output;
        record=  "   proc sort data=__poptmp;";output;
        record=  "     by &varby4pop  &tmptrt;";output;
        record=  "   run;";output;
        record=  " ";output;
        record=  "   data __pop;";output;
        record=  "     merge __pop __poptmp;";output;
        record=  "     by &varby4pop  &tmptrt;";output;
        record=  "     if __grpid=. then __grpid=999;";output;
        %do i=1 %to &numtrt ;
            record=  "       if __pop_&i=. then __pop_&i=0;";output;
        %end;
        record=  "   run;";output;

        run;

        proc append base=rrgpgm data=rrgpgmtmp;
        run;

    %end;
    %else %do;
        %local tmp1 tmp2;
        %let tmp1=%sysfunc(tranwrd(&varby,  %str( ), %str(,)));
        %let tmp2=%sysfunc(tranwrd(&tmptrt, %str( ), %str(,)));

        data rrgpgmtmp;
        length record $ 2000;
        keep record;
        record=  " ";output;
        record=  "   proc sql noprint nowarn;";output;
        record=  "   create table __poptmp as  select * from ";output;
        record=  "    (select distinct &tmp1";output;
        record=  "      from __dataset)";output;
        record=  "      cross join";output;
        record=  "    (select distinct &tmp2";output;
        record=  "      from __pop);";output;
        record=  "   quit;";output;
        record=  " ";  output;
        record=  "   proc sort data=__pop;";output;
        record=  "     by &varby &trtvar;";output;
        record=  "   run;";output;
        record=  " ";output;
        record=  "   proc sort data=__poptmp;";output;
        record=  "     by &varby &trtvar;";output;
        record=  "   run;";output;
        record=  " ";output;
        record=  "   data __pop;";output;
        record=  "     merge __pop __poptmp;";output;
        record=  "     by &varby &trtvar;";output;
        record=  "     if __grpid=. then __grpid=999;";output;
         %do i=1 %to &numtrt ;
              record=  "       if __pop_&i=. then __pop_&i=0;";output;
         %end;
        record=  "   run;";output;

        record=  " ";output;

        run;

        proc append base=rrgpgm data=rrgpgmtmp;
        run;

    %end;
%end;


%if &numtrt>1 %then %do;

    data rrgpgmtmp;
    length record $ 2000;
    keep record;
    record=  " "; output;
    record=  "proc sql noprint;"; output;
    record=  "drop table " %do i=2 %to &numtrt ; "__pop_&i " %end; ";" ;output;
    record=  "quit;";output;
    record=  " ";output;
    run;

    proc append base=rrgpgm data=rrgpgmtmp;
    run;

%end;

%__makecodeds_t (vinfods=__VARINFO, dsin=&datasetrrg);

%if %sysfunc(exist(__CODES4TRT_exec)) %then %do;

    %local varby4sql;
     proc sql noprint;
     select name into:varby4sql separated by ', '
     from __varinfo(where=(upcase(type)='GROUP' and upcase(page) = 'Y'));
     quit;


    data rrgpgmtmp;
    length record $ 2000;
    keep record;
    record=  " "; output;
    record=  " "; output;

    %if &nvarby>0 %then %do;
        record= "proc sql noprint;"; output;
        record="  create table varbytbl";  output;
        record="  as select distinct &varby4sql";  output;
        record="  from __dataset; "; output;
        record="  quit;"; output;
        record="proc sql nowarn noprint;"; output;
        record="  create table __CODES4TRT2 as"; output;
        record="  select * from varbytbl cross join __CODES4TRT;"; output;
        record="quit;"; output;
        record="data __CODES4TRT; "; output;
        record="set __CODES4TRT2;"; output;
        record="run;"; output;
    %end;


    record="data __pop;"; output;
    record="  set __pop;"; output;
    record="  drop __dec_&trtvar;"; output;
    record="run;"; output;
    record="proc sql noprint;"; output;
    record="  create table __popx as select * from __pop natural full outer join __CODES4TRT;"; output;
    record="quit;"; output;
    record='%local __mod_nline __mod_autospan __mod_suff __mod_prefix;'; output;
    record="proc sql noprint;"; output;
    record="  select distinct __nline_&trtvar into: __mod_nline"; output;
    record="  separated by ' ' from __popx (where=(not missing(__nline_&trtvar)));"; output;
    record="  select distinct __suff_&trtvar into: __mod_suff"; output;
    record="  separated by ' ' from __popx (where=(not missing(__suff_&trtvar)));"; output;
    record="  select distinct __prefix_&trtvar into: __mod_prefix"; output;
    record="  separated by ' ' from __popx (where=(not missing(__prefix_&trtvar)));"; output;
    record="  select distinct __autospan into: __mod_autospan"; output;
    record="  separated by ' ' from __popx (where=(not missing(__autospan)));"; output;
    record="quit;"; output;
    record=" " ; output;
    record=" " ; output;
    record="data __pop;"; output;
    record="  set __popx;"; output;
    record="  if missing(__grpid) then __grpid=999;"; output;
    record="  if missing(__pop_1)  then __pop_1=0;"; output;
    record="  if missing(__grouped)  then __grouped=0;"; output;
    record= '  if missing(__autospan)  then __autospan="'|| '&__mod_autospan'|| '";'; output;
    record="  if missing(__suff_&trtvar)  then __suff_&trtvar="|| '"'|| '&__mod_suff'|| '";'; output;
    record="  if missing(__nline_&trtvar)  then __nline_&trtvar="|| '"'|| '&__mod_nline'|| '";'; output;
    record="  if missing(__prefix_&trtvar)  then __prefix_&trtvar="|| '"' ||'&__mod_prefix'|| '";'; output;
    record="  run;"; output;
    run;

    proc append base=rrgpgm data=rrgpgmtmp;
    run;

%* end of "if %sysfunc(exist(__CODES4TRT_exec))";
%end;

data rrgpgmtmp;
length record $ 2000;
keep record;
record=  "*------------------------------------------------------------------;"; output;
record=  "* CREATE TREATMENT ID, ENUMERATING ALL TREATMENTS SEQUENTIALLY ;"; output;
record=  "*------------------------------------------------------------------;"; output;
record=  " "; output;

%local tmp tmp1;
%let tmp =%sysfunc(tranwrd(%sysfunc(compbl(
      __grouped &trtvar /*&trtdec*/)), %str( ), %str(,)));
%let tmp1 = %sysfunc(tranwrd(%sysfunc(compbl(&trtvar)), %str( ), %str(,)));

record=  "proc sql  noprint;"; output;
record=  "create table __trt as select distinct "; output;
record=  "&tmp"; output;
record=  "from __pop"; output;
record=  "order by &tmp1;"; output;
record=  "quit;"; output;
record=  " "; output;
record=  " "; output;
record=  "data __trt;"; output;
record=  "set __trt ;"; output;
record=  "by &trtvar;"; output;
record=  "retain __trtid;"; output;
record=  "if _n_=1 then __trtid=0;"; output;
record=  "if first.&trtvar then __trtid+1;"; output;
record=  "run;"; output;
record=  " "; output; output;
record=  "*------------------------------------------------------------------;"; output;
record=  "* MAXTRT IS THE NUMBER OF TREATMENT GROUPS;"; output;
record=  "*------------------------------------------------------------------;"; output;
record=  " "; output;
record=  " "; output;
record=  "proc sql noprint;"; output;
record=  "   select max(__trtid) into:maxtrt separated by ' ' from __trt;"; output;
record=  "quit;"; output;
record=  " "; output;
record=  " "; output;
record=  "*------------------------------------------------------------------;"; output;
record=  "%* ADD __TRTID VARIABLE TO DATASET WITH POPULATION COUNT;"; output;
record=  "*------------------------------------------------------------------;"; output;
record=  " "; output;



%__joinds(data1=__pop,
        data2=__trt,
          by = &trtvar,
      mergetype=INNER,
        dataout=__pop);




record=  "data __pop;";output;
record=  "set __pop;";output;
record=  "__pop = __pop_&numtrt;";output;
record=  "run;";output;
record=  " "; output;
record=  " "; output;
record=  "*-------------------------------------------------------------------;";output;
record=  "* GET HEADER ENTRIES FOR THE TABLE;";output;
record=  "*-------------------------------------------------------------------;";output;
record=  " "; output;
record=  "data __poph;"; output;
record=  "set __pop;"; output;
record=  "length __col __prefix $ 2000;"; output;
record=  "__overall=0;"; output;
record=  "__trtvar=1;"; output;

%do i=1 %to &numtrt;
    record=  "  __rowid=&i;"; output;
    record=  "  __col='';"; output;
    record=  "  __prefix=__prefix_&&trt&i;"; output;
    %if %length(&grpinc)=0 %then %do;
        record=  "  if __nline_&&trt&i='Y' then "; output;
        record=  "    __col = cats(__dec_&&trt&i, '//(N=',__pop_&i, ')', "; output;
        record=  "      __suff_&&trt&i);"; output;
        record=  "  else  __col = cats(__dec_&&trt&i,  __suff_&&trt&i);"; output;
    %end;
    %else %do;
        record=  "  __col = cats(__dec_&&trt&i,  __suff_&&trt&i);"; output;
    %end;
    record=  "  output;"; output;
%end;

record=  "run;"; output;
record=  " "; output;;
record=  "*-------------------------------------------------------------------;"; output;
record=  "* ADD __TRTID TO __DATASET;"; output;
record=  "*-------------------------------------------------------------------;"; output;
record=  " "; output;;


%__joinds(data1=__dataset,
        data2=__trt,
          by = &trtvar,
    mergetype=INNER,
      dataout=__dataset);


record = '%local __filesizebytes ;'; output;
record = 'data _null_; set sashelp.vtable;  '; output; 
record = "  WHERE LIBNAME = 'WORK'  AND MEMNAME = '__DATASET'  ;"; output;
record = "  call symput('__filesizebytes', put(FILESIZE, best.) );"; output;
record = 'run;'; output;
record = '%put RRG INFO: __dataset has &__filesizebytes bytes;'; output;
record = ' ';    output;
record=  "sasfile work.__dataset.data open; "; output;
record=  "run; "; output;

%if &numtrt>1 %then %do;
    %local nt;
    %let nt = %eval(&numtrt-1);



    record=  " "; output;
    record=  "*------------------------------------------------------------------;"; output;
    record=  "* DEFINE BREAKOKAT VARIABLE, WHICH HOLD COLUMN NUMBERS;"; output;
    record=  "* WHERE TABLE IS ALLOWED TO BREAK;"; output;
    record=  "* THIS HAS EFFECT ONLY IF THERE ARE MORE THAN 1 TREATMENT; "; output;
    record=  "*  VARIABLES, AND ALL VALUES OF LAST TREATMENT ARE TO BE KEPT; "; output;
    record=  "*  TOGETHER;"; output;
    record=  "*------------------------------------------------------------------;"; output;
    record=  " "; output;
    record=  " "; output;
    record=  "proc sort data=__pop;"; output;
    record=  "by &trtvar;"; output;
    record=  "run;"; output;
    record=  " "; output;
    record=  "data __pop;"; output;
    record=  "  set __pop;"; output;
    record=  "  by &trtvar;"; output;
    record=  "  if first.&&trt&nt then __cb=1;"; output;
    record=  "run;"; output;
    record=  " "; output;
    record=  "proc sort data=__pop;"; output;
    record=  "  by __trtid;"; output;
    record=  "run;"; output;
    record=  " "; output;
    record=  "proc sql noprint;"; output;
    record=  "  select __trtid into:breakokat separated by ' ' "; output;
    record=  "    from __pop(where=(__cb=1));"; output;
    record=  "quit;"; output;
    record=  " "; output;



%* end of "if numtrt>0";
%end;

run;

proc append base=rrgpgm data=rrgpgmtmp;
run;

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
        dsin = &defreport_dataset,
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
%if %length(&gdsset)>0 %then %let ngs=%sysfunc(countw(&gdsset, %str( )));

%* ngs is number of groupby variables for which codelist was given;


%if &ngs>0 %then %do;
    %local tmp;
    %let tmp = %scan(&gdsset,1,%str( ));

    data __grpcodes_exec;
      set &tmp._exec ;
    run;

    proc sql noprint nowarn;
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

    data rrgpgmtmp;
    length record $ 2000;
    keep record;
    record=  " "; output;
    record=  " "; output;
    record=  "data __grpcodes;";output;
    record=  "    set &tmp ;";output;
    record=  "  run;";output;
    record=  " ";  output;
    record=  "proc sql noprint nowarn;";output;

    %do i=2 %to &ngs;
        %local tmp;
        %let tmp = %scan(&gdsset,&i,%str( ));

          record=  "     create table __tmp as select * from __grpcodes";output;
          record=  "       cross join &tmp ;";output;
          record=  "     create table __grpcodes as select * from __tmp;";output;
    %end;

    record=  "  quit;";output;
    record=  " ";output;
    record=  "  data __grpcodes;";output;
    record=  "    set __grpcodes;";output;
    record=  "    if 0 then do;";output;

    %do i=1 %to &ngrpv;
        record=  "__order_%scan(&groupby,&i, %str( ))=.;";output;
    %end;

    record=  "    end;";output;
    record=  "  run;";output;
    record=  " ";output;
    %local tmp;
    %let tmp=;
    %do i=1 %to &ngrpv;
        %let tmp=&tmp __order_%scan(&groupby,&i, %str( ));
    %end;

    record=  "  proc sort data=__grpcodes;";output;
    record=  "by &tmp;";output;
    record=  "  run;";output;
    record=  " ";  output;
    record=  "  data __grpcodes __grptemplate;";output;
    record=  "    set __grpcodes;";output;
    record=  "    __orderg = _n_;";output;
    record=  "  run;  ";output;
    record=  " ";output;

    run;

    proc append base=rrgpgm data=rrgpgmtmp;
    run;

%* end of ngs>0;
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


data rrgpgmtmp;
length record $ 2000;
keep record;
record=  " "; output;
record=  "*------------------------------------------------------------------;"; output;
record=  "* INITIALIZE DATASET WITH TABLE CONTENT;"; output;
record=  "*------------------------------------------------------------------;"; output;
record=  " "; output;
record=  "data __all;"; output;
record=  "if 0;"; output;
record=  "run;"; output;
record=  " "; output;
record=  "data __overallstats;"; output;
record=  "if 0;"; output;
record=  "run;"; output;
record=  " "; output;
record=  "*------------------------------------------------------------------;"; output;
record=  "* CACLULATE REQUESTED STATISTICS;"; output;
record=  "*------------------------------------------------------------------;"; output;
record=  " "; output;
run;

proc append base=rrgpgm data=rrgpgmtmp;
run;


%do i=1 %to &numvar;

    %if &&type&i=CAT %then %do;

          %__cnts (
               dsin  = __dataset,
            dsinrrg  = &datasetrrg,
                unit = %nrbquote(&defreport_subjid),
               varid = &i,
       groupvars4pop = &groupby4pop,
      groupvarsn4pop = &groupbyn4pop,
             byn4pop = &varbyn4pop ,
              by4pop = &varby4pop ,
             trtvars = %cmpres(&trtvar),
          %if %upcase(&defreport_warnonnomatch) ne Y %then %do;
              warn_on_nomatch=0,
          %end;
             aetable = %upcase(&defreport_aetable),
               outds = __fcat&i);

       data rrgpgmtmp;
        length record $ 2000;
        keep record;
        record=  " "; output;
        record=  " "; output;
        record=  "data __all;"; output;
        record=  "set __all __fcat&i (in=__a);"; output;
        record=  "if __a then __grptype=1;"; output;
        record=  "run;"; output;
        record=  " "; output;

        run;

        proc append base=rrgpgm data=rrgpgmtmp;
        run;

        %* NOTE: __GRPTYPE IS USED TO CORRECTLY SORT RECORDS, SINCE ;
        %* FOR CONDITION LINES USER HAS A CHOICE OF WHETHER OR NOT
        %* APPLY GROUPING;

    %* end of type=CAT;
    %end;


    %if &&type&i=COND %then %do;

           %__cond(
               outds = __fcond&i,
               varid = &i,
                unit = &defreport_subjid,
       groupvars4pop = &groupby4pop,
      groupvarsn4pop = &groupbyn4pop,
             byn4pop = &varbyn4pop ,
              by4pop = &varby4pop ,
              events = %upcase(&defreport_aetable),
             trtvars = &trtvar);



         data rrgpgmtmp;
          length record $ 2000;
          keep record;
          record=  " "; output;
          record=  "data __all;"; output;
          record=  "set __all __fcond&i ;"; output;
          record=  "run;"; output;
          record=  " "; output;

          run;

          proc append base=rrgpgm data=rrgpgmtmp;
          run;

          %* NOTE: __GRPTYPE IS USED TO CORRECTLY SORT RECORDS, ;
          %* SINCE FOR CONDITION LINES;
          %* USER HAS A CHOICE OF WHETHER OR NOT APPLY GROUPING;
          %* MACRO __COND SETS __GRPTYPE TO 0 IF NO GROUPING IS TO BE APPLIED, ;
          %* AND TO 1 IF GROUPING IS TO BE APPLIED TO CONDITION LINE;


    %*end of type=cond;
    %end;


    %if &&type&i=LABEL %then %do;

          %__label(
             outds=__flab&i,
             varid=&i,
         groupvars=&groupby,
                by=&varby ,
        indentbase=&ngrpv,
              dsin=__dataset);



        data rrgpgmtmp;
        length record $ 2000;
        keep record;
        record=  " ";     output;
        record=  "data __all;"; output;
        record=  "set __all __flab&i (in=__a);"; output;
        record=  "if __a then __grptype=1;"; output;
        record=  "run;"; output;
        record=  " "; output;

        run;

        proc append base=rrgpgm data=rrgpgmtmp;
        run;

        %* NOTE: __GRPTYPE IS USED TO CORRECTLY SORT RECORDS, SINCE ;
        %* FOR CONDITION LINES USER HAS A CHOICE OF WHETHER OR NOT
        %* APPLY GROUPING;

    %* end of type=label;
    %end;


    %if &&type&i=CONT %then %do;
        %__cont (
             varid=&i,
              unit=&defreport_subjid,
     groupvars4pop=&groupby4pop,
    groupvarsn4pop=&groupbyn4pop,
           byn4pop=&varbyn4pop ,
            by4pop=&varby4pop ,
         trtvars=&trtvar,
           outds=__fcont&i);


        data rrgpgmtmp;
        length record $ 2000;
        keep record;
        record=  " "; output;
        record=  "data __all;"; output;
        record=  "set __all __fcont&i (in=__a);"; output;
        record=  "if __a then __grptype=1;"; output;
        record=  "run;"; output;
        record=  " "; output;

        run;

        proc append base=rrgpgm data=rrgpgmtmp;
        run;

  %* end of type=cont;
  %end;

%* end of i=1 to numvar;
%end;


data rrgpgmtmp;
length record $ 2000;
keep record;
record=  " "; output;
record=  "data __all;"; output;
record=  "set __all;"; output;
record=  "__sid=1;"; output;
record=  "run;"; output;
record=  " "; output;
record=  "*------------------------------------------------------------------;"; output;
record=  "* CHECK IF DATASET WITH CALCULATED STATISTICS HAS ANY RECORDS;"; output;
record=  "*------------------------------------------------------------------;"; output;
record=  " "; output;
record=  '%local dsid rc numobs;'; output;
record=  '%let dsid = %sysfunc(open(__all));'; output;
record=  '%let numobs = %sysfunc(attrn(&dsid, NOBS));'; output;
record=  '%let rc = %sysfunc(close(&dsid));'; output;
record=  " "; output;
record=  '%if &numobs=0 %then %do;'; output;
record=  '  %put  DATASET WITH STATISTICS HAS NO RECORDS, ;'; output;
record=  '  %put  SKIP TO MACRO GENERATING TABLE;'; output;

  %if &nvarby=0 and &trtacross=Y %then %do;  
  	  
  record=  "     data __fall;"; output;  
  record=  "  __col_0 = ' ';"; output;  
  record=  "  __indentlev = 0;"; output;  
  record=  "  __ROWID = 10;"; output;  
  record= "      __tcol='"||strip(symget("defreport_nodatamsg"))||"';";  output;  
    
    
  record=  "  __VTYPE = 'DUMMY';"; output;  
  record=  "__DATATYPE='TBODY';"; output;  
  record=  "__colwidths='NH NH';"; output;  
  record=  "__ALIGN='C';"; output;  
  record=  "     run;"; output;  
  record=  " "; output;  
  record=  '  %let maxtrt=10;'; output;  
  record=  " "; output;  
  record=  "proc sort data=__poph ;"; output;  
  record=  "by &varby __rowid __trtvar __autospan __prefix;"; output;  
  record=  "     run;"; output;  
  record=  " "; output;  
     
  record=  "proc transpose data=__poph out=__head prefix=__col_;"; output;  
  record=  "by &varby __rowid __trtvar __autospan __prefix;"; output;  
  record=  "id __trtid;"; output;  
  record=  "var __col;"; output;  
  record=  "run;"; output;  
  record=  " "; output;  
    
  record=  "data __fall;"; output;  
  record=  "  set __head (in=a) __fall;"; output;  
  record=  "  if a then do;"; output;  
  record=  "   __datatype='HEAD';"; output;  
  record=  "  end;;"; output;  
  record=  "run;  "; output;  
  record=  " "; output;  
  %end;  
    
  %else %do;  
record=  " data __fall;"; output;
record=  " if 0;"; output;
record=  " __indentlev=.;"; output;
record=  " run;"; output;
record=  " "; output;

  %end;  
    
record=  '     %goto dotab;'; output;
record=  '%end;'; output;
record=  " "; output;
run;

proc append base=rrgpgm data=rrgpgmtmp;
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

    data rrgpgmtmp;
    length record $ 2000;
    keep record;
    record=  " ";  output;
    record=  "*---------------------------------------------------------------;"; output;
    record=  "* ADD OVERALL STATISTICS TO DATASET __ALL;"; output;
    record=  "*---------------------------------------------------------------;"; output;
    record=  " "; output;

    %if %upcase(&defreport_aetable) = N %then %do;
        %do i=1 %to &ovorder;

            %* MERGE IN CONDITION BLOCKS WITHOUT GROUPING;
            record=  '%let k = %eval(&maxtrt'|| "+&i);"; output;

            %if %length(&condblocksng) %then %do;
                record=  "proc sort data=__overallstats "; output;
                record=  "  (where=(__order=&i and __blockid in (&condblocksng) ))";  output;
                record=  "  out = __os&i;"; output;
                record=  "  by &varby __blockid;"; output;
                record=  "run;"; output;
                record=  " "; output;
                record=  "proc sort data=__all;"; output;
                record=  "  by &varby __blockid;"; output;
                record=  "run;"; output;
                record=  " "; output;
                record=  "data __all;"; output;
                record=  "  merge __all (in=__a) "; output;
                record=  "       __os&i(keep = &varby  __blockid  __stat_value __stat_align);"; output;
                record=  "by &varby __blockid;"; output;
                record=  'length __col_&k $ 2000;'; output;
                record=  "if __a;"; output;
                record=  "__align = trim(left(__align))||' '||trim(left(__stat_align));"; output;
                record=  "if first.__blockid and __blockid in (&condblocksng) " 'then __col_&k=__stat_value;'; output;
                record=  'drop __stat_value;'; output;
                record=  "run;"; output;
                record=  " "; output;

            %*end of condblocksng;
            %end;

            %* MERGE IN ALL OTHER BLOCKS;
            %if %length(&condblocksg.&catblocks) %then %do;

                record=  "proc sort data=__overallstats"; output;
                record=  "  (where=(__order=&i and __blockid in (&condblocksg &catblocks) ))";       output;
                record=  "  out = __os&i;";output;
                record=  "  by &varby &groupby __blockid;";output;
                record=  "run;";output;
                record=  " ";output;
                record=  "proc sort data=__all;";output;
                record=  "  by &varby &groupby __blockid;";output;
                record=  "run;";output;
                record=  " ";output;
                record=  "data __all;";output;
                record=  "  merge __all (in=__a) ";output;
                record=  "       __os&i(keep = &varby &groupby __blockid  __stat_value __stat_align);";output;
                record=  "by &varby &groupby __blockid;";output;
                record=  'length __col_&k $ 2000;';output;
                record=  "if __a;";output;
                record=  "__align = trim(left(__align))||' '||trim(left(__stat_align));";output;
                record=  "if first.__blockid and __blockid in (&condblocksg &catblocks) "|| 'then __col_&k=__stat_value;';output;
                record=  'drop __stat_value;';output;
                record=  "run;";output;
                record=  " ";output;

            %*end of condblocksg.catblocks);
            %end;

        %* end of do i=1 to ovorder    ;
        %end;

    %* end of  aetable=N ;
    %end;

    %else %do;
        %do i=1 %to &ovorder;
            record=  '%let k = %eval(&maxtrt'|| "+&i);";
            %* MERGE IN CONDITION BLOCKS WITHOUT GROUPING;

            %if %length(&condblocksng) %then %do;
                record=  "proc sort data=__overallstats ";                                                                 output;
                record=  "  (where=(__order=&i and __blockid in (&condblocksng) ))";                                       output;
                record=  "  out = __osa&i;";                                                                               output;
                record=  "  by &varby __blockid;";                                                                         output;
                record=  "run;";                                                                                           output;
                record=  " ";                                                                                              output;
                record=  "proc sort data=__all;";                                                                          output;
                record=  "  by &varby __blockid;";                                                                         output;
                record=  "run;";                                                                                           output;
                record=  " ";                                                                                              output;
                record=  "data __all;";                                                                                    output;
                record=  "  merge __all (in=__a) ";                                                                        output;
                record=  "       __osa&i(keep = &varby  __blockid  __stat_value __stat_align);";                           output;
                record=  "by &varby __blockid;";                                                                           output;
                record=  'length __col_&k $ 2000;';                                                                        output;
                record=  "if __a;";                                                                                        output;
                record=  "__align = trim(left(__align))||' '||trim(left(__stat_align));";                                  output;
                record=  "if first.__blockid and __blockid in (&condblocksng) " 'then __col_&k=__stat_value;';             output;
                record=  'drop __stat_value;';                                                                             output;
                record=  "run;";                                                                                           output;
                record=  " ";                                                                                              output;

            %* end of condblocksng;
            %end;

            %if %length(&condblocksg) %then %do;
                %* MERGE IN CONT BLOCKS AND CONDITION BLOCKS WITH GROUPING;                                                 output;
                record=  "proc sort data=__overallstats ";                                                                  output;
                record=  "  (where=(__order=&i and __blockid in (&condblocksg) ))";                                         output;
                record=  "  out = __osa&i;";                                                                                output;
                record=  "  by &varby &groupby __blockid;";                                                                 output;
                record=  "run;";                                                                                            output;
                record=  " ";                                                                                               output;
                record=  "proc sort data=__all;";                                                                           output;
                record=  "  by &varby &groupby __blockid;";                                                                 output;
                record=  "run;";                                                                                            output;
                record=  " ";                                                                                               output;
                record=  "data __all;";                                                                                     output;
                record=  "  merge __all (in=__a) ";                                                                         output;
                record=  "       __osa&i(keep = &varby &groupby __blockid  __stat_value __stat_align);";                    output;
                record=  "by &varby &groupby __blockid;";                                                                   output;
                record=  'length __col_&k $ 2000;';                                                                         output;
                record=  "if __a;";                                                                                         output;
                record=  "__align = trim(left(__align))||' '||trim(left(__stat_align));";                                   output;
                record=  "if first.__blockid and __blockid in (&condblocksg) "|| 'then __col_&k=__stat_value;';               output;
                record=  'drop __stat_value;';                                                                              output;
                record=  "run;";                                                                                            output;
                record=  " ";                                                                                               output;

            %* end of condblocksg;
            %end;

            %* MERGE IN CATEGORICAL VARIABLES BLOCKS ;
            %do ii=1 %to &numcatblocks;
                  record=  '%local hasdata;';                                                                                         output;
                  record=  '%let hasdata=0;';                                                                                         output;
                  record=  " ";                                                                                                       output;
                  record=  "data __tmp;";                                                                                             output;
                  record=  "  set __overallstats";                                                                                    output;
                  record=  "  (where=(__order=&i and __blockid = &&cb&ii ));";                                                        output;
                  record=  "if _n_=1 then call symput('hasdata','1');";                                                               output;
                  record=  "run;";                                                                                                    output;
                  record=  " ";                                                                                                       output;
                  record=  '%if &hasdata=1  %then %do;';                                                                              output;
                  record=  " ";                                                                                                       output;
                  record=  "proc sort data=__all;";                                                                                   output;
                  record=  "  by &varby __grpid &groupby __blockid &&cbname&ii;";                                                     output;
                  record=  "run;";                                                                                                    output;
                  record=  " ";                                                                                                       output;
                  record=  "proc sort data=__overallstats ";                                                                          output;
                  record=  "  (where=(__order=&i and __blockid = &&cb&ii ))";                                                         output;
                  record=  "  out = __osb&i;";                                                                                        output;
                  record=  "  by &varby __grpid &groupby __blockid &&cbname&ii;";                                                     output;
                  record=  "run;";                                                                                                    output;
                  record=  " ";                                                                                                       output;
                  record=  "data __all;";                                                                                             output;
                  record=  "  merge __all (in=__a) ";                                                                                 output;
                  record=  "       __osb&i(keep = &&cbname&ii __grpid &varby &groupby __blockid ";                                    output;
                  record=  "       __stat_value __stat_align);";                                                                      output;
                  record=  "by &varby __grpid &groupby __blockid &&cbname&ii;";                                                       output;
                  record=  'length __col_&k $ 2000;';                                                                                 output;
                  record=  "if __a;";                                                                                                 output;
                  record=  "__align = trim(left(__align))||' '||trim(left(__stat_align));";                                           output;
                  record=  "if first.&&cbname&ii and __blockid = &&cb&ii " 'and __col_1 ne "" then __col_&k=__stat_value;';           output;
                  record=  'drop __stat_value;';                                                                                      output;
                  record=  "run;";                                                                                                    output;
                  record=  " ";                                                                                                       output;
                  record=  '%end;';                                                                                                   output;

            %*end of ii=1 to numcatblocks;
            %end;

        %* end of do i=1 %to &ovorder;
        %end;

    %* end of else (else to aetable = N ) ;
    %end;

    record=  " ";                                                                                                                     output;
    record=  "*---------------------------------------------------------------;";                                                     output;
    record=  "* ADD OVERALL STATISTICS HEADER TO __POPH DATASET;";                                                                    output;
    record=  "*---------------------------------------------------------------;";                                                     output;
    record=  " ";                                                                                                                     output;
    record=  "proc sort data=__overallstats nodupkey;";                                                                               output;
    record=  "  by __order  ;";                                                                                                       output;
    record=  "run;";                                                                                                                  output;
    record=  " ";                                                                                                                     output;

    %if %length(&varby) %then %do;
        %local tmp;
        %let tmp = %sysfunc(tranwrd(&varby, %str( ), %str(,))) ;

        record=  "proc sql noprint nowarn;";                                                                                          output;
        record=  "    create table __tmp as ";                                                                                        output;
        record=  "  select * from __overallstats (drop=&varby) cross join";                                                           output;
        record=  "  (select distinct &tmp from __poph);";                                                                             output;
        record=  "  create table __overallstats as select * from __tmp;";                                                             output;
        record=  "  quit;";                                                                                                           output;
        record=  " ";                                                                                                                 output;
        record=  "  proc sort data=__overallstats;";                                                                                  output;
        record=  "    by __order &varby;";                                                                                            output;
        record=  "  run;";                                                                                                            output;
    %end;

    record=  "data __poph0;";                                                                                                         output;
    record=  "set __poph;";                                                                                                           output;
    record=  "if _n_=1;";                                                                                                             output;
    record=  "keep __autospan;";                                                                                                      output;
    record=  "run;";                                                                                                                  output;
    record=  " ";                                                                                                                     output;
    record=  "data __overallstats;";                                                                                                  output;
    record=  "set __overallstats ;";                                                                                                  output;
    record=  "  by __order &varby;";                                                                                                  output;
    record=  '  retain __trtid &maxtrt;';                                                                                             output;
    record=  "if first.__order  then __trtid+1;";                                                                                     output;
    record=  "    __col = __stat_label;";                                                                                             output;
    record=  "    __align = 'C';";                                                                                                    output;
    record=  "    __rowid = 1;";                                                                                                      output;
    record=  "    __grpid = 999;";                                                                                                    output;
    record=  "    __overall = 1;";                                                                                                    output;
    record=  "run;";                                                                                                                  output;
    record=  " ";                                                                                                                     output;
    record=  "data __overallstats;";                                                                                                  output;
    record=  "  set __overallstats ;";                                                                                                output;
    record=  "  if _n_=1 then set __poph (drop=__trtid __col __overall);";                                                            output;
    record=  "  run;";                                                                                                                output;
    record=  " ";                                                                                                                     output;
    record=  "data __poph;";                                                                                                          output;
    record=  "  set __poph __overallstats;";                                                                                          output;
    record=  "run;";                                                                                                                  output;
    record=  " ";                                                                                                                     output;
    record=  '%let maxtrt=%eval(&maxtrt'|| "+&ovorder);";                                                                               output;
    run;

    proc append base=rrgpgm data=rrgpgmtmp;
    run;

%* end of ovorder>0;
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
         select distinct decode, label into :grpdec_&&grp&i separated by ' ',
         :grplab&i separated by ' '
          from __varinfo where upcase(name)=upcase("&&grp&i")
               and type='GROUP' and page ne 'Y';

         %let decodestr=&decodestr &&grpdec_&tmp;
    %end;

    %do i=1 %to &nvarby;
         %local vby&i  vblabel&i;
         %let vby&i = %scan(&varby, &i, %str( ));
         %let tmp = &&vby&i;
         %local vbdec_&&vby&i;
         select distinct decode, label  into:vbdec_&&vby&i separated by ' ',:vblabel&i  separated by ' '
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

         data rrgpgmtmp;
         length record $ 2000;
         keep record;
         record=  " ";                                                      output;
         record=  "data __grpcodes;";                                       output;
         record=  "  set __grpcodes;";                                      output;
         record=  "  if 0 then do;";                                        output;
         %do i=1 %to &ngrpv;
             record=  "    __order_&&grp&i=.;";                             output;
         %end;
         record=  "  end;";                                                 output;
         record=  "run;";                                                   output;
         record=  " ";                                                      output;
         run;

         proc append base=rrgpgm data=rrgpgmtmp;
         run;

         %local dsid rc varnum ;
         %let dsid = %sysfunc(open(__grpcodes_exec));
         %do i=1 %to &ngrpv;
             %let varnum = %sysfunc(varnum(&dsid, &&grp&i));
             %if &varnum>0 %then %let grps_w_cl=&grps_w_cl &&grp&i;
             %else %let grps_no_cl=&grps_no_cl &&grp&i;
         %end;
         %let rc = %sysfunc(close(&dsid));

     %* end of  exist(__grpcodes_exec);
     %end;

     %else %do;
           %let grps_no_cl=&groupby;
     %* end of else;
     %end;


     data rrgpgmtmp;
     length record $ 2000;
     keep record;
     record=  "*------------------------------------------------------------;";                            output;
     record=  "* GROUP VARIABLES  WITH CODELIST:&grps_w_cl ;";                                             output;
     record=  "* GROUP VARIABLES  WITH NO CODELIST:&grps_NO_cl &VARBY;";                                   output;
     record=  "*------------------------------------------------------------;";                            output;
     record=  " ";                                                                                         output;
     RUN;

     proc append base=rrgpgm data=rrgpgmtmp;
     run;

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

         data rrgpgmtmp;
         length record $ 2000;
         keep record;

         record=  "*------------------------------------------------------------;";                       output;
         record=  "* CASE: NO GROUPING VARIABLES - ONLY CREATE __VARBYLAB ;";                             output;
         record=  "*------------------------------------------------------------;";                       output;
         record=  " ";                                                                                    output;
         %if %length(&tmp1) %then %do; length &tmp1 $ 2000; %end;
         record=  " ";                                                                                    output;
         %do j=1 %to &nvarby;
             __vblabel&j = quote(trim(left(symget("vblabel&j"))));
         %end;

         %if %length(&decodestr)>0 %then %do;
                record=  "*---------------------------------------------------------;";                  output;
                record=  "* ADD DECODES FROM __DATASET TO __ALL;";                                       output;
                record=  "*---------------------------------------------------------;";                  output;
                record=  " ";                                                                            output;
                record=  "proc sql noprint;";                                                            output;
                record=  "  create table __tmpdec as select distinct &tmpdec";                           output;
                record=  "    from __dataset;";                                                          output;
                record=  "  create table __tmpdec2 as select * from";                                    output;
                record=  "    __tmpdec natural right join __all;";                                       output;
                record=  "  create table __all as select * from __tmpdec2;  ";                           output;
                record=  "quit;";                                                                        output;
                record=  " ";                                                                            output;
         %end;

         record=  " ";                                                                                   output;
         record=  "*---------------------------------------------------------;";                         output;
         record=  "* CREATE __VARBYLAB WITH DECRIPTION OF PAGE-BY VARIABLES  ;";                         output;
         record=  "*---------------------------------------------------------;";                         output;
         record=  " ";                                                                                   output;
         record=  "data __all;";                                                                         output;
         record=  "set __all;";                                                                          output;
         record=  "length __varbylab $ 2000;";                                                           output;
         record=  " ";                                                                                   output;
         record=  "   __varbylab='';";                                                                   output;

         %do j=1 %to &nvarby;
              %let tmp = &&vby&j;
              %if %length(&&vblabel&j) %then %do;
                   record=  " __varbylab =strip(__varbylab)||' '||" || strip(__vblabel&j) ||";";                     output;
              %end;
              %if %length(&&vbdec_&tmp) %then %do;
                   record=  "   __varbylab = trim(left(__varbylab))||' '||&&vbdec_&tmp;";                output;
              %end;
              %else %do;
                   record=  "   __varbylab=trim(left(__varbylab))||' '||&&vby&j;";                       output;
              %end;
         %end;
         record=  "run;";                                                                                output;
         record=  " ";                                                                                   output;
         run;

         proc append base=rrgpgm data=rrgpgmtmp;
         run;

      %* end of "if ngrpv=0";
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

        data rrgpgmtmp;
        length record $ 2000;
        keep record;
        record=  "*------------------------------------------------------------;";                             output;
        record=  "* CASE: NO GROUPING VARIABLES HAVE CODELIST;";                                               output;
        record=  "*------------------------------------------------------------;";                             output;
        record=  " ";                                                                                          output;

        %if %length(&tmp1) %then %do; length &tmp1 $ 2000; %end;
        %do i=1 %to &ngrpv;
            __grplab&i = quote(trim(left(symget("grplab&i"))));
        %end;
        %do j=1 %to &nvarby;
            __vblabel&j = quote(trim(left(symget("vblabel&j"))));
        %end;

        record=  " ";                                                                                          output;


        %do i=1 %to &ngrpv;
            %local ttt;
            %let ttt=&&grp&i;
            %if %length(&&grpdec_&ttt)>0 %then %do;
                %let tmpdec = %sysfunc(tranwrd(&&grp&i &&grpdec_&ttt, %str( ), %str(,)));

                 record=  " ";                                                                                                   output;
                 record=  "*-------------------------------------------------------------------------;";                         output;
                 record=  "* ADD DECODES FOR &&grp&i FROM __DATASET TO __ALL; ";                                                 output;
                 record=  "*-------------------------------------------------------------------------;";                         output;
                 record=  " ";                                                                                                   output;
                 record=  "proc sql noprint;";                                                                                   output;
                 record=  "create table __tmpdec as select distinct &tmpdec";                                                    output;
                 record=  " from __dataset;";                                                                                    output;
                 record=  "create table __tmpdec2 as select * from";                                                             output;
                 record=  " __tmpdec natural right join __all;";                                                                 output;
                 record=  "create table __all as select * from __tmpdec2;  ";                                                    output;
                 record=  "quit;";                                                                                               output;
                 record=  " ";                                                                                                   output;
            %end;
            record=  " ";                                                                                                        output;
        %* end of do i=1 to ngrpv;
        %end;

        record=  " ";                                                                                                            output;

        %if %length(&vbdecodestr) %then %do;
             record=  "*-------------------------------------------------------------------------;";                             output;
             record=  "* ADD DECODES FOR &varby FROM __DATASET TO __ALL; ";                                                      output;
             record=  "*-------------------------------------------------------------------------;";                             output;
             record=  " ";                                                                                                       output;
             %let tmpdec = %sysfunc(tranwrd(&varby &vbdecodestr, %str( ), %str(,)));                                             output;
             record=  "proc sql noprint;";                                                                                       output;
             record=  "   create table __tmpdec as select distinct &tmpdec";                                                     output;
             record=  "     from __dataset;";                                                                                    output;
             record=  "   create table __tmpdec2 as select * from";                                                              output;
             record=  "     __tmpdec natural right join __all;";                                                                 output;
             record=  "   create table __all as select * from __tmpdec2;  ";                                                     output;
             record=  " quit;     ";                                                                                             output;
             record=  " ";                                                                                                       output;
        %end;


        %if %length(&varby) %then %do;
            record=  "*---------------------------------------------------------;";                                              output;
            record=  "* CREATE __VARBYLAB WITH DECRIPTION OF PAGE-BY VARIABLES  ;";                                              output;
        %end;

        %if %length(&groupby) %then %do;
            record=  "*---------------------------------------------------------;";                                              output;
            record=  '* CREATE __grplabel_&grp1... __grplabel_&grpX;';                                                           output;
            record=  "* WITH DISPLAY VALUES OF GROUPING VARIABLES  ;";                                                           output;
        %end;

        record=  "*---------------------------------------------------------;";                                                  output;
        record=  " ";                                                                                                            output;
        record=  "data __all;";                                                                                                  output;
        record=  "length &tmp $ 2000;";                                                                                          output;
        record=  "set __all;";                                                                                                   output;
        record=  " ";                                                                                                            output;
        record=  "if 0 then do;";                                                                                                output;

        %do i=1 %to &ngrpv;
            record=  "   __grplabel_&&grp&i='';";                                                                                output;
            record=  "   __order_&&grp&i =.;";                                                                                   output;
            record=  "   call missing(&&grp&i);";                                                                                output;
        %end;

        record=  "end;";                                                                                                         output;
        record=  " ";                                                                                                            output;
        record=  "   __varbylab='';";                                                                                            output;

        %do i=1 %to &ngrpv;
             %let tmp = &&grp&i;
             record=  " __grplabel_&&grp&i =" ||strip(__grplab&i)|| ";";                                                                    output;
             %if %length(&&grpdec_&tmp) %then %do;
                record=  " __grplabel_&&grp&i = strip(__grplabel_&&grp&i)||' '||strip(&&grpdec_&tmp);";                          output;
             %end;
             %else %do;
                record=  " __grplabel_&&grp&i = strip(__grplabel_&&grp&i)||' '||strip(&&grp&i);";                                output;
             %end;
        %end;

        %if %length(&varby) %then %do;

            %do j=1 %to &nvarby;
                 %let tmp = &&vby&j;
                 %if %length(&&vblabel&j) %then %do;
                      record=  " __varbylab =strip(__varbylab)||' '||" ||strip(__vblabel&j)|| ";";                                          output;
                 %end;
                 %if %length(&&vbdec_&tmp) %then %do;
                      record=  "   __varbylab = trim(left(__varbylab))||' '||&&vbdec_&tmp;";                                     output;
                 %end;
                 %else %do;
                      record=  "   __varbylab=trim(left(__varbylab))||' '||&&vby&j;";                                            output;
                 %end;
            %end;
        %* end of varby;
        %end;

        record=  "run;";                                                                                                         output;
        record=  " ";                                                                                                            output;
        run;

        proc append base=rrgpgm data=rrgpgmtmp;
        run;

    %* end of "if ngrpv>0 and length(grps_w_cl)=0";
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

        %if %length(&vdecodestr)>0 %then    %let tmpdec = %sysfunc(tranwrd(&varby &vdecodestr, %str( ), %str(,)));


        data rrgpgmtmp;
        length record $ 2000;
        keep record;
        record=  "*------------------------------------------------------------;";                                        output;
        record=  "* CASE: ALL GROUPING VARIABLES HAVE CODELIST;";                                                         output;
        record=  "*------------------------------------------------------------;";                                        output;
        record=  " ";                                                                                                     output;

        %if %length(&tmp1) %then %do; length &tmp1 $ 2000; %end;
        %do i=1 %to &ngrpv;
            __grplab&i = quote(trim(left(symget("grplab&i"))));
        %end;
        %do j=1 %to &nvarby;
            __vblabel&j = quote(trim(left(symget("vblabel&j"))));
        %end;

        %if %length(&vdecodestr)>0 %then %do;
            record=  "*---------------------------------------------------------;";                                        output;
            record=  "* ADD DECODES FOR BY-PAGE VARIABLES FROM __DATASET TO __ALL;";                                       output;
            record=  "*---------------------------------------------------------;";                                        output;
            record=  " ";                                                                                                  output;
            record=  "proc sql noprint;";                                                                                  output;
            record=  "  create table __tmpdec as select distinct &tmpdec";                                                 output;
            record=  "    from __dataset;";                                                                                output;
            record=  "  create table __tmpdec2 as select * from";                                                          output;
            record=  "    __tmpdec natural right join __all;";                                                             output;
            record=  "  create table __all as select * from __tmpdec2;  ";                                                 output;
            record=  "quit;";                                                                                              output;
            record=  " ";                                                                                                  output;
        %end;

        record=  " ";                                                                                                      output;

        %do i=1 %to &ngrpv;
            record=  " ";                                                                                                  output;
            record=  "*---------------------------------------------------------------------;";                            output;
            record=  "* GET DECODES FOR &&GRP&I;";                                                                         output;
            record=  "*---------------------------------------------------------------------;";                            output;

            %local ttt;
            %let ttt=&&grp&i;

            record=  "    proc sort data=__all;";                                                                                       output;
            record=  "      by &&grp&i;";                                                                                               output;
            record=  "    run;";                                                                                                        output;
            record=  " ";                                                                                                               output;
            record=  " ";                                                                                                               output;
            record=  "    proc sort data=__grpcodes out=__tmpgrpcodes (keep=&&grp&i &&grpdec_&ttt __order_&&grp&i) nodupkey;";          output;
            record=  "      by &&grp&i;";                                                                                               output;
            record=  "    run;";                                                                                                        output;
            record=  " ";                                                                                                               output;
            record=  "    data __all;";                                                                                                 output;
            record=  "      merge __tmpgrpcodes __all (in=__a) ;";                                                                      output;
            record=  "      by &&grp&i;";                                                                                               output;
            record=  "      if __a;";                                                                                                   output;
            record=  "    run;    ";                                                                                                    output;
            record=  " ";                                                                                                               output;
        %* end of i=1 to ngrpv;
        %end;



        %if %length(&varby) %then %do;
            record=  "*---------------------------------------------------------;";                                                     output;
            record=  "* CREATE __VARBYLAB WITH DECRIPTION OF PAGE-BY VARIABLES  ;";                                                     output;
        %end;

        %if %length(&groupby) %then %do;
            record=  "*---------------------------------------------------------;";                                                      output;
            record=  '* CREATE __grplabel_&grp1... __grplabel_&grpX;';                                                                   output;
            record=  "* WITH DISPLAY VALUES OF GROUPING VARIABLES  ;";                                                                   output;
        %end;

        record=  "*---------------------------------------------------------;";                                                         output;
        record=  " ";                                                                                                                   output;
        record=  "data __all;";                                                                                                         output;
        record=  "length &tmp $ 2000;";                                                                                                 output;
        record=  "set __all;";                                                                                                          output;
        record=  " ";                                                                                                                   output;
        record=  "if 0 then do;";                                                                                                       output;

        %do i=1 %to &ngrpv;
            record=  "   __grplabel_&&grp&i='';";                                                                                       output;
            record=  "   __order_&&grp&i='';";                                                                                          output;
            record=  "   call missing(&&grp&i);";                                                                                       output;
        %end;

        record=  "end;";                                                                                                                output;
        record=  " ";                                                                                                                   output;
        record=  "   __varbylab='';";                                                                                                   output;

        %do i=1 %to &ngrpv;
            %let tmp = &&grp&i;
            record=  " __grplabel_&&grp&i =" ||strip(__grplab&i)|| ";";                                                                            output;
            %if %length(&&grpdec_&tmp) %then %do;
                record=  " __grplabel_&&grp&i = strip(__grplabel_&&grp&i)||' '||strip(&&grpdec_&tmp);";                                 output;
            %end;
            %else %do;
                record=  " __grplabel_&&grp&i = strip(__grplabel_&&grp&i)||' '||strip(&&grp&i);";                                       output;
            %end;
        %end;

        %if %length(&varby) %then %do;

            %do j=1 %to &nvarby;
               %let tmp = &&vby&j;
               %if %length(&&vblabel&j) %then %do;
                    record=  " __varbylab =strip(__varbylab)||' '||" ||strip(__vblabel&j) ||";";                                                    output;
               %end;
               %if %length(&&vbdec_&tmp) %then %do;
                    record=  "   __varbylab = trim(left(__varbylab))||' '||&&vbdec_&tmp;";                                               output;
               %end;
               %else %do;
                    record=  "   __varbylab=trim(left(__varbylab))||' '||&&vby&j;";                                                      output;
               %end;
            %end;

        %* end of length(varby);
        %end;


        record=  "run;";                                                                                                                 output;
        record=  " ";                                                                                                                    output;
        run;

        proc append base=rrgpgm data=rrgpgmtmp;
        run;


        %let groupby=;
        %do i=1 %to &ngrpv;
            %let groupby = &groupby __order_&&grp&i &&grp&i;
        %end;


        proc sql noprint;
          update __rrgpgminfo set value="&groupby" where key = "newgroupby";
        quit;

    %* end of if ngrpv>0 and length(grps_no_cl)=0;
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


        data rrgpgmtmp;
        length record $ 2000;
        keep record;
        record=  "*------------------------------------------------------------;";                                   output;
        record=  "* CASE: SOME GROUPING VARIABLES HAVE CODELIST, OTHERS DO NOT;";                                    output;
        record=  "*------------------------------------------------------------;";                                   output;
        record=  " ";                                                                                                output;

        %if %length(&tmp1) %then %do; length &tmp1 $ 2000; %end;
        %do i=1 %to &ngrpv;
            __grplab&i = quote(trim(left(symget("grplab&i"))));
        %end;
        %do j=1 %to &nvarby;
            __vblabel&j = quote(trim(left(symget("vblabel&j"))));
        %end;

        record=  " "; output;                                                                                        output;

        %if %length(&tmpdec)>0 %then %do;
            record=  " ";                                                                                            output;
            record=  "*-------------------------------------------------------------;";                              output;
            record=  "* CROSSJOIN __GRPCODES DATASET ;";                                                             output;
            record=  "* (CONTAINING ALL COMBOS OF GROUPING VARIABLES WITH CODELIST);";                               output;
            record=  "* WITH ALL COMBOS OF GROUPING VARIABLES WITHOUT CODELIST);";                                   output;
            record=  "*-------------------------------------------------------------;";                              output;
            record=  " ";                                                                                            output;
            record=  "proc sql noprint nowarn;";                                                                     output;
            record=  "  create table __tmp1g as select distinct &tmpdec from __dataset;";                            output;
            record=  "  create table __tmp2g as select * from";                                                      output;
            record=  "    __grpcodes cross join __tmp1g;";                                                           output;
            record=  "   create table __grpcodes as select * from __tmp2g;";                                         output;
            record=  "quit;";                                                                                        output;
            record=  " ";                                                                                            output;
        %end;

        %if %length(&vdecodestr) %then %do;
            record=  " ";                                                                                            output;
            record=  "*---------------------------------------------------------------------;";                      output;
            record=  "* GET DECODES FOR &varby;";                                                                    output;
            record=  "*---------------------------------------------------------------------;";                      output;
            record=  " ";                                                                                            output;
            record=  " proc sort data=__all;";                                                                       output;
            record=  "   by &varby;";                                                                                output;
            record=  " run;";                                                                                        output;
            record=  " ";                                                                                            output;
            record=  "    proc sort data=__tmp1g out=__tmp1g2 nodupkey;";                                            output;
            record=  "       by &varby;";                                                                            output;
            record=  "    run;";                                                                                     output;
            record=  " ";                                                                                            output;
            record=  "    data __all;";                                                                              output;
            record=  "      merge __tmp1g2 (keep = &varby &vdecodestr) __all (in=__a ) ;";                           output;
            record=  "      by &varby;";                                                                             output;
            record=  "      if __a;";                                                                                output;
            record=  "    run;    ";                                                                                 output;
            record=  " ";                                                                                            output;
        %end;

        %do i=1 %to &ngrpv;
            record=  " ";                                                                                            output;
            record=  "*---------------------------------------------------------------------;";                      output;
            record=  "* GET DECODES FOR &&GRP&I;";                                                                   output;
            record=  "*---------------------------------------------------------------------;";                      output;

              %local ttt;
              %let ttt=&&grp&i;

            record=  "    proc sort data=__all;";                                                                    output;
            record=  "      by &&grp&i;";                                                                            output;
            record=  "    run;";                                                                                     output;
            record=  " ";                                                                                            output;
            record=  "    proc sort data=__grpcodes nodupkey out=__tmpgrpcodes (keep=&&grp&i &&grpdec_&ttt __order_&&grp&i);";      output;
            record=  "      by &&grp&i;";                                                                            output;
            record=  "    run;";                                                                                     output;
            record=  " ";                                                                                            output;
            record=  "    data __all;";                                                                              output;
            record=  "      merge __tmpgrpcodes __all (in=__a) ;";                                                   output;
            record=  "      by &&grp&i;";                                                                            output;
            record=  "      if __a;";                                                                                output;
            record=  "    run;    ";                                                                                 output;
            record=  " ";                                                                                            output;

        %end;

        record=  " ";                                                                                                output;

        %if %length(&varby) %then %do;
            record=  "*---------------------------------------------------------;";                                  output;
            record=  "* CREATE __VARBYLAB WITH DECRIPTION OF PAGE-BY VARIABLES  ;";                                  output;
        %end;

        %if %length(&groupby) %then %do;
            record=  "*---------------------------------------------------------;";                                  output;
            record=  '* CREATE __grplabel_&grp1... __grplabel_&grpX;';                                               output;
            record=  "* WITH DISPLAY VALUES OF GROUPING VARIABLES  ;";                                               output;
        %end;

        record=  "*---------------------------------------------------------;";                                    output;
        record=  " ";                                                                                              output;
        record=  "data __all;";                                                                                    output;
        record=  "length &tmp $ 2000;";                                                                            output;
        record=  "set __all;";                                                                                     output;
        record=  " ";                                                                                              output;
        record=  "if 0 then do;";                                                                                  output;

        %do i=1 %to &ngrpv;
           record=  "   __grplabel_&&grp&i='';";                                                                   output;
           record=  "   __order_&&grp&i='';";                                                                      output;
           record=  "   call missing(&&grp&i);";                                                                   output;
        %end;

        record=  "end;";                                                                                           output;
        record=  " ";                                                                                              output;
        record=  "   __varbylab='';";                                                                              output;

        %do i=1 %to &ngrpv;
           %let tmp = &&grp&i;
           record=  " __grplabel_&&grp&i =" ||strip(__grplab&i) ||";";                                                        output;
           %if %length(&&grpdec_&tmp) %then %do;
              record=  " __grplabel_&&grp&i = strip(__grplabel_&&grp&i)||' '||strip(&&grpdec_&tmp);";              output;
           %end;
           %else %do;
              record=  " __grplabel_&&grp&i = strip(__grplabel_&&grp&i)||' '||strip(&&grp&i);";                    output;
           %end;
        %end;

        %if %length(&varby) %then %do;

            %do j=1 %to &nvarby;
                 %let tmp = &&vby&j;
                 %if %length(&&vblabel&j) %then %do;
                      record=  " __varbylab =strip(__varbylab)||' '||"||strip(__vblabel&j)|| ";";                   output;
                 %end;
                 %if %length(&&vbdec_&tmp) %then %do;
                      record=  "   __varbylab = trim(left(__varbylab))||' '||strip(&&vbdec_&tmp);";                 output;
                 %end;
                 %else %do;
                      record=  "   __varbylab=trim(left(__varbylab))||' '||strip(&&vby&j);";                        output;
                 %end;
            %end;

        %end;

        record=  "run;";                                                                                            output;
        record=  " ";                                                                                               output;
        run;

        proc append base=rrgpgm data=rrgpgmtmp;
        run;

    %* end of case4;
    %end;

    %let groupby=;
    %do i=1 %to &ngrpv;
        %let groupby = &groupby __order_&&grp&i &&grp&i;
    %end;


    proc sql noprint;
      update __rrgpgminfo set value="&groupby" where key = "newgroupby";
    quit;

%* end of ngrpv>0 or nvarby>0;
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
  sta=%upcase(&defreport_statsacross));

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




%if %upcase(&defreport_statsacross)=Y %then %do;


    %__transposes(
      dsin=__ALL,
      varby=&varby,
      groupby=&groupby,
      trtvar=&ntrtvar,
      overall=&ovorder);

%end;



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

data rrgpgmtmp;
length record $ 2000;
keep record;
record=  " ";                                                                                                 output;
record=  "*-----------------------------------------------------------------;";                               output;
record=  "* SORT TABLE AND ASSIGN ROW ID;";                                                                   output;
record=  "*-----------------------------------------------------------------;";                               output;
record=  " ";                                                                                                 output;
record=  "proc sort data=__all;";                                                                             output;
record=  "  by &varby __grptype __tby &groupby __grpid __blockid ";                                           output;
record=  "     __order __tmprowid;";                                                                          output;
record=  "run;";                                                                                              output;
record=  " ";                                                                                                 output;

%if %upcase(&defreport_aetable) ne N %then %do;
    record=  "* IF >1 CATVAR SPECIFIED FOR AE TABLE, ;";                                                      output;
    record=  "*   GROUPING VARIABLES ARE REP EATED.;";                                                        output;
    record=  "data __all;";                                                                                   output;
    record=  "  set __all;";                                                                                  output;
    record=  "  by &varby __grptype __tby &groupby __grpid __blockid ";                                       output;
    record=  "     __order __tmprowid;";                                                                      output;
    record=  "  if __grpid ne ceil(__grpid) and last.__grpid ";                                               output;
    record=  "       and not first.__grpid then delete;";                                                     output;
    record=  "run;  ";                                                                                        output;
    record=  " ";                                                                                             output;
    record=  "proc sort data=__all;";                                                                         output;
    record=  "  by &varby __grptype __tby &groupby __grpid __blockid ";                                       output;
    record=  "     __order __tmprowid;";                                                                      output;
    record=  "run;";                                                                                          output;
    record=  " ";                                                                                             output;
%end;


%local nn;
%let nn=&ngrpv;
%if %upcase(&defreport_statsacross)=Y %then %let nn=%eval(&ngrpv-1);


record=  "data __all ;";                                                                                      output;
record=  "length __suffix $ 2000;";                                                                           output;
record=  "  set __all;";                                                                                      output;
record=  " drop __i __nindentlev;";                                                                           output;
record=  "  if 0 then do; __varlabel=''; __grplabel_0=''; end;";                                              output;
record=  "  by &varby __grptype __tby &groupby __grpid __blockid ";                                           output;
record=  "     __order __tmprowid;";                                                                          output;
record=  "  array cols{*} __col_:;";                                                                          output;

%if &ngrpv>0 %then %do;
    record=  "  array grpl{*}" || %do i=1 %to &ngrpv; " __grplabel_&&grp&i"||  %end;";" ;                         output;
%end;
%else %do;
    record="   array grpl{*} __grplabel_0;";                                                                  output;
%end;

record=  "  do __i=1 to dim(cols);";                                                                          output;
record=  "    cols[__i]=trim(left(cols[__i]));";                                                              output;
record=  "    if compress(cols[__i],'().,:')='' then cols[__i]='';";                                          output;
record=  "  end;";                                                                                            output;
record=  " ";                                                                                                 output;
record=  "  __ntmprowid=_n_;";                                                                                output;
record=  "  __sid = 1;";                                                                                      output;
record=  " ";                                                                                                 output;
record=  "    __oldind=__indentlev;";                                                                         output;
record=  "  if __labelline ne 1 and dequote(__varlabel) ne '' ";                                              output;
record=  "    and __vtype ne 'COND' then ";                                                                   output;
record=  "    __indentlev=__indentlev+1;";                                                                    output;
record=  "    __nindentlev=__indentlev;";                                                                     output;

run;

proc append base=rrgpgm data=rrgpgmtmp;
run;



%if %upcase(&defreport_aetable) ne N %then %do;
    data rrgpgmtmp;
    length record $ 2000;
    keep record;
    record=  "    * ASSIGN CORRECT DISPLAY VALUES TO ROWS ";                                                  output;
    record=  "         REPRESENTING GROUPING VARIABLES;";                                                     output;
    record=  "    if __vtype not in ('COND','CONDS','CONDLAB') then do;";                                     output;
    record=  "      if __grpid ne ceil(__grpid)  then do;";                                                   output;
    record=  "           __ind = floor(__grpid);";                                                            output;
    record=  "           if __ind=998 then __ind = &ngrpv;";                                                  output;

    %if %upcase(&defreport_statsacross)=Y and &ngrpv>0 %then %do;
        record=  "           __indentlev = max(__ind-1,0);";                                                  output;
    %end;
    %else %do;
        record=  "           __indentlev = max(__ind-1+__oldind-&ngrpv,0);";                                  output;
    %end;

    record=  "           __sid = -&ngrpv+__ind-1;";                                                           output;
    record=  "           __vtype=cats('GLABEL', __ind);";                                                     output;
    record=  "           __suffix='';";                                                                       output;
    record=  "           __keepn=1;";                                                                         output;
    record=  "           if __ind>0 then __col_0=grpl[__ind];";                                               output;
    record=  "       end;";                                                                                   output;
    record=  "       else do;";                                                                               output;

    %do i=&ngrpv %to 1 %by -1;

        record=  "         if first.&&grp&i  then do;";                                                       output;

        %if %upcase(&defreport_statsacross)=Y and &ngrpv>0 %then %do;
           record=  "          if __grpid ne 999 then __nindentlev = __indentlev-&ngrpv+__grpid-1;";          output;
           record=  "          else __nindentlev = __indentlev;";                                             output;
        %end;
        %else %do;
            record=  "          __nindentlev = __grpid-2+__indentlev-&ngrpv;";                                output;
        %end;

        record=  "          __sid = -&ngrpv+&i-1;";                                                           output;
        record=  "          __vtype=CATS('GLABEL',&i);";                                                      output;
        record=  "          if not last.&&grp&i then do;";                                                    output;
        record=  "          __suffix='';";                                                                    output;
        record=  "          __keepn=1;";                                                                      output;
        record=  "          end;";                                                                            output;
        record=  "          __col_0=trim(left(__grplabel_&&grp&i));";                                         output;
        record=  "         end;";                                                                             output;
    %end;

    %if &ngrpv>0 %then %do;
        record=  "                 if __nindentlev ne . then __indentlev = max(0,__nindentlev);";             output;
    %end;

    record=  "       end;    ";                                                                               output;
    record=  "    end;";                                                                                      output;
    record=  "    else do;";                                                                                  output;
    record=  "         __indentlev=max(__oldind,0);";                                                         output;
    record=  "    end;";                                                                                      output;
    record=  " ";                                                                                             output;


    %if &ngrpv>0 %then %do;
        record=  "    if __col_0='' then __col_0 = 'Missing';";                                               output;
    %end;
    %else %do;
        record=  "    if __col_0='' and __vtype ne 'GLABEL0' then __col_0 = 'Missing';";                      output;
    %end;

    record=  "    if last.__blockid and __skipline='Y' then __suffix = '~-2n';";                              output;


    proc append base=rrgpgm data=rrgpgmtmp;
    run;

    %* end of AETABLE ne N;

%end;

%else %do;

    %if %upcase(&defreport_statsacross)=Y and &ngrpv>1 %then %do;
        data rrgpgmtmp;
        length record $ 2000;
        keep record;
        record=  "     __col_0 = trim(left(__grplabel_&&grp&ngrpv));";  output;
        run;
        proc append base=rrgpgm data=rrgpgmtmp;
        run;
    %end;


%end;

run;





data rrgpgmtmp;
length record $ 2000;
keep record;
record=  " ";                                                                                                output;
record=  "  output;";                                                                                        output;
record=  "  do __i=1 to dim(cols);";                                                                         output;
record=  "    cols[__i]='';";                                                                                output;
record=  "  end;";                                                                                           output;
record=  " ";                                                                                                output;

%if %upcase(&defreport_aetable)=N %then %do;


    record=  "    * CREATE ROWS FOR DISPLAY OF GROUPING VARIABLES;";                                         output;
    record=  "    * ASSIGN CORRECT DISPLAY VALUES TO THESE ROWS ;";                                          output;

    %do i=1 %to &nn;

        record=  "      if first.&&grp&i then do;";                                                          output;

        %if %upcase(&defreport_statsacross)=Y and &ngrpv>0 %then %do;
            record=  "     __indentlev=max(&i-1+__oldind-&nn,0);";                                           output;
         %end;
         %else %do;
            record=  "     __indentlev = max(&i-1+__oldind-&ngrpv,0);";                                      output;
        %end;

        record=  "        __sid = -&ngrpv+&i-1;";                                                            output;
        record=  "        __vtype=CATS('GLABEL',&i);";                                                       output;
        record=  "        __suffix='';";                                                                     output;
        record=  "        __keepn=1;";                                                                       output;
        record=  "        __col_0=trim(left(__grplabel_&&grp&i));";                                          output;
        record=  "        output;";                                                                          output;
        record=  "      end;";                                                                               output;

    %end;


%end;


record=  "  * CREATE ROWS WITH DESCRIPTION OF ANALYSIS VARIABLE;";                                           output;
record=  "  if first.__blockid then do;";                                                                    output;
record=  "     if __labelline ne 1 then do;";                                                                output;
record=  "        __sid=0;";                                                                                 output;
record=  "        __suffix='';";                                                                             output;

%if %upcase(&defreport_statsacross)=Y and &ngrpv>1 %then %do;
    record=  "        if last.%scan(&groupby,-2, %str( )) then do;";                                         output;
    record=  "          __suffix = '~-2n';";                                                                 output;
    record=  "          __keepn=0;";                                                                         output;
    record=  "        end;;";                                                                                output;
%end;
%else %do;
    record=  "        __keepn=1;";                                                                           output;
%end;

record=  "        __indentlev=max(__oldind,0);";                                                             output;
record=  "        __vtype='VLABEL';";                                                                        output;
record=  "        __col_0 =dequote(__varlabel);";                                                            output;
record=  "        __align = 'L '||repeat('L '," ||'&maxtrt);' ;                                                output;
record=  "        if __col_0 ne '' then output;";                                                            output;
record=  "     end;";                                                                                        output;
record=  "  end;";                                                                                           output;
record=  " ";                                                                                                output;
record=  "run;";                                                                                             output;
record=  " ";                                                                                                output;

%if &ngrpv=0 and %upcase(&defreport_aetable) ne N %then %do;
    record=  " ";                                                                                            output;
    record=  "data __all;";                                                                                  output;
    record=  "set __all;";                                                                                   output;
    record=  "if __vtype='GLABEL0' then delete;";                                                            output;
    record=  "run;;";                                                                                        output;
%end;

record=  "proc sort data=__all;";                                                                            output;
record=  "by __ntmprowid __sid;";                                                                            output;
record=  "run;";                                                                                             output;
record=  " ";                                                                                                output;
record=  " ";                                                                                                output;
record=  '%local numobsinall;';                                                                              output;
record=  " ";                                                                                                output;
record=  "data __all;";                                                                                      output;
record=  "set __all end=eof;";                                                                               output;
record=  "if eof then call symput ('numobsinall', cats(_n_));";                                              output;
record=  "__tmprowid=_n_;";                                                                                  output;

%if %upcase(&defreport_statsacross) ne Y /*or &ngrpv<=1*/ %then %do;
    record=  "if index(__vtype,'GLABEL')>0 then __suffix='';";                                               output;
%end;

record=  "drop __ntmprowid;";                                                                                output;
record=  "run;";                                                                                             output;
record=  " ";                                                                                                output;
record=  "data __fall;";                                                                                     output;
record=  "length __datatype $ 8;";                                                                           output;
record=  "set __all;";                                                                                       output;
record=  "__datatype='TBODY';";                                                                              output;
record=  "__rowid=_n_;";                                                                                     output;
record=  "array cols {*} __col_:;";                                                                          output;
record=  "  do __i=1 to dim(cols);";                                                                         output;
record=  "     cols[__i]=strip(cols[__i]);";                                                                 output;
record=  "  end;  ";                                                                                         output;
record=  "__dis=.; _n=.; __rowt=.; __ord=.; __old=.;";                                                       output;
record=  "drop __tmprowid  __tby __skipline __rowt: __ord: __label: __grp: ";                                output;
record=  '    __dis: _n: __varlabel __i __old:;';                                                            output;
record=  "run;";                                                                                             output;
record=  " ";                                                                                                output;
record=  " ";                                                                                                output;
record=  "*----------------------------------------------------------------;";                               output;
record=  "  * IF LABEL IS TO SPAN WHOLE TABLE, CREATE __TCOL VARIABLE;";                                     output;
record=  "*----------------------------------------------------------------;";                               output;
record=  " ";                                                                                                output;
record=  "data __fall;";                                                                                     output;
record=  "set __fall;";                                                                                      output;
record=  "length __tcol __tmptcol $ 2000;";                                                                  output;
record=  "retain __tcol;";                                                                                   output;
record=  "if 0 then do; __wholerow=''; __tcol=''; __tmptcol=''; end;";                                       output;
record=  "__oldwr = lag(__wholerow);";                                                                       output;
record=  "__tmptcol = lag(__col_0);";                                                                        output;
record=  "if upcase(__oldwr) = 'Y' then do;";                                                                        output;
record=  "  __tcol=strip(__tmptcol);";                                                                       output;
record=  "  __fospan=1;";                                                                                    output;
record=  "end;";                                                                                             output;
record=  "if __wholerow ne 'Y' then output;";                                                                output;
record=  "drop __oldwr __tmptcol;";                                                                          output;
record=  "run;";                                                                                             output;
record=  " ";                                                                                                output;
record=  " ";                                                                                                output;

run;

proc append base=rrgpgm data=rrgpgmtmp;
run;



%if %upcase(&defreport_aetable)=EVENTSE %then %do;

    data rrgpgmtmp;
    length record $ 2000;
    keep record;
    record=  "*----------------------------------------------------------------;";                           output;
    record=  "  * ADD EVENT COUNT TO TABLE;";                                                                output;
    record=  "*----------------------------------------------------------------;";                           output;
    record=  " ";                                                                                            output;
    record=  '  data __fall ;';                                                                              output;
    record=  "  set __fall;";                                                                                output;
    record=  " ";                                                                                            output;
    record=  '  %do i=1 %to &maxtrt;';                                                                       output;
    record=  '  __col_&i = __colevt_&i ;';                                                                   output;
    record=  '  %end;';                                                                                      output;
    record=  " ";                                                                                            output;
    record=  "  length __nalign $ 2000;";                                                                    output;
    record=  "  __nalign = scan(__align,1,' ');";                                                            output;
    record=  '  do __i=1 to &maxtrt;';                                                                       output;
    record=  "     __nalign = left(trim(__nalign))||' D';";                                                  output;
    record=  '  end;';                                                                                       output;
    record=  '  __align = trim(left(__nalign));';                                                            output;
    record=  '  drop __i __nalign; ';                                                                        output;
    record=  "run;";                                                                                         output;
    run;

    proc append base=rrgpgm data=rrgpgmtmp;
    run;

%end;



%if %upcase(&defreport_aetable)=EVENTS %then %do;

    data rrgpgmtmp;
    length record $ 2000;
    keep record;
    record=  "*----------------------------------------------------------------;";                           output;
    record=  "  * ADD EVENT COUNT TO TABLE;";                                                                output;
    record=  "*----------------------------------------------------------------;";                           output;
    record=  " ";                                                                                            output;
    record=  '  data __fall (rename=(%do i=1 %to %eval(2*&maxtrt);';                                         output;
    record=  '           __ncol_&i=__col_&i %end;));';                                                       output;
    record=  "  set __fall (rename=(";                                                                       output;
    record=  '  %do i=1 %to &maxtrt;';                                                                       output;
    record=  '  __col_&i = __ncol_%eval(2*&i-1)';                                                            output;
    record=  '  __colevt_&i =__ncol_%eval(2*&i)';                                                            output;
    record=  '  %end;';                                                                                      output;
    record=  "  ));";                                                                                        output;
    record=  "  length __nalign $ 2000;";                                                                    output;
    record=  "    __nalign = scan(__align,1,' ');";                                                          output;
    record=  '  do __i=1 to &maxtrt;';                                                                       output;
    record=  "        __nalign = left(trim(__nalign))||' '||";                                               output;
    record=  "            trim(left(scan(__align, __i+1, ' ')))||' D';";                                     output;
    record=  '  end;';                                                                                       output;
    record=  '  __align = trim(left(__nalign));';                                                            output;
    record=  '  drop __i __nalign; ';                                                                        output;
    record=  "run;";                                                                                         output;
    run;

    proc append base=rrgpgm data=rrgpgmtmp;
    run;

%end;




%if %upcase(&defreport_aetable)=EVENTSES %then %do;
    data rrgpgmtmp;
    length record $ 2000;
    keep record;
    record=  "*----------------------------------------------------------------;";                           output;
    record=  "  * ADD EVENT COUNT TO TABLE;";                                                                output;
    record=  "*----------------------------------------------------------------;";                           output;
    record=  " ";                                                                                            output;
    record=  '  data __fall (rename=(%do i=1 %to %eval(2*&maxtrt);';                                         output;
    record=  '           __ncol_&i=__col_&i %end;));';                                                       output;
    record=  "  set __fall (rename=(";                                                                       output;
    record=  '  %do i=1 %to &maxtrt;';                                                                       output;
    record=  '  __colevt_&i = __ncol_%eval(2*&i-1)';                                                         output;
    record=  '  __col_&i =__ncol_%eval(2*&i)';                                                               output;
    record=  '  %end;';                                                                                      output;
    record=  "  ));";                                                                                        output;
    record=  "  length __nalign $ 2000;";                                                                    output;
    record=  "    __nalign = scan(__align,1,' ');";                                                          output;
    record=  '  do __i=1 to &maxtrt;';                                                                       output;
    record=  "        __nalign = left(trim(__nalign))||' D '||";                                             output;
    record=  "            trim(left(scan(__align, __i+1, ' ')));";                                           output;
    record=  '  end;';                                                                                       output;
    record=  '  __align = trim(left(__nalign));';                                                            output;
    record=  '  drop __i __nalign; ';                                                                        output;
    record=  "run;";                                                                                         output;

    run;

    proc append base=rrgpgm data=rrgpgmtmp;
    run;

%end;



data rrgpgmtmp;
length record $ 2000;
keep record;
record=  '%if &numobsinall>1 %then %do;';                                                                                output;
record=  " ";                                                                                                            output;
record=  "data __fall;";                                                                                                 output;
record=  "  merge __fall __fall(firstobs=2 keep=__col_0 __vtype rename=(__col_0=__newcol0 __vtype=__nvtype));";          output;
record=  "  if index(__newcol0, '~-2n')=1 then do;";                                                                     output;
record=  "    __suffix='~-2n';";                                                                                         output;
record=  "  end;";                                                                                                       output;
record=  "  if index(__col_0, '~-2n')=1 then do;";                                                                       output;
record=  "    __col_0=substr(__col_0,5);";                                                                               output;
record=  "  end;";                                                                                                       output;
record=  "drop __newcol0;";                                                                                              output;
record=  "run;";                                                                                                         output;
record=  " ";                                                                                                            output;
record=  '%end;';                                                                                                        output;
record=  " ";                                                                                                            output;
run;

proc append base=rrgpgm data=rrgpgmtmp;
run;

data rrgpgmtmp;
length record $ 2000;
keep record;
record=  " ";                                                                                                            output;
record=  "*----------------------------------------------------------------;";                                           output;
record=  "* GET HEADER FOR THE TABLE;";                                                                                  output;
record=  "*----------------------------------------------------------------;";                                           output;
record=  " ";                                                                                                            output;
record=  "proc sort data=__poph;";                                                                                       output;
record=  "by &varby __rowid __trtvar __autospan __prefix;";                                                              output;
record=  "run;";                                                                                                         output;
record=  " ";                                                                                                            output;
record=  "proc transpose data=__poph out=__head prefix=__col_;";                                                         output;
record=  "by &varby __rowid __trtvar __autospan __prefix;";                                                              output;
record=  "id __trtid;";                                                                                                  output;
record=  "var __col;";                                                                                                   output;
record=  "run;";                                                                                                         output;
record=  " ";                                                                                                            output;


record=  "data __head;";                                                                                    output;
record=  '  length __datatype $ 8 __align __col_0 - __col_&maxtrt $ 2000;';                                 output;
record=  "  set __head end=eof;";                                                                           output;
record=  "  by &varby __rowid;";                                                                            output;
record=  '  array __col{*} __col_1-__col_&maxtrt;';                                                         output;
record=  "  __col_0='';";                                                                                   output;

%if &nvarby=0 %then %do;
    record=  "  if eof then __col_0 = " ||quote(dequote(strip(symget("defreport_colhead1"))))|| ";";                                              output;
%end;
%else %do;
    record=  "  if last.&&vby&nvarby then __col_0 = " ||quote(dequote(strip(symget("defreport_colhead1"))))||";";                               output;
%end;

record=  "  __datatype='HEAD';";                                                                            output;
record=  "  __align ='L'||repeat(' C', dim(__col));";                                                       output;
record=  "  drop  _name_;";                                                                                 output;
record=  "run;";                                                                                            output;
record=  " ";                                                                                               output;
record=  "*--------------------------------------------------------------------;";                          output;
record=  "* EXTRACT COMMON HEADER TEXT;";                                                                   output;
record=  "*--------------------------------------------------------------------;";                          output;
record=  " ";                                                                                               output;
run;

proc append base=rrgpgm data=rrgpgmtmp;
run;


%__spanh(dsin=__head);

%if %upcase(&defreport_aetable)=EVENTS   %then %do;

    data rrgpgmtmp;
    length record $ 2000;
    keep record;
    record=  " ";                                                                                           output;
    record=  "*--------------------------------------------------------------------;";                      output;
    record=  "* CREATE EVENT COUNT HEADINGS ;";                                                             output;
    record=  "*--------------------------------------------------------------------;";                      output;
    record=  " ";                                                                                           output;

    %if &nvarby>0 %then %do;
        record=  "proc sort data=__head;";                                                                  output;
        record=  "by &varby;";                                                                              output;
        record=  "run;";                                                                                    output;
        record=  " ";                                                                                       output;
    %end;

    record=  "  data __head ;";                                                                             output;
    record=  "  set __head end=eof ;";                                                                      output;

    %if &nvarby>0 %then %do;
        record=  "by &varby;";                                                                              output;
    %end;

    record=  '  length __ncol_0 %do i=1 %to &maxtrt;  __colevt_&i %end; $ 2000;';                           output;
    record=  "  retain __ncol_0;";                                                                          output;
    record=  '    %do i=1 %to &maxtrt;  ';                                                                  output;
    record=  '    __colevt_&i=__col_&i;';                                                                   output;
    record=  '  %end;';                                                                                     output;
    record=  " ";                                                                                           output;

    %if &nvarby=0 %then %do;
        record=  "    if eof then do;";                                                                     output;
        record=  "    __ncol_0=__col_0;";                                                                   output;
        record=  "    __col_0='';";                                                                         output;
        record=  "    output;";                                                                             output;
    %end;

    %else %do;
        record=  "      if last.&&vby&nvarby then do;";                                                     output;
        record=  "    __ncol_0=__col_0;";                                                                   output;
        record=  "    __col_0='';";                                                                         output;
        record=  "    output;";                                                                             output;
    %end;

    record=  "     __col_0 = __ncol_0;";                                                                    output;
    record=  "     __rowid+1;";                                                                             output;
    record=  '    %do i=1 %to &maxtrt;  ';                                                                  output;
    record=  '      __col_&i= "Number of Subjects";';                                                       output;
    record=  '      __colevt_&i = "Number of Events";';                                                     output;
    record=  '    %end;';                                                                                   output;
    record=  "        output;";                                                                             output;
    record=  "  end;";                                                                                      output;
    record=  "  else output;";                                                                              output;
    record=  "  run;";                                                                                      output;
    record=  "  data __head (drop=__align rename=(__nalign=__align ";                                       output;
    record=  '      %do i=1 %to %eval(2*&maxtrt); __ncol_&i=__col_&i %end;));';                             output;
    record=  "  set __head (rename=(";                                                                      output;
    record=  '  %do i=1 %to &maxtrt;';                                                                      output;
    record=  '  __col_&i = __ncol_%eval(2*&i-1)';                                                           output;
    record=  '  __colevt_&i =__ncol_%eval(2*&i)';                                                           output;
    record=  '  %end;';                                                                                     output;
    record=  "  )) end=eof ;";                                                                              output;
    record=  "  length __nalign $ 2000;";                                                                   output;
    record=  "    __nalign = scan(__align,1,' ');";                                                         output;
    record=  '  do __i=1 to &maxtrt;';                                                                      output;
    record=  "        __nalign = left(trim(__nalign))||' C C';";                                            output;
    record=  '  end;';                                                                                      output;
    record=  "  run;";                                                                                      output;
    record=  '  %let maxtrt = %eval(2*&maxtrt);';                                                           output;

    run;

    proc append base=rrgpgm data=rrgpgmtmp;
    run;

%* end of aetable=events;
%end;


%if %upcase(&defreport_aetable)=EVENTSES %then %do;

    data rrgpgmtmp;
    length record $ 2000;
    keep record;
    record=  " ";                                                                                             output;
    record=  "*--------------------------------------------------------------------;";                        output;
    record=  "* CREATE EVENT COUNT HEADINGS ;";                                                               output;
    record=  "*--------------------------------------------------------------------;";                        output;
    record=  " ";                                                                                             output;

    %if &nvarby>0 %then %do;
        record=  "proc sort data=__head;";                                                                    output;
        record=  "by &varby;";                                                                                output;
        record=  "run;";                                                                                      output;
        record=  " ";                                                                                         output;
    %end;

    record=  "  data __head ;";                                                                               output;
    record=  "  set __head end=eof ;";                                                                        output;

    %if &nvarby>0 %then %do;
        record=  "by &varby;";                                                                                output;
    %end;

    record=  '  length __ncol_0 %do i=1 %to &maxtrt;  __colevt_&i %end; $ 2000;';                             output;
    record=  "  retain __ncol_0;";                                                                            output;
    record=  '    %do i=1 %to &maxtrt;  ';                                                                    output;
    record=  '    __colevt_&i=__col_&i;';                                                                     output;
    record=  '  %end;';                                                                                       output;
    record=  " ";                                                                                             output;

    %if &nvarby=0 %then %do;
        record=  "    if eof then do;";                                                                       output;
        record=  "    __ncol_0=__col_0;";                                                                     output;
        record=  "    __col_0='';";                                                                           output;
        record=  "    output;";                                                                               output;
    %end;
    %else %do;
        record=  "      if last.&&vby&nvarby then do;";                                                       output;
        record=  "    __ncol_0=__col_0;";                                                                     output;
        record=  "    __col_0='';";                                                                           output;
        record=  "    output;";                                                                               output;
    %end;

    record=  "     __col_0 = __ncol_0;";                                                                      output;
    record=  "     __rowid+1;";                                                                               output;
    record=  '    %do i=1 %to &maxtrt;  ';                                                                    output;
    record=  '      __col_&i= "Number of  Subjects";';                                                        output;
    record=  '      __colevt_&i = "Number of Events";';                                                       output;
    record=  '    %end;';                                                                                     output;
    record=  "        output;";                                                                               output;
    record=  "  end;";                                                                                        output;
    record=  "  else output;";                                                                                output;
    record=  "  run;";                                                                                        output;
    record=  "  data __head (drop=__align rename=(__nalign=__align ";                                         output;
    record=  '      %do i=1 %to %eval(2*&maxtrt); __ncol_&i=__col_&i %end;));';                               output;
    record=  "  set __head (rename=(";                                                                        output;
    record=  '  %do i=1 %to &maxtrt;';                                                                        output;
    record=  '  __colevt_&i = __ncol_%eval(2*&i-1)';                                                          output;
    record=  '  __col_&i =__ncol_%eval(2*&i)';                                                                output;
    record=  '  %end;';                                                                                       output;
    record=  "  )) end=eof ;";                                                                                output;
    record=  "  length __nalign $ 2000;";                                                                     output;
    record=  "    __nalign = scan(__align,1,' ');";                                                           output;
    record=  '  do __i=1 to &maxtrt;';                                                                        output;
    record=  "        __nalign = left(trim(__nalign))||' C C';";                                              output;
    record=  '  end;';                                                                                        output;
    record=  "  run;";                                                                                        output;
    record=  '  %let maxtrt = %eval(2*&maxtrt);';                                                             output;

    run;

    proc append base=rrgpgm data=rrgpgmtmp;
    run;

%* end of aetable=eventses;
%end;




%local splitrow;
proc sql noprint;
  select splitrow into:splitrow separated by ' '
    from __varinfo(where=(type='TRT'));
quit;

%if %length(&splitrow) %then %do;

    data rrgpgmtmp;
    length record $ 2000;
    keep record;
    record=  "  data __head(drop=__rowid __i __ncol: __split __issplit: ";                                          output;
    record=  "             rename=(__newrowid=__rowid));";                                                          output;
    record=  '    length __split $ 1 __ncol_0 - __ncol_&maxtrt $ 200;';                                             output;
    record=  "    set __head;";                                                                                     output;
    record=  "    retain __newrowid;";                                                                              output;
    record=  "    if _n_=0 then __newrowid=0;";                                                                     output;
    record=  " ";                                                                                                   output;
    record=  '    array cols{*} __col_1-__col_&maxtrt;';                                                            output;
    record=  '    array ncols{*} __ncol_1-__ncol_&maxtrt;';                                                         output;
    record=  '    __split ="&splitrow";';                                                                           output;
    record=  "    __issplit=0;";                                                                                    output;
    record=  "    __ncol_0=__col_0;";                                                                               output;
    record=  " ";                                                                                                   output;
    record=  "    if __trtvar ne 1 then do;";                                                                       output;
    record=  "      __newrowid+1;";                                                                                 output;
    record=  "      output;";                                                                                       output;
    record=  "    end;";                                                                                            output;
    record=  "    else do;";                                                                                        output;
    record=  "    do __i=1 to dim(cols);";                                                                          output;
    record=  "      ncols[__i]=cols[__i]; ";                                                                        output;
    record=  "        if index(ncols[__i],__split)>0 then __issplit=1; ";                                           output;
    record=  "    end;    ";                                                                                        output;
    record=  "    do while (__issplit=1);";                                                                         output;
    record=  "      __issplit=0;";                                                                                  output;
    record=  "      do __i=1 to dim(cols);";                                                                        output;
    record=  " ";                                                                                                   output;
    record=  "        __ind = index(ncols[__i],__split);";                                                          output;
    record=  "        if __ind=1 then do;";                                                                         output;
    record=  "          cols[__i]='';";                                                                             output;
    record=  "          ncols[__i]=substr(ncols[__i],__ind+1);";                                                    output;
    record=  "        end;";                                                                                        output;
    record=  "        else if __ind>0 and __ind<length(ncols[__i]) then do;";                                       output;
    record=  "          cols[__i]=substr(ncols[__i],1,__ind-1);";                                                   output;
    record=  "          ncols[__i]=substr(ncols[__i],__ind+1);";                                                    output;
    record=  "        end;";                                                                                        output;
    record=  " ";                                                                                                   output;
    record=  "        else if __ind=length(ncols[__i]) then do;";                                                   output;
    record=  "          cols[__i]=substr(ncols[__i],1,__ind-1);";                                                   output;
    record=  "          ncols[__i]='';";                                                                            output;
    record=  "        end;";                                                                                        output;
    record=  "      else do;";                                                                                      output;
    record=  "           cols[__i]=ncols[__i];";                                                                    output;
    record=  "         ncols[__i]='';";                                                                             output;
    record=  "      end;";                                                                                          output;
    record=  "      __issplit2 = index(ncols[__i],__split);";                                                       output;
    record=  "        if __issplit2>0 then __issplit=1;";                                                           output;
    record=  "      put cols[__i]= ncols[__i]=;";                                                                   output;
    record=  "      end;  ";                                                                                        output;
    record=  "      __newrowid+1;";                                                                                 output;
    record=  "      __col_0='';";                                                                                   output;
    record=  "      output;  ";                                                                                     output;
    record=  "      put __issplit=;";                                                                               output;
    record=  "    end;";                                                                                            output;
    record=  "    __newrowid+1;";                                                                                   output;
    record=  "    do __i=1 to dim(cols);";                                                                          output;
    record=  "      cols[__i]=ncols[__i];";                                                                         output;
    record=  "      __col_0=__ncol_0;";                                                                             output;
    record=  "    end;";                                                                                            output;
    record=  " ";                                                                                                   output;
    record=  "    output;";                                                                                         output;
    record=  "  end;";                                                                                              output;
    record=  "  run;";                                                                                              output;
    record=  " ";                                                                                                   output;
    run;

    proc append base=rrgpgm data=rrgpgmtmp;
  run;

%* end of length(splitrow);
%end;

data rrgpgmtmp;
length record $ 2000;
keep record;
record=  " ";                                                                                                      output;
record=  "proc sort data=__head;";                                                                                 output;
record=  "  by &varby __rowid;";                                                                                   output;
record=  "run;";                                                                                                   output;
record=  " ";                                                                                                      output;
record=  "data __head (drop = __rowid rename=(__nrowid=__rowid));";                                                output;
record=  "  set __head end=eof;  ";                                                                                output;
record=  "  by &varby __rowid;";                                                                                   output;
record=  "  retain __nrowid;";                                                                                     output;

%if %length(&varby) %then %do;
    record=  "if first.&&vby&nvarby then __nrowid=0;";                                                             output;
    record=  "  if not last.&&vby&nvarby then do;";                                                                output;
    record=  "    __align = tranwrd(__align, 'R', 'C');";                                                          output;
    record=  "    __align = tranwrd(__align, 'D', 'C');";                                                          output;
    record=  "  end;";                                                                                             output;
%end;
%else %do;
    record=  "if _n_=1 then __nrowid=0;";                                                                          output;
    record=  "  if not eof then do;";                                                                              output;
    record=  "    __align = tranwrd(__align, 'R', 'C');";                                                          output;
    record=  "    __align = tranwrd(__align, 'D', 'C');";                                                          output;
    record=  "  end;";                                                                                             output;
%end;

record=  "  __nrowid+1;";                                                                                          output;
record=  "run;";                                                                                                   output;
record=  " ";                                                                                                      output;
run;

proc append base=rrgpgm data=rrgpgmtmp;
run;



%local rrgoutpathlazy;
%let rrgoutpathlazy=&rrgoutpath;




data rrgpgmtmp;
length record $ 2000;
keep record;
*set __repinfo;

%if &nvarby>0 %then %do;

    %let varby=%sysfunc(compbl(&varby));

    %local tmp;
    %let tmp=%sysfunc(tranwrd(&varby,%str( ), %str(,)));

    record=  " ";                                                                                                 output;
    record=  "*--------------------------------------------------------;";                                        output;
    record=  "* ADD <PAGE BY> VARIABLE LABEL TO HEADER RECORDS;";                                                 output;
    record=  "*--------------------------------------------------------;";                                        output;
    record=  " ";                                                                                                 output;
    record=  "proc sql noprint;";                                                                                 output;
    record=  "create table __varlab as select distinct ";                                                         output;
    record=  "&tmp   ,";                                                                                          output;
    record=  "   __varbylab from __fall ;";                                                                       output;
    record=  " quit;";                                                                                            output;
    record=  " ";                                                                                                 output;
    record=  "  proc sort data=__head;";                                                                          output;
    record=  "  by &varby;";                                                                                      output;
    record=  "  run;";                                                                                            output;
    record=  " ";                                                                                                 output;
    record=  "proc sort data=__varlab;";                                                                          output;
    record=  "  by &varby;";                                                                                      output;
    record=  "  run;";                                                                                            output;
    record=  " ";                                                                                                 output;
    record=  "  data __head;";                                                                                    output;
    record=  "  merge __head __varlab (in=__invb);";                                                              output;
    record=  "  by &varby;";                                                                                      output;
    record=  " if __invb;";                                                                                       output;
    record=  "  run;";                                                                                            output;
%end;

record=  " ";                                                                                                     output;
record=  "*------------------------------------------------------------------;";                                  output;
record=  "* JOIN TABLE BODY AND TABLE HEADER;";                                                                   output;
record=  "*------------------------------------------------------------------;";                                  output;
record=  " ";                                                                                                     output;
record=  "data __fall;";                                                                                          output;
record=  "  set __head __fall;";                                                                                  output;
record=  '  format %do i=0 %to &maxtrt; __col_&i %end;;';                                                         output;
record=  '  informat %do i=0 %to &maxtrt; __col_&i %end;;';                                                       output;
record=  'run;';                                                                                                  output;

%if &nvarby>0 %then %do;

    record=  " ";                                                                                                 output;
    record=  "*--------------------------------------------------------;";                                        output;
    record=  "* CREATE A SINGLE __VARBYGRP VARIABLE;";                                                            output;
    record=  "*--------------------------------------------------------;";                                        output;
    record=  " ";                                                                                                 output;
    record=  "  proc sort data=__fall;";                                                                          output;
    record=  "  by &varby;";                                                                                      output;
    record=  "  run;";                                                                                            output;
    record=  " ";                                                                                                 output;
    record=  "  data __fall;";                                                                                    output;
    record=  "  set __fall;";                                                                                     output;
    record=  "  by &varby;";                                                                                      output;
    record=  "  retain __varbygrp ;";                                                                             output;
    record=  "  if _n_=1 then __varbygrp=0;";                                                                     output;
    record=  "  if first.&&vby&nvarby then do;";                                                                  output;
    record=  "        __varbygrp+1;";                                                                             output;
    record=  "  end;";                                                                                            output;
    record=  "  run;";                                                                                            output;
    record=  " ";                                                                                                 output;
    record=  "   proc sql noprint;";                                                                              output;
    record=  "    create table __falltmp as select * from __fall where";                                          output;
    record=  "      __varbygrp in (select distinct __varbygrp from __fall (where=(__datatype='TBODY')));";        output;
    record=  "    create table __fall as select * from __falltmp;  ";                                             output;
    record=  "    quit;";                                                                                         output;
    record=  " ";                                                                                                 output;
    record=  " ";                                                                                                 output;
%end;

record=  " ";                                                                                                          output;
record= '*--------------------------------------------------------------;';                                            output;
record= '* if RCD has only __vtype=LABEL, generate "no data" report;';                                                 output;
record= '*--------------------------------------------------------------;';                                            output;
record=  " ";                                                                                                          output;
record=  '%local vtypes;';                                                                                             output;
record=  'proc sql noprint;';                                                                                          output;
record=  "  select distinct __vtype into:vtypes separated by ' ' ";                                                    output;
record=  "    from __fall (where=(__vtype not in ('VLABEL','LABEL')));";                                               output;
record=  ' quit; ';                                                                                                    output;
record=  " ";                                                                                                          output;
record=  '%if %length(&vtypes)=0 %then %do;';                                                                          output;

%if &nvarby=0 and &trtacross =Y %then %do;

record=  "  data __fall;";                                                                                             output;
record=  "  __col_0=' ';";                                                                                             output;
record=  "  __ROWID = 10;";                                                                                            output;
record=  "  __indentlev = 0;";                                                                                         output;
record=   "  __tcol='"||strip(symget("defreport_nodatamsg"))||"';";                                                    output;
record=  "  __VTYPE = 'DUMMY';";                                                                                       output;
record=  "__DATATYPE='TBODY';";                                                                                        output;
record=  "__colwidths='NH NH';";                                                                                       output;
record=  "__ALIGN='C';";                                                                                               output;
record=  "  run;  ";                                                                                                   output;
record=  " ";                                                                                                          output;
record=  "proc transpose data=__poph out=__head prefix=__col_;";                                                       output;
record=  "by &varby __rowid __trtvar __autospan __prefix;";                                                            output;
record=  "id __trtid;";                                                                                                output;
record=  "var __col;";                                                                                                 output;
record=  "run;";                                                                                                       output;
record=  " ";                                                                                                          output;
record=  "data __fall;";                                                                                               output;
record=  "  set __head (in=a) __fall;";                                                                                output;
record=  "  if a then do;";                                                                                            output;
record=  "   __datatype='HEAD'; ";                                                                                     output;
record=  "  end;";                                                                                                     output;
record=  "run;  ";                                                                                                     output;
record=  '  %let maxtrt=1;';                                                                                           output;
record=  '%end;';                                                                                                      output;
record=  " ";                                                                                                          output;
record=  " ";                                                                                                          output;
record=  " ";                                                                                                          output;
record= '%dotab:';                                                                                                     output;
record=  " ";                                                                                                          output;
%end;

%else %do;

record=  " data __fall;"; output;
record=  " if 0;"; output;
record=  " __indentlev=.;"; output;
record=  " run;"; output;
record=  " "; output;
record=  '  %let maxtrt=1;';                                                                                           output;
record=  '%end;';                                                                                                      output;
record=  " ";                                                                                                          output;
record=  " ";                                                                                                          output;
record=  " ";                                                                                                          output;
record= '%dotab:';                                                                                                     output;
record=  " ";                                                                                                          output;
%end;

run;

proc append base=rrgpgm data=rrgpgmtmp;
run;




%__makerepinfo;


data rrgpgmtmp;
length record $ 2000;
keep record;
record=  " ";                                                                                                          output;
record=  "data &rrguri;";                                                                                              output;
record=  "  set rrgreport __fall ;";                                                                                    output;
record=  "run;";                                                                                                       output;
record=  " ";                                                                                                          output;
record=  " ";                                                                                                          output;
run;

proc append base=rrgpgm data=rrgpgmtmp;
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




%if &defreport_statsincolumn=Y %then %do;

  %__rrg_unindentv;

%end;




data rrgpgmtmp;
length record $ 2000;
keep record;
record=  " ";                                                                                                                                     output;
record=  " ";                                                                                                                                     output;
record=  "* -----------------------------------------------------------------------;";                                                            output;
record=  "* CREATE VARIABLE __NEXT_INDENTLEV TO INDICATE NEXT INDENT LEVEL;";                                                                     output;
record=  "* -----------------------------------------------------------------------;";                                                            output;
record=  " ";                                                                                                                                     output;
record=  "proc sort data=&rrguri;";                                                                                                               output;
record=  "  by  __datatype __varbygrp descending __rowid;";                                                                                       output;
record=  "run;";                                                                                                                                  output;
record=  " ";                                                                                                                                     output;
record=  "data &rrguri;";                                                                                                                         output;
record=  "  set &rrguri;";                                                                                                                        output;
record=  "  by  __datatype __varbygrp descending __rowid;";                                                                                       output;
record=  "  length __cellfonts __cellborders  __title1_cont __label_cont $ 500 __topborderstyle __bottomborderstyle $ 2;";                        output;
record=  "  __cellfonts = '';";                                                                                                                   output;
record=  "  __cellborders = '';";                                                                                                                 output;
record=  "  __topborderstyle='';";                                                                                                                output;
record=  "  __bottomborderstyle='';";                                                                                                             output;
record=  "  __label_cont='';";                                                                                                                    output;
record=  "  __title1_cont='';";                                                                                                                   output;
record=  "  __next_indentlev=lag(__indentlev);";                                                                                                  output;
record=  "  if first.__datatype then __next_indentlev=.;";                                                                                        output;
record=  "run;";                                                                                                                                  output;
record=  " ";                                                                                                                                     output;
record=  "proc sort data=&rrguri;";                                                                                                               output;
record=  "  by  __datatype __varbygrp  __rowid;";                                                                                                 output;
record=  "run;";                                                                                                                                  output;
record=  " ";                                                                                                                                     output;            
record=  " ";                                                                                                                                     output;
record=  '%mend;';                                                                                                                                output;
record=  " ";                                                                                                                                     output;
record=  " ";                                                                                                                                     output;
record=  '%rrg;';                                                                                                                                 output;
record=  'sasfile work.__dataset close;   '  ;                                                                                                    output;
record=  "run;";                                                                                                                                  output;

run;

proc append base=rrgpgm data=rrgpgmtmp;
run;



data _null_;
  set rrgfmt;
  *record = tranwrd(strip(record), '%', '/#0037 ');
  call execute(cats('%nrstr(',record,')'));

run;


%let __workdir = %sysfunc(getoption(work));
%let __workdir=%sysfunc(tranwrd(&__workdir, %str(\), %str(/) ));


data _null_;
  set rrgpgm;

  file "&__workdir./rrgpgm.sas"  lrecl=1000;
  put record  ;

run;





%if &rrg_debug>0 %then %do;
data __timer;
  set __timer end=eof;
	length task $ 100;
	output;
		if eof then do;
		  task = "ANALYSING RRG MACROS STARTED";
		  dt=datetime();
		  output;
		end;
run;
%end;

%inc "&__workdir./rrgpgm.sas";
%if &rrg_debug>0 %then %do;
data __timer;
  set __timer end=eof;
	length task $ 100;
	output;
		if eof then do;
		  task = "MACRO EXECUTION FINISHED";
		  dt=datetime();
		  output;
		end;
run;
%end;
%exit:




%put;
%put;
%put ------------------------------------------------------------------------;;
%put  FINISHED PROGRAM GENERATING STEP;;
%put ------------------------------------------------------------------------;;
%put;
%put;





%mend;
