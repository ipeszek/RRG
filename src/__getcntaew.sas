/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __getcntaew(datain=, unit=, group=, cnt=, dataout=, 
                 trtvar=, var=, desc=, where=, total=N)/store;

%* creates a dataset with count of distinc &unit, grouped by &group;
%* provides count for each grouping variable as well if cntallgrpYN=Y;
%* note: unit is one variable;


%local datain unit group  cnt dataout  trtvar var  desc where total;


%let datain = %unquote(&datain);


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
     
%if %upcase(&desc)=Y %then %let desc=descending;
%else %let desc= ;    






record = " ";  output;
record =  "data &dataout;"; output;
record =  "if 0;"; output;
record =  "run;"; output;
record = " "; output;
record =  "data __out; if 0; run;"; output;

     
%do i=1 %to &numgroups;
    record = " "; output;
    record = " ";   output;
    record = " ";   output;
    record =  "*-------------------------------------------------------------------;"; output;
    record =  "* TAKE THE MAXIMUM &VAR;"; output;
    record =  "*-------------------------------------------------------------------;"; output;
    record = " "; output;
    record =  "proc sort data=&datain nodupkey out=__tmpdatain;"; output;
    record =  "  by &trtvar &&ngrp&i  &unit &desc &var;"; output;
    record =  "run;"; output;
    record = " "; output;
    record =  "data __tmpdatain;"; output;
    record =  "  set __tmpdatain;"; output;
    record =  "  by &trtvar &&ngrp&i &unit &desc &var;"; output;
    record =  "  if last.%scan(&unit,-1, %str( ));"; output;
    record =  "run;"; output;
    record = " "; output;
    record = " "; output;

    %if &total=N %then %do;
        record =  "*-------------------------------------------------------------------;"; output;
        record =  "* COUNT NUMBER OF DISTINCT &UNIT IN EACH "; output;
        record =  "*   &trtvar &&ngrp&i &var COMBINATION;"; output;
        record =  "*-------------------------------------------------------------------;"; output;
        record = " "; output;
           %local j;
           %let j = %eval(&numgroups-&i+1);
           %if &j = &numgroups %then %let j=999;
           %local tmp1 tmp2;
           %let tmp1 = %sysfunc(tranwrd(%sysfunc(compbl(&trtvar &&ngrp&i  &var)), 
              %str( ), %str(,)));
           %let tmp2 = %sysfunc(tranwrd(%sysfunc(compbl(&trtvar &&ngrp&i &unit &var)),
                %str( ), %str(,)));
    %end;
    %else %do;
        record =  "*-------------------------------------------------------------------;"; output;
        record =  "* COUNT NUMBER OF DISTINCT &UNIT IN EACH "; output;
        record =  "*   &trtvar &&ngrp&i  COMBINATION;"; output;
        record =  "*-------------------------------------------------------------------;"; output;
        record = " "; output;
           %local j;
           %let j = %eval(&numgroups-&i+1);
           %if &j = &numgroups %then %let j=999;
           %local tmp1 tmp2;
           %let tmp1 = %sysfunc(tranwrd(%sysfunc(compbl(&trtvar &&ngrp&i  )), 
              %str( ), %str(,)));
           %let tmp2 = %sysfunc(tranwrd(%sysfunc(compbl(&trtvar &&ngrp&i &unit )),
                %str( ), %str(,)));
     %end;
      
      record =  "proc sql noprint;"; output;
      record =  "    create table __out as"; output;
      record =  "    select &tmp1,"; output;
      record =  "      count(*) as &cnt, &j as __grpid from "; output;
      record =  "    (select distinct "; output;
       record =  "      &tmp2"; output;  
/*        %if %length(&where) %then %do;  */
/*           record =  "    from  &datain (where=("; output; */
/*           record =  strip(symget("where")); output; */
/*           record = "  )))"; output; */
/*       %end; */
/*       %else %do; */
          record =  "    from  __tmpdatain)"; output;
      /* %end; */
      record =  "    group by &tmp1"; output;
      record =  "    order by &tmp1;"; output;
      record =  "quit;"; output;
      record = " "; output;
      record =  "data &dataout;"; output;
      record =  "  set &dataout __out;"; output;
      record =  "run;"; output;
      record = " "; output;
%end;

record =  "proc sql noprint;"; output;
record =  "  drop table __out;"; output;
record =  "quit;"; output;
record = " "; output;

%mend;

