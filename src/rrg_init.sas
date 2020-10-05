/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 
 
 Macro parameters specified by User:
 - URI (required) the name of the report. Must be allowable SAS dataset name.
 - PURPOSE (optional, rarely used) writes to generated program a comment about 
     the purpose of this macro. 
     the default is " to clean up work directory of files starting with __
         and to initialize __varinfo data set and __statinfo datasets"
 - OUTNAME (optional) name of output RTF and/or PDF file, without extension, 
      if it is desired to name the output file in different lenght/naming convention 
      than SAS dataset rules allow. The length/value is limited only by OS restrictions. 
 */
 
 /*
10Sep2020 rrg_init PROGRAM FLOW
Note: this.xxx refers to macro parameter xxx of this macro

1. calls %__initcomm

2. if outname defined in %rrg_intitlist then replace __outname value in __rrgxml with the one defined in %rrg_intitlist
  (and if __rrgxml does not exist, creates in with __outname=this.outname)
  
3. initializes  __varinfo dataset
    
4. creates formats from __rrgconfig ds section A1:, A2 (__rrgfmt ds)
    creates rrgheader ds from E1 section of __rrgconfig ds 

    make substitutions for 
      _URI_     (this.uri), 
      _USERID_  (&sysuserid, 
      _DATE_    (current date), 
      _PGMNAME_ (rrguri from __rrgconfig), 
      _PURPOSE_  (from this.purpose) 
      
      If there is no [E1] section then creates __rrgheader ds with rudimentary "header", which includes 
      &rrguri (typically , this.uri, unless redevined in config file, 
      creator (&sysuserid), date (date of program run), and this.purpose
  
 5.  initializes __rrginlibs ds
 
 ds used:__rrgxml (if exists), __rrgconfig   
 ds created:  , rrgheader (with pgm header) , __rrgxml (if not exists) WITH OUTNAME ONLY, 
                       __rrgfmt (for cntlin)
 ds updated:  ,  __rrgxml (updated with OUTNAME if it was created in initcomm from TOC file), 
 ds initialized as empty: __rrginlibs, __varinfo
 
  
*/  
   

%macro RRG_init (URI=, purpose=, outname=)/store;


%local uri purpose outname;
%global rrguri;
%global rrgpgmpath0;
%local  purpose;
%local __workdir __dirdel DELRRGCONF;    

%let __workdir = %sysfunc(getoption(work));

%if %index(&__workdir, %str(\))>0 %then %let __dirdel=%str(\);
%else %let __dirdel=%str(/);
%let rrgpgmpath0=&rrgpgmpath;
%let rrgpgmpath=&__workdir;
%*put 4iza rrgpgmpath=&rrgpgmpath;



%__initcomm;


%if %length(&outname) %then %do;
  
    %if %sysfunc(exist(__rrgxml)) %then %do;

      data __rrgxml;
        set __rrgxml;
        __outname="&outname";
      run;
    
    %end;
    
    %else %do;
      data __rrgxml;
        __outname="&outname";
      run;
    %end;    

%end;

data __varinfo;
if 0;
run;


%** DEFINE FORMATS FOR DISPLAY OF STATISTICS AND FOR DECIMAL PRECISION MODIFIERS;
%** TAKING THEM FROM CONFIGURATION FILE;

data __rrgfmt (rename=(rtype=type));
  set __rrgconfig( where=(type=:'[A1'));
  length start end label fmtname rtype $ 200;
  start=w1;
  end=w1;
  label=w2;
  if type='[A1]' then fmtname="$__rrgcf";
  else if type='[A1L]' then fmtname="$__rrglf";
  rtype='C';
  output;
  drop type;
run;


data __rrgtmpfmt2 (rename=(rtype=type));
  set __rrgconfig( where=(type='[A2]')) end=eof;
  length start end label fmtname rtype $ 200;
  start=w1;
  end=w1;
  label=w2;
  fmtname="__rrgdf";
  rtype='I';
  output;
  if eof then do;
    start='**OTHER**';
    end='**OTHER** ';
    rtype='O';
    fmtname="__rrgdf";
    label='1';
    output;
  end;
  
  drop type;
run;

proc append base=__rrgfmt data=__rrgtmpfmt2;
run;



proc format cntlin=__rrgfmt;
run;


*** DETERMINE IF HEADER TEMPLATE IS PROVIDED IN CONFIGURATION FILE;

data rrgheader;
set __rrgconfig(where=(type='[E1]'));
length sdate $ 9 uri rrguri $ 200 record $ 2000;

sdate_ = date();
sdate = put(sdate_, date9.);
RRGURI = upcase(cats(symget("rrguri")));
URI = upcase(cats(symget("uri")));

record = tranwrd(cats(record), "_URI_", cats(uri)); 
record = tranwrd(cats(record), "_USERID_", cats("&sysuserid"));
record = tranwrd(cats(record), "_DATE_", cats(sdate));
record = tranwrd(cats(record), "_PGMNAME_", cats(rrguri));
record = tranwrd(cats(record), "_PURPOSE_", cats(symget('purpose')));
output;
run;

%local ise1;
%let ise1=0;

proc sql noprint;
  select count(*) into:ise1 separated by ' ' from rrgheader;
quit;

%if &ise1=0 %then %do;

    data rrgheader;
    length record $ 2000;
    now = today();
    record="/*---------------------------------------------------------------------;"; output;
    record=" ";output;
    record="Program:       &rrguri..sas";output;
    record=" ";output;
    record="Purpose:       &purpose";output;
    record="Date created:  "||put(now,date9.);output;
    record="Author:        &sysuserid";output;
    record=" ";output;
    record=" ";output;
    record="Rapid Report Generator (RRG) Version %__version;";output;
    record="Copyright Izabella Peszek 2008 (iza.peszek@gmail.com)";output;
    record="*--------------------------------------------------------------------*/;";output;
    record=" ";output;
    record=" ";output;
    run;

%end;

/*
data __rrginlibs;
  if 0;
run;
*/



%put FINISFED RRG_INIT;

%mend;




