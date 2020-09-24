/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __rrg_unindent(indentlev=0)/store;
  
  %local dataset stretch width indentlev i j;
  %let dataset=&rrguri;

  

data rrgpgmtmp;
length record $ 200;
keep record;
record = " "; output;
record = " "; output;
record =  "*---------------------------------------------------------------------;"; output;
record =  "*  PULL REQUESTED GROUPING VARIABLES INTO COLUMNS;"; output;
record =  "*---------------------------------------------------------------------;"; output;
record = " "; output;
record = '%local nmt;'; output;
record = " "; output;
record =  "  data &dataset;"; output;
record =  "    set &dataset;"; output;
record =  "    length " %do i=0 %to &indentlev; " __newcol&i " %end; " $ 2000;"; output;
record =  "    retain " %do i=0 %to &indentlev; " __newcol&i " %end; ";"; output;
record =  "    if 0 then do; "; output;
record =  "      __indentlev=0;"; output;
record =  "    __fordelete=.;"; output;
%do i=0 %to &indentlev; 
    record =  "       __col_&i = ''; "; output;
%end; 
record =  "    end;"; output;
record =  "    __oldind=lag(__indentlev);"; output;
record =  "    if __datatype='TBODY' then do;"; output;
%do i=0 %to &indentlev;
    record =  "      if __indentlev=&i then  do;"; output;
    record =  "         __newcol&i=cats(__col_0); "; output;
    %do j=%eval(&i+1) %to &indentlev; 
        record =  "         __newcol&j='';"; output;
    %end;
    record =  "      end;"; output;
%end;
record =  "      if __indentlev <=&indentlev  then __fordelete=1;"; output;
record =  "    end;"; output; output;
record =  "    if _n_=1 then do;";
record =  "      array cols {*} __col_:;"; output;
record =  "      call symput('nmt', cats(dim(cols)-1));"; output;
record =  "    end; "; output;
record =  "    if __datatype='RINFO' then __lastcheadid=__lastcheadid+&indentlev+1;"; output;
record =  "  run;"; output;
record = " ";     output;
record = " "; output;
record =  '%local lastrow;'; output;
record =  "proc sql noprint;"; output;
record =  "  select max(__rowid) into:lastrow separated by ' '"; output;
record =  "    from &dataset(where=(__datatype='HEAD'));"; output;
record =  "    quit;"; output;
record = " ";     output;
record = " "; output;

%local rename2;
%let rename2=;
%do i=0 %to &indentlev;
%let rename2 = &rename2 __newcol&i=__col_&i;
%end;


record = '%if &nmt>0 %then %do;'; output;
record = " "; output;
record =  '  %local rename1 rename2 j i ;'; output;
record =  '  %let rename2 = '||strip("&rename2")||";";  output;
record =  '  %let rename1 = ;'; output;
record =  '  %do i=0 %to &nmt;'; output;
record =  '    %let j = %eval(&i+'|| "&indentlev+1);"; output;
record =  '    %let rename1=&rename1 __col_&i = __ncol_&j;'; output;
record =  '    %let rename2=&rename2 __ncol_&j = __col_&j;'; output;
record =  '  %end;'; output;
record = " ";       output;
record =  "  data &dataset "|| '(rename=(&rename2));'; output;
record =  "    set &dataset "|| '(rename=(&rename1));'; output;
record =  "    if 0 then __fordelete=.;"; output;
record =  "    if __align = '' then __align = 'L';"; output;
record =  "    if __stretch = '' then __stretch = 'Y';"; output;
record =  "    if __fordelete=1 then delete; "; output;
%if &indentlev=0 %then %do;
    record =  "    __align = 'L '||cats(__align);"; output;
    record =  "    __stretch = 'Y '||cats(__stretch);"; output;
%end;
%else %do;
    record =  "    __align = repeat('L ', &indentlev)||cats(__align);"; output;
    record =  "    __stretch = repeat('Y ', &indentlev)||cats(__stretch);"; output;
%end;
record =  '    if __datatype="HEAD" and __rowid=&lastrow  then do;'; output;
%local j;
%do i=0 %to &indentlev;
    %let j = %eval(&indentlev+1); output;
    record =  "    __newcol&i = scan(cats(__ncol_&j), %eval(&i+1), '!');"; output;
%end;
record =  "    __ncol_&j = scan(cats(__ncol_&j), %eval(&indentlev+2), '!');"; output;
record =  "    end; "; output;
record =  "    if __datatype='TBODY' then do;"; output;

%* add indentation level to column;
record =  "      if __indentlev-&indentlev-1>0 then "; output;
record =  "        __ncol_%eval(&indentlev+1) = "; output;
record =  "           cats('/i', __indentlev-&indentlev-1)||' '|| __ncol_%eval(&indentlev+1);"; output;
%do i=0 %to &indentlev;
  record =  "    __ncol_&i = cats(__newcol&i);"; output;
%end;
record =  "    end; "; output; output;
record =  "  run;   "; output;
record = " "; output;
record =  "  data &dataset ;"; output;
record =  "    set &dataset ;"; output;
record =  "    if 0 then __i = .;"; output;
record =  "    drop __i ;"; output;
record =  "   if __datatype='RINFO' then do;"; output;
record =  "    __rtype='LISTING';"; output;
record =  "    __gcols = compbl('" %do i=0 %to &indentlev; " &i " %end; "');"; output;
record =  "  end;"; output;

%do i=0 %to &indentlev;
    record =  "    __tmpval = lag(__col_&i);"; output;
    record =  "    __first_&i = 1;"; output;
    %if &i=0 %then %do;
        record =  "    if __datatype='TBODY' and __rowid>1 and __tmpval = __col_&i then __first_&i=.;"; output;
    %end;
    %else %do;
        record =  "    if __datatype='TBODY' and __rowid>1 and __tmpval = __col_&i "; output;
        record =  "        and __first_%eval(&i-1) =. then __first_&i=.;"; output;
    %end;
%end;

record =  "    __indentlev=0;"; output;
record =  "    drop __oldind  %do i=0 %to &indentlev;  __ncol_&i  %end;;"; output;
record =  " run;"; output;
record = " "; output;
record =  '%end;'; output;
record = " "; output;
record = " "; output;
run;  


proc append data=rrgpgmtmp base=rrgpgm;
run;

%mend;  
