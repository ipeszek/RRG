/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro rrg_joinds(
      data1=, 
      data2=, 
         by=, 
       type=MERGE, 
    dataout=, 
       cond=, 
  mergetype=OUTER)/store;
  
/***************************************************************************** 
Purpose: A macro to merge or set two datasets

Author:  Iza Peszek, 30Sep2008

Parameters:
      data1 : first data set
      data2 : second dataset
         by : list of "by" variables
       type : SET|MERGE, type of join
    dataout : name of output dataset
       cond : additional subsetting condition applied after merge
  mergetype : INNER|OUTER, for merge, specifies whether INNER or FULL (OUTER) 
              join is applied. Default is OUTER
  
Modifications:

Notes:
  if type is not given then merge is used
  cond is additional subsetting condition (where) applied
    after merge
  mergetype = INNER keeps only matching records from both datasets
  mergetype = OUTER keeps all observations

*****************************************************************************/;

%local data1 data2 by type dataout cond mergetype;

%if %upcase(&type) ne MERGE %then %let type=SET;

%if %upcase(&type) = MERGE %then %do;

  %*-----------------------------------------------------------;
  %* sort and merge two datasets;
  %*-----------------------------------------------------------;

%local i dsid1 dsid2 rc1 rc2 notin1 notin2 tmp tmp1 oldby newby;
%let oldby=&by;

%let dsid1 = %sysfunc(open(&data1));
%let dsid2 = %sysfunc(open(&data2));
%do i=1 %to %sysfunc(countw(&oldby, %str( )));
   %let tmp = %scan(&oldby,&i, %str( ));
   %let v1=%sysfunc(varnum(&dsid1, &tmp));
   %let v2=%sysfunc(varnum(&dsid2, &tmp));
   %if &v1>0 and &v2>0 %then %let newby=&newby &tmp;
   %if &v1=0 and &v2>0 %then %let notin1=&notin1 &tmp;
   %if &v2=0 and &v1>0 %then %let notin2=&notin2 &tmp;
%end;

%let rc1=%sysfunc(close(&dsid1));
%let rc2=%sysfunc(close(&dsid2));

%if %length(&notin1)=0 and %length(&notin2)=0 %then %do;
  proc sort data=&data1 out=__d1;
    by &by;
  run;
  
  proc sort data=&data2 out=__d2;
    by &by;
  run;

%end;

%if %length(&notin1) and %length(&notin2) %then %do;
   proc sql noprint;
    create table __tmp as select distinct 
       %sysfunc(tranwrd(&notin1,%str( ), %str(,)))
    from &data2;
    create table __d1 as select * from __tmp
      cross join &data1;
    create table __tmp as select distinct 
       %sysfunc(tranwrd(&notin2,%str( ), %str(,)))
    from &data1;
    create table __d2 as select * from __tmp
      cross join &data2;
  quit;  

  proc sort data=__d1;
    by &by;
  run;

  proc sort data=__d2;
    by &by;
  run;
%end;

%if %length(&notin1) and %length(&notin2)=0 %then %do;
   proc sql noprint;
    create table __tmp as select distinct 
       %sysfunc(tranwrd(&notin1,%str( ), %str(,)))
    from &data2;
    create table __d1 as select * from __tmp
      cross join &data1;
  quit;  

  proc sort data=__d1;
    by &by;
  run;

  proc sort data=&data2 out=__d2;
    by &by;
  run;
%end;

%if %length(&notin1)=0 and %length(&notin2) %then %do;
   proc sql noprint;
    create table __tmp as select distinct 
       %sysfunc(tranwrd(&notin2,%str( ), %str(,)))
    from &data1;
    create table __d2 as select * from __tmp
      cross join &data2;
  quit;  

  proc sort data=__d2;
    by &by;
  run;

  proc sort data=&data1 out=__d1;
    by &by;
  run;
%end;



  data &dataout;
    merge __d1(in=__a) __d2 (in=__b);
    by  &by;
    
    %*---------------------------------------------------------;
    %* if INNER join, keep only records from both datasets;
    %*---------------------------------------------------------;
  
    %if %upcase(&mergetype)=INNER %then %do;
      if __a and __b;
    %end;
 
  
    %*---------------------------------------------------------;
    %* if &cond was given, apply it ;
    %*---------------------------------------------------------;
    %if %length(&cond) %then %do;
      if &cond;
    %end;
  run;
;

data __rrghd0;
  length record $ 2000;
%if %length(&notin1) and %length(&notin2) %then %do;
record= "proc sql noprint;"; output;
record= "  create table __tmp as select distinct ";output;
record= "       %sysfunc(tranwrd(&notin1,%str( ), %str(,)))";output;
record= "    from &data2;";output;
record= "  create table __d1 as select * from __tmp";output;
record= "      cross join &data1;";output;
record= "  create table __tmp as select distinct ";output;
record= "       %sysfunc(tranwrd(&notin2,%str( ), %str(,)))";output;
record= "    from &data1;";output;
record= "  create table __d2 as select * from __tmp";output;
record= "      cross join &data2;";output;
record= "  drop table __tmp;";output;
record= "quit;  ";output;
record= " ";output;
record= "proc sort data=__d1;";output;
record= "  by &by;";output;
record= "  run;";output;
record= " ";output;
record= "proc sort data=__d2;";output;
record= "  by &by;";output;
record= "  run;";output;
record= " ";output;
%end;
%if %length(&notin1) and %length(&notin2)=0  %then %do;
record= "proc sql noprint;";output;
record= "  create table __tmp as select distinct ";output;
record= "       %sysfunc(tranwrd(&notin1,%str( ), %str(,)))";output;
record= "    from &data2;";output;
record= "  create table __d1 as select * from __tmp";output;
record= "      cross join &data1;";output;
record= "  drop table __tmp;";output;
record= "quit;  ";output;
record= " ";output;
record= "proc sort data=__d1;";output;
record= "  by &by;";output;
record= "  run;";output;
record= " ";output;
record= "proc sort data=&data2 out=__d2;";output;
record= "  by &by;";output;
record= "  run;";output;
record= " ";output;
%end;
%if %length(&notin1)=0 and %length(&notin2)  %then %do;
record= "proc sql noprint;";output;
record= "  create table __tmp as select distinct ";output;
record= "       %sysfunc(tranwrd(&notin2,%str( ), %str(,)))";output;
record= "    from &data1;";output;
record= "  create table __d2 as select * from __tmp";output;
record= "      cross join &data2;";output;
record= "  drop table __tmp;";output;
record= "quit;  ";output;
record= " ";output;
record= "proc sort data=__d2;";output;
record= "  by &by;";output;
record= "  run;";output;
record= " ";output;
record= "proc sort data=&data1 out=__d1;";output;
record= "  by &by;";output;
record= "  run;";output;
record= " ";output;
%end;
%if %length(&notin1)=0 and %length(&notin2)=0  %then %do;

record= "proc sort data=&data1 out=__d1;";output;
record= "  by &by;";output;
record= "  run;";output;
record= " ";output;
record= "proc sort data=&data2 out =__d2;";output;
record= "  by &by;";output;
record= "  run;";output;
record= " ";output;
%end;
record= "  data &dataout;";output;
record= "    merge __d1(in=__a) __d2 (in=__b);";output;
record= "    by  &by;";output;
    
    %*---------------------------------------------------------;
    %* if INNER join, keep only records from both datasets;
    %*---------------------------------------------------------;
  
    %if %upcase(&mergetype)=INNER %then %do;
record= "      if __a and __b;"; output;
    %end;
  
    %*---------------------------------------------------------;
    %* if &cond was given, apply it ;
    %*---------------------------------------------------------;
    %if %length(&cond) %then %do;
record= "      if &cond;";output;
    %end;
record= "  run;";output;
record= " ";output;



  %*-----------------------------------------------------------;
  %* delete temporary datasets;
  %*-----------------------------------------------------------;

record= "proc sql noprint;";output;
record= "  drop table __d1;";output;
record= "  drop table __d2;";output;
record= "  quit;";output;
record= " ";output;
run;  
%end;

%else %do;

  %*-----------------------------------------------------------;
  %* set two datasets;
  %*-----------------------------------------------------------;

data &dataout;
set &data1 &data2;
    %if %length(&by) %then %do;
by &by;
    %end;
    
    %*---------------------------------------------------------;
    %* if &cond was given, apply it ;
    %*---------------------------------------------------------;
  
    %if %length(&cond) %then %do;
if &cond;
    %end;

run;

data __rrghd0;
length record $ 2000;
record= " ";output;
record= "  data &dataout;"; output;
record= "    set &data1 &data2;";output;
    %if %length(&by) %then %do;
record= "      by &by;";output;
    %end;
    
    %*---------------------------------------------------------;
    %* if &cond was given, apply it ;
    %*---------------------------------------------------------;
  
    %if %length(&cond) %then %do;
record= "        if &cond;";output;
    %end;

record= "  run;";output;
record= " ";output;
run;  
%end;


data __rrght;
  set  __rrght __rrghd0;
run;

data __usedds0;
  length ds $ 2000;
  ds = strip(symget("data1"));
  output;
  ds = strip(symget("data2"));
  output;
run;

data __usedds;
  set __usedds __usedds0;
run;


%mend ;
