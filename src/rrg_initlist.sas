/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro RRG_initlist (URI=, purpose=, outname=)/store;

/***************************************************************************** 
Purpose: A macro to clean up work directory of files starting with __

Author:  Iza Peszek, 30Sep2008

  
Modifications:
18AUG2020: changed location of generated program to work directory;

****************************************************************************/;

/*
24Jul2020 rrg_initlist PROGRAM FLOW
Note: this.xxx refers to macro parameter xxx of this macro

calls %__initcomm

if outname defined in %rrg_intitlist then replace __outname value in __rrgxml with the one defined in %rrg_intitlist
  (and if __rrgxml does not exist, creates in with __outname=this.outname)
  
cancel out possible proc prinnto destination

copy [E1] section of __rrgconfig into __rrght ds and make substitutions for 
  _URI_     (this.uri), 
  _USERID_  (&sysuserid, 
  _DATE_    (current date), 
  _PGMNAME_ (rrguri from __rrgconfig), 
  _PURPOSE_  (from this.purpose) 
  
  If there is no [E1] section then creates __rrght ds with rudimentary "header", which includes 
  &rrguri (typically , this.uri, unless redevined in config file, 
  creator (&sysuserid), date (date of program run), and this.purpose
  
  
*/  
   


%local uri purpose outname;
%global rrguri rrgpgmpath0;
%local  purpose;
%local __workdir __dirdel DELRRGCONF;    

%let __workdir = %sysfunc(getoption(work));

%if %index(&__workdir, %str(\))>0 %then %let __dirdel=%str(\);
%else %let __dirdel=%str(/);
%let rrgpgmpath0=&rrgpgmpath;
%let rrgpgmpath=&__workdir;

  
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

data __rrginlibs;
  if 0;
run;

%mend;




