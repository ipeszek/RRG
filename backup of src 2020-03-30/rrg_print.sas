/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

** todo: breakokat: make sure that values <= num of cols;
/*
NOTE: this is developer version with lots of debugging info printed to log
*/

%macro rrg_print(
__align = ,
rowid=__rowid,
manageph=,
colwidths=,
dataset=,
debug=0,
nodatamsg=,
dest=,
filename=,
fontsize=,
footnot1=,
footnot2=,
footnot3=,
footnot4=,
footnot5=,
footnot6=,
footnot7=,
footnot8=,
indentsize=,
orient=,
pagehead=Y,
papersize=,
pgmname=,
lastcheadid=,
likeascii=,
stretch=,
tab1stop=,
tab2stop=,
title1=,
title2=,
title3=,
title4=,
title5=,
title6=,
systitle=,
sysfoot=,
unit=,
split =%str(!),
breakokat= ,
extralines=,
path=,
exh=N,
spanstr=%str(__),
newlinestr=%str(//),
pad=1,
trtlist=)/store;


%*------------------------------------------------------------------------------

 COPYRIGHT Izabella Peszek, 2007
           iza.peszek@gmail.com

 MACRO PARAMETERS:
     &dataset: input dataset
    &filename: name of the table
     &pgmname: name of program
    &tab1stop: size of 1st tab for right-decimal alignemnt
    &tab1stop: size of 2nd tab for right-decimal alignemnt
        &unit: unit (in|cm)
   &colwidths: widths of column
      &orient: P/L: orientation
   &papersize: LETTER/A4: paper size
    &fontsize: font size
   &stretch:   if N, adjust table width
        &dest: APP/CSR: whether to print title1
   &title1, ...&title3: titles
   &footnot1,..., &footnot8: footnotes
       &debug: if>0 prints extra debugging info to log

KNOWN ISSUES:
currently there is no way to avoid war ning in log
    about too long quoted string.
occasionally blank page is generated at end of file
   this happens because SAS inserts paragraph after each table
   if table ends at page boundary, blank page is generated

PLANNED ENHANCEMENTS:
   implement regular expression to detect part boundary in %UT_prtgsl
   implement check that all curly parentheses are closed
   todo: make \par more generic by adding line break parameter
   make escapechar generic same way
   adjust padding of numbers for pdf to center them
   adjust pagelines for CSR destination

-----------------------------------------------------------------------------;

%local __align i j k;

%if &syssite ne 0032422001 OR &SYSUSERID NE peszeki %then %let debug=0;

proc datasets nowarn nolist memtype=data;
delete __rtf: ;
run;
quit;


%local __align rowid manageph colwidths dataset debug nodatamsg
       dest filename fontsize footnot1 footnot2 footnot3
       footnot4 footnot5 footnot6 footnot7 footnot8
       indentsize orient pagehead papersize pgmname lastcheadid
       likeascii stretch tab1stop tab2stop title1 title2 title3
       title4 title5 title6 systitle sysfoot unit split
       breakokat extralines path exh spanstr newlinestr pad trtlist;

%*---------------------------------------------------------------------------;
%* store user options;
%*---------------------------------------------------------------------------;

proc optsave out = work.__rtfopt ;
run;

%let er= ER;
%let ror = ROR;



%local colw ncpp;
%let ncpp=0;


%put ------------------------------------------------------------------------;
%put;
%put STARTING EXECUTION OF RRG_PRINT MACRO V1.2 28FEB2008;


%if %length(&dataset)=0  %then %do;
   %put &ER.&ROR.: dataset parameter must be specfied;
   %goto exit;
%end;

%local tmpdataset;
%let tmpdataset = %scan(&dataset, 1, '(');

%if %sysfunc(exist(&tmpdataset))=0  %then %do;
   %put &ER.&ROR.: dataset &tmpdataset does not exist;
   %goto exit;
%end;


options missing=.;

%if (&syssite ne 0032422001 or &syssite ne 70110201) OR &SYSUSERID NE peszeki %then %let debug=0;

%if &debug =0 %then %do;
   options nomfile nomlogic nomprint nosource nosource2 nosymbolgen nomacrogen nonotes;
%end;



%*----------------------------------------------------------;
%* retrieve options from dataset if they are there;
%*----------------------------------------------------------;

%local dsid rc issuffix isalign isindent isfoot  isdatatype
         ispapersize isorient isdest iscolwidths isfontsize iskeepn iswholerow
         isfilename isstretch isunit istab1stop istab2stop ispath
         istitle1 istitle2 istitle3 istitle4 istitle5 istitle6
         issystitle
         isfootnot1 isfootnot2 isfootnot3 isfootnot4 isfootnot5 isfootnot6
         isfootnot7 isfootnot8 i islastcheadid isindentsize sysfoots ismethod
         issplit ispagebb isbreakokat isbanner isextralines isnodatamsg;

data __rtftmpdataset;
set &dataset (where=(__datatype='RINFO'));
run;

%let dsid=%sysfunc(open(__rtftmpdataset));

%let     isbreakokat= %sysfunc(varnum(&dsid,%str(__breakokat)));
%let       isbanner= %sysfunc(varnum(&dsid,%str(__banner)));
%let       ispagebb= %sysfunc(varnum(&dsid,%str(__pagebb)));
%let       ismethod= %sysfunc(varnum(&dsid,%str(__likeascii)));
%let     iswholerow= %sysfunc(varnum(&dsid,%str(__wholerow)));
%let   islastcheadid= %sysfunc(varnum(&dsid,%str(__lastcheadid)));
%let   isindentsize= %sysfunc(varnum(&dsid,%str(__indentsize)));
%let      issuffix = %sysfunc(varnum(&dsid,%str(__suffix)));
%let      isindent = %sysfunc(varnum(&dsid,%str(__indentlev)));
%let       isalign = %sysfunc(varnum(&dsid,%str(__align)));
%let        isfoot = %sysfunc(varnum(&dsid,%str(__systemfoot)));
%let    isdatatype = %sysfunc(varnum(&dsid,%str(__datatype)));
%let       iskeepn = %sysfunc(varnum(&dsid,%str(__keepn)));
%let   ispapersize = %sysfunc(varnum(&dsid,%str(__papersize)));
%let      isorient = %sysfunc(varnum(&dsid,%str(__orient)));
%let        isdest = %sysfunc(varnum(&dsid,%str(__dest)));
%let   iscolwidths = %sysfunc(varnum(&dsid,%str(__colwidths)));
%let    isfonTsize = %sysfunc(varnum(&dsid,%str(__fontsize)));
%let    isfilename = %sysfunc(varnum(&dsid,%str(__filename)));
%let     isstretch = %sysfunc(varnum(&dsid,%str(__stretch)));
%let        isunit = %sysfunc(varnum(&dsid,%str(__unit)));
%let    istab1stop = %sysfunc(varnum(&dsid,%str(__tab1stop)));
%let    istab2stop = %sysfunc(varnum(&dsid,%str(__tab2stop)));
%let    issystitle = %sysfunc(varnum(&dsid,%str(__systitle)));
%let      istitle1 = %sysfunc(varnum(&dsid,%str(__title1)));
%let      istitle2 = %sysfunc(varnum(&dsid,%str(__title2)));
%let      istitle3 = %sysfunc(varnum(&dsid,%str(__title3)));
%let      istitle4 = %sysfunc(varnum(&dsid,%str(__title4)));
%let      istitle5 = %sysfunc(varnum(&dsid,%str(__title5)));
%let      istitle6 = %sysfunc(varnum(&dsid,%str(__title6)));
%let    isfootnot1 = %sysfunc(varnum(&dsid,%str(__footnot1)));
%let    isfootnot2 = %sysfunc(varnum(&dsid,%str(__footnot2)));
%let    isfootnot3 = %sysfunc(varnum(&dsid,%str(__footnot3)));
%let    isfootnot4 = %sysfunc(varnum(&dsid,%str(__footnot4)));
%let    isfootnot5 = %sysfunc(varnum(&dsid,%str(__footnot5)));
%let    isfootnot6 = %sysfunc(varnum(&dsid,%str(__footnot6)));
%let    isfootnot7 = %sysfunc(varnum(&dsid,%str(__footnot7)));
%let    isfootnot8 = %sysfunc(varnum(&dsid,%str(__footnot8)));
%let    issplit    = %sysfunc(varnum(&dsid,%str(__split)));
%let    ispath     = %sysfunc(varnum(&dsid,%str(__path)));
%let  isextralines = %sysfunc(varnum(&dsid,%str(__extralines)));
%let  isnodatamsg  = %sysfunc(varnum(&dsid,%str(__nodatamsg)));

%let            rc = %sysfunc(close(&dsid));

%*----------------------------------------------------------;
%* determine options;
%*----------------------------------------------------------;

proc sql noprint;
   %if %length(&breakokat)=0 and &isbreakokat>0 %then %do ;
      select distinct __breakokat into:breakokat separated by ''
      from  __rtftmpdataset
      where __breakokat ne '';
   %end;
   %if %length(&nodatamsg)=0 and &isnodatamsg>0 %then %do ;
      select distinct __nodatamsg into:nodatamsg separated by ''
      from  __rtftmpdataset
      where __nodatamsg ne '';
   %end;

   %if %length(&extralines)=0 and &isextralines>0 %then %do ;
      select distinct __extralines into:extralines separated by ''
      from  __rtftmpdataset
      where __extralines ne '';
   %end;

   %if %length(&lastcheadid)=0 and &islastcheadid>0 %then %do ;
      select distinct __lastcheadid into:lastcheadid separated by ''
      from  __rtftmpdataset
      where __lastcheadid ne '';
   %end;
   %if %length(&fontsize)=0 and &isfontsize>0 %then %do ;
      select distinct __fontsize into:fontsize separated by ''
      from  __rtftmpdataset
      where __fontsize ne '';
   %end;
   %if %length(&dest)=0 and &isdest>0 %then %do ;
      select distinct __dest into:dest separated by ''
      from  __rtftmpdataset
      where __dest ne '';
   %end;
   %if %length(&papersize)=0 and &ispapersize>0 %then %do ;
      select distinct __papersize into:papersize separated by ''
      from  __rtftmpdataset
      where __papersize ne '';
   %end;
   %if %length(&orient)=0 and &isorient>0 %then %do ;
      select distinct __orient into:orient separated by ''
      from  __rtftmpdataset
      where __orient ne '';
   %end;
   %if %length(&filename)=0 and &isfilename>0 %then %do ;
      select distinct __filename into:filename separated by ''
      from  __rtftmpdataset
      where __filename ne '';
   %end;
   %if %length(&colwidths)=0 and &iscolwidths>0 %then %do ;
      select distinct __colwidths into:colwidths separated by ''
      from  __rtftmpdataset
      where __colwidths ne '';
   %end;
   %if %length(&stretch)=0 and &isstretch>0 %then %do ;
      select distinct __stretch into:stretch separated by ''
      from  __rtftmpdataset
      where __stretch ne '';
   %end;
   %if %length(&unit)=0 and &isunit>0 %then %do ;
      select distinct __unit into:unit separated by ''
      from  __rtftmpdataset where __unit ne '';
   %end;
   %if %length(&tab1stop)=0 and &istab2stop>0 %then %do ;
      select distinct __tab1stop into:tab1stop separated by ''
      from  __rtftmpdataset
      where __tab1stop ne '';
   %end;
   %if %length(&tab2stop)=0 and &istab2stop>0 %then %do ;
      select distinct __tab2stop into:tab2stop separated by ''
      from  __rtftmpdataset
      where __tab2stop ne '';
   %end;

   %if &isfoot>0 %then %do ;
      select distinct __systemfoot into:sysfoots separated by ''
      from  __rtftmpdataset
      where __systemfoot ne '';
   %end;
   %*put split=&split;
   %if %length(&split)=0 and &issplit>0 %then %do ;
      select distinct __split into:split separated by ''
      from  __rtftmpdataset
      where __split ne '';
   %end;

   %if %length(&likeascii)=0 and &ismethod>0 %then %do ;
      select distinct __likeascii into:likeascii separated by ''
      from  __rtftmpdataset
      where __likeascii ne '';
   %end;

   %if %length(&systitle)=0 and &issystitle>0 %then %do ;
         select distinct compbl(__systitle) into:systitle separated by ''
         from  __rtftmpdataset
         where __systitle ne '';
   %end;


   %do i=1 %to 6;
      %if %length(&&title&i)=0 and &&istitle&i>0 %then %do ;
         select distinct compbl(__title&i) into:title&i separated by ''
         from  __rtftmpdataset
         where __title&i ne '';
      %end;
   %end;
   %do i=1 %to 8;
      %if %length(&&footnot&i)=0 and &&isfootnot&i>0 %then %do ;
         select distinct compbl(__footnot&i) into:footnot&i separated by ''
         from  __rtftmpdataset
         where __footnot&i ne '';
      %end;
   %end;
   %if %length(&path)=0 and &ispath>0 %then %do ;
      select distinct __path into:path separated by '' from __rtftmpdataset
      where __path ne '';
   %end;

quit;



%do i=1 %to 6;
   %let title&i=%nrbquote(&&title&i);
   %let title&i=%qleft(%qtrim(&&title&i));
   %if %length(&&title&i) %then %let title&i=%sysfunc(compbl(&&title&i));
%end;
%do i=1 %to 8;
   %let footnot&i=%nrbquote(&&footnot&i);
   %let footnot&i=%qtrim(&&footnot&i);
   %if %length(&&footnot&i) %then %let footnot&i=%sysfunc(compbl(&&footnot&i));

%end;


%let filename = %qleft(%qtrim(&filename));
%let path = %qleft(%qtrim(&path));

%*----------------------------------------------------------;
%* apply defaults to unspecified options;
%*----------------------------------------------------------;


%let nodatamsg=%nrbquote(&nodatamsg);
%let nodatamsg=%qtrim(&nodatamsg);

%if %length(&nodatamsg)=0 %then %do;
   %let nodatamsg=No data;
%end;

%if %length(&likeascii)=0 or &likeascii ne 2 %then %do;
   %let likeascii=1;
%end;


%if %length(&unit)=0 %then %do;
   %let unit=IN;
%end;
%let unit=%upcase(&unit);


%if %length(&stretch)=0 %then %do;
   %let stretch=Y;
%end;
%let stretch = %upcase(&stretch);

%if %length(&fontsize)=0 %then %do;
   %let fontsize=10;
%end;
%let fontsize = %sysfunc(floor(&fontsize));

%let dest=%upcase(&dest);
%if %length(&dest)=0 %then %do;
   %let dest=APP;
%end;
%else %do;
   %let dest = %upcase(&dest);
   %if &dest ne CSR %then %do;
      %let dest=APP;
   %end;
%end;



%* hack for testing;

%*let dest=APP;
%*let orient=L;
%* let colwidths=;

%let likeascii=1;
%if &dest=APP %then %let likeascii=2;
%*let stretch=N;


%let papersize=%upcase(&papersize);
%let orient=%upcase(&orient);


%if &papersize ne A4 %then %do;
   %let papersize=LETTER;
%end;

%if &dest=CSR and %length(&orient)=0 %then %do;
   %let orient=P;
%end;

%if &orient ne P %then %do;
   %let orient=L;
%end;

%if %length(&filename)=0 and %length(&pgmname)=0 %then %do;
   %put &ER.&ROR.: filename or pgmname parameter must be specfied;
   %goto exit;
%end;

%if %length(&pgmname)=0 %then %do;
   %let pgmname=&filename;
%end;


%if %length(&lastcheadid)=0 %then %do;
   %let lastcheadid=0; %* repeat only 1st column;
%end;


%*--------------------------------------------------------------------------;
%* define template;
%*--------------------------------------------------------------------------;


%*--------------------------------------------------------------------------;
%** SET WIDTH OF THE TABLE IN TWIPS and number of lines per page            ;
%*--------------------------------------------------------------------------;
%local tablew pagelines tm bm rm lm ;


%if %upcase(&orient)= P %then %do;

   %if &papersize=A4 %then %do;
      %if &fontsize<=8 %then %do; %let pagelines=71; %end;
      %if &fontsize=9 %then %do; %let pagelines=65; %end;
      %if &fontsize=10 %then %do; %let pagelines=59; %end;
      %if &fontsize=11 %then %do; %let pagelines=53; %end;
      %if &fontsize=12 %then %do; %let pagelines=49; %end;
      %if &dest=CSR %then %let pagelines = %eval(&pagelines-1);

      %let tablew=9028;
      %let tm=1.00;
      %let bm=1.00;
      %let lm=1.00;
      %let rm=1.00;

   %end;
   %else %do;
      %if &fontsize<=8 %then %do; %let pagelines=71; %end;
      %if &fontsize=9 %then %do; %let pagelines=65; %end;
      %if &fontsize=10 %then %do; %let pagelines=59; %end;
      %if &fontsize=11 %then %do; %let pagelines=53; %end;
      %if &fontsize=12 %then %do; %let pagelines=49; %end;
      %if &dest=CSR %then %let pagelines = %eval(&pagelines-1);


      %let tm=1.00;
      %let bm=1.00;
      %let lm=1.00;
      %let rm=1.00;

      %let tablew=9360;
   %end;
%end;
%if %upcase(&orient)= L %then %do;


   %if &papersize=A4 %then %do;
      %if &fontsize<=8 %then %do; %let pagelines=45; %end;
      %if &fontsize=9 %then %do; %let pagelines=38; %end;
      %if &fontsize=10 %then %do; %let pagelines=37; %end;
      %if &fontsize=11 %then %do; %let pagelines=32; %end;
      %if &fontsize=12 %then %do; %let pagelines=29; %end;
      %if &dest=CSR %then %let pagelines = %eval(&pagelines-1);

      %let tm=1.50;
      %let bm=1.14;
      %let lm=1.35;
      %let rm=1.34;
      %let tablew=12900;
   %end;
   %else %do;
      %if &fontsize<=8 %then %do; %let pagelines=40; %end;
      %if &fontsize=9 %then  %do; %let pagelines=38; %end;
      %if &fontsize=10 %then %do; %let pagelines=34; %end;
      %if &fontsize=11 %then %do; %let pagelines=29; %end;
      %if &fontsize=12 %then %do; %let pagelines=28; %end;
      %if &dest=CSR %then %let pagelines = %eval(&pagelines-1);

      %let tm=1.26;
      %let bm=1.26;
      %let lm=1.00;
      %let rm=1.00;
      %let tablew=12900;
   %end;
%end;
%if %length(&extralines) %then %do;
  %let pagelines=%eval(&pagelines+((-1)*(&extralines)));
%end;



%local fontface;
%let fontface=Courier New;
%if &dest=CSR %then %let fontface=Times New Roman;

PROC TEMPLATE;
   DEFINE STYLE DefaultNewTitle;
   PARENT=styles.rtf;
   REPLACE fonts /
      'TitleFont' = ("&fontface",&fontsize.pt)
      'TitleFont2' = ("&fontface",&fontsize.pt)
      'headingEmphasisFont' = ("&fontface",&fontsize.pt, Bold)
      'headingFont' = ("&fontface",&fontsize.pt)
      'docFont' = ("&fontface",&fontsize.pt)
      'StrongFont' = ("Arial, Helvetica, Helv",4,Bold)
      'EmphasisFont' = ("Arial, Helvetica, Helv",3,Italic)
      'FixedEmphasisFont' = ("Courier",2,Italic)
      'FixedStrongFont' = ("Courier",2,Bold)
      'FixedHeadingFont' = ("Courier",2)
      'BatchFixedFont' = ("SAS Monospace, Courier",2)
      'FixedFont' = ("Courier",2);
      
      style Body from Document
      "Controls the Body file." /
      bottommargin = &bm.in
      topmargin = &tm.in
      rightmargin = &rm.in
      leftmargin = &lm.in
      background=_undef_
      foreground=_undef_
      
      /*backgroundimage="F:\RRGPrivate\draft.jpg"*/
      
      ;
      
     style TitlesAndFooters/
         background=_undef_
        foreground=_undef_
     ;
      
      
      %if &dest=CSR %then %do;
        replace systemtitle from TitlesAndFooters/
           protectspecialchars=off;
        replace systemfooter from TitlesAndFooters/
           protectspecialchars=off;
      %end;
     
    style container from container/
    background=_undef_
    foreground=_undef_
    ;
     
    style table from table /
      cellpadding = 1pt
      cellspacing = 0pt;
      
    style header from header /
      background=_undef_;
      
  end;
    
   
RUN;

%if &orient=L %then %do;
options orientation=landscape  nodate nonumber center nobyline;
%end;
%else %do;
options orientation=portrait  nodate nonumber center nobyline;
%end;


ods escapechar='~';
ods listing close;
%if &dest=APP %then %do;
  %let filename = &path./&filename..pdf;
  ods pdf file="&filename" style=DefaultNewTitle notoc;
%end;
%else %do;
  %let filename = &path./&filename..rtf;
  ods rtf file="&filename" style=DefaultNewTitle ;
%end;

title;
footnote;
%local frame protectstr;
%let protectstr=%str(protectspecialchars=off);
%let frame=hsides;
%if &dest=CSR %then %do;
    %if &likeascii=1 %then %let frame=void;
    %let protectstr=%str(protectspecialchars=off);
%end;



%local ntit1 ntit2 ntit3 ntit4 ntit5 ntit6 numtit;
%local nfoot1 nfoot2 nfoot3 nfoot4 nfoot5 nfoot6 nfoot7 nfoot8 numfoot;
%let systitle= %sysfunc(tranwrd(%nrbquote(&&systitle),
     %str(&newlinestr), %str(~-2n)));
%let numtit=0;

%do i=1 %to 6;
   %if %length(%nrbquote(&&title&i)) %then %do;
      %let numtit=%eval(&numtit+1);
      %let ntit&numtit = %sysfunc(tranwrd(%nrbquote(&&title&i),
          %str(&newlinestr), %str(~-2n)));
   %end;
%end;

%let numfoot=0;

%do i=1 %to 8;
   %if %length(%nrbquote(&&footnot&i)) %then %do;
      %let numfoot=%eval(&numfoot+1);
      %let nfoot&numfoot = &&footnot&i;
    %let nfoot&numfoot = %sysfunc(tranwrd(%nrbquote(&&footnot&i),
        %str(&newlinestr), %str(~-2n)));
   %end;
%end;

%* todo temporary to deal with testing datasets;
   %if %length(&sysfoots) %then %do;
      %let numfoot=%eval(&numfoot+1);
      %let nfoot&numfoot = &sysfoots;
   %end;


%local titlef0;
%let titlef0=\b &ntit1;
%do i=2 %to &numtit;
    %let titlef0 = &titlef0.~-2n&&ntit&i;
%end;



%local __date __time;

   data _NULL_;
      datetime=datetime();
      date=put(datepart(datetime), date9.);
      time=put(timepart(datetime), time5.);
      call symput("__date", date);
      call symput("__time", time);
   run;



%*--------------------------------------------------------------------------;
%* PREPARE DATASET;
%*--------------------------------------------------------------------------;

data __rtf4rtf ;
length __pagebb $ 12;
set &dataset (where=(__datatype ne 'RINFO'));
%if %length(&__align) %then %do;
__align = compbl(symget("__align"));
%end;


__val ='';
__den='';
__evtc='';
__lastcheadid = '';
__fontsize = '';
__dest = '';
__papersize = '';
__orient = '';
__filename = '';
__colwidths = '';
__stretch = '';
__unit = '';
__tab1stop = '';
__tab2stop = '';

%if &ispagebb=0 %then %do; __pagebb=''; %end;
%do i=1 %to 6;
   __title&i = '';
%end;
%do i=1 %to 8;
   __footnot&i = '';
%end;
__systemfoot = '';
drop __lastcheadid __fontsize __dest __papersize
   __orient __filename  __colwidths __stretch __unit __tab1stop
   __tab2stop  __val: __den: __evtc:
   %do i=1 %to 6;   __title&i %end;
   %do i=1 %to 8;   __footnot&i  %end; __systemfoot;
run;

%local dsid vnum1 vnum2  rc;
%let vnum1=0; %let vnum2=0;
%let dsid=%sysfunc(open(__rtf4rtf));
%let vnum1=%sysfunc(varnum(&dsid, __varbygrp));
%let vnum2=%sysfunc(varnum(&dsid, __varbylab));
%let rc = %sysfunc(close(&dsid));


%*---------------------------------------------------------------------------;
%* REPLACE VARBY with __varbygrp making SURE THAT VARBY IS SEQUENTIAL;
%*---------------------------------------------------------------------------;

%local maxbid;
%let maxbid=1;


%if &vnum1>0 %then %do;
   proc sort data=__rtf4rtf;
      by __varbygrp   &rowid;
   run;

   data __rtf4rtf (rename=(__vargrp=__varbygrp));
      length __varbylab $ 2000;
      set __rtf4rtf end=eof;
      by __varbygrp &rowid;
      retain __vargrp;
      __rowid=_n_;
      if _n_=1 then __vargrp=0;
      if first.__varbygrp then __vargrp =  __vargrp+1;
      %if &vnum2=0 %then %do;
      __varbylab = "";
      %end;
      __tmpvarby=1;
      if eof then call symput("maxbid", compress(put(__vargrp, 12.)));
      drop __varbygrp;
   run;

%end;

%else %do;
   data __rtf4rtf ;
   length __varbylab $ 2000;
   set __rtf4rtf;
      __varbygrp=1;
      __varbylab='';
      __tmpvarby=1;
      __rowid=_n_;
   run;
%end;

%if &debug>0 %then %do;
   %put number fo varby groups, maxbid=&maxbid;
%end;

%*---------------------------------------------------------------------------;
%* cretae banner ordering;
%*---------------------------------------------------------------------------;
 %if &isbanner>0 %then %do;

   proc sort data=__rtf4rtf;
      by __varbygrp  __rowid;
   run;

   data __rtf4rtf;
   set __rtf4rtf;
   by __varbygrp  __rowid;
   retain __bannerid ;
   if first.__varbygrp then __bannerid=0;
   if __banner ne '' then __bannerid+1;
   run;

   data __rtf4rtf(drop=__banner rename=(__banner2=__banner));
    set __rtf4rtf;
    length __banner2 $ 2000;
    retain __banner2;
    if __banner ne '' then __banner2 = left(trim(__banner));
   run;


 %end;


data __rtf4rtf;
   length __align $ 2000 __prefix __col: __prefix1-__prefix10 $ 2000 ;
   set __rtf4rtf;
   __col0='';
   %if &iskeepn=0 %then %do;        __keepn=.;        %end;
   %if &isindentsize=0 %then %do;   __indentsize=.;   %end;
   %if &issuffix=0 %then %do;       __suffix='';      %end;
   %if &isalign=0 %then %do;        __align='';       %end;
   %if &isindent=0 %then %do;       __indentlev=0;    %end;
   __align = upcase(__align);

   %if %length(&indentsize) %then %do; __indentsize = &indentsize; %end;
   if __indentsize=. then __indentsize=1;
   if __indentlev=<0 then __indentlev=0;
   __tmpli=floor(__indentlev*24*&fontsize*__indentsize);
   __prefix='';
   if __indentlev>0 then do;
     %if &dest=CSR %then %do;
        __prefix = compress("\li"||put(__tmpli, 12.));
     %end;
     %else %do;
        /*
        __indentlev2 = __indentsize*(2*__indentlev-1);
        __prefix ="~m"||repeat(" ", __indentlev2)||"~m";
        */
        __pad = floor(__tmpli/(12*&fontsize));
        if __pad=1 then __prefix = "~m ~m";
        else if __pad>1 then do;
          __pad =__pad-1;
          __prefix ="~m"||repeat(" ", __pad)||"~m";
        end;
     %end;
   end;
   
   if __datatype='HEAD' then do;
    
    %if &dest=CSR %then %do;
      %do j=1 %to 10;
        __prefix&j = cats("\par\li",floor(&j*24*&fontsize*__indentsize))||" ";
        __col_0 = tranwrd(trim(left(__col_0)),"/t&j", trim(__prefix&j));
      %end;
    %end;  
    %else %do;
      %do j=1 %to 10;
        __prefix&j='';
        __col_0 = tranwrd(trim(left(__col_0)),"/t&j ", "~-2n~m  ~m");
      %end;
    %end;
    
  end;

   drop __col0 __prefix1-__prefix10;
run;



%local lastcol varlist newvarlist;;

%let lastcol=-1;

%*--------------------------------------------------------------------------;
%* DETERMINE HOW MANY COLUMNS (COL_1, COL_2 ...) ARE IN INPUT DATASET;
%*--------------------------------------------------------------------------;


%local dsid rc vnum isdata;
%let isdata=0;
%let dsid=%sysfunc(open(__rtf4rtf));
%let isdata = %sysfunc(attrn(&dsid, NLOBS));
%let rc=%sysfunc(close(&dsid));

%if &isdata=0 %then %goto donoreport;

proc contents data=__rtf4rtf noprint out = __rtfds_cont;
run;


data __rtfds_cont;
   length __num $ 3;
   set __rtfds_cont ;
   if substr(lowcase(name),1,6)= "__col_";
   __num = substr(name, 7);
   %* todo: implement regular expressions to check that this is valid number;
run;


data __rtfds_cont;
   set __rtfds_cont end=eof;
   _nn=_n_-1;
   if eof then do;
      call symput('lastcol', compress(put(_nn, 12.)));
   end;
run;


%if &lastcol=-1 %then %do;

   %donoreport:

     data __dummy;
     length __dummy $ 2000;
     __dummy = trim(left(symget("nodatamsg")));
     %if &dest=APP %then %do;
     __dummy = tranwrd(trim(__dummy),'//','~-2n ');
     %end;
     %else %do;
     __dummy = tranwrd(trim(__dummy),'//','\par ');
     %end;
     run;

      proc report data=__dummy nowindows split="&split"
        style(report)={&protectstr rules=groups frame=&frame }
        style(header)={&protectstr  rules=none just=l
                          frame=void bordercolor=black}
        style(lines)={just=l &protectstr 
                          rules=none bordercolor=black}
                       ;

      %if &dest=APP %then %do;
         %if %length(&systitle) %then %do;
         title j=l "&systitle" j=r "Page ~{thispage} of ~{lastpage}";
         
         %end;
         %else %do;
         title j=r "Page ~{thispage} of ~{lastpage}";
         
         %end;
         %local cnt;
         %let cnt=2;
         %do i=1 %to &numtit;
               title&cnt j=c "&&ntit&i" ;
               %let cnt = %eval(&cnt+1);
         %end;
         %let cnt=1;
  
         footnote&cnt j=l "Program: &pgmname..sas  &__date &__time";
            column __dummy;
      %end;

      %else %do;
         compute after;
         %let cnt=1;
   
         %if &cnt=1 %then %do;
            line "Program: &pgmname..sas &__date &__time \brdrt\brdrs\brdrw15";
         %end;
         %else %do;
            line "Program: &pgmname..sas  &__date &__time";
         %end;
         endcomp;
            column  ( "&titlef0" __dummy);
      %end;

      define __dummy / ""
             style(column)={&protectstr cellwidth=100%
                            font_size=&fontsize.pt };

      run;

%if &dest=APP %then %do;
   ods pdf close;
%end;
%else %do;
   ods rtf close;
%end;
ods listing;

%goto exit;


%end;

%if &lastcol=0 %then %do;
   data __rtf4rtf;
   length __col_0 __col_1 $ 2000;
   set __rtf4rtf;
   __col_1 = '';
   run;

   %let lastcol=1;
%end;

%*---------------------------------------------------------------------------;
%* PLACEHOLDER: make sure that all curly braces are closed;
%*---------------------------------------------------------------------------;
/*
data __rtf_rors;
if 0;
run;

%__ipchkcurly(
   dsin =__rtf4rtf,
   varlist =%do i=0 %to &lastcol; __col_&i %end;,
   leftsymbol ={,
   rightsymbol=},
   infods=__rtf_rors);

%local numerr;

proc sql noprint;
   select count(*) into:numerr from __rtf_rors;
quit;

%if &numerr>0 %then %do;

   data __rtf_rors;
   set __rtf_rors;
      put "&er.&ror.:" msg;
   run;

   %put;
   %put;
   %put ABORTING MACRO PRT_TABLEF.......................................... ;
   %put;
   %put;
   %goto exit;
%end;
*/

%*--------------------------------------------------------------------------;
%* determine header information;
%*--------------------------------------------------------------------------;
%if %length(&trtlist) %then %do;


data __rtfcolumns;
length __string __nstring __tmpttl __tmpvname $ 2000 __colid_ $ 20;
keep __rowid __nstring __colid __colid_;
do i=0 to &lastcol;
  __colid=i;
  __colid_="__col_"||compress(put(i,12.));
  __rowid=1;
  __tmpvname = "__TRTLIST_&trtlist"||compress(put(i,12.))||"_TTL";
  __tmpttl = left(trim(symget(__tmpvname)));
  __string = reverse(trim(left(__tmpttl)));
  __spanstr = reverse(compress(symget("spanstr")));
  __ls = length(__spanstr);
  do while (__string ne "");
    tmp=index(left(trim(__string)), compress(__spanstr));
    if tmp>0 then do;
       __nstring = reverse(substr(trim(left(__string)), 1, tmp-1));

       __string = substr(trim(left(__string)), tmp+__ls);
    end;
    else do;
       __nstring= reverse(trim(left(__string)));
       __string='';
    end;
    output;
    __rowid+(-1);
  end;
end;
run;

data __rtfcolumns;
length __datatype $ 8 __align $ 200;
set __rtfcolumns(in=__a) __rtf4rtf (in=__b);
if __a then do;
   __datatype='HEAD';
   __align ='L';
   do __i=1 to &lastcol;
   __align = left(trim(__align))||" C";
   end;
 end;
else __datatype='TBODY';
drop __i;
run;

%end;

data __rtfcolumns __rtf4rtf;
   length %do i=0 %to &lastcol; __col_&i %end; $ 2000 __newline $ 8;
   ARRAY cols{*} $ 2000 __col_0-__col_&lastcol;
   set __rtf4rtf;
   __newline = compress(symget("newlinestr"));
   do __i=1 to dim(cols);
      %if &dest=APP %then %do;
         %* for pdf destination, the control word for superscript is different;
         cols[__i]=tranwrd(trim(left(cols[__i])), '{\super', '~{super');
      %end;
      cols[__i]=tranwrd(trim(left(cols[__i])), '{\tab}', '');
    cols[__i]=tranwrd(trim(left(cols[__i])), compress(__newline), "~-2n");
      %* temporary: for dealing with testing dataset;
   end;
   %if &isbanner>0 %then %do;
     __banner=tranwrd(trim(left(__banner)), compress(__newline), "~-2n");
   %end;
   if __datatype='HEAD' then output __rtfcolumns;
   else output __rtf4rtf;
run;


%local dsid rc vnum ishead;
%let ishead=0;
%let dsid=%sysfunc(open(__rtfcolumns));
%let ishead = %sysfunc(attrn(&dsid, NLOBS));
%let rc=%sysfunc(close(&dsid));

%if &ishead=0 %then %do;
   %put &ER.&ROR.: input dataset does not have any records
         with __datatype=HEAD (defining table header);
   %goto exit;
%end;


%local dsid rc vnum isdata;
%let isdata=0;
%let dsid=%sysfunc(open(__rtf4rtf));
%let isdata = %sysfunc(attrn(&dsid, NLOBS));
%let rc=%sysfunc(close(&dsid));

%if &isdata=0 %then %goto donoreport;

%*--------------------------------------------------------------------------;
%* if string has new line inside, generate multiple lines;
%*--------------------------------------------------------------------------;

proc sort data=__rtfcolumns;
by __varbygrp __rowid;
run;

data __rtfcolumns (rename=(__nrowid=__rowid));
set __rtfcolumns ;
by __varbygrp __rowid;
length __col $ 2000 __colid $ 20;
keep __col __colid __nrowid __varbygrp __varbylab __align;
array cols{*} __col_0--__col_&lastcol;
retain __nrowid;
if first.__varbygrp then __nrowid=0;
__nrowid+1;
do __i=1 to dim(cols);
__col = cols[__i];
__j=__i-1;
__colid = "__col_"||compress(put(__j, 12.));
output;
end;
run;

proc sort data=__rtfcolumns;
by __varbygrp __rowid __colid;
run;


data __rtfcolumns;
length __string __nstring $ 2000 ;
set __rtfcolumns;
by __varbygrp __rowid;
retain __nrowid;
keep __rowid __nrowid __nstring __colid __varbygrp __varbylab __align;
  __string = reverse(trim(left(__col)));
  __spanstr = reverse(compress(symget("spanstr")));
  __ls = length(__spanstr);
  __nrowid = 0;
  if __string="" then output;
  do while (__string ne "");
    tmp=index(left(trim(__string)), compress(__spanstr));
    if tmp>0 then do;
     if tmp>1 then
       __nstring = reverse(substr(trim(left(__string)), 1, tmp-1));
     else __nstring = "";
     if tmp+__ls<=length(__string) then
       __string = substr(trim(left(__string)), tmp+__ls);
     else __string="";
    end;
    else do;
       __nstring= reverse(trim(left(__string)));
       __string='';
    end;
    output;
    __nrowid+(-1);
  end;
run;


proc sort data=__rtfcolumns;
by __varbygrp __rowid __nrowid __align;
run;

proc transpose data=__rtfcolumns out=__rtfcolumnst;
by __varbygrp __rowid __nrowid __align;
id __colid;
var __nstring;
run;

data __rtfcolumnst (drop=__rowid __nrowid rename=(__nnrowid=__rowid));
set __rtfcolumnst;
by __varbygrp __rowid __nrowid __align;
retain __nnrowid;
if first.__varbygrp then __nnrowid=0;
__nnrowid+1;
if last.__varbygrp then __lastrow=1;
run;




%local i j k;



%*-----------------------------------------------------------------------;
%* CONVERT colwidths TO TWIPS;
%*-----------------------------------------------------------------------;
%local  F2P minwidth;
%if %length(&colwidths)=0 %then %do;
  %let colwidths=FIT2PAGE;
%end;
%if %upcase(&colwidths)=FIT2PAGE %then %do;
   %let F2P=Y;
   %let  colwidths=;
%end;
%let colwidths=%__ut_prtc2t(string=&colwidths, unit=&unit);
%let tab1stop=%__ut_prtc2t(string=&tab1stop, unit=&unit);
%let tab2stop=%__ut_prtc2t(string=&tab2stop, unit=&unit);

%let colwidths=%__ut_prtf2n(string=&colwidths, num=%eval(&lastcol+1));
%local ts1 ts2;
%if %length(&tab1stop)>0 %then %do;
   %let tab1stop=%__ut_prtf2n(string=&tab1stop,num=%eval(&lastcol+1));
%end;
%if %length(&tab2stop)>0 %then %do;
   %let tab2stop=%__ut_prtf2n(string=&tab2stop,num=%eval(&lastcol+1));
%end;
%if %length(&minwidth)>0 %then %do;
   %let minwidth=%__ut_prtf2n(string=&minwidth,num=%eval(&lastcol+1));
%end;
%else %do;
  %do i=1 %to %eval(&lastcol+1);
      %let minwidth = &minwidth X;
  %end;
%end;


%if &debug>0 %then %do;
   %put colwidths=&colwidths tab1stop1=&tab1stop tab2stop=&tab2stop
        minwidth=&minwidth;
%end;

%*--------------------------------------------------------------------------;
%* DETERMINE RELATIVE COLUMN WIDTHS FOR BODY OF TABLE;
%*--------------------------------------------------------------------------;

%*--------------------------------------------------------------------------;
%* split header entries from last header row to generate a record
     for every word;
%*--------------------------------------------------------------------------;


%if &exh=N %then %do;

%* note: it assumes only one record for headers in each __varbygrp;

proc sort data=__rtfcolumns out=__rtftmph (where=(__nrowid=0));
by __varbygrp __rowid __colid;
run;

%local lastrid;

data __rtftmph;
length __nstring2 $ 2000;
set __rtftmph end=eof;
by __varbygrp __rowid __colid;
retain __nnrowid;
if first.__colid then __nnrowid=0;
__nstring = compbl(__nstring);
__nstring= tranwrd(compbl(__nstring), '~-2n', ' ');
__nstring= tranwrd(compbl(__nstring), '/', ' ');
do i=1 to length(__nstring);
    __nstring2=scan(__nstring,i,' ');
  if __nstring2 ne "" then do;
      __nnrowid+1;
    output;
  end;
end;
if eof then call symput('lastrid', cats(__rowid));
run;

proc sort data=__rtftmph (where=(__rowid=&lastrid));
by __varbygrp __rowid __nrowid __nnrowid;
run;

  
proc transpose data=__rtftmph out=__rtftmph ;
by __varbygrp __rowid __nrowid __nnrowid;
id __colid;
var __nstring2;
run;
%end;
%else %do;
data __rtftmph;
if 0;
__col='';
run;
%end;



%*--------------------------------------------------------------------------;
%* add header records generated in previous step to dataset with table body;
%* deremine width needed for each column;
%*--------------------------------------------------------------------------;


data __rtfds_w;
   length __tmpalign $ 8;
   set __rtf4rtf __rtftmph (in=__a  keep=__col:);
   array __afm{251} _temporary_ ;


   %if &dest=APP %then %do;
      do __i=1 to 251;
        __afm[__i]=600;
      end;
   %end;
   %else %do;
     %__ut_prtgfm;
     %* this array has 251 elements;
     if __a then do;
       do __i=1 to 251;
         __afm[__i] = __afmb[__i];
       end;
       __indentsize=0;
       __indentlev=0;
     end;
     else do;
        do __i=1 to 251;
           __afm[__i] = __afmn[__i];
        end;
     end;
   %end;

   if __tmpli=. then __tmpli=0;
   __align = upcase(compbl(__align));


   %do i=0 %to &lastcol;
      __tmpalign = scan(__align, %eval(&i+1), ' ');
      if __a then __tmpalign ='C';
      %__ut_prtgsl(varin=__col_&i, lenvar=__len_&i, fs=&fontsize,
                alignvar=__tmpalign);
      if __a and "&dest"="CSR" then do;
      %* for bold font, need more space;
      __len_&i._1 =ceil(1.1*__len_&i._1);
      __len_&i._6 =ceil(1.1*__len_&i._6);
      __len_&i._7 =ceil(1.1*__len_&i._7);
      __len_&i._2 =ceil(1.1*__len_&i._2);
      __len_&i._3 =ceil(1.1*__len_&i._3);
      __len_&i._4 =ceil(1.1*__len_&i._4);
      __len_&i._5 =ceil(1.1*__len_&i._5);
      end;
   %end;
   %* add size of indent to 1st column width;
   __len_0_5 = __len_0_5+__tmpli;
   __len_0_1 = __len_0_1+__tmpli;

   drop __i __tmpl __word: k z __tmpalign;
run;





%*--------------------------------------------------------------------------;
%* determine column widths based on largest width across all records;
%*--------------------------------------------------------------------------;

proc sql noprint;
   %do i=0 %to &lastcol;
     %do j=1 %to 8;
        %local len_&i._&j;
           select max(__len_&i._&j) into: len_&i._&j from __rtfds_w ;
           %if &debug>0 %then %do;
           %put len_&i._&j = &&len_&i._&j;
           %end;
     %end;
   %end;
quit;



%local autom part1 part2a part2b  __tmp0 __tmp20   __tmp __tmp2;

%do i=0 %to &lastcol;
   %local __diff&i ;
   %if (&&len_&i._3+&&len_&i._4)>&&len_&i._2 %then
       %let len_&i._2=%eval(&&len_&i._3+&&len_&i._4);
   %if (&&len_&i._7+&&len_&i._6)>&&len_&i._1 %then
       %let len_&i._1=%eval(&&len_&i._7+&&len_&i._6);

   %let __diff&i = %eval(&&len_&i._1+&&len_&i._2-&&len_&i._5);

   %if &&__diff&i>0 %then %do;
         %let len_&i._5=%eval(&&len_&i._5+&&__diff&i);
   %end;


   %* use user-provided column widths if applicable;
   %let __tmp0 = %scan(&colwidths, %eval(&i+1), %str( ));
   %if %length(&__tmp0) and &__tmp0 ne W and &__tmp0 ne N %then %do;
      %if  &__tmp0<216 %then %let __tmp0 = 216;
      %if  &&len_&i._5<&__tmp0 %then %let len_&i._5=&__tmp0;
   %end;

   %* adjust tab1stop;
   %let __diff&i = %eval(&&len_&i._5-&&len_&i._1-&&len_&i._2);
   %let __diff&i = %sysevalf(&&__diff&i/2, floor);
   %if &&__diff&i>0 %then %do;
         %if len_&i._1>0 %then
             %let len_&i._1=%eval(&&len_&i._1+ &&__diff&i);
         %else %if &&len_&i._3>0 %then
             %let len_&i._3=%eval(&&len_&i._3+&&__diff&i);
   %end;

   %let len_&i._3=%eval(&&len_&i._3+&&len_&i._7);

   %* use user-provided tabstops if applicable;

   %let __tmp = %scan(&tab1stop, %eval(&i+1), %str( ));
   %if %length(&__tmp) %then %do;
         %let len_&i._1=&__tmp;
   %end;

   %let __tmp = %scan(&tab2stop, %eval(&i+1), %str());
   %if %length(&__tmp) %then %do;
       %let len_&i._3=&__tmp;
   %end;

   %* cell padding;
   %*let len_&i._5=%eval(&&len_&i._5+160);

   %let len_&i._5=%eval(&&len_&i._5+220);
   %if &pad ne 0 %then %do;
      %let len_&i._5=%eval(&&len_&i._5+220);
   %end;

   %let autom = &autom &&len_&i._5;
   %let part1  = &part1 &&len_&i._1;
   %let part2a = &part2a &&len_&i._3;
   %let part2b = &part2b &&len_&i._4;
%end;


%if &debug>0 %then %do;
   %put automatic widths:;
   %put lastcol=&lastcol;
   %put user provided colwidths=&colwidths;
   %put calculated/adjusted colwidths (before wrap adjustment) autom=&autom;
   %put part1=&part1;
   %put part2a=&part2a;
   %put part2b=&part2b;
%end;

%if %length(&colwidths) %then %do;
   %if %length(%scan(&colwidths,2,%str( )))=0 %then %do;
       %do i = 1 %to &lastcol;
           %let colwidths= &colwidths %scan(&autom, %eval(&i+1), %str( ));
       %end;
   %end;
%end;




%*---------------------------------------------------------------------------;
%* remove header lines from dataset;
%*---------------------------------------------------------------------------;

data __rtfds_w;
   set  __rtfds_w;
   if __datatype='TBODY';
   if __prefix ne "" then  do;
     %if &dest=APP %then %do;
        __col_0 = trim(left(__prefix))||trim(left(__col_0));
   %end;
   %else %do;
        __col_0 = trim(left(__prefix))||" "||trim(left(__col_0));
   %end;
   end;
run;

%*---------------------------------------------------------------------------;
%* determine number of non-repeated columns per page
         and stop and start column on each page;
%*---------------------------------------------------------------------------;


%let ncpp=1;
%local cpp1 cstart1 cstop1;
%let cpp1=&lastcol;
%let cstart1=%eval(&lastcheadid+1);
%let cstop1 = &lastcol;

%* adjust minwidth2 so that if unspecified it takes len_8_&i;
%* which is min width so words do not break in the middle;

%local minwidth2 tmp;
%do i=0 %to &lastcol;
  %let tmp=%scan(&minwidth, %eval(&i+1), %str( ));
  %if &tmp=X %then %let tmp = &&len_&i._8;
  %let minwidth2=&minwidth2 &tmp;
%end;


%let minwidth = &minwidth2;

%__ut_prtgcw(breakokat=&breakokat, tw=&tablew, repeatc=&lastcheadid,
             outds=__rtfds_w3, debug=&debug, stretch=&stretch);

%local nofit;
proc sql noprint;
   select max(__nofit) into: nofit from __rtfds_w3;
quit;

%*---------------------------------------------------------------------------;
%* STOP PROGRAM IF TABLE CAN NOT FIT IN AVAILABLE SPACE;
%*---------------------------------------------------------------------------;

%if &nofit>0 %then %do;
   %put &er.&ror: The table can not be fitted
           with column widths and/or breaks assigned;
   %put &er.&ror: consider specifying different colwidths or cpp,
           or use colwidths=fit2page;
   %put &er.&ror: Execution aborted;
   %goto exit;
%end;

%*-------------------------------------------------------------------------;
%* adjust column widths so they add up to width of table;
%*-------------------------------------------------------------------------;
%__UT_prtacw(datain=__rtfds_w3, dataout=__rtfcolw,
            part1=&part1, part2a=&part2a,
            lastcheadid=&lastcheadid, debug=0, stretch=&stretch);

%*-------------------------------------------------------------------------;
%* determine number of lines for titles and footnotes;
%*-------------------------------------------------------------------------;

%local sum1 sum2;
%* sum1: number of lines for titles;
%* sum2: number of lines for footnotes;
%let sum1=0;
%let sum2=0;


%local tmp1;

data __rtftitles;
length __tit $ 2000;
%if &dest=CSR %then %do;
  %__ut_prtgfm;
  array __afm{251} _temporary_ ;
  do i=1 to dim(__afm);
    __afm[i]=__afmn[i];
  end;
%end;

__lt=0;
__lf=0;
%do i=1 %to &numtit;
    __tit = trim(left(symget("ntit&i")));
    %__UT_prtgnl(string=__xxspanned,
       origstring=__tit, delimiter=%str(~-2n),
       tw=&tablew, linesvar=__lt, dest=&dest);
     output;
%end;
%if &dest=APP %then %do;
__tit = trim(left(symget("systitle")));
%__UT_prtgnl(string=__xxspanned,
origstring=__tit, delimiter=%str(~-2n),
tw=&tablew, linesvar=__lt, dest=&dest);
output;
%end;
__lt=0;
%do i=1 %to &numfoot;
    __tit = trim(left(symget("nfoot&i")));
    %__UT_prtgnl(string=__xxspanned,
       origstring=__tit, delimiter=%str(~-2n), tw=&tablew,
       linesvar=__lf, dest=&dest);
     output;
%end;
run;

proc sql noprint;
select sum(__lt) into:sum1 from __rtftitles;
select sum(__lf) into:sum2 from __rtftitles;
quit;

%if &debug>0 %then %put sum1=&sum1 sum2=&sum2 likeascii=&likeascii;

%*----------------------------------------------------------------------;
%* split header dataset to have one header dataset for each column group;
%*----------------------------------------------------------------------;

data __rtfcolumns;
set __rtfcolumnst;
run;


%__UT_prtsd(datain=__rtfcolumnst, lastcheadid=&lastcheadid,
           keepvars=__rowid __varbygrp __align __lastrow);


%__UT_prtsd(datain=__rtfcolumns, lastcheadid=&lastcheadid,
            keepvars=__rowid __varbygrp __align __lastrow);

%*----------------------------------------------------------------------;
%* determine spanned heades;
%*----------------------------------------------------------------------;



%let ncpp=0;
proc sql noprint;
  select count(*) into:ncpp from __rtfds_w3;
quit;

%do i=1 %to &ncpp;
  %__UT_prtph(datain=__rtfcolumnst_&i, group=&i);
%end;


%if &likeascii=1 and &manageph=Y %then %do;

  %if &pagehead=Y %then %do;
  %*----------------------------------------------------------------------;
  %* for each record determine "parent" label,
            and determine how many lines needed for parent;
  %*----------------------------------------------------------------------;

   %local i maxil;
   proc sql noprint;
      select max(__indentlev) into:maxil from __rtfds_w;
   quit;
   %let maxil = %eval(&maxil+1);

   %if &maxil>1 %then %do;

      proc sort data=__rtfds_w;
      by __varbygrp  __rowid ;
      run;

      data __rtfds_w ;
      *length __fc $ 2000;
      set __rtfds_w;
       by __varbygrp  __rowid ;
       %* assumption: parent line  occurs in 1st column only;
       length %do i=1 %to &maxil; __parent&i %end; $ 2000;
       retain %do i=1 %to &maxil;
              __parent&i
              %end;;
       array parent{*} $ 2000 __parent1-__parent&maxil ;
       if __indentlev=. then __indentlev=0;
       if first.__varbygrp then do;
          do __i=1 to &maxil;
            parent[__i]='';
          end;
       end;
       if __indentlev <&maxil-1 then do;
       parent[__indentlev+2] = trim(left(__col_0));
       end;
       run;

       data __rtfds_w ;
      length __fc $ 2000;
      set __rtfds_w;
       by __varbygrp  __rowid ;
       array parent{*} $ 2000 __parent1-__parent&maxil ;
       do __i = __indentlev+2 to &maxil;
         parent[__i]='';
       end;
       %* create appropriate field codes;
       if not first.__varbygrp then do;
       __fc = "{\field{\*\fldinst { SEQ s2 \\h \\r }"||
             "{\field{\*\fldinst {  =}{\field{\*\fldinst { SEQ s3 \\c }}}"||
             "}}}}{\field{\*\fldinst"||
             "{ SEQ s3 \\h \\r}{\field{\*\fldinst {  =}"||
             "{\field{\*\fldinst { page }}}}}}}"||
             "{\field{\*\fldinst { if }"||
             "{\field{\*\fldinst { seq s2 \\c }}}{ =}"||
             "{\field{\*\fldinst { seq s3 \\c }}}"||
             '{ " " "';   /*||trim(left(__col_&i))||'"}}}';*/
        do __i=1 to dim(parent);
           if parent[__i] ne "" then
           __fc  = trim(left(__fc))||trim(left(parent[__i]))||"~-2n";
        end;
        __fc =  left(trim(__fc))||'"}}}'||trim(left(__col_0));
        __col_0 = left(trim(__fc));
       end;
       run;
   %end;
   %end;

   %if &pagehead=N %then %do;

      proc sort data=__rtfds_w;
         by __varbygrp  __rowid;
      run;

      data __rtfds_w;
      set __rtfds_w;
      by __varbygrp   __rowid;
      array repeato{*} __col_0 - __col_&lastcheadid;
      array repeatt{*} $ 2000 __tcol_0 - __tcol_&lastcheadid;
      retain __tcol_0 - __tcol_&lastcheadid;
      __substatid=1;
      do __i=0 to &lastcheadid;
         if repeato{__i+1] ne '' then repeatt[__i+1]=repeato[__i+1];
      end;
      do __i=0 to &lastcheadid;
            repeato[__i+1]=repeatt[__i+1];
      end;
      %* create field codes;
      if not first.__varbygrp then do;
       %do i=0 %to &lastcheadid;
      __col_&i = "{\field{\*\fldinst { SEQ s2&i \\h \\r }"||
             "{\field{\*\fldinst {  =}{\field{\*\fldinst { SEQ s3&i \\c }}}"||
             "}}}}{\field{\*\fldinst"||
             "{ SEQ s3&i \\h \\r}{\field{\*\fldinst {  =}"||
             "{\field{\*\fldinst { page }}}}}}}"||
             "{\field{\*\fldinst { if }"||
             "{\field{\*\fldinst { seq s2&i \\c }}}{ =}"||
             "{\field{\*\fldinst { seq s3&i \\c }}}"||
             '{ " " "'||trim(left(__col_&i))||'"}}}';

       %end;
       end;

      run;
   %end;


%end;



%if &likeascii=2 %then %do;


   %*-------------------------------------------------------------------;
   %* determine number of lines for headers;
   %*-------------------------------------------------------------------;

   %local headerlines;
   %let headerlines=0;

   %do i=1 %to &ncpp;
        data __rtfcolumnst_&i ;
        set __rtfcolumnst_&i;
        length __xxspanned __origstring __tmp $ 3000 ;
        %if &dest=CSR %then %do;
           %__ut_prtgfm;
           array __afm{251} _temporary_ ;
           do i=1 to dim(__afm);
             __afm[i]=__afmn[i];
           end;
         %end;

        %__UT_prtgnl(string=__xxspanned,
         origstring=__spanned, delimiter=%str(~-2n),
             tw=__cellwidth, linesvar=__linesused);
          if __lastrow ne 1 and __nospan ne 1
                then __linesused = __linesused+1;
        run;

     %local headerlines&i;

      proc sql noprint;
       select sum(maxl) into:headerlines&i from
       (select __level, max(__linesused) as maxl
       from __rtfcolumnst_&i group by __level);
      quit;

      %if &&headerlines&i>&headerlines %then %let headerlines=&&headerlines&i;

   %end;

    proc sort data=__rtfcolumns out=__rtfcntheads (keep=__varbygrp) nodupkey;
    by __varbygrp;
    run;

    data __rtfcntheads; set __rtfcntheads;
    by __varbygrp;
    __headerlines = &headerlines;
    run;


   %*------------------------------------------------------------------------;
   %* determine number of lines for "varby" title line
   %*------------------------------------------------------------------------;

   proc sort data=__rtfds_w;
   by __varbygrp;
   run;

   data __rtfds_w;
      set __rtfds_w;
      by __varbygrp;
      retain __linesusedby;
    __linesusedbn=0;
      %if &dest=CSR %then %do;
        %__ut_prtgfm;
        array __afm{251} _temporary_ ;
        do i=1 to dim(__afm);
          __afm[i]=__afmn[i];
        end;
      %end;

      if _n_=1 then __linesusedby=0;
      if first.__varbygrp and __varbylab ne '' then do;
        %__UT_prtgnl(string=__xxspanned,
             origstring=__varbylab, delimiter=%str(~-2n),
             tw=&tablew, linesvar=__linesusedby, dest=&dest);
      end;
      %if &isbanner>0 %then %do;
        if __banner ne '' then do;
           %__UT_prtgnl(string=__xxbanner,
             origstring=__banner, delimiter=%str(~-2n),
             tw=&tablew, linesvar=__linesusedbn, dest=&dest);
        end;
      %end;
   run;


   proc sort data=__rtfds_w;
      by __varbygrp  __rowid ;
   RUN;

   %*------------------------------------------------------------------------;
   %* determine number of lines for column variables;
   %* dtermine total number of lines per groups
         that are to be kept on the same page;
   %* these are deremined by __keepn=0 variable;
   %*------------------------------------------------------------------------;

   %local colw0 colw;
   %let colw=;
   proc sql noprint;
      %do i=0 %to &lastcheadid;
      %local __cw;
      %let __cw=;
      select min(__colw_&i) into:__cw from __rtfds_w3;
      %let colw  = &colw &__cw;
      %*put colw=&colw;
   %end;
   select __partcolw into:colw0 separated by ' ' from __rtfcolw;
   %let colw = %sysfunc(compbl(&colw &colw0));
   quit;
   %*put colw=&colw;


   data __rtfds_w;
      merge __rtfds_w __rtfcntheads;
      by __varbygrp;
   run;

   %if &isbanner>0 %then %do;
   proc sort data=__rtfds_w;
   by __varbygrp __bannerid __rowid;
   run;
   %end;

   data __rtfds_w __rtfkeepcnt(keep=__keepcnt  __keepgroup __varbygrp);
      set  __rtfds_w end=eof;
    %if &isbanner>0 %then %do;
       by __varbygrp __bannerid __rowid;
    %end;
    %else %do;
      by __varbygrp;
      %end;
      array cols{*} __col_0-__col_&lastcol;
      array nw{%eval(&lastcol+1)} %do i=0 %to &lastcol; __len_&i._5 %end;;
      retain __keepgroup 0 __keepcnt 0 ;

      __colw =symget('colw');
      __titlelines=&sum1;
      /*%if &dest=APP %then %do; __titlelines=1+&sum1; %end;*/
      __footlines=1+&sum2;

      __linesused=1;


      *tmp1 = nw[1];
      tmp2 = input(scan(__colw, 1, ' '),12.)-__tmpli;
      %* actual available width for printing;
    %__UT_prtgnl(string=__xxspanned,
       origstring=cols[1], delimiter=%str(~-2n),
       tw=tmp2, linesvar=__curline, dest=&dest);
      *__curline = ceil(tmp1/tmp2);
      __linesused = max(__linesused, __curline);

      do __i=2 to &lastcol+1;
         *tmp1 = nw[__i];
         tmp2 = input(scan(__colw, __i, ' '),12.);
         %__UT_prtgnl(string=__xxspanned,
           origstring=cols[__i], delimiter=%str(~-2n),
           tw=tmp2, linesvar=__curline, dest=&dest);

         *__curline = ceil(tmp1/tmp2);
         __linesused = max(__linesused,__curline);
      end;


      if index(__suffix,"~-2n")>0  then __linesused=__linesused+1;


      %if &isbanner>0 %then %do;
          if __banner ne '' then __linesused = __linesused+__linesusedbn;
      %end;
      __keepcnt=__keepcnt+__linesused;
      if __keepn ne 1 or last.__varbygrp then do;
         output __rtfkeepcnt;
         output __rtfds_w;
         __keepgroup=__keepgroup+1;
         __keepcnt=0;
      end;
      else output __rtfds_w;

   run;

   %*----------------------------------------------------------------------;
   %* for each record determine "parent" label,
            and determine how many lines needed for parent;
   %*----------------------------------------------------------------------;

   %local maxil;
   proc sql noprint;
      select max(__indentlev) into:maxil from __rtfds_w;
   quit;
   %let maxil = %eval(&maxil+1);

   %if &maxil>1 %then %do;

      data __rtfds_w;
      set __rtfds_w;
       by __varbygrp  __rowid ;
       %* assumption: parent line  occurs in 1st column only;
       length %do i=1 %to &maxil; __parent&i __parentprefix_&i %end; $ 2000;
       retain %do i=1 %to &maxil;
              __parent&i __parentl&i __parentprefix_&i
              %end;;
       array parent{*} $ 2000 __parent1-__parent&maxil ;
       array parentl{*}  __parentl1-__parentl&maxil ;
       array parentprefix{*} $ 2000  __parentprefix_1-__parentprefix_&maxil;

       if __indentlev=. then __indentlev=0;

       if __col_0 ne '' then do;
       parent[__indentlev+1] = trim(left(__col_0));
       parentprefix[__indentlev+1] = trim(left(__prefix));
       parentl[__indentlev+1] = __linesused;
     end;
     /*
       do __i = __indentlev+2 to &maxil;
         parent[__i]='';
         parentl[__i]=0;
         parentprefix[__i]='';
       end;
     */
      run;

      data __rtfds_w ;
       set __rtfds_w;
     by __varbygrp  __rowid ;
       array parent{*} $ 2000 __parent1-__parent&maxil;
       array parentl{*} __parentl1-__parentl&maxil;
       array parentprefix{*} $ 2000  __parentprefix_1-__parentprefix_&maxil ;
     if first.__varbygrp then do;
          do __i=1 to &maxil;
            parent[__i]='';
            parentprefix[__i]='';
            parentl[__i]=0;
          end;
       end;

       parent[__indentlev+1]='';
       parentl[__indentlev+1]=0;
       parentprefix[__indentlev+1]='';
       __phlines=0;
       do __i=1 to &maxil;
          __phlines = max(__phlines, parentl[__i]);
       end;
     __phlines=__phlines+__linesusedbn;
      run;

   %end;

   %else %do;

      %let pagehead=N;

      data __rtfds_w;
      set __rtfds_w;
      __phlines=__linesusedbn;
   %end;



   %if %sysfunc(exist(__rtfkeepcnt)) %then %do;

      proc sort data=__rtfkeepcnt;
         by __varbygrp __keepgroup;
      run;

      proc sort data=__rtfds_w;
         by __varbygrp __keepgroup;
      run;

      data __rtfds_w;
         merge __rtfds_w(in=__a drop=__keepcnt) __rtfkeepcnt;
         by __varbygrp __keepgroup;
         if __a;
         if __keepcnt=. then __keepcnt=0;
      run;

      proc sort data=__rtfds_w;
         by __varbygrp  __rowid;
      run;
   %end;




   %*------------------------------------------------------------------------;
   %* determine page breaks;
   %*------------------------------------------------------------------------;

   %local maxind;
   proc sql noprint;
      select max(__indentlev) into:maxind from __rtfds_w;
   quit;

   data __rtfds_w;
      set __rtfds_w ;
      by __varbygrp;
      retain __lsf __pagenum ;

      __pageheadlines=__phlines;
      __lpp=&pagelines;
      __pagemax = __lpp-__headerlines-__titlelines-__footlines-__linesusedby;

      if last.__varbygrp then __keepn=1;
      __keepn2 = lag(__keepn);
      %* __keepn2=1 means page break shoudl not occur,else page break allowed;
      if _n_=1 then do;
         __pagenum=0;
         __lsf=0;
      end;

      __breakok=0;
      if __keepn2 ne 1 then __breakok =1;


      if __breakok=1  then do;
         __tmp=__linesused;
         if __suffix="~-2n" then do;
            __tmp = __linesused-1;
            __keepcnt=__keepcnt-1;
         end;
         if (__lsf+__tmp>__lpp) or (first.__varbygrp)  or __pagebb ne '' or
            (__lsf+__keepcnt>__lpp and __keepcnt<=__pagemax)  then do;
            %if &dest=APP %then %do;
               __lsf=__titlelines+__footlines+__headerlines
                      +__linesusedby+__linesused;
               if not first.__varbygrp then
                     __lsf=__lsf+__pageheadlines;
            %end;
            %else %do;
               __lsf=__headerlines+__linesused;
               if first.__varbygrp
                   then __lsf=__lsf+__titlelines+__linesusedby;
               else __lsf=__lsf+__titlelines+__linesusedby+__pageheadlines;
            %end;
            __pagenum  =__pagenum+1;
         end;
         else __lsf=__lsf+__linesused;
      end;
      else do;
         __tmp=__linesused;
         if __suffix="~-2n" then do;
            __tmp = __linesused-1;
         end;
         if (__lsf+__tmp>__lpp) or (first.__varbygrp) or __pagebb ne ''
         then do;
            %if &dest=APP %then %do;
               __lsf=__titlelines+__footlines+__headerlines
                       +__linesusedby+__linesused;
               if not first.__varbygrp then __lsf=__lsf+__pageheadlines;
            %end;
            %else %do;
               __lsf=__headerlines+__linesused;
               if first.__varbygrp
                   then __lsf=__lsf+__titlelines+__linesusedby;
               else __lsf=__lsf+__titlelines+__linesusedby+__pageheadlines;
            %end;
            __pagenum  =__pagenum+1;
         end;
         else __lsf=__lsf+__linesused;
      end;

   run;

run;


   %*-----------------------------------------------------------------------;
   %* if pagehead=N then for beginning of page print repeatdcols;
   %*-----------------------------------------------------------------------;

  %* todo: this may create a problem if this repeated info takes more than
     one line -- for the future, determine max lines used by repeated page
     heads and add to extralines;

   %if &pagehead=N %then %do;

      proc sort data=__rtfds_w;
         by __varbygrp __pagenum  __rowid;
      run;

      data __rtfds_w;
      set __rtfds_w;
      by __varbygrp __pagenum  __rowid;
      array repeato{*} __col_0 - __col_&lastcheadid;
      array repeatt{*} $ 2000 __tcol_0 - __tcol_&lastcheadid;
      retain __tcol_0 - __tcol_&lastcheadid;
      __substatid=1;
      do __i=0 to &lastcheadid;
         if repeato{__i+1] ne '' then repeatt[__i+1]=repeato[__i+1];
      end;
      if first.__pagenum then do;
         do __i=0 to &lastcheadid;
            repeato[__i+1]=repeatt[__i+1];
         end;
      end;
      run;


   %end;


   proc sort data=__rtfds_w;
   by __varbygrp __pagenum  __rowid;
   run;

   %*-------------------------------------------------------------------------;
   %* add records for the top of the page etc;
   %*-------------------------------------------------------------------------;

   %if &pagehead ne N %then %do;

      data __rtfds_w;
      set __rtfds_w;
      by __varbygrp __pagenum  __rowid;
      %if &maxil>1 %then %do;
         array parent{*} $ 2000 __parent1-__parent&maxil;
         array parentprefix{*} $ 2000 __parentprefix_1-__parentprefix_&maxil;
      %end;
      __substatid=1;
      output;
      if first.__pagenum and __indentlev>0 then do;
         do __i=1 to __indentlev;
            __substatid=__i/100;
            %do i=0 %to &lastcol;
              __col_&i='';
            %end;
            %if &maxil>1 %then %do;
             __col_0=parent[__i];
             __prefix = parentprefix[__i];
             __suffix='';
            %end;
            output;
         end;
      end;
      run;

      proc sort data=__rtfds_w;
      by __varbygrp __pagenum  __substatid  __rowid;
      run;

  %end;

   %local maxpages ;
   %let maxpages=1;

   %if &ncpp=1 %then %do;

      %* simplify rtf if all columns fit on one page;

      data __rtfds_w (rename=(__npnum=__pagenum));
         set __rtfds_w ( rename=(__pagenum=__oldpagenum));
         by __varbygrp __oldpagenum  __substatid __rowid;
         retain __npnum;
         if _n_=1 then __npnum=0;
         if first.__varbygrp then __npnum+1;
         if first.__oldpagenum and not first.__varbygrp then do;
            __pagebb='\pagebb';
         end;
         run;
      /*%if &dest=APP %then %do; %let maxbid=1;  %end;*/
   %end;

   %else %do;
      data __rtfds_w;
      set __rtfds_w;
      __oldpagenum=1;
      run;

   proc sql noprint;
      select max(__pagenum) into:maxpages from __rtfds_w;
   quit;

   %end;


/*
   proc sql noprint;
      select max(__pagenum) into:maxpages from __rtfds_w;
   quit;
*/

%end;

%local keep;
%let keep = __align __prefix __suffix __keepn __varbygrp __varbylab ;
%let keep= &keep __pagebb __rowid  ;
%if &isbanner>0 %then %let keep= &keep __banner __bannerid;

%if &likeascii=2 %then %do;
   %let keep=&keep __pagenum __oldpagenum ;
%end;



%__UT_prtsd(datain=__rtfds_w, lastcheadid=&lastcheadid,
              keepvars=&keep, keeplengths=1);

%let fontsize=%qtrim(&fontsize);


%if &orient=L %then %do;
options missing='' center;
%end;
%else %do;
options missing='' center;
%end;

%*put title1 = &&title1;
%do i=1 %to 8;
 %*put footnote&i=&&footnot&i;
%end;


%*put ncpp=&ncpp;
%local ii jj kk start kkk jjj;

%do kkk=1 %to &maxbid;


%do jj=1 %to &ncpp;

   %*------------------------------------------------------------------------;
   %* subset header info dataset to keep only those columns;
   %*------------------------------------------------------------------------;

   data __rtfforreportstr ;
   set __rtfcolumns_&jj
    (where=(__varbygrp=&kkk))
   ;
   run;

   %*------------------------------------------------------------------------;
   %* define widths in inches;
   %*------------------------------------------------------------------------;

   %local colw&jj colw_&jj colstr&jj header&i._&j halign&i._&jj newrpar&jj newpart2a&jj lastcol_&jj;
   %** IP 2008-12-19;
   
   proc sql noprint;
      select __colw into: colw&jj from __rtfcolw where __colgrp=&jj;
      select __allcols into:lastcol_&jj from __rtfcolw where __colgrp=&jj;
      select __part1 into: newrpar&jj from __rtfcolw where __colgrp=&jj;
      select __part2 into: newpart2a&jj from __rtfcolw where __colgrp=&jj;
   quit;

   %let lastcol_&jj=%cmpres(&&lastcol_&jj);
   %let colw_&jj=%cmpres(&&colw&jj);
   %let newrpar&jj=%cmpres(&&newrpar&jj);
   %let newpart2a&jj=%cmpres(&&newpart2a&jj);

   %do ii=0 %to &&lastcol_&jj;
      %local cw&i._&jj cwo&i._&jj np1_&i._&jj np2_&i._&jj ;
      %local header&i._&jj halign&i._&jj;
   %end;



   %let cwo0_&jj = %eval(%scan(&&colw&jj,1,%str( ))-20);
   %let np1_0_&jj = %scan(&&newrpar&jj,1,%str( ));
   %let np2_0_&jj = %scan(&&newpart2a&jj,1,%str( ));
   %let np2_0_&jj = %eval(&&np1_0_&jj+&&np2_0_&jj);
   %*let cw0_&jj = %sysevalf(&&cwo0_&jj/1440);
   %let cw0_&jj = %sysevalf(10000*&&cwo0_&jj./&tablew, floor);
   %let cw0_&jj = %sysevalf(&&cw0_&jj./100);
   %*let cw0_&jj = %sysfunc(round(&&cw0_&jj,0.001))IN;
   %do i=1 %to %eval(&&lastcol_&jj);

     %let cwo&i._&jj = %eval(%scan(&&colw&jj,%eval(&i+1),%str( ))-20);

     %let np1_&i._&jj = %scan(&&newrpar&jj,%eval(&i+1),%str( ));
     %let np2_&i._&jj = %scan(&&newpart2a&jj,%eval(&i+1),%str( ));
     %let np2_&i._&jj = %eval(&&np1_&i._&jj+&&np2_&i._&jj);
     %*let cw&i._&jj = %sysevalf(&&cwo&i._&jj/1440);
     %let cw&i._&jj = %sysevalf(10000*&&cwo&i._&jj./&tablew, floor);
   %let cw&i._&jj = %sysevalf(&&cw&i._&jj./100);
     %*let cw&i._&jj = %sysfunc(round(&&cw&i._&jj,0.001))IN;
   %end;


   %*-----------------------------------------------------------------------;
   %* define columns for proc report;
   %*-----------------------------------------------------------------------;



   %local border;
   %let border=\brdrb\brdrs\brdrw15;

   %local numh;
   proc sql noprint;
   select count(*) into:numh from __rtfforreportstr;
   quit;
   %let numh = %cmpres(&numh);

    data __rtfinull_&jj;
  length __nc_0-__nc_&&numh
         __st_0-__st_&&lastcol_&jj __st1_0-__st1_&&lastcol_&jj
         __st2_0-__st2_&&lastcol_&jj __st3_0-__st3_&&lastcol_&jj
    __tmp1 __tmp2 __tmp3  __tmp4  __tmpstart __tmpstop __bottomlines 
   __startcolnum __stopcolnum __nstartcolnum __nstopcolnum __tmpstr
     $ 2000;
  set __rtfforreportstr end=eof;

  __tmp1=''; __tmp2=''; __tmp3='';

  array newcols {*} $ 2000 __nc_0-__nc_&numh;
  array astarts {*} $ 2000 __st_0-__st_&&lastcol_&jj ;
  array astarts2 {*} $ 2000 __st1_0-__st1_&&lastcol_&jj ;
  array astops {*} $ 2000 __st2_0-__st2_&&lastcol_&jj;
  array astops2 {*} $ 2000 __st3_0-__st3_&&lastcol_&jj;
  array cols {*} $ 2000 __col_0-__col_&&lastcol_&jj ;
   array widths {*} __w0-__w&&lastcol_&jj;

  retain __startcolnum __stopcolnum __nc_0 -__nc_&numh
             __st_0-__st_&&lastcol_&jj __st1_0-__st1_&&lastcol_&jj;

   __split = compress(symget('split'));
   __split=dequote(__split);

   do __i=1 to %EVAL(&&lastcol_&jj+1);
   cols[__i]=tranwrd(trim(left(cols[__i})), "{\b}", " ");
      cols[__i]=trim(left(cols[__i]));
      %if %length(&split)>0 %then %do;
         cols [__i]=tranwrd(cols[__i], compress(__split), ' ');
      %end;
   end;
 
  if _n_=1 then   do;
     __startcolnum='0';
   __stopcolnum = "&&lastcol_&jj";
  end;
  __nstartcolnum='';
  __nstopcolnum='';
 
  __ngrpf = countw(__startcolnum,' ');
   *put;
   *put;
   *put __ngrpf = __startcolnum= __stopcolnum=;


  %do i=1 %to %eval(&&lastcol_&jj+1);
     widths[&i]= %scan(&&colw&jj,&i,%str( ));
  %end;

  if _n_>1 then newcols[_n_] =newcols[_n_-1];


  if __ngrpf=0 then do;
  *put;
  *put;
     if not eof then do;
         do __i=0 to &&lastcol_&jj;
           __tmp2 = '("'||trim(left(cols[__i+1]))||'" __col_'
                          ||compress(put(__i, 12.))||" )";
           __tmp3 = "__col_"||compress(put(__i, 12.));
           *put;
           *put "tmp3=" __tmp3 "tmp2=" __tmp2 "newcolsn=" newcols[_n_];
           newcols[_n_] = tranwrd(newcols[_n_], " "||trim(left(__tmp3))
                     ||" ", " "||trim(left(__tmp2))||" ");
           *put "new newcolsn=" newcols[_n_];
         end;

     end;

  end;


  
  do __j=1 to __ngrpf;
    if _n_=1 then do;
      __tmpstart_=0;
      __tmpstop_=&&lastcol_&jj;
    end;
    if _n_>1 then do;
       __tmpstart = scan(__startcolnum, __j, ' ');
       __tmpstop  = scan(__stopcolnum, __j, ' ');
       __tmpstart_ = input(__tmpstart,12.);
       __tmpstop_  = input(__tmpstop,12.);
    end;
    if __tmpstart_ >=0  then do;
      __tmp3='';
      __tmp1=cols[__tmpstart_+1];
      __tmp2='';
      __start=__tmpstart_;
      __stop=__start;
      __notfinished=0;

      do __i=__tmpstart_ to __tmpstop_;
         if eof then do;
              __tmp2 = trim(left(__tmp2))||" __col_"||compress(put(__i, 12.));
         end;
         else do;
           if cols[__i+1] = __tmp1 then do;
              __stop=__i;
        __notfinished=0;
           end;
           else do;
             __tmp3 = "<"||compress(put(__start,12.))||"-"||compress(put(__stop,12.))||">";
             __totalw=0;
             __tmp4='';
             do __k=__start to __stop;
                __totalw=__totalw+widths[__k+1];
                __tmp4 = trim(left(__tmp4))||" __col_"||compress(put(__k,12.));
             end;
             %if &dest=APP %then %do;
                __totalw = max(2, floor((__totalw)/(&fontsize*12))-5);
                __bottomlines = "~-2n"||repeat("_", __totalw);
             %end;
             %else %do;
                __totalw = __totalw-80;
                __bottomlines = "\par\tab\tab\tql\tx80\tlul\tx"||compress(put(__totalw,12.));
             %end;
             if __stop=__start then __bottomlines="~-2n ";
             if compress(__tmp1) in ("", "\b\b0") then __bottomlines="";
             __tmp2=trim(left(__tmp2))||' ("'||trim(left(__tmp1))||trim(left(__bottomlines))||'" ';
             __tmp2=trim(left(__tmp2))||" "||trim(left(__tmp4))||" )";
             __tmp1 = cols[__i+1];
             __notfinished=1;
       __nstartcolnum=cats(__nstartcolnum)||" "||cats(__start);
       __nstopcolnum=cats(__nstopcolnum)||" "||cats(__stop);

             __start=__i;
             __stop=__start;
       
           end; ** else;
         end; ** not eof;
      end; **do __i=__tmpstart_ to __tmpstop_;

       __totalw=0;
       __tmp4='';
       do __k=__start to __tmpstop_;
           __totalw=__totalw+widths[__k+1];
           __tmp4 = trim(left(__tmp4))||" __col_"||compress(put(__k,12.));
       end;
       %if &dest=APP %then %do;
         __totalw =max(2, floor( (__totalw)/(&fontsize*12))-2)-1;
         __bottomlines = "~-2n"||repeat("_", __totalw);
       %end;
       %else %do;
         __totalw = __totalw-80;
         __bottomlines = "\par\tab\tab\tql\tx80\tlul\tx"||compress(put(__totalw,12.));
       %end;
       if __tmpstop_=__start then __bottomlines="~-2n";
       if compress(__tmp1) in ("", "\b\b0") then __bottomlines="";
       if __notfinished=1 then do;
          __tmp3 = "<"||compress(put(__start,12.))||"-"||compress(put(__tmpstop_,12.))||">";
          __tmp2=trim(left(__tmp2))||' ("'||trim(left(__tmp1))||trim(left(__bottomlines))||'" ';
          *astarts[__cnt]=__tmp3;
          *astarts2[__cnt]=__tmp4;
          __tmp2=trim(left(__tmp2))||" "||trim(left(__tmp4))||" )";
          __nstartcolnum=cats(__nstartcolnum)||" "||cats(__start);
      __nstopcolnum=cats(__nstopcolnum)||" "||cats(__tmpstop_);
          

       end; **if __notfinished=1 then do;
       else do;
          if not eof then do;
               __tmp2=trim(left(__tmp2))||' ("'||trim(left(__tmp1))||trim(left(__bottomlines))||'" ';
               __tmp2=trim(left(__tmp2))||" "||trim(left(__tmp4))||" )";
         __nstartcolnum=cats(__nstartcolnum)||" "||cats(__start);
         __nstopcolnum=cats(__nstopcolnum)||" "||cats(__tmpstop_);
           
          end;
       end;
      if _n_>1 then do;
         __tmpstr = '';
       do __i =input(scan(__startcolnum,__j,' '),best.) to input(scan(__stopcolnum,__j,' '),best.);
             __tmpstr = cats(__tmpstr)||" "||cats("__col_",__i);
       end;
       *put __j= __startcolnum= __stopcolnum= __tmpstr= __tmp2=;
       *put newcols[_n_]=;
           newcols[_n_] = tranwrd(newcols[_n_], " "||cats(__tmpstr)||" ", " "||trim(left(__tmp2))||" ");
       *put;
       *put "new" newcols[_n_]=;
    end;
      else newcols[_n_]=__tmp2;
    end; **if __tmpstart_ >=0  then do;
  end; ** do __j=1 to __ngrpf;

  __startcolnum = __nstartcolnum;
  __stopcolnum  = __nstopcolnum;

 
  if eof then do;
    newcols[_n_]=compbl(newcols[_n_]);
    newcols[_n_]=tranwrd(trim(left(newcols[_n_])), '\b \b0','');
    if newcols[_n_]='' then do;
      %do jjj=0 %to &&lastcol_&jj;
          newcols[_n_]= trim(left(newcols[_n_]))||" "||"__col_&jjj";
      %end;
    end;
    call symput ("colstr&jj", newcols[_n_]);
    %do i=0 %to &&lastcol_&jj;
        call symput("header&i._&jj", trim(left(__col_&i)));
        call symput("halign&i._&jj", scan(__align, &i+1, ' '));
    %end;
  end;

  run;


   %do ii=0 %to &&lastcol_&jj;
      %if (&&halign&ii._&jj ne C) and (&&halign&ii._&jj ne R)
         and (&&halign&ii._&jj ne L)  %then
         %let halign&ii._&jj = C ;
         %*put halign&ii._&jj =&&halign&ii._&jj ne C ;
   %end;



   %*------------------------------------------------------------------------;
   %* subset report dataset to keep only relevant columns;
   %*------------------------------------------------------------------------;


   data __rtfforreport_&jj;
   set __rtfds_w_&jj /*%if &ncpp>1 or &dest=CSR  %then %do;*/
          (where=(__varbygrp=&kkk))
    /*%end;*/;
   __recid=_n_;
   run;

   %local varbytit;


   %if &dest=CSR %then %do;

   %*------------------------------------------------------------------------;
   %* for RTF: insert tabs for decimal alignment;
   %*------------------------------------------------------------------------;


      data __rtfforreport_&jj;
      length   __wrd: $ 2000 __tmpalign $ 2 ;
      set __rtfforreport_&jj;

      array cols {*} $ 2000 __col_0-__col_&&lastcol_&jj;
      array wrd1f {*} $ 2000 __wrd1f_0-__wrd1f_&&lastcol_&jj;
      array wrd2f {*} $ 2000 __wrd2f_0-__wrd2f_&&lastcol_&jj;

      __align = trim(left(compbl(__align)));


      do __i=1 to dim(cols);
         __tmpalign = scan(__align, __i, ' ');
       cols[__i] = left(cols[__i]);
       if __tmpalign in ('DD', 'RD') then do;
       wrd1f[__i] = trim(left(scan(cols[__i], 1, " ")));
       __indp=index(cols[__i]," ");
       if __indp>0 then do;
          wrd2f[__i] = trim(substr(cols[__i], __indp+1));
       end;
       if wrd2f[__i] ne '' then
       cols[__i]=trim(left(wrd1f[__i]))||"{\tab}"
             ||trim(left(wrd2f[__i]));
       end;
    end;
       run;

   %end;

   %else %do;

   %*------------------------------------------------------------------------;
   %* for Courier font only: add padding spaces;
   %*------------------------------------------------------------------------;


   data __rtfforreport_&jj;
      length   __wrd: $ 2000 __tmpalign $ 2 ;
      set __rtfforreport_&jj;

      array cols {*} $ 2000 __col_0-__col_&&lastcol_&jj;
      array wrd1 {*} $ 2000 __wrd1_0-__wrd1_&&lastcol_&jj;
      array wrd2 {*} $ 2000 __wrd2_0-__wrd2_&&lastcol_&jj;
      array wrd1f {*} $ 2000 __wrd1f_0-__wrd1f_&&lastcol_&jj;
      array wrd2f {*} $ 2000 __wrd2f_0-__wrd2f_&&lastcol_&jj;
      array wrd1a {*} $ 2000 __wrd1a_0-__wrd1a_&&lastcol_&jj;
      array wrd1b {*} $ 2000 __wrd1b_0-__wrd1b_&&lastcol_&jj;
      array wrd2a {*} $ 2000 __wrd2a_0-__wrd2a_&&lastcol_&jj;
      array wrd2b {*} $ 2000 __wrd2b_0-__wrd2b_&&lastcol_&jj;
      array l1 {*} __l1_0-__l1_&&lastcol_&jj;
      array l2 {*} __l2_0-__l2_&&lastcol_&jj;
      array l3 {*} __l3_0-__l3_&&lastcol_&jj;

      __align = trim(left(compbl(__align)));


      do __i=1 to dim(cols);
         __tmpalign = scan(__align, __i, ' ');
       cols[__i] = left(cols[__i]);

       wrd1[__i] = trim(left(scan(cols[__i], 1, " .")));
       wrd2[__i] = trim(left(scan(cols[__i], 2, " ")));
       wrd1f[__i] = trim(left(scan(cols[__i], 1, " ")));
       __indp=index(cols[__i]," ");
       if __indp>0 then
          wrd2f[__i] = trim(substr(cols[__i], __indp+1));
       wrd1a[__i] = scan(wrd1[__i], 1, ".%()");
       wrd1b[__i] = scan(wrd1[__i], 2, ".%()");
       wrd2a[__i] = scan(wrd2[__i], 1, ".%()");
       wrd2b[__i] = scan(wrd2[__i], 2, ".%()");
       if __tmpalign in ('D', 'RD', 'DD')
              then l1[__i] = length(wrd1[__i]); else l1[__i]=0;
       if __tmpalign in ('RD')
             then l2[__i] = length(wrd2a[__i]); else l2[__i]=0;
       l3[__i] = length(cols[__i]);
       if index(cols[__i], "~{super")>0 then l3[__i]=l3[__i]-9;
    end;
   run;


   proc sql noprint;
   %do i=0 %to &&lastcol_&jj;
      %local maxl1&i maxl2&i maxl3&i;
      select max(__l1_&i) into: maxl1&i from __rtfforreport_&jj;
      select max(__l2_&i) into: maxl2&i from __rtfforreport_&jj;
      select max(__l3_&i) into: maxl3&i from __rtfforreport_&jj;
      %*put maxl1&i = &&maxl1&i  maxl2&i = &&maxl2&i maxl3&i = &&maxl3&i;
   %end;
   quit;


   data __rtfforreport_&jj;
   length __tmpalign $ 2 ;
   set __rtfforreport_&jj;

   array cols {*} $ 2000 __col_0-__col_&&lastcol_&jj;
   array wrd1 {*} $ 2000 __wrd1_0-__wrd1_&&lastcol_&jj;
   array wrd1f {*} $ 2000 __wrd1f_0-__wrd1f_&&lastcol_&jj;
   array wrd2 {*} $ 2000 __wrd2_0-__wrd2_&&lastcol_&jj;
   array wrd2f {*} $ 2000 __wrd2f_0-__wrd2f_&&lastcol_&jj;
   array wrd1a {*} $ 2000 __wrd1a_0-__wrd1a_&&lastcol_&jj;
   array wrd1b {*} $ 2000 __wrd1b_0-__wrd1b_&&lastcol_&jj;
   array wrd2a {*} $ 2000 __wrd2a_0-__wrd2a_&&lastcol_&jj;
   array wrd2b {*} $ 2000 __wrd2b_0-__wrd2b_&&lastcol_&jj;
  __tmpalign='';


  %do i=0 %to &&lastcol_&jj;
     __tmpalign = scan(__align, %eval(&i+1), ' ');
     if __tmpalign in ('DD', 'RD') then do;
        * put "wordlf_&i=" __wrd1f_&i;
         if __wrd1f_&i ne "" then do;
            __diff=&&maxl1&i-__l1_&i;
            if __diff=1 then __col_&i = " "||trim(__wrd1f_&i);
            else if __diff>1 then do;
               __diff=__diff-1;
               __col_&i = repeat(" ", __diff)||trim(__wrd1f_&i);
            end;
            else __col_&i = trim(__wrd1f_&i);
         end;
         *put "diff=" __diff 3. "__col_&i=" __col_&i;
         if __wrd2f_&i ne "" then do;
            __diff=&&maxl2&i-__l2_&i;
              if __diff in (0) then __col_&i = trim(__col_&i)||" "
                 ||trim(__wrd2f_&i);
              else if __diff in (1) then __col_&i = trim(__col_&i)||"  "
                 ||trim(__wrd2f_&i);
            else if __diff>1 then do;
               *__diff=__diff-1;
               __col_&i =trim(__col_&i)||repeat(" ", __diff)||trim(__wrd2f_&i);
            end;
            else __col_&i = trim(__col_&i)||trim(__wrd2f_&i);

         end;
  *        put "2nd diff=" __diff 3.  "__col_&i=" __col_&i;
         %* add padding if actual total width > needed total width;
          __tmp = (floor(&&cwo&i._&jj./(12*&fontsize)) -&&maxl3&i.-2)/2-1;
          * __tmp = (floor(&&cwo&i._&jj./
              (12*&fontsize))-length(__col_&i)-2)/2-1;

           if __tmp=0 then __col_&i = " "||trim(__col_&i);
           else if __tmp>0 then __col_&i = repeat(" ", __tmp)||trim(__col_&i);
           if __col_&i ne "" then __col_&i = "~m"||trim(__col_&i);
  *        put "final __col_&i=" __col_&i;
  *        put;
     end;
     else if __tmpalign in ('D') then do;
         if __wrd1f_&i ne "" then do;
            __diff=&&maxl1&i-__l1_&i;
            if __diff=1 then __col_&i = " "||trim(__wrd1f_&i);
            else if __diff>1 then do;
               __diff=__diff-1;
               __col_&i = repeat(" ", __diff)||trim(__wrd1f_&i);
            end;
            else __col_&i = trim(__wrd1f_&i);
         end;
  *        put "__col_&i=" __col_&i;
         if __wrd2f_&i ne "" then do;
            __col_&i = trim(__col_&i)||" "||trim(__wrd2f_&i);
         end;
  *        put "__col_&i=" __col_&i;
         %* add padding if actual total width > needed total width;

          __tmp = (floor(&&cwo&i._&jj./(12*&fontsize)) -&&maxl3&i.-2)/2-1;
           if __tmp=0 then __col_&i = " "||trim(__col_&i);
           else if __tmp>0 then __col_&i = repeat(" ", __tmp)||trim(__col_&i);

           if __col_&i ne "" then __col_&i = "~m"||trim(__col_&i);
  *        put "final __col_&i=" __col_&i;
     end;

     else if __tmpalign = 'C' then do;
        __col_&i ="~S={just=center}"||trim(left(__col_&i));
     end;
     else if __tmpalign = 'R' then do;
        __col_&i ="~S={just=right}"||trim(left(__col_&i));
     end;
     else if __tmpalign = 'L' then do;
        __col_&i ="~S={just=left}"||trim(left(__col_&i));
     end;

     else if __tmpalign = 'DD' then do;
        __col_&i ="~S={JUST=DEC}"||trim(left(__col_&i));
     end;

  %end;

   run;

   %end;

   data __rtfforreport_&jj;
   set  __rtfforreport_&jj;
   length __tmpalign $ 2;
   __tmpalign='C';
      %* add indentation;
      *if __prefix ne '' then __col_0 = trim(__prefix)||" "||trim(__col_0);
      *if __suffix ='~-2n' then __col_0 = trim(__col_0)||'~-2n~-2n';
      if _n_=1 then do;
        call symput("varbytit", trim(left(__varbylab)));
      end;
      if __suffix ='~-2n' then do;
      %do i=0 %to &&lastcol_&jj;
        __col_&i = trim(__col_&i)||'~-2n~-2n';
      %end;
      end;
      %if &dest=CSR %then %do;
         if __pagebb='\pagebb' then __col_0 = "\pagebb "||trim(left(__col_0));
         * apply alignment;
         __align = trim(left(compbl(__align)));
         %do i=0 %to &&lastcol_&jj;
            __tmpalign = scan(__align, %eval(&i+1), ' ');
            if __tmpalign in ('RD') then __col_&i =
                 "\tqr\tx&&np1_&i._&jj.\tqdec\tx&&np2_&i._&jj.\tab "
                 ||trim(left(__col_&i));
            else if __tmpalign in ('D') then __col_&i =
                 "\tqdec\tx&&np1_&i._&jj. "
                 ||trim(left(__col_&i));
            else if __tmpalign in ('DD') then __col_&i =
                 "\tqdec\tx&&np1_&i._&jj.\tqdec\tx&&np2_&i._&jj.\tab "
                 ||trim(left(__col_&i));
            else if __tmpalign in ('C')
                 then __col_&i = "\qc "||trim(left(__col_&i));
            else if __tmpalign in ('R')
                 then __col_&i = "\qr "||trim(left(__col_&i));
            else if __tmpalign in ('L')
                 then __col_&i = "\ql "||trim(left(__col_&i));
         %end;
         if __keepn=1 then __col_0 ="\keepn "||trim(left(__col_0));
      %end;
   run;

   %let varbytit=%nrbquote(&varbytit);


   %let titlef0 = %nrbquote(\brdrb\brdrs\brdrw15\ql\b) &titlef0;
   %local titlef;
   %let titlef=&titlef0;
   %if %length(&varbytit) %then %do;
       %let titlef =  &titlef.~-2n&varbytit;
   %end;



   %if &likeascii=1 %then %do;

      proc report data=__rtfforreport_&jj nowindows
         %if %length(&split) %then %do; split="&split" %end;
        style(report)={&protectstr rules=groups frame=&frame }
        style(header)={&protectstr   rules=all
                          frame=hsides bordercolor=black}
        style(lines)={just=l &protectstr 
                          rules=none bordercolor=black}
                       ;
      by __varbygrp __varbylab;

      %if &dest=APP %then %do;
         %if %length(&systitle) %then %do;
         title j=l "&systitle" j=r "Page ~{thispage} of ~{lastpage}";
        
         %end;
         %else %do;
         title j=r "Page ~{thispage} of ~{lastpage}";
         %end;

         %local cnt;
         %let cnt=2;
         %do i=1 %to &numtit;
               title&cnt j=c "&&ntit&i" ;
               %let cnt = %eval(&cnt+1);
         %end;
         /*%if %length(&varbytit) %then %do;*/
     %if &vnum1>0 %then %do;
          /* title&cnt  j=l "&varbytit";*/
     title&cnt  j=l "#byval(__varbylab)";
         %end;


         %let cnt=1;
         %do i=1 %to &numfoot;
              footnote&cnt j=l "&&nfoot&i";
              %let cnt = %eval(&cnt+1);
         %end;
         footnote&cnt j=l "Program: &pgmname..sas  &__date &__time";
         %if &isbanner>0 %then %do;
            column __bannerid __banner &&colstr&jj;
         %end;
         %else %do;
            column &&colstr&jj;
         %end;
      %end;

      %else %do;
         compute after;
         %let cnt=1;
         %do i=1 %to &numfoot;
            %if &cnt=1 %then %do;
               line "&&nfoot&i.\brdrt\brdrs\brdrw15";
               %let cnt=%eval(&cnt+1);
            %end;
            %else %do; line "&&nfoot&i"; %let cnt=%eval(&cnt+1); %end;

         %end;
         %if &cnt=1 %then %do;
            line "Program: &pgmname..sas &__date &__time.\brdrt\brdrs\brdrw15";
         %end;
         %else %do;
            line "Program: &pgmname..sas  &__date &__time";
         %end;
         endcomp;
         %if &isbanner>0 %then %do;
            column __bannerid __banner
              ("&titlef" &&colstr&jj );
         %end;
         %else %do;
            column ("&titlef" &&colstr&jj );
         %end;
      %end;

      define __col_0 / "&&header0_&jj"
             style(column)={&protectstr cellwidth=&&cw0_&jj.%
                            font_size=&fontsize.pt }
             style(header)={&protectstr just=&&halign0_&jj
                            frame=hsides };

       %if &isbanner>0 %then %do;
           define __bannerid/order noprint order=data;
           define __banner/order noprint order=data;
       %end;


      %do i=1 %to &&lastcol_&jj;
          define __col_&i / "&&header&i._&jj"
            style(column)={&protectstr cellwidth=&&cw&i._&jj.% }
            style(header)={&protectstr just=&&halign&i._&jj};
      %end;

      %if &isbanner>0 %then %do;
           compute before __banner;
               line " ";
               line __banner $2000.;
               line " ";
           endcomp;
      %end;

      run;

   %end;
%end;



%if &likeascii=2 %then %do;

   %do ii=1 %to &maxpages;

      %do jj=1 %to &ncpp;

         data __rtfforreport;
         set __rtfforreport_&jj
     %if &ncpp>1 or &dest=CSR %then %do;
         (where=(__pagenum=&ii))
         %end;;
         run;


         proc report data=__rtfforreport nowindows
     %if %length(&split) %then %do; split="&split" %end;
              style(report)={rules=groups frame=&frame 
                           &protectstr}
              style(header)={ frame=hsides rules=none
                             bordercolor=black font_weight=bold &protectstr}
              style(lines)={just=l  rules=groups
                              bordercolor=black &protectstr}
         ;
     by __varbygrp __varbylab;

         %let cnt=1;



      %if &dest=APP %then %do;
         %if %length(&systitle) %then %do;
         title j=l "&systitle" j=r "Page ~{thispage} of ~{lastpage}";
         
         %end;
         %else %do;
         title j=r "Page ~{thispage} of ~{lastpage}";
         %end;

         %local cnt;
         %let cnt=2;
         %do i=1 %to &numtit;
               title&cnt j=c "&&ntit&i" ;
               %let cnt = %eval(&cnt+1);
         %end;
         /*%if %length(&varbytit) %then %do;*/
     %if &vnum1>0 %then %do;
         /*  title&cnt  j=l "&varbytit";*/
     title&cnt  j=l "#byval(__varbylab)";
         %end;


         %let cnt=1;
         %do i=1 %to &numfoot;
              footnote&cnt j=l "&&nfoot&i";
              %let cnt = %eval(&cnt+1);
         %end;

         footnote&cnt j=l "Program: &pgmname..sas  &__date &__time";

         %if &isbanner>0 %then %do;
           column __oldpagenum  __bannerid __banner __recid  &&colstr&jj;
         %end;
         %else %do;
           column __oldpagenum   __recid  &&colstr&jj;
         %end;
      %end;

       %else %do;
         %if &isbanner>0 %then %do;
            column __oldpagenum __bannerid __banner __recid
               ("&titlef" &&colstr&jj );
         %end;

         %else %do;
           column __oldpagenum __recid
             ("&titlef" &&colstr&jj );
         %end;
      %end;



             define __oldpagenum /order noprint order=data;
             %if &isbanner>0 %then %do;
                define __bannerid/order noprint order=data;
                define __banner/order noprint order=data;
             %end;
             define __recid /order noprint order=data;

             define __col_0 / "&&header0_&jj"
                    style(column)={cellwidth=&&cw0_&jj.% &protectstr
                                    just=&&halign0_&jj
                                    font_size=&fontsize.pt }
                    style(header)={just=left frame=hsides 
                                   &protectstr}
             ;

           %do i=1 %to &&lastcol_&jj;
             define __col_&i / "&&header&i._&jj"
                    style(column)={cellwidth=&&cw&i._&jj.% &protectstr}
                    style(header)={
                                    just=&&halign&i._&jj frame=hsides
                                   &protectstr}
             ;
           %end;

           %if &dest=APP %then %do;
              break after __oldpagenum/page;
           %end;
           %else %do;
              compute after __oldpagenum;
               %let cnt=1;
               %do i=1 %to &numfoot;
                  %if &cnt=1 %then %do;
                     line "&&nfoot&i.\brdrt\brdrs\brdrw15";
                     %let cnt=%eval(&cnt+1);
                  %end;
                  %else %do; line "&&nfoot&i"; %let cnt=%eval(&cnt+1); %end;
               %end;
               %if &cnt=1 %then %do;
                  line "Program:
                        &pgmname..sas &__date &__time.\brdrt\brdrs\brdrw15";
               %end;
               %else %do;
                  line "Program: &pgmname..sas  &__date &__time";
               %end;

             endcomp;

          %end;


         /*
         %let cnt=1;

         %do i=1 %to &numfoot;
            %if &cnt=1 %then %do;
               line "\brdrt\brdrs\brdrw15 &&nfoot&i";
               %let cnt=%eval(&cnt+1);
            %end;
            %else %do; line "&&nfoot&i"; %let cnt=%eval(&cnt+1); %end;
          %end;

         %if &cnt=1 %then %do;
             line "\brdrt\brdrs\brdrw15 Program:&pgmname..sas &__date &__time";
         %end;
         %else %do;
          line "Program: &pgmname..sas  &__date &__time";
         %end;
         endcomp;
         */

         %if &isbanner>0 %then %do;
           compute before __banner;
               line " ";
               line __banner $2000. ;
               line " ";
           endcomp;
         %end;

   run;




      %end;

   %end;

%end;

%end;


%if &dest=APP %then %do;
   ods pdf close;
%end;
%else %do;
   ods rtf close;
%end;
ods listing;

%if &debug=99 and &dest=APP %then %do;
/*proc print data=__rtfds_w;
var __col_0 __oldpagenum __lpp __linesused __titlelines __footlines
  __headerlines   __pageheadlines __linesusedby __lsf;
run;
*/
%end;

%*---------------------------------------------------------------------------;
%* cleanup;
%*---------------------------------------------------------------------------;

%exit:
%* restore options;

proc optload 
   data=__rtfopt (where=(
    lowcase(optname) in 
    ( 'mprint',
      'notes',
      'mlogic', 
      'symbolgen', 
      'macrogen'
      'mfile', 
      'source', 
      'source2', 
      'byline',
      'orientation',
      'date', 
      'number', 
      'center', 
      'byline',
      'missing')));
run;

%*put debug=&debug;
%if &debug=0 %then %do;
  proc datasets nowarn nolist memtype=data;
  delete __:;
  run;
  quit;
%end;




%put;
%put FINISHED EXECUTION OF RRG_PRINT MACRO (printing &filename) ;
%put -----------------------------------------------------------------------;


%mend ;
