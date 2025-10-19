/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __verifyuri(name)/store;
  
  %local name chk_1st chk_rest;

    %local msg;
    
    data _null_;
      length name first all $ 200;
      name = cats(upcase(symget("name")));
      first="ABCDEFGHIJKLMNOPQRSTUVWXYZ_";
      all= cats(first,"1234567890");
      chk_1st=verify(substr(name,1,1),first);
      chk_rest=verify(name,all);
      if chk_rest>0 then call symput("msg", "The URI cannot contain"||substr(name,chk_rest,1));
      else if chk_1st>0 then call symput("msg", "&er.&ror.: URI must be a valid sas dataset name. The first character in URI cannot be "||substr(name,1,1));
    run;
    
    %if %length(&msg) %then %do;
    %put &msg;
     * endsas;
   %abort cancel;
    %end;
 %mend;
