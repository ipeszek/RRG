/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __cutoff(
dsin=,
vinfods=,
trtinfods=,
trtds=,
by=,
groupvars=)/store;


%local dsin vinfods by groupvars mincnt minpct trtinfods trtds;

%local showgrpcnt showemptygroups i grpidminpct grpidmincnt
  grpsrt mincntpctvar;



data __varinfo_cutoff;
  set __varinfo (where=( type ne 'TRT'));
run;

data __varinfo_cutoff;
  set __varinfo_cutoff end=eof;
  __grpid=_n_;
  if eof then __grpid=999;
run;

proc sql;
select name into: grpsrt separated by ' '
  from __varinfo_cutoff where type ne 'TRT'
  order by __grpid;
select name into: mincntpctvar    separated by ''
from __varinfo_cutoff
where not missing (minpct) or not missing (mincnt);
quit;


 
proc sql noprint;
 
  
  select min(__grpid) into:grpidminpct separated by ' ' from __varinfo_cutoff 
    (where=(not missing(minpct)));
  
  select min(__grpid) into:grpidmincnt separated by ' ' from __varinfo_cutoff 
    (where=(not missing(mincnt)));
  
  %if %length(&grpidmincnt)<=0 %then %let grpidmincnt=999;
  %*put 4iza grpidmincnt=&grpidmincnt;
  
  %if %length(&grpidminpct)<=0 %then %let grpidminpct=999;
  %*put 4iza grpidminpct=&grpidminpct;
  
  select trim(left(mincnt)) into:mincnt separated by ' ' from __varinfo_cutoff
  (where=(__grpid=&grpidmincnt));
  select trim(left(minpct)) into:minpct separated by ' ' from __varinfo_cutoff
   (where=(__grpid=&grpidminpct));
  
  select trim(left(showgroupcnt)) into:showgrpcnt 
      separated by ' ' from &vinfods;
  select trim(left(showemptygroups)) into:showemptygroups 
      separated by ' ' from &vinfods;      
quit;




%if %length(&mincnt) or %length(&minpct) %then %do;

      %* DETERMINE CUTOFF COLUMN NUMBER;
      %local currval;
      proc sql noprint;
      select cats("cats(",name,") in (", cutoffcolumn,")") into:currval 
        separated by ' and '
        from &trtinfods (where =(cutoffcolumn ne ''));
      quit;





      %if %length(&currval)>0 %then %do;
          data _null_;
          file "&rrgpgmpath./&rrguri..sas" mod;
          put;
          put;
          put @1 "*---------------------------------------------------------------;";
          put @1 "* DETERMINE COLUMN NUMBER OF COLUMN USED FOR CUTOFF ;";
          put @1 "*---------------------------------------------------------------;";
          put;
          put '%local  mincntstr minpctstr;';
          put;
          put @1 "proc sql noprint;";
          put @1 "   select cats('__cnt_',__trtid) into: mincntstr separated by ' ' ";
          put @1 "     from &trtds (where=(&currval));";
          put @1 "   select cats('__pct_',__trtid) into: minpctstr separated by ' ' ";
          put @1 "     from &trtds (where=(&currval));";

          put @1 "quit;";
          put;
       
          put;

      %end;

      %else %do;

          data _null_;
          file "&rrgpgmpath./&rrguri..sas" mod;
          put;
          put '%local  mincntstr minpctstr;';

          
          put @1 "proc sql noprint;";
          put @1 "   select cats('__cnt_',__trtid) into:mincntstr separated by ' ' ";
          put @1 "       from __trt(where=(__grouped ne 1));";
          put @1 "   select cats('__pct_',__trtid) into:minpctstr separated by ' ' ";
          put @1 "       from __trt(where=(__grouped ne 1));";
          put @1 "quit;";
 
         
          put;
      %end;



      put @1 '%local cntw;';
      put @1 '%let cntw=%sysfunc(countw(&mincntstr, %str( )));';


      put @1 '%if %sysfunc(countw(&mincntstr, %str( )))>1  %then %do;';
      put @1 '    %let mincntstr=%sysfunc(tranwrd(&mincntstr, %str( ), %str(,)));';
      put @1 '    %let mincntstr=%nrbquote(max(&mincntstr.));';
      put @1 '%end;';
      
      put @1 '%if %sysfunc(countw(&minpctstr, %str( )))>1  %then %do;';
      put @1 '    %let minpctstr=%sysfunc(tranwrd(&minpctstr, %str( ), %str(,)));';
      put @1 '    %let minpctstr=%nrbquote(max(&minpctstr.));';
      put @1 '%end;';
      put;
 
      run;


      data _null_;
      file "&rrgpgmpath./&rrguri..sas" mod;
      put;




      put @1 "data &dsin;";
      put @1 "  set &dsin;";
      put @1 '  array cols{*} __col_1-__col_&maxtrt;';
      put @1 '  array  cnt{*} __cnt_1-__cnt_&maxtrt;';
      put @1 '  array  pct{*} __pct_1-__pct_&maxtrt;';
      put @1 '  array __colevt{*} __colevt_1 -__colevt_&maxtrt;';
      put @1 "  if 0 then do;";
      put @1 "      do __i=1 to dim(cnt);";
      put @1 "         cnt[__i]=.;";
      put @1 "         pct[__i]=.;";
      put @1 "         __colevt[__i]='';";
      put @1 "    end;";
      put @1 "  end;";

      %if %upcase(&showgrpcnt) ne Y %then %do;
          put @1 "  if __grpid ne 999 then do;";
          put @1 "    do __i=1 to dim(cols);";
          put @1 "         cols[__i]='';";
          put @1 "         __colevt[__i]='';";
          put @1 "    end;";
          put @1 "    %* CLEARS COUNTS FOR GROUPING VARIABLES:;";
          put @1 "  end;";
      %end;

      put @1 "  if __grpid=999 then do;";
      put @1 "    do __i=1 to dim(cols);";
      put @1 "      if cols[__i]='' then cols[__i]=0;";
      put @1 "    end;";
      put @1 "  end;";
      put @1 "drop __i;";
      put @1 "    run;";
      
      put '%put _all_;';

data _null_;
      file "&rrgpgmpath./&rrguri..sas" mod;
      put;

      put @1 "data &dsin;";
      put @1 "  set &dsin;";
      %if %length(&mincnt) %then %do;
        put @1 "if __grpid= &grpidmincnt  and " '&mincntstr'  " <   &mincnt  then fordelete=1;";
      %end;

      %if %length(&minpct)%then %do;
        put @1 "if __grpid= &grpidminpct  and " '&minpctstr'  " <   &minpct  then fordelete=1;";
      %end;
      put;
      put @1 "run;";
      put;
      put;
      
      
  
put @1 "proc sort data=&dsin;";
put @1 "by &grpsrt  __order;";
put @1 "run;";

put @1 "data &dsin;";
put @1 "  set &dsin;";
put @1 "by &grpsrt  __order;";
put @1 "  retain fordelete2;";
put @1 "  if first.&mincntpctvar then fordelete2=fordelete;";
put @1 "run;";

put @1 "data &dsin;";
put @1 "  set &dsin;";
put @1 "  if fordelete2=1 then delete;";
put @1 "run;";

  



run;

data _null_;
      file "&rrgpgmpath./&rrguri..sas" mod;
      put;

      put @1 "data &dsin;";
      put @1 "  set &dsin;";
      
      %if %upcase(&showemptygroups) = N %then %do;
            put @1 "*------------------------------------------------------------------;";
            put @1 "* DELETE EMPTY GROUPS THAT MAY BE GENERATED BY COUNT/PERCENT CUTOFF;";
            put @1 "*------------------------------------------------------------------;";
            put;
            put @1 "data __catgrpcnt;";
            put @1 "  set &dsin;";
            put @1 "  if __grpid=999;";
            put @1 "  keep &by __tby &groupvars;";
            put @1 "run;";

            %if %length(&groupvars) %then %do;
              
                %local numgroups;
                %let numgroups = %sysfunc(countw(&groupvars, %str( )));
              
                %local tmp tmp2;
                %do i=1 %to &numgroups;
                  %let tmp = &tmp %scan(&groupvars,&i, %str( ));  
                  %let tmp2 = %scan(&tmp,-1,%str( )); 
                  put;
                  put @1 "proc sort data=__catgrpcnt nodupkey ";
                  put @1 "    out=__catgrpcnt2 (keep=&by __tby &tmp);";
                  put @1 "  by &by __tby &tmp;";
                  put @1 "run;";
                  put;
                  put @1 "proc sort data=&dsin;";
                  put @1 "  by &by __tby &tmp ;";
                  put @1 "run;";
                  put;  
                  put @1 "data &dsin;";
                  put @1 "merge &dsin(in=__a) __catgrpcnt2 (in=__b);";
                  put @1 "by &by __tby &tmp ;";
                  put @1 "if __a and (__b or missing(&tmp2));";
                  put @1 "run;";
                  put;
                %end;
                /* end of loop for numgroups;*/
                
            %end;
            /* end of if groupvars exist; */
        
      %end;
      /* end of if showemptygroups is N; */



%end;

%mend;

