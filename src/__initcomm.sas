/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */
 
 /* 24JUl2020 Program flow
  check if output location is defined
  cancel out possible proc prinnto destination
  delete all filesin work directory  starting with "__"
  store user options in __rrgpgminfo
  check if configuration file exists. 
    If no, create default config file (__rrgconfig); 
    if yes then read it into __rrgconfig ds
    (type=sectio (e.g. [A0]), w1=keyword (e.g. fontsize) w2=value of keyword (e.g. 12)
    If configuration file has name of TOC file defined and key for records in TOC defined
    then store it in __rrgxml ds, adding where __fn=TFL_FILE_PGMNAME and __outname=TFL_FILE_OUTNAME
    __fn is "redefined" &rrguri and &rrguri is replace in its value (thus, config file can replace &uri with something else)
 
 
 
 ds used:
 ds created:  __timer, __rrgpgminfo (with options), __sasoptions (with all options), __rrgconfig, __rrgxml (with titles, footnotes, outname from TOC)
 ds updated:
 ds initializad: __usedds
 
 
 */

%macro __initcomm /store;


%global rrgfinalize rrgfinalize_er er ror rrgfinalize_done rrg_debug;
%let rrgfinalize=N;
%let rrgfinalize_er=0;
%let er=ER;
%let ROR=ROR;
%let rrgfinalize_done=0;


%if %symexist(rrgoutpath) %then %do;
   %let rrgoutpath = %sysfunc(tranwrd(%nrbquote(&rrgoutpath), %str(\), %str(/)));
%end;
%else %do;
%put ***********************************************************;
%put REQUIRED MACRO VARIABLE RRGOUTPATH IS NOT DEFINED;
%put EXITING SAS;
%put ***********************************************************;
ENDSAS;
%end;


proc datasets memtype=data nolist nowarn;
delete __:;
run;
quit;

%if &rrg_debug>0 %then %do;
data __timer;
	length task $ 100;
		task = "Program Starts";
		dt=datetime(); ;
run;	
%end;

*----------------------------------------------------------------;
* STORE USER OPTIONS ;
*----------------------------------------------------------------;


data __rrgpgminfo;
  length key $ 20 value $ 32000;
  set sashelp.voption (where=(
  OPTNAME in ('MPRINT','MLOGIC','SYMBOLGEN','MFILE','SOURCE',
   'SOURCE2','BYLINE','CENTER','LINESIZE','PAGESIZE','PAGENO',
   'NOTES','MAUTOSOURCE','NUMBER','MACROGEN')));
  if OPTNAME in ('LINESIZE','PAGESIZE','PAGENO') 
      then value = cats(optname,"=",SETTING);
  else value = cats(setting);
  key='sasoption';
  id=0;
  keep id key value;
run;

proc optsave out=__sasoptions;
  

%let rrguri=&uri;

* CHECK IF CONFGURATION FILE WAS DEFINED, IF NOT, CREATE IT; 

%local DELRRGCONF __workdir;

%if %symexist(rrg_configpath)=0 %then %do;
  %global rrg_configpath;
  %let __workdir = %sysfunc(getoption(work));
  %let DELRRGCONF = 1;
  %* CREATE TEMPRARY CONFIGURATION FILE;
  %__rrgconfig;
  %let rrg_configpath=&__workdir.&__dirdel.rrgconfig.ini;
  %put rrg_configpath=&rrg_configpath;
%end;

* READ-IN CONFIGURATION FILE;
data __rrgconfig;
infile "&rrg_configpath" length=len lrecl=2000; 
   input record $varying2000. len; 
   length RECORD w1 w2 type $ 2000;
   retain type;
   if record='' then delete;
   else do;
     if substr(record, 1,1)='#' then delete;
     if substr(record, 1,1)='[' then do;
       type=upcase(cats(record));
       delete;
     end;
     else do;
       w1 = upcase(scan(record,1,' '));
       if record ne w1 then  w2 = substr(record, length(w1)+2);
     end;  
   end;
run;



%if &DELRRGCONF=1 %then %do;
  
  %* DELETE TEMPORARY CONFIGURATION FILE;

    data _null_;
      fname="__tempfile";
        rc=filename(fname,"&rrg_configpath");
        if rc = 0 and fexist(fname) then
          rc=fdelete(fname);
          rc=filename(fname);
    run;
%end;

%* REDEFINE RRGURI;
%local  TFL_FILE_KEY TFL_FILE_NAME TFL_FILE_PGMNAME TFL_FILE_OUTNAME;

data _null_;
  set __rrgconfig(where=(type='[B0]'));
  call symput(cats(w1),cats(w2));
run;

*** READ INFO FROM TOC file (if defined) dataset into __RRGXML dataset;

%if %length(&TFL_FILE_NAME)>0 and %length(&TFL_FILE_KEY)>0 %then %do;

    data __rrgxml;
      set &TFL_FILE_NAME;
      &TFL_FILE_NEWVAR;
    run;
    
    data __rrgxml;
      set __rrgxml (where=(&TFL_FILE_KEY));
      %if %length(&TFL_FILE_PGMNAME) %then %do;
          length __fn $ 200;
          __fn = &TFL_FILE_PGMNAME;
          call symput("rrguri", cats(__fn));
      %end;
      %if %length(&TFL_FILE_OUTNAME) %then %do;
          length __outname $ 200;
          __outname=&TFL_FILE_OUTNAME;
      %end;
    run;

%end;

%* initialize helper files;

data rrgfmt;
  if 0;
  length record $ 2000;
  record='';
run;

data codebefore;
  if 0;
  length record $ 2000;
  record='';
run;

data rrgcodeafter;
  if 0;
  length record $ 2000;
  record='';
run;

data rrgheader;
  if 0;
  length record $ 2000;
  record='';
run;

data rrgfinalize;
  if 0;
  length record $ 2000;
  record='';
run;

%* VERIFY THAT RRGURI conforms to SAS DATASET NAMING RULES;

%__verifyuri(&rrguri);




%mend;




