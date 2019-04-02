/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __UT_prtgnl(string=, origstring=, delimiter=, tw=, 
                   linesvar=, dest=)/store;

%*----------------------------------------------------------------------
RESPONSIBILITY: 
   this macro is used in data step to calculate the 
   number of lines that specified string variable uses
   
AUTHOR: Iza Peszek 10NOV2007

MACRO PARAMETERS:
   string:     name of variable containing string
   origstring: name of variable (to be created) holding copy of variable
               string   
   delimiter:  the string containign delimiter denoting line break
   tw:         available cell width in twips
   linesvar:   name of variable (to be created) with number of lines
               that &String uses
   dest:       destination, APP or CSR
----------------------------------------------------------------------;

%local string origstring delimiter tw linesvar dest;

%*put &origstring=;
&string=&origstring;
__origstring=&string;

&linesvar=0;
if &string='' then do;
  &linesvar=1;
end;

else do;
__lend = length("&delimiter");

if index(&string, "&delimiter")=1 then do;
     &linesvar=1;
     &string = substr(&string, __lend+1);
end;
if index(&string, "~{super")>0 then do;
     &linesvar=&linesvar+2;
end;

__ind=1;

do while (__ind>0 );
%*put &string=;
  __ind = index(&string, "&delimiter");
  if __ind>0 then do;
      if __ind>1 then __tmp = substr(&string, 1, __ind-1);
      else __tmp='';
      %if &dest=CSR %then %do;
          %__UT_prtgsl(varin=__tmp, lenvar=__len, fs=&fontsize, 
                alignvar="C");
          &linesvar =&linesvar+ceil(__len_5/(&tw-20));      
      %end;
      %else %do;
       &linesvar = 
               &linesvar+ceil(12*&fontsize.*length(__tmp)/(&tw-20));
      %end;         
      %*put __tmp= &linesvar= &string=;
      __len = length(__tmp);
      __len2 = length(&string);
    %*put __len2= __len= __lend=;
      if __len2>=__len+__lend+1 then 
         &string  = substr(&string, __len+__lend+1);
      else do;
         &string="";  
         __ind=0;
      end;   
  end;
end;
%*put &string=;
if &string ne '' then do;
       &linesvar = 
               &linesvar+ceil(12*&fontsize.*length(&string)/(&tw-20));
end;
%*put &linesvar=;
__ind = index(reverse(__origstring), reverse("&delimiter"));
if __ind=1 then &linesvar = &linesvar+1;
%*put &linesvar=;
&linesvar = min(&linesvar, length(__origstring));
%*put &linesvar=;
%*put;
%*put;
end;

%mend;

