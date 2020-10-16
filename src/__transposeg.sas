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

proc sql noprint;
 %do i=1 %to &ncgrps_w_trt;
   %local nline&i;
   select distinct nline into:nline&i separated by ' ' 
    from __varinfo (where=(upcase(name)=upcase("%scan(&cgrps_w_trt,&i, %str( ))")));
 %end;
quit;   


*** UPDATE ___PGMINFO TO STORE NEW  GROUPING VARIABLES;

proc sql noprint;
  update __rrgpgminfo set value="&notinc2" where key = "newgroupby";
  insert into __rrgpgminfo (key, value, id)
    values("newtrt", "&trtvar &inc4", 301);
quit;





data rrgpgmtmp;
length record $ 2000;
keep record;
record=   "*------------------------------------------------------------;"; output;
record=   "* TRANSPOSE DATASET TO PLACE REQUESTED GROUPS IN COLUMNS    ;"; output;
record=   "*------------------------------------------------------------;"; output;
record= " "; output;
%if %upcase(aetable) ne N %then %do;
    record=   "data &dsin;"; output;
    record=   "  set &dsin;"; output;
    record=   "  if __grpid in (&cleargrp) then delete;"; output;
    record=   "run;  "; output;
    record= " "; output;
%end;
record=   "data __all2;"; output;
record=   "set &dsin;"; output;
record=   "length __colx __col0 $ 2000;"; output;
record=   'array cols{*} __col_1-__col_&maxtrt;'; output;
record=   'array cnts{*} __cnt_1-__cnt_&maxtrt;'; output;
record=   'array pcts{*} __pct_1-__pct_&maxtrt;'; output;
record=   'array cevs{*} __colevt_1-__colevt_&maxtrt;'; output;
record=   "  __col0=cats(__col_0);"; output;
/*
record=   '%do i=1 %to &maxtrt;'; output;
record=   '__trtid=&i;'; output;
record=   '__colx = cats(__col_&i);'; output;
record=   '__cnt = __cnt_&i;'; output;
record=   '__pct = __pct_&i;'; output;
record=   '__colevt = __colevt_&i;'; output;
record=   '__nalign = scan(__align, %eval(&i+1), " ");'; output;
record=   = "output; "; output;
record=   '%end;'; output;
*/
record=   'do i=1 to &maxtrt;'; output;
record=   '__trtid=i;'; output;
record=   '__colx = cats(cols[i]);'; output;
record=   '__cnt = cnts[i];'; output;
record=   '__pct = pcts[i];'; output;
record=   '__colevt = cevs[i];'; output;
record=   '__nalign = scan(__align, i+1, " ");'; output;
record=    "output; "; output;
record=   'end;'; output;

record=   "drop __col_: __pct_: __cnt_: __colevt_:;"; output;
record=   "run;"; output;
record=   " "; output;
record=   "***************************************************************;"; output;
record=   "*** GET ALL COMBINATIONS OF __TRTID AND ALL GROUPING VARIABLES ;"; output;
record=   "*** THAT ARE TO BE PLACED IN COLUMNS;"; output;
record=   "*** --- DATASET __ALL5"; output;
record=   "***************************************************************;"; output;
record= " "; output;
record= " "; output;
record=   "proc sort data=__all2 nodupkey out = __all3(keep=&inc1) ;"; output;
record=   "by &inc2;"; output;
record=   "run;"; output;
record= " "; output;
record=   "proc sort data=__all2 nodupkey out = __all4(keep= __trtid) ;"; output;
record=   "by __trtid;"; output;
record=   "run;"; output;
record= " "; output;
record=   "proc sql noprint nowarn;"; output;
record=   "create table __all5 as select * from"; output;
record=   "__all3 cross join __all4;"; output;
record=   "quit;"; output;
record= " "; output;
record=   "proc sort data=__all5;"; output;
record=   "by &inc2_w_trt ;"; output;
record=   "run;"; output;
record= " "; output;
record=   "*** CREATE NEW __NTRTID (COLUMN INDICATOR);"; output;
record= " "; output;
record=   "data __all5;"; output;
record=   "set __all5 end=eof;"; output;
record=   "by &inc2_w_trt;"; output;
record=   "__ntrtid=_n_;"; output;
record=   "if eof then call symput('maxtrt', cats(__ntrtid));"; output;
record=   "run;"; output;
record= " "; output;
record=   "*** MERGE __NTRTID INTO __ALL2 DATASET;"; output;
record= " "; output;
record=   "proc sort data=__all2;"; output;
record=   "by &inc2_w_trt;"; output;
record=   "run;"; output;
record= " "; output;
record=   "data __all6;"; output;
record=   "merge __all2 __all5(in=__a);"; output;
record=   "by &inc2_w_trt;"; output;
record=   "if __a;"; output;
record=   "run;"; output;
record= " "; output;
record=   "proc sort data=__all6;"; output;
record=   "by &varby  __varbylab __tby &notinc1  __grpid  __grptype "; output;
record=   " __blockid __order __labelline __varlabel __vtype __indentlev "; output;
record=   "   __skipline  __col0 ;"; output;
record=   "run;"; output;
record= " "; output;
record=   "proc transpose data=__all6 out=__all7 prefix=__col_;"; output;
record=   "var __colx;"; output;
record=   "by  &varby  __varbylab __tby &notinc1 __grpid  "; output;
record=   "__grptype __blockid __order __labelline __varlabel __vtype "; output;
record=   "   __indentlev __skipline  __col0 ;"; output;
record=   "id __ntrtid;"; output;
record=   "run;"; output;
record= " "; output;
record=   "proc transpose data=__all6 out=__all7a prefix=__al_;"; output;
record=   "var __nalign;"; output;
record=   "by  &varby  __varbylab __tby &notinc1 __grpid __grptype __blockid"; output;
record=   "  __order __labelline __varlabel __vtype __indentlev "; output;
record=   "  __skipline  __col0 ;"; output;
record=   "id __ntrtid;"; output;
record=   "run;"; output;
record= " "; output;
record=   "data &dsin;"; output;
record=   "length __align $ 2000;"; output;
record=   "merge  __all7 __all7a;"; output;
record=   "by &varby  __varbylab __tby &notinc1 __grpid  "; output;
record=   "   __grptype __blockid __order __labelline __varlabel __vtype "; output;
record=   "   __indentlev __skipline __col0;"; output;
record= " "; output;
record=   "array cols{*} __col_:;"; output;
record=   'array al{*} __al_1-__al_&maxtrt;'; output;
record=   "__align='L';"; output;
record=   "do __i=1 to dim(cols);"; output;
record=   "  if __vtype in ('CONT') and compress(cols[__i],',.(): ')='' "; output;
record=   "   then cols[__i]='';"; output;
record=   "  if __vtype in ('CONT') and al[__i]='' then al[__i]='D';"; output;
record=   "  else if al[__i]='' then al[__i]='RD';"; output;
record=   "   __align = trim(left(__align))||' '||trim(left(al[__i]));"; output;
record=   "end;"; output;
record=   "run;"; output;
record= " "; output;
record=   "proc sort data=&dsin;"; output;
record=   "  by &varby __grptype __tby &notinc2 __grpid __blockid __order ;"; output;
record=   "run;"; output;
record= " "; output;
record=   "data &dsin (rename=(__col0=__col_0));"; output;
record=   "  set &dsin;"; output;
record=   "  length __suffix $ 2000;"; output;
record=   "  by &varby __grptype __tby &notinc2 __grpid __blockid __order ;"; output;
record=   "  __tmprowid=_n_;"; output;
record=   "  if last.__blockid then __keepn=0;"; output;
record=   "  else __keepn=1;"; output;
record=   "  if last.__blockid and __skipline='Y' then __suffix='~-2n';"; output;
record=   "  __indentlev = max(0, __indentlev-&ncgrps);"; output;
record=   "run;"; output;
record= " "; output;
record= " "; output;
%if %length(&varby) %then %do;
    record=   "proc sql noprint nowarn;"; output;
    record=   "  create table __all5a as select * from ( select * from __all5)"; output;
    record=   "  cross join "; output;
    record=   "  (select distinct &varby from __poph);"; output;
    record=   "create table __all5 as select * from __all5a;"; output;
    record=   "quit;"; output;
    record= " "; output;
%end;
record=   "*** MERGE GROUPING VARIABLE LABELS INTO UNTRANSPOSED HEADER DATASET;"; output;
record= " "; output;
record=   "proc sort data=__poph;"; output;
record=   "by  &varby __trtid;"; output;
record=   "run;"; output;
record= " "; output;

** if one of the ncgroups has n_line, we need to calculate n;


%local tmptrt;


%do i=1 %to &ncgrps_w_trt;
  
    %if %upcase(%scan(&cgrps_w_trt, &i, %str( )))=%upcase(&trtvar) %then 
      %let tmptrt=&tmptrt __trtid;
    %else %let tmptrt=&tmptrt %scan(&cgrps_w_trt, &i, %str( ));
    

  
    %__getcntg(datain=__dataset, 
          unit=&defreport_subjid, 
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


record= " "; output;
record=   "proc sort data=__all5;"; output;
record=   "by  &varby __trtid;"; output;
record=   "run;"; output;
record= " "; output;
record=   "data __poph;"; output;
record=   "merge __poph __all5;"; output;
record=   "by &varby  __trtid;"; output;
record=   "drop __trtid;"; output;
record=   "run;"; output;
record= " "; output;
record=   "data __poph;"; output;
record=   "set __poph;"; output;
record=   "length __col2 $ 2000;"; output;
record=   "__rowid=&trtrow;"; output;
record=   "__col2=__col;"; output;
%if %upcase(&&nline&trtrow)=Y %then %do;
    record=   "if __nline_&trtrow = . then __nline_&trtrow=0;"; output;
    record=   "if __overall ne 1 then __col2 = cats(__col2,'//(N=', __nline_&trtrow,')');";  output;
%end;
record=   "output;"; output;
record=   "__autospan='N ';"; output;
%do i=1 %to %eval(&trtrow-1);
    record=   "__rowid=&i;"; output;
    record=   '__col2=' ||" %scan(&inc3,&i, %str( ))" || ';' ; output;
    %if %upcase(&&nline&i)=Y %then %do;
        record=   "if __nline_&i = . then __nline_&i=0;"; output;
        record=   "if __overall ne 1 then  __col2 = cats(__col2,'//(N=', __nline_&i,')');";  output;
    %end;
    record=   "output;"; output;
%end;
%do i=&trtrow %to &ncgrps;
    %local j;
    %let j=%eval(&i+1);
        record=   "__rowid=&i+1;"; output;
        record=   "__prefix='';"; output;
        record=   '__col2='|| "%scan(&inc3,&i, %str( ))" || ';'; output;
        %if %upcase(&&nline&j)=Y %then %do;
            record=   "if __nline_&j = . then __nline_&j=0;"; output;
            record=   "if __overall ne 1 then __col2 = cats(__col2,'//(N=', __nline_&j,')');";  output;
        %end;
        record=   "output;"; output;
%end;
record=   "run;"; output;
record= " "; output;
record=   "data __poph;"; output;
record=   "set __poph;"; output;
record=   "__trtid=__ntrtid;"; output;
record=   "__col=__col2;"; output;
record=   "drop __ntrtid __col2;"; output;
record=   "run;"; output;
record= " "; output;
record= " "; output;
record=   "proc sort data=__poph;"; output;
record=   "by __rowid __trtid ;"; output;
record=   "run;"; output;
record= " "; output;
record=   "*--------------------------------------------------------------;"; output;
record=   "* DETERMINE WHICH COLUMNS ARE FOR OVERALL STATISTICS;"; output;
record=   "*--------------------------------------------------------------;"; output;
record= " "; output;
record=   '%local ovcols;'; output;
record=   "proc sql noprint;"; output;
record=   "select distinct __trtid+1 into:ovcols separated by ' '"; output;
record=   " from __poph (where=(__overall=1));"; output;
record=   "quit;"; output;
record= " "; output;
record=   "*--------------------------------------------------------------;"; output;
record=   "* SET MISSING COUNT TO 0 COUNT ;"; output;
record=   "*--------------------------------------------------------------;"; output;
record= " "; output;
record=   "data &dsin;"; output;
record=   " set &dsin;"; output;
record=   "array cols{*} __col_:;"; output;
record=   "do __i=1 to dim(cols);"; output;
record=   "  if __vtype in ('CAT', 'COND') and __i not in "|| '(&ovcols -99)'; output;
record=   "      and cols[__i]='' then cols[__i]='0';"; output;
record=   "end;"; output;
record=   "run;"; output;


*** IF THERE ARE OVERALL STATISTICS, THEN WE SHOUDL NOT SET THEIR VALUES TO 0 WHEN MISSING;


*** UPDATE BREAKOKAT MACRO PARAMETER;


record= " "; output;
record=   "*** UPDATE HEADER AND BREAKOKAT MACRO PARAMETER;"; output;
record=   "proc sort data=__poph;"; output;
record=   "by &inc1_w_trt ;"; output;
record=   "run;"; output;
record= " "; output;
record=   "data __poph;"; output;
record=   "  set __poph;"; output;
record=   "by &inc1_w_trt ;"; output;
record=   "  __cb=.;"; output;
record=   "  if first.&breakvar then __cb=1;"; output;
record=   "run;"; output;
record= " "; output;
record=   "proc sort data=__poph;"; output;
record=   "  by __trtid;"; output;
record=   "run;"; output;
record= " "; output;
record= " "; output;
record=   "proc sql noprint;"; output;
record=   "  select __trtid into:breakokat separated by ' ' "; output;
record=   '    from __poph(where=(__cb=1));'; output;
record=   "quit;"; output;
record= " "; output;
/*record=   '%put breakokat=&breakokat;';*/
record= " "; output;
run;

proc append data=rrgpgmtmp base=rrgpgm;
run;



%exit:

%mend;
