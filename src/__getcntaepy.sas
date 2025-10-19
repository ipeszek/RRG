/*
 * RRG: statistical reporting system.
 *
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product.
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

 /* this is based on __getscountaew macro, adding calculation of patient-year variable

 patdays: variable indicating duration of patient for patients w/out event, in days
 onsetvar: variable indicating onset of ae event, in days, derived in cntsaepy

 some macro variables used inside:

datain:  __datasetc: __dataset where defreport_tabwhere and addcatvar.where
unit:   &defreport_subjid __theid (unless rrg_addcatvar.asubjid is spcified - then asubjid __theid)
group:  __tby + all group vars with page ne Y
var:  __order &var &decode
trtvar: all group variables with page=Y + group vars with page ne Y and aegroup ne Y + __trtid rrg_addtrt.name
cnt = __cnt
dataout: __catcn42

__theid= constant 0 for real records in the __dataset, and negative number for artificially added records by usecodesds


 */

%macro __getcntaepy(datain=, unit=, group=,  cnt=, dataout=,
                 trtvar=, var=
                 )/store;

%* creates a dataset with count of distinc &unit, grouped by &group;
%* provides count for each grouping variable as well if cntallgrpYN=Y;
%* note __patdays and __days2firstevent (both in days) are derived cntsaepy macro;


%local datain unit unit4sql group   cnt dataout  trtvar var    ;

%let unit=%sysfunc(compbl(&unit));
%let unit4sql = %sysfunc(tranwrd(&unit, %str( ) , %str(, )));
%let datain = %unquote(&datain);

%local group4sql ;
%let group4sql=%sysfunc(tranwrd(%sysfunc(compbl( &trtvar  &group &var)),   %str( ), %str(,)));

%local i allbyvars;



record = " ";  output;
record =  "data &dataout;"; output;
record =  "if 0;"; output;
record =  "run;"; output;
record = " "; output;
record =  "data __out; if 0; run;"; output;
record = " "; output;
record =  "*-------------------------------------------------------------------;"; output;
record =  "* GET NUMBER OF DISTINCT &UNIT AND SUM of __days2firstevent IN EACH ;"; output;
record =  "*    &trtvar  &group &var COMBINATION;"; output;
record =  "*-------------------------------------------------------------------;"; output;
record = " "; output;


record = " "; output;
record =  "*-------------------------------------------------------------------;"; output;
record =  "* select first occurence of event and calculate number of patients ;";  output;
record =  "*    with event AND SUM of __days2firstevent for this level;";                  output;
record =  "*-------------------------------------------------------------------;"; output;
record = " "; output;


record =  "    proc sort data=&datain out=__tmp;                          "; output;
record =  "      by &trtvar &group &var &unit  __days2firstevent;                 "; output;
record =  "    run;                                                       "; output;
record =  "                                                               "; output;
record =  "     data __tmp;                                               "; output;
record =  "      set __tmp;                                               "; output;
record =  "      by &trtvar  &group &var &unit __days2firstevent;                        "; output;
record =  "      if first.%qscan(&unit,-1);                                          "; output;
record =  "     run;                                                      "; output;
record = " "; output;

record =  "proc sql;                                                                                           "; output;  
record =  "  create table __dummy as select * from                                                             "; output;  
record =  "  (select distinct %sysfunc(tranwrd(%sysfunc(compbl(&trtvar &unit __patdays)), %str( ), %str(, )))   "; output;  
record =  "  from __dataset  )                                                                                  "; output;  
record =  "  cross join                                                                                         "; output;  
record =  "  (select distinct %sysfunc(tranwrd(%sysfunc(compbl(&group &var)), %str( ), %str(, )))               "; output;  
record =  "  from __tmp  )                                                                                  "; output;  
record =  "  order by %sysfunc(tranwrd(%sysfunc(compbl(&trtvar &group &var &unit)), %str( ), %str(, )));                   "; output;  
record =  "quit;                                                                                               "; output;  
record =  "                                                                                                    "; output;  
record =  "data __tmp;                                                                                         "; output;  
record =  "  merge __tmp (in=a) __dummy;                                                                       "; output;  
record =  "  by &trtvar &group &var &unit;                                                                                 "; output;  
record =  "  if not a then __days2firstevent=__patdays;                                                        "; output;  
record =  "  if  a then __countit=1;                                                                           "; output;  

  record =  "run;                                                                                                "; output;  
record = " "; output;
    
record =  "proc sql noprint;"; output;

record =  "    create table &dataout (where=(&cnt ne .)) as"; output;
record =  "      select  &group4sql, "; output;

record =  "        sum(__countit) as &cnt, sum(__days2firstevent) as __sumdays ,  999 as __grpid from __tmp"; output;
record =  "        group by &group4sql"; output;
record =  "        order by &group4sql;"; output;
record = " "; output;
record = "     quit; "; output;



%local i j numgroups tmp;
%let numgroups = %sysfunc(countw(&group, %str( )));
%do i=1 %to &numgroups;
    %local grp&i;
    %let grp&i = %scan(&group, &i, %str( ));
    %let j = %eval(&numgroups-&i+1);
    %local ngrp&j;
    %let ngrp&j =  &tmp &&grp&i;
    %let tmp = &tmp &&grp&i;
%end;

/* %do i=1 %to &numgroups;      */
%do i=1 %to %eval(&numgroups-1);

    %* DO SEQUENTIAL NODUPKEY SORT AND COUNT OF GROUPING VARIABLE;
    record =  "*------------------------------------------------------------------;"; output;
    record =  "* GET NUMBER OF DISTINCT &UNIT IN EACH &trtvar &&ngrp&i COMBINATION;"; output;
    record =  "*AND SUM OF DAYS TO FIRST EVENT;"; output;

    record =  "*------------------------------------------------------------------;"; output;
    record = " ";   output;



    %local j;
    %let j = %eval(&numgroups-&i+1);
/*       %if &j = &numgroups %then %let j=999;   */
/*  2024-08-13*/   
    %local group4sql ;
    %let group4sql = %sysfunc(tranwrd(%sysfunc(compbl(&trtvar &&ngrp&i )),
         %str( ), %str(,)));


record =  "   proc sort data=&datain out=__tmp;                "; output;
record =  "      by &trtvar &&ngrp&i &unit __days2firstevent;          "; output;
record =  "   run;                                             "; output;
record =  "                                                    "; output;
record =  "     data __tmp;                                    "; output;
record =  "      set __tmp;                                   "; output;
record =  "      by &trtvar &&ngrp&i &unit __days2firstevent;          "; output;
record =  "      if first.%qscan(&unit,-1);                               "; output;
record =  "     run;                                           "; output;
record =  "*---------------------------------------------------------------------------;"; output;
    
record =  "proc sql;                                                                                           "; output;  
record =  "  create table __dummy as select * from                                                             "; output;  
record =  "  (select distinct %sysfunc(tranwrd(%sysfunc(compbl(&trtvar &unit __patdays)), %str( ), %str(, )))   "; output;  
record =  "  from __dataset  )                                                                                  "; output;  
record =  "  cross join                                                                                         "; output;  
record =  "  (select distinct %sysfunc(tranwrd(%sysfunc(compbl(&&ngrp&i )), %str( ), %str(, )))               "; output;  
record =  "  from __tmp  )                                                                                  "; output;  
record =  "  order by %sysfunc(tranwrd(%sysfunc(compbl(&trtvar &&ngrp&i &unit)), %str( ), %str(, )));                   "; output;  
record =  "quit;                                                                                               "; output;  
record =  "                                                                                                    "; output;  
  
record =  "data __tmp;                                                                                         "; output;  
record =  "  merge __tmp (in=a) __dummy;                                                                       "; output;  
record =  "  by &trtvar &&ngrp&i &unit;                                                                                 "; output;  
record =  "  if not a then __days2firstevent=__patdays;                                                        "; output;  
record =  "  if  a then __countit=1;                                                                           "; output;  
  record =  "run;                                                                                                "; output;  
    

record =  "proc sql noprint;"; output;
record = " "; output;
record =  "    create table __out  (where=(&cnt ne .)) as"; output;
record =  "    select  &group4sql, "; output;
record =  "      sum(__countit) as &cnt, sum(__days2firstevent) as __sumdays , &j as __grpid from __tmp"; output;
record =  "    group by &group4sql"; output;
record =  "    order by &group4sql;"; output;
record = " "; output;
record =  "quit;"; output;
record = " "; output;


record = " "; output;
record =  "  data &dataout;"; output;
record =  "set &dataout __out;"; output;
record =  "  run;"; output;

%end;

record =  "data &dataout;                                          "; output;
record =  "  set &dataout;                                         "; output;
record =  "    __py=__sumdays/365.25;           "; output;
record =  "    __pyr = &multiplier* &cnt/__py;                     "; output;
record =  "  run;                                                  "; output;

record = " "; output;

record =  "proc sql noprint;"; output;
record =  "  drop table __tmp, __dummy,  __out;"; output;
record =  "quit;"; output;
record = " "; output;

%mend;

