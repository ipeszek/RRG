/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */


%macro rrg_inc4list(string)/ store;

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



data _null_;
file "&rrgpgmpath./&rrguri.0.sas" mod lrecl=8192;
length string  $ 32000;
string = '%inc '||"'"||cats(symget("string"))||"' ;";;
put;
put string;
call symput("st", string);
put;
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

