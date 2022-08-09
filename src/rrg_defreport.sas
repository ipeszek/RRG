/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 
 
 * ds created: __rrgfmt (formats from config sections A1:, A2, A3 and A4)), replaces __rrgfmt from rrg_init, 
               __nspropskey, __nsprops, __sprops, __repinfo (by rrg_defcomm)
 * ds used: __rrgconfig(where=(type='[B0]')), __rrgxml, __repinfo (by rrg_defcomm)
 * ds initialized:
 * ds updated:   __timer

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
Footnot9=,
Footnot10=,
Footnot11=,
Footnot12=,
Footnot13=,
Footnot14=,
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
bookmark_pdf=,
lowmemorymode=Y)/store;

%local Dataset popWhere tabwhere Colhead1 subjid Title1 title2 title3
title4 title5 title6 Footnot1 Footnot2 Footnot3 Footnot4
Footnot5 Footnot6 Footnot7 footnot8 
Footnot9 Footnot10 Footnot11 footnot12  Footnot13 footnot14 Statsincolumns reptype 
eventcnt dest nodatamsg fontsize orient colwidths systitle_l 
systitle_r systitle_m sfoot_l sfoot_m sfoot_r systitle
extralines warnonnomatch print debug aetable stretch indentsize
font margins papersize statsincolumn statsacross colspacing
append appendable addlines pooled4stats 
csfoot_fs tablepart
cpapersize corient coutformat cfontsize cfont cmargins 
cshead_l cshead_r cshead_m csfoot_l csfoot_m csfoot_r 
splitchars esc_char  gen_size_info rtf_linesplit
orderby cwatermark savercd   bookmark_rtf bookmark_pdf  lowmemorymode
;

%global defreport_pooled4stats defreport_statsincolumn defreport_statsacross defreport_savercd 
      defreport_print defreport_colhead1 defreport_popwhere defreport_dataset
      defreport_tabwhere defreport_warnonnomatch defreport_debug defreport_aetable defreport_nodatamsg defreport_subjid
      defreport_aetable defreport_lowmemorymode;

%let defreport_statsincolumn=%upcase(&statsincolumn);
%if %length(&statsincolumns)>0  %then  %let defreport_statsacross=%upcase(&statsincolumns);;
%if %length(&statsacross)       %then  %let defreport_statsacross=%upcase(&statsacross);;
%let defreport_pooled4stats=%upcase(&pooled4stats);
%let defreport_print=%upcase(&print);
%let defreport_savercd=%upcase(&savercd);
%let defreport_colhead1=&colhead1;
%let defreport_lowmemorymode=%upcase(&lowmemorymode);
%if &defreport_lowmemorymode ne Y %then %let defreport_lowmemorymode=N;

%let defreport_popwhere                             =     &popwhere                  ;
%let defreport_dataset                              =     &dataset                   ;
%let defreport_tabwhere                             =     &tabwhere                  ;
%let defreport_warnonnomatch                        =     &warnonnomatch             ;
%let defreport_debug                                =     &debug                     ;
%let defreport_nodatamsg                            =     &nodatamsg                 ;
%let defreport_subjid                               =     &subjid                    ;
              
                                                                                  
%if &rrg_debug>0 %then %do;

data __timer;
  set __timer end=eof;
	length task $ 100;
	output;
		if eof then do; 
		  task = "Defreport STARTED";
		  dt=datetime(); 
		  output;
		end;
run;

%end;

%let defreport_aetable=N;
%if %upcase(&reptype)=EVENTS %then %do;
  %if %qupcase(&eventcnt)=Y %then %let defreport_aetable=EVENTS;
  %else %if %qupcase(&eventcnt)=%nrbquote(Y(SE)) %then %let defreport_aetable=EVENTS;
  %else %if %qupcase(&eventcnt)=%nrbquote(Y(ES)) %then %let defreport_aetable=EVENTSES;
  %else %if %qupcase(&eventcnt)=%nrbquote(Y(E)) %then %let  defreport_aetable=EVENTSE;
  %else %let defreport_aetable=Y;
%end;


%let tablepart=%upcase(&tablepart);



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
         nFootnot5 nFootnot6 nFootnot7 nfootnot8 
          nFootnot9 nFootnot10
         nFootnot11 nFootnot12 nFootnot13 nfootnot14;;

%local i j;
%local inlibs inlibs0;


%__defcomm;





*** DETERMINE IF HEADER TEMPLATE IS PROVIDED IN CONFIGURATION FILE;


**** CREATE FILE WITH FORMAT ***********;


  
data rrgfmt;
 length record $ 2000;
 keep record;
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
run;
  
data __rrght0;
  set __rrgconfig(where=(type='[A3]')) end=eof;
  length record $ 2000;
  keep record;
  record = cats(w2); output;
  if eof then do;
    record=';'; output;    
    record=" ";output;
    record="picture __rrgpf (round default= 10)";output;
  end;
run;

proc append data=__rrght0 base=rrgfmt;
run;
 

data __rrght0;
  set __rrgconfig(where=(type='[A4]')) end=eof;
  length record $ 2000;
  keep record;
  record = cats(w2); output;
  if eof then do;
    record=';'; output;    
    record=" ";output;
    record="value $__rrgcf";output;
  end;
run;

proc append data=__rrght0 base=rrgfmt;
run;


data __rrght0;
  set __rrgconfig(where=(type='[A1]')) end=eof;
  length record $ 2000;
  keep record;
  w1 = quote(cats(w1));
  w2= quote(cats(w2));
  record = cats(w1," = ", w2); output;
  if eof then do;
    record=';'; output;  
    record=' '; output;
    record="value $__rrglf"; output;
  end;
run;

proc append data=__rrght0 base=rrgfmt;
run;


data __rrght0;
  set __rrgconfig(where=(type='[A1L]')) end=eof;
  length record $ 2000;  
  keep record;
  w1 = quote(cats(w1));
  w2= quote(cats(w2));
  record = cats(w1," = ", w2); output;
  if eof then do;
    record=';'; output;  
    record=' '; output;
    record="invalue __rrgdf"; output;
  end;
run;

proc append data=__rrght0 base=rrgfmt;
run;

data __rrght0;
  set __rrgconfig(where=(type='[A2]')) end=eof;
  length record $ 2000;
  keep record;
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

proc append data=__rrght0 base=rrgfmt;
run;

/*
%local i;
data __rrginlibs0;
  length dataset $ 200;
  dataset=''; output;
  %do i=1 %to %sysfunc(countw(&inlibs, %str( )));
      %let inlibs0=%scan(&inlibs,&i, %str( ));  
      if index(upcase("&dataset"), upcase("&inlibs0"))>0 then do;
         output;
      end;
  %end;
run;

data __rrginlibs;
  set __rrginlibs __rrginlibs0;
run;
*/

%skipdef:


%mend;
