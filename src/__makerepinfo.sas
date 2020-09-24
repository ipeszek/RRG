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
    __title1 - __title6, __footnot1 - __footnot14,
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
     
     
     ds used: __repinfo
     ds created: rrgpgmtmp
     ds updated: this.outds

 */
 

%macro __makerepinfo (numcol=, islist=N)/store;

  
%local  numcol islist;
  

data rrgpgmtmp;
length record $ 200;
keep record;
set __repinfo;
length __tmpw  $ 2000;

record= " "; output;
record=   '%macro __metadata;';output;
record=   '%local __fontsize __indentsize __orient __dest  __nodatamsg';output;
record=   '       __title1 __title2 __title3 __title4 __title5 __title6';output;
record=   '       __footnot1 __footnot2 __footnot3 __footnot4';output;
record=   '       __footnot5 __footnot6 __footnot7 __footnot8 __outformat';   output;
record=   '       __footnot9 __footnot10 __footnot11 __footnot12 __footnot13 __footnot14';   output;
record=   '       __shead_l __shead_r __shead_m __papersize __watermark ';output;
record=   '       __sfoot_l __sfoot_r __sfoot_m __sprops __sfoot_fs __gcols __rtype';output;
record=   '       __colwidths __extralines __stretch i __font __margins __lastcheadid __dist2next';output;
record=   '       __bookmarks_rtf __bookmarks_pdf ;';output;
record= " ";output;
record= " ";output;
%if &islist=Y %then %do;
    record= " ";output;
    record=   '%local breakokat;';output;
    record=   '%let breakokat = '||strip("&breakokat")|| ;";"; output;
    record= " ";output;
%end;

record=   '%let __fontsize=' ||strip(fontsize)|| ";";output;
record=   '%let __bookmarks_rtf=%str(' ||strip(bookmarks_rtf) || ");"; output;
record=   '%let __bookmarks_pdf=%str(' ||strip(bookmarks_pdf) || ");"; output;


record=   '%let __sfoot_fs=' ||strip( sfoot_fs)|| ";"; output;
/*
record=   '%let __indentsize=' ||strip((indentsize)|| ";"; output;
record=   '%let __orient=' ||strip(orient)|| ";"; output;
*/
if index (upcase(outformat),'RTF')=0 then do;
    if index (upcase(outformat),'PDF')>0 then do;
       record=   '%let __dest=PDF;'; output;
    end;
    else do;
        record=   '%let __dest=RTF PDF;'; output; 	
    end;
end;
else do;
    if index (upcase(outformat),'PDF')>0 then do;
        record=   '%let __dest=RTF PDF;'; output;
    end;
    else do;
        record=   '%let __dest=RTF;'; output;
    end;  
end;  

record=   '%let __filename=' ||strip(filename) ||";"; output;
record=   '%let __nodatamsg=' ||strip( nodatamsg)|| ";"; output;

array titles title1-title6 ;
array foots footnot1-footnot14 ;

do jj=1 to dim(titles);
    __xx= countw(titles[jj], ' ');
    __yy = floor(__xx/10);
    __yy2 = __xx-10*__yy;
    __tmpw='';

    do __i = 1 to __yy;
      __tmpw='';
      do __j =1 to 10;
        __tmpw = strip(__tmpw)||' '||strip(scan(titles[jj], 10*(__i-1)+__j,' '));
      end;
      record=   '%let __title'||put(jj,1.)||' = %str(&__title'||put(jj,1.)||'.)%str('||
         strip( __tmpw)||");";  output;
    end;  
    __tmpw='';
    do __j=1 to __yy2;
        __tmpw = strip(__tmpw)||' '||strip(scan(titles[jj], 10*__yy+__j,' '));
    end;
    record=   '%let __title'||put(jj,1.)||' = %str(&__title'||put(jj,1.)||'.)%str(' ||
        strip(__tmpw)||");";  output;
 end;     
      
 
 do jj=1 to dim(foots);
 
    __xx= countw(foots[jj], ' ');
    __yy = floor(__xx/10);
    __yy2 = __xx-10*__yy;
    __tmpw='';

    do __i = 1 to __yy;
        __tmpw='';
        do __j =1 to 10;
          __tmpw = strip(__tmpw)||' '||strip(scan(foots[jj], 10*(__i-1)+__j,' '));
        end;
        record=   '%let __footnot'||put(jj,1.)||' = %str(&__footnot'||put(jj,1.)||'.)%str('||
          strip( __tmpw)||");";  output;
    end;
        __tmpw='';
        do __j=1 to __yy2;
            __tmpw = strip(__tmpw)||' '||strip(scan(foots[jj], 10*__yy+__j,' '));
        end;
        record=   '%let __footnot'||put(jj,1.)||' = %str(&__footnot'||put(jj,1.)||'.)%str(' ||
            strip(__tmpw)||");";    output;   
    
end;

__xx= countw(shead_l, ' ');
__yy = floor(__xx/10);
__yy2 = __xx-10*__yy;
__tmpw='';

do __i = 1 to __yy;
  __tmpw='';
  do __j =1 to 10;
    __tmpw = strip(__tmpw)||' '||strip(scan(shead_l, 10*(__i-1)+__j,' '));
  end;
  record=   '%let __shead_l = %str(&__shead_l.)%str('||strip(__tmpw)||");";  output;
end;
  __tmpw='';
  do __j=1 to __yy2;
    __tmpw = strip(__tmpw)||' '||strip(scan(shead_l, 10*__yy+__j,' ')); 
  end;
  record=   '%let __shead_l = %str(&__shead_l.)%str('||strip(__tmpw)||");";  output;
  

__xx= countw(shead_m, ' ');
__yy = floor(__xx/10);
__yy2 = __xx-10*__yy;
__tmpw='';

do __i = 1 to __yy;
  __tmpw='';
  do __j =1 to 10;
    __tmpw = strip(__tmpw)||' '||strip(scan(shead_m, 10*(__i-1)+__j,' '));
  end;
  record=   '%let __shead_m = %str(&__shead_m.)%str('||strip(__tmpw)||");";  output;
end;
  __tmpw='';
  do __j=1 to __yy2;
    __tmpw = strip(__tmpw)||' '||strip(scan(shead_m, 10*__yy+__j,' '));
  end;
  record=   '%let __shead_m = %str(&__shead_m.)%str('||strip(__tmpw)||");";  output;
  

__xx= countw(shead_r, ' ');
__yy = floor(__xx/10);
__yy2 = __xx-10*__yy;
__tmpw='';

do __i = 1 to __yy;
  __tmpw='';
  do __j =1 to 10;
    __tmpw = strip(__tmpw)||' '||strip(scan(shead_r, 10*(__i-1)+__j,' '));
  end;
  record=   '%let __shead_r = %str(&__shead_r.)%str('||strip(__tmpw)||");"; output;
end;
  __tmpw='';
  do __j=1 to __yy2;
    __tmpw = strip(__tmpw)||' '||strip(scan(shead_r, 10*__yy+__j,' '));
  end;
  record=   '%let __shead_r = %str(&__shead_r.)%str('||strip(__tmpw)||");"; output;
  

__xx= countw(sfoot_r, ' ');
__yy = floor(__xx/10);
__yy2 = __xx-10*__yy;
__tmpw='';

do __i = 1 to __yy;
  __tmpw='';
  do __j =1 to 10;
    __tmpw = strip(__tmpw)||' '||strip(scan(sfoot_r, 10*(__i-1)+__j,' '));
  end;
  record=   '%let __sfoot_r = %str(&__sfoot_r.)%str('||strip(__tmpw)||");"; output;
end;
  __tmpw='';
  do __j=1 to __yy2;
    __tmpw = strip(__tmpw)||' '||strip(scan(sfoot_r, 10*__yy+__j,' '));
  end;
  record=   '%let __sfoot_r = %str(&__sfoot_r.)%str('||strip(__tmpw)||");"; output;
  

__xx= countw(sfoot_m, ' ');
__yy = floor(__xx/10);
__yy2 = __xx-10*__yy;
__tmpw='';

do __i = 1 to __yy;
  __tmpw='';
  do __j =1 to 10;
    __tmpw = strip(__tmpw)||' '||strip(scan(sfoot_m, 10*(__i-1)+__j,' '));
  end;
  record=   '%let __sfoot_m = %str(&__sfoot_m.)%str('||strip(__tmpw)||");"; output;
end;
  __tmpw='';
  do __j=1 to __yy2;
    __tmpw = strip(__tmpw)||' '||strip(scan(sfoot_m, 10*__yy+__j,' '));
  end;
  record=   '%let __sfoot_m = %str(&__sfoot_m.)%str('||strip(__tmpw)||");"; output;
  

__xx= countw(sfoot_l, ' ');
__yy = floor(__xx/10);
__yy2 = __xx-10*__yy;
__tmpw='';

do __i = 1 to __yy;
  __tmpw='';
  do __j =1 to 10;
    __tmpw = strip(__tmpw)||' '||strip(scan(sfoot_l, 10*(__i-1)+__j,' '));
  end;
  record=   '%let __sfoot_l = %str(&__sfoot_l.)%str('||strip(__tmpw)||");"; output;
end;
  __tmpw='';
  do __j=1 to __yy2;
    __tmpw = strip(__tmpw)||' '||strip(scan(sfoot_l, 10*__yy+__j,' '));
  end;
  record=   '%let __sfoot_l = %str(&__sfoot_l.)%str('||strip(__tmpw)||");"; output;
  

%* assembe sprops;
record=   '%let __sprops= &__sprops. xx=xx;'; output;
__xx= countw(sprops, ',');
__yy = floor(__xx/10);
__yy2 = __xx-10*__yy;
__tmpw='';

do __i = 1 to __yy;
  __tmpw='';
  do __j =1 to 10;
    __tmpw = strip(__tmpw)||','||strip(scan(sprops, 10*(__i-1)+__j,','));
  end;
  record=   '%let __sprops= %str(&__sprops.)%str(' ||strip(__tmpw)||");"; output;
end;  
  __tmpw='';
  do __j=1 to __yy2;
    __tmpw = strip(__tmpw)||','||strip(scan(sprops, 10*__yy+__j,','));
  end;
  record=   '%let __sprops= %str(&__sprops.)%str(' ||strip(__tmpw)||");"; output;
  




record=   '%let __stretch='  ||strip(stretch)|| ";"; output;

record=   '%local __path;'; output;
record=   '%if %length(&rrgoutpath)=0 %then'; output;
record=   '  %let __path='|| "&rrgoutpathlazy;"; output;
record=   '%else %let __path = &rrgoutpath;'; output;
record=   '%let __colwidths=' ||strip(colwidths)|| ";"; output;
record=   '%let __dist2next=' ||strip(dist2next)|| ";"; output;
record=   '%let __rtype=' ||strip(rtype)|| ";"; output;
record=   '%let __gcols=' ||strip(gcols)|| ";"; output;
record=   '%let __lastcheadid=' ||strip(lastcheadid)|| ";"; output;
record=   '%let __extralines=' ||strip(extralines)|| ";"; output;
record=   '%let __margins=' ||strip(margins)|| ";"; output;
record=   '%let __papersize=' ||strip(papersize)||";"; output;
record=   '%let __outformat=' ||strip(outformat)||";"; output;
record=   '%let __watermark=' ||strip(watermark)||";"; output;
record=   '%let __font='|| strip(font)|| ";"; output;



record= " "; output;
record=   "data __report;"; output;
record=   " length __datatype $ 8 __footnot1-footnot14 title1-title6"; output;
record=   "        __bookmarks_rtf __bookmarks_pdf"; output;
record=   "        __sprops __systitle "; output;
record=   "        __shead_r __shead_m __shead_l __dist2next __breakokat"; output;
record=   "        __sfoot_r __sfoot_m __sfoot_l __stretch __colwidths __rtype __gcols $ 2000;"; output;
record= " ";  output;
record=   "   __datatype   = 'RINFO';"; output;
record=   "   __rowid      = .;"; output;
record=   "   __varbygrp   = .;"; output;
record=   "   __sprops     = trim(left(symget('__sprops')));"; output;
record=   "   __fontsize   = trim(left(symget('__fontsize')));"; output;
record=   "   __bookmarks_pdf   = trim(left(symget('__bookmarks_pdf')));"; output;
record=   "   __bookmarks_rtf   = trim(left(symget('__bookmarks_rtf')));"; output;

record=   "   __papersize  = trim(left(symget('__papersize')));"; output;
record=   "   __watermark  = trim(left(symget('__watermark')));"; output;
record=   "   __indentsize = trim(left(symget('__indentsize')));"; output;
record=   "   __orient     = trim(left(symget('__orient')));"; output;
record=   "   __breakokat  = trim(left(symget('breakokat')));"; output;
record=   "   __dest       = trim(left(symget('__dest')));"; output;
record=   "   __filename   = trim(left(symget('__filename')));"; output;


record=   "  __nodatamsg   = trim(left(symget('__nodatamsg')));"; output;
record=   "  __title1      = trim(left(symget('__title1')));"; output;
record=   "  __title2      = trim(left(symget('__title2')));"; output;
record=   "  __title3      = trim(left(symget('__title3')));"; output;
record=   "  __title4      = trim(left(symget('__title4')));"; output;
record=   "  __title5      = trim(left(symget('__title5')));"; output;
record=   "  __title6      = trim(left(symget('__title6')));"; output;
record=   "  __footnot1    = trim(symget('__footnot1'));"; output;
record=   "  __footnot2    = trim(symget('__footnot2'));"; output;
record=   "  __footnot3    = trim(symget('__footnot3'));"; output;
record=   "  __footnot4    = trim(symget('__footnot4'));"; output;
record=   "  __footnot5    = trim(symget('__footnot5'));"; output;
record=   "  __footnot6    = trim(symget('__footnot6'));"; output;
record=   "  __footnot7    = trim(symget('__footnot7'));"; output;
record=   "  __footnot8    = trim(symget('__footnot8'));"; output;
record=   "  __footnot9    = trim(symget('__footnot9'));"; output;
record=   "  __footnot10    = trim(symget('__footnot10'));"; output;
record=   "  __footnot11    = trim(symget('__footnot11'));"; output;
record=   "  __footnot12    = trim(symget('__footnot12'));"; output;
record=   "  __footnot13    = trim(symget('__footnot13'));"; output;
record=   "  __footnot14     = trim(symget('__footnot14'));"; output;
record=   "  __path        = trim(left(symget('__path')));"; output;
record=   "  __systitle    = trim(left(symget('__shead_l')));"; output;
record=   "  __shead_l     = trim(left(symget('__shead_l')));"; output;
record=   "  __shead_m     = trim(left(symget('__shead_m')));"; output;
record=   "  __shead_r     = trim(left(symget('__shead_r')));"; output;
record=   "  __sfoot_l     = trim(left(symget('__sfoot_l')));"; output;
record=   "  __sfoot_m     = trim(left(symget('__sfoot_m')));"; output;
record=   "  __sfoot_r     = trim(left(symget('__sfoot_r')));"; output;
record=   "  __colwidths   = trim(left(symget('__colwidths')));"; output;
record=   "  __sfoot_fs    = trim(left(symget('__sfoot_fs')));"; output;
record=   " __extralines   = trim(left(symget('__extralines')));"; output;
record=   " __stretch      = trim(left(symget('__stretch')));"; output;
record=   " __font         = trim(left(symget('__font')));"; output;
record=   " __margins      = trim(left(symget('__margins')));"; output;
record=   " __outformat    = trim(left(symget('__outformat')));"; output;
record=   " __version      = '"|| "%__version.';" ; output;
record=   " __lastcheadid  = trim(left(symget('__lastcheadid')));"; output;
record=   " __rtype        = trim(left(symget('__rtype')));"; output;
record=   " __gcols        = trim(left(symget('__gcols')));"; output;
record=   " __dist2next    = trim(left(symget('__dist2next')));"; output;
record= " "; output;
record=   "__i=0;"; output;
record=   "if __colwidths='' then __colwidths='LW';"; output;
record=   "if countw(__colwidths,' ')=1 then do;"; output;
%if %length(&numcol)=0 %then %do;
    record=   '   __colwidths = compbl(__colwidths)||repeat(" NH", &maxtrt-1);'; output;
%end;
%else %do;
    record=   "   __colwidths = compbl(__colwidths)||repeat(' NH', &numcol-1);"; output;
%end;
record=   "end;  "; output;
%if %length(&numcol)=0 %then %do;
    record=   'else if countw(__colwidths," ")<&maxtrt+1 then do;'; output;
    record=   '   __colwidths = compbl(__colwidths)||repeat(" "||scan(__colwidths,-1," "), &maxtrt-countw(__colwidths," "));'; output;
%end;
%else %do;
    record=   "else if countw(__colwidths,' ')<&numcol+1 then do;"; output;
    record=   "   __colwidths = compbl(__colwidths)||repeat(' '||scan(__colwidths,-1,' '), &numcol-countw(__colwidths,' '));"; output;
%end;
record=   "end;"; output;
put 'put __colwidths=;'; output;

record=   "if __stretch='' then __stretch='Y';"; output;
%if %length(&numcol)=0 %then %do;
    record=   'if countw(__stretch," ")<&maxtrt+1 then do;'; output;
    record=   '   __stretch = compbl(__stretch)||repeat(" "||scan(__stretch,-1," "), &maxtrt-countw(__stretch," "));'; output;
%end;
%else %do;
    record=   "if countw(__stretch,' ')<&numcol+1 then do;"; output;
    record=   "   __stretch = compbl(__stretch)||repeat(' '||scan(__stretch,-1,' '), &numcol-countw(__stretch,' '));"; output;

%end;
record=   "end;"; output;
record= " "; output;
record=   'w1 = strip("'|| "'"|| '");'; output;
record=   'w2 = strip("'|| "#squot" ||'");'; output;
record=   '__colhead1   = tranwrd(strip(__colhead1),     strip(w2),  strip(w1));'; output;
record=   '__title1     = tranwrd(strip(__title1),     strip(w2),  strip(w1));'; output;
record=   '__title2     = tranwrd(strip(__title2),     strip(w2),  strip(w1));'; output;
record=   '__title3     = tranwrd(strip(__title3),     strip(w2),  strip(w1));'; output;
record=   '__title4     = tranwrd(strip(__title4),     strip(w2),  strip(w1));'; output;
record=   '__title5     = tranwrd(strip(__title5),     strip(w2),  strip(w1));'; output;
record=   '__title6     = tranwrd(strip(__title6),     strip(w2),  strip(w1));'; output;
%do i=1 %to 14;
    record=   "__footnot&i   = tranwrd(strip(__footnot&i),   strip(w2),  strip(w1));"; output;
%end;

record=   '__colhead1   = tranwrd(strip(__colhead1),   strip(w2),  strip(w1));'; output;
record=   '__sfoot_r    = tranwrd(strip(__sfoot_r),    strip(w2),  strip(w1));'; output;
record=   '__sfoot_m    = tranwrd(strip(__sfoot_m),    strip(w2),  strip(w1));'; output;
record=   '__sfoot_l    = tranwrd(strip(__sfoot_l),    strip(w2),  strip(w1));'; output;
record=   '__shead_l    = tranwrd(strip(__shead_l),    strip(w2),  strip(w1));'; output;
record=   '__shead_m    = tranwrd(strip(__shead_m),    strip(w2),  strip(w1));'; output;
record=   '__shead_r    = tranwrd(strip(__shead_r),    strip(w2),  strip(w1));'; output;
record= " "; output;
record=   'w1 = strip("'||"("|| '");'; output;
record=   'w2 = strip("'|| "#lpar"|| '");'; output;
record=   '__colhead1   = tranwrd(strip(__colhead1),     strip(w2),  strip(w1));'; output;
record=   '__title1     = tranwrd(strip(__title1),     strip(w2),  strip(w1));'; output;
record=   '__title2     = tranwrd(strip(__title2),     strip(w2),  strip(w1));'; output;
record=   '__title3     = tranwrd(strip(__title3),     strip(w2),  strip(w1));'; output;
record=   '__title4     = tranwrd(strip(__title4),     strip(w2),  strip(w1));'; output;
record=   '__title5     = tranwrd(strip(__title5),     strip(w2),  strip(w1));'; output;
record=   '__title6     = tranwrd(strip(__title6),     strip(w2),  strip(w1));'; output;
%do i=1 %to 14;
    record=   "__footnot&i   = tranwrd(strip(__footnot&i),   strip(w2),  strip(w1));"; output;
%end;
record=   '__colhead1   = tranwrd(strip(__colhead1),   strip(w2),  strip(w1));'; output;
record=   '__sfoot_r    = tranwrd(strip(__sfoot_r),    strip(w2),  strip(w1));'; output;
record=   '__sfoot_m    = tranwrd(strip(__sfoot_m),    strip(w2),  strip(w1));'; output;
record=   '__sfoot_l    = tranwrd(strip(__sfoot_l),    strip(w2),  strip(w1));'; output;
record=   '__shead_l    = tranwrd(strip(__shead_l),    strip(w2),  strip(w1));'; output;
record=   '__shead_m    = tranwrd(strip(__shead_m),    strip(w2),  strip(w1));'; output;
record=   '__sheade_r   = tranwrd(strip(__shead_r),    strip(w2),  strip(w1));'; output;
record= " "; output;
record=   'w1 = strip("' ||")"|| '");'; output;
record=   'w2 = strip("' ||"#rpar"|| '");'; output;
record=   '__title1     = tranwrd(strip(__title1),     strip(w2),  strip(w1));'; output;
record=   '__title2     = tranwrd(strip(__title2),     strip(w2),  strip(w1));'; output;
record=   '__title3     = tranwrd(strip(__title3),     strip(w2),  strip(w1));'; output;
record=   '__title4     = tranwrd(strip(__title4),     strip(w2),  strip(w1));'; output;
record=   '__title5     = tranwrd(strip(__title5),     strip(w2),  strip(w1));'; output;
record=   '__title6     = tranwrd(strip(__title6),     strip(w2),  strip(w1));'; output;
%do i=1 %to 14;
    record=   "__footnot&i   = tranwrd(strip(__footnot&i),   strip(w2),  strip(w1));"; output;
%end;
record=   '__colhead1   = tranwrd(strip(__colhead1),   strip(w2),  strip(w1));'; output;
record=   '__sfoot_r    = tranwrd(strip(__sfoot_r),    strip(w2),  strip(w1));'; output;
record=   '__sfoot_m    = tranwrd(strip(__sfoot_m),    strip(w2),  strip(w1));'; output;
record=   '__sfoot_l    = tranwrd(strip(__sfoot_l),    strip(w2),  strip(w1));'; output;
record=   '__shead_l    = tranwrd(strip(__shead_l),    strip(w2),  strip(w1));'; output;
record=   '__shead_m    = tranwrd(strip(__shead_m),    strip(w2),  strip(w1));'; output;
record=   '__shead_r    = tranwrd(strip(__shead_r),    strip(w2),  strip(w1));'; output;

record= " "; output;
record= "drop w1 w2 __i;"; output;
record=   "run;"; output;
record= " "; output;
record=   '%mend;'; output;
record= " "; output;
record=   '%__metadata;'; output;
record= " "; output;
run;


proc append data=rrgpgmtmp base=rrgpgm;
run;


%mend;
