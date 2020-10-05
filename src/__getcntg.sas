
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
%let datain = %sysfunc( tranwrd( %str(&datain),%str(%"), %str(%') ) );
length __datain $ 2000;
__datain = "&datain";


record = "data &dataout;";                                                                      output;
record = "  if 0;";                                                                             output;
record = "run;";                                                                                output;


%if %length(&group) %then %do;
    %local tmp1 tmp2 ;
    %let tmp1 = %sysfunc(tranwrd(%sysfunc(compbl(&group)), %str( ), %str(,)));
    %let tmp2 = %sysfunc(tranwrd(%sysfunc(compbl(&group &unit)), 
       %str( ), %str(,))) ;
 
    record=" ";                                                                                 output;
    record = "*------------------------------------------------------;";                        output;
    record = "* COUNT NUM of DISTINCT &UNIT IN EACH &TMP1 COMBINATION;";                        output;
    record = "*------------------------------------------------------;";                        output;
    record = "  proc sql noprint;";                                                             output;
    record = "    create table &dataout as";                                                    output;
    record = "    select &tmp1, count(*) as &cnt, 999 as __grpid from ";                        output;
    record = "    (select distinct &tmp2 from " ;                                               output;
    record =      __datain;                                                                     output;
    record = "     )";                                                                          output;
    record = "    group by &tmp1";                                                              output;
    record = "    order by &tmp1;";                                                             output;
    record = "  quit;";                                                                         output;
%end;
%else %do;
    %local tmp3;
    %let tmp3 = %sysfunc(tranwrd(%sysfunc(compbl( &unit)), %str( ), %str(,))) ;
    record = "*---------------------------------------------------------------;";               output;
    record = "* COUNT DISTINCT &UNIT.S ;";                                                      output;
    record = "*---------------------------------------------------------------;";               output;
    record = "  proc sql noprint;";                                                             output;
    record = "    create table &dataout as";                                                    output;
    record = "    select count(*) as &cnt, 999 as __grpid from ";                               output;
    record = "    (select distinct &tmp3 from " ;                                               output;
    record =  __datain;                                                                         output;
    record = "   )";                                                                               output;
    record = "  quit;";                                                                         output;
%end;








%mend;
