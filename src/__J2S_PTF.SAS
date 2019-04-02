/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __j2s_ptf (ls=, hhasdata=, ispage=)/store;
  
%* this macro processess titles and footnotes and calculates how many lines they use;
* dependencies: __repinfo;


%local i ls titcnt footcnt sfcnt shcnt hhasdata ispage;
%put;
%put *************************************************************************;
%put STARTNG EXECUTION OF __J2S_PTF;
%put hhasdata=&hhasdata;
%put ls=&ls ispage=&ispage;
%put;



data __currtfl;
/*set __repinfo (keep = title: footnot: shead: sfoot:);*/
set &rrguri ( where=(__datatype='RINFO') keep = __datatype __title: __footnot: __shead: __sfoot:);
length string title1-title6 footnot1-footnot8 shead_r  shead_l 
   sfoot_r  sfoot_l $ 2000 ns1  tmp w1 tmpw pad $ 200 type  $ 10 ns $ 200;
ls=&ls;
 
type='title';
titcnt=0;
%do i=1 %to 6;
  title&i = tranwrd(__title&i, "//", byte(11));
  if index(title&i, byte(11))=1 then title&i = byte(160)||trim(title&i);
  if index(title&i, byte(11))=length(title&i) then title&i=trim(title&i)||byte(160);
  do j=1 to countw(title&i, byte(11));
    string = strip(scan(title&i, j, byte(11)));
    ns = '';
    ns1='';
    tmp='';
    cntk = countw(string,' ');
    if string ne '' then do;
      do k=1 to cntk;
        ns1=cats(ns);
        tmp = scan(string,k,' ');
        ns = cats(ns)||' '||cats(tmp);
        lenns= length(ns);
        if lenns>ls then do;
          __diff1 = floor((&ls-length(ns1))/2);
          if __diff1>0 then ns=repeat(byte(160), __diff1-1)||cats(ns1);
          else ns=cats(ns1);
          titcnt=titcnt+1;
          output;
          ns = cats(tmp);
        end;
      end;
      if ns ne '' then do;
        titcnt=titcnt+1;
        __diff1 = floor((&ls-length(ns))/2);
        if __diff1>0 then ns=repeat(byte(160), __diff1-1)||cats(ns);
        else ns=cats(ns);
        ns=cats(ns);
        output;
      end;
    end;
  end;
%end;

call symput('titcnt', put(titcnt, best.));
titcnt=.;

type='foot';
 
leftlen=0;
footcnt=1;
%* footcnt includes the top line above footnotes;
ns = repeat("_", &ls-1);
output;
%do i=1 %to 8;
  footnot&i = tranwrd(__footnot&i, "//", byte(11));
  if index(footnot&i, byte(11))=1 then footnot&i = byte(17)||trim(footnot&i);
  if index(footnot&i, byte(11))=length(footnot&i) then footnot&i=trim(footnot&i)||byte(17);
  do j=1 to countw(footnot&i, byte(11));
    string = strip(scan(footnot&i, j, byte(11)));
    indftr = index(string, '/ftr');
    indftl = index(string, '/ftl');
    if indftr>0 then leftlen = max(leftlen, indftr-1);
    if indftl>0 then leftlen = max(leftlen, indftl-1);
  end;
%end;
   
pad='';
if leftlen>0 then  do;
  pad = repeat(byte(160), leftlen);
  leftlen=leftlen+1;
end;
 
%do i=1 %to 8;
  do j=1 to countw(footnot&i, byte(11));
   
    string = strip(scan(footnot&i, j, byte(11)));
     
    if string ne '' then do;
      __line1=1;
      indftr = index(string, '/ftr');
      if indftr>0 then do;
        if leftlen>indftr then
          w1 = repeat(byte(160), leftlen-indftr-1)||substr(string, 1, indftr-1)||byte(160);
        else  w1 = substr(string, 1, indftr-1)||byte(160);
        string=strip(substr(string,indftr+4));
      end;
      indftl = index(string, '/ftl');
      if indftl>0 then do;
        w1 = substr(string, 1, indftl-1)||repeat(byte(160), leftlen-indftl);
        string=strip(substr(string,indftl+4));
      end;
      ns='';
      spaceleft = &ls - leftlen-1;
      do i=1 to countw(string,' ');
        tmpw = scan(string,i,' ');
        if ns='' then __mod=0;
        else __mod=1;
        if spaceleft-length(tmpw)-__mod>=0 then do;
          if ns ne '' then do;
            ns = strip(ns)||' '||scan(string,i,' ');
            spaceleft = spaceleft - length(tmpw)-1;
          end;
          else do;
            ns = scan(string,i,' ');
            spaceleft = spaceleft - length(tmpw);
          end;
        end;
        else do;
          footcnt=footcnt+1;
          if __line1=1 then ns = strip(w1)||strip(ns);
          else ns = strip(pad)||strip(ns);
          *call symput(cats('foot',put(footcnt, best.)), strip(ns));
          output;
          __line1=0;
          ns = tmpw;
          spaceleft = &ls - leftlen-1-length(tmpw);
        end;
      end;
      if ns ne '' then do;
        footcnt=footcnt+1;
        if __line1=1 then ns = strip(w1)||strip(ns);
        else ns = strip(pad)||strip(ns);
        *call symput(cats('foot',put(footcnt, best.)), strip(ns));
        output;
        __line1=0;
      end;
    end;
  end;
%end;

call symput('footcnt', put(footcnt, best.));

%* process system headers;
%* limtation: shead_m is not supported;
%* assumes shead_l and s_head_r do not have wrapping except for hardoced //;
type='shead';
__sheadcnt=0;
shead_l = strip(tranwrd(__shead_l, "//", byte(12)));
if shead_l ne '' then __sheadcnt = countw(shead_l, byte(12))+1;
shead_r = strip(tranwrd(__shead_r, "//", byte(12)));
if string ne '' then __sheadcnt = max(countw(shead_r, byte(12))+1,__sheadcnt);

do i=1 to __sheadcnt;
  tmpw='';
  tmpw = strip(scan(shead_r, i, byte(12)));
  ns = strip(scan(shead_l, i, byte(12)));
  if tmpw ne '' then ns = strip(ns)||repeat(byte(160), &ls-length(tmpw)-length(ns)-1)||strip(tmpw);
  shcnt=i;
  output;
end;
call symput('shcnt', put(__sheadcnt, best.));
 
 
type='sfoot';
__sfootcnt=0;
sfoot_l = strip(tranwrd(__sfoot_l, "//", byte(12)));
if sfoot_l ne '' then __sfootcnt = countw(sfoot_l, byte(12));
sfoot_r = strip(tranwrd(__sfoot_r, "//", byte(12)));
if sfoot_r ne '' then __sfootcnt = max(countw(sfoot_r, byte(12)),__sfootcnt);

do i=1 to __sfootcnt;
  tmpw='';
  tmpw = strip(scan(sfoot_r, i, byte(12)));
  ns = strip(scan(sfoot_l, i, byte(12)));
  if tmpw ne '' then ns = strip(ns)||repeat(byte(160), &ls-length(tmpw)-length(ns)-1)||strip(tmpw);
  sfcnt=i;
  output;
end;
call symput('sfcnt', put(__sfootcnt, best.));
 
keep titcnt footcnt shcnt sfcnt type ns;
run;
 


proc sort data=__currtfl (where=(type='title')) out=__currtflt;
  by titcnt;
run;

proc sort data=__currtfl (where=(type='foot')) out=__currtflf;
  by footcnt;
run;


proc sort data=__currtfl (where=(type='sfoot')) out=__currtflsf;
  by sfcnt;
run;

proc sort data=__currtfl (where=(type='shead')) out=__currtflsh;
  by shcnt;
run;



%local hl;  
proc sql noprint;
  select hl into:hl from __lpp;
quit;

%if &hhasdata=0 %then %do;
  
  data __curtflf;
    if 0;
  run;
  
  %let footcnt=0;
  
  %let hl = %eval(4+&titcnt+&footcnt+&shcnt+&sfcnt);
  %let lpp = %eval(&ps - &hl - &titcnt-&footcnt-&shcnt-&sfcnt);
  %* todo: check if hl, lpp is correct;
  %let lppnh = %eval(&ps - &titcnt-&footcnt-&shcnt-&sfcnt);
%end;
  
%else %do;
  %if &ispage=1 %then %let hl = %eval(&hl+1);
  %* this includes varbylab line, assuming one line;
  %* todo: figure out number of varby lines;
  %let lpp = %eval(&ps - &hl- &titcnt-&footcnt-&shcnt-&sfcnt);
  %* lpp is number of lines available for the body of the report;
  %let lppnh = %eval(&ps - &titcnt-&footcnt-&shcnt-&sfcnt);
%end;

%if &debug>0 %then %do; 
  %put 4iza lines used for header: &hl;
  %put lines used for titles: &titcnt and &shcnt;
  %put lines used for foots: &footcnt and &sfcnt;
  %put available lines = &lpp;
  %put available lines not counting header = &lppnh;
%end; 
 
data __lpp;
  set __lpp;
  lpp=&lpp;
  lppnh=&lppnh;
run; 



%put;  
%put FINISHED EXECUTION OF __J2S_PTF;  
%put *************************************************************************;
%mend;  
