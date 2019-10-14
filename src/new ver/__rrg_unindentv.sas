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

  
data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put;
put @1 "*---------------------------------------------------------------------;";
put @1 "*  DETERMINE LARGES INDENT LEVEL- THIS WILL BE PULLED ;";
PUT @1 "*     INTO SEPARATE COLUMN;";
put @1 "*---------------------------------------------------------------------;";
put;
put @1 '%local nmt incv dsid rc nv;';
put;
put;
put @1 '%let dsid=%sysfunc(open(__fall));';
put @1 '%let nv = %sysfunc(varnum(&dsid,__indentlev));';
put @1 '%let rc = %sysfunc(close(&dsid));';
put @1 '%let incv = 0;';
put;
put @1 '%if &nv<=0 %then %goto skipunindent;';
put;
put @1 "proc sql noprint;";
put @1 "select max(__indentlev) into:incv separated by '' from __fall (where =(__indentlev>=0));";
put @1 "quit;";
put;
put '%if %length(&incv) <=0 %then %let incv=0;';

put @1 "*---------------------------------------------------------------------;";
put @1 "*  PULL REQUESTED STATISTICS VARIABLES INTO 2ND COLUMN;";
put @1 "*---------------------------------------------------------------------;";
put;
put;
put @1 "  data &dataset;";
put @1 "    set &dataset;";
put @1 "    length __newcol0 $ 2000 ;";
put @1 "    retain __newcol0 __newind;";
put @1 "    if _n_=1 then do;";
put @1 "      array cols {*} __col_:;";
put @1 "      call symput('nmt', cats(dim(cols)-1));";
put @1 "    end; ";
put @1 "    if __datatype='TBODY' then do;";
put @1 '      if __indentlev<&incv then  do;';
put @1 "        __newcol0=cats(__col_0); ";
put @1 "        __newind=__indentlev; ";
put @1 ' %if %length(&incv) %then %do;';
put @1 '        if __indentlev = &incv-1 then __fordelete=1;';
put @1 "        else do; do __i=1 to dim(cols); cols[__i]=''; end; end;";
put @1 ' %end;';
put @1 ' %else %do;';
put @1 "   do __i=1 to dim(cols); cols[__i]=''; end; end;";
put @1 ' %end;';
put @1 "      end;";
put @1 "    end;";
put @1 "    if __datatype='RINFO' then __lastcheadid=__lastcheadid+1;";
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
%let rename2 = __newcol0=__col_0;



put '%if &nmt>0 %then %do;';
put;
put @1 '  %local rename1 rename2 j i ;';
put @1 '  %let rename2 = ' "&rename2 ;";
put @1 '  %let rename1 =  ;';
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
put @1 "    __stretch = 'Y '||cats(__stretch);";
put @1 '    if __datatype="HEAD" and __rowid=&lastrow  then do;';
put @1 "    __newcol0 = scan(cats(__ncol_1),1, '!');";
put @1 "    __ncol_1 = scan(cats(__ncol_1), 2, '!');";
put @1 "    end; ";
put @1 "    __indentlev=__newind;";
put @1 "  run;   ";
put;
put @1 "  data &dataset ;";
put @1 "    set &dataset ;";
put @1 "   __oldcol=lag(__col_0);";
/*
put @1 "   if __datatype='RINFO' then do;";
put @1 '    __tmp = &nmt +2 - countw(__colwidths," ");';
put @1 '    do __i=1 to __tmp;';
put @1 "      __colwidths = 'LW '||cats(__colwidths);";
put @1 '    end;';
put @1 '    __tmp = &nmt +2-countw(__stretch, " ");';
put @1 '    do __i=1 to __tmp;';
put @1 "      __stretch = 'Y '||cats(__stretch);";
put @1 '    end;';
put @1 "  end;";
*/
put @1 "  if __datatype='TBODY' and __rowid>1 and __col_0=__oldcol then do;";
put @1 "    __col_0='';";
put @1 '    __indentlev=&incv;';
put @1 "  end;";
put @1 "  drop  __newind __oldcol ;";
put @1 " run;";
put;
put @1 '%end;';
put;
put @1 '%skipunindent:';
put;
put;
put;
put;
run;  
%mend;  
