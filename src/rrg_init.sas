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

%macro RRG_init (URI=, purpose=, outname=)/store;

/***************************************************************************** 
Purpose: A macro to clean up work directory of files starting with __
         and to initialize __varinfo data set and __statinfo datasets

Author:  Iza Peszek, 30Sep2008

Parameters:
  
  
Modifications:
18AUG2020: changed location of generated program to work directory;

Notes:
 

****************************************************************************/;

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
%put 4iza rrgpgmpath=&rrgpgmpath;



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

data __rrgtmpfmt1 (rename=(rtype=type));
  set __rrgconfig( where=(type='[A1]'));
  length start end label fmtname rtype $ 200;
  start=w1;
  end=w1;
  label=w2;
  fmtname="__rrgcf";
  rtype='C';
  output;
  drop type;
run;


data __rrgtmpfmt1l (rename=(rtype=type));
  set __rrgconfig( where=(type='[A1L]'));
  length start end label fmtname rtype $ 200;
  start=w1;
  end=w1;
  label=w2;
  fmtname="__rrglf";
  rtype='C';
  output;
  drop type;
run;
/*
proc print data=__rrgtmpfmt1;
  title "__rrgtmpfmt1";
run;
*/

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


data __rrgtmpfmt;
  set __rrgtmpfmt1 __rrgtmpfmt1l __rrgtmpfmt2;
run;

proc format cntlin=__rrgtmpfmt;
run;


*** DETERMINE IF HEADER TEMPLATE IS PROVIDED IN CONFIGURATION FILE;

data __rrght;
  set __rrgconfig(where=(type='[E1]'));
length sdate $ 9 uri rrguri $ 200;

sdate_ = date();
sdate = put(sdate_, date9.);
RRGURI = upcase(cats(symget("rrguri")));
URI = upcase(cats(symget("uri")));

record = tranwrd(cats(record), "_URI_", cats(uri));
record = tranwrd(cats(record), "_USERID_", cats("&sysuserid"));
record = tranwrd(cats(record), "_DATE_", cats(sdate));
record = tranwrd(cats(record), "_PGMNAME_", cats(rrguri));
record = tranwrd(cats(record), "_PURPOSE_", cats(symget('purpose')));
run;

%local ise1;
%let ise1=0;

proc sql noprint;
  select count(*) into:ise1 separated by ' ' from __rrght;
quit;

%if &ise1=0 %then %do;

data __rrght;
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
proc sql noprint;
  create table __tmp as select libname, path from sashelp.vlibnam
  where upcase(libname) not in ("SASHELP","SASUSER","WORK","MAPS", "RRGMACR")
  and upcase(libname) not in 
  (select libname from sashelp.vmember where upcase(memname)='SASMACR');
quit;

data __rrght0;
set __tmp end=eof;
length record $ 2000;
if _n_=1 then do;
record=" ";output;

record='%macro __fix_libref(name=,location=);';output;
record='%if %sysfunc(libref(&name)) eq 0 %then';output;
record='  %put LIB REF &NAME DEFINED EXTERNALLY;';output;
record='%else %do;';output;
record='  %put LIB REF &NAME DOES NOT EXIST;';output;
record='  %put ASSIGNING IT TO OLD LOCATION >&LOCATION<;';output;
record='  %put DEFINED DURING PROGRAM GENERATION;';output;
record= '  libname &name "&location";';output;
record='%end;';output;
record='%mend;';output;
record=" ";output;

end;
record=cats('%__fix_libref(name=', libname, ', location=', path, ');');output;
record=" ";output;
run;

** note : not sure if I shoudl add __rrght0 here;
data __rrght;
  set __rrght __rrght0;
run;
*/

data __rrginlibs;
  if 0;
run;

data __timer;
	set __timer end=eof;
	output;
	if eof then do;
		task = "Finished initialization";
		time=time(); output;
	end;
run;	


%mend;




