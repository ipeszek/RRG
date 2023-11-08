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
 
  creates dataset rrgREPORT, 
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

%macro makestring(name);
    %local name;
    *&name=tranwrd(strip(&name),'"',"#dbquot ");
    *&name=tranwrd(strip(&name),"'","#squot ");
    *&name=tranwrd(strip(&name),'(',"#lpar");
    *&name=tranwrd(strip(&name),')',"#rpar");
    &name=tranwrd(strip(&name),'"',"/#0034 ");
    &name=tranwrd(strip(&name),"'","/#0039 ");
    &name=tranwrd(strip(&name),'(',"/#0040 ");
    &name=tranwrd(strip(&name),')',"/#0041 ");

    record=  "__"|| "&name="||'"'|| strip(&name)|| ' ";';  output;
%mend;  




data rrgpgmtmp;
length record $ 2000;
keep record;
set __repinfo;

record= " "; output;
record=   "data rrgreport;"; output;
record=   " length __datatype __fontsize __dest __sfoot_fs $ 8 __footnot1-__footnot14 __title1-__title6"; output;
record=   "        __bookmarks_rtf __bookmarks_pdf __filename __nodatamsg __watermark"; output;
record=   "        __sprops  "; output;
record=   "        __shead_r __shead_m __shead_l "; output;
record=   "        __sfoot_r __sfoot_m __sfoot_l __stretch __colwidths __rtype __gcols $ 2000;"; output;
record= " ";  output;
record=   "   __datatype   = 'RINFO';"; output;
record=   "   __rowid      = .;"; output;
record=   "   __varbygrp   = .;"; output;


%if &islist=Y %then %do;
  record=   '__fontsize="' ||strip(fontsize)|| '";';output;
%end;

record=   '__fontsize="' ||strip(fontsize)|| '";';output;
record=   '__bookmarks_rtf="' ||strip(bookmark_rtf) || '";'; output;
record=   '__bookmarks_pdf="' ||strip(bookmark_pdf) || '";'; output;
record=   '__sfoot_fs="' ||strip( sfoot_fs)|| '";'; output;
if index (upcase(outformat),'RTF')=0 then do;
    if index (upcase(outformat),'PDF')>0 then do;
       record=   '__dest="PDF";'; output;
    end;
    else do;
        record=   '__dest="RTF PDF";'; output; 	
    end;
end;
else do;
    if index (upcase(outformat),'PDF')>0 then do;
        record=   '__dest="RTF PDF";'; output;
    end;
    else do;
        record=   '__dest="RTF";'; output;
    end;  
end;  

record=   '__filename="' ||strip(filename) ||'";'; output;

%makestring(nodatamsg);



%makestring(title1);
%makestring(title2);
%makestring(title3);
%makestring(title4);
%makestring(title5);
%makestring(title6);

%do jj=1 %to 14;
  %makestring(footnot&jj);
%end;

%makestring(nodatamsg);
%makestring(shead_l); 
%makestring(shead_r); 
%makestring(shead_m );
%makestring(sfoot_r );
%makestring(sfoot_l );
%makestring(sfoot_m );
%makestring(sprops);
 


record=   '__stretch="'  ||strip(stretch)|| '";'; output;
record=   '__path = "'||"&rrgoutpath"||'";'; output;
record=   '__colwidths="' ||strip(colwidths)|| '";'; output;
/*record=   '__dist2next="' ||strip(dist2next)|| '";'; output;*/
record=   '__rtype="' ||strip(rtype)|| '";'; output;
record=   '__gcols="' ||strip(gcols)|| '";'; output;
record=   '__lastcheadid="' ||strip(lastcheadid)|| '";'; output;
record=   '__extralines="' ||strip(extralines)|| '";'; output;
record=   '__margins="' ||strip(margins)|| '";'; output;
record=   '__papersize="' ||strip(papersize)||'";'; output;
record=   '__outformat="' ||strip(outformat)||'";'; output;
record=   '__watermark="' ||strip(watermark)||'";'; output;
record=   '__font="'|| strip(font)|| '";'; output;



record= " "; output;


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





record=   "run;"; output;
record= " "; output;

run;


proc append data=rrgpgmtmp base=rrgpgm;
run;


%mend;
