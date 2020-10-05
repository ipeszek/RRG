/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro rrg_finalizelist(debug=0, savexml=, output_engine=JAVA, replace=)/store;
  
  ** finalizes generating program;
  ** adds printing;
  ** calls generated program;
  
  
%local debug lastcol savexml output_engine  fname colsp varby ;  
%local append appendable tablepart colwidths  stretch print gcols dist2next replace;
 

%local debug savexml savercd gentxt fname ;
  
proc sql noprint;
  select   savercd, gentxt , filename, print            
           into
           :savercd, :gentxt, :fname, :print
         separated by ' '
       from __repinfo;
quit;



%local debugc;
%let debugc=%str(%%*);
%if &debug>0 %then %let debugc=;

%if %upcase(&append)=Y or %upcase(&append)=TRUE %then %let append=Y;
%else %let append=N;
%if %upcase(&appendable)=Y or %upcase(&appendable)=TRUE %then %let appendable=Y;
%else %let appendable=N;





data __rrgfinalize;;
  length record $ 2000;
  keep record;
  record= " "; output;
  record= " ";output;
  record=  "*-------------------------------------------------------------------;";output;
  record=  "* FINAL SORTING OF DATASET IN CASE RRG_CODEAFTER MODIFIED __ROWID;";output;
  record=  "*-------------------------------------------------------------------;";output;
  record= " ";output;
  record=  "proc sort data=&rrguri(where=(__datatype ne 'RINFO')) out=__tmp;";output;
  %if %length(&varby) %then %do;
      record=  "by __varbygrp __datatype __rowid;";output;
  %end;
  %else %do;
      record=  "by __datatype __rowid;";output;
  %end;
  record=  "run;";output;
  record= " ";output;
  record=  "data &rrguri;";output;
  record=  "set &rrguri (where=(__datatype='RINFO')) __tmp;";output;
  record=  "__rowid=_n_-1;";output;
  record=  "run;";output;
  record= " ";output;
  record= " ";output;

%*if &tablepart=FIRST  %then %do;
  /*

    record= " ";output;
    record= " ";output;
    record=  "*-------------------------------------------------------------------;";output;
    record=  "* STORE RCD DATASET FOR FUTURE UPDATES FROM OTHER TABLE PARTS;";output;
    record=  "*-------------------------------------------------------------------;";output;
    record= " ";output;
    record=  "  data &rrguri._tmp;";output;
    record=  "    set &rrguri;";output;
    record=  "  run;";output;
    record= " ";output;
  */

%*end;







/*
%if &tablepart=MIDDLE  %then %do;

  
    record= " ";
    record=  "*-------------------------------------------------------------------;";
    record=  "* APPEND NEXT PART OF RCD TO EXISTING RCD;";
    record=  "*-------------------------------------------------------------------;";
    record= " ";
    record=  "  data &rrguri._tmp;";
    record=  "    set &rrguri._tmp &rrguri (where=(__datatype='TBODY'));";
    record=  "   if __datatype='TBODY' then __rowid=_n_;";
    record=  "  run;";
    record= " ";
 
%end;

%if &tablepart=LAST %then %do;

 
    record= " ";
    record=  "*-------------------------------------------------------------------;";
    record=  "* APPEND LAST PART OF RCD TO EXISTING RCD;";
    record=  "*-------------------------------------------------------------------;";
    record= " ";
    record=  "  data &rrguri;";
    record=  "    set &rrguri._tmp &rrguri (where=(__datatype='TBODY'));";
    record=  "  if __datatype='TBODY' then  __rowid=_n_;";
    record=  "  run;";
    record= " ";
 

%end;

%if &tablepart=LAST  %then %do;
*/
    %local rrgoutpathlazy ;
    %let rrgoutpathlazy=&rrgoutpath;


%if %upcase(&print)=Y %then %do;

    record= " ";                                                                                                       output;
    record=  "*-------------------------------------------------------------------;";                                  output;
    record=  "* GENERATE OUTPUT;";                                                                                     output;
    record=  "*-------------------------------------------------------------------;";                                  output;
    record= " ";                                                                                                       output;
    record=  '%macro rrgout;';                                                                                         output;
    record=  '%local objname;';                                                                                        output;
    record=  "proc sql noprint;";                                                                                      output;
    record=  "select upcase(objname) into:objname from sashelp.vcatalg";                                               output;
    record=  "where libname='RRGMACR' and upcase(objname)='__SASSHIATO';";                                             output;
    record=  "quit;";                                                                                                  output;
    record= " ";                                                                                                       output;
    record= " ";                                                                                                       output;
    record = '%local __path;';                                                                                         output;
    record=  '%if %length(&rrgoutpath)=0 %then';                                                                       output;
    record=  '  %let __path='|| "&rrgoutpathlazy;";                                                                      output;
    record=  '%else %let __path = &rrgoutpath;';                                                                       output;
    %if %symexist(__sasshiato_home) %then %do;                                                                        
          record=  '%if %symexist(__sasshiato_home) %then %do;';                                                       output;
          record=  '  %if &objname=__SASSHIATO  and  %length(&__sasshiato_home) %then %do;';                           output;
          %if %upcase(&savexml)=Y %then %do;                                                                           
              record=  '   %__sasshiato(path=&__path,'|| " debug=&debug, dataset=&rrguri);";                             output;
          %end;                                                                                                       
          %else %do;                                                                                                   
              record=  '   %__sasshiato('|| "debug=&debug,dataset=&rrguri);";                                            output;
          %end;                                                                                                        
          record=  '  %end;';                                                                                          output;
          record=  '%end;';                                                                                            output;
    %end;                                                                                                              
    record= " ";                                                                                                       output;
    record=  '%mend rrgout;';                                                                                          output;
    record= " ";       
    record=  '%rrgout;';                                                                                          output;
    record= " ";                                                                                                       output;                                                                                                output;

%end;
    
/* %end;   */


run;



proc append base=rrgpgm data=__rrgfinalize;
run;


data _null_;
  set __rrgfinalize;
  call execute(cats('%nrstr(',record,')'));
run;


data _null_;
  set rrgheader rrgfmt rrgcodebefore rrgpgm rrgcodeafter rrgfinalize;
 
  file "&rrgpgmpath./&rrguri..sas"  lrecl=1000;
  put record  ;
  
run;


/*

dm "log; clear";

proc datasets memtype=data nolist nowarn;
  delete __rrg:;
run;
quit; 


data __timer;
  set __timer end=eof;
  output;
  if eof then do;
    task = "Finished Generating Program - submitting for execution";
    time=time(); output;
  end;
run;  





/*
data __timer;
  set __timer end=eof;
  format time time8.;
  output;
  if eof then do;
    task = "Finished program";
    time=time(); output;
  end;
  
run;  
*/




%if &savercd=Y  %then %do;
  %*__savercd_m;
%end;

%if %upcase(&gentxt)=Y  %then %do;

    %*__gentxt_m;

%end; 

 
    
%skippr:


data _null_;
  set __timer;
  if _n_=1 then put 'EXECUTION STATISTICS:';
  put @1 time time8. @10 task $100.;
run;




%mend;
