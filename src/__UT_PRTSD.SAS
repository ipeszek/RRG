/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __UT_prtsd(datain=, lastcheadid=, keepvars=, keeplengths=0)/store;

%*----------------------------------------------------------------------------
 REPONSIBILITY: 
 this macro splits dataset into appropriate column groups, 
      keeping repeated columns
      each dataset is named &datain._X (x=1,2,...)
 
 AUTHOR:        Iza Peszek, 10NOV2007                                                                              
                                                                              
 MACRO PARAMETERS:                                                            
   &datain:     input data set to be split
   &lastcheadid: ID of last column in ID group (to be repeated in each dataset)
   &keepvars:   list of variables to keep in new datasets 
   &keeplengths: if 1, then variables holding lenfths of each column 
                  and its parts is also kept in output datasets
                                                                              
----------------------------------------------------------------------------;


%local datain lastcheadid keepvars keeplengths ncpp i j k;

proc sql noprint;
select count(*) into:ncpp from __rtfds_w3;
  %do i=1 %to &ncpp;
      %local cstart&i cstop&i cpp&i;
      select __startcol into:cstart&i from __rtfds_w3 where group=&i;
      select __endcol into:cstop&i from __rtfds_w3 where group=&i;
      %let cpp&i = %eval(&&cstop&i-&&cstart&i+1);
  %end;
quit;

%local renamestr keep kl rl;
%let keep=;
%do i=0 %to &lastcheadid;
  %let keep=&keep __col_&i;
  %let kl = __len_&i._6 __len_&i._3 __len_&i._5;
%end;


%do i=1 %to &ncpp;
    %local keep&i rename&i kl&i rl&i;
    %let keep&i=&keep;
    %let kl&i =&kl;
    %do j=&&cstart&i %to &&cstop&i;
        %let k = %eval(&j-&&cstart&i+1+&lastcheadid);
        %let keep&i = &&keep&i __col_&j;
        %let kl&i = &&kl&i __len_&j._6 __len_&j._3 __len_&j._5;
        %let rename&i = &&rename&i __col_&j = __col_&k;
        %let rl&i = %str(&&rl&i __len_&j._6=__len_&k._6 
                   __len_&j._3=__len_&k._3 __len_&j._5=__len_&k._5);
    %end;
    
    %if &keeplengths=1 %then %do;
       %let keep&i = &&keep&i &&kl&i;
       %let rename&i=&&rename&i &&rl&i;
    %end;
    
    data &datain._&i %if &i>0 %then %do; (rename=(&&rename&i)) %end;;
    set &datain (keep=&&keep&i &keepvars);
    length __tmpalign $ 2000;
    __lastcol = %eval(&lastcheadid+&&cpp&i);
    __tmpalign ='';
    __align = compbl(__align);
    %do j=0 %to &lastcheadid;
        __tmpalign = trim(left(__tmpalign))||" "
                ||scan(__align, %eval(&j+1), ' ');
    %end;
    %do j=&&cstart&i %to &&cstop&i;
       __tmpalign = trim(left(__tmpalign))||" "
             ||scan(__align, %eval(&j+1), ' ');
    %end;
    __align = __tmpalign;
    drop __tmpalign;
    run;
%end;


%mend;
