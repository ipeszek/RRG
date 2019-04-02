/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __getcntaew(datain=, unit=, group=, cnt=, dataout=, 
                 trtvar=, var=, worstvar=, desc=, where=, total=N)/store;

%* creates a dataset with count of distinc &unit, grouped by &group;
%* provides count for each grouping variable as well if cntallgrpYN=Y;
%* note: unit is one variable;


%local datain unit group  cnt dataout  trtvar var worstvar desc where total;


%let datain = %unquote(&datain);

data _null_;
  length __wh $ 2000;
  __wh = strip(symget("where"));
file "&rrgpgmpath./&rrguri..sas" mod;
put;  
put @1 "data &dataout;";
put @1 "if 0;";
put @1 "run;";
put;
put @1 "data __out; if 0; run;";

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
     
%do i=1 %to &numgroups;
put;
put;  
put;  
put @1 "*-------------------------------------------------------------------;";
put @1 "* TAKE THE MAXIMUM &VAR;";
put @1 "*-------------------------------------------------------------------;";
put;
put @1 "proc sort data=&datain nodupkey;";
put @1 "  by &trtvar &&ngrp&i  &unit &desc &var;";
put @1 "run;";
put;
put @1 "data &datain;";
put @1 "  set &datain;";
put @1 "  by &trtvar &&ngrp&i &unit &desc &var;";
put @1 "  if last.%scan(&unit,-1, %str( ));";
put @1 "run;";
put;
put;

%if &total=N %then %do;
put @1 "*-------------------------------------------------------------------;";
put @1 "* COUNT NUMBER OF DISTINCT &UNIT IN EACH ";
put @1 "*   &trtvar &&ngrp&i &var COMBINATION;";
put @1 "*-------------------------------------------------------------------;";
put;
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
put @1 "*-------------------------------------------------------------------;";
put @1 "* COUNT NUMBER OF DISTINCT &UNIT IN EACH ";
put @1 "*   &trtvar &&ngrp&i  COMBINATION;";
put @1 "*-------------------------------------------------------------------;";
put;
   %local j;
   %let j = %eval(&numgroups-&i+1);
   %if &j = &numgroups %then %let j=999;
   %local tmp1 tmp2;
   %let tmp1 = %sysfunc(tranwrd(%sysfunc(compbl(&trtvar &&ngrp&i  )), 
      %str( ), %str(,)));
   %let tmp2 = %sysfunc(tranwrd(%sysfunc(compbl(&trtvar &&ngrp&i &unit )),
        %str( ), %str(,)));
%end;
      
put @1 "proc sql noprint;";
put @1 "    create table __out as";
put @1 "    select &tmp1,";
put @1 "      count(*) as &cnt, &j as __grpid from ";
put @1 "    (select distinct ";
put @1 "      &tmp2";
%if %length(&where) %then %do;
put @1 "    from  &datain (where=";
put @5 __wh;
put "  ))";
%end;
%else %do;
put @1 "    from  &datain)";
%end;
put @1 "    group by &tmp1";
put @1 "    order by &tmp1;";
put @1 "quit;";
put;
put @1 "data &dataout;";
put @1 "  set &dataout __out;";
put @1 "run;";
put;
%end;

put @1 "proc sql noprint;";
put @1 "  drop table __out;";
put @1 "quit;";
put;
run;
%mend;
;
