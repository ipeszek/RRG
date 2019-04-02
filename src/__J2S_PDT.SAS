/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __j2s_pdt(numcol=, cl=, colwidths=, lpp=, isspanrow=, ispage=, __spanvar=, varbyval=NONE)/store;

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
put @1 "if __indentlev<0 then __indentlev=0;";
put @1 "if __indentlev>0 then __col_0 = '/t'||strip(put(__indentlev,best.))||trim(__col_0);";
put @1 "run;";
put;
put @1 "data __final (drop=__dtl_:) __dtl(keep=__dtl_:);";
put @1 "length __al $ 5 __len __colwidths __tmpsep __tmpgp $ 2000;";
put @1 "set __final end=eof;";
put @1 "array cols{*} __col_0 -__col_&numcol;";
put @1 "array tl{*} __tl_0 -__tl_&numcol;";
put @1 "array tl2{*} __tl2_0 -__tl2_&numcol;";
put @1 "array dtl{*} __dtl_0 -__dtl_&numcol;";
put @1 "array dtl2{*} __dtl2_0 -__dtl2_&numcol;";
put @1 "retain __dtl_0 -__dtl_&numcol __dtl2_0 -__dtl2_&numcol;";
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
put @1 "    tl[__cc]= __tl;";
put @1 "    tl2[__cc]= 0;";
put @1 "    put 'Decimal: ' cols[__cc]= tl[__cc]= tl2[__cc]= __al=;";
put @1 "  end;";
put @1 "  else if __al = 'RD' then do;";
put @1 '    %__getpadsRD(string=cols[__cc]);';
put @1 "    tl[__cc]= __tl;";
put @1 "    tl2[__cc]= __tl2;";
put @1 "    put 'RD: ' cols[__cc]= tl[__cc]= tl2[__cc]= __al=;";
put @1 "  end;";
put @1 "  else do;";
put @1 '    %__splitstr(string=cols[__cc], len=input(scan(__len, __cc,' " ' '), best.));";
put @1 "    tl2[__cc]= 0;";
put @1 "  end;";
put @1 "dtl[__cc]=max(dtl[__cc], tl[__cc]);";
put @1 "dtl2[__cc]=max(dtl2[__cc], tl2[__cc]);";
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
PUT @1 "** DETERMINE NUMBER OF LINES PER RECORD;";
put @1 "*---------------------------------------------------------------------;";
put;
put @1 "data __final;";
put @1 "set __final end=eof;";
put @1 "length __lst $ 2000 __al  $ 5 ;";
put @1 "if _n_=1 then set __dtl;";
 
put @1 "array cols{*} __col_0 -__col_&numcol;";
 
 
put @1 "array tl{*} __tl_0 -__tl_&numcol;";
put @1 "array dtl{*} __dtl_0 -__dtl_&numcol;";
put @1 "array tl2{*} __tl2_0 -__tl2_&numcol;";
put @1 "array dtl2{*} __dtl2_0 -__dtl2_&numcol;";

put @1 "array nl{*} __nl_0 -__nl_&numcol;";
put @1 "array actlen{*} __actlen_0 -__actlen_&numcol;";
put @1 "__len = '" "&cl" "';";
 
put @1 "retain __actlen_0-__actlen_&numcol __actlen_vb __actlen_sp;";
put @1 "if _n_=1 then do;";
put @1 "  __actlen_vb=0;";
put @1 "  __actlen_sp=0;";
/*
%if &isspanrow=1 %then %do;
  put @1 "  __spanvar=0;";
%end;
*/
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
put @1 "  else if __al = 'RD' then do;";
&debugc put @1 "    put 'RD: ' cols[__cc]= dtl2[__cc]= tl2[__cc]= dtl[__cc]= tl[__cc]=;";
put @1 "    if dtl2[__cc]>0  then do;";
put @1 "      diff = dtl2[__cc]-tl2[__cc];";
put @1 "      if diff>0 then cols[__cc]=scan(cols[__cc],1,byte(160)||' ')||repeat(byte(160), diff)||scan(cols[__cc],2,byte(160)||' ');";
&debugc put @1 "put diff= cols[__cc]=; put;";
put @1 "    end;";
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

%if &isspanrow=1 %then %do;
  put @1 "if __fospan = 1 then do;";
  put @1 "  __nfmaxl = __nfmaxl+1+count(__tcol,'\par');";
  put " __tmpcnt = count(__tcol,'\par');";
  
  put @1 "  __maxl = __maxl+1+count(__tcol,'\par');";
  put @1 "end;";
%end;
put;
 
put @1 "if eof then do;";
 
put @1 "  __lst='length';";
%if &ispage=1 %then %do;
  put @1 "  __lst = strip(__lst)||' __varbylab $ '||strip(put(__actlen_vb, best.));";
%end;
%if &isspanrow=1 %then %do;
  put @1 "  __lst = strip(__lst)||' __tcol $ '||strip(put(__actlen_sp, best.));";
%end;
put @1 "  do __cc=1 to dim(cols);";
put @1 "    __cc0=__cc-1;";
put @1 "    __lst = strip(__lst)||' __col_'||strip(put(__cc0, best.))||'  $ '||strip(put(actlen[__cc], best.));";
put @1 "  end;";
put @1 "  call symput('__rrglenstmt', strip(__lst));";
put @1 "end;";
put @1 "run;";
put;
put;
put @1 "*---------------------------------------------------------------------;";
PUT @1 "** DETERMINE 'PARENT' LINES FOR EACH RECORD;";
PUT @1 "** THESE ARE LINES TO BE PRINTED ON TOP OF THE PAGE;";
put @1 "*---------------------------------------------------------------------;";
put @1 "data __final;";
put @1 "set __final;";
put @1 "length __parent0 - __parent10 __parentfull  $ 5000;";
put @1 "array parents{*} __parent0 - __parent10;";
put @1 "array parentsl{*} __parentl0 - __parentl10;";
put @1 "retain __parent0 - __parent10 __parentl0 - __parentl10;";
put @1 "__oldind = lag(__indentlev);";
put @1 "parents[__indentlev+1]=__col_0;";
put @1 "parentsl[__indentlev+1]=__nl_0;";
put @1 "do __i=__indentlev+2 to 10;";
put @1 "  parents[__i]='';";
put @1 "  parentsl[__i]=0;";
put @1 "end;";
put @1 "__parentfull = '';";
put @1 "__tmpparentl = 0;";
put @1 "do __i=1 to __indentlev;";
put @1 "  if __parentfull ne '' then do;";
put @1 "    if parents[__i] ne '' then do;";
put @1 "      __parentfull=strip(parents[__i])||'|'||strip(__parentfull);";
put @1 "      __tmpparentl=__tmpparentl+parentsl[__i];";
put @1 "    end;";
put @1 "  end;";
put @1 "  else do;";
put @1 "    if parents[__i] ne '' then do;";
put @1 "      __parentfull=strip(parents[__i]);";
put @1 "      __tmpparentl=parentsl[__i];";
put @1 "    end;";
put @1 "  end;";
put @1 "end;";
put @1 "run;";
PUT;

put @1 "*---------------------------------------------------------------------;";
PUT @1 "** DETERMINE 'KEEPN' GROUPS;";
put @1 "*---------------------------------------------------------------------;";
put;
put @1 "proc sort data=__final;";
put @1 "by descending __rowid;";
put @1 "run;";
put;
put @1 "data __final;";
put @1 "set __final;";
put @1 "by descending __rowid;";
put @1 "retain __keepngrp __keepnlc;";
put @1 "if _n_=1 then do;";
put @1 "  __keepngrp=0;";
put @1 "  __keepnlc=__nfmaxl;";
put @1 "end;";
put @1 "if __keepn ne 1 then do;";
put @1 "  __keepngrp+1;";
put @1 "  if _n_>1 then __keepnlc=__nfmaxl;";
put @1 "end;";
put @1 "else if _n_>1 then __keepnlc+__nfmaxl;";
put @1 "run;";
put;
put @1 "proc sort data= __final;";
put @1 "by descending __keepngrp __rowid;";
put @1 "run;";
put;
put @1 "data __final;";
put @1 "set __final;";
put @1 "by descending __keepngrp __rowid;";
put @1 "retain __keepnlc0 __keepnlc0p;";
%* __keepnlc0 = lines per group;
%* __keepnlc0p = lines per group including parent lines;
put @1 "if first.__keepngrp then do;";
put @1 "  __keepnlc0=__keepnlc;";
put @1 "  __keepnlc0p=__keepnlc+__tmpparentl;";
put @1 "end;";
put @1 "run;";
%* __keepnlc0 is the number of lines per "keepn" group;
%* __keepnlc0p is the number of lines per "keepn" group including parent lines;

put;
put @1 "*---------------------------------------------------------------------;";
PUT @1 "** DETERMINE PAGE BREAKS;";
put @1 "*---------------------------------------------------------------------;";
put;
put @1 "data __final;";
put @1 "set __final end=eof;";
put @1 "by descending __keepngrp __rowid;";
%if &isspanrow=1 %then %do;
put @1 "retain __linesf __npage __spanvar ;";
%end;
%else %do;
put @1 "retain __linesf __npage;";
%end;

put @1 "if _n_=1 then do;";
%if &isspanrow=1 %then %do;
  put @1 "  __spanvar=0;";
%end;
put @1 "  __linesf=0;";
put @1 "  __npage=1;";
put @1 "end;";
put;

put @1 "if first.__keepngrp then do;";
put @1 "  if (__linesf + __keepnlc0 > &lpp) then do;";
put @1 "    __npage+1;";
%if &isspanrow=1 %then %do;
put @1 "    __spanvar+1;";
%end;
put @1 "    __linesf = __keepnlc0p;";
put @1 "  end;";
put @1 "  else __linesf = __linesf+__keepnlc0;";
put @1 "end;";

%if &isspanrow=1 %then %do;
  put @1 " if __fospan=1 then __spanvar+1;";
%end;

%if &debug=0 %then %do; 
  put @1 "drop __tmp: __tl: __dtl: __nl: __nf: __max: ;";
  %if &ispage=1 %then %do;
    put @1 "drop __old:;";
  %end;
%end;
 
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
  put @1 "keep __col_: __rowid __npage &__spanvar __varby: __parentfull;";
%end;
%else %do;
  put @1 "by __npage  &__spanvar __rowid;";
  put @1 "keep __col_: __rowid __npage &__spanvar __parentfull;";
%end;
 
put @1 "array cols{*} __col_0 -__col_&numcol;";
 
%do i=0 %to &numcol;
  %if %length(&&cst&i) %then %do; put @1 "&&cst&i"; %end;
%end;
 
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
%end;
%else %do;
  put @1 "by __npage  &__spanvar __rowid;";
%end;
 
put @1 "array cols{*} __col_0 -__col_&numcol;";
 
put @1 "output;";
put @1 "if first.__npage and __parentfull ne '' then do;";
put @1 "  do __cc = 1 to dim(cols);";
put @1 "    cols[__cc]='';";
put @1 "  end;";
put @1 "  do __jj=1 to countw(__parentfull,'|');";
put @1 "    __rowid=__rowid-(10-__jj)*0.00000001;";
put @1 "    cols[1]=scan(__parentfull,__jj, '|');";
put @1 "    output;";
put @1 "  end;";
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
