/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __defcomm/store;

** 04Dec2014 added additional substitution: _apgmname_ to get actual program name;


/*

ds used: __rrgconfig(where=(type='[B0]')), __rrgxml, 
ds created: __nspropskey, __nsprops, __sprops, __repinfo
ds updated:


*/




%*------------------------------------------------------------------------------------;
%*** READ SUBJID, INDENTSIZE, NODATAMSG DEST AND WARNONNOMATCH FROM CONFIGURATION FILE;
%*** IF NOT GIVEN IN MACRO CALL THEN USE VALUES FROM CONFIGURATION FILE;

%local  nsavercd ngentxt ;

data _null_;
  set __rrgconfig(where=(type ='[D4]'));
  call symput(cats('n',w1),w2);
run;

%if %length(&nodatamsg)=0 %then %let nodatamsg=&nnodatamsg;
%if %length(&subjid)=0 %then %let subjid=&nsubjid;
%if %length(&indentsize)=0 %then %let indentsize=&nindentsize;
%if %length(&warnonnomatch)=0 %then %let warnonnomatch=&nwarnonnomatch;
%if %length(&dest)=0 %then %let dest=&ndest;
%let warnonnomatch=%upcase(&warnonnomatch);
%let dest=%upcase(&dest);
%if %length(&dest)=0 %then %let dest = APP;


%if %length(&savercd)=0 %then %let savercd=&nsavercd;
%if %length(&gentxt)=0 %then %let gentxt=&ngentxt;
%let savercd = %upcase(&savercd);
%if &savercd ne Y %then %let savercd=N;


%let gentxt = %upcase(&gentxt);
%if &gentxt ne Y %then %let gentxt=N;




%*------------------------------------------------------------------------------------;


%*------------------------------------------------------------------------------------;
%*** READ TITLES/FOOTNOTES FROM XML FILE;
%*** IF NOT GIVEN IN MACRO CALL THEN USE VALUES FROM CONFIGURATION FILE;

%local i istitle isfoot;
%let istitle=N;
%let isfoot=N;
%do i=1 %to 6;
  %if %length(&&title&i)>0 %then %let istitle=Y;
%end; 
%do i=1 %to 14;
  %if %length(&&footnot&i)>0 %then %let isfoot=Y;
%end; 


data _null_;
  set __rrgconfig(where=(type='[B0]'));
 call symput(cats(w1),cats(w2));
%* put w1= w2=;
run;

%if %length(&TFL_FILE_NAME)>0 and %length(&TFL_FILE_KEY)>0 %then %do;
  
  
  data __testt;
  set __rrgxml;
  
  if 0 then do;
    %do i=1 %to %sysfunc(countw(&TFL_FILE_TITLES,%str( )));
      %qscan(&TFL_FILE_TITLES, &i)='';
    %end;
    %do i=1 %to %sysfunc(countw(&TFL_FILE_FOOTNOTES,%str( )));
      %qscan(&TFL_FILE_FOOTNOTES, &i)='';
    %end;

  end;
  
 
  run;
  
  %local maxtit tmp maxfoot;
  %let maxtit =6;
  %let maxfoot=14;
  %let tmp = %sysfunc(countw(&TFL_FILE_TITLES,%str( )));
  %if &tmp<6 %then %let maxtit=&tmp;
  %let tmp = %sysfunc(countw(&TFL_FILE_FOOTNOTES,%str( )));
  %if &tmp<14 %then %let maxfoot=&tmp;
  
  proc sql noprint;
    %if &istitle=N %then %do;
      %do i=1 %to &maxtit;
        select %scan(&TFL_FILE_TITLES, &i) into:ntit&i separated by ' ' from __testt;
      %end;
    %end;
    %if &isfoot=N %then %do;
      %do i=1 %to &maxfoot;
        select %scan(&TFL_FILE_FOOTNOTES, &i) into : nfootnot&i separated by ' ' from __testt;
      %end;
    %end;
  quit;      
  
  %let j=0;
  %do i=1 %to &maxtit;
     %if %length(%nrbquote(&&ntit&i))>0 %then %do;
        %let j=%eval(&j+1);
        %let title&j = %nrbquote(&&ntit&i);
     %end;
  %end;
  %let j=0;
  %do i=1 %to &maxfoot;
     %if %length(%nrbquote(&&nfootnot&i))>0 %then %do;
        %let j=%eval(&j+1);
        %let footnot&j = %nrbquote(&&nfootnot&i);
     %end;
  %end;

  %* IF SPECIFIED IN XML FILE, ADD TAB STOPS INSIDE FOOTNOTES;
  %if &isfoot=N %then %do;
    data _null_;
     set __rrgconfig(where=(type='[B0]' and w1 in ('TABL_AFTER','TABR_AFTER')));
     length tmp  tmp2 tmp1 $ 2000;
     
     %do i=1 %to &maxfoot;
        
        tmp = symget("footnot&i"); 
        if index(tmp, cats(w2))=1 then do;
          tmp2 = substr(tmp, length(w2));
          if w1='TABL_AFTER' then tmp1 = cats(w2)|| '/ftl '||cats(tmp2);
          else tmp1 = cats(w2)|| '/ftr '||cats(tmp2);
          call symput("footnot&i", cats(tmp1));
        end; 
     %end;
    run;
  %end;

%end;  


data __nspropskey;
length key $ 20;
key ='outformat'; output;
key ='papersize'; output;
key ='margins'; output;  
key='fontsize'; output; 
key='orient'; output;   
key='font'; output;     
key='shead_l'; output;  
key='shead_m'; output;  
key='shead_r'; output;  
key='sfoot_r'; output;   
key='sfoot_l'; output;  
key='sfoot_m'; output;  
key='sfoot_fs'; output;
key='watermark'; output;
run;

*** CREATE DOCUMENT PROPERTIES FILES : NOT SPROPS AND SPROPS;

proc sql noprint;
%if %upcase(&dest)=CSR %then %do;
  create table __nsprops as select * from   
  __rrgconfig
  where type='[C2]' and lowcase(w1) in
  (select * from __nspropskey);
  create table __sprops as select * from   
  __rrgconfig
  where type='[C2]' and lowcase(w1) not in
  (select * from __nspropskey);
%end;
%else %do;
  create table __nsprops as select * from   
  __rrgconfig
  where type='[C1]' and lowcase(w1) in
  (select * from __nspropskey);
  create table __sprops as select * from   
  __rrgconfig
  where type='[C1]' and lowcase(w1) not in
  (select * from __nspropskey);
%end;
quit;

*** DOCUMENT PROPERTIES - NOT SPROPS; 


*libname __vrfy ".";

data _null_;
  set sashelp.vextfl;
  if index(upcase(xpath), ".SAS") then call symput('__program', left(trim(tranwrd(xpath,'\','\\')))); 
run; 

data __nsprops;
  length tmp tmp2  w2 $ 2000;
  set __nsprops;
  tmp2=strip(symget("__program"));
  tmp = cats("&rrgpgmpath.")||cats("/&rrguri..sas");
  tmp = tranwrd(tmp, "\","/");
  w2 = tranwrd(trim(w2), '_USERID_',"&sysuserid");
  w2 = tranwrd(trim(w2), '_PGMNAME_',trim(tmp));
  w2 = tranwrd(trim(w2), '_APGMNAME_',trim(tmp2));
  w2 = tranwrd(trim(w2), '_SPGMNAME_',"&rrguri");
  call symput(cats('c',w1),w2);
  %* put w1= w2=;
  drop tmp2;
run;



%if %length(&systitle)>0  %then %let cshead_l=%nrbquote(&systitle);
%if %length(&font)>0      %then %let cfont=&font;
%if %length(&fontsize)>0  %then %let cfontsize=&fontsize;
%if %length(&margins)>0   %then %let cmargins=&margins;
%if %length(&orient)>0    %then %let corient=&orient;
%if %length(&papersize)>0 %then %let cpapersizet=&papersize;

*** DOCUMENT PROPERTIES - SPROPS;  

data __sprops;
  set __sprops;
  length entry $ 200;
  ** ensure lowcase;
  if lowcase(w1) in ('date_fmt_uc','irtfpl_shead','irtfpl_sfoot','irtfpl_foot')
     and w2 ne '' then entry = cats(lowcase(w1),'=',lowcase(w2));
  
  ** ensure upcase;
  else if lowcase(w1) in ('foot_pos','title_al')
    and w2 ne '' then entry = cats(lowcase(w1),'=',upcase(w2));
  
  else if w2 ne '' then entry = cats(lowcase(w1),'=',w2);
run;

%local sprops;
proc sql noprint;
  select entry into: sprops separated by ',' from __sprops;
quit;      

/*
  
data _null_;
  set __rrgconfig(where=(type='[E2]'));
  call symput('inlibs',cats(w1));
run;
*/

%local __fname;

%if (%length(&TFL_FILE_NAME)>0 and %length(&TFL_FILE_KEY)>0 and %length(&TFL_FILE_OUTNAME)) or  %sysfunc(exist(__rrgxml))  %then %do;
    data __rrgxml;
      set __rrgxml;
      call symput('__fname', cats(__outname));
    run;  
%end;

 

%if %length(&__fname)=0 %then %let __fname=&rrguri;

%global rrgtablepart rrgtablepartnum;
%let append=%upcase(&append);
%let appendable=%upcase(&appendable);
%if &append ne Y %then %let append=N;
%if &appendable ne Y %then %let appendable=N;

%if &append=Y and &appendable=Y %then %let rrgtablepart=MIDDLE;
%else %if &append ne Y and &appendable=Y %then %let rrgtablepart=FIRST;
%else %if &append = Y and &appendable ne Y %then %let rrgtablepart=LAST;
%else %if &append ne Y and &appendable ne Y %then %let rrgtablepart=FIRSTANDLAST;

%if &rrgtablepart=FIRST or &rrgtablepart=FIRSTANDLAST %then %let rrgtablepartnum=1;
%else %let rrgtablepartnum=%eval(&rrgtablepartnum+1);


data __repinfo;
  length footnot1 -footnot14
  title1 title2 title3 title4 title5 title6 Colhead1
  shead_l shead_m shead_r sfoot_l sfoot_r sfoot_m  
   sprops colwidths ncw  filename  $ 2000 tmp $ 20;

Dataset=trim(left(symget("Dataset")));
inlibs=trim(left(symget("inlibs")));

popWhere=cats("(",trim(left(symget("popWhere"))),")");
popwhere=tranwrd(popwhere,'"',"'");
if compress(popWhere, '()')='' then popWhere='';

tabwhere=cats("(",trim(left(symget("tabwhere"))),")");
tabwhere=tranwrd(tabwhere,'"',"'");
if compress(tabwhere, '()')='' then tabwhere='';
Colhead1=trim(left(symget("Colhead1")));
subjid=trim(left(symget("subjid")));
Statsacross=trim(left(symget("Statsacross")));
Statsincolumn=trim(left(symget("Statsincolumn")));
aetable=trim(left(symget("aetable")));

%do i=1 %to 6;
    Title&i=trim(left(symget("Title&i")));
%end;
%do i=1%to 14;
    Footnot&i =trim(symget("Footnot&i"));
%end;

indentsize=trim(left(symget("indentsize")));
nodatamsg=trim(left(symget("nodatamsg")));
extralines=trim(left(symget("extralines")));
warnonnomatch=trim(left(symget("warnonnomatch")));
savercd=trim(left(symget("savercd")));
gentxt=trim(left(symget("gentxt")));


dest=upcase(trim(left(symget("dest"))));
print=trim(left(symget("print")));
debug=trim(left(symget("debug")));
orderby = upcase(trim(left(symget("orderby"))));
stretch = upcase(trim(left(symget("stretch"))));

colwidths=trim(left(symget("colwidths")));
colspacing=trim(left(symget("colspacing")));
if colwidths ne '' then do;
ncw = '';
do __i=1 to countw(colwidths, ' ');
  tmp = scan(colwidths,__i,' ');
  if upcase(tmp) not in ('N', 'LW', 'NH', 'LWH') and
    index(upcase(tmp), 'IN') <= 0 and 
    index(upcase(tmp), 'CM') <= 0 and 
    index(upcase(tmp), 'CH') <= 0 
    then
    ncw = cats(ncw)||' '||cats(tmp,'in');
    else ncw = cats(ncw)||' '||cats(tmp);
end;
colwidths=cats(ncw);
end;





*watermark = upcase(trim(left(symget("cwatermark"))));
watermark = trim(left(symget("cwatermark")));
sfoot_fs = upcase(trim(left(symget("csfoot_fs"))));
outformat = upcase(trim(left(symget("coutformat"))));
papersize = upcase(trim(left(symget("cpapersize"))));
margins = upcase(trim(left(symget("cmargins"))));
fontsize=trim(left(symget("cfontsize")));
orient=trim(left(symget("corient")));
font = upcase(trim(left(symget("cfont"))));
shead_l=trim(left(symget("cshead_l")));
shead_m=trim(left(symget("cshead_m")));
shead_r=trim(left(symget("cshead_r")));
sfoot_r=trim(left(symget("csfoot_r")));
sfoot_l=trim(left(symget("csfoot_l")));
sfoot_m=trim(left(symget("csfoot_m")));
  

%***  SPROPS PARAMETERS;

sprops = trim(left(symget('sprops')));
%if %length(&colspacing)>0 %then %do;
 sprops = cats( sprops, ",col_sp=", scan(upcase(trim(left(symget("colspacing")))),1,' '));
%end;
%if %length(&addlines)>0 %then %do;
 sprops = cats( sprops, ",rtfpl_extlns=", upcase(trim(left(symget("addlines")))));
%end;
%if &appendable =Y  %then %do;
 sprops = cats( sprops, ",appendable=true");
%end;
%if &append=Y  %then %do;
 sprops = cats( sprops, ",append=true");
%end;
%if %length(&splitchars)>0 %then %do;
 sprops = cats( sprops, ",splitchars=", trim(left(symget("splitchars"))));
%end;
%if %length(&esc_char)>0 %then %do;
 sprops = cats( sprops, ",esc_char=", trim(left(symget("esc_char"))));
%end;
%if %length(&gen_size_info)>0 %then %do;
 sprops = cats( sprops, ",gen_size_info=", trim(left(symget("gen_size_info"))));
%end;
%if %length(&rtf_linesplit)>0 %then %do;
 sprops = cats( sprops, ",rtf_linesplit=", trim(left(symget("rtf_linesplit"))));
%end;

/*sprops = cats( sprops, ",rtf_pgsepparfs=2");*/
sprops = cats( sprops, ',xx=xx');

filename="&__fname";

pgmname="&rrguri";

********************************************************************;

%do i=1 %to 6;
    title&i = tranwrd(cats(title&i), "'", "#squot");
    title&i = tranwrd(cats(title&i), "(", "#lpar");
     title&i = tranwrd(cats(title&i), ")", "#rpar");
%end;
%do i=1 %to 6;
  footnot&i = tranwrd(cats(footnot&i), "'", "#squot");
  footnot&i = tranwrd(cats(footnot&i), "(", "#lpar");
  footnot&i = tranwrd(cats(footnot&i), ")", "#rpar");
%end;

colhead1 = tranwrd(cats(colhead1), "'", "#squot");
sfoot_r = tranwrd(cats(sfoot_r), "'", "#squot");
sfoot_m = tranwrd(cats(sfoot_m), "'", "#squot");
sfoot_l = tranwrd(cats(sfoot_l), "'", "#squot");
shead_l = tranwrd(cats(shead_l), "'", "#squot");
shead_m = tranwrd(cats(shead_m), "'", "#squot");
shead_r = tranwrd(cats(shead_r), "'", "#squot");



colhead1 = tranwrd(cats(colhead1), "(", "#lpar");
sfoot_r= tranwrd(cats(sfoot_r), "(", "#lpar");
sfoot_m= tranwrd(cats(sfoot_m), "(", "#lpar");
sfoot_l= tranwrd(cats(sfoot_l), "(", "#lpar");
shead_l = tranwrd(cats(shead_l), "(", "#lpar");
shead_m = tranwrd(cats(shead_m), "(", "#lpar");
shead_r = tranwrd(cats(shead_r), "(", "#lpar");


colhead1 = tranwrd(cats(colhead1), ")", "#rpar");
sfoot_r = tranwrd(cats(sfoot_r), ")", "#rpar");
sfoot_m = tranwrd(cats(sfoot_m), ")", "#rpar");
sfoot_l = tranwrd(cats(sfoot_l), ")", "#rpar");
shead_l = tranwrd(cats(shead_l), ")", "#rpar");
shead_m = tranwrd(cats(shead_m), ")", "#rpar");
shead_r = tranwrd(cats(shead_r), ")", "#rpar");

bookmarks_pdf="&bookmark_pdf";
bookmarks_rtf="&bookmark_rtf";
run;


  
%mend;
