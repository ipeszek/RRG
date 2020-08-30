/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */
 
 /* PROGRAM FLOW:
    10Aug2020     
    
    note: this.xxx below refers to macro parameter xxx of this macro; yyy.xxx refers to variable xxx in yyy dataset                                 


AT GENERATION TIME:
=====================
create macro variables dataset, orderby from variables in __REPINFO with the same names

in dataset __LISTINFO:
 create variable __orderby seting it to &orderby
 set variable __fm to 1 for variables whose names match "word" in  __orderby variable
 for variables not in __orderby, issue warning if GROUP, SKIPLINE, SPANROW, KEEPTOGETHER, PAGE are 'Y' and set them to 'N'

create macro variables XXX&i from each recod in __LISTINFO ds where XXX =  label, width, group, spanrow, align, 
  halign, page, id, alias, skipline, decode, format, stretch, keeptogether, breakok (as BREAK), dist2next (as D2N)
  create macro variables java2sas, indentsize from corresponding variables in  __LISTINFO (which are constant in __listinfo???) 

  if page=Y then set spanrow, group and id to blank
  if spanrow=Y then set  group and  id to blank

  set defaults for align (L), halign(=align), width (LW)

  if any of spanrow&i=Y then mv isspanrow=1
  if any of page&i=Y then mv ispage=1
  d2n is not specified then set it to 1 (if &java2sas=Y) or to D otherwise
  if stretch is not N then set it to Y

The following macro variables are defined:
 NUMVARS=number of records in __LISTINFO
 VCN0, VCN1, VCN2 etc where VCNx=column number (in order of invokation of RRG_DEFCOL) with PAGE ne Y and SPANROW ne Y
   (that is, if 1st , 2nd and 4th call of RRG_DEFCOL has PAGE ne Y and SPANROW ne Y, and other calls have
     either PAGE=Y or SPANROW=Y then VCN0=1, VCN1=2, VCN3=4) 
 PVN1, PVN2, PVN3 etc where PVNx= column number with PAGE=Y
 LASTVB=RRG_DEFCOL.name from last invokation of RRG_DEFCOL with page=Y
 SVN1, SVN2, SVN3 etc where SVNx= column number with SPANROW=Y
 LASTSPAN=RRG_DEFCOL.name from last invokation of RRG_DEFCOL with SPANROW=Y
 
If &append ne Y then Write  to &rrgpgmpath./&rrguri..sas all __rrght.record records  and set __rrght to empty  

Start creating &RRGPGMPATH./&RRGURI.0.SAS file :
  write all __rrght.record records 

in this dataset write sas code to do the following:

1. create dummy format $ best which prints ' ' as ' '

2. create datasets &rrguri by sorting input dataset by &ORDERBY
   create macro variable numobs which is 0 if number of records in &rrguri

3. create datasets &rrguri and __head from &rrguri dataset:

    the following is done if &NUMOBS>0:

              ceate variable __VTYPEx=vartype of x-th RRG_DEFCOL.NAME and retain them
              set variables  __spanrowtmp, __varbylab, __tcol, __varbylab, __suffix, __tmp, __tmp2 to ''
                __keepn to 0,       __rowid to _n_,       __datatype to 'TBODY'

                if &isspanrow=1 then  initialize __fospanvar to 0 and retain
                if &ispage='Y' then initialize __varbygrp to 0 and retain
                create variable __varbylab from all variabes with RRG_DEFCOL.PAGE=Y
                   showing RRG_DEFCOL.NAME variable as (1) formatted with RRG_DEFCOL.FORMAT if specified,
                   or (2) as RRG_DEFCOL.DECODE if specified, or (3) just as RRG_DEFCOL.NAME (in this order)
                  prefixed with RRG_DEFCOL.LABEL and space, and concatenating such text from all "PAGE" variables

          4. numcol = number of variables which are neither PAGE nor SPANROW

              increment __varbygrp by 1 on change of &lastvb

              if &isspanrow=1 then:

               create variable __TCOL from all variabes with RRG_DEFCOL.SPANROW=Y
                       showing RRG_DEFCOL.NAME variable as (1) formatted with RRG_DEFCOL.FORMAT if specified,
                       or (2) as RRG_DEFCOL.DECODE if specified, or (3) just as RRG_DEFCOL.NAME (in this order)
                      prefixed with RRG_DEFCOL.LABEL and space, and concatenating such text from all "PAGE" variables,
                      with line break ("//") separating them
                      
                     On change in variable with SPANROW=Y: if first.&lastspan then set __fospan=1 and increment __fospanvar by 1
                      
                      IF RRG_DEFCOL.LABEL is not specified then set name of the variable (specified in rrg_DEFCOL.NAME)
                        to formatted or decoded value (if format or decode is given)
                      
                      Set keepn to 1 and if &keeptogether=Y then set __keepn to 0 on last.name where name=rrg_DEFCOL.NAME
                      
                      For each  variable which  is neither PAGE nor SPANROW
                        create variable __col_x (sequentially starting with 0)
                         showing RRG_DEFCOL.NAME variable as (1) formatted with RRG_DEFCOL.FORMAT if specified,
                         or (2) as RRG_DEFCOL.DECODE if specified, or (3) just as RRG_DEFCOL.NAME (in this order)
                         
                        create variable __align by concatenating RRG_DEFCOL.ALIGN from all such variables
                        
                        if RRG_DEFCOL.SKIPLINE=Y then set __suffix='~-2n' on last.name
                        
                        for each variable witch GROUP=Y:
                          set __first_&i=1 on first.name where  &i is column number of this variable
                          if this variable also has KEEPTOGETHER=Y then on last.name set __keepn = 0 and set __keepn=1 elsewhere
            
            
                OUTPUT to &RRGURI dataset
                
        the following is done regardless of value of  &NUMOBS:
          
             
  
  CREATE records for HEADER:
  
    create __align for header records by concatenating HALIGNx (RRG_DEFCOL.HALIGN) 
    output last record (if no PAGE variables or &numobs=0) or records where 
      last.&LASTVB (if at least one column has PAGE=Y)

SUBMIT the PROGRAM GENERATED SO FAR

add the portion generated so far (&rrgpgmpath./&rrguri.0.sas)
  to final generated program (&rrgpgmpath./&rrguri..sas)

Clear &rrgpgmpath./&rrguri.0.sas

AT PROGRAM GENERATING STEP: 

    create macro variable BREAKOKAT by concatenating all column numbers (space delimited) 
      with &BREAKz  (i.e RRG_DEFCOL.BREAKOKAT =Y)
    create macro variable LASTCHEADID = number of last column with IDz=Y (i.e. RRG_DEFCOL.BREAKOKAT =Y)
    create macro variable GCOLS by concatenating all column numbers (space delimited) 
      with &GROUPz  (i.e RRG_DEFCOL.GROUP =Y)
    create macro variable COLWIDTHS by concatenating all WIDTHz macro varaible (i.e RRG_DEFCOL.WIDTH)
    create macro variable DIST2NEXT by concatenating all D2Nz macro varaible (i.e RRG_DEFCOL.DIST2NEXT)
    create macro variable STRETCH by concatenating all STRETCHz macro varaible (i.e RRG_DEFCOL.STRETCH)
    create macro variable ALIGN by concatenating all ALIGNz macro varaible (i.e RRG_DEFCOL.ALIGN)

    TO DATASET __REPINFO, add variables
      lastcheadid, gcols, colwidths, dist2next, stretch, breakokat (from macro variables above) and rtype = 'LISTING';

call %__makerepinfo(outds=&rrguri.0.sas, numcol=&numcol, islist=Y)
  to create dataset __REPORT with RINFO record for final RCD
  
  Process headers:
  
   AT GENERATION TIME, create dataset __head0 with __datatype='HEAD'.
    The headers are crated based on labels (RRG_DEFCOL.LABEL) and stored in __col_0, __col_1 etc
    If there are no spanned columns (label has "span" separator" "/-/" then __col_0,__col_1 etc are just labels
    If there are spanned columns then for each level of "spanning" a separate row is created
    __rowid variable starts with 1 
    
    Macro variable LASTHRID is the number of levels for headers
    
    Add records to file "&RRGPGMPATH./&RRGURI.0.SAS", to 
    1. create __head0 dataset at runtime,
    which is a copy of __head0 created at generation time, keeping __col_: __rowid and __datatype
    
    2. create dataset __HEAD1 by adding __ALIGN lifted from __HEAD dataset created previously,
        and if there are PAGE variables then cross-join it with all values/display 
        of __VARBYGRP __VARBYLAB from __HEAD dataset. 
        If there are spanned headers then set allignemt of all except last one to "C" 
          (this can be adjusted in rrg_codeafterlist)   
    3. add  __HEAD1 to &rrguri and create variables      
       __cellfonts, __cellborders, __topborderstyle, __bottomborderstyle, __label_cont, __title1_cont
       all set to ''. These are placeholders to be specified if desired in rrg_codeafterlist
    4. ADD __REPORT dataset to &rrguri dataset           
    
    
    THE FOLLOWING STEPS ARE ONLY PERFORMED IF THIS.FINALIZE =Y (DEFAULT)     
    
    add records to &rrgpgmpath./&rrguri.0.sas and to "&rrgpgmpath./&rrguri..sas" to:

    save text version of &rrguri datset (%gentxt), save copy of &rrguri (%savercd),
    if _sasshiato_home macro variable exists and ??? then call sasshiato and save xml if requested  
    call &rrgpgmpath./&rrguri.0.sas program
    clear &rrgpgmpath./&rrguri.0.sas file

    at program-generation, collect metadata info and add to __metadata file
    if java2sas=Y then perform steps to use proc report (DEPRECATED) 
    perform cleanup of created temp files      

*/

%macro rrg_genlist(debug=0, savexml=, finalize=y)/store;
%* note: for now, colsize and dist2next (if in units) shoudl be number of chars if java2sas is used; 
%* assumes __tcol takes only one line between //;
%* assumes varbygrp has only one line;
%* ignores __keepn;

%* Revision notes:  07Apr2014 commented out recoding of curly braces to #123 and #125 (superscript did not work except in header);
%*                  12Aug2020 added handling of no data so that headers and footnotes are displayed 
 
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
 
 %local nodatamsg;
proc sql noprint;
  select nodatamsg into: nodatamsg separated by ' '   from __repinfo;
quit;
  
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

put @1 '%macro dolist;';

put @1 "*---------------------------------------------------------------------;";
PUT @1 "** TRANSFORM DATASET APPLYING FORMATS AND DECODES AS NEEDED;";
put @1 "*---------------------------------------------------------------------;";
PUT;
put @1 "proc sort data=&dataset out = &rrguri;";
put @1 "  by &orderby;";
put @1 "run;";
put;
put @1 "*---------------------------------------------------------------------;";
put @1 "** CHECK IF INPUT DATASET HAS ANY RECORDS ;";
put @1 "*---------------------------------------------------------------------;";
PUT;


put @1 '%local dsid  numobs rc;';
put @1 '  %let dsid = %sysfunc(open(' "&rrguri));";
put @1 '  %let numobs = %sysfunc(attrn(&dsid, nobs));';
put @1 '  %let rc = %sysfunc(close(&dsid));';
put @1 '  %put numobs=&numobs;';




put @1 "data &rrguri __head;";
put @1 '%IF &NUMOBS>0 %then %do;';
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
       put @1 "       __tmp2" ' = cats("' "&&label&z" '")||" "||cats(__tmp);';
    %end;
    
    %else %do;
      put @1 "       &&alias&z" ' = cats(__tmp);';
        put @1 "       __tmp2" ' = cats(__tmp);';
    %end;
    
    %if &i>1 %then %do;
      put @1 "          __tcol = cats(__tcol,'//',__tmp2);";
    %end;
    %else %do;
      put @1 "          __tcol = cats(__tmp2);";
    %end;
   
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
put @1 '%end;';


put @1 '%else %do;';
put @1 "  length  __align  $ 2000;";
put @1 "__varbygrp=.; __varbylab='';";
%do i=0 %to &numcol;
  put @1 "__first_&i=0;";
%end;
/* create "no data" as __tcol;*/
put @1 "__tcol='&nodatamsg';";
put @1 "__col_0=' ';";
put @1 "__datatype='TBODY';";
put @1 "__align='C';";
put @1 "__rowid=1;";


put @1 "  output &rrguri;";

put @1 '%end;';

put;
put @1 "***-------------FOR HEADER: --------------------------------------------***;";
put;



put;
put @1 "__align='';";
%do i=0 %to &numcol;
%let z = &&vcn&i;
put @1 '     __align = cats(__align)||" "||cats("' "&&halign&z" '");';
%end;
put;
%if &ispage=1 %then %do;
  put @1 '%if &numobs>0 %then %do;';
  put @1 "  if first.&lastvb then output __head;";
  put @1 '%end;';
  put @1 '%else %do;';
  put @1 "  output __head;";
  put @1 '%end;';
%end;
%else %do;
    put @1 '%if &numobs>0 %then %do;';
      put @1 "  if eof then do;";
      put @1 "     output __head;";
      put @1 "  end;";
    put @1 '%end;';
    put @1 '%else %do;';
    put @1 "     output __head;";
    put @1 '%end;';
  put;
%end;
 
put @1 "  keep __:;";
put @1 "run;       ";
put;
put '%mend;';
put;
put '%dolist;';
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
 
 
 
%* define breakokat;
%local breakokat;
%do i=0 %to &numcol;
%let z = &&vcn&i;
%if &&break&z=Y %then %do;
%let breakokat=&breakokat &i;
%end;
%end;
 
 
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
*** the following 3 lines seem to have no effect whatsoever;
%__makerepinfo(outds=&rrguri.0.sas, numcol=&numcol, islist=Y);


 
%* DEFINE COLUMN HEADERS;


%local numspan;

data   __head0;
length __datatype $ 8
%do i=0 %to &numcol; __col_&i  __ncol_&i %end;
$ 2000 ;
numspan=0; *** added to account for more than one level;
*** test this;
%do i=0 %to &numcol;
  %let z = &&vcn&i;
  __ncol_&i = cats("&&label&z");
  numspan0 = count(__ncol_&i, '/-/');
  __ncol_&i = tranwrd(cats(__ncol_&i), '/-/', byte(30));
   
  if numspan0>numspan then numspan=numspan0; *** numspan not defined yet?;
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
put @1 "output;";
put; 
run;


data _null_;
file "&rrgpgmpath./&rrguri.0.sas" mod lrecl=5000;
 
%if &ispage=1 %then %do;
 
put @1 "data __head;";
put @1 "set __head;";
/*put @1 '%if &numobs>0 %then %do;';*/
  put @1 "keep __varbygrp __varbylab __ALIGN;";
/*put @1 '%end;';
put @1 '%else %do;';
  put @1 "keep  __ALIGN;";
put @1 '%end;';*/
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

put @1 'rc=filename(fname,"' '&__path./' "&rrguri..out0" '");';
put @1 "if rc = 0 and fexist(fname) then rc=fdelete(fname);";
put @1 "rc=filename(fname);";
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

put @1 'rc=filename(fname,"' '&__path./' "&fname..out0" '");';
put @1 "if rc = 0 and fexist(fname) then rc=fdelete(fname);";
put @1 "rc=filename(fname);";
put @1 'rc=filename(fname,"' '&__path./' "&rrguri.0.txt" '");';
put @1 "if rc = 0 and fexist(fname) then rc=fdelete(fname);";
put @1 "rc=filename(fname);";

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
 
run;






%exitlist:

options msglevel=i;
filename __infile "&rrgpgmpath./&rrguri..sas" lrecl=1000;
filename __outfil " &rrgpgmpath0./&rrguri..sas" lrecl=1000;

data _null_;
  length msg $ 384;
   rc=fcopy('__infile', '__outfil');
   if rc=0 then
      put 'Copied generated program.';
   else do;
      msg=sysmsg();
      put rc= msg=;
   end;
run;

%mend;

