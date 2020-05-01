/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __label(
outds=,
varid=,
groupvars=,
by=,
indentbase=,
dsin=)/store;

/*---------------------------------------------------------------------------
author: Iza Peszek, 11 June 2008

Purpose: Create a record for printing a "label" in a table.
  this macro creates a dataset &outds with variable __col_0. 
  If &groupvars are not blank, then the dataset will 
     have all distinct combination of values of &groupvars variables,
     as encountered in &dsin.
     Additionally, the following variables are created in &outds:
       __align (defines a string of alignments for all columns)
       __suffix (indicates skipline)
       __keepn=1 (indicates that this record should appear on the same page as
                   next record
       __indentlev (indicates number of indentation levels)
       __vtype="LABEL"
     and the followign variables,(which parent macro expects to find in &outds)
       __labelline=0 
       __order=1
       __tmprowid=1
       __blockid=&varid
       __tby=1
       
       
NOTE: macro parameter indentbase is never used       
----------------------------------------------------------------------------*/

%local outds indent skipline groupvars indentbase lbl varid dsin by
       wholerow keepwithnext;

data __labeld1;
set __varinfo (where=(varid=&varid));
run;
%let indent=0;

* DETERMINE WHAT LABEL TO PRINT, WHAT IS INDENTATION LEVEL, ;
*  AND WHETHER TO PRINT  SKIPLINE AFTEWARDS;

proc sql noprint;
  select indent            into:indent   separated by ' ' from __labeld1;
  select upcase(skipline)  into:skipline separated by ' ' from __labeld1;
  select dequote(label)    into:lbl      separated by ' ' from __labeld1;
  select wholerow          into:wholerow separated by ' ' from __labeld1;
  select upcase(keepwithnext)
         into:keepwithnext separated by ' ' from __labeld1;
quit;

%local ngrpv;
%let ngrpv=0;
%if %length(&groupvars) %then %do;
  %let ngrpv = %sysfunc(countw(&groupvars, %str( )));
%end;

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
length label1 $ 20000;
%*__label = symget("lbl");
%* symget did not want to work here...;
set __labeld1;
label1 = quote(cats(dequote(label)));
put @1 "*-------------------------------------------------------------;";
put @1 "*  CREATE ROW WITH DISPLAY OF " LABEL1;
put @1 "*-------------------------------------------------------------;";
put;
put;
put @1 "data &outds;";
put @1 "  length __col_0 __align $ 2000 __suffix  __vtype $ 20;";
put @1 "  __col_0 = " label1  ";";
put @1 "  __indentlev=&indent+&ngrpv;"; ** 2009-07-08;
put @1 "  __suffix='';";
%local tmp;
%if &skipline=Y %then %do;
put @1 "  __suffix='~-2n';";
%end;
put @1 "  __tmprowid=1;";
put @1 "  __blockid=&varid;";
%if &keepwithnext=Y %then %do;
  put @1 "  __keepn=1;";
%end;
%else %do;
  put @1 "  __keepn=0;";
%end;
put @1 "  __align = 'L '||repeat('L '," '&maxtrt);' ;
put @1 "  __tby=1;";
put @1 "  __labelline=0;";
put @1 "  __vtype='LABEL';";
put @1 "  __order=1;";
put @1 "  __grpid=999;";
put @1 "  __skipline=strip('" "&skipline" "');";
put @1 "  __wholerow=strip('" "&wholerow" "');";
put @1 "run;";
put;


%if %length(&by.&groupvars) %then %do;

* IF GROUPING VARIABLES ARE SPECIFIED, CREATE LABEL RECORD FOR EACH
   COMBINATION OF GROUPING VARABLES IN &DSIN;
put @1 "*----------------------------------------------------------------;";   
put @1 "* CREATE LABEL RECORD FOR EACH COMBINATION OF GROUPING VARABLES;";
put @1 "*----------------------------------------------------------------;";
put;   
put @1 "data __labeld1;";
put @1 "if 0;";
put @1 "run;";
put;
%local tmp;
%let tmp =  %sysfunc(tranwrd(%sysfunc(compbl(__tby &by &groupvars)) ,
   %str( ),%str(,)));
put @1 "proc sql noprint;";
put @1 "create table __labeld1 as select distinct ";
put @1 "   &tmp";
put @1 "   from &dsin";
put @1 "   order by __tby;";
put @1 "   quit;";
put;
put @1 "   proc sort data=&outds;";
put @1 "   by __tby;";
put @1 "   run;";
put;
put @1 "   data &outds;";
put @1 "   merge __labeld1 &outds;";
put @1 "   by __tby;";
put @1 "   __grpid=999;";
put @1 "   run;";
put;
put @1 "proc sql noprint;";
put @1 "drop table __labeld1;";
put @1 "quit;";
put;
run;
%end;
%mend;

