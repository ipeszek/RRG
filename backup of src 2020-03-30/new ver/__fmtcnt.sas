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

put @1 "if &cntvar=. then &cntvar=0; ";
put @1 "if &denomvar>0  then &pctvar = 100*&cntvar/&denomvar;";
put @1 "if &denomvar=. then &denomvar=0;";

%if %qupcase(%qcmpres(&stat))=N  %then %do;
put @1 "&outvar = compress(put(&cntvar, 12.));";
%end;
%if %qupcase(%qcmpres(&stat))=D  %then %do;
put @1 "&outvar = compress(put(&denomvar, 12.));";
%end;
%else %if %qupcase(%qcmpres(&stat))=PCT  %then %do;
  put @1 "&outvar=cats(put(&pctvar, &pctfmt));";
%end;
%else %if %qupcase(%qcmpres(&stat))=NPCT or
  %qupcase(%qcmpres(&stat))=%nrbquote(N+PCT) %then  %do;
  put @1 "&outvar = cats(&cntvar)||' '||cats(put(&pctvar, &pctfmt));";
%end;   
%else %if %qupcase(%qcmpres(&stat))=NNPCT  or
   %qupcase(%qcmpres(&stat))=%nrbquote(N+D+PCT)  %then %do;
   put @1 "&outvar = cats(&cntvar,'/', &denomvar)||' '||cats(put(&pctvar, &pctfmt));";
%end;   
%else %if %qupcase(%qcmpres(&stat))=%nrbquote(N+D)  %then %do;
   put @1 "&outvar = cats(&cntvar,'/', &denomvar);";
%end;   

%mend;
