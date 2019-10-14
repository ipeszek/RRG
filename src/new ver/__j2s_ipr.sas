/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __j2s_ipr(lppnh=, ls=, appendable=, append=, replace=)/store;
  
%* generates code to infile proc report and to add titles and footnotes;
%* generated code appends to &rrguri.0.sas
  
%local lppnh i ls appendable append replace;
%local rrgoutpathlazy ;
%let rrgoutpathlazy=&rrgoutpath;
  
%put;
%put *************************************************************************;
%put STARTNG EXECUTION OF __J2S_IPR;
%put lppnh=&lppnh ls=&ls  appendable=&appendable append=&append;
%put;

%local i tmp1 tmp2 tmp;
 
 
data null;
file "&rrgpgmpath./&rrguri.0.sas"  mod lrecl=5000;
put;
put;
put @1 '%macro __ipr;';
put;
put @1 '%global __rrgpn;';
put @1 '%local __path;';
put @1 '%if %length(&rrgoutpath)=0 %then';
put @1 '  %let __path=' "&rrgoutpathlazy;";
put @1 '%else %let __path = &rrgoutpath;';
put;
put @1 "*-------------------------------------------------------------------------;";
put @1 "*** INFILE PROC REPORT;";
put @1 "*-------------------------------------------------------------------------;";
PUT;
put @1 "data __file4rtf; ";
put @1 '   infile "' '&__path./' "&fname..out" '" length=len; ';
put @1 "   length fc $ 1 record $ 200;";
put @1 "   input record $varying2000. len; ";
put @1 "   retain pagenum 1  idnum 0;";
put @1 "   if record ne '' then fc = substr(record,1,1);";
put @1 "   else fc=' ';";
put @1 "   fcr=rank(fc);";
put @1 "   if fcr=12 then pagenum+1;";
put @1 "   record = compress(record, byte(12));";
put @1 "   idnum+1;";
put @1 "run;";
PUT;
put;
put @1 "*-------------------------------------------------------------------------;";
put @1 "*  COUNT NUMBER OF LINES PER PAGE;";
put @1 "*-------------------------------------------------------------------------;";
put;
put;
put @1 "data __file4rtf;";
put @1 "  set __file4rtf;";
put @1 "  retain numlines ;";
put @1 "  if _N_=1 or fcr=12 THEN NUMLINES=0;";
put @1 "  numlines+1;";
put @1 " __cntpar = count(record, '\par');";
put @1 " numlines = numlines + __cntpar;";
put @1 " drop __cntpar;";
put @1 "run;";
put;
 
put @1 "*-------------------------------------------------------------------------;";
put @1 "* ADD RECORDS WITH TITLES AND FOOTNOTES ;";
put @1 "*-------------------------------------------------------------------------;";
put;
put;
put @1 "data __file4rtf;";
put @1 "set __file4rtf end=eof;";
put @1 "length  tmpr $ 200;";
put;
put @1 "oldnumlines=lag(numlines);";
put @1 "if _n_=1 then do;";
put @1 "    tmpr= record;";
put;
run;

data null;
file "&rrgpgmpath./&rrguri.0.sas"  mod lrecl=5000;
set __currtflsh end=eof;
ns = strip(ns);
if index(ns,'"')>0 then do;
  put @1 "  record = '" ns "';";
end;
else do;
  put @1 '  record = "' ns '";';
end;
put @1 "  output;";
run;

data null;
file "&rrgpgmpath./&rrguri.0.sas"  mod lrecl=5000;
set __currtflt end=eof;
ns = strip(ns);
if index(ns,'"')>0 then do;
  put @1 "  record = '" ns "';";
end;
else do;
  put @1 '  record = "' ns '";';
end;

put @1 "  output;";
if eof then do;
  put @1 "  fcr=0;";
  put @1 "  record=tmpr;";
  put @1 "  output;";
  put @1 "end;";
  put;
  put @1 "else if fcr=12 then do;";
  put @1 "  tmpr= cats(record);";
  put @1 "  do i=1 to &lppnh-oldnumlines;";
  put @1 "    record = ' ';";
  put @1 "    output;";
  put @1 "  end;";
end;
run;

data null;
file "&rrgpgmpath./&rrguri.0.sas"  mod lrecl=5000;
set __currtflf end=eof;
ns = strip(ns);
if index(ns,'"')>0 then do;
  put @1 "  record = '" ns "';";
end;
else do;
  put @1 '  record = "' ns '";';
end; 
put @1 "  output;";
run;

data null;
file "&rrgpgmpath./&rrguri.0.sas"  mod lrecl=5000;
set __currtflsf end=eof;
ns = strip(ns);
if index(ns,'"')>0 then do;
  put @1 "  record = '" ns "';";
end;
else do;
  put @1 '  record = "' ns '";';
end;

put @1 "  output;";
if eof then do;
  put @1 "  record = '\page';";
  put @1 "  output;";
end;
run;

data null;
file "&rrgpgmpath./&rrguri.0.sas"  mod lrecl=5000;
set __currtflsh end=eof;
ns = strip(ns);
if index(ns,'"')>0 then do;
  put @1 "  record = '" ns "';";
end;
else do;
  put @1 '  record = "' ns '";';
end;
put @1 "  output;";
run;

data null;
file "&rrgpgmpath./&rrguri.0.sas"  mod lrecl=5000;
set __currtflt end=eof;
ns = strip(ns);
if index(ns,'"')>0 then do;
  put @1 "  record = '" ns "';";
end;
else do;
  put @1 '  record = "' ns '";';
end;
put @1 "  output;";
if eof then do;
  put @1 "  record=tmpr;";
  put @1 "  output;";
  put @1 "end;";
  put;
  put @1 "else if eof then do;";
  put @1 "  output;";
  put @1 "  do i=1 to &lppnh-numlines;";
  put @1 "    record = ' ';";
  put @1 "    output;";
  put @1 "  end;";
end;
run;

data null;
file "&rrgpgmpath./&rrguri.0.sas"  mod lrecl=5000;
set __currtflf end=eof;
ns = strip(ns);
if index(ns,'"')>0 then do;
  put @1 "  record = '" ns "';";
end;
else do;
  put @1 '  record = "' ns '";';
end;
  put @1 "  output;";
run;

data null;
file "&rrgpgmpath./&rrguri.0.sas"  mod lrecl=5000;
set __currtflsf end=eof;
ns = strip(ns);
if index(ns,'"')>0 then do;
  put @1 "  record = '" ns "';";
end;
else do;
  put @1 '  record = "' ns '";';
end;

put @1 "  output;";
if eof then do;
  put @1 "end;";
  put @1 "else  output;";
  %* todo: if not appendable then do below ;
  put @1 " if eof then call symput('__rrgpn', strip(put(pagenum, best.)));";
  put @1 "run;";
  put;
  put;
  put;
end;

run;
 
 
data null;
file "&rrgpgmpath./&rrguri.0.sas"  mod lrecl=5000;
put;
put @1 "data _null_;";
put @1 'file "' '&__path./' "&fname..out0" '"' "&appendm lrecl=1000;";
put @1 "set __file4rtf end=eof;";
%if &append = Y %then %do;
  put @1 "if _n_=1 then put '\page';";
%end;
put @1 "put record $&ls..;";
put @1 "run;";
put;

%if &append = Y %then %do;
  put @1 "data __file4rtf;";
  put @1 'infile "' '&__path./' "&fname..out0" '" lrecl=1000 length=len;';
  put @1 "input record $varying1000. len; ";
  put @1 "run;";
  put;

  %if &appendable ne Y %then %do;
    put @1 "*--------------------------------------------------------------------------;";
    put @1 "* DETERMINE TOTAL NUMBER OF PAGES;";
    put @1 "*--------------------------------------------------------------------------;";
    put;
    put @1 "data __file4rtf;";
    put @1 "set  __file4rtf end=eof;";
    put @1 "retain pagenum;";
    put @1 "if _n_=1 then pagenum=1;";
    put @1 "if record='\page' then pagenum+1;";
    put @1 "if eof then call symput('__rrgpn', strip(put(pagenum, best.)));";
    %if %length(&replace) %then %do;
      %do i=1 %to %sysfunc(countw(%nrbquote(&replace),%str(,)));
        %let tmp=%qscan(%nrbquote(&replace),&i, %str(,));
        %let tmp1=%qscan(%nrbquote(&tmp),1,%str(:));
        %let tmp2=%qscan(%nrbquote(&tmp),2,%str(:));
        put @1 "   record = tranwrd(trim(record), &tmp1, &tmp2);";
      %end;
    %end;
    
    put @1 "run;";
    put;
  %end;
%end;
put;
put @1 '%mend;';
put;
put @1 '%__ipr;';

%put; 
%put FINISHED EXECUTION OF __J2S_IPR; 
%put *************************************************************************;

%mend;
