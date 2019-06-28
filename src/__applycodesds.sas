/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __applycodesds(
codelistds=,
codes=,
codesds=,
grptemplateds=,
countds=,
dsin=,
by=,
groupvars =,
var =,
decode=,
warn_on_nomatch=1,
fmt=,
misstext=,
missorder=,
showmiss=,
remove=
)/store;

%local codelistds codes codesds grptemplateds countds dsin by 
       groupvars var decode warn_on_nomatch fmt misstext missorder
       showmiss remove;

%local missdec iscodelistds;
%local ngrp tmpgrp i;

%let ngrp = %sysfunc(countw(&groupvars, %str( )));
%do i=1 %to &ngrp;
    %let tmpgrp = &tmpgrp %scan(&groupvars, &i, %str( ))%str(=);
%end;
%let missdec = %nrbquote(&misstext);

*------------------------------------------------------------;
* IF CODELISTDS EXIST THEN MERGE IT IN TO DELETE MODALITIES;
*   NOT ON THE LIST;
*------------------------------------------------------------;

    
%if %sysfunc(exist(&codelistds._exec)) %then %do; 
  %if %length(&decode) %then %do;
  proc sql noprint;
    select distinct &decode into:missdec separated by ' ' 
     from &codelistds._exec(where=(missing(&var)));
  quit;   
  %end;  
  
  %if &missorder=999999 %then %do;
  proc sql noprint;
  select distinct __order into:missorder separated by ' '
    from &codelistds._exec(where=(missing(&var)));
  quit;  
  %end;
%end;
/*%if %length(&missorder)=0 %then %let missorder=999999;*/

%if %length(%nrbquote(&missdec))=0 %then %let missdec=Missing;



data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put;
length __missdec $ 2000;
__missdec = quote(symget("missdec"));

%if &codes=1 or &codesds=1  %then %do; 

put @1 "*----------------------------------------------------------------;";
put @1 "* TAKE ONLY COUNTS FOR MODALITIES NOT IN DATASET FROM codelist  ;";
put @1 "*----------------------------------------------------------------;";
put ;
put @1 "data &codelistds;";
put @1 "  set &countds;";
put @1 "  if 0 then __total=.;";
put @1 "  if __trtid<0 and __total ne 1;";
put @1 "  keep &by __tby &groupvars __order &var __grpid &decode ;";
put @1 "run;";
put;

  %if %length(&by.&groupvars)>0 and &codes ne 1  %then %do; 
  

put @1 "*------------------------------------------------------;";
put @1 "* MERGE COUNTS DATASET WITH 'GROUP TEMPLATE' DATASET   ;";
put @1 "* KEEPING ONLY GROUPING VARIABLES VALUES FROM TEMPLATE ;";
put @1 "*------------------------------------------------------;";
put;


put @1 "proc sort data=&grptemplateds;";
put @1 "  by &by &groupvars;";
put @1 "run;";
put;  
put @1 "proc sort data=&dsin;";
put @1 "  by &by &groupvars;";
put @1 "run;";
put;  
put @1 "data &dsin;";
put @1 "  merge &dsin &grptemplateds (in=__a keep = &by &groupvars);";
put @1 "  by &by &groupvars;";
put @1 "  if not __a then do;";
%if &warn_on_nomatch=1 %then %do;
put @1 "    put 'WAR' 'NING: deleting the following group ;'";
put @1 "'    as not found in codelist :' &tmpgrp;";
%end;
put @1 "    delete;";
put @1 "  end;  ";
put @1 "run;";
put ; 
  %end;
put @1 "*------------------------------------------------------;";
put @1 "* MERGE COUNTS DATASET WITH CODELIST DATASET           ;";
put @1 "* KEEPING ONLY ANALYSIS VARIABLE VALUES FROM TEMPLATE  ;";
put @1 "*------------------------------------------------------;";
put;

put @1 "data &codelistds;";
put @1 "set &codelistds;";
put @1 "if missing(&var) then __order=&missorder; ";
put @1 "run;";
put;

put @1 "proc sort data=&codelistds nodupkey;";
put @1 "  by &by __tby &groupvars __order  &var __grpid &decode ;";
put @1 "run;";
put;
put @1 "proc sort data=&dsin;";
put @1 "  by &by __tby &groupvars   __order &var __grpid &decode ;";
put @1 "run;";
put ;

put @1 "data &dsin;";
put @1 "  merge &dsin &codelistds (in=__a);";
put @1 "  by &by __tby &groupvars   __order &var __grpid &decode ;";
put @1 "  if 0 then do;";
put @1 "    __total=1;";
put @1 "    __missing=0;";
put @1 "  end;";

put @1 "** KEEP ONLY REQUESTED MODLAITIES;";
put @1 "**  and MISSIGN MODALITY AND TOTAL IF REQUESTED;";
put @1 "if not __a and __total ne 1 and __missing ne 1 then do;";
    %if &warn_on_nomatch=1 %then %do;
put @1 "   put 'WAR' 'NING: deleting the following modality ;'";
put @1 "'     as not found in codelist :' &tmpgrp &var.=;";
     %end; 
put @1 "   delete;";
put @1 "end;  ";
%if %length(&remove)>0 %then %do;
length remove $ 2000;
remove = strip(symget("remove"));
put @1 "if __total ne 1  then do;";
put @1 "   if &var  in ( " remove " ) then delete;";
put @1 "end;  ";
%end;

put @1 "run;";
put ;
%end;
%else %do;
put @1 "proc sort data=&dsin;";
put @1 "  by &by __tby &groupvars   __order &var __grpid &decode ;";
put @1 "run;";
put ;

%end;

put;
put @1 "*-----------------------------------------------------------------;";
put @1 "* CREATE DISPLAY OF ANALYSIS VARIABLE;";
put @1 "*-----------------------------------------------------------------;";
put ;
put @1 "data &dsin;";
put @1 "  length __col_0 $ 2000;";
put @1 "  set &dsin;";
put @1 "  by &by __tby &groupvars   __order &var __grpid &decode ;";
put ;
put @1 '  array __col{*} $ 2000 __col_1 -__col_&maxtrt;';
put @1 '  array __cnt{*} __cnt_1 -__cnt_&maxtrt;';
put @1 '  array __colevt{*} $ 2000 __colevt_1 -__colevt_&maxtrt;';
put ;
put @1 "  if 0 then do;";
put @1 "    __total=0;";
put @1 "    __missing=0;";
put @1 "    do __i =1 to dim(__col);";
put @1 "      __cnt[__i]=0;";
put @1 "      __colevt[__i]='';";
put @1 "    end;";
put @1 "   end;";
put ;
put;
put @1 "  __rowtotal=0;";
put @1 "  do __i =1 to dim(__col);";
put @1 "    if __col[__i]='' then __col[__i]='0';";
put @1 "    if __cnt[__i]=.  then __cnt[__i]=0;";
put @1 "    if __colevt[__i]='' then __colevt[__i]='0';";
put @1 "     __rowtotal=__rowtotal+__cnt[__i];";
put @1 "  end;";
put ;
put @1 "  if __missing ne 1 and __total ne 1 then do;";
put @1 "    __col_0 = cats(&var);";
put ;
/*
%if &showmiss ne A %then %do;
*/
%if %index(&aetable, EVENTS)>0 or &showmiss ne A %then %do;
put @1 "    %* THIS CLEARS 0-COUNT ROWS FOR MISSING MODALITY: ;";
put @1 "    if missing(&var) and __rowtotal=0 then delete;";
%end;

put @1 "    if __grpid=999 and  missing(&var) and __col_0 = '' ";
put @1 "       and not first.__grpid then do;";
put @1 "    * __GRPID = 999 CORRESPONDS TO COUNT OF &VAR;";
put @1 "     __col_0 = cats('" "&missdec" "');";
put @1 "     __order = &missorder;";
put @1 "    end;";
put @1 "    else do;";
%if %length(&fmt) %then %do;
put @1 "       __col_0=put(&var, &fmt);";
%end;
%if %length(&decode) %then %do;
put @1 "       __col_0=&decode;";
%end;
put @1 "    end;";
put @1 "  end;";
put @1 "  else if __missing=1 then do;";
put @1 "    __order = &missorder;";
%if &showmiss ne A %then %do;
put @1 "    if missing(&var) and __rowtotal=0 then delete;";
%end;
%if %length(&decode) %then %do;
put @1 "    __col_0=&decode;";
put @1 "    if missing(&var) then __col_0 =" __missdec ";";
%end;
put @1 "    if __col_0='' then __col_0='" "&missdec"  "';";
put @1 "  end;";  
put @1 "__col__0=''; __cnt__0=.; __pct__0=.; __colevt__0='';";
put @1 "if __fordelete=1 then delete;";
put @1 "drop __col__: __cnt__: __pct__: __colevt__:;  ";

put @1 "run;";
put;
put @1 "proc print data = &dsin;";
put "title 'final data from applycodesds';";
put "run;";

run;

%mend;



