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

%if &isnewtrt=0 %then %do;

    proc sql noprint;
      insert into __rrgpgminfo (key, value, id)
        values("newtrt", "&inc4", 301);
    quit;

%end;

data rrgpgmtmp;
length record $ 2000;
keep record;
record = " ";                                                                                output;  
record =  "data __poph;";                                                                    output;
record =  "set __poph;";                                                                     output;
record =  "if 0 then __fname='';";                                                           output;
record =  "run;";                                                                            output;
record = " ";                                                                                output;
record =  "*--------------------------------------------------------------;";                output;
record =  "%* DETERMINE HOW MANY COLUMNS ARE UNDER EACH TREATMENT ;";                        output;
record =  "%* IN CASE GROUPING VARIABLES HAVE ACROSS=Y;";                                    output;
record =  "%*--------------------------------------------------------------;";               output;
record = " ";                                                                                output;
record = " ";                                                                                output;
%if &ncgrps>0 %then %do;
    record =  '%local numgrps numtrt ovcols;';                                               output;
    record =  "* numgrps=number of columns under each treatment column;";                    output;
    record =  "* numtrt=number of treatment columns;";                                       output;
    record =  "* ovcols=ids of columns with overall statistics ;";                           output;
    record = " ";                                                                            output;
%end;
%else %do;
    record =  '%local numtrt ovcols;';                                                       output;
    record =  "* numtrt=number of treatment columns;";                                       output;
    record =  "* ovcols=ids of columns with overall statistics ;";                           output;
    record = " ";                                                                            output;
%end;
record = " ";                                                                                output;
record =  "proc sql noprint;";                                                               output;
%if &ncgrps>0 %then %do;
    record =  "select count(*) into:numgrps separated by ' ' from ";                         output;
    record =  "  (select distinct &tmpcgrps from __poph);";                                  output;
    record =  '%let numtrt = %sysevalf(&maxtrt/&numgrps);';                                  output;
%end;
%else %do;
    record =  '%let numtrt=&maxtrt;';                                                        output;
%end;
record = " ";                                                                                output;
record =  "*--------------------------------------------------------------;";                output;
record =  "* DETERMINE WHICH COLUMNS ARE FOR OVERALL STATISTICS;";                           output;
record =  "*--------------------------------------------------------------;";                output;
record = " ";                                                                                output;
record =  "select distinct __trtid into:ovcols separated by ' '";                            output;
record =  "   from __poph(where=(__overall=1));";                                            output;
record = " ";                                                                                output;
record =  "quit;  ";                                                                         output;
record = " ";                                                                                output;
record = " ";                                                                                output;
record =  "*----------------------------------------------------------;";                    output;
record =  "* DETERMINE DISPLAY VALUES OF TREATMENT VARIABLES; ";                             output;
record =  "*----------------------------------------------------------;";                    output;
record = " ";                                                                                output;
record =  "proc sql noprint;";                                                               output;
record =  "  create table __trtdisp as select distinct";                                     output;
%local tmp;                                                                                  
%let tmp = %sysfunc(compbl(__fname &trtvar  &varby));                                        
%let tmp = %sysfunc(tranwrd(&tmp, %str( ), %str(,)));                                        
record =  "   &tmp, tranwrd(__col,'//', ' ') as __grplabel___tmptrtvar";                     output;
record =  "   from __poph(where=(__rowid=1))";                                               output;
record =  "   order by  &tmp;";                                                              output;
record =  "quit;";                                                                           output;
record = " ";                                                                                output;
record =  "data __trtdisp;";                                                                 output;
record =  "  set __trtdisp;";                                                                output;
record =  "  by __fname &trtvar  &varby;";                                                   output;
record =  " retain __tmptrtvar;";                                                            output;
record =  "if _n_=1 then __tmptrtvar=0;";                                                    output;
record =  "if first.&trtvar then  __tmptrtvar+1;";                                           output;
record =  " __order___tmptrtvar=__tmptrtvar;";                                               output;
record =  "run;";                                                                            output;
record = " ";                                                                                output;
record =  '%local numptrt;';                                                                 output;
record =  'proc sql noprint;';                                                               output;
record =  "select max(__tmptrtvar) into:numptrt separated by ' '";                           output;
record =  "from __trtdisp (where=(__fname=''));";                                            output;
record =  "quit;";                                                                           output;
record = " ";                                                                                output;
record =  "proc sort data=__trtdisp;";                                                       output;
record =  "by &varby __tmptrtvar;";                                                          output;
record =  "run;";                                                                            output;
record = " ";                                                                                output;
record =  "*----------------------------------------------------------;";                    output;
record =  "* TRANSPOSE DATASET TO PUT TREATMENT IN ROWS;";                                   output;
record =  "*----------------------------------------------------------;";                    output;
record = " ";                                                                                output;
record =  '%local  i j;';                                                                    output;
record = " ";                                                                                output;
record =  "data __all;";                                                                     output;
record =  "  length __tmpalign $ 2000;";                                                     output;
record =  "  set __all;";                                                                    output;
record =  "  __tmpalign =__align;";                                                          output;
record =  "__indentlev =__indentlev+1;";                                                     output;
%if &ncgrps>0 %then %do;                                                                     
    record =  '  __isval=0;';                                                                output;
    record =  '  __tmptrtvar= 1;';                                                           output;
    record =  '  output;';                                                                   output;
    record =  '  %do j=2 %to &numptrt;';                                                     output;
    record =  '    __tmptrtvar = &j;';                                                       output;
    record =  "    __align = scan(__tmpalign,1,' ');";                                       output;
    record =  '    %do i=1 %to &numgrps;';                                                   output;
    record =  '       __col_&i = __col_%eval(&i+(&j-1)*&numgrps);'; output;
    record =  "     __align = cats(__align)||' '||scan(__tmpalign,"||
                        '%eval(&i+(&j-1)*&numgrps+1),'|| "' ');";output;
    record =  '    %end;';output;
    record =  '    output;';output;
    record =  '  %end;';output;
    record =  '  %do j=%eval(&numptrt+1) %to &numtrt;';output;
    record =  "   __fname='OVRL';";output;
    record =  "   __col_0 = __varlabel;";output;
    record =  "   __varlabel='';";output;
    record =  '    __tmptrtvar = &j;';output;
    record =  "    __align = scan(__tmpalign,1,' ');";output;
    record =  '    %do i=1 %to &numgrps;';output;
    record =  '       __col_&i = __col_%eval(&i+(&j-1)*&numgrps);';output;
    record =  "     __align = cats(__align)||' '||scan(__tmpalign," ||'%eval(&i+(&j-1)*&numgrps+1),'|| "' ');";output;
    record =  '       if __col_&i '|| " ne '' then __isval=1;"; output;
    record =  '    %end;';output;
    record =  '    if __isval=1 then output;';output;
    record =  '  %end;';output;
    record =  ' %if &numptrt>1 %then %do;';output;
    record =  '  drop  __col_%eval(&numgrps+1)-__col_&maxtrt;';output;
    record =  ' %end;';output;
    record =  '  drop __isval ;';output;
%end;
  
%else %do;
    record =  '    %do j=1 %to &numptrt;';output;
    record =  '      __tmptrtvar = &j;';output;
    record =  '      __col_1 = __col_&j;';output;
    record =  "      __align = scan(__tmpalign,1,' ');";output;
    record =  "      __align = cats(__align)||' '||scan(__tmpalign,"|| '%eval(&j+1),'|| "' ');";output;
    record =  '      output;';output;
    record =  '    %end;  ';output;
    record =  '  %do j=%eval(&numptrt+1) %to &numtrt;';output;
    record =  "    __fname='OVRL';";output;
    %if "&sta" ne "Y" %then %do;
        record =  "    __col_0 = __varlabel;";output;
        record =  "    __varlabel='';";output;
    %end;
    %else %do;
        record =  "    __col_0 = '';";output;
    %end;
    record =  '    __tmptrtvar = &j;';output;
    record =  "    __align = scan(__tmpalign,1,' ');";output;
    record =  '    __col_1 = __col_&j;';output;
    record =  "    __align = cats(__align)||' '||scan(__tmpalign," ||'%eval(&j+1),'|| "' ');";output;
    record =  '    if __col_&j ' ||" ne '' then output;"; output;
    record =  '  %end;';output; 
    record =  '  %if &maxtrt>2 %then %do;              ';output;
    record =  '    drop __col_2-__col_&maxtrt;         ';output;
    record =  '  %end;                                 ';output;
    record =  '  %else %if &maxtrt=2 %then %do;        ';output;
    record =  '    drop __col_2;                       ';output;
    record =  '  %end;                                 ';output;
   
    
%end;
  
record =  'run;  ';output;
record = " ";output;
record =  '*----------------------------------------------------------;';output;
record =  '* ADD DISPLAY VARIABLES for TREATMENT;';output;
record =  '%*----------------------------------------------------------;';output;
record = " ";output;
record =  "proc sort data=__all;";output;
record =  "by &varby __tmptrtvar;";output;
record =  "run;";output;
record = " ";output;

record =  "data __all;";output;
record =  "merge __all __trtdisp ;";output;
record =  "by &varby __tmptrtvar;";output;
record =  "if __fname='OVRL' then do;";output;
record =  "   __vtype='OV';";output;
record =  "   __order=999999999;";output;
record =  " end;";output;
record =  "run;";output;
record = " ";output;
record =  '*-------------------------------------------------------------------------;';output;
record =  '* UPDATE HEADER;';output;
record =  '*-------------------------------------------------------------------------;';output;
record = " ";output;
%if &ncgrps>0 %then %do;
    record =  'data __poph;';output;
    record =  '  set __poph;';output;
    record =  '  if __rowid>1 and __trtid<=&numgrps;';output;
    record =  "  drop &trtvar __dec_&trtvar __suff_&trtvar ";output;
    record =  "       __prefix_&trtvar __nline_&trtvar;";output;
    record =  'run;';output;
    record = " ";output;
    record =  'data __poph;';output;
    record =  '  set __poph;';output;
    record =  '  __rowid=__rowid-1;';output;
    record =  'run;';output;
%end;
%else %do;
    record =  "data __poph;";output;
    record =  "    set __poph;";output;
    record =  "    if __trtid=1;";output;
    record =  "    __col='';";output;
    record =  "  run;";output;
%end;
record = " ";output;


record = " ";output;
record =  "*--------------------------------------------;";output;
record =  "*** UPDATE BREAKOKAT MACRO PARAMETER;";output;
record =  "*--------------------------------------------;";output;
record = " ";output;
%if &ncgrps<=1 %then %do;
    record =  '%let breakokat=;';output;
%end;
%else %do;
    %local breakvar;
    %let breakvar = %scan(&cgrps,-2, %str( ));

    record =  "proc sort data=__poph;";output;
    record =  "by &cgrps ;";output;
    record =  "run;";output;
    record=" ";output;
    record =  "data __poph;";output;
    record =  "  set __poph;";output;
    record =  "by &cgrps ;";output;
    record =  "  __cb=.;";output;
    record =  "  if first.&breakvar then __cb=1;";output;
    record =  "run;";output;
    record=" ";output;
    record =  "proc sort data=__poph;";output;
    record =  "  by __trtid;";output;
    record =  "run;";output;
    record = " ";output;
    record=" ";output;
    record =  "proc sql noprint;";output;
    record =  "  select __trtid into:breakokat separated by ' ' ";output;
    record =  '    from __poph(where=(__cb=1));';output;
    record =  "quit;";output;
    record = " ";output;
    record=" ";output;
%end;
record = " ";output;
%if &ncgrps=0 %then %do;
    record =  '%let maxtrt = 1;';output;
%end;
%else %do;
    record =  '%let maxtrt = &numgrps;';output;
%end;
record = " ";output;
run;


proc append data=rrgpgmtmp base=rrgpgm;
run;




%* todo: adjust nline;

%skip:
%mend;

