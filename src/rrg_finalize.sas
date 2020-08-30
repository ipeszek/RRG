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
  
  
%local debug lastcol savexml output_engine java2sas fname colsp varby metadatads;  
%local append appendable tablepart colwidths  stretch print gcols dist2next replace;
 

data _null_;
  file "&rrgpgmpath./&rrguri.0.sas"  mod lrecl=1000;
  put;
run; 
  
proc sql noprint;
  select append into:append separated by ' ' from __repinfo;
  select tablepart into:tablepart separated by ' ' from __repinfo;
  select indentsize into:indentsize separated by ' ' from __repinfo;
  select appendable into:appendable separated by ' ' from __repinfo;
  select upcase(java2sas) into:java2sas separated by ' '  from __repinfo;
  select filename into:fname separated by ' ' from __report;
  select colwidths into:colwidths separated by ' ' from __repinfo;
  select colspacing into:colsp separated by ' ' from __repinfo;
  select stretch into:stretch separated by ' ' from __repinfo;
  select print into:print separated by ' ' from __repinfo;
  %if %sysfunc(exist(__varinfo)) %then %do;
      select name into:varby separated by ' ' from __varinfo(where=( upcase(page)='Y'));
  %end;
  select METADATADS into:METADATADS separated by ' ' from __repinfo;
quit;


%local useddatasets popwhere tabwhere usedvars tt1 tt2 tt3 tt4 tt5 tt6 i subjid 
       where popwhere2 denomwhere totalwhere n_analvar macrosused macrosused2 macrosinc1 macrosinc2 ;
  

%if %length(&metadatads) %then %do;

     proc sql noprint;
        select tabwhere into:tabwhere separated by '; '  from __repinfo (where =(tabwhere ne ''));
        select popwhere into:popwhere separated by '; '  from __repinfo (where =(popwhere ne ''));
        %if %sysfunc(exist(__varinfo)) %then %do;
            select popwhere into:popwhere2 separated by '; '  from __varinfo (where =(popwhere ne ''));
            select totalwhere into:totalwhere separated by '; '  from __varinfo (where =(totalwhere ne ''));
            select denomwhere into:denomwhere separated by '; '  from __varinfo (where =(denomwhere ne ''));
            select where into:where separated by '; '  from __varinfo (where =(where ne ''));
        %end;
        %do i=1 %to 6;
            select strip(title&i) into:tt&i separated by ' ' from __repinfo;
        %end;
        select strip(subjid) into:subjid separated by ' ' from __repinfo;
        
        %if %sysfunc(exist(__varinfo)) %then %do;
            select count(*) into:n_analvar separated by ' ' from __varinfo (
                   where=(upcase(type)='CAT' or upcase(type)='CONT' or upcase(type)='COND'));  
            select strip(name)||' with parameters: '||strip(parms) into:macrosused separated by '; '
              from __varinfo (where =(type='MODEL' and parms ne ''));
            select strip(parms) into:macrosused2 separated by '; '
              from __varinfo (where =(type='MODEL' and parms ne ''));
        %end;
        select strip(value) into:macrosinc1 separated by '; '
          from __rrgpgminfo (where =(key='rrg_inc'));
        select strip(value) into:macrosinc2 separated by '; '
          from __rrgpgminfo (where =(key='rrg_call_macro'));

        quit;  

       libname __mout "&rrgoutpath";
       
       *--- add dataset to __usedds;
       
      
       data __rrginlibs;
        length dataset  $ 2000;
        set __rrginlibs;
       run;
       
       data __usedds;
        set __usedds __repinfo (keep = dataset rename=(dataset=ds)) __rrginlibs(rename=(dataset=ds));
       run;
       
       *--- keep only "permanent datasets" in __usedds;
       
       data  __usedds;
        set __usedds;
        if index(ds, '.')>0;
       run;   
      
       proc sql noprint;
          select distinct scan(ds,1,'(') into:useddatasets separated by '; '  from __usedds;
       quit;

%end;     

%local debugc;
%let debugc=%str(%%*);
%if &debug>0 %then %let debugc=;

%if %upcase(&append)=Y or %upcase(&append)=TRUE %then %let append=Y;
  %else %let append=N;
%if %upcase(&appendable)=Y or %upcase(&appendable)=TRUE %then %let appendable=Y;
  %else %let appendable=N;

data _null_;
  file "&rrgpgmpath/&rrguri..sas" mod;
  put;
  put;
  put @1 "*-------------------------------------------------------------------;";
  put @1 "* FINAL SORTING OF DATASET IN CASE RRG_CODEAFTER MODIFIED __ROWID;";
  put @1 "*-------------------------------------------------------------------;";
  PUT;
  put @1 "proc sort data=&rrguri(where=(__datatype ne 'RINFO')) out=__tmp;";
  %if %length(&varby) %then %do;
    put @1 "by __varbygrp __datatype __rowid;";
  %end;
  %else %do;
    put @1 "by __datatype __rowid;";
  %end;
  put @1 "run;";
  put;
  put @1 "data &rrguri;";
  put @1 "set &rrguri (where=(__datatype='RINFO')) __tmp;";
  put @1 "__rowid=_n_-1;";
  put @1 "run;";
  put;
  put;
run;


%if &tablepart=FIRST  %then %do;

  data _null_;
  file "&rrgpgmpath/&rrguri..sas" mod;
  put;
  put;
  put @1 "*-------------------------------------------------------------------;";
  put @1 "* STORE RCD DATASET FOR FUTURE UPDATES FROM OTHER TABLE PARTS;";
  put @1 "*-------------------------------------------------------------------;";
  put;
  put @1 "  data &rrguri._tmp;";
  put @1 "    set &rrguri;";
  put @1 "  run;";
  put;
  run;

  %goto skippr;

%end;

%if &tablepart=MIDDLE  %then %do;

  data _null_;
  file "&rrgpgmpath/&rrguri..sas" mod;
  put;
  put @1 "*-------------------------------------------------------------------;";
  put @1 "* APPEND NEXT PART OF RCD TO EXISTING RCD;";
  put @1 "*-------------------------------------------------------------------;";
  put;
  put @1 "  data &rrguri._tmp;";
  put @1 "    set &rrguri._tmp &rrguri (where=(__datatype='TBODY'));";
  put @1 "   if __datatype='TBODY' then __rowid=_n_;";
  put @1 "  run;";
  put;
  run;

  %goto skippr;

%end;

%if &tablepart=LAST %then %do;

  data _null_;
  file "&rrgpgmpath/&rrguri..sas" mod;
  put;
  put @1 "*-------------------------------------------------------------------;";
  put @1 "* APPEND LAST PART OF RCD TO EXISTING RCD;";
  put @1 "*-------------------------------------------------------------------;";
  put;
  put @1 "  data &rrguri;";
  put @1 "    set &rrguri._tmp &rrguri (where=(__datatype='TBODY'));";
  put @1 "  if __datatype='TBODY' then  __rowid=_n_;";
  put @1 "  run;";
  put;
  run;

%end;


%local rrgoutpathlazy ;
%let rrgoutpathlazy=&rrgoutpath;


%if %upcase(&print)=Y %then %do;


  data _null_;
  file "&rrgpgmpath/&rrguri..sas" mod;
  put;
  put @1 "*-------------------------------------------------------------------;";
  put @1 "* GENERATE OUTPUT;";
  put @1 "*-------------------------------------------------------------------;";
  put;
  put @1 '%macro rrgout;';
  %if %upcase(&output_engine)=SAS %then %do;
      put @1 '%local objname;';
      put @1 "proc sql noprint;";
      put @1 "select upcase(objname) into:objname from sashelp.vcatalg";
      put @1 "where libname='RRGMACR' and upcase(objname)='RRG_PRINT';";
      put @1 "quit;";
      put;
      put @1 '%if &objname=RRG_PRINT  %then %do;';
      put @1 '  %rrg_print(dataset=' "&rrguri, ";
      put @1 "    debug=&debug, ";
      put @1 "   filename=&rrguri);";
      put @1 '%end;';
      put @1 '%else %do;';
      put @1 "  proc print data=&rrguri;";
      put @1 "    var __col_:;";
      put @1 "  run;";
      put @1 '%end;';
  %end;
  %if %upcase(&output_engine)=JAVA %then %do;
    put @1 '%local objname;';
    put @1 "proc sql noprint;";
    put @1 "select upcase(objname) into:objname from sashelp.vcatalg";
    put @1 "where libname='RRGMACR' and upcase(objname)='__SASSHIATO';";
    put @1 "quit;";
    put;
    put;
    put '%local __path;';
    put @1 '%if %length(&rrgoutpath)=0 %then';
    put @1 '  %let __path=' "&rrgoutpathlazy;";
    put @1 '%else %let __path = &rrgoutpath;';
 
    %if %symexist(__sasshiato_home) %then %do;
        put @1 '%if %symexist(__sasshiato_home) %then %do;';
        put @1 '  %if &objname=__SASSHIATO  and  %length(&__sasshiato_home) %then %do;';
        %if %upcase(&savexml)=Y %then %do;
          put @1 '   %__sasshiato(path=&__path,' " debug=&debug, dataset=&rrguri);";
        %end; 
        %else %do;
          put @1 '   %__sasshiato(' "debug=&debug,dataset=&rrguri);";
        %end;
        put @1 '  %end;';
        put @1 '%end;';
    %end;
  %end;
  put;
  put;

  put;
  put @1 '%mend rrgout;';
  put;
  put @1 '%rrgout;';
  run;
%end;




%local savercd gentxt;
proc sql noprint;
  select savercd into:savercd separated by ' ' from __repinfo;
  select gentxt into:gentxt separated by ' ' from __repinfo;
quit;

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


%inc "&rrgpgmpath./&rrguri..sas";



data __timer;
  set __timer end=eof;
  format time time8.;
  output;
  if eof then do;
    task = "Finished program";
    time=time(); output;
  end;
  
run;  


%local modstr;
  
%if %upcase(&append)=Y %then %do;
    %let modstr=MOD;
%end;
 

%if &savercd=Y  %then %do;
  %__savercd;
%end;

%if %upcase(&gentxt)=Y  %then %do;

  %__gentxt;


  data _null_;
  file "&rrgpgmpath./&rrguri.0.sas"  mod lrecl=1000;
  put;
  put @1 "*-------------------------------------------------;";
  put @1 "*  CLEANUP;";
  put @1 "*-------------------------------------------------;";
  put;
  put @1 '%macro __clean;';
  put;
  put @1 '%local __path;';
  put @1 '%if %length(&rrgoutpath)=0 %then';
  put @1 '  %let __path=' "&rrgoutpathlazy;";
  put @1 '%else %let __path = &rrgoutpath;';
  put;
  put @1 "data _null_;";
  put @1 "fname='tempfile';";
  put @1 'rc=filename(fname,"' '&__path./' "&rrguri.0.txt" '");';
  put @1 "if rc = 0 and fexist(fname) then rc=fdelete(fname);";
  put @1 "rc=filename(fname);";
  put @1 "run;";
  put;
  put @1 '%mend;';
  put;
  put @1 '%__clean;';
  put;
  run;
 
%end;  

%if  %upcase(&print)=Y  %then %do;
    %inc "&rrgpgmpath./&rrguri.0.sas";

    data _null_;
      infile "&rrgpgmpath./&rrguri.0.sas" length=len lrecl=1000;
      file "&rrgpgmpath./&rrguri..sas" mod lrecl=1000;
      length record $ 5000;
      input record $varying2000. len;
      put record $varying2000. len;
    run;

%end;


%if %upcase(&print) ne Y %then %do;
    %put skipping;
    %goto skippr;
%end;
  

%if %upcase(&java2sas)=Y  %then %do;

    data _null_;
      file "&rrgpgmpath./&rrguri.0.sas";
    run;

    %if &append ne Y %then %do;
        %__def_list_macros;
    %end;
    
   
    %local ps ls;
    %let ls = 119;
    %let ps = 44;
    
     
    %* determine margins and page size from sasshiato;
    %* determine and process column string;
    %local colstr cl totusedw clearh cntcs;
  
  
    %local rtfstr;
    data _null_;
      infile "&rrgoutpath./&fname._j_info3.txt" length=len lrecl=5000;
      length record $ 5000;
      input record $varying2000. len;
      call symput('rtfstr', scan(record,4,' '));
      call symput('ps', scan(record,3,' '));
      call symput('ls', scan(record,2,' '));
    run; 
    
    %let ps = %eval(&ps+1);
  
    %*---------------------------------------------------------------------------;
            %* calculate widths of columns based on the data available during generation;
    %*---------------------------------------------------------------------------;
    %local dist2next numcol;

    data _null_;
      infile "&rrgoutpath./&fname._j_info.txt" length=len lrecl=5000;
      length record $ 5000 ;
      input record $varying2000. len;
      record = compbl(record);
      __tmp = substr(scan(record,1,' ,'),2);
      call symput('numcol', strip(__tmp));
    run;
            
    data _null_;
      length dist2next colwidths $ 2000;    
      numcol = &numcol;
      dist2next=upcase(compbl(symget("colsp")));
      dist2next=tranwrd(dist2next,'CH','');
      if dist2next='' then do;
        do i=0 to numcol;
          dist2next = strip(dist2next)||' D';
        end;
      end;
      numind = countw(dist2next,' ');
      if numind < numcol+1 then do;
        dist2next = strip(dist2next)||repeat(' '||scan(dist2next,-1,' '), numcol-numind);
      end;

    
      colwidths=upcase(strip(symget("colwidths")));
      if colwidths='' then do;
        colwidths='LWH';
        do i=1 to numcol;
          colwidths = strip(colwidths)||' NH';
        end;
        call symput ('colwidths', strip(colwidths));
      end;
    
      call symput ('dist2next', strip(dist2next));
  
    run;

  
    %local tmp tmpcw0 tmpcw tmp1;
    %do i=0 %to &numcol;
      %if %scan(&dist2next,%eval(&i+1), %str( ))=D %then %let tmp = &tmp 1;
      %else %do;
        %let tmp1 = %upcase(%scan(&dist2next,%eval(&i+1), %str( )));
        %let tmp = &tmp &tmp1;
      %end;
      
      %let tmpcw0 = %upcase( %scan(&colwidths,%eval(&i+1), %str( )));
      %if %length(&tmpcw0)=0 %then %let tmpcw=&tmpcw LWH;
      %else %do;
        %if %index(&tmpcw0,'CH')>0 %then %let tmpcw = &tmpcw %sysfunc(tranwrd(&tmpcw0, CH, %str()));
        %else %do;
          %if (&tmpcw0 ne LWH)  and (&tmpcw0 ne LW) and (&tmpcw0 ne NH) and (&tmpcw0 ne N) %then %do;
            %put specified width value &tmpcw0 is not supported and was changed to LWH.;
            %put supported values are N NH LW LWH or XXch where XX is integer (meaning xx characters);
            %let tmpcw0=LWH;
          %end;
          %let tmpcw=&tmpcw &tmpcw0;
        %end;
      
      %end;
    %end;
  
    %let dist2next=&tmp;
    %let colwidths = &tmpcw;
  
    %local lasthrid;
    proc sql noprint;
      select max(__rowid) into:lasthrid separated by ' '
        from &rrguri (where=(__datatype='HEAD'));
    quit;
    
    
    
    %__calc_col_wt;
  
  
    %local nofit er ror;
    %let er=ER;
    %let ror=ROR;
  
    proc sql noprint;
      select __err into:nofit separated by ' ' from __maxes;
    quit;
    
    %if &nofit=1 %then %do;
     %put &er.&ror.: Table can not fit on one page with the specified widths. Program aborted.;
     %goto skippr;
    %end;  
    
    data __maxes;
      set __maxes;
      call symput('cl', strip(__cl));
      put 'The column widths are ' __cl;
    run;
     
  
    %*-----------------------------------------------------------------------------; 
    %* create dataset __colinfo which stores alignments and spacing for each column;
    %* and indicator whether this is "first only" column;
    %*-----------------------------------------------------------------------------;
    
     proc sql noprint;
      select __gcols into:gcols separated by ' ' from &rrguri(where=(__datatype='RINFO'));
     quit;
     
     data __colinfo;
        length nal $ 20;  
      
        %* &gcol is column number of columns that are "grouping" columns; 
     
        %do i=0 %to &numcol;
          colnum=&i;
          focol=0;
          nal='left flow';
          ** first only column;

          %if &i>0 %then %do; sp = %scan(&dist2next, &i, %str( )); %end;
          %if %length(&gcols) %then %do;
            if colnum in (&gcols) then focol=1;
          %end; 
          output;
        %end; 
     run; 
  
     %*********************************************************************************;
     %local __fospanvar __spanvar dsid varnum rc isspanrow;
     %let isspanrow=0;
     %let dsid = %sysfunc(open(&rrguri));
     %let varnum = %sysfunc(varnum(&dsid, __tcol));
     %if &varnum>0 %then %let isspanrow=1;
      %let rc = %sysfunc(close(&dsid)); 
      
      %if &isspanrow=1 %then %do;
        %let __fospanvar=__fospanvar __tcol;
        %let __spanvar=__spanvar __tcol;
      %end;
       
      %local ispage;
      %let ispage=0;
      proc sql noprint;
        select count(*) into:ispage separated by ' '
        from __varinfo (where=(upcase(type)='GROUP' and upcase(page)='Y'));
      quit;
      %if &ispage>0 %then %let ispage=1;     
      %local lpp lppnh;

      %*-------------------------------------------------------------------------------------;
      %* process titles and footnotes;
      %*-------------------------------------------------------------------------------------;

      data __repinfo;
        set __report; 
      run;
      
      %__j2s_ptf0(ls=&ls,  ispage=&ispage);

      data null;
        file "&rrgpgmpath./&rrguri.0.sas"  mod lrecl=5000;
        put;
        put @1 '%macro __pp;';
        put;
        put @1 '%local __path;';
        put @1 '%if %length(&rrgoutpath)=0 %then';
        put @1 '  %let __path=' "&rrgoutpathlazy;";
        put @1 '%else %let __path = &rrgoutpath;';  
        put @1 'proc printto print = "' '&__path./' "&fname..out" '" new;';
        put;
        put @1 '%mend;';
        put @1 '%__pp;';
        put;
      run;
      

      %local maxvb;
      %let maxvb=0;
      %if &ispage=0 %then %do;

          %*-------------------------------------------------------------------------------------;
          %* calculate what is needed and run proc report ;
          %*-------------------------------------------------------------------------------------;
        
          %__j2s_process(varbyval=NONE);
        
      %end;
  
      %else %do;
  
         proc sql noprint;
          select max(__varbygrp) into: maxvb separated by ' ' from &rrguri;
         quit;
         
         %if &maxvb=. %then %let maxvb=0;
         %local varbycnt;
         %do varbycnt=1 %to &maxvb;
      
            %*-------------------------------------------------------------------------------------;
            %* calculate what is needed and run proc report for each __varbygrp;
            %*-------------------------------------------------------------------------------------;
          
            %__j2s_process(varbyval=&varbycnt);
     
         %end;
  
      %end;
  
  
   
      %*-------------------------------------------------------------------------------------;
      %* infile proc report;
      %*-------------------------------------------------------------------------------------;
       
      %readrtf:
      
      %*-------------------------------------------------------------------------------------;
      %* append to &rrguri.0.sas statements to infile proc report and add titles and foots;
      %*-------------------------------------------------------------------------------------;
      
      %local appendm;
      %if %upcase(&append) ne Y %then %let append=N;
      %if %upcase(&append) = Y %then %do;
        %let appendm=mod;
      %end;

      
      %__j2s_ipr(lppnh=&lppnh, ls=&ls, appendable=&appendable, append=&append, replace=%nrbquote(&replace));
   
      %if  %upcase(&appendable) ne Y %then %do; 
      
        %*-------------------------------------------------------------------------;
        %*** append to &rrguri.0.sas statements to create final RTF file;
        %*-------------------------------------------------------------------------;
        
        %__j2s_cr_rtf(ls=&ls);
  
      %end;
  


      %*-------------------------------------------------------------------------;
      %* delete created helper files ;
      %*-------------------------------------------------------------------------;
      
      
      data _null_;
        file "&rrgpgmpath./&rrguri.0.sas"  mod lrecl=1000;
        put;
        %if %upcase(&appendable) ne Y %then %do;
            put @1 '%macro __clean2;';
            put;
            put @1 '%local __path;';
            put @1 '%if %length(&rrgoutpath)=0 %then';
            put @1 '  %let __path=' "&rrgoutpathlazy;";
            put @1 '%else %let __path = &rrgoutpath;';
            put;
            put @1 "*-------------------------------------------------;";
            put @1 "*  CLEANUP;";
            put @1 "*-------------------------------------------------;";
            put;
            put @1 "data _null_;";
            put @1 "fname='tempfile';";
            put @1 'rc=filename(fname,"' '&__path./' "&fname..out0" '");';
            put @1 "if rc = 0 and fexist(fname) then rc=fdelete(fname);";
            put @1 "rc=filename(fname);";
            put @1 'rc=filename(fname,"' '&__path./' "&fname..out" '");';
            put @1 "if rc = 0 and fexist(fname) then rc=fdelete(fname);";
            put @1 "rc=filename(fname);";
            put @1 "run;";
            put;
            put @1 '%mend;';
            put;
            put @1 '%__clean2;';
            put;
        %end;
      run;

   
      data _null_;
          infile "&rrgpgmpath./&rrguri.0.sas" length=len lrecl=1000;
          file "&rrgpgmpath./&rrguri..sas" mod lrecl=1000;
          length record $ 5000;
          input record $varying2000. len;
          put record $varying2000. len;
      run;

  

      %* submit remaining portion;
      %if  %upcase(&print)=Y  %then %do;
        %inc "&rrgpgmpath./&rrguri.0.sas";
      %end;
     
  

%end;  

%skippr:

%put RRG INFO: fname=&fname rrguri=&rrguri;
  
data _null_;
fname="tempfile";
** log file;
rc=filename(fname,"&rrgpgmpath./&rrguri.0.sas");
if rc = 0 and fexist(fname) then
rc=fdelete(fname);
rc=filename(fname);
 

%if &debug<99 %then %do;
    rc=filename(fname,"&rrgoutpath./&fname..dummy");
    if rc = 0 and fexist(fname) then
    rc=fdelete(fname);
    rc=filename(fname);
    
    rc=filename(fname,"&rrgoutpath./&fname._j_info2.txt");
    if rc = 0 and fexist(fname) then
    rc=fdelete(fname);
    rc=filename(fname);
    rc=filename(fname,"&rrgoutpath./&fname._j_info.txt");
    if rc = 0 and fexist(fname) then
    rc=fdelete(fname);
    rc=filename(fname);
    rc=filename(fname,"&rrgoutpath./&fname._j_info3.txt");
    if rc = 0 and fexist(fname) then
    rc=fdelete(fname);
    rc=filename(fname);
    rc=filename(fname,"&rrgoutpath./&rrguri..xml");
    if rc = 0 and fexist(fname) then
    rc=fdelete(fname);
    rc=filename(fname);
    rc=filename(fname,"&rrgoutpath./&rrguri.0.txt");
    if rc = 0 and fexist(fname) then
    rc=fdelete(fname);
    rc=filename(fname);      
    rc=filename(fname,"&rrgoutpath./&fname..out");
    if rc = 0 and fexist(fname) then
    rc=fdelete(fname);
    rc=filename(fname);
    rc=filename(fname,"&rrgoutpath./&fname..out0");
    if rc = 0 and fexist(fname) then
    rc=fdelete(fname);
    rc=filename(fname);
    
%end; 
 
run;

  
data _null_;
  set __timer;
  if _n_=1 then put 'EXECUTION STATISTICS:';
  put @1 time time8. @10 task $100.;
run;

*---- IF REQUESTED, STORE METADATA INFORMATION ----------------;


%if %length(&metadatads) %then %do;
  
  
   *--- check which variables exist in permanent datasets;
   
   *------ create dataset with list of used variables;
   
   data __vars;
    length name $ 32;
    set __varinfo end=eof;
    name= upcase(name);
    if name ne '' then output;
    name=upcase(decode);
    if name ne '' then output;
    if eof then do;
      name = upcase(symget("subjid"));
      output;
    end;  
    keep name;
   run;

   data __vars3;
    set __usedds;
    length tmp $ 2000 name $ 32;
    tmp  = scan(ds,2,'(');
      do i=1 to length(tmp);
      tmp2 = scan(tmp,i, "!@#$%^&*()+[{-=}]|\:;<,>.?/ ");
      if index(tmp2, '"') ne 1 and index(tmp2, "'") ne 1 then do;
        name = upcase(strip(tmp2));
        if name ne '' then output;
      end;
    end; 
    keep name;
   run;

   data __vars2;
    length tmp tmp2 name $ 32 ;
    keep name;
    tmp = strip(symget("popwhere"));
    do i=1 to length(tmp);
      tmp2 = scan(tmp,i, "!@#$%^&*()+[{-=}]|\:;<,>.?/ ");
      if index(tmp2, '"') ne 1 and index(tmp2, "'") ne 1 then do;
        name = upcase(strip(tmp2));
        if name ne '' then output;
      end;
    end; 
    tmp = strip(symget("popwhere2"));
    do i=1 to length(tmp);
      tmp2 = scan(tmp,i, "!@#$%^&*()+[{-=}]|\:;<,>.?/ ");
      if index(tmp2, '"') ne 1 and index(tmp2, "'") ne 1 then do;
        name = upcase(strip(tmp2));
        if name ne '' then output;
      end;
    end; 
    tmp = strip(symget("tabwhere"));
    do i=1 to length(tmp);
      tmp2 = scan(tmp,i, "!@#$%^&*()+[{-=}]|\:;<,>.?/ ");
      if index(tmp2, '"') ne 1 and index(tmp2, "'") ne 1 then do;
        name = upcase(strip(tmp2));
        if name ne '' then output;
      end;
    end; 
    tmp = strip(symget("denomwhere"));
    do i=1 to length(tmp);
      tmp2 = scan(tmp,i, "!@#$%^&*()+[{-=}]|\:;<,>.?/ ");
      if index(tmp2, '"') ne 1 and index(tmp2, "'") ne 1 then do;
        name = upcase(strip(tmp2));
        if name ne '' then output;
      end;
    end;     
    tmp = strip(symget("totalwhere"));
    do i=1 to length(tmp);
      tmp2 = scan(tmp,i, "!@#$%^&*()+[{-=}]|\:;<,>.?/ ");
      if index(tmp2, '"') ne 1 and index(tmp2, "'") ne 1 then do;
        name = upcase(strip(tmp2));
        if name ne '' then output;
      end;
    end;     

    tmp = strip(symget("where"));
    do i=1 to length(tmp);
      tmp2 = scan(tmp,i, "!@#$%^&*()+[{-=}]|\:;<,>.?/ ");
      if index(tmp2, '"') ne 1 and index(tmp2, "'") ne 1 then do;
        name = upcase(strip(tmp2));
        if name ne '' then output;
      end;
    end;  
    tmp = strip(symget("macrosused2"));
    do i=1 to length(tmp);
      tmp2 = scan(tmp,i, "!@#$%^&*()+[{-=}]|\:;<,>.?/ ");
      if index(tmp2, '"') ne 1 and index(tmp2, "'") ne 1 then do;
        name = upcase(strip(tmp2));
        if name ne '' then output;
      end;
    end;  
   run;
  
   data __vars;
    set __vars __vars2 __vars3;
   run;

    proc sort data=__vars nodupkey;
      by name;
    run;


   
   *------ create list of variables from each used dataset;
   
   %local numds;
   
   data __usedds;
   set __usedds end=eof;
   length stmt $ 2000;
   ds = scan(ds,1,'( ');
   stmt = "data __tmp; set "||strip(ds)||'; run; proc contents data=__tmp noprint out=__cont'||strip(put(_N_, best.))||
          '; run;  data __cont'||strip(put(_N_, best.))||'; length dsname $ 200; set __cont'||strip(put(_N_, best.))||
          '; dsname = "'||strip(scan(ds,2,'.('))||'";';
   call execute(stmt);
   if eof then call symput('numds', strip(put(_N_, best.)));
   run;
   
   
   data __cont;
    if 0;
   run;
   
   *--- check which variable is in which dataset;
   %if &numds>0 %then %do;
       %do i=1 %to &numds;
            data __cont&i;
              length name $ 40;
              set __cont&i;
              name= upcase(name);
              dsname= upcase(dsname);
              keep name dsname;
            run;
            
            proc sort data=__cont&i nodupkey;
              by name;
            run;
            
            data __cont&i;
              merge __cont&i (in=a) __vars (in=b);
              by name;
              if a and b;
              dsname = strip(dsname)||'.'||strip(name);
            run;
              
            data __cont;
              set __cont __cont&i (keep=dsname);
             run;
       %end;
       
       data __cont;
        set __cont __codebvars;
       run;
      
       proc sort data=__cont nodupkey;
        by dsname;
       run;
      
       proc sql noprint;
        select distinct dsname into:usedvars separated by '; '  from __cont;
       quit;
  
  %end;

   *--- check if metadata file exist, if not then create it ---;

   %if %sysfunc(exist(__mout.&metadatads))=0 %then %do;
     data __mout.&metadatads;
      if 0;
      length rrguri $ 100 datasets variables popwhere tabwhere invarwhere title1-title6 o_where  fname 
             macrosused $ 2000;
      rrguri='';
      datasets='';
      variables='';
      popwhere='';
      tabwhere ='';
      title1='';
      title2='';
      title3='';
      title4='';
      title5='';
      title6='';
      o_where ='';
      invarwhere='';
      fname='';
      macrosused='';
     run; 
   %end;

   *--- if append=n and tablepart=FIRST then delete existing entries for the program;
   
   %if %upcase(&append)=N and (&tablepart=FIRST or %length(&tablepart)=0) %then %do;
     data __mout.&metadatads;
      set __mout.&metadatads;
      if rrguri = strip("&rrguri") then delete;
     run; 
   %end; 
   
   *--- insert entries for the program;
   
   data __meta;
        length rrguri $ 100 datasets variables popwhere tabwhere invarwhere title1-title6 o_where fname 
               macrosused tmp1 tmp2 $ 2000;
        rrguri = strip(symget("rrguri"));
        fname =  strip(symget("fname"));
        datasets = strip(symget("useddatasets"));
        variables = strip(symget("usedvars"));
        tabwhere = strip(symget("tabwhere"));
        popwhere = strip(symget("popwhere"));
        %do i=1 %to 6;
        title&i = strip(symget("tt&i"));
        %end;
        if &n_analvar=1 then do;
          if tabwhere ne '' then tabwhere = strip(tabwhere)||' and '||strip(symget("where"));
        end;  
        else invarwhere=strip(symget("where"));
        o_where = strip(symget("popwhere2"))||' '||strip(symget("denomwhere"))||
                  ' '||strip(symget("totalwhere"));
        macrosused = strip(symget("macrosused"));     
        tmp1 = strip(symget("macrosinc1"));
        tmp2 = strip(symget("macrosinc2"));
        macrosused = catx('; ',strip(macrosused),strip(tmp1),strip(tmp2));
        
        drop tmp1 tmp2;
   run;  

   data __mout.&metadatads;
      set __mout.&metadatads __meta;
   run;
   

%end;



%if &debug=0  and (&tablepart=LAST or %length(&tablepart)=0 ) %then %do;
  proc datasets nowarn nolist memtype=data;
    delete __:;
  run;
  quit; 
%end;

%if &tablepart=FIRST or &tablepart=MIDDLE  %then %do;

    data __varinfo;
    if 0;
    run;  

    data __rrgpgminfo;
      length key $ 20 value $ 32000;
      id=.;  
      key='';
      value='';
      if 0;
    run;  
%end;




options msglevel=i;
filename __infile "&rrgpgmpath./&rrguri..sas" lrecl=1000;
filename __outfil " &rrgpgmpath0./&rrguri..sas" lrecl=1000;

data _null_;
  length msg $ 384;
   rc=fcopy('__infile', '__outfil');
   if rc=0 then
      put 'Copied generated program.';
   else do;
      msg=sysmsg();
      put rc= msg=;
   end;
run;


%mend;
