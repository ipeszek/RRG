/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro rrg_finalize(debug=0, savexml=, output_engine=JAVA, replace=)/store;
  
  ** finalizes generating program;
  ** adds printing;
  ** calls generated program;
  
  
%local debug  savexml output_engine  varby ;  
%local  tablepart  replace;
 

%local debug savexml    ;

%local rrgoutpathlazy ;
%let rrgoutpathlazy=&rrgoutpath;

%if &rrg_debug>0 %then %do; 
data __timer;
  set __timer end=eof;
	length task $ 100;
	output;
		if eof then do; 
		  task = "RRG FINILIZE (OUTPUT GENERATION) STARTED";
		  dt=datetime(); 
		  output;
		end;
run;

%end;
  
proc sql noprint;
  
  %if %sysfunc(exist(__varinfo)) %then %do;
    select name into:varby separated by ' ' from __varinfo(where=( upcase(page)='Y'));
  %end;
  
quit;


%local i;

%local debugc;
%let debugc=%str(%%*);
%if &debug>0 %then %let debugc=;

data rrgfinalize;;
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
  record=  "data &rrguri rrgtablepart&rrgtablepartnum;";output;
  record=  "set &rrguri (where=(__datatype='RINFO')) __tmp;";output;
  record=  "__rowid=_n_-1;";output;
  RECORD= "__dsid=&rrgtablepartnum;"; output;
  record=  "run;";output;
  record= " ";output;
  record= " ";output;

                                      

%* CREATE RTF AND/OR PDF OUTPUT;

%if %upcase(&defreport_print)=Y  %then %do;
  

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
    record=  '  %let __path='|| "&rrgoutpathlazy;";                                                                    output;
    record=  '%else %let __path = &rrgoutpath;';                                                                       output;
    %if %symexist(__sasshiato_home) %then %do;                                                                        
          record=  '%if %symexist(__sasshiato_home) %then %do;';                                                       output;
          record=  '  %if &objname=__SASSHIATO  and  %length(&__sasshiato_home) %then %do;';                           output;
          %do i=1 %to &rrgtablepartnum;
              %if %upcase(&savexml)=Y %then %do;                                                                           
                  record=  '   %__sasshiato(path=&__path,'|| " debug=&debug, dataset=rrgtablepart&i);";                output;
                  record=" ";                                                                                          output;
                  record = 'filename rrgf "&__path./rrgtablepart'||"&i."||'.xml";';                                    output;
                  record=" ";                                                                                          output;

                  record=  ' data _null_;'   ;                                                                         output;
                  record=  ' 	if fexist("rrgf") then do;'   ;                                                          output;
                  %if &i>1 %then %do;
                  record=  ' 		rc = rename("&__path./rrgtablepart'||"&i."||'.xml", "&__path./&rrguri._part'||
                    "&i."||'.xml","file");';                                                                           output;
                  %end;
                  %else %do;
                  record=  ' 		rc = rename("&__path./rrgtablepart'||"&i."||'.xml", "&__path./&rrguri..xml","file");'; output;                 	
                  %end;	
                  record=  ' 	end;' ;                                                                                  output;
                  record=  ' run; ' ;                                                                                  output;    
                  record=" ";                                                                                          output;             
 
                  record = 'filename rrgf ;';                                                                          output;
                  record=" ";                                                                                          output;             
              %end;                                                                                                       
              %else %do;                                                                                                   
                  record=  '   %__sasshiato('|| "debug=&debug,dataset=rrgtablepart&i);";                               output;
                  

              %end;                                                                       
          %end;                                 
          record=  '  %end;';                                                                                          output;
          record=  '%end;';                                                                                            output;
    %end;                                                                                                              
    record= " ";                                                                                                       output;
    record=  '%mend rrgout;';                                                                                          output;
    record= " ";                                                                                                       output;
    record=  '%rrgout;';                                                                                               output;
    record= " ";                                                                                                       output;    
%end;
    

run;

%if &rrgfinalize_done=0 %then %do;

%if &rrg_debug>0 %then %do;
data __timer;
  set __timer end=eof;
	length task $ 100;
	output;
		if eof then do; 
		  task = "GENERATING PDF AND/OR RTF OUTPUT STARTED";
		  dt=datetime(); 
		  output;
		end;
run;
%end;
  data _null_;
    set rrgfinalize;
    call execute(cats('%nrstr(',record,')'));
    
   %if &rrg_debug>0 %then %do; 
  data __timer;
  set __timer end=eof;
	length task $ 100;
	output;
		if eof then do; 
		  task = "RRG FINALIZE finished";
		  dt=datetime(); 
		  output;
		end;
run;
%end;

%end;

%*-------------------------------------------------;
%* CREATE GENERATED PROGRAM;
%*-------------------------------------------------;
%if &rrg_debug>0 %then %do;
data __timer;
  set __timer end=eof;
	length task $ 100;
	output;
		if eof then do; 
		  task = "WRITING GENERATED PROGRAM TO DISK STARTED";
		  dt=datetime(); 
		  output;
		end;
run;
%end;
%if &rrgtablepart = FIRSTANDLAST  %then %do;

    data _null_;
      set %if %sysfunc(exist(rrgheader)) %then %do; rrgheader %end;
          %if %sysfunc(exist(rrgfmt)) %then %do; rrgfmt %end;
          %if %sysfunc(exist(rrginc)) %then %do; rrginc %end;
          %if %sysfunc(exist(rrgjoinds)) %then %do; rrgjoinds %end;

          %if %sysfunc(exist(rrgcodebefore)) %then %do; rrgcodebefore %end;
          rrgpgm 
          %if %sysfunc(exist(rrgcodeafter)) %then %do; rrgcodeafter %end;
          rrgfinalize;
      file "&rrgpgmpath./&rrguri..sas"  lrecl=1000;
      put record  ;
      
    run;
    
%end;

%else %if &rrgtablepart = FIRST  %then %do;

    data rrgpgm0;
        set %if %sysfunc(exist(rrgheader)) %then %do; rrgheader %end;
          %if %sysfunc(exist(rrgfmt)) %then %do; rrgfmt %end;
          %if %sysfunc(exist(rrginc)) %then %do; rrginc %end;
          %if %sysfunc(exist(rrgjoinds)) %then %do; rrgjoinds %end;

          

          %if %sysfunc(exist(rrgcodebefore)) %then %do; rrgcodebefore %end;
          rrgpgm 
          %if %sysfunc(exist(rrgcodeafter)) %then %do; rrgcodeafter %end;
          rrgfinalize;
    run;
    
%end;

%else %if &rrgtablepart = MIDDLE  %then %do;

    data rrgpgm0;
      set rrgpgm0 
       %if %sysfunc(exist(rrgfmt)) %then %do; rrgfmt %end;
       rrgpgm 
       %if %sysfunc(exist(rrgcodeafter)) %then %do; rrgcodeafter %end; 
      rrgfinalize;
    run;
    
%end;

%else %if &rrgtablepart = LAST  %then %do;

    data _null_;
      set rrgpgm0 
         %if %sysfunc(exist(rrgfmt)) %then %do; rrgfmt %end;
      rrgpgm 
       %if %sysfunc(exist(rrgcodeafter)) %then %do; rrgcodeafter %end; 
      rrgfinalize;
     
      file "&rrgpgmpath./&rrguri..sas"  lrecl=1000;
      put record  ;
      
    run;
    
%end;    




%if &rrg_debug>0 %then %do;
data __timer;
  set __timer end=eof;
  output;
  if eof then do;
    task = "WRITING GENERATED PROGRAM TO DISK FINISHED";
    time=time(); output;
  end;
run;  
%end;






%if &defreport_savercd=Y  %then %do;
  %if &rrg_debug>0 %then %do;
  data __timer;
  set __timer end=eof;
	length task $ 100;
	output;
		if eof then do; 
		  task = "SAVERCD STARTED";
		  dt=datetime(); 
		  output;
		end;
run;
%end;

  %__savercd_m;
  %if &rrg_debug>0 %then %do;
  data __timer;
  set __timer end=eof;
	length task $ 100;
	output;
		if eof then do; 
		  task = "SAVERCD FINISHED";
		  dt=datetime(); 
		  output;
		end;
run;
%end;
%end;






LIBNAME rrgOUT "&RRGPGMPATH";

%if &rrg_debug>0 %then %do;
data __timer;
  set __timer END=EOF ;
  length pgmname $ 50;
  pgmname="&rrguri";
  PDT=LAG(DT);
  RETAIN START;
  IF _N_=1 THEN START=DT;
  
  IF _N_>1 THEN ELAPSED=(DT-PDT);
  PUT "TASK= " TASK   @65 DT DATETIME19. @87 "ELAPSED:   "  ELAPSED 8.1 "   SECONDS";
  output;
  IF EOF THEN DO;
    TOTALtm=DT-START;
    TASK="TOTAL EXECUTION TIME";
    PUT "TOTAL TIME: "  TOTALtm " SECONDS";
    output;
  END;
run;

proc append data=__timer base=rrgout.__execution;
run;
%end;

/*  */
/* %if &rrgsasfopen=1 %then %do; */
/* 	sasfile work.rrgpgm close; */
/* 	%LET rrgsasfopen=0; */
/* %end; */

%if  &rrg_debug=0  AND ( &rrgtablepart=LAST or &rrgtablepart=FIRSTANDLAST) %then %do;
  
    proc datasets memtype=data nolist nowarn;
      delete rrg: __:;
    run;
    quit; 

%end; 

    
%mend;
