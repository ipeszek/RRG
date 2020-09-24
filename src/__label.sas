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


data rrgpgmtmp;
length record $ 200;
keep record;
length label1 $ 2000;
set __labeld1;
label1 = quote(cats(dequote(label)));
record =  "*-------------------------------------------------------------;"; output;
record =  "*  CREATE ROW WITH DISPLAY OF " ||strip(LABEL1)||";"; output;
record =  "*-------------------------------------------------------------;"; output;
record = " "; output;
record = " "; output;
record =  "data &outds;"; output;
record =  "  length __col_0 __align $ 2000 __suffix  __vtype $ 20;"; output;
record =  "  __col_0 = " ||strip(label1)  ";"; output;
record =  "  __indentlev=&indent+&ngrpv;"; ; output;
record =  "  __suffix='';"; output;
%local tmp;
%if &skipline=Y %then %do;
    record =  "  __suffix='~-2n';"; output;
%end;
record =  "  __tmprowid=1;"; output;
record =  "  __blockid=&varid;"; output;
%if &keepwithnext=Y %then %do;
    record =  "  __keepn=1;"; output;
%end;
%else %do;
    record =  "  __keepn=0;"; output;
%end;
record =  "  __align = 'L '||repeat('L ',"|| '&maxtrt);' ; output;
record =  "  __tby=1;"; output;
record =  "  __labelline=0;"; output;
record =  "  __vtype='LABEL';"; output;
record =  "  __order=1;"; output;
record =  "  __grpid=999;"; output;
record =  "  __skipline=strip('"|| "&skipline"|| "');"; output;
record =  "  __wholerow=strip('"|| "&wholerow"|| "');"; output;
record =  "run;"; output;
record = " "; output;


%if %length(&by.&groupvars) %then %do;

    * IF GROUPING VARIABLES ARE SPECIFIED, CREATE LABEL RECORD FOR EACH
       COMBINATION OF GROUPING VARABLES IN &DSIN;
    record =  "*----------------------------------------------------------------;";    output;
    record =  "* CREATE LABEL RECORD FOR EACH COMBINATION OF GROUPING VARABLES;"; output;
    record =  "*----------------------------------------------------------------;"; output;
    record = " ";    output;
    record =  "data __labeld1;"; output;
    record =  "if 0;"; output;
    record =  "run;"; output;
    record = " "; output;
    %local tmp;
    %let tmp =  %sysfunc(tranwrd(%sysfunc(compbl(__tby &by &groupvars)) ,
       %str( ),%str(,)));
    record =  "proc sql noprint;"; output;
    record =  "create table __labeld1 as select distinct "; output;
    record =  "   &tmp"; output;
    record =  "   from &dsin"; output;
    record =  "   order by __tby;"; output;
    record =  "   quit;"; output;
    record = " "; output;
    record =  "   proc sort data=&outds;"; output;
    record =  "   by __tby;"; output;
    record =  "   run;"; output;
    record = " "; output;
    record =  "   data &outds;"; output;
    record =  "   merge __labeld1 &outds;"; output;
    record =  "   by __tby;"; output;
    record =  "   __grpid=999;"; output;
    record =  "   run;"; output;
    record = " "; output;
    record =  "proc sql noprint;"; output;
    record =  "drop table __labeld1;"; output;
    record =  "quit;"; output;
    record = " "; output;

%end;

run;


proc append data=rrgpgmtmp base=rrgpgm;
run;


%mend;

