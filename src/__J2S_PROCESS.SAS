/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __j2s_process(varbyval=)/store;

%local varbyval;

  %* determine column headers;
  %* assumes all headers are the same in each varby group;
  %* this will not work for table;
  
  %local hhasdata;
  %let hhasdata=0;
  %* hhasdata=1 if there are some header records;
   

  data __headers;
  %if &varbyval=NONE %then %do;
  set &rrguri ;
  %end;
  %else %do;
  set &rrguri (where=(__varbygrp=&varbyval));
  %end;
  if __datatype='HEAD';
  %if &ispage=1 %then %do;
  keep __rowid __varbygrp __col_:;
  %end;
  %else %do;
  keep __rowid __col_:;
  %end;
  run;
   
  data __headers;
  set __headers;
  if _n_=1 then call symput('hhasdata','1');
  run;
   
/*
  proc print data=__headers;
    title '__headers';
  run;
  title;
    
  run;
*/
  
  data __lpp;
    hl=4;
  run;
  
  
  %if &hhasdata=1 %then %do;
  
    %*---------------------------------------------------------------------; 
    %* process headers - create splits etc;
    %* run fake proc report to determine number of lines for header;
    %* read-in proc report and retrieve number of lines for header;
    %* does not generate code;
    %*---------------------------------------------------------------------; 
    %* limitation: actual data can not have more lines than "duing generation";
    %*---------------------------------------------------------------------; 
    
     %__j2s_ph(ispage=&ispage, numcol=&numcol, fname=&fname, cl =&cl, ls=&ls, ps=&ps, type=table);
     
    %* this  step generated  dataset __colstr with split text of "columns" statement;
    %* the individual parts are in variable tmp1;
    %* it also updated __colinfo storing column widths and labels (cw and clab);
    %* and __lpp dataset with hl (number of header lines);
   
  %end; 
  
     
  %******************************************************************************;
  %** process titles and determine number of lines used by titles  and footnotes ;
  %*  does not generate code;
  %******************************************************************************;
   
  %*********************************************************************************;
   
  
  %__j2s_ptf1(ls=&ls, hhasdata=&hhasdata, ispage=&ispage);
  
  
  %******************************************************************************;
  %** previous step created files __currtflt, __currtflf, __currtflsh,;
  %** __currtflsf (wiht titles, footers, system titles and system footers);
  %** and updated __lpp dataset with lpp and lppnh ;
  %* (lines per page and lines per page excl. header;
  %******************************************************************************;
  %* limitation/todo: vabylab: one line, tcols- one line between splits; 
  %******************************************************************************; 
    
  %if &hhasdata=0 %then %do;
  
    %****************************************************************;
    %* generate report with "no data" mesage only and no footnotes;
    %****************************************************************;
  
    data __currtflf;
      if 0;
    run;
   
    
    data _null_;
    set __report;
    file "&rrgoutpath./&fname..out" ;
    length line $ &ls;
    line = repeat("_", &ls-1);
    put @1 line;
    put;
    put __nodatamsg;
    put @1 line;
    put;
    run;
     
    %goto skip;
  %end;
   
  
  
  
  %*-------------------------------------------------------------------------------------; 
  %* generate code to transform data -- create line splits, calc page breaks etc;
  %*-------------------------------------------------------------------------------------;
  

  data __lpp;
    set __lpp;
    call symput('lpp', strip(put(lpp, best.)));
    call symput('lppnh', strip(put(lppnh, best.)));
  run;
  
  
  
  %__j2s_pdt(numcol=&numcol, cl=&cl, colwidths=&colwidths, lpp=&lpp, isspanrow=&isspanrow, 
      ispage=&ispage, __spanvar=&__spanvar, varbyval=&varbyval); 
  
  %*-------------------------------------------------------------------------------------;
  %* run proc report;
  %*-------------------------------------------------------------------------------------;
  
  %__j2s_rprt(ls=&ls, ps=&ps, ispage=&ispage, isspanrow=&isspanrow, __spanvar=&__spanvar);
 
 
%skip: 
%mend;
