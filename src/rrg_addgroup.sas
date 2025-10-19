/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

/* 22May2019: added ordervar;*/

%macro rrg_addgroup(
name=,
label=,
stat=,
page=,
popsplit=,
decode=,
incolumns=,
codelist=,
codelistds=,
delimiter=%str(,),
nline=N,
sortcolumn=,
freqsort=,
autospan=,
skipline=,
preloadfmt=,
across=N,
incolumn=,
colhead=,
mincnt=,
minpct=,
ordervar=,
eventcnt=,
aegroup=,
cutoffval=,
cutofftype=

)/store;


%* note stat parameter seems to be never used;

%local name label stat page decode incolumns  codelist codelistds delimiter nline 
     sortcolumn freqsort autospan preloadfmt across incolumn colhead mincnt minpct
     popsplit eventcnt ordervar
     aegroup cutoffval cutofftype ;

%put STARTING RRG_ADDGROUP USING VARIABLE &NAME;

%if %upcase(&incolumns)=Y %then %let page=;
%if %upcase(&across)=Y %then %let page=;
%if %length(&incolumns)>0 %then %let across=&incolumns;
%if &skipline = 1 %then %let skipline=Y;

%if %upcase(&page) = Y and %length(&popsplit)=0 %then %let popsplit=Y;
%if %upcase(&aegroup) ne N %then %let aegroup=Y;


%if %length(&codelistds) %then %do;
  
  %local __name_type __decode_type;
  
  data __tmp;
  set &codelistds ;
  if _n_=1 then do;
    call symput('__name_type',vtype(&name));
    call symput('__decode_type',vtype(&decode));
  end;
  run;

   %if &__name_type=N and &__decode_type=N %then %do;
      proc sql noprint;
      select  strip(put(&name, best.))||'='||quote(strip(put(&decode, best.)))
      into: codelist separated by "&delimiter"
      from &codelistds;
      quit;
   %end;
   %else %if &__name_type=N and &__decode_type=C %then %do;
      proc sql noprint;
      select  strip(put(&name, best.))||'='||quote(strip(&decode))
      into: codelist separated by "&delimiter"
      from &codelistds;
      quit;
   %end;
   %else %if &__name_type=C and &__decode_type=N %then %do;
      proc sql noprint;
      select  quote(strip(&name))||'='||quote(strip(put(&decode, best.)))
      into: codelist separated by "&delimiter"
      from &codelistds;
      quit;
   %end;
   %else %if &__name_type=C and &__decode_type=C %then %do;
      proc sql noprint;
      select  quote(strip(&name))||'='||quote(strip(&decode))
      into: codelist separated by "&delimiter"
      from &codelistds;
      quit;
   %end;

  
%end;  

%if %length(&preloadfmt) %then %do;

    proc format cntlout=__fmtxxx;
    run;
    
    %local  nc delim;
    
    data __tmp1;
    set __fmtxxx;
    
    if upcase(fmtname)=compress(upcase("&preloadfmt"),'$.');
    length __ns $ 200;
    
    if type='N' then __ns = cats(start,"=",quote(cats(label)));
    else if type='C' then __ns = cats(quote(strip(start)),"=",quote(cats(strip(label))));
    if start ='**OTHER**' and index(hlo,'O')>0 then delete;
    run;
    
    %local found delim startchar;
    %let found=0;
    %let startchar=31;
    
    %*** DETERMINE A CHARACTER THAT CAN BE USED AS DELIMITER;
    
    data __tmp2;
    set __tmp1;
    do __i=1 to length(__ns);
    __x = rank(substr(__ns,__i,1));
    output;
    end;
    run;
    
    proc sort data=__tmp2 nodupkey out=__tmp3;
    by __x;
    run;
    
    data __tmp4;
    do __x = 33 to 127;
    if __x not in (34, 37, 38, 39, 40,41,44) then output;
    end;
    run;
    
    proc sort data=__tmp4;
    by __x;
    run;
    
    
    data __tmp5;
    merge __tmp4(in=a) __tmp3(in=b);
    by __x;
    if a and not b;
    run;
    
    data __tmp5;
    set __tmp5;
    if _n_=1;
    call symput("delim", cats(byte(__x)));
    run;
    
    %if %length(&delim) %then %do;
    
      proc sql noprint;
       select cats(__ns) into:nc separated by "&delim" from __tmp1;
      quit;
    
      %if %length(&nc)=0 %then %do;
         %put WAR%str()NING: specified PRELOADFMT (&preloadfmt) not found;
      %end;
    
    %end;
    
    %else %do;
       %put WAR%str()NING: could not find a character to use as delimiter, all characters used already;
    %end;
    
    %if %length(&delim) and %length(&nc) %then %do;
      %let codelist = %nrbquote(&nc); 
      %let codelistds=;
      %let templateds=;
      %let delimiter= %str(&delim);
    %end;

%end;



%__rrgaddgenvar(
name=%nrbquote(&name),
label=%nrbquote(&label),
decode=%nrbquote(&decode),
type=GROUP,
page=&page,
popsplit=&popsplit,
stat=&stat,
nline=&nline,
codelist=%nrbquote(&codelist),
delimiter = %nrbquote(&delimiter),
outds=__varinfo,
across=&across,
incolumn=&incolumn,
freqsort=%nrbquote(&freqsort),
colhead=%nrbquote(&colhead),
autospan=%nrbquote(&autospan),
skipline=%nrbquote(%upcase(&skipline)),
preloadfmt = %nrbquote(&preloadfmt),
sortcolumn=&sortcolumn,
mincnt=%nrbquote(&mincnt),
minpct=%nrbquote(&minpct),
eventcnt=%upcase(&eventcnt),
aegroup=%upcase(&AEGROUP),
cutoffval=&cutoffval,
cutofftype=&cutofftype
/*,
ordervar=&ordervar
*/
);





%put RRG_ADDGROUP USING VARIABLE &NAME COMPLETED SUCESSULLY;


%mend;
