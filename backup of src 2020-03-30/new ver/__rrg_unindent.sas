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

  
data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put;
put @1 "*---------------------------------------------------------------------;";
put @1 "*  PULL REQUESTED GROUPING VARIABLES INTO COLUMNS;";
put @1 "*---------------------------------------------------------------------;";
put;
put '%local nmt;';
put;
put @1 "  data &dataset;";
put @1 "    set &dataset;";
put @1 "    length " %do i=0 %to &indentlev; " __newcol&i " %end; " $ 2000;";
put @1 "    retain " %do i=0 %to &indentlev; " __newcol&i " %end; ";";
put @1 "    if 0 then do; ";
put @1 "      __indentlev=0;";
put @1 "     __fordelete=.;";
%do i=0 %to &indentlev; 
put @1 "       __col_&i = ''; ";
%end; 
put @1 "    end;";
put @1 "    __oldind=lag(__indentlev);";
put @1 "    if __datatype='TBODY' then do;";
%do i=0 %to &indentlev;
put @1 "      if __indentlev=&i then  do;";
put @1 "         __newcol&i=cats(__col_0); ";
%do j=%eval(&i+1) %to &indentlev;
put @1 "         __newcol&j='';";
%end;
put @1 "      end;";
%end;
put @1 "      if __indentlev <=&indentlev  then __fordelete=1;";
put @1 "    end;";
put @1 "    if _n_=1 then do;";
put @1 "      array cols {*} __col_:;";
put @1 "      call symput('nmt', cats(dim(cols)-1));";
put @1 "    end; ";
put @1 "    if __datatype='RINFO' then __lastcheadid=__lastcheadid+&indentlev+1;";
put @1 "  run;";
put;    
put;
put @1 '%local lastrow;';
put @1 "proc sql noprint;";
put @1 "  select max(__rowid) into:lastrow separated by ' '";
put @1 "    from &dataset(where=(__datatype='HEAD'));";
put @1 "    quit;";
put;    
put;
%local rename2;
%let rename2=;
%do i=0 %to &indentlev;
%let rename2 = &rename2 __newcol&i=__col_&i;
%end;


put '%if &nmt>0 %then %do;';
put;
put @1 '  %local rename1 rename2 j i ;';
put @1 '  %let rename2 = ' "&rename2 ;";
put @1 '  %let rename1 = ;';
put @1 '  %do i=0 %to &nmt;';
put @1 '    %let j = %eval(&i+' "&indentlev+1);";
put @1 '    %let rename1=&rename1 __col_&i = __ncol_&j;';
put @1 '    %let rename2=&rename2 __ncol_&j = __col_&j;';
put @1 '  %end;';
put;      
put @1 "  data &dataset " '(rename=(&rename2));';
put @1 "    set &dataset " '(rename=(&rename1));';
put @1 "    if __align = '' then __align = 'L';";
put @1 "    if __stretch = '' then __stretch = 'Y';";
put @1 "    if __fordelete=1 then delete; ";
%if &indentlev=0 %then %do;
put @1 "    __align = 'L '||cats(__align);";
put @1 "    __stretch = 'Y '||cats(__stretch);";
%end;
%else %do;
put @1 "    __align = repeat('L ', &indentlev)||cats(__align);";
put @1 "    __stretch = repeat('Y ', &indentlev)||cats(__stretch);";
%end;
put @1 '    if __datatype="HEAD" and __rowid=&lastrow  then do;';
%local j;
%do i=0 %to &indentlev;
%let j = %eval(&indentlev+1);
put @1 "    __newcol&i = scan(cats(__ncol_&j), %eval(&i+1), '!');";
%end;
put @1 "    __ncol_&j = scan(cats(__ncol_&j), %eval(&indentlev+2), '!');";
put @1 "    end; ";
put @1 "    if __datatype='TBODY' then do;";

%* add indentation level to column;
put @1 "      if __indentlev-&indentlev-1>0 then ";
put @1 "        __ncol_%eval(&indentlev+1) = ";
put @1 "           cats('/i', __indentlev-&indentlev-1)||' '|| __ncol_%eval(&indentlev+1);";
%do i=0 %to &indentlev;
put @1 "    __ncol_&i = cats(__newcol&i);";
%end;
put @1 "    end; ";
put @1 "  run;   ";
put;
put @1 "  data &dataset ;";
put @1 "    set &dataset ;";
put @1 "    if 0 then __i = .;";
put @1 "    drop __i ;";
put @1 "   if __datatype='RINFO' then do;";
put @1 "    __rtype='LISTING';";
put @1 "    __gcols = compbl('" %do i=0 %to &indentlev; " &i " %end; "');";
/*
put @1 '    __tmp = &nmt ' "+2+&indentlev - countw(__colwidths,' ');";
put @1 '    do __i=1 to __tmp;';
put @1 "      __colwidths = 'LW '||cats(__colwidths);";
put @1 '    end;';
put @1 '    __tmp = &nmt ' "+2+&indentlev -countw(__stretch, ' ');";
put @1 '    do __i=1 to __tmp;';
put @1 "      __stretch = 'Y '||cats(__stretch);";
put @1 '    end;';
*/
put @1 "  end;";

%do i=0 %to &indentlev;
put @1 "    __tmpval = lag(__col_&i);";
put @1 "    __first_&i = 1;";
%if &i=0 %then %do;
put @1 "    if __datatype='TBODY' and __rowid>1 and __tmpval = __col_&i then __first_&i=.;";
%end;
%else %do;
put @1 "    if __datatype='TBODY' and __rowid>1 and __tmpval = __col_&i ";
put @1 "        and __first_%eval(&i-1) =. then __first_&i=.;";
%end;
%end;

put @1 "    __indentlev=0;";
put @1 "    drop __oldind " %do i=0 %to &indentlev; " __ncol_&i " %end;";";
put @1 " run;";
put;
put @1 '%end;';
put;
put;
put;
put;
put;
run;  
%mend;  
