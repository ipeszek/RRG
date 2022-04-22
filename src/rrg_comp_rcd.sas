/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */
/*
****************************************************************************
****************************************************************************
**-PROGRAM NAME: COMP_RCD.SAS
**-
**-DESCRIPTION:  MACRO TO  COMPARE 2 RCD OUTPUTS
**-
**-CODED BY:     PESZEKI ON 13OCT2010
**-MOD BY:       
**-
**-INPUT:
**-     
**-
**-OUTPUT:
**-       &RRGURI._DIFF.RTF
**-
**-
**-MACROS:  
**-  
**-
**-NOTES: 
****************************************************************************
****************************************************************************;
*/

options mautosource sasautos=(sasautos);


%macro rrg_comp_rcd(oldlib=, newlib=, rrguri=)/store;

%local rrguri oldlib newlib;



/*
1. read in both RCD dtasets
2. create new rowid
3. check number of columns
4. if one has more columns then other, create additional blank columns
   (todo)
5. merge 2 datasets and compare each column value
   if all are the same, diff=0
   if at least one is different, diff=1 
   concatenate 2 dataset (if diff=1 then corresponding column gets different color)
6 use sasshiato to print   

*/


%local oldnumcol newnumcol oldnumrec newnumrec oldnumds newnumds;
%let oldnumds=1;
%let newnumds=1;

%local dsid vnum1 vnum2 rc isvargrp1 isvargrp2;
%let dsid = %sysfunc(open(&oldlib..&rrguri));
%put dsid=&dsid;
%let vnum1 = %sysfunc(varnum(&dsid, __dsid));
%let isvargrp1 = %sysfunc(varnum(&dsid, __varbygrp));
%let rc= %sysfunc(close(&dsid));
%let dsid = %sysfunc(open(&newlib..&rrguri));
%let vnum2 = %sysfunc(varnum(&dsid, __dsid));
%let isvargrp2 = %sysfunc(varnum(&dsid, __varbygrp));
%let rc= %sysfunc(close(&dsid));

%if &isvargrp1<=0 %then %do;
  data d10;
    set &oldlib..&rrguri;
    __varbygrp=1;
    __varbylab='';
  run; 
%end;

%else %do;
  data d10;
    set &oldlib..&rrguri;
  run; 
%end;

%if &isvargrp2<=0 %then %do;
  data d20;
    set &newlib..&rrguri;
    __varbygrp=1;
    __varbylab='';
  run; 
%end;

%else %do;
  data d20;
    set &newlib..&rrguri;
  run; 
%end;


%if &vnum1>0 and &vnum2>0 %then %do;

  proc sql noprint;
  select max(__dsid) into:oldnumds separated by '' from &oldlib..&rrguri;
  select max(__dsid) into:newnumds separated by '' from &newlib..&rrguri;
  quit;

%end;


%local j war ning;
%let war=WAR;
%let ning=NING;

%if &newnumds ne &oldnumds %then %do;
%put &war.&ning.: structure of the table is completely different;
%goto skip;
%end;

%do j=1 %to &oldnumds;
    
    

    data d1;
    length t1-t6 f1-f8 $ 2000;
    %if &vnum1>0 and &vnum2>0 %then %do;
    set d10 (where=(__dsid=&j) drop=__rowid) end=eof;
    %end;
    %else %do;
    set d1 ( drop=__rowid) end=eof;
    %end;
    __rowid=_n_;
    
    array cols{*} __col_:;
    array ts{*} t1-t6;
    array fs{*} f1-f8;
    array titles{*} __title1-__title6;
    array foots{*} __footnot1-__footnot14;
    
    __numcol = dim(cols)-1;
    if eof then call symput('oldnumrec', strip(put(_N_, best.)));
    
    if __datatype='RINFO' then do;
      cnt=1;
      do k=1 to 6;
        if titles[k] ne '' then DO;
          ts[cnt]=titles[k];
          cnt=cnt+1;
        end;  
      end;  
      cnt=1;
      do k=1 to 8;
        if foots[k] ne '' then DO;
          fs[cnt]=tranwrd(foots[k], '/ftr',' ');
          fs[cnt]=tranwrd(fs[cnt], '/ftl',' ');
          cnt=cnt+1;
        end;  
      end;  
    
    end;
    ;
    run;
    
    proc sort data=d1;
      by __varbylab __varbygrp  __rowid;
    run;
    
    data d1 (drop = __rowid rename=(__nrowid=__rowid));
      set d1;
      by __varbylab __varbygrp  __rowid;
      retain __nrowid;
      if first.__varbygrp then __nrowid=0;
      __nrowid+1;
    run;
      
    
    data d2;
    length t1-t6 f1-f8 $ 2000;
    %if &vnum1>0 and &vnum2>0 %then %do;
    set d20 (where=(__dsid=&j) drop=__rowid) end=eof;
    %end;
    %else %do;
    set d2 (drop=__rowid) end=eof;
    %end;


    __rowid=_n_;
    array cols{*} __col_:;
    array ts{*} t1-t6;
    array fs{*} f1-f8;
    array titles{*} __title1-__title6;
    array foots{*} __footnot1-__footnot14;
    
    __numcol = dim(cols)-1;
    if eof then call symput('newnumrec', strip(put(_N_, best.)));
    
    if __datatype='RINFO' then do;
      cnt=1;
      do k=1 to 6;
        if titles[k] ne '' then DO;
          ts[cnt]=titles[k];
          cnt=cnt+1;
        end;  
      end;  
      cnt=1;
      do k=1 to 8;
        if foots[k] ne '' then DO;
          fs[cnt]=tranwrd(foots[k], '/ftr',' ');
          fs[cnt]=tranwrd(fs[cnt], '/ftl',' ');
          cnt=cnt+1;
        end;  
      end;
    end;    
    drop __title: __footnot:;
    run;
    
    proc sort data=d2;
      by __varbylab __varbygrp __rowid;
    run;
    
    data d2 (drop = __rowid rename=(__nrowid=__rowid));
      set d2;
      by __varbylab __varbygrp __rowid;
      retain __nrowid;
      if first.__varbygrp then __nrowid=0;
      __nrowid+1;
    run;
    
    
    %local tit1 tit2 tit3 tit4 tit5 tit6 f1 f2 f3 f4 f5 f6 f7 f8 k;
    proc sql noprint;
    %do k=1 %to 6;
    select t&k into:tit&k separated by '' from d1 (where=(__datatype='RINFO'));
    %end;
    %do k=1 %to 8;
    select f&k into:f&k separated by '' from d1 (where=(__datatype='RINFO'));
    %end;
    quit;
    
    data d2;
    length __title1-__title6 __footnot1-__footnot14 $ 2000;
    set d2;
    by __varbylab __varbygrp __rowid;
    diff2=0;
    if __datatype='RINFO' then do;
      %do k=1 %to 6;
        if trim(t&k) ne trim(symget("tit&k")) then do;
          __title&k = "{\cf2 "||trim(symget("tit&k"))||"}//{\cf3 "||trim(t&k)||"}";
          diff2=1;
        end;  
        else __title&k = trim(t&k);
      %end;
      %do k=1 %to 8;
        if trim(f&k) ne trim(symget("f&k")) then do;
          __footnot&k = "{\cf2 "||trim(symget("f&k"))||"}//{\cf3 "||trim(f&k)||"}";
          diff2=1;
        end;  
        else __footnot&k = trim(f&k);
      %end;
    end;
    run;
    
    
    proc sql noprint;
    %do k=1 %to 6;
    select t&k into:tit&k separated by '' from d2 (where=(__datatype='RINFO'));
    %end;
    %do k=1 %to 8;
    select f&k into:f&k separated by '' from d2 (where=(__datatype='RINFO'));
    %end;
    quit;
    
    data d1;
    length __title1-__title6 __footnot1-__footnot14 $ 2000;
    set d1;
    by __varbylab __varbygrp __rowid;
    diff2=0;
    if __datatype='RINFO' then do;
      %do k=1 %to 6;
        if trim(t&k) ne trim(symget("tit&k")) then do;
          __title&k = "{\cf2 "||trim(t&k)||"}//{\cf3 "||trim(symget("tit&k"))||"}";
          diff2=1;
        end;  
        else __title&k = trim(t&k);
      %end;
      %do k=1 %to 8;
        if trim(f&k) ne trim(symget("f&k")) then do;
          __footnot&k = "{\cf2 "||trim(f&k)||"}//{\cf3 "||trim(symget("f&k"))||"}";
          diff2=1;
        end;  
        else __footnot&k = trim(f&k);
      %end;
    end;
    run;
    

    
    
    proc sql noprint;
    select distinct __numcol into:oldnumcol separated by '' from d1;
    select distinct __numcol into:newnumcol separated by '' from d2;
    quit;
    
    
    
    %put old number of columns: &oldnumcol;
    %put new number of columns: &newnumcol;
    
    %put old number of records: &oldnumrec;
    %put new number of records: &newnumrec;
    
    %local i maxc;
    %let maxc=&oldnumcol;
    %if &oldnumcol<&newnumcol %then %let maxc=&newnumcol;
    
    

    
    %if &oldnumcol<&newnumcol %then %do;
    data d1;
    set d1;
    %end;
    %else %do;
    data d2; set d2;
    %end;
    keep __col_: __rowid __varby:;
    if __datatype ne 'RINFO' then output;
    run;

        
    proc sort data=d1;
    by __varbylab __varbygrp __rowid;
    run;
    
    proc sort data=d2;
    by __varbylab __varbygrp __rowid;
    run;
    
    %if &oldnumcol<&newnumcol %then %do;
    data d3;
    length __col_0 - __col_&maxc __colwidths $ 4000;
    merge d1 (rename=(%do i=0 %to &oldnumcol; __col_&i=__newcol_&i  %end;)) d2;
    by __varbylab __varbygrp __rowid;
    %if &j=1 %then %do;
    __filename = "&rrguri._diff";
    %end;
    %else %do;
    __filename = "&rrguri._diff_part_&j";
    %end;
    __watermark='';
    __font='COURIER';
    __fontsize=8;
    __outformat='SRTF';
    __colwidths = repeat('LW ', &maxc);
    __stretch =  repeat('Y ', &maxc);
    diff=0;
    %do i=0 %to &oldnumcol;
        if trim(__col_&i) ne trim(__newcol_&i) then diff=1;
    %end;
    %do i=%eval(&oldnumcol+1) %to &newnumcol;
         diff=1;
    %end;
    if diff=1 then do;
    %do i=0 %to &oldnumcol;
        if trim(__col_&i) ne trim(__newcol_&i) then do;  
          if __col_&i='' then __col_&i='<BLANK>';
          if __newcol_&i='' then __newcol_&i='<BLANK>';
          __col_&i ="{\cf2 "||trim(__newcol_&i)||"} // {\cf3 "||trim(__col_&i)||"}"; 
        end;  
    %end;
    %do i=%eval(&oldnumcol+1) %to &newnumcol;
         __col_&i ="{\cf3 "||trim(__col_&i)||"}";
    %end;
    end;
    drop __align;
    run;
    
    %end;
    
    %else %do;
    
    proc sort data=d1;
      by __varbylab __varbygrp __rowid;
    run;
    
    proc sort data=d2;
      by __varbylab __varbygrp __rowid;
    run;
    
    data d3;
    length __col_0 - __col_&maxc $ 4000;
    merge d1 (rename=(%do i=0 %to &oldnumcol; __col_&i=__newcol_&i  %end;)) d2;
    by __varbylab __varbygrp __rowid;
    %if &j=1 %then %do;
    __filename = "&rrguri._diff";
    %end;
    %else %do;
    __filename = "&rrguri._diff_part_&j";
    %end;

    __watermark='';
    __font='COURIER';
    __fontsize=8;
    __outformat='RTF';
    __stretch =  repeat('Y ', &maxc);
    __colwidths = repeat('LW ', &maxc);
    diff=0;
    %do i=0 %to &newnumcol;
        if trim(__col_&i) ne trim(__newcol_&i) then  diff=1;
    %end;
    %do i=%eval(&newnumcol+1) %to &oldnumcol;
         diff=1;
    %end;
    if diff=1 then do;
    %do i=0 %to &newnumcol;
        if trim(__col_&i) ne trim(__newcol_&i) then do;
          if __col_&i='' then __col_&i='<BLANK>';
          if __newcol_&i='' then __newcol_&i='<BLANK>';
          __col_&i ="{\cf2 "||trim(__newcol_&i)||"} // {\cf3 "||trim(__col_&i)||"}"; 
          diff=1;
        end;  
    %end;
    %do i=%eval(&newnumcol+1) %to &oldnumcol;
         __col_&i ="{\cf2 "||trim(__newcol_&i)||"}";
         diff=1;
    %end;
    end;
    drop __align;
    run;
    
    %end;
    
   
    
    %local maxdiff1 maxdiff2;
    proc sql noprint;
    select max(diff) into:maxdiff1 from d3;
    select max(diff2) into:maxdiff2 from d3;
    quit;
    
    %if &maxdiff1=0 and &maxdiff2=0 %then %do;
    data d3;
    set d3;
    if __datatype='RINFO';
    __nodatamsg='Tables are identical';
    run;
    
    %end;
    
    %else %do;

      %if &maxdiff1=0  %then %do;
      
        data d30;
          length __col_0 $ 200;
          __datatype='HEAD'; __rowid=1; __col_0 = ''; output;
          __datatype='TBODY'; __col_0 = 'Contents of the tables are identical. Only Titles or Footnotes are different.';
           __rowid=2; output;
         run;
  
        data d3;
        set d3 (where=(__datatype='RINFO')) d30;
        run;      
      
      %end;  
    
    %end;
    
    %__sasshiato(dataset=d3);
    
    %end;

%skip:
%mend;

