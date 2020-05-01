/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro rrg_genlist(debug=0, savexml=, finalize=y)/store;
%* note: for now, colsize and dist2next (if in units) shoudl be number of chars if java2sas is used; 
%* assumes __tcol takes only one line between //;
%* assumes varbygrp has only one line;
%* ignores __keepn;

%* Revision notes:  07Apr2014 commented out recoding of curly braces to #123 and #125 (superscript did not work except in header);
 
 
%local debugc;
%let debugc=%str(%%*);
%if &debug>0 %then %let debugc=;
 
 

 
%local numvars i dataset orderby j isspanrow ispage debug java2sas indentsize;

proc sql noprint;
  select dataset into:dataset separated by ' ' from __repinfo;
  select orderby into:orderby separated by ' ' from __repinfo;
quit;

data __listinfo;
  set __listinfo;
  length __orderby $ 2000;
  __orderby = strip(symget("orderby"));
  __fm=0;
  
  do __kk=1 to countw(__orderby, ' ');
   if upcase(alias)=upcase(scan(__orderby, __kk, ' ')) then __fm=1;
  end;
  if __fm = 0 then do;
    if upcase(group)='Y' then do;
      put 'WAR' 'NING: GROUP=Y requested for ' alias ' but ' alias ' is not specified in ORDERBY. GROUP=Y is ignored.';
      group='N';
    end;  
    if upcase(skipline)='Y' then  do;
      put 'WAR' 'NING: SKIPLINE=Y requested for ' alias ' but ' alias ' is not specified in ORDERBY. SKIPLINE=Y is ignored.';
      skipline='N';
    end;
    if upcase(keeptogether)='Y' then  do;
      put 'WAR' 'NING: KEEPTOGETHER=Y requested for ' alias ' but ' alias ' is not specified in ORDERBY. KEEPTOGETHER=Y is ignored.';
      keeptogether='N';
    end;
    if upcase(spanrow)='Y' then  do;
      put 'WAR' 'NING: SPANROW=Y requested for ' alias ' but ' alias ' is not specified in ORDERBY. SPANROW=Y is ignored.';
      SPANROW='N';
    end;
    if upcase(PAGE)='Y' then  do;
      put 'WAR' 'NING: PAGE=Y requested for ' alias ' but ' alias ' is not specified in ORDERBY. PAGE=Y is ignored.';
      PAGE='N';
    end;
  end;
run;

 
proc sql noprint;
select max(varid) into:numvars separated by ' ' from __listinfo;
%do i=1 %to &numvars;
  %local label&i  width&i group&i spanrow&i align&i halign&i
  page&i id&i alias&i  decode&i format&i stretch&i
  break&i d2n&i keeptogether&i;
   
  select dequote(label)  into: label&i separated   by ' ' from __listinfo (where=(varid=&i));
   
  select width   into: width&i separated   by ' ' from __listinfo (where=(varid=&i));
  select upcase(group)   into: group&i separated   by ' ' from __listinfo (where=(varid=&i));
  select upcase(spanrow) into: spanrow&i separated by ' ' from __listinfo (where=(varid=&i));
  select upcase(align)   into: align&i separated   by ' ' from __listinfo (where=(varid=&i));
  select upcase(halign)  into: halign&i separated  by ' ' from __listinfo (where=(varid=&i));
  select upcase(page)    into: page&i separated    by ' ' from __listinfo (where=(varid=&i));
  select upcase(id)      into: id&i separated      by ' ' from __listinfo (where=(varid=&i));
  select upcase(alias)   into: alias&i separated   by ' ' from __listinfo (where=(varid=&i));
  
  select upcase(skipline) into: skipline&i separated   by ' ' from __listinfo (where=(varid=&i));
  select upcase(decode)  into: decode&i separated   by ' ' from __listinfo (where=(varid=&i));
  select upcase(format)  into: format&i separated   by ' ' from __listinfo (where=(varid=&i));
  select upcase(stretch) into: stretch&i separated   by ' ' from __listinfo (where=(varid=&i));
  select upcase(keeptogether) into: keeptogether&i separated   by ' ' from __listinfo (where=(varid=&i));
  select upcase(breakok) into: break&i separated   by ' ' from __listinfo (where=(varid=&i));
  select upcase(dist2next) into: d2n&i separated   by ' ' from __listinfo (where=(varid=&i));
   
  select upcase(java2sas) into:java2sas separated by ' ' from __repinfo; 
  select indentsize into:indentsize separated by ' ' from __repinfo;
   
  %if &&spanrow&i=Y %then %let isspanrow=1;
  %if &&page&i=Y %then %let ispage=1;
  
  %if %upcase(&java2sas)=Y %then %do;
    %if %length(&&d2n&i)=0 %then %let d2n&i=1;
  %end;
  %else %do;
    %if %length(&&d2n&i)=0 %then %let d2n&i=D;
  %end;  
  %if "&&stretch&i" ne "N" %then %let stretch&i=Y;

%end;




quit;
 
%local numcol numpagev numspanv lastvb lastspan;
%let numcol=-1;
%let numpagev=0;
%let numspanv=0;
 
%do i=1 %to &numvars;
 
%if &&page&i=Y %then %do;
%let spanrow&i=;
%let group&i=;
%let id&i =;
%end;
%if &&spanrow&i=Y %then %do;
%let group&i=;
%let id&i =;
%end;
 
%if &&page&i ne Y and &&spanrow&i ne Y %then %do;
  %let numcol = %eval(&numcol+1);
  %local vcn&numcol;
  %let vcn&numcol=&i;
%end;
%else %if &&page&i = Y %then %do;
  %let numpagev = %eval(&numpagev+1);
  %local pvn&numpagev;
  %let pvn&numpagev=&i;
  %let lastvb=&&alias&i;
%end;
%else %if &&spanrow&i = Y %then %do;
  %let numspanv = %eval(&numspanv+1);
  %local svn&numspanv;
  %let svn&numspanv=&i;
  %let lastspan=&&alias&i;
%end;
 
%if %length(&&align&i)=0 %then %let align&i = L;
%if %length(&&halign&i)=0 %then %let halign&i = &&align&i;
%if %length(&&width&i)=0 %then %let width&i=LW;
 
%end;
 
%local i z   ;
 
%local append appendable;
proc sql noprint;
select upcase(append) into:append separated by ' ' from __repinfo;
select upcase(appendable) into:appendable separated by ' ' from __repinfo;
quit;
%local appendm;
%if %upcase(&append) ne Y %then %let append=N;
%if &append = Y %then %do;
%let appendm=mod;
%end;
 




%if &append ne Y %then %do;
  data _null_;
  set __rrght;
  file "&rrgpgmpath./&rrguri..sas"  ;
  put record;
  run;
  
  %* todo: check if still works with append;
  
  data __rrght;
    if 0;
    record='';
  run;

%end;
 
 
  
data _null_;
set __rrght;
file "&rrgpgmpath./&rrguri.0.sas"  ;
put record;
run;  


data _null_;
file "&rrgpgmpath./&rrguri.0.sas" mod;
put;
put;
put @1 "proc format;";
put @1 "  value $ best";
put @1 "  ' ' = ' ';";
put @1 "run;";
put;
put;
put @1 "*---------------------------------------------------------------------;";
PUT @1 "** TRANSFORM DATASET APPLYING FORMATS AND DECODES AS NEEDED;";
put @1 "*---------------------------------------------------------------------;";
PUT;
put @1 "proc sort data=&dataset out = &rrguri;";
put @1 "  by &orderby;";
put @1 "run;";
put;
put @1 "data &rrguri __head;";
put @1 "  set &rrguri end=eof;";
put @1 "  by &orderby;";
put @1 "  length __datatype $ 8 __suffix  $ 20";
put @1 "  __spanrowtmp __varbylab  __tcol __align __tmp __tmp2 $ 2000";
put @1  %do i=0 %to &numcol; "__col_&i " %end; "  $ 2000 ; ";
put;
put;
put @1 "retain ";
%do i=1 %to &numvars; 
put @4 "__vtype&i";
%end;
put @4 ";";
put;
put @1 "if _n_=1 then do;";
put @1 "  __dsid = open('" "&rrguri" "');";
     %do i=1 %to &numvars;
put @1 "  __vtype&i = upcase(vartype(__dsid, varnum(__dsid, '" "&&alias&i" "')));";
  %end;
put @1 "  __rc = close(__dsid);";
put @1 "end;  ";
put;
put;

put @1 "  __spanrowtmp='';";
put @1 "  __varbylab='';";
put @1 "  __tcol='';";
put @1 "  __varbylab='';";
put @1 "  __suffix='';";
put @1 "  __keepn=0;";
put @1 "  __datatype='TBODY';";
put @1 "  __rowid=_n_;";
put @1 "  __tmp='';";
put @1 "  __tmp2='';";
put;

%if &isspanrow=1 %then %do;
  put @1 "retain __fospanvar;";
  put @1 "if _n_=1 then __fospanvar=0;";
%end;

%if &ispage=1 %then %do;
  put @1 "  %* DEFINE __VARBYGRP;";
  put @1 "    retain __varbygrp 0;";
  %let z = &pvn1;
  %if %length(&&format&z) %then %do;
    put @1 '      __varbylab = cats("' "&&label&z" '"' "||' '||put(&&alias&z, &&format&z));";
  %end;
  %else %if %length(&&decode&z) %then %do;
    put @1 '      __varbylab = cats("' "&&label&z" '"' "||' '||&&decode&z);";
  %end;
  %else %do;

    put @1 "      if __vtype&z = 'C' then  __varbylab = cats(" '"' "&&label&z" '"' "||' '||&&alias&z);";
    put @1 '      else __varbylab = cats("' "&&label&z" '"' "||' '||strip(put(&&alias&z, best.)));";
    
  %end;
 
  %do i=2 %to &numpagev;
    %let z = &&pvn&i;
    %if %length(&&format&z) %then %do;
      put @1 '        __varbylab = cats(__varbylab,"//","' "&&label&z" '"||" "' "||put(&&alias&z, &&format&z));";
    %end;
    %else %if %length(&&decode&z) %then %do;
      put @1 '        __varbylab = cats(__varbylab,"//","' "&&label&z" '"||" "' "||&&decode&z);";
    %end;
    %else %do;
       put @1 "        if __vtype&z = 'C' then __varbylab = " 'cats(__varbylab,"//","' "&&label&z" '"||" "' "||&&alias&z);";
       put @1 '        else __varbylab = cats(__varbylab,"//","' "&&label&z" '"||" "' "||strip(put(&&alias&z, best.)));";

    %end;
      /*
      PUT @1 "     __varbylab = tranwrd(trim(__varbylab), '{','/#123');";
      PUT @1 "     __varbylab = tranwrd(trim(__varbylab), '}','/#125');";
      */
    
  %end;
 
  put @1 "    if first.&lastvb then do;";
  put @1 "       __varbygrp=__varbygrp+1;";
  put @1 "    end;";
  put;
%end;
 
%if &isspanrow=1 %then %do;
 
  put @1 "  %* DEFINE SPAN ROW VARIABLE;";
  put @1 "    __tcol='';";
  %do i=1 %to &numspanv;
    %let z = &&svn&i;
    put @1 "       __tmp = '';";
    %if %length(&&format&z) %then %do;
      put @1 "       __tmp = put(&&alias&z, &&format&z);";
    %end;
    %else %if %length(&&decode&z) %then %do;
      put @1 "       __tmp = &&decode&z;";
    %end;
    %else %do;
       put @1 "       if __vtype&z ='C' then __tmp = &&alias&z;";
       put @1 "       else __tmp = strip(put(&&alias&z, best.));";

    %end;
    %if %length(&&label&z) %then %do;
      /*put @1 "       &&alias&z" ' = cats("' "&&label&z" '")||" "||cats(__tmp);';*/
       put @1 "       __tmp2" ' = cats("' "&&label&z" '")||" "||cats(__tmp);';
    %end;
    
    %else %do;
      put @1 "       &&alias&z" ' = cats(__tmp);';
        put @1 "       __tmp2" ' = cats(__tmp);';
    %end;
    
    %if &i>1 %then %do;
      /*put @1 "          __tcol = cats(__tcol,'//',&&alias&z);";*/
      put @1 "          __tcol = cats(__tcol,'//',__tmp2);";
    %end;
    %else %do;
      /*put @1 "          __tcol = cats(&&alias&z);";*/
      put @1 "          __tcol = cats(__tmp2);";
    %end;
      /*
      PUT @1 "     __tcol = tranwrd(trim(__tcol), '{','/#123');";
      PUT @1 "     __tcol = tranwrd(trim(__tcol), '}','/#125');";
      */

    
   
    %if &&keeptogether&z=Y %then %do;
      put @1 "        if last.&&alias&z then __keepn = 0; else __keepn=1;";
    %end;
    
    
  %end;
 
  put @1 "     if first.&lastspan then do;";
  put @1 "      __fospan=1;";
  put @1 "      __fospanvar+1;";
  put @1 "     end; ";
  put;
%end;
 
put @1 "  %* DEFINE __COL_0, __COL_1 ETC;";
put @1 "  %* DEFINE __ALIGN AND __SUFFIX;";
put @1 "  __align = '';";

%do i=0 %to &numcol;
  %let z = &&vcn&i;
  %if %length(&&format&z) %then %do;
    put @1 "     __col_&i = cats(put(&&alias&z, &&format&z));";
  %end;
  %else %if %length(&&decode&z) %then %do;
    put @1 "     __col_&i = cats(&&decode&z);";
  %end;
  %else %do;
    put @1 "     if __vtype&z='C' then __col_&i = strip(&&alias&z);";
    put @1 "     else __col_&i = strip(put(&&alias&z, best.));";

  %end;
    /*PUT @1 "     __col_&i = tranwrd(trim(__col_&i), '{','/#123');";
    PUT @1 "     __col_&i = tranwrd(trim(__col_&i), '}','/#125');";
    */
  put @1 '     __align = cats(__align)||" "||cats("' "&&align&z" '");';
  %if &&skipline&z=Y %then %do;
    put @1 "        if last.&&alias&z then __suffix = '~-2n';";
  %end;

 
  %if &&group&z=Y %then %do;
    put @1 "        if  first.&&alias&z then __first_&i=1;";
    %if &&keeptogether&z=Y %then %do;
      put @1 "        if last.&&alias&z then __keepn = 0; else __keepn=1;";
    %end;
  %end;



%end;
 
 
 
put @1 "  output &rrguri;";
put;
put @1 "__align='';";
%do i=0 %to &numcol;
%let z = &&vcn&i;
put @1 '     __align = cats(__align)||" "||cats("' "&&halign&z" '");';
%end;
put;
%if &ispage=1 %then %do;
put @1 "  if first.&lastvb then output __head;";
%end;
%else %do;
put @1 "  if eof then do;";
put @1 "     output __head;";
put @1 "  end;";
put;
%end;
 
put @1 "  keep __:;";
put @1 "run;       ";
put;
put;
put;
run;
quit;
 
proc datasets memtype=data;
  delete __rrght;
run; 
quit;
 
%if &java2sas=Y and &append ne Y %then %do;
%__def_list_macros;
%end;

 
%inc "&rrgpgmpath./&rrguri.0.sas";
 
%* add this portion to generated file;
data _null_;
infile "&rrgpgmpath./&rrguri.0.sas" length=len lrecl=1000;
file "&rrgpgmpath./&rrguri..sas" mod lrecl=1000;
length record $ 5000;
input record $varying2000. len;
put record $varying2000. len;
run;

data _null_;
file "&rrgpgmpath./&rrguri.0.sas" ;
put ' ';
run; 
 
 
%* NOTE: THIS CLEARS __VARBYLAB, __SPANROWTMP
VARIABLES UNLESS THIS IS A CHANGE IN THEIR VALUES;
 
%* define breakokat;
%local breakokat;
%do i=0 %to &numcol;
%let z = &&vcn&i;
%if &&break&z=Y %then %do;
%let breakokat=&breakokat &i;
%end;
%end;
 
%* DEFINE LASTHEADID and __gcols and colwidths;
 
%local lastcheadid gcols colwidths stretch dist2next align;
%let lastcheadid=0;
%do i=0 %to &numcol;
%let z = &&vcn&i;
%if &&id&z=Y %then %let lastcheadid=&i;
%if &&group&z=Y %then %let gcols = &gcols &i;
%let colwidths = &colwidths &&width&z;
%let dist2next = &dist2next &&d2n&z;
%let stretch = &stretch &&stretch&z;
%let align = &align &&align&z;

%end;

%local rrgoutpathlazy;
%let rrgoutpathlazy=&rrgoutpath;

data __repinfo;
  set __repinfo;
  lastcheadid=&lastcheadid;
  gcols = cats(symget("gcols"));
  colwidths = cats(symget("colwidths"));
  dist2next = cats(symget("dist2next"));
  stretch = cats(symget("stretch"));
  breakokat = trim(left(symget('breakokat')));
  rtype = 'LISTING';
run;  



data _null_;
file "&rrgpgmpath./&rrguri.0.sas" mod ;
set __repinfo;
%__makerepinfo(outds=&rrguri.0.sas, numcol=&numcol, islist=Y);


 
/* 
data __repinfo0 (rename=(
%do i=1 %to 6; title&i=__title&i %end;
%do i=1 %to 8; footnot&i=__footnot&i %end;
fontsize=__fontsize
indentsize=__indentsize
orient=__orient
nodatamsg =__nodatamsg
font=__font
margins=__margins
shead_l = __shead_l
shead_m=__shead_m
shead_r=__shead_r
sfoot_l=__sfoot_l
sfoot_m=__sfoot_m
sfoot_r=__sfoot_r
papersize=__papersize
sprops = __sprops
sfoot_fs = __sfoot_fs
filename = __filename
pgmname = __pgmname
watermark=__watermark
outformat=__outformat
));
length filename $ 1000;
set __repinfo;
 
length __gcols  __colwidths __stretch  __breakokat $ 2000
__datatype $ 8 __rtype $ 20;
__lastcheadid=&lastcheadid;
__gcols = cats(symget("gcols"));
__colwidths = cats(symget("colwidths"));
__dist2next = cats(symget("dist2next"));
__stretch = cats(symget("stretch"));
__datatype = 'RINFO';
__breakokat = trim(left(symget('breakokat')));
__rtype = 'LISTING';
%if &java2sas=Y %then %do;
filename = strip(filename)||'_j';
%end;
run;
*/ 
 
 
%* DEFINE COLUMN HEADERS;


%local numspan;

data   __head0;
length __datatype $ 8
%do i=0 %to &numcol; __col_&i  __ncol_&i %end;
$ 2000 ;
%do i=0 %to &numcol;
  %let z = &&vcn&i;
  __ncol_&i = cats("&&label&z");
  numspan0 = count(__ncol_&i, '/-/');
  __ncol_&i = tranwrd(cats(__ncol_&i), '/-/', byte(30));
   
  if numspan0>numspan then numspan=numspan0;
%end;
__datatype='HEAD';
call symput('numspan', strip(put(numspan, best.)));
 
if numspan=0 then do;
__rowid=1;
%do i=0 %to &numcol;
__col_&i=cats(__ncol_&i);
%end;
output;
end;
else do;
do __i=numspan+1 to 1 by -1;
%do i=0 %to &numcol;
__col_&i = scan(__ncol_&i, -1*__i, byte(30));
%end;
__rowid=numspan+2-__i;
output;
end;
end;
drop __ncol_:;
run;




%local lasthrid;
proc sql noprint;
  select max(__rowid) into:lasthrid separated by ' ' from __head0;
quit;
 
data _null_;
file "&rrgpgmpath./&rrguri.0.sas" mod lrecl=5000;
put ;
put @1 "data __head0;";
put @1 "length __col_0  - __col_&numcol  $ 2000 __datatype $ 8 ;";
put;
put @1 "__datatype='HEAD';";
run;

data _null_;
file "&rrgpgmpath./&rrguri.0.sas" mod lrecl=5000;
set __head0;
%do i=0 %to &numcol;
put @1 "__col_&i = " '"' __col_&i '";';
%end;
put @1 "__rowid = " __rowid 5. ";";
/*put @1 "__align = '" __align "';";*/
put @1 "output;";
put; 
run;


data _null_;
file "&rrgpgmpath./&rrguri.0.sas" mod lrecl=5000;
 
%if &ispage=1 %then %do;
 
put @1 "data __head;";
put @1 "set __head;";
put @1 "keep __varbygrp __varbylab __ALIGN;";
put @1 "run;";
put; 
%end;
%else %do;
put @1 "data __head;";
put @1 "set __head;";
put @1 "keep __ALIGN;";
put @1 "run;";
put;
%end;
 
put @1 "proc sql noprint;";
put @1 "create table __head1 as select * from";
put @1 "__head0 cross join __head;";
put @1 "quit;";
put;
 
 
 
%if &numspan>0 %then %do;
  put @1 "data __head1;";
  put @1 "set __head1;";
  put @1 "if __rowid<&numspan then do;";
  put @1 "__align = repeat('C ', &numcol);";
  put @1 "end;";
  put @1 "run;";
  put;
%end;
 
 
put @1 "data &rrguri;";
put @1 "set __head1 &&rrguri;";
put @1 "  length __cellfonts __cellborders __title1_cont __label_cont $ 500 __topborderstyle __bottomborderstyle $ 2;";
put @1 "  __cellfonts = '';";
put @1 "  __cellborders = '';";
put @1 "  __topborderstyle='';";
put @1 "  __bottomborderstyle='';";
put @1 "  __label_cont='';";
put @1 "  __title1_cont='';";
put @1 "run;";
put; 
put @1 "proc sort data=&rrguri;";
%if &ispage=1 %then %do; 
put @1 "by   __varbygrp __datatype __rowid;";
%end;
%else %do;
put @1 "by    __datatype __rowid;";
%end;
put @1 "run;";
put;
put @1 "data &rrguri;";
put @1 "set __report &rrguri ;";
put @1 "run;";
put; 
run;

%if %upcase(&finalize) ne Y %then %goto exitlist;

%local savercd gentxt;
proc sql noprint;
  select savercd into:savercd separated by ' ' from __repinfo;
  select gentxt into:gentxt separated by ' ' from __repinfo;
quit;


%local modstr;
%if %upcase(&append)=Y %then %do;
    %let modstr=MOD;
%end;

%if %upcase(&savercd)=Y and %upcase(&finalize)=Y %then %do;
 
  %__savercd;
  
%end;

%if %upcase(&gentxt)=Y and %upcase(&finalize)=Y %then %do;

  %__gentxt;

%end;



data _null_;
file "&rrgpgmpath./&rrguri.0.sas" mod lrecl=5000;
put;
put;
put @1 '%macro rrgout;';
put;
put @1 '  %local objname;';
put;
put @1 "  proc sql noprint;";
put @1 "  select upcase(objname) into:objname from sashelp.vcatalg";
put @1 "  where libname='RRGMACR' and upcase(objname)='__SASSHIATO';";
put @1 "  quit;";
put;
put '%local __path;';
put @1 '%if %length(&rrgoutpath)=0 %then';
put @1 '  %let __path=' "&rrgoutpathlazy;";
put @1 '%else %let __path = &rrgoutpath;';
put;
%if %symexist(__sasshiato_home) %then %do;
put @1 '  %if %symexist(__sasshiato_home) %then %do;';
put @1 '    %if &objname=__SASSHIATO  and  %length(&__sasshiato_home) %then %do;';
%if %upcase(&savexml)=Y %then %do;
 /*put @1 '     %__sasshiato(path=' "%str(&rrgoutpath), debug=&debug, dataset=&rrguri,reptype=L);";*/
 put @1 '   %__sasshiato(path=&__path,' " debug=&debug, dataset=&rrguri, reptype=L);";
%end; 
%else %do;
  put @1 '     %__sasshiato(' "debug=&debug,dataset=&rrguri,reptype=L);";
%end;
put @1 '    %end;';
put @1 '  %end;';
%end;
put;
put @1 '%mend rrgout;';
put;
put @1 '%rrgout;';
run;
 
%inc "&rrgpgmpath./&rrguri.0.sas";
 
%* add this portion to generated file;
data _null_;
infile "&rrgpgmpath./&rrguri.0.sas" length=len lrecl=1000;
file "&rrgpgmpath./&rrguri..sas" mod lrecl=1000;
length record $ 5000;
input record $varying2000. len;
put record $varying2000. len;
run;




data _null_;
file "&rrgpgmpath./&rrguri.0.sas" ;
put ' ';
run; 
 
 
%local fname;
proc sql noprint;
select filename into:fname separated by ' ' from __repinfo;
quit;

 
%*----------------------------------------------------------------------;
%* save metadata;
%*----------------------------------------------------------------------;

%local metadatads;
proc sql noprint;
  select METADATADS into:METADATADS separated by ' ' from __repinfo;
quit;

%if %length(&metadatads)=0 %then %goto skipmeta;

%local useddatasets usedvars tt1 tt2 tt3 tt4 tt5 tt6 i subjid 
       where n_analvar macrosinc1 macrosinc2 ;

 proc sql noprint;
    
    %do i=1 %to 6;
    select strip(title&i) into:tt&i separated by ' ' from __repinfo;
    %end;
    select strip(value) into:macrosinc1 separated by '; '
      from __rrgpgminfo (where =(key='rrg_inc'));
    select strip(value) into:macrosinc2 separated by '; '
      from __rrgpgminfo (where =(key='rrg_call_macro'));

    quit;  

   libname __mout "&rrgoutpath";  

   data __rrginlibs;
    length dataset  $ 2000;
    set __rrginlibs;
    if 0 then dataset='';
   run;
   
   data __usedds;
    set __usedds __repinfo (keep = dataset rename=(dataset=ds)) __rrginlibs(rename=(dataset=ds));
   run;
   
   *--- keep only "permanent datasets" in __usedds;
   
   data  __usedds;
    set __usedds;
    if index(ds, '.')>0;
    run;   
  
  proc sql noprint;
    select distinct scan(ds,1,'(') into:useddatasets separated by '; '  from __usedds;
  quit;
  
  data __vars;
    set __listinfo end=eof;
    length name $ 32;
    name= upcase(alias);
    if name ne '' then output;
    name=upcase(decode);
    if name ne '' then output;
    if eof then do;
      name = upcase(symget("subjid"));
      output;
    end;  
    keep name;
   run;
   
   data __vars2;
    set __usedds;
    length tmp $ 2000 name $ 32;
    tmp  = scan(ds,2,'(');
      do i=1 to length(tmp);
      tmp2 = scan(tmp,i, "!@#$%^&*()+[{-=}]|\:;<,>.?/ ");
      if index(tmp2, '"') ne 1 and index(tmp2, "'") ne 1 then do;
        name = upcase(strip(tmp2));
        if name ne '' then output;
      end;
    end; 
    keep name;
  run;
  
  data __vars;
    set __vars __vars2;
  run;
    
   proc sort data=__vars nodupkey;
      by name;
    run;

   
   
   *------ create list of variables from each used dataset;
   
   %local i numds;
   
   data __usedds;
   set __usedds end=eof;
   length stmt $ 2000;
   ds = scan(ds,1,'( ');
   stmt = "data __tmp; set "||strip(ds)||'; run; proc contents data=__tmp noprint out=__cont'||strip(put(_N_, best.))||
          '; run;  data __cont'||strip(put(_N_, best.))||'; length dsname $ 200; set __cont'||strip(put(_N_, best.))||
          '; dsname = "'||strip(scan(ds,2,'.('))||'";';
   call execute(stmt);
   if eof then call symput('numds', strip(put(_N_, best.)));
   run;
   
   
   data __cont;
    if 0;
   run;
   
   *--- check which variable is in which dataset;
   %if &numds>0 %then %do;
     %do i=1 %to &numds;
          data __cont&i;
            length name $ 32;
            set __cont&i;
            name= upcase(name);
            dsname= upcase(dsname);
            keep name dsname;
          run;
          
          proc sort data=__cont&i nodupkey;
            by name;
          run;
          
          data __cont&i;
            merge __cont&i (in=a) __vars (in=b);
            by name;
            if a and b;
            dsname = strip(dsname)||'.'||strip(name);
          run;
            
          data __cont;
            set __cont __cont&i (keep=dsname);
           run;
     %end;
     
   data __cont;
    set __cont __codebvars;
   run;
  
   proc sort data=__cont nodupkey;
    by dsname;
  run;
   
     proc sql noprint;
      select distinct dsname into:usedvars separated by '; '  from __cont;
     quit;
  
   %end;   
   
 *--- check if metadata file exist, if not then create it ---;

   %if %sysfunc(exist(__mout.&metadatads))=0 %then %do;
     data __mout.&metadatads;
      if 0;
      length rrguri $ 100 datasets variables popwhere tabwhere invarwhere title1-title6 o_where  fname 
             macrosused $ 2000;
      rrguri='';
      datasets='';
      variables='';
      popwhere='';
      tabwhere ='';
      title1='';
      title2='';
      title3='';
      title4='';
      title5='';
      title6='';
      o_where ='';
      invarwhere='';
      fname='';
      macrosused='';
     run; 
   %end;   
   
  *--- if append=n then delete existing entries for the program;
   
   %if %upcase(&append)=N  %then %do;
     data __mout.&metadatads;
      set __mout.&metadatads;
      if rrguri = strip("&rrguri") then delete;
     run; 
   %end; 
   
   *--- insert entries for the program;
   
      data __meta;
        length rrguri $ 100 datasets variables popwhere tabwhere invarwhere title1-title6 o_where fname 
               macrosused tmp1 tmp2 $ 2000;
        rrguri = strip(symget("rrguri"));
        fname =  strip(symget("fname"));
        datasets = strip(symget("useddatasets"));
        variables = strip(symget("usedvars"));
        tabwhere='';
        popwhere='';
        invarwhere='';
        o_where = '';
        %do i=1 %to 6;
          title&i = strip(symget("tt&i"));
        %end;
        macrosused = '';
        tmp1 = strip(symget("macrosinc1"));
        tmp2 = strip(symget("macrosinc2"));
        macrosused = catx('; ',strip(tmp1),strip(tmp2));
        
        drop tmp1 tmp2;
      run;  

      data __mout.&metadatads;
      set __mout.&metadatads __meta;
      run;
      
  

%skipmeta:  
 


%local colstr cl totusedw clearh cntcs;

 
%if &java2sas ne Y %then %goto skippr;
 
%local ps ls;
%let ls = 119;
%let ps = 44;

 
%* determine margins and page size from sasshiato;
%* determine and process column string;


%local rtfstr;
data _null_;
infile "&rrgoutpath./&fname._j_info3.txt" length=len lrecl=5000;
length record $ 5000;
input record $varying2000. len;
call symput('rtfstr', scan(record,4,' '));
call symput('ps', scan(record,3,' '));
call symput('ls', scan(record,2,' '));
run; 

%let ps = %eval(&ps+1);

%*---------------------------------------------------------------------------;
%* calculate widths of columns based on the data available during generation;
%*---------------------------------------------------------------------------;

%local tmp tmpcw0 tmpcw tmp1;
%do i=0 %to &numcol;
  %if %scan(&dist2next,%eval(&i+1), %str( ))=D %then %let tmp = &tmp 1;
  %else %do;
    %let tmp1 = %upcase(%scan(&dist2next,%eval(&i+1), %str( )));
   
    %if %index(&tmp1,CH)>0 %then %let tmp1 =  %sysfunc(tranwrd(&tmp1, CH, %str()));
    %else %if &tmp1<=12 %then %let tmp1=1;
    %let tmp = &tmp &tmp1;
  %end;
  
  %let tmpcw0 = %upcase( %scan(&colwidths,%eval(&i+1), %str( )));
  %if %length(&tmpcw0)=0 %then %let tmpcw=&tmpcw LWH;
  %else %do;
    %if %index(&tmpcw0,'CH')>0 %then %let tmpcw = &tmpcw %sysfunc(tranwrd(&tmpcw0, CH, %str()));
    %else %do;
      %if (&tmpcw0 ne LWH)  and (&tmpcw0 ne LW) and (&tmpcw0 ne NH) and (&tmpcw0 ne N) %then %do;
        %put specified width value &tmpcw0 is not supported and was changed to LWH.;
        %put supported values are N NH LW LWH or XXch where XX is integer (meaning xx characters);
        %let tmpcw0=LWH;
      %end;
      %let tmpcw=&tmpcw &tmpcw0;
    %end;
  
  %end;
%end;

%let dist2next=&tmp;
%let colwidths = &tmpcw;
%if &debug>0 %then %do;

%end;

%__calc_col_wt;

%local nofit er ror;
%let er=ER;
%let ror=ROR;

proc sql noprint;
  select __err into:nofit separated by ' ' from __maxes;
quit;

%if &nofit=1 %then %do;

 %put &er.&ror.: Table can not fit on one page with the specified widths. Program aborted.;
 %goto skippr;
%end;  

data __maxes;
  set __maxes;
  call symput('cl', strip(__cl));
  put 'The column widths are ' __cl;
run;
 
%*-----------------------------------------------------------------------------; 
%* create dataset __colinfo which stores alignments and spacing for each column;
%* and indicator whether this is "first only" column;
%*-----------------------------------------------------------------------------;

data __colinfo;
  length nal $ 20;  
 
%do i=0 %to &numcol;
  colnum=&i;
  focol=0;
  ** first only column;
  %let z = &&vcn&i;
  %local nal&i  __sp&i;
  %if %upcase(&&align&z)=L %then %do; nal='left flow'; %end;
  %if %upcase(&&align&z)=D %then %do; nal='left flow';%end;
  %if %upcase(&&align&z)=C %then %do; nal='center';%end;
  %if %upcase(&&align&z)=R %then %do; nal='right';%end;
  %if &i>0 %then %do; sp = %scan(&dist2next, &i, %str( )); %end;
  %if %upcase(&&group&z)=Y %then %do; focol=1; %end;
  output;
%end; 
run; 

%*********************************************************************************;
%local __fospanvar __spanvar;
%if &isspanrow=1 %then %do;
  %let __fospanvar=__fospanvar __tcol;
  %let __spanvar=__spanvar __tcol;
%end;
 


 
%* determine column headers;
%* assumes all headers are the same in each varby group;
%* this will not work for table;

%local hhasdata;
%let hhasdata=0;
%* hhasdata=1 if there are some header records;
 
data __headers;
set &rrguri;
if __datatype='HEAD';
%if &ispage=1 %then %do;
keep __rowid __varbygrp __col_:;
%end;
%else %do;
keep __rowid __col_:;
%end;
run;
 
data __headers;
set __headers;
if _n_=1 then call symput('hhasdata','1');
run;
 

data __lpp;
  hl=4;
run;



%if &hhasdata=1 %then %do;

  %*---------------------------------------------------------------------; 
  %* process headers - create splits etc;
  %* run fake proc report to determine number of lines for header;
  %* read-in proc report and retrieve number of lines for header;
  %* does not generate code;
  %*---------------------------------------------------------------------; 
  %* limitation: actual data can not have more lines than "duing generation";
  %*---------------------------------------------------------------------; 
  
   %__j2s_ph(ispage=&ispage, numcol=&numcol, fname=&fname, cl =&cl, ls=&ls, ps=&ps);
   
  %* this  step generated  dataset __colstr with split text of "columns" statement;
  %* the individual parts are in variable tmp1;
  %* it also updated __colinfo storing column widths and labels (cw and clab);
  %* and __lpp dataset with hl (number of header lines);
 
%end; 
 

 
%******************************************************************************;
%** process titles and determine number of lines used by titles  and footnotes ;
%*  does not generate code;
%******************************************************************************;
 
%*********************************************************************************;
 
%__j2s_ptf(ls=&ls, hhasdata=&hhasdata, ispage=&ispage);

%******************************************************************************;
%** previous step created files __currtflt, __currtflf, __currtflsh,;
%** __currtflsf (wiht titles, footers, system titles and system footers);
%** and updated __lpp dataset with lpp and lppnh ;
%* (lines per page and lines per page excl. header;
%******************************************************************************;
%* limitation/todo: vabylab: one line, tcols- one line between splits; 
%******************************************************************************; 

%local lpp lppnh;



data __lpp;
  set __lpp;
  call symput('lpp', strip(put(lpp, best.)));
  call symput('lppnh', strip(put(lppnh, best.)));
run;
  
%if &hhasdata=0 %then %do;

%put;
%put RRG INFO: at generation time there was no data to show;
%put;
  
  %****************************************************************;
  %* generate report with "no data" mesage only and no footnotes;
  %****************************************************************;

  data __currtflf;
    if 0;
  run;
 
  data null;
  file "&rrgpgmpath./&rrguri.0.sas" mod ;
  set __report;
  put;
  put;
  put @1 '%macro __nodata;';
  put;
  put @1 '%local __path;';
  put @1 '%if %length(&rrgoutpath)=0 %then';
  put @1 '  %let __path=' "&rrgoutpathlazy;";
  put @1 '%else %let __path = &rrgoutpath;';
  put;
  put @1 "data _null_;";
  put @1 'file "' '&__path./' "&fname..out"  '";' ;
  put @1 "  length line $ &ls;";
  put @1 "  line = repeat('_', &ls-1);";
  put @1 "  put @1 line;";
  put @1 "  put;";
  put @1 '  put "'  __nodatamsg '";';
  put @1 "  put @1 line;";
  put @1 "  put;";
  put @1 "  run;";
  put @1 ;
  put @1 '%mend;';
  put @1 '%__nodata;';
  run;
   
  %goto readrtf;
%end;
 



%*-------------------------------------------------------------------------------------; 
%* generate code to transform data -- create line splits, calc page breaks etc;
%*-------------------------------------------------------------------------------------;




%__j2s_pd(numcol=&numcol, cl=&cl, colwidths=&colwidths, lpp=&lpp, isspanrow=&isspanrow, 
    ispage=&ispage, __spanvar=&__spanvar); 



%*-------------------------------------------------------------------------------------;
%* run proc report;
%*-------------------------------------------------------------------------------------;

/*
  data null;
  file "&rrgpgmpath./&rrguri.0.sas"  mod lrecl=5000;
  put;
  put @1 "proc printto print = '" "&rrgoutpath./&fname..out" "' new;";
  put;
  put;
*/

%__j2s_rpr(ls=&ls, ps=&ps, ispage=&ispage, isspanrow=&isspanrow, __spanvar=&__spanvar);

%*-------------------------------------------------------------------------------------;
%* infile proc report;
%*-------------------------------------------------------------------------------------;
 
%readrtf:

%*-------------------------------------------------------------------------------------;
%* append to &rrguri.0.sas statements to infile proc report and add titles and foots;
%*-------------------------------------------------------------------------------------;

%__j2s_ipr(lppnh=&lppnh, ls=&ls, appendable=&appendable, append=&append);
 
 
%if  %upcase(&appendable) ne Y %then %do; 

  %*-------------------------------------------------------------------------;
  %*** append to &rrguri.0.sas statements to create final RTF file;
  %*-------------------------------------------------------------------------;
  
  %__j2s_cr_rtf(ls=&ls);

%end;




%if %upcase(&appendable) ne Y %then %do;
data _null_;
file "&rrgpgmpath./&rrguri.0.sas" mod lrecl=1000;
put;
put @1 "*-------------------------------------------------;";
put @1 "*  CLEANUP;";
put @1 "*-------------------------------------------------;";
put;
put @1 '%macro __clean;';
put;
put @1 '%local __path;';
put @1 '%if %length(&rrgoutpath)=0 %then';
put @1 '  %let __path=' "&rrgoutpathlazy;";
put @1 '%else %let __path = &rrgoutpath;';
put;
put @1 "data _null_;";
put @1 "fname='tempfile';";

/*put @1 "rc=filename(fname,'" "&rrgoutpath./&rrguri..out0" "');";*/
put @1 'rc=filename(fname,"' '&__path./' "&rrguri..out0" '");';
put @1 "if rc = 0 and fexist(fname) then rc=fdelete(fname);";
put @1 "rc=filename(fname);";
/*put @1 "rc=filename(fname,'" "&rrgoutpath./&rrguri.0.txt" "');";*/
put @1 'rc=filename(fname,"' '&__path./' "&rrguri.0.txt" '");';
put @1 "if rc = 0 and fexist(fname) then rc=fdelete(fname);";
put @1 "rc=filename(fname);";
put @1 "run;";
put;
put @1 '%mend;';
put;
put @1 '%__clean;';
put;
run;

%end;


%*-------------------------------------------------------------------------;
%* add remaining portion (rrguri.0.sas) to generated file (rrguri.sas);
%*-------------------------------------------------------------------------;

data _null_;
infile "&rrgpgmpath./&rrguri.0.sas" length=len lrecl=1000;
file "&rrgpgmpath./&rrguri..sas" mod lrecl=1000;
length record $ 5000;
input record $varying2000. len;
put record $varying2000. len;
run;


%* submit remaining portion;
%inc "&rrgpgmpath./&rrguri.0.sas";

data _null_;
file "&rrgpgmpath./&rrguri.0.sas" ;
put ' ';
run; 

 

 
 
%skippr:




%*-------------------------------------------------------------------------;
%* delete created helper files ;
%*-------------------------------------------------------------------------;


data _null_;
file "&rrgpgmpath./&rrguri.0.sas"  lrecl=1000;
put;
%if %upcase(&appendable) ne Y %then %do;
put @1 '%macro __clean2;';
put;
put @1 '%local __path;';
put @1 '%if %length(&rrgoutpath)=0 %then';
put @1 '  %let __path=' "&rrgoutpathlazy;";
put @1 '%else %let __path = &rrgoutpath;';
put;
put @1 "*-------------------------------------------------;";
put @1 "*  CLEANUP;";
put @1 "*-------------------------------------------------;";
put;
put @1 "data _null_;";
put @1 "fname='tempfile';";

/*put @1 "rc=filename(fname,'" "&rrgoutpath./&fname..out0" "');";*/
put @1 'rc=filename(fname,"' '&__path./' "&fname..out0" '");';
put @1 "if rc = 0 and fexist(fname) then rc=fdelete(fname);";
put @1 "rc=filename(fname);";
/*put @1 "rc=filename(fname,'" "&rrgoutpath./&rrguri.0.txt" "');";*/
put @1 'rc=filename(fname,"' '&__path./' "&rrguri.0.txt" '");';
put @1 "if rc = 0 and fexist(fname) then rc=fdelete(fname);";
put @1 "rc=filename(fname);";

/*put @1 "rc=filename(fname,'" "&rrgoutpath./&fname..out" "');";*/
put @1 'rc=filename(fname,"' '&__path./' "&fname..out" '");';
put @1 "if rc = 0 and fexist(fname) then rc=fdelete(fname);";
put @1 "rc=filename(fname);";
put @1 "run;";
put;
put @1 '%mend;';
put;
put @1 '%__clean2;';
put;
%end;
run;

data _null_;
infile "&rrgpgmpath./&rrguri.0.sas" length=len lrecl=1000;
file "&rrgpgmpath./&rrguri..sas" mod lrecl=1000;
length record $ 5000;
input record $varying2000. len;
put record $varying2000. len;
run;


%* submit remaining portion;
%inc "&rrgpgmpath./&rrguri.0.sas";



data _null_;
fname="tempfile";
** log file;

rc=filename(fname,"&rrgpgmpath./&rrguri.0.sas");
if rc = 0 and fexist(fname) then
rc=fdelete(fname);
rc=filename(fname);


%if &debug<99 %then %do;
  rc=filename(fname,"&rrgoutpath./&fname..dummy");
  if rc = 0 and fexist(fname) then
  rc=fdelete(fname);
  rc=filename(fname);
  
  rc=filename(fname,"&rrgoutpath./&fname._j_info2.txt");
  if rc = 0 and fexist(fname) then
  rc=fdelete(fname);
  rc=filename(fname);
  rc=filename(fname,"&rrgoutpath./&fname._j_info.txt");
  if rc = 0 and fexist(fname) then
  rc=fdelete(fname);
  rc=filename(fname);
  rc=filename(fname,"&rrgoutpath./&fname._j_info3.txt");
  if rc = 0 and fexist(fname) then
  rc=fdelete(fname);
  rc=filename(fname);
  /*
  %if %upcase(&appendable) ne Y %then %do;
  rc=filename(fname,"&rrgoutpath./&fname._j.rtf");
  if rc = 0 and fexist(fname) then
  rc=fdelete(fname);
  rc=filename(fname);
  */
  rc=filename(fname,"&rrgoutpath./&fname..out");
  if rc = 0 and fexist(fname) then
  rc=fdelete(fname);
  rc=filename(fname);
  rc=filename(fname,"&rrgoutpath./&fname..out0");
  if rc = 0 and fexist(fname) then
  rc=fdelete(fname);
  rc=filename(fname);
  rc=filename(fname,"&rrgoutpath./&fname.0.txt");
  if rc = 0 and fexist(fname) then
  rc=fdelete(fname);
  rc=filename(fname);  
%end;
/*
rc=filename(fname,"&rrgoutpath./&rrguri..xml");
if rc = 0 and fexist(fname) then
rc=fdelete(fname);
rc=filename(fname);
*/
 
run;

%exitlist:

%mend;

