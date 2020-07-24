/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __transposeg(
  dsin=, 
  varby=,
  groupby=,
  trtvar=)/store;

%local dsin  varby groupby trtvar;
%let trtvar=%upcase(&trtvar);

/*
PURPOSE:  IF ONE OR MORE GROUPIGN VARIABLE WAS REQUESTED TO BE PUT IN COLUMNS
          THEN THIS MACRO PERFORMS APPROTIATE TRANSPOSITION OF DATASET &DSIN
          IT ALSO MERGES THIS GROUPING VARIABLES INTO HEADER DATASET __POPH
          
          FINALLY IT REDEFINES GROUPBY MACRO VARIABLE REMOVING THESE GROUPING
          VARIABLES FROM IT AND UPDATES __PGMINFO DATASET WITH THIS INFORMATION
          
          
          IF DATASET __GRPCODES EXISTS, THIS MEANS THAT USER SPECIFIED 
          CODELISTDS  FOR GROUPING VARIABLE. THE ORDER OF MODALITIES OF 
          "IN-C0LUMN" GROUPS WILL BE TAKEN FROM THERE; 
           OTHERWISE IT WILL BE ALPHABETICAL

MACRO PARAMETERS:
DSIN      INPUT DATASET
VARBY     VARBY VARIABLES
GROUPBY   ORIGINAL GROUPBY VARIABLES
trtvar    ORIGINAL TREATMENT VARIABLES
          
NOTES:   
*/



*** DETERMINE WHICH GROUPING VARIABLES ARE TO BE PLACED IN COLUMNS;
*** DETERMINE ORIGINAL ID OF THESE VARIABLES (RELATIVE TO GRP1, GRP2 ETC);
  
%local  cgrps cgrps_w_trt tmp notcgrps allgrps i istrtacross;

proc sql noprint;
  select across into :istrtacross separated by ' '
     from __varinfo (where =(type='TRT'));

  select upcase(name),varid into 
     :allgrps separated by ' ',
     :tmp separated by ' '  
     from __varinfo (where =(type='GROUP'  
       and upcase(page) ne 'Y'))
     order by varid;

  select upcase(name),varid into 
     :cgrps separated by ' ',
     :tmp separated by ' '  
     from __varinfo (where =(type='GROUP' and upcase(across)='Y' 
       and upcase(page) ne 'Y'))
     order by varid;
  select upcase(name), varid into
     :cgrps_w_trt separated by ' ',
     :tmp separated by ' '
      from __varinfo 
      (where =((type='GROUP' and upcase(across)='Y') or type='TRT'))
      order by varid;
   select upcase(name), varid into
     :notcgrps separated by ' ',
     :tmp separated by ' '
      from __varinfo 
      (where =((type='GROUP' and upcase(across) ne 'Y' 
          and upcase(page) ne 'Y')))
      order by varid;      
quit;  



%local cleargrp tmp tmp2 j;
%if %length(&allgrps) %then %do;
  %do i=1 %to %sysfunc(countw(&allgrps,%str( )));
     %let tmp = %scan(&allgrps, &i, %str( ));
     %if %length(&cgrps) %then %do;
       %do j=1 %to %sysfunc(countw(&cgrps,%str( ))); 
         %let tmp2 = %scan(&cgrps, &j, %str( ));
         %if &tmp=&tmp2 %then %let cleargrp = &cleargrp %eval(&i+1);
       %end;  
     %end;
  %end;
%end; 


%local breakvar;
%let breakvar = %scan(&cgrps_w_trt,-2, %str( ));


%if &trtvar=__TRT %then %do;
    %let cgrps_w_trt=__TRT &cgrps;
%end;

%if %length(&cgrps)=0 %then %goto exit;

%local ncgrps ncgrps_w_trt nnotcgrps i inc1 inc2 inc3 inc4 ;
%local inc1_w_trt inc2_w_trt  notinc1 notinc2 notinc3 trtrow;
%let ncgrps=0;
%let ncgrps_w_trt=0;
%let nnotcgrps=0;

%if %length(&cgrps) %then %do;
%let ncgrps = %sysfunc(countw(&cgrps, %str( )));
%end;
%let ncgrps_w_trt = %eval(&ncgrps+1);
%if %length(&notcgrps) %then %do;
%let nnotcgrps = %sysfunc(countw(&notcgrps, %str( )));
%end;
%do i=1 %to &ncgrps;
  %let tmp = %scan(&cgrps, &i, %str( ));
  %let inc1 = &inc1 __order_&tmp &tmp __grplabel_&tmp;
  %let inc2 = &inc2 __order_&tmp &tmp ;
  %let inc3 = &inc3 __grplabel_&tmp;
  %let inc4 = &inc4 &tmp;
%end;

%do i=1 %to &nnotcgrps;
  %let tmp = %scan(&notcgrps, &i, %str( ));
  %let notinc1 = &notinc1 __order_&tmp &tmp __grplabel_&tmp;
  %let notinc2 = &notinc2 __order_&tmp &tmp ;
  %let notinc3 = &notinc3 &tmp;
%end;  

%do i=1 %to &ncgrps_w_trt;
  %let tmp = %scan(&cgrps_w_trt, &i, %str( ));
  %if %upcase(&tmp)=%upcase(&trtvar) %then %do;
     %let inc2_w_trt = &inc2_w_trt __trtid; 
     %let inc1_w_trt = &inc1_w_trt &tmp ;
     %let trtrow=&i;
  %end;   
  %else %do;
     %let inc2_w_trt = &inc2_w_trt __order_&tmp &tmp ;
     %let inc1_w_trt = &inc1_w_trt __order_&tmp &tmp ;
  %end;   
%end;




data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put @1 "*------------------------------------------------------------;";
put @1 "* TRANSPOSE DATASET TO PLACE REQUESTED GROUPS IN COLUMNS    ;";
put @1 "*------------------------------------------------------------;";
put;
run;


*** MAKE DATASET LONG AND SKINNY - RECREATE __TRTID ;
data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
%if %upcase(aetable) ne N %then %do;
put @1 "data &dsin;";
put @1 "  set &dsin;";
put @1 "  if __grpid in (&cleargrp) then delete;";
put @1 "run;  ";
put;
%end;
put @1 "data __all2;";
put @1 "set &dsin;";
put @1 "length __colx __col0 $ 2000;";
put @1 'array cols{*} __col_1-__col_&maxtrt;';
put @1 'array cnts{*} __cnt_1-__cnt_&maxtrt;';
put @1 'array pcts{*} __pct_1-__pct_&maxtrt;';
put @1 'array cevs{*} __colevt_1-__colevt_&maxtrt;';
/*put @1 "  __col0=cats(__suffix)||cats(__col_0);";*/
put @1 "  __col0=cats(__col_0);";
put @1 '%do i=1 %to &maxtrt;';
put @1 '__trtid=&i;';
put @1 '__colx = cats(__col_&i);';
put @1 '__cnt = __cnt_&i;';
put @1 '__pct = __pct_&i;';
put @1 '__colevt = __colevt_&i;';
put @1 "__nalign = scan(__align, &i+1, ' ');";
put @1 "output;";
put @1 '%end;';
put @1 "drop __col_: __pct_: __cnt_: __colevt_:;";
put @1 "run;";
put;
put @1 "***************************************************************;";
put @1 "*** GET ALL COMBINATIONS OF __TRTID AND ALL GROUPING VARIABLES ;";
put @1 "*** THAT ARE TO BE PLACED IN COLUMNS;";
put @1 "*** --- DATASET __ALL5";
put @1 "***************************************************************;";
put;
put;
put @1 "proc sort data=__all2 nodupkey out = __all3(keep=&inc1) ;";
put @1 "by &inc2;";
put @1 "run;";
put;
put @1 "proc sort data=__all2 nodupkey out = __all4(keep= __trtid) ;";
put @1 "by __trtid;";
put @1 "run;";
put;
put @1 "proc sql noprint nowarn;";
put @1 "create table __all5 as select * from";
put @1 "__all3 cross join __all4;";
put @1 "quit;";
put;
put @1 "proc sort data=__all5;";
put @1 "by &inc2_w_trt ;";
put @1 "run;";
put;
put @1 "*** CREATE NEW __NTRTID (COLUMN INDICATOR);";
put;
put @1 "data __all5;";
put @1 "set __all5 end=eof;";
put @1 "by &inc2_w_trt;";
put @1 "__ntrtid=_n_;";
put @1 "if eof then call symput('maxtrt', cats(__ntrtid));";
put @1 "run;";
put;
put @1 "*** MERGE __NTRTID INTO __ALL2 DATASET;";
put;
put @1 "proc sort data=__all2;";
put @1 "by &inc2_w_trt;";
put @1 "run;";
put;
put @1 "data __all6;";
put @1 "merge __all2 __all5(in=__a);";
put @1 "by &inc2_w_trt;";
put @1 "if __a;";
put @1 "run;";
put;
put @1 "proc sort data=__all6;";
put @1 "by &varby  __varbylab __tby &notinc1  __grpid  __grptype ";
put @1 " __blockid __order __labelline __varlabel __vtype __indentlev ";
put @1 "   __skipline  __col0 ;";
put @1 "run;";
put;
put @1 "proc transpose data=__all6 out=__all7 prefix=__col_;";
put @1 "var __colx;";
put @1 "by  &varby  __varbylab __tby &notinc1 __grpid  ";
put @1 "__grptype __blockid __order __labelline __varlabel __vtype ";
put @1 "   __indentlev __skipline  __col0 ;";
put @1 "id __ntrtid;";
put @1 "run;";
put;
put @1 "proc transpose data=__all6 out=__all7a prefix=__al_;";
put @1 "var __nalign;";
put @1 "by  &varby  __varbylab __tby &notinc1 __grpid __grptype __blockid";
put @1 "  __order __labelline __varlabel __vtype __indentlev ";
put @1 "  __skipline  __col0 ;";
put @1 "id __ntrtid;";
put @1 "run;";

put;
put @1 "data &dsin;";
put @1 "length __align $ 2000;";
put @1 "merge  __all7 __all7a;";
put @1 "by &varby  __varbylab __tby &notinc1 __grpid  ";
put @1 "   __grptype __blockid __order __labelline __varlabel __vtype ";
put @1 "   __indentlev __skipline __col0;";
put;
put @1 "array cols{*} __col_:;";
put @1 'array al{*} __al_1-__al_&maxtrt;';
put @1 "__align='L';";
put @1 "do __i=1 to dim(cols);";
put @1 "  if __vtype in ('CONT') and compress(cols[__i],',.(): ')='' ";
put @1 "   then cols[__i]='';";
put @1 "  if __vtype in ('CONT') and al[__i]='' then al[__i]='D';";
put @1 "  else if al[__i]='' then al[__i]='RD';";
put @1 "   __align = trim(left(__align))||' '||trim(left(al[__i]));";
put @1 "end;";
put @1 "run;";
put;
put @1 "proc sort data=&dsin;";
put @1 "  by &varby __grptype __tby &notinc2 __grpid __blockid __order ;";
put @1 "run;";
put ;
put @1 "data &dsin (rename=(__col0=__col_0));";
put @1 "  set &dsin;";
put @1 "  length __suffix $ 2000;";
put @1 "  by &varby __grptype __tby &notinc2 __grpid __blockid __order ;";
put @1 "  __tmprowid=_n_;";
put @1 "  if last.__blockid then __keepn=0;";
put @1 "  else __keepn=1;";
put @1 "  if last.__blockid and __skipline='Y' then __suffix='~-2n';";
put @1 "  __indentlev = max(0, __indentlev-&ncgrps);";
put @1 "run;";
put ;
/*
put @1 "*** ADD &VARBY TO __ALL5 DATASET;";
put @1 "proc sort data=__all2 nodupkey out = __all3(keep=&inc1) ;";
put @1 "by &inc2;";
put @1 "run;";
put;
put @1 "proc sort data=__all2 nodupkey out = __all4(keep=&varby __trtid) ;";
put @1 "by &varby __trtid;";
put @1 "run;";
put;
put @1 "proc sql noprint;";
put @1 "create table __all5 as select * from";
put @1 "__all3 cross join __all4;";
put @1 "quit;";
put;
*/
put;
%if %length(&varby) %then %do;
put @1 "proc sql noprint nowarn;";
put @1 "  create table __all5a as select * from ( select * from __all5)";
put @1 "  cross join ";
put @1 "  (select distinct &varby from __poph);";
put @1 "create table __all5 as select * from __all5a;";
put @1 "quit;";
put;
%end;
put @1 "*** MERGE GROUPING VARIABLE LABELS INTO UNTRANSPOSED HEADER DATASET;";
put;
put @1 "proc sort data=__poph;";
put @1 "by  &varby __trtid;";
put @1 "run;";
put ;
run;

** if one of the ncgroups has n_line, we need to calculate n;


proc sql noprint;
 %do i=1 %to &ncgrps_w_trt;
   %local nline&i;
   select distinct nline into:nline&i separated by ' ' 
    from __varinfo (where=(upcase(name)=upcase("%scan(&cgrps_w_trt,&i, %str( ))")));
    
 %end;
quit;   


/*
%if &istrtacross=N %then %do;
  %let cgrps_w_trt = &cgrps &trtvar;
%end;

%* does not work;
*/
%local tmptrt;


  %do i=1 %to &ncgrps_w_trt;
  
    %if %upcase(%scan(&cgrps_w_trt, &i, %str( )))=%upcase(&trtvar) %then 
     %let tmptrt=&tmptrt __trtid;
     
    %else %let tmptrt=&tmptrt %scan(&cgrps_w_trt, &i, %str( ));
    
  ** CODE MODIFICATION 21AUG2010;
  /*
    %__getcntg(datain=__dataset, 
          unit=&subjid, 
          group=&varby &tmptrt,
          cnt=__nline_&i, 
          dataout=__nline_&i);




    %__joinds(
    data1=__all5, 
    data2=__nline_&i, 
    by=&varby &tmptrt,
    dataout=__all5, cond=,
    mergetype=left);

  */
  
    %__getcntg(datain=__dataset, 
          unit=&subjid, 
          group=&varby4pop &tmptrt,
          cnt=__nline_&i, 
          dataout=__nline_&i);




    %__joinds(
    data1=__all5, 
    data2=__nline_&i, 
    by=&varby4pop &tmptrt,
    dataout=__all5, cond=,
    mergetype=left);

 %end;







data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put @1 "proc sort data=__all5;";
put @1 "by  &varby __trtid;";
put @1 "run;";
put ;
put @1 "data __poph;";
put @1 "merge __poph __all5;";
put @1 "by &varby  __trtid;";
put @1 "drop __trtid;";
put @1 "run;";
put;
put @1 "data __poph;";
put @1 "set __poph;";
put @1 "length __col2 $ 2000;";
put @1 "__rowid=&trtrow;";
put @1 "__col2=__col;";
%if %upcase(&&nline&trtrow)=Y %then %do;
put @1 "if __nline_&trtrow = . then __nline_&trtrow=0;";
put @1 "if __overall ne 1 then __col2 = cats(__col2,'//(N=', __nline_&trtrow,')');"; 
%end;

put @1 "output;";

put @1 "__autospan='N ';";
%do i=1 %to %eval(&trtrow-1);
put @1 "__rowid=&i;";
put @1 "__col2=" "%scan(&inc3,&i, %str( ));" ";";
%if %upcase(&&nline&i)=Y %then %do;
put @1 "if __nline_&i = . then __nline_&i=0;";
put @1 "if __overall ne 1 then  __col2 = cats(__col2,'//(N=', __nline_&i,')');"; 
%end;
put @1 "output;";
%end;
%do i=&trtrow %to &ncgrps;
%local j;
%let j=%eval(&i+1);

put @1 "__rowid=&i+1;";
put @1 "__prefix='';";
put @1 "__col2=" "%scan(&inc3,&i, %str( ));" ";";
%if %upcase(&&nline&j)=Y %then %do;
put @1 "if __nline_&j = . then __nline_&j=0;";
put @1 "if __overall ne 1 then __col2 = cats(__col2,'//(N=', __nline_&j,')');"; 
%end;

put @1 "output;";
%end;

put @1 "run;";
put ;
put @1 "data __poph;";
put @1 "set __poph;";
put @1 "__trtid=__ntrtid;";
put @1 "__col=__col2;";
put @1 "drop __ntrtid __col2;";
put @1 "run;";
put ;
put ;
put @1 "proc sort data=__poph;";
put @1 "by __rowid __trtid ;";
put @1 "run;";
put;
put @1 "*--------------------------------------------------------------;";
put @1 "* DETERMINE WHICH COLUMNS ARE FOR OVERALL STATISTICS;";
put @1 "*--------------------------------------------------------------;";
put;
put @1 '%local ovcols;';
put @1 "proc sql noprint;";
put @1 "select distinct __trtid+1 into:ovcols separated by ' '";
put @1 " from __poph (where=(__overall=1));";
put @1 "quit;";
put;
put @1 "*--------------------------------------------------------------;";
PUT @1 "* SET MISSING COUNT TO 0 COUNT ;";
put @1 "*--------------------------------------------------------------;";
put;
put @1 "data &dsin;";
put @1 " set &dsin;";
put @1 "array cols{*} __col_:;";
put @1 "do __i=1 to dim(cols);";
put @1 "  if __vtype in ('CAT', 'COND') and __i not in " '(&ovcols -99)';
put @1 "      and cols[__i]='' then cols[__i]='0';";
put @1 "end;";
put @1 "run;";
put ;
run;

*** IF THERE ARE OVERALL STATISTICS, THEN WE SHOUDL NOT SET THEIR VALUES TO 0 WHEN MISSING;


*** UPDATE BREAKOKAT MACRO PARAMETER;

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;  
put;
put @1 "*** UPDATE HEADER AND BREAKOKAT MACRO PARAMETER;";
put @1 "proc sort data=__poph;";
put @1 "by &inc1_w_trt ;";
put @1 "run;";
put ;
put @1 "data __poph;";
put @1 "  set __poph;";
put @1 "by &inc1_w_trt ;";
put @1 "  __cb=.;";
put @1 "  if first.&breakvar then __cb=1;";
put @1 "run;";
put ;
put @1 "proc sort data=__poph;";
put @1 "  by __trtid;";
put @1 "run;";
put;
put ;
put @1 "proc sql noprint;";
put @1 "  select __trtid into:breakokat separated by ' ' ";
put @1 '    from __poph(where=(__cb=1));';
put @1 "quit;";
put;
put @1 '%put breakokat=&breakokat;';
put ;
run;

*** UPDATE ___PGMINFO TO STORE NEW  GROUPING VARIABLES;

proc sql noprint;
  update __rrgpgminfo set value="&notinc2" where key = "newgroupby";
  insert into __rrgpgminfo (key, value, id)
    values("newtrt", "&trtvar &inc4", 301);
quit;



%exit:

%mend;
