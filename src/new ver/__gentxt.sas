/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __gentxt/store;
  %local rrgoutpathlazy ;
  %let rrgoutpathlazy=&rrgoutpath;

 

 data _null_;
  file "%str(&rrgpgmpath.)/&rrguri.0.sas" mod lrecl=1000;
  put;
  put;
  put;
  put @1 '*---------------------------------------------------------;';
  put @1 '*  SAVING VALIDATION TEXT FILE;';
  put @1 '*---------------------------------------------------------;';
  put;
  put;
  put @1 '%macro __rrggenfile;';
  put @1 '  %local lastcol dsin vbvn rc nobs __path v_fil_loc v_fil_loc0;';
  put @1 '  %let vbvn=0;';
  put;
  put;
  put @1 '%if %length(&rrgoutpath)=0 %then';
  put @1 '  %let __path=' "&rrgoutpathlazy;";
  put @1 '%else %let __path = &rrgoutpath;';
  put;
  put @1 '%let v_fil_loc = &__path./'  "&rrguri..txt;";
  put @1 '%let v_fil_loc0 = &__path./' "&rrguri.0.txt;";  
  put;
  put @1 "*--------------------------------------------------------------------------;";
  put @1 "*** CHECK IF DATASET WITH TABLE CONTENT HAS ANY OBSERVATIONS;";
  put @1 "*--------------------------------------------------------------------------;";
  put;
  put @1 '  %let dsin = %sysfunc(open(' "&rrguri" "));";
  put @1 '  %let vbvn = %sysfunc(varnum(&dsin, __varbylab));';
  put @1 '  %let nobs = %sysfunc(attrn(&dsin, nobs));';
  put @1 '  %let rc = %sysfunc(close(&dsin));';
  put;
  put @1 '  %if &nobs<=0 %then %do;';
  put;
  put @1 '    *-------------------------------------------------------------------;';
  put @1 '    * GENERATE EMPTY VALIDATION FILE;';
  put @1 '    *-------------------------------------------------------------------;';
  put;      
  put @1 '    data _null_;';
  put @1 '    file "' '&v_fil_loc0' '"' "&modstr;";
  put @1 "    put ' ';";
  put @1 '    run;';
  put;
  put @1 '  %end;';

  put @1 '  %else %do;';
  put @1 '    %local lastcol;';
  put;  
  put @1 '    data _null_;';
  put @1 "    set &rrguri;";
  put @1 "    if 0 then __col_0='';";
  put @1 "    array cols{*} $ 2000 __col_:;";
  put @1 "    n = dim(cols)-1;";
  put @1 "    if _n_=1 then call symput('lastcol', strip(put(n, best.)));";
  put @1 "    run;";
  put;  
  put @1 "    *-------------------------------------------------------------------;";
  put @1 "    * GENERATE VALIDATION FILE;";
  put @1 "    *-------------------------------------------------------------------;";
  put @1 "    data _null_;";
  put @1 "    set &rrguri(where=(__datatype='TBODY'));";
  put @1 '    file "' '&v_fil_loc0' '";';
  put;
  put @1 "    if 0 then do;";
  put @1 "      __tcol=''; __fospan=.;"; 
  put @1 "    end;";
  put;      
  put @1 '    array cols{*} __col_0 - __col_&lastcol;';
  put @1 "    do i=1 to dim(cols);";
  put @1 "        cols[i]=cats(cols[i]);";  
  put @1 "    end;";
  put;
  put @1 '    %if &vbvn>0 %then %do;';
  /*put @1 "      if __tcol ne '' and __fospan=1 then put __varbylab __tcol;  ";*/
  put @1 "      if __tcol ne '' and __fospan=1 then put __varbylab __tcol;  ";
  put @1 '      put __varbylab  __col_0 - __col_&lastcol; ';
  put @1 '    %end;';
  put @1 '    %else %do;';
  put @1 "      if __tcol ne '' and __fospan=1 then put __tcol;  ";
  put @1 '      put  __col_0 - __col_&lastcol; ';
  put @1 '    %end;';
  put;      
  put @1 "    run;";
  put;  
  put @1 '  %end;';
  put;
  put @1 "  data _null_;";
  put @1 '  file "' '&v_fil_loc' '"'  "&modstr lrecl=32000;";
  put @1 '  infile "' '&v_fil_loc0' '" length=len; ';
  put @1 "  input record2 $varying2000. len; ";
  put @1 "  record2=tranwrd(trim(record2),'//',' ');";
  put @1 "  record2=compbl(record2);";
  put @1 "  if record2 ne '' then put record2;";
  put @1 "  run;";
  put;
  put @1 '%mend;';
  put;
  put @1 '%__rrggenfile;';
  put;
run;  
  
%mend;
