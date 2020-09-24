/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __savercd/store;
 %local rrgoutpathlazy ;
 %let rrgoutpathlazy=&rrgoutpath;
 
 

 data _null_;
  file "&rrgpgmpath./&rrguri.0.sas" mod lrecl=1000;
  put;
  put;
  put '%macro __rrg_savercd;';
  put;
  put '%local __path;';
  put @1 '%if %length(&rrgoutpath)=0 %then';
  put @1 '  %let __path=' "&rrgoutpathlazy;";
  put @1 '%else %let __path = &rrgoutpath;';
  put;
  /*put @1 "libname out '" "%str(&rrgoutpath)" "';";*/
  put @1 'libname out "' '&__path' '";';
  put;
  put;
  put;
  put @1 '*---------------------------------------------------------;';
  put @1 '*  SAVING RCD DATASET;';
  put @1 '*---------------------------------------------------------;';
  put;
  %if %upcase(&append)=N %then %do;
    put @1 "    data out.&rrguri (compress=YES); ";
    put @1 "    length __varbylab $ 2000;";
    put @1 "      set &rrguri;";
    
    put @1 "      retain __col_:  __rowid __datatype __varbygrp __varbylab __vtype ";
    put @1 "        __indentlev  __next_indentlev __align __suffix __keepn __blockid ";
    put @1 "       __dsid __tcol __gcols __first:  __fname __cell: __topborderstyle ";
    put @1 "      __bottomborderstyle __foot: __title: __shead_: __sfoot_: __nodatamsg;";
    
    
    
    put @1 "     if 0 then do;";
    put @1 "        __tcol='';";
    put @1 "        __gcols='';";
    put @1 "        __datatype='';";
    put @1 "        __varbygrp='';";
    put @1 "        __varbylab='';";
    put @1 "        __vtype='';";
    put @1 "        __fname='';";
    put @1 "        __rowid=.;";
    put @1 "        __col_0=''; ";
    %do i=1 %to 14;
        put @1 "        __footnot&i='';";
    %end;
    
    put @1 "        __title1=''; ";
    put @1 "        __title2=''; ";
    put @1 "        __title3=''; ";
    put @1 "        __title4=''; ";
    put @1 "        __title5=''; ";
    put @1 "        __title6=''; ";
    put @1 "        __shead_l='';";
    put @1 "        __shead_m='';";
    put @1 "        __shead_r='';";
    put @1 "        __sfoot_l='';";
    put @1 "        __sfoot_m='';";
    put @1 "        __sfoot_r='';";
    put @1 "        __nodatamsg='';";
    put @1 "        __align='';";
    put @1 "        __suffix='';";
    put @1 "        __keepn=.;";
    put @1 "        __blockid=.;";
    put @1 "        __indentlev =.;";
    put @1 "        __dsid=.;";
    put @1 "        __first=.;";
    put @1 "        __next_indentlev=.;";
    put @1 "      end;";
    put @1 "      __dsid=1;";
    
    
    put @1 "      keep __datatype __vtype __rowid __col_: __foot: __title: __next_indentlev ";
    put @1 "      __shead_: __sfoot_: __nodatamsg __align __suffix __keepn __blockid __cell:";
    put @1 "      __indentlev __dsid __tcol __gcols __first: __varbygrp __varbylab __fname ";
    put @1 "      __topborderstyle __bottomborderstyle;";
    put @1 "    run;";
    put;  
  %end;
    
  %else %do;
    put;
    put;    
    put @1 '    %local dsid;';
    put @1 '    proc sql noprint;';
    put @1 "      select max(__dsid) into:dsid separated by ' ' from out.&rrguri;";
    put @1 '    quit;';
    put;  
    put @1 "      data out.&rrguri (compress=YES);";
    put @1 "       set out.&rrguri(in=__old) &rrguri(in=__new);";
    put @1 '       if __new then __dsid=&dsid+1;';
    
     put @1 "      retain __rowid __col_: __datatype __vtype __indentlev  __next_indentlev";
    put @1 "       __align __suffix __keepn __blockid __varbygrp __varbylab __dsid ";
    put @1 "        __tcol __gcols __first:  __fname __cell:  __topborderstyle __bottomborderstyle";
    put @1 "      __foot: __title: __shead: __sfoot: __nodatamsg ;";
    
    put @1 "       if 0 then do;";
    put @1 "         __datatype='';";
    put @1 "        __varbygrp='';";
    put @1 "        __varbylab='';";
    put @1 "         __vtype='';";
    put @1 "         __fname='';";
    put @1 "         __rowid=.;";
    put @1 "         __col_0=''; ";
    %do i=1 %to 14;
        put @1 "        __footnot&&i='';";
    %end;
   
    put @1 "         __title1=''; ";
    put @1 "         __title2=''; ";
    put @1 "         __title3=''; ";
    put @1 "         __title4=''; ";
    put @1 "         __title5=''; ";
    put @1 "         __title6=''; ";
    put @1 "         __shead_l='';";
    put @1 "         __shead_m='';";
    put @1 "         __shead_r='';";
    put @1 "         __sfoot_l='';";
    put @1 "         __sfoot_m='';";
    put @1 "         __sfoot_r='';";
    put @1 "         __nodatamsg='';";
    put @1 "         __align='';";
    put @1 "         __suffix='';";
    put @1 "         __keepn=.;";
    put @1 "         __blockid=.;";
    put @1 "         __indentlev =.;";
    put @1 "         __dsid=.;";
    put @1 "         __tcol ='';";
    put @1 "         __gcols='';";
    put @1 "         __first=.;";
    put @1 "         __next_indentlev=.;";
    put @1 "        end;      ";
    put;      
    put @1 "      keep __datatype __vtype __rowid __col_: __foot: __title: __next_indentlev";
    put @1 "      __shead: __sfoot: __nodatamsg __align __suffix __keepn __blockid __cell: ";
    put @1 "      __indentlev __dsid __tcol __gcols __first: __varbygrp __varbylab __fname";
    put @1 "      __topborderstyle __bottomborderstyle;";
    put @1 "    run;";
    put;  
  %end;
  put;

  put;
  put @1 '%mend;';
  put ;
  put @1 '%__rrg_savercd;';
  put;
  
run;
  
%mend;    
