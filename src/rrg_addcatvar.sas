/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro rrg_addcatvar(
Where=,
popwhere=,
popgrp=,
totalgrp=,
totalwhere=,
name=,
label=,
totalpos=last,
misspos=,
totaltext=,
misstext=,
countwhat=all,
suffix=,
stats=NPCT, 
overallstats=,
skipline=Y,
indent=0,
denom=,
denomgrp=,
denomwhere=,
fmt=, 
worst=,
events=n,
decode=,
codelist=,
codelistds=,
templateds=,
freqsort=,
sortcolumn=,
mincnt=,
minpct=,
labelline=1,
delimiter=%str(,),
ordervar=,
subjid=,
showgroupcnt=N,
showemptygroups=N,
pct4missing=,
pct4total=n,
pctfmt=%nrbquote(__rrgp1d.),
preloadfmt=,
showmissing=,
keepwithnext=N,
templatewhere=,
desc=,
remove=,
DENOMINClTRT=Y,
show0cnt=y,
noshow0cntvals=)/store;

%* NOTE: POPGRP MUST BE A SUBSET OF TOTALGRP AND TOTALGRP MUST BE A SUBSET OF GROUPVARS (WITHOUT PAGEBY VARS);

%* events parameter seems to be never used;
%* same for templateds;

%local where popwhere  popgrp  name  label  totalpos last totaltext  countwhat  
       suffix  stats skipline indent denom  denomwhere  fmt   worst  events 
       decode  codelist  codelistds  templateds  freqsort  mincnt  minpct  
       delimiter ordervar showgroupcnt showemptygroups showmissing pctfmt 
       overallstats sortcolumn preloadfmt labelline pct4missing totalgrp
       totalwhere  subjid misspos misstext denomgrp keepwithnext templatewhere
       desc remove DENOMINClTRT show0cnt noshow0cntvals pct4total;

%PUT STARTING RRG_ADDCATVAR USING VARIABLE &NAME;


%if %length(&denom) %then %let denomgrp=&denom;

%if %length(&preloadfmt) %then %do;

 
    
    proc format cntlout=__fmtxxx;
    run;
    
    %local  nc delim;
    
    data __tmp1;
    set __fmtxxx;
    if upcase(fmtname)=compress(upcase("&preloadfmt"),'$.');
    length __ns $ 200;
    if type='N' then __ns = cats(start,"=",quote(cats(label)));
    else if type='C' then __ns = cats(quote(start),"=",quote(cats(label)));
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

%if %length(&pct4missing)=0 or   %length(&pct4total)=0 or   %length(&showmissing)=0  %then %do;
  data _null_;
    set __rrgconfig(where=(type='[D1]'));
    %if %length(&pct4missing)=0 %then %do;
      if lowcase(w1)='pct4missing' then call symput(w1,w2);
    %end;
    %if %length(&pct4total)=0 %then %do;
      if lowcase(w1)='pct4total' then call symput(w1,w2);
    %end;
     %if %length(&showmissing)=0 %then %do;
      if lowcase(w1)='showmissing' then  call symput(w1,w2);
     %end;
  run;
%end;

/* if showmissing not included in configuration file */
%if %length(&showmissing)=0 %then %let showmissing=y;

%if &skipline = 1 %then %let skipline=Y;
%if %length(skipline)=0 %then %let skipline=Y;


%__rrgaddgenvar(
where=%nrbquote(&where),
popwhere=%nrbquote(&popwhere),
popgrp=%nrbquote(&popgrp),
totalgrp=%nrbquote(&totalgrp),
totalwhere=%nrbquote(&totalwhere),
name=%nrbquote(&name),
label=%nrbquote(&label),
suffix=%nrbquote(&suffix),
stat=%upcase(%nrbquote(&stats)), 
ovstat=%nrbquote(&overallstats),
skipline=%upcase(&skipline),
indent=&indent,
denom=%nrbquote(&denomgrp),
denomwhere=%nrbquote(&denomwhere),
fmt=%nrbquote(&fmt),
decode=%nrbquote(&decode),
codelist=%nrbquote(&codelist),
codelistds=%nrbquote(&codelistds),
templateds=%nrbquote(&templateds),
sortcolumn=%nrbquote(&sortcolumn),
ordervar=%nrbquote(&ordervar),
totalpos=%nrbquote(&totalpos),
totaltext=%nrbquote(&totaltext),
misspos=%nrbquote(&misspos),
misstext=%nrbquote(&misstext),
events=&events,
countwhat=%nrbquote(&countwhat),
freqsort=%nrbquote(&freqsort),
mincnt=%nrbquote(&mincnt),
minpct=%nrbquote(&minpct),
delimiter = %nrbquote(&delimiter),
subjid=%nrbquote(&subjid),
type=CAT,
keepwithnext=&keepwithnext,
pctfmt=%nrbquote(&pctfmt),
showgroupcnt = %nrbquote(&showgroupcnt),
pct4missing = %nrbquote(&pct4missing),
pct4total = %nrbquote(&pct4total),
showemptygroups = %nrbquote(&showemptygroups),
showmissing = %nrbquote(&showmissing),
preloadfmt = %nrbquote(&preloadfmt),
templatewhere=%nrbquote(&templatewhere),
outds=__varinfo,
desc=&desc,
delmods=%nrbquote(&remove),
DENOMINClTRT=%upcase(&DENOMINClTRT),
show0cnt=%nrbquote(&show0cnt),
noshow0cntvals=%nrbquote(&noshow0cntvals)

);






 
%put RRG_ADDCATVAR USING VARIABLE &NAME COMPLETED SUCESSULLY;

%mend;
