/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro rrg_deflist(
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
colspacing=4,
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
orderby=,
appendable=,
append=,
print=Y,
savercd=,
gentxt=,
bookmark_rtf=,
bookmark_pdf=)/store;

%local Dataset popWhere tabwhere Colhead1 subjid Title1 title2 title3
title4 title5 title6 Footnot1 Footnot2 Footnot3 Footnot4
Footnot5 Footnot6 Footnot7 footnot8 Statsincolumns reptype 
eventcnt dest nodatamsg fontsize orient colwidths systitle_l 
systitle_r systitle_m sfoot_l sfoot_m sfoot_r systitle
extralines warnonnomatch print debug aetable stretch indentsize
font margins papersize  statsincolumn statsacross colspacing
append appendable addlines csfoot_fs  tablepart
cpapersize corient coutformat cfontsize cfont cmargins 
cshead_l cshead_r cshead_m csfoot_l csfoot_m csfoot_r 
splitchars esc_char java2sas gen_size_info rtf_linesplit
orderby cwatermark savercd  gentxt bookmark_rtf bookmark_pdf
;


%let tablepart=;

%local nsubjid nindentsize nwarnonnomatch 
       npapersize nfontsize nfont nmargins nshead_l
       nshead_r nshead_m nsfoot_l nsfoot_m nsfoot_r   
       nnodatamsg norient    
       ;
%local TFL_FILE_KEY TFL_FILE_NEWVAR TFL_FILE_NAME
       BREAK_AFTER_TITLES  TFL_FILE_FOOTNOTE TFL_FILE_PGMNAME
       TFL_FILE_OUTNAME
       titalign tabnum  titlebreaks;
       
%local tit1 tit2 tit3 tit4 tit5 poptit ;
%local ntit1 ntit2 ntit3 ntit4 ntit5 npoptit nnodatamsg ndest ;
%local nTitle1 ntitle2 ntitle3 ntitle4 ntitle5 ntitle6 
         nFootnot1 nFootnot2 nFootnot3 nFootnot4
         nFootnot5 nFootnot6 nFootnot7 nfootnot8 ;
  
%local i j;
%local inlibs inlibs0;
       
%__defcomm;

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




%mend;
