/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __rrg_unindentv/store;
  
  %local dataset stretch width ;
  %let dataset=&rrguri;

  

data rrgpgmtmp;
length record $ 2000;
keep record;
record = " "; output;
record = " ";output;
record =  "*---------------------------------------------------------------------;";output;
record =  "*  DETERMINE LARGES INDENT LEVEL- THIS WILL BE PULLED ;";output;
record =  "*     INTO SEPARATE COLUMN;";output;
record =  "*---------------------------------------------------------------------;";output;
record = " ";output;
record =  '%local nmt incv dsid rc nv;';output;
record = " ";output;
record = " ";output;
record =  '%let dsid=%sysfunc(open(__fall));';output;
record =  '%let nv = %sysfunc(varnum(&dsid,__indentlev));';output;
record =  '%let rc = %sysfunc(close(&dsid));';output;
record =  '%let incv = 0;';output;
record = " ";output;
record =  '%if &nv<=0 %then %goto skipunindent;';output;
record = " ";output;
record =  "proc sql noprint;";output;
record =  "select max(__indentlev) into:incv separated by '' from __fall (where =(__indentlev>=0));";output;
record =  "quit;";output;
record = " ";output;
record = '%if %length(&incv) <=0 %then %let incv=0;';output;

record =  "*---------------------------------------------------------------------;";output;
record =  "*  PULL REQUESTED STATISTICS VARIABLES INTO 2ND COLUMN;";output;
record =  "*---------------------------------------------------------------------;";output;
record = " ";output;
record = " ";output;
record =  "  data &dataset;";output;
record =  "    set &dataset;";output;
record =  "    length __newcol0 $ 2000 ;";output;
record =  "    retain __newcol0 __newind;";output;
record =  "    if 0 then __fordelete=.;";output;
record =  "    if _n_=1 then do;";output;
record =  "      array cols {*} __col_:;";output;
record =  "      call symput('nmt', cats(dim(cols)-1));";output;
record =  "    end; ";output;
record =  "    if __datatype='TBODY' then do;";output;
record =  '      if __indentlev<&incv then  do;';output;
record =  "        __newcol0=cats(__col_0); ";output;
record =  "        __newind=__indentlev; ";output;
record =  ' %if %length(&incv) %then %do;';output;
record =  '        if __indentlev = &incv-1 then __fordelete=1;';output;
record =  "        else do; do __i=1 to dim(cols); cols[__i]=''; end; end;";output;
record =  ' %end;';output;
record =  ' %else %do;';output;
record =  "   do __i=1 to dim(cols); cols[__i]=''; end; end;";output;
record =  ' %end;';output;
record =  "      end;";output;
record =  "    end;";output;
record =  "    if __datatype='RINFO' then __lastcheadid=__lastcheadid+1;";output;
record =  "  run;";output;
record = " ";    output;
record = " ";output;
record =  '%local lastrow;';output;
record =  "proc sql noprint;";output;
record =  "  select max(__rowid) into:lastrow separated by ' '";output;
record =  "    from &dataset(where=(__datatype='HEAD'));";output;
record =  "    quit;";output;
record = " ";    output;
record = " ";output;
%local rename2;
%let rename2 = __newcol0=__col_0;



record = '%if &nmt>0 %then %do;';output;
record = " ";output;
record =  '  %local rename1 rename2 j i ;';output;
record =  '  %let rename2 = '|| "&rename2 ;";output;
record =  '  %let rename1 =  ;';output;
record =  '  %do i=0 %to &nmt;';output;
record =  '    %let j = %eval(&i+1);';output;
record =  '    %let rename1=&rename1 __col_&i = __ncol_&j;';output;
record =  '    %let rename2=&rename2 __ncol_&j = __col_&j;';output;
record =  '  %end;';output;
record = " ";      output;
record =  "  data &dataset " ||'(rename=(&rename2));';output;
record =  "    set &dataset "|| '(rename=(&rename1));';output;
record =  "    if 0 then __fordelete=.;";output;
record =  "    if __fordelete=1 then delete; ";output;
record =  "    __align = 'L '||cats(__align);";output;
record =  "    __stretch = 'Y '||cats(__stretch);";output;
record =  '    if __datatype="HEAD" and __rowid=&lastrow  then do;';output;
record =  "    __newcol0 = scan(cats(__ncol_1),1, '!');";output;
record =  "    __ncol_1 = scan(cats(__ncol_1), 2, '!');";output;
record =  "    end; ";output;
record =  "    __indentlev=__newind;";output;
record =  "  run;   ";output;
record = " ";output;
record =  "  data &dataset ;";output;
record =  "    set &dataset ;";output;
record =  "   __oldcol=lag(__col_0);";output;
record =  "  if __datatype='TBODY' and __rowid>1 and __col_0=__oldcol then do;";output;
record =  "    __col_0='';";output;
record =  '    __indentlev=&incv;';output;
record =  "  end;";output;
record =  "  drop  __newind __oldcol ;";output;
record =  " run;";output;
record = " ";output;
record =  '%end;';output;
record = " ";output;
record =  '%skipunindent:';output;
record = " ";output;

run;  


proc append data=rrgpgmtmp base=rrgpgm;
run;

%mend;  
