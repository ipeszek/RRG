/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __getcntae(datain=, unit=, group=, cnt=, dataout=, 
                 trtvar=, var=)/store;

%* creates a dataset with count of distinc &unit, grouped by &group;
%* provides count for each grouping variable as well if cntallgrpYN=Y;
%* note: unit is one variable;


%local datain unit group  cnt dataout  trtvar var;

%let datain = %unquote(&datain);


record = " ";  output;
record =  "data &dataout;"; output;
record =  "if 0;"; output;
record =  "run;"; output;
record = " "; output;
record =  "data __out; if 0; run;"; output;
record = " "; output;
record =  "*-------------------------------------------------------------------;"; output;
record =  "* GET NUMBER OF DISTINCT &UNIT IN EACH ;"; output;
record =  "*    &trtvar &group &var COMBINATION;"; output;
record =  "*-------------------------------------------------------------------;"; output;
record = " "; output;
%local tmp1 tmp2;
%let tmp1=%sysfunc(tranwrd(%sysfunc(compbl( &trtvar &group &var)), 
   %str( ), %str(,)));
%let tmp2= %sysfunc(tranwrd(%sysfunc(compbl( &trtvar &group &var &unit)),
     %str( ), %str(,))) ;
record =  "proc sql noprint;"; output;
record =  "    create table &dataout as"; output;
record =  "    select  &tmp1, "; output;
record =  "      count(*) as &cnt, 999 as __grpid from "; output;
record =  "    (select distinct &tmp2"; output;
record =  "    from  &datain)"; output;
record =  "    group by &tmp1"; output;
record =  "    order by &tmp1;"; output;
record =  "quit;"; output;
record = " "; output;
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
     
%do i=1 %to &numgroups;

    %* DO SEQUENTIAL NODUPKEY SORT AND COUNT OF GROUPING VARIABLE; 
    record =  "*------------------------------------------------------------------;"; output;
    record =  "* GET NUMBER OF DISTINCT &UNIT IN EACH &trtvar &&ngrp&i COMBINATION;"; output;
    record =  "*------------------------------------------------------------------;"; output;
    record = " ";   output;
    record =  "proc sort data=&datain nodupkey;"; output;
    record =  "    by &trtvar &&ngrp&i &unit;"; output;
    record =  "  run;"; output;
    %local j;
    %let j = %eval(&numgroups-&i+1);
    %local tmp1 tmp2;
    %let tmp1 = %sysfunc(tranwrd(%sysfunc(compbl(&trtvar &&ngrp&i )),
         %str( ), %str(,)));
    %let tmp2 = %sysfunc(tranwrd(%sysfunc(compbl(&trtvar &&ngrp&i &unit)),
        %str( ), %str(,)));
    record = " ";  output;
    record =  "  proc sql noprint;"; output;
    record =  "    create table __out as"; output;
    record =  "    select &tmp1, count(*) as &cnt, &j as __grpid from "; output;
    record =  "    (select distinct &tmp2"; output;
    record =  "    from  &datain)"; output;
    record =  "    group by &tmp1"; output;
    record =  "    order by &tmp1;"; output;
    record =  "  quit;"; output;
    record = " "; output;
    record =  "  data &dataout;"; output;
    record =  "set &dataout __out;"; output;
    record =  "  run;"; output;

%end;
record = " "; output;
record =  "proc sql noprint;"; output;
record =  "  drop table __out;"; output;
record =  "quit;"; output;
record = " "; output;

%mend;

