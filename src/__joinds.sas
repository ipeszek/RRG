/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __joinds(
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

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put @1 "proc sort data=&data1 out=__d1 ;";
put @1 "  by &by;";
put @1 "run;";

put @1 "proc sort data=&data2 out=__d2;";
put @1 "  by &by;";
put @1 "run;";
  
put @1 "data &dataout;";
put @1 "    merge __d1(in=__a) __d2 (in=__b);";
put @1 "by  &by;";
    %*---------------------------------------------------------;
    %* if INNER join, keep only records from both datasets;
    %*---------------------------------------------------------;
  
    %if %upcase(&mergetype)=INNER %then %do;
put @1 "if __a and __b;";
    %end;
    %else %if %upcase(&mergetype)=%str(LEFT) %then %do;
put @1 "if __a ;";
    %end;
    %else %if %upcase(&mergetype)=%str(RIGHT) %then %do;
put @1 "if __b;";
    %end;

put @1 "run;";

  
%end;

%else %do;

  %*-----------------------------------------------------------;
  %* set two datasets;
  %*-----------------------------------------------------------;

put @1 "data &dataout;";
put @1 "  set __d1 __d2;";
    %if %length(&by) %then %do;
put @1 "  by &by;";
    %end;
put @1 "run;";
  
%end;
run;

%mend ;

  
