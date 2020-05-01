/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __getcntg(datain=, unit=, group=, cnt=, dataout=)/store;

%* creates a dataset with count of distinc &unit, grouped by &group;
%* note: unit is one variable;


%local datain unit group  cnt dataout var trtvar ;

%let datain = %unquote(&datain);


data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
length __datain $ 2000;
put @1 "data &dataout;";
put @1 "  if 0;";
put @1 "run;";


%if %length(&group) %then %do;
%local tmp1 tmp2 ;
%let tmp1 = %sysfunc(tranwrd(%sysfunc(compbl(&group)), %str( ), %str(,)));
%let tmp2 = %sysfunc(tranwrd(%sysfunc(compbl(&group &unit)), 
   %str( ), %str(,))) ;
put;
put @1 "*------------------------------------------------------;";
PUT @1 "* COUNT NUM of DISTINCT &UNIT IN EACH &TMP1 COMBINATION;";
put @1 "*------------------------------------------------------;";

put @1 "  proc sql noprint;";
put @1 "    create table &dataout as";
put @1 "    select &tmp1, count(*) as &cnt, 999 as __grpid from ";
__datain = cats(symget("datain"));
put @1 "    (select distinct &tmp2 from  " __datain ")";
put @1 "    group by &tmp1";
put @1 "    order by &tmp1;";
put @1 "  quit;";
%end;
%else %do;
%local tmp3;
%let tmp3 = %sysfunc(tranwrd(%sysfunc(compbl( &unit)), %str( ), %str(,))) ;
put @1 "*---------------------------------------------------------------;";
PUT @1 "* COUNT DISTINCT &UNIT.S ;";
put @1 "*---------------------------------------------------------------;";
__datain = cats(symget("datain"));
put @1 "  proc sql noprint;";
put @1 "    create table &dataout as";
put @1 "    select count(*) as &cnt, 999 as __grpid from ";
put @1 "    (select distinct &tmp3) from  " __datain ");";
put @1 "  quit;";
%end;
put;


run;

%mend;
