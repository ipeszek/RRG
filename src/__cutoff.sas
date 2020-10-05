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
  set __varinfo (where=( upcase(strip(type)) not in ('TRT',"'MODEL'")));
run;

data __varinfo_cutoff;
  set __varinfo_cutoff end=eof;
  __grpid=_n_;
  if eof then __grpid=999;
run;

proc sql noprint;
select name into: grpsrt separated by ' '
  from __varinfo_cutoff where type not in ('TRT',"'MODEL'")
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
  %if %length(&grpidminpct)<=0 %then %let grpidminpct=999;
 
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


       data rrgpgmtmp;
        length record $ 2000;
        keep record;


    %if %length(&currval)>0 %then %do;

 
        record=" "; output;
        record=" "; output;
        record= "*---------------------------------------------------------------;"; output;
        record= "* DETERMINE COLUMN NUMBER OF COLUMN USED FOR CUTOFF ;"; output;
        record= "*---------------------------------------------------------------;"; output;
        record=" "; output;
        record= '%local  mincntstr minpctstr;'; output;
        record=" "; output;
        record= "proc sql noprint;"; output;
        record= "   select cats('__cnt_',__trtid) into: mincntstr separated by ' ' "; output;
        record= "     from &trtds (where=(&currval));"; output;
        record= "   select cats('__pct_',__trtid) into: minpctstr separated by ' ' "; output;
        record= "     from &trtds (where=(&currval));"; output;
        record= "quit;"; output;
        record=" "; output;
        record=" "; output;

    %end;

    %else %do;

        record=" "; output;
        record= '%local  mincntstr minpctstr;'; output;
        record= "proc sql noprint;";output;
        record= "   select cats('__cnt_',__trtid) into:mincntstr separated by ' ' ";output;
        record= "       from __trt(where=(__grouped ne 1));";output;
        record= "   select cats('__pct_',__trtid) into:minpctstr separated by ' ' ";output;
        record= "       from __trt(where=(__grouped ne 1));";output;
        record= "quit;";output;
        record=" ";output;

    %end;



    record= '%local cntw;';output;
    record= '%let cntw=%sysfunc(countw(&mincntstr, %str( )));';output;
    record= '%if %sysfunc(countw(&mincntstr, %str( )))>1  %then %do;';output;
    record= '    %let mincntstr=%sysfunc(tranwrd(&mincntstr, %str( ), %str(,)));';output;
    record= '    %let mincntstr=%nrbquote(max(&mincntstr.));';output;
    record= '%end;';output;
    record= '%if %sysfunc(countw(&minpctstr, %str( )))>1  %then %do;';output;
    record= '    %let minpctstr=%sysfunc(tranwrd(&minpctstr, %str( ), %str(,)));';output;
    record= '    %let minpctstr=%nrbquote(max(&minpctstr.));';output;
    record= '%end;';output;
    record=" ";output;
    record=" ";output;
    record= "data &dsin;";output;
    record= "  set &dsin;";output;
    record= '  array cols{*} __col_1-__col_&maxtrt;';output;
    record= '  array  cnt{*} __cnt_1-__cnt_&maxtrt;';output;
    record= '  array  pct{*} __pct_1-__pct_&maxtrt;';output;
    record= '  array __colevt{*} __colevt_1 -__colevt_&maxtrt;';output;
    record= "  if 0 then do;";output;
    record= "      do __i=1 to dim(cnt);";output;
    record= "         cnt[__i]=.;";output;
    record= "         pct[__i]=.;";output;
    record= "         __colevt[__i]='';";output;
    record= "    end;";output;
    record= "  end;";output;
    
    %if %upcase(&showgrpcnt) ne Y %then %do;
        record= "  if __grpid ne 999 then do;";output;
        record= "    do __i=1 to dim(cols);";output;
        record= "         cols[__i]='';";output;
        record= "         __colevt[__i]='';";output;
        record= "    end;";output;
        record= "    %* CLEARS COUNTS FOR GROUPING VARIABLES:;";output;
        record= "  end;";output;
    %end;
    
    record= "  if __grpid=999 then do;";output;
    record= "    do __i=1 to dim(cols);";output;
    record= "      if cols[__i]='' then cols[__i]=0;";output;
    record= "    end;";output;
    record= "  end;";output;
    record= "drop __i;";output;
    record= "    run;";output;
    record=" ";output;
    record= "data &dsin;";output;
    record= "  set &dsin;";output;
    
    %if %length(&mincnt) %then %do;
        record= "if __grpid= &grpidmincnt  and "||strip('&mincntstr')||  " <  &mincnt  then fordelete=1;";output;
    %end;
    %if %length(&minpct)%then %do;
      record= "if __grpid= &grpidminpct  and "||strip('&minpctstr')||  " <   &minpct  then fordelete=1;";output;
    %end;
    
    record=" ";output;
    record= "run;";output;
    record=" ";output;
    record=" ";output;
    record= "proc sort data=&dsin;";output;
    record= "by &grpsrt  __order;";output;
    record= "run;";output;
    record= "data &dsin;";output;
    record= "  set &dsin;";output;
    record= "  by &grpsrt  __order;";output;
    record= "  retain fordelete2;";output;
    record= "  if first.&mincntpctvar then fordelete2=fordelete;";output;
    record= "run;";output;
    record= "data &dsin;";output;
    record= "  set &dsin;";output;
    record= "  if fordelete2=1 then delete;";output;
    record= "run;";output;
    record=" ";output;
    record= "data &dsin;";output;
    record= "  set &dsin;";output;

    %if %upcase(&showemptygroups) = N %then %do;
        record= "*------------------------------------------------------------------;";output;
        record= "* DELETE EMPTY GROUPS THAT MAY BE GENERATED BY COUNT/PERCENT CUTOFF;";output;
        record= "*------------------------------------------------------------------;";output;
        record=" ";output;
        record= "data __catgrpcnt;";output;
        record= "  set &dsin;";output;
        record= "  if __grpid=999;";output;
        record= "  keep &by __tby &groupvars;";output;
        record= "run;";output;

        %if %length(&groupvars) %then %do;
          
            %local numgroups;
            %let numgroups = %sysfunc(countw(&groupvars, %str( )));
          
            %local tmp tmp2;
            %do i=1 %to &numgroups;
              %let tmp = &tmp %scan(&groupvars,&i, %str( ));  
              %let tmp2 = %scan(&tmp,-1,%str( )); 
              record=" ";output;
              record= "proc sort data=__catgrpcnt nodupkey ";output;
              record= "  out=__catgrpcnt2 (keep=&by __tby &tmp);";output;
              record= "  by &by __tby &tmp;";output;
              record= "run;";output;
              record=" ";output;
              record= "proc sort data=&dsin;";output;
              record= "  by &by __tby &tmp ;";output;
              record= "run;";output;
              record=" ";  output;
              record= "data &dsin;";output;
              record= "merge &dsin(in=__a) __catgrpcnt2 (in=__b);";output;
              record= "by &by __tby &tmp ;";output;
              record= "if __a and (__b or missing(&tmp2));";output;
              record= "run;";output;
              record=" ";output;
            %end;
              /* end of loop for numgroups;*/
              
        %end;
        /* end of if groupvars exist; */
      
    %end;
    /* end of if showemptygroups is N; */
  run;


    proc append data=rrgpgmtmp base=rrgpgm;
    run;
%end;

%mend;

