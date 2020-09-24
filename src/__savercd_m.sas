/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __savercd_m/store;
 %local rrgoutpathlazy ;
 %let rrgoutpathlazy=&rrgoutpath;
 %local __path;
 
  %if %length(&rrgoutpath)=0 %then %let __path=&rrgoutpathlazy;
  %else %let __path = &rrgoutpath;
  
  libname out "&__path";
 
  *---------------------------------------------------------;
  *  SAVE RCD DATASET;
  *---------------------------------------------------------;
 
  %if %upcase(&append)=N %then %do;
        
        data out.&rrguri (compress=YES);
        length __varbylab $ 2000;
          set &rrguri;
    
          retain __col_:  __rowid __datatype __varbygrp __varbylab __vtype 
                __indentlev  __next_indentlev __align __suffix __keepn __blockid 
               __dsid __tcol __gcols __first:  __fname __cell: __topborderstyle 
              __bottomborderstyle __foot: __title: __shead_: __sfoot_: __nodatamsg;
    
    
    
         if 0 then do;
            __tcol='';
            __gcols='';
            __datatype='';
            __varbygrp='';
            __varbylab='';
            __vtype='';
            __fname='';
            __rowid=.;
            __col_0='';
            %do i=1 %to 14;
              __footnot1='';
            %end;
              
            
            __title1='';
            __title2='';
            __title3='';
            __title4='';
            __title5='';
            __title6='';
            __shead_l='';
            __shead_m='';
            __shead_r='';
            __sfoot_l='';
            __sfoot_m='';
            __sfoot_r='';
            __nodatamsg='';
            __align='';
            __suffix='';
            __keepn=.;
            __blockid=.;
            __indentlev =.;
            __dsid=.;
            __first=.;
            __next_indentlev=.;
          end;
          __dsid=1;
    
    
          keep __datatype __vtype __rowid __col_: __foot: __title: __next_indentlev 
          __shead_: __sfoot_: __nodatamsg __align __suffix __keepn __blockid __cell:
          __indentlev __dsid __tcol __gcols __first: __varbygrp __varbylab __fname 
          __topborderstyle __bottomborderstyle;
        run;
   
  %end;
    
  %else %do;
 
        %local dsid;
        proc sql noprint;
          select max(__dsid) into:dsid separated by ' ' from out.&rrguri;
        quit;
    
          data out.&rrguri (compress=YES);
           set out.&rrguri(in=__old) &rrguri(in=__new);
           if __new then __dsid=&dsid+1;
    
           retain __rowid __col_: __datatype __vtype __indentlev  __next_indentlev
                 __align __suffix __keepn __blockid __varbygrp __varbylab __dsid 
                  __tcol __gcols __first:  __fname __cell:  __topborderstyle __bottomborderstyle
                __foot: __title: __shead: __sfoot: __nodatamsg 
    
           if 0 then do;
             __datatype='';
            __varbygrp='';
            __varbylab='';
             __vtype='';
             __fname='';
             __rowid=.;
             __col_0='';
             %do i=1 %to 14;
                 __footnot&i='';
             %end;
                        
             __title1='';
             __title2='';
             __title3='';
             __title4='';
             __title5='';
             __title6='';
             __shead_l='';
             __shead_m='';
             __shead_r='';
             __sfoot_l='';
             __sfoot_m='';
             __sfoot_r='';
             __nodatamsg='';
             __align='';
             __suffix='';
             __keepn=.;
             __blockid=.;
             __indentlev =.;
             __dsid=.;
             __tcol ='';
             __gcols='';
             __first=.;
             __next_indentlev=.;
            end;      ;
     
          keep __datatype __vtype __rowid __col_: __foot: __title: __next_indentlev
              __shead: __sfoot: __nodatamsg __align __suffix __keepn __blockid __cell: 
              __indentlev __dsid __tcol __gcols __first: __varbygrp __varbylab __fname
              __topborderstyle __bottomborderstyle;
        run;
    
  %end;
  
%mend;    
