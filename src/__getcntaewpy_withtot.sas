/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */
 
 /* this is based on __getscountaew macro, adding calculation of patient-year variable



 */

%macro __getcntaewpy_withtot(datain=, unit=, group=,  cnt=, dataout=, 
                 trtvar=, var=, where=                               )/store;


%* creates a dataset with count of distinc &unit, grouped by &group;
%* provides count for each grouping variable as well if cntallgrpYN=Y;
%* note: unit is one variable;


%local datain unit group  cnt dataout  trtvar var    unit4sql;

%let unit=%sysfunc(compbl(&unit));
%let unit4sql = %sysfunc(tranwrd(&unit, %str( ), %str(, )));
%let datain = %unquote(&datain);
%if &where=  %then %let where=1;


%local group4sql ;  
%let group4sql=%sysfunc(tranwrd(%sysfunc(compbl( &trtvar  &group &var)),   %str( ), %str(,)));  
 

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

%* for example if  group=hlt llt soc then ngrp1=hlt llt soc, ngrp2=hlt llt, ngrp3=hlt;    



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
 
    record = " "; output;
    record =  "proc sort data=&datain nodupkey out=__tmpdsin;"; output;
    record =  "where " ||strip(symget("where"))||";"; output;
    record =  "  by &trtvar &&ngrp&i  &unit    __days2firstevent;"; output;
    record =  "run;"; output;
    record = " "; output;
    record =  "data __tmpdsin;"; output;
    record =  "  set __tmpdsin;"; output;
    record =  "  by &trtvar &&ngrp&i &unit   __days2firstevent;"; output;
    record =  "  if first.%scan(&unit,-1, %str( ));"; output;
    record =  "run;"; output;
    record = " "; output;
    record = " "; output;


    record =  "proc sql;                                                                                           "; output;  
    record =  "  create table __dummy as select * from                                                             "; output;  
    record =  "  (select distinct %sysfunc(tranwrd(%sysfunc(compbl(&trtvar &unit __patdays)), %str( ), %str(, )))   "; output;  
    record =  "  from __dataset  )                                                                                  "; output;  
    record =  "  cross join                                                                                         "; output;  
    record =  "  (select distinct %sysfunc(tranwrd(%sysfunc(compbl(&&ngrp&i)), %str( ), %str(, )))               "; output;  
    record =  "  from __tmpdsin  )                                                                                  "; output;  
    record =  "  order by %sysfunc(tranwrd(%sysfunc(compbl(&trtvar &&ngrp&i  &unit)), %str( ), %str(, )));                   "; output;  
    record =  "quit;                                                                                               "; output;  
    record =  "                                                                                                    "; output;  
    record =  "data __tmpdsin;                                                                                         "; output;  
    record =  "  merge __tmpdsin (in=a) __dummy;                                                                       "; output;  
    record =  "  by &trtvar &&ngrp&i  &unit;                                                                                 "; output;  
    record =  "  if not a then __days2firstevent=__patdays;                                                        "; output;  
    record =  "  if  a then __countit=1;                                                                           "; output;  
    record =  "run;                                                                                                "; output;  
    record = " "; output;


        record =  "*-------------------------------------------------------------------;"; output;
        record =  "* COUNT NUMBER OF DISTINCT &UNIT IN EACH "; output;
        %if &where ne 1 %then %do;
        record =  "*   &trtvar &&ngrp&i  COMBINATION where &where;"; output;
        %end;
        %else %do;
         record =  "*   &trtvar &&ngrp&i  COMBINATION ;"; output; 
        %end;
        record =  "*-------------------------------------------------------------------;"; output;
        record = " "; output;
           %local j;
           %let j = %eval(&numgroups-&i+1);
           %if &j = &numgroups %then %let j=999;
           %local tmp1 tmp2;
           %let tmp1 = %sysfunc(tranwrd(%sysfunc(compbl(&trtvar &&ngrp&i   __days2firstevent)), 
              %str( ), %str(,)));
           %let tmp2 = %sysfunc(tranwrd(%sysfunc(compbl(&trtvar &&ngrp&i &unit  __days2firstevent __countit)),
                %str( ), %str(,)));
   
      
      record =  "proc sql noprint;"; output;
      record =  "    create table __out as"; output;
      record =  "    select &tmp1,"; output;
      record =  "      sum(__countit) as &cnt, sum(__days2firstevent) as __sumpy, &j as __grpid from "; output;
      record =  "    (select distinct "; output;
      record =  "      &tmp2"; output;
      record =  "    from  __tmpdsin)"; output;
      
      record =  "    group by &tmp1"; output;
      record =  "    order by &tmp1;"; output;
      record =  "quit;"; output;
      record = " "; output;
      
      
      
      record =  "data &dataout;"; output;
      record =  "  set &dataout __out;"; output;
      record =  "run;"; output;
      record = " "; output;
%end;

    record =  "data &dataout;                                          "; output;
    record =  "  set &dataout;                                         "; output;
    record =  "  if __sumpy ne . then   __py=(__sumpy)/365.25 ;        "; output;
    record =  "    if &cnt=. then &cnt=0;                              "; output;    
    record =  "    if __py >0 then __pyr = &multiplier*&cnt/__py;                                  "; output;
    record =  "  run;                                                  "; output;


record =  "proc sql noprint;"; output;
record =  "  drop table __out,  __tmpdsin,  __dummy;"; output;
record =  "quit;"; output;
record = " "; output;

%mend;

