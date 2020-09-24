/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __fmtcnt(cntvar=, pctvar=, denomvar=, stat=, 
  outvar=, pctfmt=%nrbquote(__rrgp1d.))/store;
%local cntvar pctvar denomvar stat outvar pctfmt;

record =  "if &cntvar=. then &cntvar=0; "; output;
record =  "if &denomvar>0  then &pctvar = 100*&cntvar/&denomvar;";output;
record =  "if &denomvar=. then &denomvar=0;";output;

%if %qupcase(%qcmpres(&stat))=N  %then %do;
record =  "&outvar = compress(put(&cntvar, 12.));";output;
%end;
%if %qupcase(%qcmpres(&stat))=D  %then %do;
record =  "&outvar = compress(put(&denomvar, 12.));";output;
%end;
%else %if %qupcase(%qcmpres(&stat))=PCT  %then %do;
  record =  "&outvar=cats(put(&pctvar, &pctfmt));";output;
%end;
%else %if %qupcase(%qcmpres(&stat))=NPCT or
  %qupcase(%qcmpres(&stat))=%nrbquote(N+PCT) %then  %do;
  record =  "&outvar = cats(&cntvar)||' '||cats(put(&pctvar, &pctfmt));";output;
%end;   
%else %if %qupcase(%qcmpres(&stat))=NNPCT  or
   %qupcase(%qcmpres(&stat))=%nrbquote(N+D+PCT)  %then %do;
   record =  "&outvar = cats(&cntvar,'/', &denomvar)||' '||cats(put(&pctvar, &pctfmt));";output;
%end;   
%else %if %qupcase(%qcmpres(&stat))=%nrbquote(N+D)  %then %do;
   record =  "&outvar = cats(&cntvar,'/', &denomvar);";output;
%end;   

%mend;
