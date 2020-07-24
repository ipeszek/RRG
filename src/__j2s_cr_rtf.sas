/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __j2s_cr_rtf(ls=)/store;
  
%local ls;  
%* writes code to create final rtf file;  
%* appends this code to &rrguri.0.sas;
%* dependencies: need rtfstr;


%put;
%put *************************************************************************;
%put STARTNG EXECUTION OF __J2S_CR_RTF;
%put ls=&ls;
%put;

%local fs;

proc sql noprint;
  select __fontsize into:fs separated by ' ' from __report;
quit;

%let fs=%eval(2*&fs);

  

data null;
file "&rrgpgmpath./&rrguri.0.sas"  mod lrecl=5000;
put;
put;
put @1 '%macro __cr_rtf;';
put;
put @1 '%local __path;';
put @1 '%if %length(&rrgoutpath)=0 %then';
put @1 '  %let __path=' "&rrgoutpathlazy;";
put @1 '%else %let __path = &rrgoutpath;';
put;
put @1 "*-------------------------------------------------------------------------;";
put @1 "*** CREATE RTF FILE;";
put @1 "*-------------------------------------------------------------------------;";
put;
put @1 "data _null_;";
put @1 'file "' '&__path./' "&fname..rtf" '" lrecl=1000;';
put @1 "set __file4rtf end=eof;";
put @1 "length dt pg $ 30 tmp1 tmp2 $ 200;";
put @1 "retain dt;";
put @1 "if _n_=1 then do;";
put @1 "  pagenum=1;";
put @1 "  tmp1='';";
put @1 "  tmp2='';";
put @1 "  date_ = date();";
put @1 "  time_=time();";
put @1 "  dt = put(date_, date9.)||' '||put(time_, time5.);";
put;
put @1 "  put '{\rtf1\ansi\deff0\deflang1033{\fonttbl{\f0\fmodern Courier New;}}';";
put @1 "  put '" "&rtfstr" "';";
put @1 "  put '\nocompatoptions\deflang1033\plain\" "fs&fs" "\f0 ';";
put @1 "end;";
put;
put @1 "if record ne '\page' then do;";
put @1 "  if index(record,'_DATE_')>0 then do;";
put @1 "    ind160 = index(record, byte(160));";
put @1 "    if ind160>1 then do;";
put @1 "      tmp1 = substr(record, 1,ind160-1);";
put @1 "      tmp2 =  tranwrd(substr(record, ind160),byte(160),'');";
put @1 "      tmp2 = tranwrd(strip(tmp2), '_DATE_', strip(dt));";
put @1 "      record = strip(tmp1)||repeat(byte(160), &ls-length(tmp1)-length(tmp2)-1)||strip(tmp2);";
put @1 "    end;";
put @1 "    else if ind160=1 then do;";
put @1 "      tmp2 =  tranwrd(record,byte(160),'');";
put @1 "      tmp2 = tranwrd(strip(tmp2), '_DATE_', strip(dt));";
put @1 "      record = repeat(byte(160), &ls-length(tmp2)-1)||strip(tmp2);";
put @1 "    end;";
put @1 "  end;";
put @1 "  if index(record,'_PAGE_')>0 then do;";
put @1 "    pg = 'Page '||strip(put(pagenum, best.))||' of '||" 'strip("' '&__rrgpn' '");';
put @1 "    ind160 = index(record, byte(160));";
put @1 "    if ind160>1 then do;";
put @1 "      tmp1 = substr(record, 1,ind160-1);";
put @1 "      tmp2 =  tranwrd(substr(record, ind160),byte(160),'');";
put @1 "      tmp2 = tranwrd(strip(tmp2), '_PAGE_', strip(pg));";
put @1 "      record = strip(tmp1)||repeat(byte(160), &ls-length(tmp1)-length(tmp2)-1)||strip(tmp2);";
put @1 "    end;";
put @1 "    else if ind160=1 then do;";
put @1 "      tmp2 =  tranwrd(record,byte(160),'');";
put @1 "      tmp2 = tranwrd(strip(tmp2), '_PAGE_', strip(pg));";
put @1 "      record = repeat(byte(160), &ls-length(tmp2)-1)||strip(tmp2);";
put @1 "    end;";
put @1 "  end;";
 
put @1 "  record = tranwrd(record, byte(160), ' ');";
put @1 "  put ";
put @1 "  '\pard\plain\widctlpar\adjustright\aspalpha\aspnum\faauto\ql\li0\ri0\sa0\sb0\f0\" "fs&fs '" ;
put @1 "     record $&ls.. '\par ';";
put @1 "end;";
put @1 "else do;";
put @1 "  put '\page';";
put @1 "  pagenum+1;";
put @1 "end;";
put;
put @1 "if eof then do;";
put @1 " put '}';";
put @1 "end;";
put;
put @1 "run;";
put;
put;
put @1 '%mend;';
put;
put @1 '%__cr_rtf;';
put;
put;
run;

%put; 
%put FINISHED EXECUTION OF __J2S_CR_RTF; 
%put *************************************************************************;

%mend;
