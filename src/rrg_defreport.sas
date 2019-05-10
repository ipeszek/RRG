/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro rrg_defreport(
Dataset=,
Title1=,
title2=,
title3=,
title4=,
title5=,
title6=,
Footnot1=,
Footnot2=,
Footnot3=,
Footnot4=,
Footnot5=,
Footnot6=,
Footnot7=,
footnot8=,
colspacing=1ch,
nodatamsg=,
indentsize=2,
addlines=,
dest=APP,

/* for backwards compatibility */
papersize=,
orient=,
fontsize=,
font=,
margins=,
systitle=,
/* end of for backwards compatibility */
splitchars=%str(- ),
esc_char=%str(/),
rtf_linesplit=hyphen,
java2sas=,
debug=0,
popWhere=,
tabwhere=,
Colhead1=,
Statsincolumns=,
reptype=REGULAR,
eventcnt=N,
statsincolumn=,
statsacross=,
subjid=,
warnonnomatch=,
colwidths=,
extralines=,
stretch=,
append=,
appendable=,
tablepart=,
print=Y,
savercd=,
pooled4stats=N,
bookmark_rtf=,
bookmark_pdf=)/store;

%local Dataset popWhere tabwhere Colhead1 subjid Title1 title2 title3
title4 title5 title6 Footnot1 Footnot2 Footnot3 Footnot4
Footnot5 Footnot6 Footnot7 footnot8 Statsincolumns reptype 
eventcnt dest nodatamsg fontsize orient colwidths systitle_l 
systitle_r systitle_m sfoot_l sfoot_m sfoot_r systitle
extralines warnonnomatch print debug aetable stretch indentsize
font margins papersize statsincolumn statsacross colspacing
append appendable addlines pooled4stats 
csfoot_fs tablepart
cpapersize corient coutformat cfontsize cfont cmargins 
cshead_l cshead_r cshead_m csfoot_l csfoot_m csfoot_r 
splitchars esc_char java2sas gen_size_info rtf_linesplit
orderby cwatermark savercd java2sas gentxt bookmark_rtf bookmark_pdf
;



%let aetable=N;
%if %upcase(&reptype)=EVENTS %then %do;
  %if %qupcase(&eventcnt)=Y %then %let aetable=EVENTS;
  %else %if %qupcase(&eventcnt)=%nrbquote(Y(SE)) %then %let aetable=EVENTS;
  %else %if %qupcase(&eventcnt)=%nrbquote(Y(ES)) %then %let aetable=EVENTSES;
  %else %if %qupcase(&eventcnt)=%nrbquote(Y(E)) %then %let  aetable=EVENTSE;
  %else %let aetable=Y;
%end;


%let tablepart=%upcase(&tablepart);

%if %length(&statsincolumns)>0 %then %let statsacross=&statsincolumns;

%local nsubjid nindentsize nwarnonnomatch 
       npapersize nfontsize nfont nmargins nsystitle_l
       nsystitle_r nsystitle_m nsfoot_l nsfoot_m nsfoot_r   
       nnodatamsg norient    
       ;
%local TFL_FILE_KEY TFL_FILE_NEWVAR TFL_FILE_NAME
       BREAK_AFTER_TITLES TFL_FILE_FOOTNOTE TFL_FILE_PGMNAME
       TFL_FILE_OUTNAME
       titalign tabnum  titlebreaks;    

%local tit1 tit2 tit3 tit4 tit5 poptit ;          
%local ntit1 ntit2 ntit3 ntit4 ntit5 npoptit nnodatamsg ndest;
%local nTitle1 ntitle2 ntitle3 ntitle4 ntitle5 ntitle6 
         nFootnot1 nFootnot2 nFootnot3 nFootnot4
         nFootnot5 nFootnot6 nFootnot7 nfootnot8 ;

%local i j;
%local inlibs inlibs0;


%__defcomm;

data __report;
  set __repinfo;
run;

data __repinfo;
	set __repinfo;
pooled4stats = "&pooled4stats";
/*
if bookmarks_pdf ne '' or bookmarks_rtf ne '' then sprops = 
sprops = cats( sprops, ',bookmarks_enabled=true');
*/
run;



*** DETERMINE IF HEADER TEMPLATE IS PROVIDED IN CONFIGURATION FILE;


%* START GENERATING PROGRAM;


  
data __rrght;
  set __rrght end=eof;
  output;
  if eof then do;
    record=' '; output;
    record = '*------------------------------------------------------------;'; output;
    record = '* DEFINE FORMATS;'; output;
    record = '*------------------------------------------------------------;'; output;    
    record=' '; output;
    record='proc format;';  output;
    record="value $__rrgsf";output;
    record= " 'N'     = 'N'";output;
    record= " 'PCT'   = '%'";output;
    record= " 'NPCT'  = 'n (%)'";output;
    record= " 'N+PCT'  = 'n (%)'";output;
    record= " 'NNPCT' = 'n/N (%)'";output;
    record= " 'N+D+PCT' = 'n/N (%)'";output;
    record= " 'N/N'   ='n/N'";output;
    record= " 'N+D'   ='n/N'";output;
    record=';';output;
    record=" ";output;
    record='picture __rrgp1d (round default= 10)';output;
    end;
run;
  
data __tmp;
  set __rrgconfig(where=(type='[A3]')) end=eof;
run;
  
data  __rrght0;
  set __tmp end=eof;
  length record $ 2000;
  record = cats(w2); output;
  if eof then do;
    record=';'; output;    
    record=" ";output;
    record="picture __rrgpf (round default= 10)";output;
  end;
run;

data  __rrght;
  set  __rrght __rrght0;
run;

data __tmp;
  set __rrgconfig(where=(type='[A4]')) end=eof;
run;
  
data  __rrght0;
  set __tmp end=eof;
  length record $ 2000;
  record = cats(w2); output;
  if eof then do;
    record=';'; output;    
    record=" ";output;
    record="value $__rrgcf";output;
  end;
run;

data  __rrght;
  set  __rrght __rrght0;
run;


data __tmp;
  set __rrgconfig(where=(type='[A1]')) end=eof;
run;
/*
data  __rrght0;
  set __tmp end=eof;
  length record $ 2000;
  w1 = quote(cats(w1));
  w2= quote(cats(w2));
  record = cats(w1," = ", w2); output;
  if eof then do;
    record=';'; output;  
    record=' '; output;
    record="invalue __rrgdf"; output;
  end;
run;

data  __rrght;
  set  __rrght __rrght0;
run;
*/

data  __rrght0;
  set __tmp end=eof;
  length record $ 2000;
  w1 = quote(cats(w1));
  w2= quote(cats(w2));
  record = cats(w1," = ", w2); output;
  if eof then do;
    record=';'; output;  
    record=' '; output;
    record="value $__rrglf"; output;
  end;
run;

data  __rrght;
  set  __rrght __rrght0;
run;


data __tmp;
  set __rrgconfig(where=(type='[A1L]')) end=eof;
run;


data  __rrght0;
  set __tmp end=eof;
  length record $ 2000;
  w1 = quote(cats(w1));
  w2= quote(cats(w2));
  record = cats(w1," = ", w2); output;
  if eof then do;
    record=';'; output;  
    record=' '; output;
    record="invalue __rrgdf"; output;
  end;
run;

data  __rrght;
  set  __rrght __rrght0;
run;
data __tmp;
  set __rrgconfig(where=(type='[A2]')) end=eof;
run;

data  __rrght0;
  set __tmp end=eof;
  length record $ 2000;
  w1 = quote(cats(w1));
  w2=cats(w2);
  record=cats(w1, "=", w2); output;  
  if eof then do;
  record="other         =1";output;  
  record=';';output;  
  record=' '; output;
  record="value $__rrgbl";output;  
  record=" low-high   =' '";output;  
  record=';';output;  
  record=' '; output;
  record='run;';output;  
  record=' '; output;
  record=' '; output;
  record = '*------------------------------------------------------------;'; output;
  record = '* END OF DEFINE FORMATS;'; output;
  record = '*------------------------------------------------------------;'; output;    
  record=' '; output;
 
end;
run;

data  __rrght;
  set  __rrght __rrght0;
run;

%local i;
data __rrginlibs0;
  length dataset $ 200;
  dataset=''; output;
  %do i=1 %to %sysfunc(countw(&inlibs, %str( )));
    %let inlibs0=%scan(&inlibs,&i, %str( ));  
    if index(upcase("&dataset"), upcase("&inlibs0"))>0 then do;
       /*dataset = scan(upcase("&dataset"),2, '. ')||'.SAS7BDAT';*/
       output;
    end;
  %end;
run;

data __rrginlibs;
  set __rrginlibs __rrginlibs0;
run;

%skipdef:

data __timer;
	set __timer end=eof;
	output;
	if eof then do;
		task = "Finished def-report";
		time=time(); output;
	end;
run;	

%mend;
