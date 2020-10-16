/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __gentxt_m/store;
  %local rrgoutpathlazy ;
  %let rrgoutpathlazy=&rrgoutpath;

 


  *---------------------------------------------------------;
  *  SAVE VALIDATION TEXT FILE;
  *---------------------------------------------------------;

  
    %local lastcol dsin vbvn rc nobs __path v_fil_loc v_fil_loc0;
    %let vbvn=0;
  
  %if %length(&rrgoutpath)=0 %then    %let __path=&rrgoutpathlazy;
  %else %let __path = &rrgoutpath;
  
  %let v_fil_loc = &__path./&rrguri..txt;
  %let v_fil_loc0 = &__path./&rrguri.0.txt;  
 
  *--------------------------------------------------------------------------;
  *** CHECK IF DATASET WITH TABLE CONTENT HAS ANY OBSERVATIONS;
  *--------------------------------------------------------------------------;
 
    %let dsin = %sysfunc(open(&rrguri));
    %let vbvn = %sysfunc(varnum(&dsin, __varbylab));
    %let nobs = %sysfunc(attrn(&dsin, nobs));
    %let rc = %sysfunc(close(&dsin));
 
    %if &nobs<=0 %then %do;
 
        *-------------------------------------------------------------------;
        * GENERATE EMPTY VALIDATION FILE;
        *-------------------------------------------------------------------;
   
        data _null_;
        file "&v_fil_loc" mod lrecl=32000;;
        put " ";
        run;
  
    %end;

    %else %do;
        %local lastcol;
    
        data _null_;
        set &rrguri;
        if 0 then __col_0=' ';
        array cols{*} $ 2000 __col_:;
        n = dim(cols)-1;
        if _n_=1 then call symput('lastcol', strip(put(n, best.)));
        run;
    
        *-------------------------------------------------------------------;
        * GENERATE VALIDATION FILE;
        *-------------------------------------------------------------------;
        data _null_;
        set &rrguri(where=(__datatype='TBODY'));
          file "&v_fil_loc"  lrecl=32000;;
         put;
        if 0 then do;
          __tcol=' ';
          __fospan=.; 
        end;
        put;      
        array cols{*} __col_0 - __col_&lastcol;
        do i=1 to dim(cols);
            cols[i]=cats(cols[i]);  
        end;
        put;
        %if &vbvn>0 %then %do;
          if __tcol ne '' and __fospan=1 then put __varbylab __tcol;  
          put __varbylab  __col_0 - __col_&lastcol; 
        %end;
        %else %do;
          if __tcol ne '' and __fospan=1 then put __tcol;  
          put  __col_0 - __col_&lastcol; 
        %end;
        put;      
        run;
      
    %end;
  
%mend;
