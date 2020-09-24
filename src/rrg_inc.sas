/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 
 * the only user-specified parameter is STRING. Depending  on system configuration it can be just a name of sas program (typically, macro, e.g. mymacro.sas) but often fully qualified path needs to be used, e.g. C:\pgm\mymacro.sas
 */


%macro rrg_inc(string)/ store;

%local string pgmpath;
%local st dost;
%let st=%str();

%if %index(&string, %str(\)) or %index(&string,%str(/)) %then %do;
  
%end;
%else %do;
  
  data _null_;
  set sashelp.vextfl;
  
   if index(upcase(xpath), ".SAS") then do;
      xpath = tranwrd(xpath,'\','/');
      xpath = reverse(strip(xpath));
      lastslash=index(xpath,"/");
      xpath = reverse(substr(xpath, lastslash));
      call symput('pgmpath', strip(xpath));
    end;
  run;  
  
  %let string = &pgmpath.&string;
  
%end;  


%if %sysfunc(exist(__drrght))=0 %then %do;
    data __rrght0;
    length record $ 2000;
    record =  '%inc '||"'"||cats(symget("string"))||"' ;";;
    run;
    
    data __rrght;
      set  __rrght __rrght0;
    run;

%end;



data rrgpgmtmp;
length record  $ 200;
keep record;
record = '%inc '||"'"||cats(symget("string"))||"' ;";;
call symput("st", string);
output;
record=' '; output;
run;

proc append data=rrgpgmtmp base=rrgpgm;
run;

&st;

data __tmp;
  length key $ 20 value $ 32000;
  key = "rrg_inc";
  value = strip(symget("string"));
run;

data   __rrgpgminfo;
  set __rrgpgminfo __tmp;
run;

%mend;

