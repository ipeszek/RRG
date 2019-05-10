/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __transposet(
  varby=,
  groupby=,
  trtvar=,
  sta=)/store;

%* transposes RCD to place treatment in rows;  



%local varby dsin groupby trtvar isacross sta;


%local i nnotcgrps notcgrps notinc2 cgrps ncgrps tmp inc4;
%let nnotcgrps=0;
%let ncgrps=0;
proc sql noprint;
 select upcase(name), varid into
     :isacross separated by ' ',
     :tmp separated by ' '
      from __varinfo 
      (where =((type='TRT' and upcase(across) = 'N' 
          )))
      order by varid;      
 
 select upcase(name), varid into
     :notcgrps separated by ' ',
     :tmp separated by ' '
      from __varinfo 
      (where =((type='GROUP' and upcase(across) ne 'Y' 
          and upcase(page) ne 'Y')or type='TRT' and upcase(across)='N'))
      order by varid;      
 select upcase(name),varid into 
     :cgrps separated by ' ',
     :tmp separated by ' '  
     from __varinfo (where =(type='GROUP' and upcase(across)='Y' 
       and upcase(page) ne 'Y'))
     order by varid;      
quit;  



%if %length(&isacross)=0 %then %goto skip;

%if %length(&notcgrps) %then %do;
  %let nnotcgrps = %sysfunc(countw(&notcgrps, %str( )));
%end;
%if %length(&cgrps) %then %do;
  %let ncgrps = %sysfunc(countw(&cgrps, %str( )));
%end;


%do i=1 %to &nnotcgrps;
  %let tmp = %scan(&notcgrps, &i, %str( ));
  %if %upcase(&tmp)=%upcase(&trtvar) %then 
    %let notinc2 = &notinc2 __order___tmptrtvar __tmptrtvar;
  %else %let notinc2 = &notinc2 __order_&tmp &tmp ;  
%end;  

%do i=1 %to &ncgrps;
  %let tmp = %scan(&cgrps, &i, %str( ));
  %let inc4 = &inc4 __order_&tmp &tmp ;
%end;  
%local tmpcgrps;
%if %length(&cgrps) %then %do;
%let tmpcgrps = %sysfunc(compbl(&cgrps));
%let tmpcgrps = %sysfunc(tranwrd(&tmpcgrps, %str( ), %str(,)));
%end;

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put @1 "data __poph;";
put @1 "set __poph;";
put @1 "if 0 then __fname='';";
put @1 "run;";
put;
put @1 "*--------------------------------------------------------------;";
put @1 "%* DETERMINE HOW MANY COLUMNS ARE UNDER EACH TREATMENT ;";
put @1 "%* IN CASE GROUPING VARIABLES HAVE ACROSS=Y;";
put @1 "%*--------------------------------------------------------------;";
put;
put;
%if &ncgrps>0 %then %do;
put @1 '%local numgrps numtrt ovcols;';
put @1 "* numgrps=number of columns under each treatment column;";
put @1 "* numtrt=number of treatment columns;";
put @1 "* ovcols=ids of columns with overall statistics ;";
put;
%end;
%else %do;
put @1 '%local numtrt ovcols;';
put @1 "* numtrt=number of treatment columns;";
put @1 "* ovcols=ids of columns with overall statistics ;";
put;
%end;
put;
put @1 "proc sql noprint;";
%if &ncgrps>0 %then %do;
put @1 "select count(*) into:numgrps separated by ' ' from ";
put @1 "  (select distinct &tmpcgrps from __poph);";
put @1 '%let numtrt = %sysevalf(&maxtrt/&numgrps);';
%end;
%else %do;
put @1 '%let numtrt=&maxtrt;';
%end;
put;
put @1 "*--------------------------------------------------------------;";
put @1 "* DETERMINE WHICH COLUMNS ARE FOR OVERALL STATISTICS;";
put @1 "*--------------------------------------------------------------;";
put;
put @1 "select distinct __trtid into:ovcols separated by ' '";
put @1 "   from __poph(where=(__overall=1));";
put;
put @1 "quit;  ";

put;
put;
put @1 "*----------------------------------------------------------;";
put @1 "* DETERMINE DISPLAY VALUES OF TREATMENT VARIABLES; ";
put @1 "*----------------------------------------------------------;";
put;


put @1 "proc sql noprint;";
put @1 "  create table __trtdisp as select distinct";
%local tmp;
%let tmp = %sysfunc(compbl(__fname &trtvar  &varby));
%let tmp = %sysfunc(tranwrd(&tmp, %str( ), %str(,)));
put @1 "   &tmp, tranwrd(__col,'//', ' ') as __grplabel___tmptrtvar";
put @1 "   from __poph(where=(__rowid=1))";
put @1 "   order by  &tmp;";
put @1 "quit;";
put;
put @1 "data __trtdisp;";
put @1 "  set __trtdisp;";
put @1 "  by __fname &trtvar  &varby;";
put @1 " retain __tmptrtvar;";
put @1 "if _n_=1 then __tmptrtvar=0;";
put @1 "if first.&trtvar then  __tmptrtvar+1;";
put @1 " __order___tmptrtvar=__tmptrtvar;";
put @1 "run;";
put;
put @1 '%local numptrt;';
put @1 'proc sql noprint;';
put @1 "select max(__tmptrtvar) into:numptrt separated by ' '";
put @1 "from __trtdisp (where=(__fname=''));";
put @1 "quit;";
put;
put @1 "proc sort data=__trtdisp;";
put @1 "by &varby __tmptrtvar;";
put @1 "run;";
put;
put @1 "*----------------------------------------------------------;";
put @1 "* TRANSPOSE DATASET TO PUT TREATMENT IN ROWS;";
put @1 "*----------------------------------------------------------;";
put;
put @1 '%local  i j;';
put;
put @1 "data __all;";
put @1 "  length __tmpalign $ 2000;";
put @1 "  set __all;";
put @1 "  __tmpalign =__align;";
put @1 "__indentlev =__indentlev+1;"; 
  %if &ncgrps>0 %then %do;
put @1 '  __isval=0;';
put @1 '  __tmptrtvar= 1;';
put @1 '  output;';
put @1 '  %do j=2 %to &numptrt;';
put @1 '    __tmptrtvar = &j;';
put @1 "    __align = scan(__tmpalign,1,' ');";
put @1 '    %do i=1 %to &numgrps;';
put @1 '       __col_&i = __col_%eval(&i+(&j-1)*&numgrps);';
put @1 "     __align = cats(__align)||' '||scan(__tmpalign," '%eval(&i+(&j-1)*&numgrps+1),' "' ');";
put @1 '    %end;';
put @1 '    output;';
put @1 '  %end;';
put @1 '  %do j=%eval(&numptrt+1) %to &numtrt;';
put @1 "   __fname='OVRL';";
put @1 "   __col_0 = __varlabel;";
put @1 "   __varlabel='';";
put @1 '    __tmptrtvar = &j;';
put @1 "    __align = scan(__tmpalign,1,' ');";
put @1 '    %do i=1 %to &numgrps;';
put @1 '       __col_&i = __col_%eval(&i+(&j-1)*&numgrps);';
put @1 "     __align = cats(__align)||' '||scan(__tmpalign," '%eval(&i+(&j-1)*&numgrps+1),' "' ');";
put @1 '       if __col_&i ' " ne '' then __isval=1;"; 
put @1 '    %end;';
put @1 '    if __isval=1 then output;';
put @1 '  %end;';
put @1 ' %if &numptrt>1 %then %do;';
put @1 '  drop  __col_%eval(&numgrps+1)-__col_&maxtrt;';
put @1 ' %end;';
put @1 '  drop __isval ;';
  %end;
  
  %else %do;
put @1 '    %do j=1 %to &numptrt;';
put @1 '      __tmptrtvar = &j;';
put @1 '      __col_1 = __col_&j;';
put @1 "      __align = scan(__tmpalign,1,' ');";
put @1 "      __align = cats(__align)||' '||scan(__tmpalign," '%eval(&j+1),' "' ');";
put @1 '    output;';
put @1 '    %end;  ';
put @1 '  %do j=%eval(&numptrt+1) %to &numtrt;';
put @1 "    __fname='OVRL';";
%if "&sta" ne "Y" %then %do;
put @1 "    __col_0 = __varlabel;";
put @1 "    __varlabel='';";
%end;
%else %do;
put @1 "    __col_0 = '';";
%end;
put @1 '    __tmptrtvar = &j;';
put @1 "    __align = scan(__tmpalign,1,' ');";
put @1 '    __col_1 = __col_&j;';
put @1 "    __align = cats(__align)||' '||scan(__tmpalign," '%eval(&j+1),' "' ');";
put @1 '    if __col_&j ' " ne '' then output;"; 
put @1 '  %end;';
put @1 '  drop __col_2-__col_&maxtrt;';
  %end;
  
put @1 'run;  ';
put;
put @1 '*----------------------------------------------------------;';
put @1 '* ADD DISPLAY VARIABLES for TREATMENT;';
put @1 '%*----------------------------------------------------------;';
put;
put @1 "proc sort data=__all;";
put @1 "by &varby __tmptrtvar;";
put @1 "run;";
put;

put @1 "data __all;";
put @1 "merge __all __trtdisp /*(drop =__fname)*/;";
put @1 "by &varby __tmptrtvar;";
put @1 "if __fname='OVRL' then do;";
put @1 "   __vtype='OV';";
put @1 "   __order='999999999';";
put @1 " end;";
put @1 "run;";
put;

put @1 '*-------------------------------------------------------------------------;';
put @1 '* UPDATE HEADER;';
put @1 '*-------------------------------------------------------------------------;';
put;
%if &ncgrps>0 %then %do;
put @1 'data __poph;';
put @1 '  set __poph;';
put @1 '  if __rowid>1 and __trtid<=&numgrps;';
put @1 "  drop &trtvar __dec_&trtvar __suff_&trtvar ";
put @1 "       __prefix_&trtvar __nline_&trtvar;";
put @1 'run;';
put;
put @1 'data __poph;';
put @1 '  set __poph;';
put @1 '  __rowid=__rowid-1;';
put @1 'run;';
%end;
%else %do;
put @1 "data __poph;";
put @1 "    set __poph;";
put @1 "    if __trtid=1;";
put @1 "    __col='';";
put @1 "  run;";
%end;
put;
run;

%*-------------------------------------------------------------------------;
%* UPDATE GROUPING VARIABLES;
%*-------------------------------------------------------------------------;

%local isnewtrt;
%let isnewtrt=0;
data __rrgpgminfo;
  set __rrgpgminfo;
  if key = "newgroupby" then value = "&notinc2";
  if key = "newtrt" then do;
    call symput('isnewtrt', '1');
    value = trim(left(value));
    if upcase(value) = upcase("&trtvar") then value = '';
    else if scan(upcase(value),1,' ')=upcase("&trtvar") then
       value = substr(value, length("&trtvar")+1);
  end;
run;

*** todo : what will happen if no treatment variable/no column groups?;

%if &isnewtrt=0 %then %do;

proc sql noprint;
  insert into __rrgpgminfo (key, value, id)
    values("newtrt", "&inc4", 301);
quit;

%end;




data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;  
put;
put @1 "*--------------------------------------------;";
put @1 "*** UPDATE BREAKOKAT MACRO PARAMETER;";
put @1 "*--------------------------------------------;";
put;
%if &ncgrps<=1 %then %do;
put @1 '%let breakokat=;';
%end;
%else %do;
%local breakvar;
%let breakvar = %scan(&cgrps,-2, %str( ));

put @1 "proc sort data=__poph;";
put @1 "by &cgrps ;";
put @1 "run;";
put ;
put @1 "data __poph;";
put @1 "  set __poph;";
put @1 "by &cgrps ;";
put @1 "  __cb=.;";
put @1 "  if first.&breakvar then __cb=1;";
put @1 "run;";
put ;
put @1 "proc sort data=__poph;";
put @1 "  by __trtid;";
put @1 "run;";
put;
put ;
put @1 "proc sql noprint;";
put @1 "  select __trtid into:breakokat separated by ' ' ";
put @1 '    from __poph(where=(__cb=1));';
put @1 "quit;";
put;
put ;
%end;
put;
%if &ncgrps=0 %then %do;
put @1 '%let maxtrt = 1;';
%end;
%else %do;
put @1 '%let maxtrt = &numgrps;';
%end;
put;
run;



%* todo: adjust nline;

%skip:
%mend;

