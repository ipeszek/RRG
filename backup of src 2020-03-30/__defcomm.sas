/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __defcomm/store;

** 04Dec2014 added additional substitution: _apgmname_ to get actual program name;

%*------------------------------------------------------------------------------------;
%*** READ SUBJID, INDENTSIZE, NODATAMSG DEST AND WARNONNOMATCH FROM CONFIGURATION FILE;
%*** IF NOT GIVEN IN MACRO CALL THEN USE VALUES FROM CONFIGURATION FILE;

%local njava2sas nsavercd ngentxt nmetadatads;

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

%let njava2sas = %upcase(&njava2sas);
%let java2sas = %upcase(&java2sas);
%if %length(&java2sas)=0 %then %let java2sas=&njava2sas;
%if &java2sas ne Y %then %let java2sas=N;

%if %length(&savercd)=0 %then %let savercd=&nsavercd;
%if %length(&gentxt)=0 %then %let gentxt=&ngentxt;
%let savercd = %upcase(&savercd);
%if &savercd ne Y %then %let savercd=N;


%let gentxt = %upcase(&gentxt);
%if &gentxt ne Y %then %let gentxt=N;

%if %upcase(&java2sas)=Y %then %let gen_size_info=simple;



%*------------------------------------------------------------------------------------;


%*------------------------------------------------------------------------------------;
%*** READ TITLES/FOOTNOTES FROM XML FILE;
%*** IF NOT GIVEN IN MACRO CALL THEN USE VALUES FROM CONFIGURATION FILE;
%* TODO: FIX THIS TO BE MORE GENERIC;

%local i istitle isfoot;
%let istitle=N;
%let isfoot=N;
%do i=1 %to 6;
  %if %length(&&title&i)>0 %then %let istitle=Y;
%end; 
%do i=1 %to 8;
  %if %length(&&footnot&i)>0 %then %let isfoot=Y;
%end; 


data _null_;
  set __rrgconfig(where=(type='[B0]'));
 call symput(cats(w1),cats(w2));
 put w1= w2=;
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
  %let maxfoot=8;
  %let tmp = %sysfunc(countw(&TFL_FILE_TITLES,%str( )));
  %if &tmp<6 %then %let maxtit=&tmp;
  %let tmp = %sysfunc(countw(&TFL_FILE_FOOTNOTES,%str( )));
  %if &tmp<8 %then %let maxfoot=&tmp;
  
  proc sql noprint;
    %if &istitle=N %then %do;
      %do i=1 %to &maxtit;
        select %scan(&TFL_FILE_TITLES, &i) into:ntit&i separated by ' ' from __testt;
      %end;
    %end;
    %if &isfoot=N %then %do;
      %do i=1 %to &maxfoot;
        select %scan(&TFL_FILE_FOOTNOTES, &i) into:nfootnot&i separated by ' ' from __testt;
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

  
data _null_;
  set __rrgconfig(where=(type='[E2]'));
  call symput('inlibs',cats(w1));
run;

%local __fname;

%if %length(&TFL_FILE_NAME)>0 and %length(&TFL_FILE_KEY)>0 and 
 %length(&TFL_FILE_OUTNAME) %then %do;
data __rrgxml;
  set __rrgxml;
  call symput('__fname', cats(__outname));
run;  
%end;

%if %sysfunc(exist(__rrgxml)) %then %do;
data __rrgxml;
  set __rrgxml;
  call symput('__fname', cats(__outname));
run;  
%end;
  

%if %length(&__fname)=0 %then %let __fname=&rrguri;

data __repinfo;
  length footnot1 footnot2 footnot3 footnot4
   footnot5 footnot6 footnot7 footnot8
  title1 title2 title3 title4 title5 title6 Colhead1
  shead_l shead_m shead_r sfoot_l sfoot_r sfoot_m  
   sprops colwidths ncw  filename metadatads $ 2000 tmp $ 20;

java2sas=upcase(strip(symget("java2sas")));   
Dataset=trim(left(symget("Dataset")));
inlibs=trim(left(symget("inlibs")));
popWhere=cats("(",trim(left(symget("popWhere"))),")");
if compress(popWhere, '()')='' then popWhere='';
tabwhere=cats("(",trim(left(symget("tabwhere"))),")");
if compress(tabwhere, '()')='' then tabwhere='';
Colhead1=trim(left(symget("Colhead1")));
subjid=trim(left(symget("subjid")));
Statsacross=trim(left(symget("Statsacross")));
Statsincolumn=trim(left(symget("Statsincolumn")));
aetable=trim(left(symget("aetable")));

Title1=trim(left(symget("Title1")));
title2=trim(left(symget("title2")));
title3=trim(left(symget("title3")));
title4=trim(left(symget("title4")));
title5=trim(left(symget("title5")));
title6=trim(left(symget("title6")));
Footnot1=trim(symget("Footnot1"));
Footnot2=trim(symget("Footnot2"));
Footnot3=trim(symget("Footnot3"));
Footnot4=trim(symget("Footnot4"));
Footnot5=trim(symget("Footnot5"));
Footnot6=trim(symget("Footnot6"));
Footnot7=trim(symget("Footnot7"));
footnot8=trim(symget("Footnot8"));
indentsize=trim(left(symget("indentsize")));
nodatamsg=trim(left(symget("nodatamsg")));
extralines=trim(left(symget("extralines")));
warnonnomatch=trim(left(symget("warnonnomatch")));
java2sas=upcase(trim(left(symget("java2sas"))));
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




append = upcase(trim(left(symget("append"))));
appendable = upcase(trim(left(symget("appendable"))));
tablepart= upcase(trim(left(symget("tablepart"))));
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
%if %upcase(&appendable) =TRUE or %upcase(&appendable)=Y %then %do;
 sprops = cats( sprops, ",appendable=true");
%end;
%if %upcase(&append)=TRUE or %upcase(&append)=Y %then %do;
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
metadatads = strip(symget("nmetadatads"));

run;
  

data __repinfo;
	set __repinfo;
title1 = tranwrd(cats(title1), "'", "#squot");
title2 = tranwrd(cats(title2), "'", "#squot");
title3 = tranwrd(cats(title3), "'", "#squot");
title4 = tranwrd(cats(title4), "'", "#squot");
title5 = tranwrd(cats(title5), "'", "#squot");
title6 = tranwrd(cats(title6), "'", "#squot");
footnot1 = tranwrd(cats(footnot1), "'", "#squot");
footnot2 = tranwrd(cats(footnot2), "'", "#squot");
footnot3 = tranwrd(cats(footnot3), "'", "#squot");
footnot4 = tranwrd(cats(footnot4), "'", "#squot");
footnot5 = tranwrd(cats(footnot5), "'", "#squot");
footnot6 = tranwrd(cats(footnot6), "'", "#squot");
footnot7 = tranwrd(cats(footnot7), "'", "#squot");
footnot8 = tranwrd(cats(footnot8), "'", "#squot");
colhead1 = tranwrd(cats(colhead1), "'", "#squot");
sfoot_r = tranwrd(cats(sfoot_r), "'", "#squot");
sfoot_m = tranwrd(cats(sfoot_m), "'", "#squot");
sfoot_l = tranwrd(cats(sfoot_l), "'", "#squot");
shead_l = tranwrd(cats(shead_l), "'", "#squot");
shead_m = tranwrd(cats(shead_m), "'", "#squot");
shead_r = tranwrd(cats(shead_r), "'", "#squot");


title1 = tranwrd(cats(title1), "(", "#lpar");
title2 = tranwrd(cats(title2), "(", "#lpar");
title3 = tranwrd(cats(title3), "(", "#lpar");
title4 = tranwrd(cats(title4), "(", "#lpar");
title5 = tranwrd(cats(title5), "(", "#lpar");
title6 = tranwrd(cats(title6), "(", "#lpar");
footnot1 = tranwrd(cats(footnot1), "(", "#lpar");
footnot2 = tranwrd(cats(footnot2), "(", "#lpar");
footnot3 = tranwrd(cats(footnot3), "(", "#lpar");
footnot4 = tranwrd(cats(footnot4), "(", "#lpar");
footnot5 = tranwrd(cats(footnot5), "(", "#lpar");
footnot6 = tranwrd(cats(footnot6), "(", "#lpar");
footnot7 = tranwrd(cats(footnot7), "(", "#lpar");
footnot8 = tranwrd(cats(footnot8), "(", "#lpar");
colhead1 = tranwrd(cats(colhead1), "(", "#lpar");
sfoot_r= tranwrd(cats(sfoot_r), "(", "#lpar");
sfoot_m= tranwrd(cats(sfoot_m), "(", "#lpar");
sfoot_l= tranwrd(cats(sfoot_l), "(", "#lpar");
shead_l = tranwrd(cats(shead_l), "(", "#lpar");
shead_m = tranwrd(cats(shead_m), "(", "#lpar");
shead_r = tranwrd(cats(shead_r), "(", "#lpar");

title1 = tranwrd(cats(title1), ")", "#rpar");
title2 = tranwrd(cats(title2), ")", "#rpar");
title3 = tranwrd(cats(title3), ")", "#rpar");
title4 = tranwrd(cats(title4), ")", "#rpar");
title5 = tranwrd(cats(title5), ")", "#rpar");
title6 = tranwrd(cats(title6), ")", "#rpar");
footnot1 = tranwrd(cats(footnot1), ")", "#rpar");
footnot2 = tranwrd(cats(footnot2), ")", "#rpar");
footnot3 = tranwrd(cats(footnot3), ")", "#rpar");
footnot4 = tranwrd(cats(footnot4), ")", "#rpar");
footnot5 = tranwrd(cats(footnot5), ")", "#rpar");
footnot6 = tranwrd(cats(footnot6), ")", "#rpar");
footnot7 = tranwrd(cats(footnot7), ")", "#rpar");
footnot8 = tranwrd(cats(footnot8), ")", "#rpar");
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