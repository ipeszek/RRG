/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __j2s_rprt(ls=, ps=, ispage=, isspanrow= , __spanvar=)/store;
  
%local  ls ps ispage isspanrow __spanvar i;  
%* runs proc report;



%put;
%put *************************************************************************;
%put STARTNG EXECUTION OF __J2S_RPR;
%put ls=&ls ps=&ps ispage=&ispage ;
%put isspanrow=&isspanrow __spanvar=&__spanvar;
%put;


%do i=0 %to  &numcol;
  %local sp&i nal&i cw&i clab&i;
%end;


data __colinfo;
  set __colinfo;
  length clab $ 2000;
  call symput('sp'||strip(put(colnum, best.)), strip(put(sp,best.)));
  call symput('nal'||strip(put(colnum, best.)), strip(nal));
  *call symput('cw'||strip(put(colnum, best.)), strip(put(cw,best.)));
  call symput('cw'||strip(put(colnum, best.)), strip(cw));
  call symput('clab'||strip(put(colnum, best.)), strip(clab));
run;

%do i=0 %to  &numcol;

%end;

data null;
file "&rrgpgmpath./&rrguri.0.sas"  mod lrecl=5000;
put;
put;
put;
put @1 "*--------------------------------------------------------------------;";
put @1 "*  RUN PROC REPORT;";
put @1 "*--------------------------------------------------------------------;";
put;
run;
 
%* todo: store colstr&i in file; 


%local rrgoutpathlazy ;
%let rrgoutpathlazy=&rrgoutpath;


 
data null;
file "&rrgpgmpath./&rrguri.0.sas"  mod lrecl=5000;
put;
put;
put;
put @1 '%macro __rprt;';
put;
put @1 '%local __path;';
put @1 '%if %length(&rrgoutpath)=0 %then';
put @1 '  %let __path=' "&rrgoutpathlazy;";
put @1 '%else %let __path = &rrgoutpath;';
put;
put @1 'proc printto print = "' '&__path./' "&fname..out" '";';
put;
put;
put @1 "options ls=&ls ps = &ps notes mprint nocenter nodate nonumber;";
put "title; ";
put "footnote;";
put;
put @1 "proc report data=__final headline formchar(2)='_'  missing split='|' nowd spacing=0;";
put;
%if &ispage=1 %then %do;
put @1 "  columns __varbygrp __varbylab __npage &__spanvar " ;
%end;
%else %do;
put @1 "  columns  __npage &__spanvar";
%end;
run;

data null;
set __colstr;
file "&rrgpgmpath./&rrguri.0.sas"  mod lrecl=5000;
put tmp1;
run;

data null;
file "&rrgpgmpath./&rrguri.0.sas"  mod lrecl=5000;
put @1 ";";
put @1 "  define __npage /order order=internal noprint;";
%if &ispage=1 %then %do;
put @1 "  define __varbygrp /order order=internal noprint;";
put @1 "  define __varbylab /order order=internal noprint;";
%end;
%if &isspanrow=1 %then %do;
put @1 "  define __spanvar /order order=internal noprint;";
put @1 "  define __tcol /order order=internal noprint;";
%end;
%if %length(&clab0) %then %do;
put @1 "    define __col_0 /width=&cw0  " '"' "&clab0" '" ' " &nal0 ;";
%end;
%else %do;
put @1 "    define __col_0 /width=&cw0 ' ' &nal0 ;";
%end;
 
 
%do i=1 %to &numcol;
%if %length(&&clab&i) %then %do;
put @1 "    define __col_&i /width=&&cw&i spacing=&&sp&i " '"' "&&clab&i" '" ' " &&nal&i ;";
%end;
%else %do;
put @1 "    define __col_&i /width=&&cw&i spacing=&&sp&i ' ' &&nal&i ;";
%end;
%end;
 
put @1 "  break after __npage/page;";
put @1 "  compute before _page_;";
%if &ispage=1 %then %do;
put @1 "    line @1 __varbylab $&ls..;";
%end;
put @1 "  length __line $ &ls;";
put @1 "  __line = repeat('_', &ls.);";
put @1 "  line @1 __line $&ls..;";
put @1 "  endcomp;";
%if &isspanrow=1 %then %do;
put @1 "  compute before __tcol;";
put @1 "   line @1 __tcol $&ls..;";
put @1 "  endcomp;";
%end;
 
put @1 "run;";
put @1 "quit;";
put;
put;
put @1 "proc printto print=print;";
put @1 "run;";
put;
put @1 '%mend;';
put;
put @1 '%__rprt;';
PUT;
run;

 
  
 
%put; 
%put FINISHED EXECUTION OF __J2S_RPR; 
%put *************************************************************************;
%put;  
%mend;  
