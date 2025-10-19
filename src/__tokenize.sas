/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __tokenize(s)/parmbuff store;
%local string dsout;
%* cretes dataset __tokends with 1 variables: nstring ;
%* nobs is number of tokens in &string (comma=delimited);
%* nstring (length $ 2000) is value of each token;
%* number of observations is in this dataset is number of tokens;

%local s  string i;



data _null_;
length x $ 2000;
x = symget("syspbuff");
x = substr(x,2, length(x)-2);
call symput ("string", trim(x));
run;

%local  ischar;
%let ischar=0;
%if %index(%nrbquote(&string),%str(%"))>0 or %index(%nrbquote(&string),%str(%'))>0 
   %then %do;
     %let ischar=1;
%end;

/*    
data __tokends;
length  nstring $ 2000;
do nstring=&string;
   %if &ischar=1 %then %do;
      nstring = quote(trim(nstring));
   %end;
   %else %do;
      nstring =cats(input(nstring, ??best.));
   %end;
   output;
end;
run;
*/

%local numtokens ;
%let numtokens = %sysfunc(countw(&string, %str(,)));
%do i=1 %to &numtokens;
  %local token&i;
  %let token&i = %sysfunc(scan(&string, &i, %str(,)));
%end;

data __tokends;
length  nstring  $ 2000;
%do i=1 %to &numtokens;
  %if &ischar=1 %then %do;
    nstring=quote(dequote(strip(symget("token&i"))));
  %end;
  %else %do;
    nstring = strip(symget("token&i"));
   %end;
  output;
%end;
run;



%mend;
