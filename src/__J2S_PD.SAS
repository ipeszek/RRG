/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __j2s_pd(numcol=, cl=, colwidths=, lpp=, isspanrow=, ispage=, __spanvar=, varbyval=NONE)/store;

%local numcol cl colwidths lpp isspanrow ispage __spanvar i varbyval;

%put;
%put *************************************************************************;
%put STARTNG EXECUTION OF __J2S_PD;
%put numcol=&numcol cl=&cl colwidths=&colwidths;
%put lpp=&lpp isspanrow=&isspanrow ispage=&ispage __spanvar=&__spanvar;
%put;
  
  
  
%* writes statements to generated program that process input dataset ;
%* create hard splits , apply padding, calculate page breaks;



%do i=0 %to &numcol;
  %local st&i cst&i;
%end;

data __colinfo;
  set __colinfo;
  length stmt cstmt $ 2000;
  colnum2=colnum+1;
  if focol=1 then do;
     stmt="if __first_"||strip(put(colnum, best.))||" = 1 then __nfmaxl = max(__nfmaxl, nl["||
      strip(put(colnum2, best.))||"]);";
     cstmt= "if __first_"||strip(put(colnum, best.))||" ne 1 and not first.__npage then __col_"||
       strip(put(colnum, best.))||" = '';";  
  end;    
  else stmt = "__nfmaxl = max(__nfmaxl, nl["||strip(put(colnum2, best.))||"]);";
  call symput ('st'||strip(put(colnum, best.)), strip(stmt));
  call symput ('cst'||strip(put(colnum, best.)), strip(cstmt));
run;
      
 
data null;
file "&rrgpgmpath./&rrguri.0.sas" mod ;
put;
put;
put @1;
put @1 "*---------------------------------------------------------------------;";
put @1 "*** TRANSFORM DATA FOR PRINTING - CREATE INDENTATIONS AND LINE SPLITS;";
put @1 "*---------------------------------------------------------------------;";
put;
put;
put @1 "data __final;";
%if &varbyval=NONE %then %do;
put @1 "set &rrguri;";
%end;
%else %do;
put @1 "set &rrguri (where=(__varbygrp=&varbyval));";
%end;
put @1 "if __datatype='TBODY';";
put @1 "run;";
put;
put @1 "data __final (drop=__dtl_:) __dtl(keep=__dtl_:);";
put @1 "length __al $ 5 __len __colwidths $ 200;";
put @1 "set __final end=eof;";
put @1 "array cols{*} __col_0 -__col_&numcol;";
put @1 "array tl{*} __tl_0 -__tl_&numcol;";
put @1 "array dtl{*} __dtl_0 -__dtl_&numcol;";
put @1 "retain __dtl_0 -__dtl_&numcol;";
put;
put @1 "if _n_=1 then do;";
put @1 " do __cc=1 to dim(dtl);";
put @1 "   dtl[__cc]=0;";
put @1 " end;";
put @1 "end;";
put;
put @1 "__len = '" "&cl" "';";
put @1 "__colwidths = upcase(strip('" "&colwidths" "'));";
 
put;
put @1 "do __cc = 1 to dim(cols);";
put @1 " if scan(__colwidths, __cc, ' ') in ('NH', 'N') then ";
put @1 "    cols[__cc]=tranwrd(strip(cols[__cc]), ' ', byte(160));";


put @1 " tl[__cc]=0;";
put @1 "  __al = scan(__align, __cc, ' ');";
put @1 "  if __al = 'D' then do;";
put @1 '    %__getpads(string=cols[__cc]);';
put @1 "  tl[__cc]= __tl;";
put @1 "  end;";
put @1 "  else do;";
put @1 '    %__splitstr(string=cols[__cc], len=input(scan(__len, __cc,' " ' '), best.));";
put @1 "  end;";
put @1 "dtl[__cc]=max(dtl[__cc], tl[__cc]);";
put @1 "end;";
put @1 "output __final;";
put @1 "if eof then output __dtl;";
put @1 "run;";
put;
put;
put;
put;
put @1 "*---------------------------------------------------------------------;";
PUT @1 "** PAD NUMBERS WITH DECIMAL ALIGNMENT;";
PUT @1 "** DETERMINE PAGE BREAKS;";
put @1 "*---------------------------------------------------------------------;";
put;
put @1 "data __final;";
put @1 "length __lst $ 2000 __al $ 5;";
put @1 "set __final end=eof;";
put @1 "if _n_=1 then set __dtl;";
 
put @1 "array cols{*} __col_0 -__col_&numcol;";
 
 
put @1 "array tl{*} __tl_0 -__tl_&numcol;";
put @1 "array dtl{*} __dtl_0 -__dtl_&numcol;";
put @1 "array nl{*} __nl_0 -__nl_&numcol;";
put @1 "array actlen{*} __actlen_0 -__actlen_&numcol;";
put @1 "__len = '" "&cl" "';";
 
put @1 "retain __linesf __npage __actlen_0-__actlen_&numcol __actlen_vb __actlen_sp;";
put @1 "if _n_=1 then do;";
put @1 "  __actlen_vb=0;";
put @1 "  __actlen_sp=0;";
%if &isspanrow=1 %then %do;
  put @1 "  __spanvar=0;";
%end;
put @1 "  __linesf=0;";
put @1 "  __npage=1;";
put @1 "end;";
%if &ispage=1 %then %do;
  put @1 "__oldvarbygrp = lag(__varbygrp);";
  put @1 "if _n_=1 then __oldvarbygrp = __varbygrp;";
%end;
put @1 "__maxl = 0;";
put @1 "__nfmaxl = 0;";
put @1 "* __maxl=max number of lines across all columns;";
put @1 "* __nfmaxl=max number of lines across all not first-only columns;";
%if &ispage=1 %then %do;
  put @1 "__actlen_vb = max(__actlen_vb, length(__varbylab));";
%end;
%if &isspanrow=1 %then %do;
  put @1 "__tcol = tranwrd(strip(__tcol), '//','\par ');";
  put @1 "__actlen_sp = max(__actlen_sp, length(__tcol));";
%end;
put @1 "do __cc = 1 to dim(cols);";
put @1 "  __al = scan(__align, __cc, ' ');";
put @1 "  if __al = 'D' then do;";
put @1 "    if dtl[__cc]>0  then do;";
put @1 "      diff = dtl[__cc]-tl[__cc];";
put @1 "      if diff>0 then cols[__cc]=repeat(byte(160), diff-1)||strip(cols[__cc]);";
put @1 "    end;";
put @1 "    nl[__cc]= ceil(length(cols[__cc])/(input(scan(__len, __cc, ' '), best.)));";
put @1 "  end;";
put @1 "  else nl[__cc]=countw(cols[__cc],'|');";
put @1 "  if __suffix = '~-2n' then nl[__cc]+1;";
put;
put @1 "  ** this is number of lines needed for given cell;";
put @1 "  __maxl = max(__maxl, nl[__cc]);";
put @1 "  actlen[__cc]=max(actlen[__cc], length(cols[__cc]));";
put @1 "end;";
%do i=0 %to &numcol;
  put @1 "&&st&i";
%end;
/*  
%if &numfocols>0  %then %do;
  %do i=1 %to &numfocols;
    put @1 "if __first_&&focol&i = 1 then __nfmaxl = max(__nfmaxl, nl[%eval(&&focol&i+1)]);";
  %end;
%end;
%if &numnfocols>0  %then %do;
  %do i=1 %to &numnfocols;
    put @1 "__nfmaxl = max(__nfmaxl, nl[%eval(&&nfocol&i+1)]);";
  %end;
%end;
*/ 
%if &isspanrow=1 %then %do;
  put @1 "if __fospan = 1 then do;";
  put @1 "  __nfmaxl = __nfmaxl+1+count(__tcol,'\par');";
  put " __tmpcnt = count(__tcol,'\par');";
  
  put @1 "  __maxl = __maxl+1+count(__tcol,'\par');";
  put @1 "end;";
%end;
 
put;
%if &ispage=1 %then %do;
  put @1 "if (__linesf + __nfmaxl > &lpp) or __varbygrp ne __oldvarbygrp then do;";
%end;
%else %do;
  put @1 "if (__linesf + __nfmaxl > &lpp) then do;";
%end;
put @1 "  __npage+1;";
%if &isspanrow=1 %then %do;
  put @1 "  __spanvar+1;";
%end;
put @1 "  __linesf = __maxl;";
put @1 "end;";
put @1 "else __linesf = __linesf+__nfmaxl;";
put;
%if &isspanrow=1 %then %do;
  put @1 " if __fospan=1 then __spanvar+1;";
%end;
 
put @1 "if eof then do;";
 
put @1 "__lst='length';";
%if &ispage=1 %then %do;
  put @1 "__lst = strip(__lst)||' __varbylab $ '||strip(put(__actlen_vb, best.));";
%end;
%if &isspanrow=1 %then %do;
  put @1 "__lst = strip(__lst)||' __tcol $ '||strip(put(__actlen_sp, best.));";
%end;
put @1 "do __cc=1 to dim(cols);";
put @1 "  __cc0=__cc-1;";
put @1 "  __lst = strip(__lst)||' __col_'||strip(put(__cc0, best.))||'  $ '||strip(put(actlen[__cc], best.));";
put @1 "end;";
put @1 "call symput('__rrglenstmt', strip(__lst));";
 
/*
put @1 "call symput('actlen_vb', strip(put(__actlen_vb, best.)));";
put @1 "call symput('actlen_sp', strip(put(__actlen_sp, best.)));";
put @1 "  do __cc=1 to dim(cols);";
put @1 "     __cc0=__cc-1;";
put @1 "  call symput(cats('actlen_', put(__cc0, best.)), strip(put(actlen[__cc], best.)));";
put @1 "  end;";
*/
put @1 "end;";
%if &debug=0 %then %do; 
  put @1 "drop __tmp: __tl: __dtl: __nl: __nf: __max: ;";
  %if &ispage=1 %then %do;
    put @1 "drop __old:;";
  %end;
%end;
 
 
*** todo: this ignores keepn parameter which is not applicable to listings anyway;
put @1 "run;";
put;
/*put "proc print data=__final; title '4iza __final'; run;";*/
put;
put @1 "data __final;";
put @1 '&__rrglenstmt.;';
put @1 "set __final;";
put @1 "run;";
put;
put @1 "proc sort data=__final;";
 
%if &ispage=1 %then %do;
  put @1 "by __varbygrp  __npage &__spanvar __rowid;";
%end;
%else %do;
  put @1 "by  __npage &__spanvar __rowid;";
%end;
put @1 "run;";
put;
put @1 "data __final;";
put @1 "set __final;";
%if &ispage=1 %then %do;
  put @1 "by __varbygrp __npage &__spanvar __rowid;";
  put @1 "keep __col_: __rowid __npage &__spanvar __varby:;";
%end;
%else %do;
  put @1 "by __npage  &__spanvar __rowid;";
  put @1 "keep __col_: __rowid __npage &__spanvar ;";
%end;
 
put @1 "array cols{*} __col_0 -__col_&numcol;";
 
%do i=0 %to &numcol;
  %if %length(&&cst&i) %then %do; put @1 "&&cst&i"; %end;
%end;
/* 
%do i=0 %to &numcol;
  %let z = &&vcn&i;
  %if &&group&z=Y %then %do;
    put @1 "if __first_&i ne 1 and not first.__npage then __col_&i = '';";
  %end;
%end;
*/
 
put @1 "output;";
put @1 "if __suffix='~-2n' then do;";
put @1 "  do __cc = 1 to dim(cols);";
put @1 "    cols[__cc]='';";
put @1 "  __rowid=__rowid+0.00001;";
put @1 "  end;";
put @1 "  output;";
put @1 "end;";
put @1 "run;";
put;
put @1 "proc sort data=__final;";
%if &ispage=1 %then %do;
  put @1 "by __varbygrp __varbylab __npage &__spanvar __rowid;";
%end;
%else %do;
  put @1 "by __npage &__spanvar __rowid;";
%end;
put @1 "run;";
put;
run;
 
%put; 
%put FINISHED EXECUTION OF __J2S_PD; 
%put *************************************************************************;
 
%mend; 
