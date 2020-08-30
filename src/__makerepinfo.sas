/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */
 
 
 /* PROGRAM FLOW:
    10Aug2020     
    
    note: this.xxx below refers to macro parameter xxx of this macro; __repinfo.xxx refers to variable xxx in __repinfo dataset                                 
  called in RRG_GENERATE and RRG_GENLIST
 
 create and run macro __metadata  which creates dataset __REPORT, 
  seting __datatype   = 'RINFO',  __rowid, __varbygrp to MISSING (numeric), 
   and variables
    __fontsize, __bookmarks_rtf, __bookmarks_pdf, __sfoot_fs, __indentsize, __orient, __filename,
    __nodatamsg, __stretch, __colwidths, __dist2next,  __rtype, __gcols, __lastcheadid, __extralines,
    __margins=, __papersize, __outformat, __watermark, __font, __stretch, __sprops, __colhead1
    __title1 - __title6, __footnot1 - __footnot8,
    __shead_l, __shead_r, __shead_m, __sfoot_l, __sfoot_m, __sfoot_r
    to corresponding variables from __REPINFO DS
    
    in __shead_l, __shead_r, __shead_m, __sfoot_l, __sfoot_m, __sfoot_r,__colhead1, replace
     "#rpar" with ")", "#squot" with "'" , "#lpar" with "("
    
    __breakokat is set to &BREAKOKAT 
      for listings, &BREAKOKAT is created in RRG_GENLIST and is the list of number of columns 
         with DEFCOL.BREAKOKAT=Y (case insensitive)
      for tables, &BREAKOKAT is created ???? 
    __dest is set to RTF, RTF PDF or PDF according to __REPINFO.OUTFORMAT variable
    __filename is set to __filename or - if &java2sas=Y - to __filename_j
    __path is set to &RRGOUTPATH if provided, or to &RRGOUTPATHLAZY otherwise 
        (RRGOUTPATH is defined in init file, and RRGOUTPATHlazy is it's copy)
   
    __version is set to value created by macro %__VERSION
    
    (also __systile is set to __shead_l)
    
    if __REPINFO.__COLWIDTHS is null then set  set to __colwidths to "LW"
    
    if __repinfo.__COLWIDTHS consist of a single word then : 
     for listings: if THIS.NUMCOL>0 then set __colwidths to this word repeated THIS.NUMCOL number of times
     for tables:  set __colwidths  to this word repated  &MAXTRT number of times
     
    if __repinfo.__COLWIDTHS consist of 2 or more words then : 
     for listings: set __colwidths to __REPINFO.__COLWIDTH followed by the last word in __REPINFO.__COLWIDTHS
      repated as many times as needed until THIS.NUMCOL  is reached 
     for tables: set __colwidths to __REPINFO.__COLWIDTH followed by the last word in __REPINFO.__COLWIDTHS
      repated as many times as needed until &MAXTRT is reached
         
    if __stretch is null then set it to "Y" 
     extend variable __stretch adding it's last word at the end as many times as  THIS.NUMCOL (for listings)
      or as  &MAXTRT  (for tables)
      
     if this macro is invoked in rrg_genlist (for listings) then THIS.NUMCOL is set to NUMCOL macro parameter defined in rrg_genlist
        as number of times RRG_DEFCOL is called
     if this macro is invoked in rrg_generate (for tables) then THIS.NUMCOL null
                                     
     if this macro is invoked in rrg_genlist (for listings) then &MAXTRT us not used  
     if this macro is invoked in rrg_generate (for tables) then &MAXTRT is generated in ???

 */
 

%macro __makerepinfo (outds=, numcol=, islist=N)/store;

  
%local outds numcol islist;
  

data _null_;
file "&rrgpgmpath./&outds" mod ;
set __repinfo;
put;
put @1 '%macro __metadata;';
put @1 '%local __fontsize __indentsize __orient __dest  __nodatamsg';
put @1 '       __title1 __title2 __title3 __title4 __title5 __title6';
put @1 '       __footnot1 __footnot2 __footnot3 __footnot4';
put @1 '       __footnot5 __footnot6 __footnot7 __footnot8 __outformat';   
put @1 '       __shead_l __shead_r __shead_m __papersize __watermark ';
put @1 '       __sfoot_l __sfoot_r __sfoot_m __sprops __sfoot_fs __gcols __rtype';
put @1 '       __colwidths __extralines __stretch i __font __margins __lastcheadid __dist2next';
put @1 '       __bookmarks_rtf __bookmarks_pdf ;';
put;
/*put @1 '%global rrgoutpath;';*/
put;
%if &islist=Y %then %do;
put;
put @1 '%local breakokat;';
put @1 '%let breakokat = ' "&breakokat ;";
put;
%end;

put @1 '%let __fontsize=' fontsize ";";
put @1 '%let __bookmarks_rtf=%str(' bookmarks_rtf ");";
put @1 '%let __bookmarks_pdf=%str(' bookmarks_pdf ");";


put @1 '%let __sfoot_fs=' sfoot_fs ";";
put @1 '%let __indentsize=' indentsize ";";
put @1 '%let __orient=' orient ";";
if index (upcase(outformat),'RTF')=0 then do;
  if index (upcase(outformat),'PDF')>0 then do;
    put @1 '%let __dest=PDF;'; 
  end;
  else do;
    put @1 '%let __dest=RTF PDF;';  	
  end;
end;
else do;
  if index (upcase(outformat),'PDF')>0 then do;
    put @1 '%let __dest=RTF PDF;';
  end;
  else do;
    put @1 '%let __dest=RTF;';
  end;  
end;  

put @1 '%let __filename=' filename ";";
put @1 '%let __nodatamsg=' nodatamsg ";";

length __tmpw  $ 2000;

__xx= countw(title1, ' ');
__yy = floor(__xx/10);
__yy2 = __xx-10*__yy;
__tmpw='';

do __i = 1 to __yy;
  __tmpw='';
  do __j =1 to 10;
    __tmpw = strip(__tmpw)||' '||strip(scan(title1, 10*(__i-1)+__j,' '));
  end;
  put @1 '%let __title1 = %str(&__title1.)%str(' __tmpw");";
end;  
  __tmpw='';
  do __j=1 to __yy2;
    __tmpw = strip(__tmpw)||' '||strip(scan(title1, 10*__yy+__j,' '));
  end;
  put @1 '%let __title1 = %str(&__title1.)%str(' __tmpw");";
  

__xx= countw(title2, ' ');
__yy = floor(__xx/10);
__yy2 = __xx-10*__yy;
__tmpw='';

do __i = 1 to __yy;
  __tmpw='';
  do __j =1 to 10;
    __tmpw = strip(__tmpw)||' '||strip(scan(title2, 10*(__i-1)+__j,' '));
  end;
  put @1 '%let __title2 = %str(&__title2.)%str(' __tmpw");";
end;  
  __tmpw='';
  do __j=1 to __yy2;
    __tmpw = strip(__tmpw)||' '||strip(scan(title2, 10*__yy+__j,' '));
  end;
  put @1 '%let __title2 = %str(&__title2.)%str(' __tmpw");";


__xx= countw(title3, ' ');
__yy = floor(__xx/10);
__yy2 = __xx-10*__yy;
__tmpw='';

do __i = 1 to __yy;
  __tmpw='';
  do __j =1 to 10;
    __tmpw = strip(__tmpw)||' '||strip(scan(title3, 10*(__i-1)+__j,' '));
  end;
  put @1 '%let __title3 = %str(&__title3.)%str(' __tmpw");";
end;
  __tmpw='';
  do __j=1 to __yy2;
    __tmpw = strip(__tmpw)||' '||strip(scan(title3, 10*__yy+__j,' '));
  end;
  put @1 '%let __title3 = %str(&__title3.)%str(' __tmpw");";
  

__xx= countw(title4, ' ');
__yy = floor(__xx/10);
__yy2 = __xx-10*__yy;
__tmpw='';

do __i = 1 to __yy;
  __tmpw='';
  do __j =1 to 10;
    __tmpw = strip(__tmpw)||' '||strip(scan(title4, 10*(__i-1)+__j,' '));
  end;
  put @1 '%let __title4 = %str(&__title4.)%str(' __tmpw");";
end;
  __tmpw='';
  do __j=1 to __yy2;
    __tmpw = strip(__tmpw)||' '||strip(scan(title4, 10*__yy+__j,' '));
  end;
  put @1 '%let __title4 = %str(&__title4.)%str(' __tmpw");";
  

__xx= countw(title5, ' ');
__yy = floor(__xx/10);
__yy2 = __xx-10*__yy;
__tmpw='';

do __i = 1 to __yy;
  __tmpw='';
  do __j =1 to 10;
    __tmpw = strip(__tmpw)||' '||strip(scan(title5, 10*(__i-1)+__j,' '));
  end;
  put @1 '%let __title5 = %str(&__title5.)%str(' __tmpw");";
end;
  __tmpw='';
  do __j=1 to __yy2;
    __tmpw = strip(__tmpw)||' '||strip(scan(title5, 10*__yy+__j,' '));
  end;
  put @1 '%let __title5 = %str(&__title5.)%str(' __tmpw");";
  

__xx= countw(title6, ' ');
__yy = floor(__xx/10);
__yy2 = __xx-10*__yy;
__tmpw='';

do __i = 1 to __yy;
  __tmpw='';
  do __j =1 to 10;
    __tmpw = strip(__tmpw)||' '||strip(scan(title6, 10*(__i-1)+__j,' '));
  end;
  put @1 '%let __title6 = %str(&__title6.)%str(' __tmpw");";
end;
  __tmpw='';
  do __j=1 to __yy2;
    __tmpw = strip(__tmpw)||' '||strip(scan(title6, 10*__yy+__j,' '));
  end;
  put @1 '%let __title6 = %str(&__title6.)%str(' __tmpw");";
  

__xx= countw(shead_l, ' ');
__yy = floor(__xx/10);
__yy2 = __xx-10*__yy;
__tmpw='';

do __i = 1 to __yy;
  __tmpw='';
  do __j =1 to 10;
    __tmpw = strip(__tmpw)||' '||strip(scan(shead_l, 10*(__i-1)+__j,' '));
  end;
  put @1 '%let __shead_l = %str(&__shead_l.)%str(' __tmpw");";
end;
  __tmpw='';
  do __j=1 to __yy2;
    __tmpw = strip(__tmpw)||' '||strip(scan(shead_l, 10*__yy+__j,' '));
  end;
  put @1 '%let __shead_l = %str(&__shead_l.)%str(' __tmpw");";
  

__xx= countw(shead_m, ' ');
__yy = floor(__xx/10);
__yy2 = __xx-10*__yy;
__tmpw='';

do __i = 1 to __yy;
  __tmpw='';
  do __j =1 to 10;
    __tmpw = strip(__tmpw)||' '||strip(scan(shead_m, 10*(__i-1)+__j,' '));
  end;
  put @1 '%let __shead_m = %str(&__shead_m.)%str(' __tmpw");";
end;
  __tmpw='';
  do __j=1 to __yy2;
    __tmpw = strip(__tmpw)||' '||strip(scan(shead_m, 10*__yy+__j,' '));
  end;
  put @1 '%let __shead_m = %str(&__shead_m.)%str(' __tmpw");";
  

__xx= countw(shead_r, ' ');
__yy = floor(__xx/10);
__yy2 = __xx-10*__yy;
__tmpw='';

do __i = 1 to __yy;
  __tmpw='';
  do __j =1 to 10;
    __tmpw = strip(__tmpw)||' '||strip(scan(shead_r, 10*(__i-1)+__j,' '));
  end;
  put @1 '%let __shead_r = %str(&__shead_r.)%str(' __tmpw");";
end;
  __tmpw='';
  do __j=1 to __yy2;
    __tmpw = strip(__tmpw)||' '||strip(scan(shead_r, 10*__yy+__j,' '));
  end;
  put @1 '%let __shead_r = %str(&__shead_r.)%str(' __tmpw");";
  

__xx= countw(sfoot_r, ' ');
__yy = floor(__xx/10);
__yy2 = __xx-10*__yy;
__tmpw='';

do __i = 1 to __yy;
  __tmpw='';
  do __j =1 to 10;
    __tmpw = strip(__tmpw)||' '||strip(scan(sfoot_r, 10*(__i-1)+__j,' '));
  end;
  put @1 '%let __sfoot_r = %str(&__sfoot_r.)%str(' __tmpw");";
end;
  __tmpw='';
  do __j=1 to __yy2;
    __tmpw = strip(__tmpw)||' '||strip(scan(sfoot_r, 10*__yy+__j,' '));
  end;
  put @1 '%let __sfoot_r = %str(&__sfoot_r.)%str(' __tmpw");";
  

__xx= countw(sfoot_m, ' ');
__yy = floor(__xx/10);
__yy2 = __xx-10*__yy;
__tmpw='';

do __i = 1 to __yy;
  __tmpw='';
  do __j =1 to 10;
    __tmpw = strip(__tmpw)||' '||strip(scan(sfoot_m, 10*(__i-1)+__j,' '));
  end;
  put @1 '%let __sfoot_m = %str(&__sfoot_m.)%str(' __tmpw");";
end;
  __tmpw='';
  do __j=1 to __yy2;
    __tmpw = strip(__tmpw)||' '||strip(scan(sfoot_m, 10*__yy+__j,' '));
  end;
  put @1 '%let __sfoot_m = %str(&__sfoot_m.)%str(' __tmpw");";
  

__xx= countw(sfoot_l, ' ');
__yy = floor(__xx/10);
__yy2 = __xx-10*__yy;
__tmpw='';

do __i = 1 to __yy;
  __tmpw='';
  do __j =1 to 10;
    __tmpw = strip(__tmpw)||' '||strip(scan(sfoot_l, 10*(__i-1)+__j,' '));
  end;
  put @1 '%let __sfoot_l = %str(&__sfoot_l.)%str(' __tmpw");";
end;
  __tmpw='';
  do __j=1 to __yy2;
    __tmpw = strip(__tmpw)||' '||strip(scan(sfoot_l, 10*__yy+__j,' '));
  end;
  put @1 '%let __sfoot_l = %str(&__sfoot_l.)%str(' __tmpw");";
  

__xx= countw(footnot1, ' ');
__yy = floor(__xx/10);
__yy2 = __xx-10*__yy;
__tmpw='';

do __i = 1 to __yy;
  __tmpw='';
  do __j =1 to 10;
    __tmpw = strip(__tmpw)||' '||strip(scan(footnot1, 10*(__i-1)+__j,' '));
  end;
  put @1 '%let __footnot1 = %str(&__footnot1.)%str(' __tmpw");";
end;
  __tmpw='';
  do __j=1 to __yy2;
    __tmpw = strip(__tmpw)||' '||strip(scan(footnot1, 10*__yy+__j,' '));
  end;
  put @1 '%let __footnot1 = %str(&__footnot1.)%str(' __tmpw");";
  

__xx= countw(footnot2, ' ');
__yy = floor(__xx/10);
__yy2 = __xx-10*__yy;
__tmpw='';

do __i = 1 to __yy;
  __tmpw='';
  do __j =1 to 10;
    __tmpw = strip(__tmpw)||' '||strip(scan(footnot2, 10*(__i-1)+__j,' '));
  end;
  put @1 '%let __footnot2 = %str(&__footnot2.)%str(' __tmpw");";
end;
  __tmpw='';
  do __j=1 to __yy2;
    __tmpw = strip(__tmpw)||' '||strip(scan(footnot2, 10*__yy+__j,' '));
  end;
  put @1 '%let __footnot2 = %str(&__footnot2.)%str(' __tmpw");";
  

__xx= countw(footnot3, ' ');
__yy = floor(__xx/10);
__yy2 = __xx-10*__yy;
__tmpw='';

do __i = 1 to __yy;
  __tmpw='';
  do __j =1 to 10;
    __tmpw = strip(__tmpw)||' '||strip(scan(footnot3, 10*(__i-1)+__j,' '));
  end;
  put @1 '%let __footnot3 = %str(&__footnot3.)%str(' __tmpw");";
end;
  __tmpw='';
  do __j=1 to __yy2;
    __tmpw = strip(__tmpw)||' '||strip(scan(footnot3, 10*__yy+__j,' '));
  end;
  put @1 '%let __footnot3 = %str(&__footnot3.)%str(' __tmpw");";


__xx= countw(footnot4, ' ');
__yy = floor(__xx/10);
__yy2 = __xx-10*__yy;
__tmpw='';

do __i = 1 to __yy;
  __tmpw='';
  do __j =1 to 10;
    __tmpw = strip(__tmpw)||' '||strip(scan(footnot4, 10*(__i-1)+__j,' '));
  end;
  put @1 '%let __footnot4 = %str(&__footnot4.)%str(' __tmpw");";
end;
  __tmpw='';
  do __j=1 to __yy2;
    __tmpw = strip(__tmpw)||' '||strip(scan(footnot4, 10*__yy+__j,' '));
  end;
  put @1 '%let __footnot4 = %str(&__footnot4.)%str(' __tmpw");";


__xx= countw(footnot5, ' ');
__yy = floor(__xx/10);
__yy2 = __xx-10*__yy;
__tmpw='';

do __i = 1 to __yy;
  __tmpw='';
  do __j =1 to 10;
    __tmpw = strip(__tmpw)||' '||strip(scan(footnot5, 10*(__i-1)+__j,' '));
  end;
  put @1 '%let __footnot5= %str(&__footnot5.)%str(' __tmpw");";
end;  
  __tmpw='';
  do __j=1 to __yy2;
    __tmpw = strip(__tmpw)||' '||strip(scan(footnot5, 10*__yy+__j,' '));
  end;
  put @1 '%let __footnot5= %str(&__footnot5.)%str(' __tmpw");";
  

__xx= countw(footnot6, ' ');
__yy = floor(__xx/10);
__yy2 = __xx-10*__yy;
__tmpw='';

do __i = 1 to __yy;
  __tmpw='';
  do __j =1 to 10;
    __tmpw = strip(__tmpw)||' '||strip(scan(footnot6, 10*(__i-1)+__j,' '));
  end;
  put @1 '%let __footnot6= %str(&__footnot6.)%str(' __tmpw");";
end;  
  __tmpw='';
  do __j=1 to __yy2;
    __tmpw = strip(__tmpw)||' '||strip(scan(footnot6, 10*__yy+__j,' '));
  end;
  put @1 '%let __footnot6= %str(&__footnot6.)%str(' __tmpw");";
  

__xx= countw(footnot7, ' ');
__yy = floor(__xx/10);
__yy2 = __xx-10*__yy;
__tmpw='';

do __i = 1 to __yy;
  __tmpw='';
  do __j =1 to 10;
    __tmpw = strip(__tmpw)||' '||strip(scan(footnot7, 10*(__i-1)+__j,' '));
  end;
  put @1 '%let __footnot7= %str(&__footnot7.)%str(' __tmpw");";
end;  
  __tmpw='';
  do __j=1 to __yy2;
    __tmpw = strip(__tmpw)||' '||strip(scan(footnot7, 10*__yy+__j,' '));
  end;
  put @1 '%let __footnot7= %str(&__footnot7.)%str(' __tmpw");";
  

__xx= countw(footnot8, ' ');
__yy = floor(__xx/10);
__yy2 = __xx-10*__yy;
__tmpw='';

do __i = 1 to __yy;
  __tmpw='';
  do __j =1 to 10;
    __tmpw = strip(__tmpw)||' '||strip(scan(footnot8, 10*(__i-1)+__j,' '));
  end;
  put @1 '%let __footnot8= %str(&__footnot8.)%str(' __tmpw");";
end;  
  __tmpw='';
  do __j=1 to __yy2;
    __tmpw = strip(__tmpw)||' '||strip(scan(footnot8, 10*__yy+__j,' '));
  end;
  put @1 '%let __footnot8= %str(&__footnot8.)%str(' __tmpw");";
 
%* assembe sprops;
put @1 '%let __sprops= &__sprops. xx=xx;';
__xx= countw(sprops, ',');
__yy = floor(__xx/10);
__yy2 = __xx-10*__yy;
__tmpw='';

do __i = 1 to __yy;
  __tmpw='';
  do __j =1 to 10;
    __tmpw = strip(__tmpw)||','||strip(scan(sprops, 10*(__i-1)+__j,','));
  end;
  put @1 '%let __sprops= %str(&__sprops.)%str(' __tmpw");";
end;  
  __tmpw='';
  do __j=1 to __yy2;
    __tmpw = strip(__tmpw)||','||strip(scan(sprops, 10*__yy+__j,','));
  end;
  put @1 '%let __sprops= %str(&__sprops.)%str(' __tmpw");";
  




put @1 '%let __stretch='  stretch ";";

put @1 '%local __path;';
put @1 '%if %length(&rrgoutpath)=0 %then';
put @1 '  %let __path=' "&rrgoutpathlazy;";
put @1 '%else %let __path = &rrgoutpath;';
put @1 '%let __colwidths=' colwidths ";";
put @1 '%let __dist2next=' dist2next ";";
put @1 '%let __rtype=' rtype ";";
put @1 '%let __gcols=' gcols ";";
put @1 '%let __lastcheadid=' lastcheadid ";";
put @1 '%let __extralines=' extralines ";";
put @1 '%let __margins=' margins ";";
put @1 '%let __papersize=' papersize";";
put @1 '%let __outformat=' outformat";";
put @1 '%let __watermark=' watermark";";
put @1 '%let __font=' font ";";



put;
put @1 "data __report;";
put @1 " length __datatype $ 8 __footnot1 __footnot2 __footnot3 __footnot4 ";
put @1 "        __footnot5 __footnot6 __footnot7 __footnot8 __bookmarks_rtf __bookmarks_pdf";
put @1 "        __sprops __title1 __title2 __title3 __systitle ";
put @1 "        __shead_r __shead_m __shead_l __dist2next __breakokat";
put @1 "        __sfoot_r __sfoot_m __sfoot_l __stretch __colwidths __rtype __gcols $ 2000;";
put;
put @1 "   __datatype   = 'RINFO';";
put @1 "   __rowid      = .;";
put @1 "   __varbygrp   = .;";
put @1 "   __sprops     = trim(left(symget('__sprops')));";
put @1 "   __fontsize   = trim(left(symget('__fontsize')));";
put @1 "   __bookmarks_pdf   = trim(left(symget('__bookmarks_pdf')));";
put @1 "   __bookmarks_rtf   = trim(left(symget('__bookmarks_rtf')));";

put @1 "   __papersize  = trim(left(symget('__papersize')));";
put @1 "   __watermark  = trim(left(symget('__watermark')));";
put @1 "   __indentsize = trim(left(symget('__indentsize')));";
put @1 "   __orient     = trim(left(symget('__orient')));";
put @1 "   __breakokat  = trim(left(symget('breakokat')));";
put @1 "   __dest       = trim(left(symget('__dest')));";
put @1 "   __filename   = trim(left(symget('__filename')));";
%if &java2sas=Y %then %do;
put @1 "   __filename   = strip(__filename)||'_j';";
%end;

put @1 "  __nodatamsg   = trim(left(symget('__nodatamsg')));";
put @1 "  __title1      = trim(left(symget('__title1')));";
put @1 "  __title2      = trim(left(symget('__title2')));";
put @1 "  __title3      = trim(left(symget('__title3')));";
put @1 "  __title4      = trim(left(symget('__title4')));";
put @1 "  __title5      = trim(left(symget('__title5')));";
put @1 "  __title6      = trim(left(symget('__title6')));";
put @1 "  __footnot1    = trim(symget('__footnot1'));";
put @1 "  __footnot2    = trim(symget('__footnot2'));";
put @1 "  __footnot3    = trim(symget('__footnot3'));";
put @1 "  __footnot4    = trim(symget('__footnot4'));";
put @1 "  __footnot5    = trim(symget('__footnot5'));";
put @1 "  __footnot6    = trim(symget('__footnot6'));";
put @1 "  __footnot7    = trim(symget('__footnot7'));";
put @1 "  __footnot8    = trim(symget('__footnot8'));";
put @1 "  __path        = trim(left(symget('__path')));";
put @1 "  __systitle    = trim(left(symget('__shead_l')));";
put @1 "  __shead_l     = trim(left(symget('__shead_l')));";
put @1 "  __shead_m     = trim(left(symget('__shead_m')));";
put @1 "  __shead_r     = trim(left(symget('__shead_r')));";
put @1 "  __sfoot_l     = trim(left(symget('__sfoot_l')));";
put @1 "  __sfoot_m     = trim(left(symget('__sfoot_m')));";
put @1 "  __sfoot_r     = trim(left(symget('__sfoot_r')));";
put @1 "  __colwidths   = trim(left(symget('__colwidths')));";
put @1 "  __sfoot_fs    = trim(left(symget('__sfoot_fs')));";
put @1 " __extralines   = trim(left(symget('__extralines')));";
put @1 " __stretch      = trim(left(symget('__stretch')));";
put @1 " __font         = trim(left(symget('__font')));";
put @1 " __margins      = trim(left(symget('__margins')));";
put @1 " __outformat    = trim(left(symget('__outformat')));";
put @1 ' __version      = "' "%__version" '";';
/*put @1 "    __lastcheadid = 0;";*/
put @1 " __lastcheadid  = trim(left(symget('__lastcheadid')));";
put @1 " __rtype        = trim(left(symget('__rtype')));";
put @1 " __gcols        = trim(left(symget('__gcols')));";
put @1 " __dist2next    = trim(left(symget('__dist2next')));";
put;
put @1 "__i=0;";
put @1 "if __colwidths='' then __colwidths='LW';";
put @1 "if countw(__colwidths,' ')=1 then do;";
%if %length(&numcol)=0 %then %do;
put @1 '   __colwidths = compbl(__colwidths)||repeat(" NH", &maxtrt-1);';
%end;
%else %do;
put @1 "   __colwidths = compbl(__colwidths)||repeat(' NH', &numcol-1);";
%end;
put @1 "end;  ";
%if %length(&numcol)=0 %then %do;
put @1 'else if countw(__colwidths," ")<&maxtrt+1 then do;';
put @1 '   __colwidths = compbl(__colwidths)||repeat(" "||scan(__colwidths,-1," "), &maxtrt-countw(__colwidths," "));';
%end;
%else %do;
put @1 "else if countw(__colwidths,' ')<&numcol+1 then do;";
put @1 "   __colwidths = compbl(__colwidths)||repeat(' '||scan(__colwidths,-1,' '), &numcol-countw(__colwidths,' '));";
%end;
put @1 "end;";
put 'put __colwidths=;';

put @1 "if __stretch='' then __stretch='Y';";
%if %length(&numcol)=0 %then %do;
put @1 'if countw(__stretch," ")<&maxtrt+1 then do;';
put @1 '   __stretch = compbl(__stretch)||repeat(" "||scan(__stretch,-1," "), &maxtrt-countw(__stretch," "));';
%end;
%else %do;
put @1 "if countw(__stretch,' ')<&numcol+1 then do;";
put @1 "   __stretch = compbl(__stretch)||repeat(' '||scan(__stretch,-1,' '), &numcol-countw(__stretch,' '));";

%end;
put @1 "end;";

put;
put @1 'w1 = strip("' "'" '");';
put @1 'w2 = strip("' "#squot" '");';
put @1 '__colhead1   = tranwrd(strip(__colhead1),     strip(w2),  strip(w1));';
put @1 '__title1     = tranwrd(strip(__title1),     strip(w2),  strip(w1));';
put @1 '__title2     = tranwrd(strip(__title2),     strip(w2),  strip(w1));';
put @1 '__title3     = tranwrd(strip(__title3),     strip(w2),  strip(w1));';
put @1 '__title4     = tranwrd(strip(__title4),     strip(w2),  strip(w1));';
put @1 '__title5     = tranwrd(strip(__title5),     strip(w2),  strip(w1));';
put @1 '__title6     = tranwrd(strip(__title6),     strip(w2),  strip(w1));';
put @1 '__footnot1   = tranwrd(strip(__footnot1),   strip(w2),  strip(w1));';
put @1 '__footnot2   = tranwrd(strip(__footnot2),   strip(w2),  strip(w1));';
put @1 '__footnot3   = tranwrd(strip(__footnot3),   strip(w2),  strip(w1));';
put @1 '__footnot4   = tranwrd(strip(__footnot4),   strip(w2),  strip(w1));';
put @1 '__footnot5   = tranwrd(strip(__footnot5),   strip(w2),  strip(w1));';
put @1 '__footnot6   = tranwrd(strip(__footnot6),   strip(w2),  strip(w1));';
put @1 '__footnot7   = tranwrd(strip(__footnot7),   strip(w2),  strip(w1));';
put @1 '__footnot8   = tranwrd(strip(__footnot8),   strip(w2),  strip(w1));';
put @1 '__colhead1   = tranwrd(strip(__colhead1),   strip(w2),  strip(w1));';
put @1 '__sfoot_r    = tranwrd(strip(__sfoot_r),    strip(w2),  strip(w1));';
put @1 '__sfoot_m    = tranwrd(strip(__sfoot_m),    strip(w2),  strip(w1));';
put @1 '__sfoot_l    = tranwrd(strip(__sfoot_l),    strip(w2),  strip(w1));';
put @1 '__shead_l    = tranwrd(strip(__shead_l),    strip(w2),  strip(w1));';
put @1 '__shead_m    = tranwrd(strip(__shead_m),    strip(w2),  strip(w1));';
put @1 '__shead_r    = tranwrd(strip(__shead_r),    strip(w2),  strip(w1));';
put;
put @1 'w1 = strip("' "(" '");';
put @1 'w2 = strip("' "#lpar" '");';
put @1 '__colhead1   = tranwrd(strip(__colhead1),     strip(w2),  strip(w1));';
put @1 '__title1     = tranwrd(strip(__title1),     strip(w2),  strip(w1));';
put @1 '__title2     = tranwrd(strip(__title2),     strip(w2),  strip(w1));';
put @1 '__title3     = tranwrd(strip(__title3),     strip(w2),  strip(w1));';
put @1 '__title4     = tranwrd(strip(__title4),     strip(w2),  strip(w1));';
put @1 '__title5     = tranwrd(strip(__title5),     strip(w2),  strip(w1));';
put @1 '__title6     = tranwrd(strip(__title6),     strip(w2),  strip(w1));';
put @1 '__footnot1   = tranwrd(strip(__footnot1),   strip(w2),  strip(w1));';
put @1 '__footnot2   = tranwrd(strip(__footnot2),   strip(w2),  strip(w1));';
put @1 '__footnot3   = tranwrd(strip(__footnot3),   strip(w2),  strip(w1));';
put @1 '__footnot4   = tranwrd(strip(__footnot4),   strip(w2),  strip(w1));';
put @1 '__footnot5   = tranwrd(strip(__footnot5),   strip(w2),  strip(w1));';
put @1 '__footnot6   = tranwrd(strip(__footnot6),   strip(w2),  strip(w1));';
put @1 '__footnot7   = tranwrd(strip(__footnot7),   strip(w2),  strip(w1));';
put @1 '__footnot8   = tranwrd(strip(__footnot8),   strip(w2),  strip(w1));';
put @1 '__colhead1   = tranwrd(strip(__colhead1),   strip(w2),  strip(w1));';
put @1 '__sfoot_r    = tranwrd(strip(__sfoot_r),    strip(w2),  strip(w1));';
put @1 '__sfoot_m    = tranwrd(strip(__sfoot_m),    strip(w2),  strip(w1));';
put @1 '__sfoot_l    = tranwrd(strip(__sfoot_l),    strip(w2),  strip(w1));';
put @1 '__shead_l    = tranwrd(strip(__shead_l),    strip(w2),  strip(w1));';
put @1 '__shead_m    = tranwrd(strip(__shead_m),    strip(w2),  strip(w1));';
put @1 '__sheade_r   = tranwrd(strip(__shead_r),    strip(w2),  strip(w1));';
put;
put @1 'w1 = strip("' ")" '");';
put @1 'w2 = strip("' "#rpar" '");';
put @1 '__title1     = tranwrd(strip(__title1),     strip(w2),  strip(w1));';
put @1 '__title2     = tranwrd(strip(__title2),     strip(w2),  strip(w1));';
put @1 '__title3     = tranwrd(strip(__title3),     strip(w2),  strip(w1));';
put @1 '__title4     = tranwrd(strip(__title4),     strip(w2),  strip(w1));';
put @1 '__title5     = tranwrd(strip(__title5),     strip(w2),  strip(w1));';
put @1 '__title6     = tranwrd(strip(__title6),     strip(w2),  strip(w1));';
put @1 '__footnot1   = tranwrd(strip(__footnot1),   strip(w2),  strip(w1));';
put @1 '__footnot2   = tranwrd(strip(__footnot2),   strip(w2),  strip(w1));';
put @1 '__footnot3   = tranwrd(strip(__footnot3),   strip(w2),  strip(w1));';
put @1 '__footnot4   = tranwrd(strip(__footnot4),   strip(w2),  strip(w1));';
put @1 '__footnot5   = tranwrd(strip(__footnot5),   strip(w2),  strip(w1));';
put @1 '__footnot6   = tranwrd(strip(__footnot6),   strip(w2),  strip(w1));';
put @1 '__footnot7   = tranwrd(strip(__footnot7),   strip(w2),  strip(w1));';
put @1 '__footnot8   = tranwrd(strip(__footnot8),   strip(w2),  strip(w1));';
put @1 '__colhead1   = tranwrd(strip(__colhead1),   strip(w2),  strip(w1));';
put @1 '__sfoot_r    = tranwrd(strip(__sfoot_r),    strip(w2),  strip(w1));';
put @1 '__sfoot_m    = tranwrd(strip(__sfoot_m),    strip(w2),  strip(w1));';
put @1 '__sfoot_l    = tranwrd(strip(__sfoot_l),    strip(w2),  strip(w1));';
put @1 '__shead_l    = tranwrd(strip(__shead_l),    strip(w2),  strip(w1));';
put @1 '__shead_m    = tranwrd(strip(__shead_m),    strip(w2),  strip(w1));';
put @1 '__shead_r    = tranwrd(strip(__shead_r),    strip(w2),  strip(w1));';
/*
put @1 '__rtype      = "";';
put @1 '__gcols      = "";';
put @1 '__dist2next  = "";';
*/
put;
put "drop w1 w2 __i;";

put @1 "run;";
put;
put @1 '%mend;';
put;
put @1 '%__metadata;';
put;
run;


%mend;
