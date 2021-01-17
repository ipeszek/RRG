/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 
 
 EXECUTES THIS.STRING AND CREATES/APPENDS RECORD WITH THIS.STRING TO __RRGINC;
 */


%macro rrg_call_macro(string)/ store;

%local string;
%local st dost;
%let st=%str();

%if %sysfunc(exist(__rrginc))=0 %then %do;
  
  data __tmp;
  length record $ 2000;
  record = cats('%',symget("string"),';');
  call execute(cats('%nrstr(',record,')'));
  run;
  
  proc append data=__tmp base=__rrginc;
  run;

%end;

%else %do;
  
  data __rrginc;
  length record $ 2000;
  keep record;
  record = cats('%',symget("string"),';');
  call execute(cats('%nrstr(',record,')'));
  run;
  
%end;




%mend;

