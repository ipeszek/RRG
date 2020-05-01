/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __UT_prtph(datain=, group=)/store;

%*--------------------------------------------------------------------------
 REPONSIBILITY: 
 this macro processess the dataset with column headers and defines
    spanned headers
 
 AUTHOR:        Iza Peszek, 10NOV2007                                                                              
                                                                              
 MACRO PARAMETERS:                                                            
   &datain:     input data set 
   &group:      number of current column group

NOTE: in future relaease of SAS it may become not necessary to manually
      split dataset prior ti proc report. SAS already does a good 
      job spliting headers automatically, but with 2 problems:
      underlining of spaned headers in not possible to automate this way
      and for RTF output page breaks are not always created 
      after each column group. 
----------------------------------------------------------------------------;


%local datain lastcol group colw;
proc sql noprint;
select __lastcol into:lastcol from &datain;
select __colw into:colw from __rtfcolw where __colgrp=&group;
quit;

data _null_;
x=symget("lastcol");
call symput("lastcol", cats(x));
run;


%let lastcol=%cmpres(&lastcol);


   data &datain;
      length __spanned $ 2000;
      set &datain end=eof;
      keep __nstartnum __nstopnum __rowid __spanned __align __lastrow 
      __varbygrp ;
      array cols{*} __col_0-__col_&lastcol;
      __nstartnum=0;
      __nstopnum=0;
      do __i=0 to &lastcol;
         __nstartnum=__i;
         __spanned = trim(left(cols[__i+1]));
         __nstopnum=__i;
         if __i<&lastcol then do;
            do __j=__i+1 to &lastcol;
               __i=__j;
               if trim(left(cols[__j+1]))=__spanned then do;
                  __nstopnum=__j;
                  if __j=&lastcol then do;
                     __i=&lastcol;
                     __j=&lastcol;
                     output;
                  end;
               end;
               else do;
                  output;
                  __i=__j-1;
                  __j=&lastcol;
               end;
            end;
         end;
         else do;
            output;
         end;
      end;
   run;


   data &datain(rename=(__tmpalign=__align));
      length __tmpalign $ 8 __start __stop __newstart __newstop __colw $ 2000;
      set &datain;
      *__rowid=_n_;
      __start = '__col_'||compress(put(__nstartnum,12.));
      __stop = '__col_'||compress(put(__nstopnum,12.));
      __newstop = __stop;
      __newstart=__start;
      __level = __rowid;
      __colw = compbl(symget("colw"));


         if __nstopnum=__nstartnum then do;
            __tmpalign = scan(__align, __nstopnum+1, ' ');
            __nospan=1;
         end;
         else __tmpalign='C';
         if __align='' then do;
            __tmpalign='C';
            if __nstopnum=0 then __tmpalign='L';
         end;
         if __spanned='' or compress(__spanned)="{\b}" 
             or compress(__spanned)="\b\b0" then __nospan=1;
         __cellwidth=0;    
         do __i=__nstartnum to __nstopnum;
            __tmp = input(scan(__colw, __i+1, ' '), 12.);
            __cellwidth=__cellwidth+__tmp;
         end;
                
      drop __align __i __tmp;
   run;

%mend;
