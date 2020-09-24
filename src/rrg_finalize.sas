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
  
  
%local debug lastcol savexml output_engine  fname colsp varby metadatads;  
%local append appendable tablepart colwidths  stretch print gcols dist2next replace;
 

%local debug savexml savercd gentxt fname metadatads;
  
proc sql noprint;
  select   savercd, gentxt , filename, metadatads            
           into
           :savercd, :gentxt   ,:fname,:metadatads
         separated by ' '
       from __repinfo;
quit;


  /*
proc sql noprint;
  select append into:append separated by ' ' from __repinfo;
  select tablepart into:tablepart separated by ' ' from __repinfo;
  select indentsize into:indentsize separated by ' ' from __repinfo;
  select appendable into:appendable separated by ' ' from __repinfo;
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
  */
/*
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
*/

%local debugc;
%let debugc=%str(%%*);
%if &debug>0 %then %let debugc=;

%if %upcase(&append)=Y or %upcase(&append)=TRUE %then %let append=Y;
%else %let append=N;
%if %upcase(&appendable)=Y or %upcase(&appendable)=TRUE %then %let appendable=Y;
%else %let appendable=N;

data rrgpgmtmp;
  length record $ 200;
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


 

    record= " ";
    record=  "*-------------------------------------------------------------------;";
    record=  "* GENERATE OUTPUT;";
    record=  "*-------------------------------------------------------------------;";
    record= " ";
    record=  '%macro rrgout;';
    
    record=  '%local objname;';
    record=  "proc sql noprint;";
    record=  "select upcase(objname) into:objname from sashelp.vcatalg";
    record=  "where libname='RRGMACR' and upcase(objname)='__SASSHIATO';";
    record=  "quit;";
    record= " ";
    record= " ";
    record = '%local __path;';
    record=  '%if %length(&rrgoutpath)=0 %then';
    record=  '  %let __path=' "&rrgoutpathlazy;";
    record=  '%else %let __path = &rrgoutpath;';
   
    %if %symexist(__sasshiato_home) %then %do;
          record=  '%if %symexist(__sasshiato_home) %then %do;';
          record=  '  %if &objname=__SASSHIATO  and  %length(&__sasshiato_home) %then %do;';
          %if %upcase(&savexml)=Y %then %do;
              record=  '   %__sasshiato(path=&__path,' " debug=&debug, dataset=&rrguri);";
          %end; 
          %else %do;
              record=  '   %__sasshiato(' "debug=&debug,dataset=&rrguri);";
          %end;
          record=  '  %end;';
          record=  '%end;';
    %end;

    record= " ";
    record=  '%mend rrgout;';
    record= " ";
    

%end;
    
/* %end;   */


run;

proc append base=rrgpgm data=rrgpgmtmp;
run;



/* %inc "&rrgpgmpath./&rrguri..sas";*/

*** what about append?;


%if %upcase(&savercd)=Y  %then %do;
%*__savercd; *** make it after program is submitted generated;
%end;

%if %upcase(&gentxt)=Y  %then %do;
    %*__gentxt_m; 
%end;

%if %length(&metadatads) %then %do;
    %*__meta(&fname);
%end;


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


/*%inc "&rrgpgmpath./&rrguri..sas";*/


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


/*
%local modstr;
  
%if %upcase(&append)=Y %then %do;
    %let modstr=MOD;
%end;
*/ 

%if &savercd=Y  %then %do;
  %*__savercd_m;
%end;

%if %upcase(&gentxt)=Y  %then %do;

    %*__gentxt_m;

%end; 

/*
    data _null_;
    file "&rrgpgmpath./&rrguri.0.sas"  mod lrecl=1000;
    record= " ";
    record=  "*-------------------------------------------------;";
    record=  "*  CLEANUP;";
    record=  "*-------------------------------------------------;";
    record= " ";
    record=  '%macro __clean;';
    record= " ";
    record=  '%local __path;';
    record=  '%if %length(&rrgoutpath)=0 %then';
    record=  '  %let __path=' "&rrgoutpathlazy;";
    record=  '%else %let __path = &rrgoutpath;';
    record= " ";
    record=  "data _null_;";
    record=  "fname='tempfile';";
    record=  'rc=filename(fname,"'|| '&__path./'|| "&rrguri.0.txt" '");';
    record=  "if rc = 0 and fexist(fname) then rc=fdelete(fname);";
    record=  "rc=filename(fname);";
    record=  "run;";
    record= " ";
    record=  '%mend;';
    record= " ";
    record=  '%__clean;';
    record= " ";
    run;
*/   
 

/*
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
*/
 
    
%skippr:

%*put RRG INFO: fname=&fname rrguri=&rrguri;
  
  /*
data _null_;
fname="tempfile";
** log file;
rc=filename(fname,"&rrgpgmpath./&rrguri.0.sas");
if rc = 0 and fexist(fname) then
rc=fdelete(fname);
rc=filename(fname);
 

%if &debug<99 %then %do;

    
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
*/
  
data _null_;
  set __timer;
  if _n_=1 then put 'EXECUTION STATISTICS:';
  put @1 time time8. @10 task $100.;
run;

/*
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


*/


%mend;
