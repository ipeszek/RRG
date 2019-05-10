/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro rrg_finalizelist(debug=0, savexml=)/store;
%* note: for now, colsize and dist2next (if in units) shoudl be number of chars if java2sas is used; 
%* assumes __tcol takes only one line between //;
%* assumes varbygrp has only one line;
%* ignores __keepn;

%* Revision notes:  07Apr2014 commented out recoding of curly braces to #123 and #125 (superscript did not work except in header);
 
%local islicenseok debug savexml ;
%*let islicenseok=%__license;
%let islicenseok=1;



%local war ning;
%let war=WAR;
%let ning=NING;

%local rrgoutpathlazy;
%let rrgoutpathlazy=&rrgoutpath;



 
%local debugc;
%let debugc=%str(%%*);
%if &debug>0 %then %let debugc=;
 
 

 
%local numvars i dataset orderby j isspanrow ispage debug java2sas indentsize;

proc sql noprint;
  select dataset into:dataset separated by ' ' from __repinfo;
  select orderby into:orderby separated by ' ' from __repinfo;
quit;

/* 
proc sql noprint;
select max(varid) into:numvars separated by ' ' from __listinfo;
%do i=1 %to &numvars;
  %local label&i  width&i group&i spanrow&i align&i halign&i
  page&i id&i alias&i  decode&i format&i stretch&i
  break&i d2n&i keeptogether&i;
   
  select dequote(label)  into: label&i separated   by ' ' from __listinfo (where=(varid=&i));
   
  select width   into: width&i separated   by ' ' from __listinfo (where=(varid=&i));
  select upcase(group)   into: group&i separated   by ' ' from __listinfo (where=(varid=&i));
  select upcase(spanrow) into: spanrow&i separated by ' ' from __listinfo (where=(varid=&i));
  select upcase(align)   into: align&i separated   by ' ' from __listinfo (where=(varid=&i));
  select upcase(halign)  into: halign&i separated  by ' ' from __listinfo (where=(varid=&i));
  select upcase(page)    into: page&i separated    by ' ' from __listinfo (where=(varid=&i));
  select upcase(id)      into: id&i separated      by ' ' from __listinfo (where=(varid=&i));
  select upcase(alias)   into: alias&i separated   by ' ' from __listinfo (where=(varid=&i));
  
  select upcase(skipline) into: skipline&i separated   by ' ' from __listinfo (where=(varid=&i));
  select upcase(decode)  into: decode&i separated   by ' ' from __listinfo (where=(varid=&i));
  select upcase(format)  into: format&i separated   by ' ' from __listinfo (where=(varid=&i));
  select upcase(stretch) into: stretch&i separated   by ' ' from __listinfo (where=(varid=&i));
  select upcase(keeptogether) into: keeptogether&i separated   by ' ' from __listinfo (where=(varid=&i));
  select upcase(breakok) into: break&i separated   by ' ' from __listinfo (where=(varid=&i));
  select upcase(dist2next) into: d2n&i separated   by ' ' from __listinfo (where=(varid=&i));
   
  select upcase(java2sas) into:java2sas separated by ' ' from __repinfo; 
  select indentsize into:indentsize separated by ' ' from __repinfo;
   
  %if &&spanrow&i=Y %then %let isspanrow=1;
  %if &&page&i=Y %then %let ispage=1;
  
  %if %upcase(&java2sas)=Y %then %do;
    %if %length(&&d2n&i)=0 %then %let d2n&i=1;
  %end;
  %else %do;
    %if %length(&&d2n&i)=0 %then %let d2n&i=D;
  %end;  
  %if "&&stretch&i" ne "N" %then %let stretch&i=Y;
  
%end;

quit;

*/

/*
 
%local numcol numpagev numspanv lastvb lastspan;
%let numcol=-1;
%let numpagev=0;
%let numspanv=0;
 
%do i=1 %to &numvars;
 
%if &&page&i=Y %then %do;
%let spanrow&i=;
%let group&i=;
%let id&i =;
%end;
%if &&spanrow&i=Y %then %do;
%let group&i=;
%let id&i =;
%end;
 
%if &&page&i ne Y and &&spanrow&i ne Y %then %do;
  %let numcol = %eval(&numcol+1);
  %local vcn&numcol;
  %let vcn&numcol=&i;
%end;
%else %if &&page&i = Y %then %do;
  %let numpagev = %eval(&numpagev+1);
  %local pvn&numpagev;
  %let pvn&numpagev=&i;
  %let lastvb=&&alias&i;
%end;
%else %if &&spanrow&i = Y %then %do;
  %let numspanv = %eval(&numspanv+1);
  %local svn&numspanv;
  %let svn&numspanv=&i;
  %let lastspan=&&alias&i;
%end;
 
%if %length(&&align&i)=0 %then %let align&i = L;
%if %length(&&halign&i)=0 %then %let halign&i = &&align&i;
%if %length(&&width&i)=0 %then %let width&i=LW;
 
%end;
 
%local i z   ;
*/
 
%local append appendable;
proc sql noprint;
select upcase(append) into:append separated by ' ' from __repinfo;
select upcase(appendable) into:appendable separated by ' ' from __repinfo;
quit;

%local appendm;
%if %upcase(&append) ne Y %then %let append=N;
%if &append = Y %then %do;
%let appendm=mod;
%end;
 
%*put 4iza append=&append appendable=&appendable;



%local savercd gentxt;
proc sql noprint;
  select savercd into:savercd separated by ' ' from __repinfo;
  select gentxt into:gentxt separated by ' ' from __repinfo;
quit;

%*put 4iza savercd=&savercd gentxt=&gentxt append=&append;
%local modstr;
%if %upcase(&append)=Y %then %do;
    %let modstr=MOD;
%end;

%if &savercd=Y  %then %do;
 
  %__savercd;
  
%end;

%if &gentxt=Y  %then %do;

  %__gentxt;

%end;



data _null_;
file "&rrgpgmpath./&rrguri.0.sas" mod lrecl=5000;
put;
put;
put @1 '%macro rrgout;';
put;
put @1 '  %local objname;';
put;
put @1 "  proc sql noprint;";
put @1 "  select upcase(objname) into:objname from sashelp.vcatalg";
put @1 "  where libname='RRGMACR' and upcase(objname)='__SASSHIATO';";
put @1 "  quit;";
put;
put '%local __path;';
put @1 '%if %length(&rrgoutpath)=0 %then';
put @1 '  %let __path=' "&rrgoutpathlazy;";
put @1 '%else %let __path = &rrgoutpath;';
put;
%if %symexist(__sasshiato_home) %then %do;
put @1 '  %if %symexist(__sasshiato_home) %then %do;';
put @1 '    %if &objname=__SASSHIATO  and  %length(&__sasshiato_home) %then %do;';
%if %upcase(&savexml)=Y %then %do;
 
 put @1 '   %__sasshiato(path=&__path,' " debug=&debug, dataset=&rrguri, reptype=L);";
%end; 
%else %do;
  put @1 '     %__sasshiato(' "debug=&debug,dataset=&rrguri,reptype=L);";
%end;
put @1 '    %end;';
put @1 '  %end;';
%end;
put;
put @1 '%mend rrgout;';
put;
put @1 '%rrgout;';
run;
 
%inc "&rrgpgmpath./&rrguri.0.sas";
 
%* add this portion to generated file;
data _null_;
infile "&rrgpgmpath./&rrguri.0.sas" length=len lrecl=1000;
file "&rrgpgmpath./&rrguri..sas" mod lrecl=1000;
length record $ 5000;
input record $varying2000. len;
put record $varying2000. len;
run;




data _null_;
file "&rrgpgmpath./&rrguri.0.sas" ;
put ' ';
run; 
 
 
%local fname;
proc sql noprint;
select filename into:fname separated by ' ' from __repinfo;
quit;

 
%*----------------------------------------------------------------------;
%* save metadata;
%*----------------------------------------------------------------------;

%local metadatads;
proc sql noprint;
  select METADATADS into:METADATADS separated by ' ' from __repinfo;
quit;

%if %length(&metadatads)=0 %then %goto skipmeta;

%local useddatasets usedvars tt1 tt2 tt3 tt4 tt5 tt6 i subjid 
       where n_analvar macrosinc1 macrosinc2 ;

 proc sql noprint;
    
    %do i=1 %to 6;
    select strip(title&i) into:tt&i separated by ' ' from __repinfo;
    %end;
    select strip(value) into:macrosinc1 separated by '; '
      from __rrgpgminfo (where =(key='rrg_inc'));
    select strip(value) into:macrosinc2 separated by '; '
      from __rrgpgminfo (where =(key='rrg_call_macro'));

    quit;  

   libname __mout "&rrgoutpath";  

   data __rrginlibs;
    length dataset  $ 2000;
    set __rrginlibs;
    if 0 then dataset='';
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
  
  data __vars;
    set __listinfo end=eof;
    length name $ 32;
    name= upcase(alias);
    if name ne '' then output;
    name=upcase(decode);
    if name ne '' then output;
    if eof then do;
      name = upcase(symget("subjid"));
      output;
    end;  
    keep name;
   run;
   
   data __vars2;
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
  
  data __vars;
    set __vars __vars2;
  run;
    
   proc sort data=__vars nodupkey;
      by name;
    run;

   
   
   *------ create list of variables from each used dataset;
   
   %local i numds;
   
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
            length name $ 32;
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
   
  *--- if append=n then delete existing entries for the program;
   
   %if %upcase(&append)=N  %then %do;
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
        tabwhere='';
        popwhere='';
        invarwhere='';
        o_where = '';
        %do i=1 %to 6;
          title&i = strip(symget("tt&i"));
        %end;
        macrosused = '';
        tmp1 = strip(symget("macrosinc1"));
        tmp2 = strip(symget("macrosinc2"));
        macrosused = catx('; ',strip(tmp1),strip(tmp2));
        
        drop tmp1 tmp2;
      run;  

      data __mout.&metadatads;
      set __mout.&metadatads __meta;
      run;
      
  

%skipmeta:  
 


%local colstr cl totusedw clearh cntcs;

 
%if &java2sas ne Y %then %goto skippr;
 
%local ps ls;
%let ls = 119;
%let ps = 44;

 
%* determine margins and page size from sasshiato;
%* determine and process column string;


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

%local tmp tmpcw0 tmpcw tmp1;
%do i=0 %to &numcol;
  %if %scan(&dist2next,%eval(&i+1), %str( ))=D %then %let tmp = &tmp 1;
  %else %do;
    %let tmp1 = %upcase(%scan(&dist2next,%eval(&i+1), %str( )));
    %*put 4iza tmp1=&tmp1;
    %if %index(&tmp1,CH)>0 %then %let tmp1 =  %sysfunc(tranwrd(&tmp1, CH, %str()));
    %else %if &tmp1<=12 %then %let tmp1=1;
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
%if &debug>0 %then %do;
%*put 4iza colwidths=&colwidths dist2next=&dist2next;
%end;

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

data __colinfo;
  length nal $ 20;  
 
%do i=0 %to &numcol;
  colnum=&i;
  focol=0;
  ** first only column;
  %let z = &&vcn&i;
  %local nal&i  __sp&i;
  %if %upcase(&&align&z)=L %then %do; nal='left flow'; %end;
  %if %upcase(&&align&z)=D %then %do; nal='left flow';%end;
  %if %upcase(&&align&z)=C %then %do; nal='center';%end;
  %if %upcase(&&align&z)=R %then %do; nal='right';%end;
  %if &i>0 %then %do; sp = %scan(&dist2next, &i, %str( )); %end;
  %if %upcase(&&group&z)=Y %then %do; focol=1; %end;
  output;
%end; 
run; 

%*********************************************************************************;
%local __fospanvar __spanvar;
%if &isspanrow=1 %then %do;
  %let __fospanvar=__fospanvar __tcol;
  %let __spanvar=__spanvar __tcol;
%end;
 


 
%* determine column headers;
%* assumes all headers are the same in each varby group;
%* this will not work for table;

%local hhasdata;
%let hhasdata=0;
%* hhasdata=1 if there are some header records;
 
data __headers;
set &rrguri;
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
  
   %__j2s_ph(ispage=&ispage, numcol=&numcol, fname=&fname, cl =&cl, ls=&ls, ps=&ps);
   
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
 
%__j2s_ptf(ls=&ls, hhasdata=&hhasdata, ispage=&ispage);

%******************************************************************************;
%** previous step created files __currtflt, __currtflf, __currtflsh,;
%** __currtflsf (wiht titles, footers, system titles and system footers);
%** and updated __lpp dataset with lpp and lppnh ;
%* (lines per page and lines per page excl. header;
%******************************************************************************;
%* limitation/todo: vabylab: one line, tcols- one line between splits; 
%******************************************************************************; 

%local lpp lppnh;



data __lpp;
  set __lpp;
  call symput('lpp', strip(put(lpp, best.)));
  call symput('lppnh', strip(put(lppnh, best.)));
run;
  
%if &hhasdata=0 %then %do;

%put;
%put RRG INFO: at generation time there was no data to show;
%put;
  
  %****************************************************************;
  %* generate report with "no data" mesage only and no footnotes;
  %****************************************************************;

  data __currtflf;
    if 0;
  run;
 
  data null;
  file "&rrgpgmpath./&rrguri.0.sas" mod ;
  set __report;
  put;
  put;
  put @1 '%macro __nodata;';
  put;
  put @1 '%local __path;';
  put @1 '%if %length(&rrgoutpath)=0 %then';
  put @1 '  %let __path=' "&rrgoutpathlazy;";
  put @1 '%else %let __path = &rrgoutpath;';
  put;
  put @1 "data _null_;";
  put @1 'file "' '&__path./' "&fname..out"  '";' ;
  put @1 "  length line $ &ls;";
  put @1 "  line = repeat('_', &ls-1);";
  put @1 "  put @1 line;";
  put @1 "  put;";
  put @1 '  put "'  __nodatamsg '";';
  put @1 "  put @1 line;";
  put @1 "  put;";
  put @1 "  run;";
  put @1 ;
  put @1 '%mend;';
  put @1 '%__nodata;';
  run;
   
  %goto readrtf;
%end;
 



%*-------------------------------------------------------------------------------------; 
%* generate code to transform data -- create line splits, calc page breaks etc;
%*-------------------------------------------------------------------------------------;




%__j2s_pd(numcol=&numcol, cl=&cl, colwidths=&colwidths, lpp=&lpp, isspanrow=&isspanrow, 
    ispage=&ispage, __spanvar=&__spanvar); 



%*-------------------------------------------------------------------------------------;
%* run proc report;
%*-------------------------------------------------------------------------------------;

/*
  data null;
  file "&rrgpgmpath./&rrguri.0.sas"  mod lrecl=5000;
  put;
  put @1 "proc printto print = '" "&rrgoutpath./&fname..out" "' new;";
  put;
  put;
*/

%__j2s_rpr(ls=&ls, ps=&ps, ispage=&ispage, isspanrow=&isspanrow, __spanvar=&__spanvar);

%*-------------------------------------------------------------------------------------;
%* infile proc report;
%*-------------------------------------------------------------------------------------;
 
%readrtf:

%*-------------------------------------------------------------------------------------;
%* append to &rrguri.0.sas statements to infile proc report and add titles and foots;
%*-------------------------------------------------------------------------------------;

%__j2s_ipr(lppnh=&lppnh, ls=&ls, appendable=&appendable, append=&append);
 
 
%if  %upcase(&appendable) ne Y %then %do; 

  %*-------------------------------------------------------------------------;
  %*** append to &rrguri.0.sas statements to create final RTF file;
  %*-------------------------------------------------------------------------;
  
  %__j2s_cr_rtf(ls=&ls);

%end;




%if %upcase(&appendable) ne Y %then %do;
data _null_;
file "&rrgpgmpath./&rrguri.0.sas" mod lrecl=1000;
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

/*put @1 "rc=filename(fname,'" "&rrgoutpath./&rrguri..out0" "');";*/
put @1 'rc=filename(fname,"' '&__path./' "&rrguri..out0" '");';
put @1 "if rc = 0 and fexist(fname) then rc=fdelete(fname);";
put @1 "rc=filename(fname);";
/*put @1 "rc=filename(fname,'" "&rrgoutpath./&rrguri.0.txt" "');";*/
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


%*-------------------------------------------------------------------------;
%* add remaining portion (rrguri.0.sas) to generated file (rrguri.sas);
%*-------------------------------------------------------------------------;

data _null_;
infile "&rrgpgmpath./&rrguri.0.sas" length=len lrecl=1000;
file "&rrgpgmpath./&rrguri..sas" mod lrecl=1000;
length record $ 5000;
input record $varying2000. len;
put record $varying2000. len;
run;


%* submit remaining portion;
%inc "&rrgpgmpath./&rrguri.0.sas";

data _null_;
file "&rrgpgmpath./&rrguri.0.sas" ;
put ' ';
run; 

 

 
 
%skippr:




%*-------------------------------------------------------------------------;
%* delete created helper files ;
%*-------------------------------------------------------------------------;


data _null_;
file "&rrgpgmpath./&rrguri.0.sas"  lrecl=1000;
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

/*put @1 "rc=filename(fname,'" "&rrgoutpath./&fname..out0" "');";*/
put @1 'rc=filename(fname,"' '&__path./' "&fname..out0" '");';
put @1 "if rc = 0 and fexist(fname) then rc=fdelete(fname);";
put @1 "rc=filename(fname);";
/*put @1 "rc=filename(fname,'" "&rrgoutpath./&rrguri.0.txt" "');";*/
put @1 'rc=filename(fname,"' '&__path./' "&rrguri.0.txt" '");';
put @1 "if rc = 0 and fexist(fname) then rc=fdelete(fname);";
put @1 "rc=filename(fname);";

/*put @1 "rc=filename(fname,'" "&rrgoutpath./&fname..out" "');";*/
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
%inc "&rrgpgmpath./&rrguri.0.sas";



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
  /*
  %if %upcase(&appendable) ne Y %then %do;
  rc=filename(fname,"&rrgoutpath./&fname._j.rtf");
  if rc = 0 and fexist(fname) then
  rc=fdelete(fname);
  rc=filename(fname);
  */
  rc=filename(fname,"&rrgoutpath./&fname..out");
  if rc = 0 and fexist(fname) then
  rc=fdelete(fname);
  rc=filename(fname);
  rc=filename(fname,"&rrgoutpath./&fname..out0");
  if rc = 0 and fexist(fname) then
  rc=fdelete(fname);
  rc=filename(fname);
  rc=filename(fname,"&rrgoutpath./&fname.0.txt");
  if rc = 0 and fexist(fname) then
  rc=fdelete(fname);
  rc=filename(fname);  
%end;
/*
rc=filename(fname,"&rrgoutpath./&rrguri..xml");
if rc = 0 and fexist(fname) then
rc=fdelete(fname);
rc=filename(fname);
*/
 
run;

%exitlist:

%mend;

