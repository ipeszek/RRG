/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro rrg_unindent(colhead2 =, stretch=y, width=N, indentlev=0)/store;
  
  %local dataset colhead2 stretch width indentlev;
  %let dataset=&rrguri;
  
data _null_;
file "&rrgpgmpath.\&rrguri..sas" mod;
put;
put;

put @1 '%macro __tmp;';
put;
put '%local nmt;';
put;
put @1 "  data &dataset;";
put @1 "    set &dataset;";
put @1 "    length __newcol0 $ 2000;";
put @1 "    retain __newcol0;";
put @1 "    if __datatype='TBODY' and __indentlev<=&indentlev then do;";
put @1 "       __newcol0=cats(__col_0);";
put @1 "       if __indentlev=&indentlev  then __fordelete=1;";
put @1 "    end;";
put @1 "    if _n_=1 then do;";
put @1 "      array cols {*} __col_:;";
put @1 "      call symput('nmt', cats(dim(cols)-1));";
put @1 "    end; ";
put @1 "    if __datatype='RINFO' then __lastcheadid=__lastcheadid+1;";
put @1 "  run;";
put;    
put;
put '%if &nmt>0 %then %do;';
put;
put @1 '  %local rename1 rename2 j i ;';
put @1 '  %let rename1 = ;';
put @1 '  %let rename2 = %str(__newcol0=__col_0);';
put @1 '  %do i=0 %to &nmt;';
put @1 '    %let j = %eval(&i+1);';
put @1 '    %let rename1=&rename1 __col_&i = __ncol_&j;';
put @1 '    %let rename2=&rename2 __ncol_&j = __col_&j;';
put @1 '  %end;';
put;      
put @1 "  data &dataset " '(rename=(&rename2));';
put @1 "    set &dataset " '(rename=(&rename1));';
put @1 "    if __fordelete=1 then delete; ";
put @1 "    __align = 'L '||cats(__align);";
put @1 "    __colwidths = '" "&width" "'||' '||cats(__colwidths);";
put @1 "    __stretch = '" "&stretch" "'||' '||cats(__stretch);";
put @1 "    if __datatype='HEAD' and __ncol_1 ne '' then do;";
put @1 "    __newcol0 = cats(__ncol_1);";
put @1 "    __ncol_1 = cats('" "&colhead2" "');";
put @1 "    end; ";
put @1 "    if __datatype='TBODY' then do;";
put @1 "    __ncol_0 = cats(__newcol0);";
put @1 "    if __indentlev<&indentlev  then __ncol_1='';";
put @1 "    __indentlev = max(0, __indentlev-1);";
put @1 "    end; ";
put @1 "  run;   ";
put;
put @1 "  data &dataset ;";
put @1 "    set &dataset ;";
put @1 "    __tmpval = lag(__col_0);";
put @1 "    if __datatype='TBODY' and __rowid>1 and __tmpval = __col_0 then __col_0='';";
put @1 "    drop __ncol_0;";
put @1 " run;";
put;
put @1 '%end;';
put;
put;
put @1 '%mend;';
put;
put @1 '%__tmp;';
put;
put;
put;
run;  
%mend;  
