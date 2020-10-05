/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __cntsae(
vinfods=,
ds4var=,
ds4pop=,
ds4denom=,
outds=,
unit=,
groupvars=,
varid=,
aetable=,
missorder=,
totorder=)/store;

%* allgrpcnt macro variabel seems to be never initialized nor used anywhere;

%local  vinfods ds4var ds4pop ds4denom  outds unit aetable
        countwhat varid groupvars pctfmt
        decode   var fmt denomvars denomwhere allstat  stat 
        totaltext totalpos totalwhere missorder totorder denomincltrt;



proc sql noprint;
  select trim(left(decode))     into:decode     separated by ' ' from &vinfods;
  select trim(left(name))       into:var        separated by ' ' from &vinfods;
  select trim(left(fmt))        into:fmt        separated by ' ' from &vinfods;
  select trim(left(denom))      into:denomvars  separated by ' ' from &vinfods;
  select trim(left(denomwhere)) into:denomwhere separated by ' ' from &vinfods;
  select upcase(trim(left(denomincltrt))) into:denomincltrt separated by ' ' from &vinfods;
  select trim(left(stat))       into:allstat    separated by ' ' from &vinfods;
  select trim(left(countwhat))  into:countwhat  separated by ' ' from &vinfods;  
  select trim(left(pctfmt))     into:pctfmt     separated by ' ' from &vinfods;
  
  select dequote(trim(left(totaltext))) into:totaltext  separated by ' ' 
    from &vinfods;
  select dequote(trim(left(totalpos)))  into:totalpos   separated by ' ' 
    from &vinfods;  

  select dequote(trim(left(totalwhere)))  into:totalwhere   separated by ' ' 
    from &vinfods;  
quit;

%if %upcase(&countwhat) ne MAX and %length(&totaltext)>0 %then %do;
    %put &WAR.&NING.: TOTAL in event-like tables can only be requested if COUNTWHAT=MAX. Request for TOTAL was ignored.;
    %let totaltext=;
%end;



%if %length(&totalwhere)=0 %then %let totalwhere=%str(1=1);

%let stat=&allstat;
%if %length(&denomwhere)=0  %then %let denomwhere=%str(1=1);

%local i tmp j lasttmp grpvarbl sortmod;
%if %length(&totaltext) %then %do;

      %let tmp=;
      %let j = %sysfunc(countw(&groupvars, %str( )));
      %let j = %eval(&j-1);
      %do i=1 %to &j;
        %let tmp = &tmp %scan(&groupvars, &i, %str( ));
      %end;
      %let grpvarbl=&tmp;
      %let lasttmp = %scan(&groupvars, -1, %str( ));

      %let sortmod=__total;
%end;


%local simplestats simpleorder;
data _null_;
  length __allstat __fname __name __modelname __simple __simpord $ 2000;
  __allstat = upcase(trim(left(symget("stat"))));
  __overall=0;
  __simple='';
  do __i =1 to countw(__allstat, ' ');
    __fname = scan(__allstat,__i,' ');
    if index(__fname,'.')>0 then do;
      __modelname = scan(__fname, 1, '.');
      __name =  scan(__fname, 2, '.');
      __model=1;
    end;
    else do;
      __name = __fname;
      __model=0;
      __simple = trim(left(__simple))||' '||trim(left(__name));
      __simpord= trim(left(__simpord))||' '||cats(__i);
    end;
    __sorder=__i;
    outrecord=" "; output;
  end;
  call symput('simplestats', cats(__simple));
  call symput('simpleorder', cats(__simpord));

run;

%local statf;
%let statf=%str($__rrgbl.);
%if %sysfunc(countw(&simplestats, %str( )))>1 %then %do;
    %let statf = %str($__rrgsf.);
%end;



data rrgpgmtmp;
length record $ 2000;
keep record;
record=" "; output;

%if %length(&totaltext) %then %do;
    record="data __datasetco ;"; output;
    record="set &ds4var;";output;
    record="run;";output;
    record=" "; output;
%end;


%if %index(&aetable, EVENTS)>0  %then %do;
    record="data __datasetce ;"; output;
    record="set &ds4var;"; output;
    record="run;"; output;
    record=" "; output;

    %if %length(&totaltext) %then %do;
        record="data __datasetceo ;"; output;
        record="set &ds4var;"; output;
        record="run;"; output;
        record=" "; output;
    %end;
%end;

    
record="*--------------------------------------------------------------------;"; output;
record="* CALCULATE COUNT OF SUBJECTS;"; output;
record="*--------------------------------------------------------------------;"; output;
record=" "; output;


%if %upcase(&countwhat)=MAX %then %do;

   %__getcntaew(
           datain = &ds4var,
             unit =  &unit, 
            group = __tby &groupvars , 
              var = __order &var &decode,
           trtvar = &by __trtid &trtvars ,
              cnt = __cnt, 
          dataout = &outds.2,
             desc = &desc);
          
      
       

    %if %length(&totaltext) %then %do;
    
       
        record=" "; output;    
        record="*--------------------------------------------------------------------;";output;
        record="* CALCULATE COUNT OF SUBJECTS for &totaltext;";output;
        record="*--------------------------------------------------------------------;";output;
        record=" "; output;
        
        
       %__getcntaew(
               datain = __datasetco ,
               where = (&totalwhere),
               total = Y,
                 unit =  &unit, 
                group = __tby &groupvars , 
                  var = __order &var &decode,
                 desc = &desc,
               trtvar = &by __trtid &trtvars ,
                  cnt = __cnt, 
              dataout = &outds.2b);
          
         
          record=" "; output;
          
          record="data &outds.2;";output;
          record="set &outds.2 &outds.2b (in=__inb);";output;
          record="if __inb then do;";output;
          record="  __total=1;";output;
          record="  &decode = cats('"|| strip("&totaltext")|| "');";output;
          record="end;";output;
        
    
    
    %end;      
%end;

%else %do;
  %__getcntae(
             datain = &ds4var,
               unit =  &unit, 
              group = __tby &groupvars ,
                var = __order &var &decode , 
             trtvar = &by __trtid &trtvars ,
                cnt = __cnt, 
            dataout = &outds.2);
       
       

%end;


record=" "; output;
record=   '%local dsid rc numobs;'; output;
record=   '%let dsid = %sysfunc(open(' || "&outds.2));" ; output;
record=   '%let numobs = %sysfunc(attrn(&dsid, NOBS));';output;
record=   '%let rc = %sysfunc(close(&dsid));';output;
record=" "; output;
record=   '%if &numobs=0 %then %goto '||"exca&varid.;";output;
record=" "; output;
record=" "; output;
record="*-------------------------------------------------;";output;
record="* TRANSPOSE DATA SET WITH COUNTS OF SUBJECTS;";output;
record="*-------------------------------------------------;";output;
record=" "; output;
record="proc sort data=&outds.2;";output;
record="  by &by __tby &groupvars __order   &var __grpid &decode &sortmod;";output;
record="run;";output;
record=" "; output;  
record="proc transpose data=&outds.2 out=__catcnt4 prefix=__cnt_;";output;
record="  by &by __tby &groupvars __order   &var __grpid &decode &sortmod;";output;
record="  id __trtid;";output;
record="  var __cnt;";output;
record="run;";output;
record=" "; output;
record=" "; output; 


    
   

%if %index(&aetable, EVENTS)>0 %then %do;

    
    record=" "; output;
    record="*------------------------------------------------------------;";output;
    record="* CALCULATE COUNT OF EVENTS;";output;
    record="*------------------------------------------------------------;";output;
    

    %if %upcase(&countwhat)=MAX %then %do;
    
       %__getcntaew(
               datain = __datasetce,
                 unit = __eventid, 
                group = __tby &groupvars , 
                  var = __order &var &decode,
               trtvar = &by __trtid &trtvars ,
                  cnt = __cntevt, 
              dataout = __catcntevt);
              
        %if %length(&totaltext) %then %do;
     
             %__getcntae(
                     datain = __datasetceo(where=(&totalwhere)),
                       unit = __eventid,
                      group = __tby &grpvarbl , 
                        var =  &lasttmp,
                     trtvar = &by __trtid &trtvars ,
                        cnt = __cntevt, 
                    dataout = __catcntevtb);
                  
                   
                record=" "; output;
                record="data __catcntevt;";output;
                record="set __catcntevt __catcntevtb (in=__inb);";output;
                record="if __inb then do;";output;
                record="  __total=1;";output;
                record="  &decode = cats('"||"&totaltext"||"');";output;
                record="end;";output;
              
       
            
      %end;                
              
    %end;

    %else %do;
              
       %__getcntae(
                datain = __datasetce,
                  unit = __eventid, 
                 group = __tby &groupvars,
                   var =  __order &var &decode , 
                trtvar = &by __trtid &trtvars ,
                   cnt = __cntevt, 
               dataout = __catcntevt);
    %end;        
           
         
           
   
    record=" "; output;
    record=" "; output;  
    record="*------------------------------------------------------------;";output;
    record="* MERGE COUNT OF SUBJECTS WITH WITH COUNT OF EVENTS;";output;
    record="*------------------------------------------------------------;";output;
    record=" "; output;  output;
    

      
     %__joinds(
          data1 = &outds.2 ,
          data2 = __catcntevt ,
             by = &by __trtid &trtvars __tby &groupvars __order  &var &decode &sortmod __grpid,
      mergetype = OUTER,
        dataout = &outds.2);
              
        
    
      record=" "; output;
      record=" "; output;  
      record=" proc sort data=&outds.2;";output;
      record="   by &by __tby &groupvars __order   &var __grpid &decode &sortmod;";output;
      record=" run;";output;
      record=" "; output;
      record="*------------------------------------------------;";output;
      record="* TRANSPOSE DATA SET WITH COUNTS OF EVENTS;";output;
      record="*-------------------------------------------------;";output;
      record=" "; output;
      record=" "; output;
      record="data &outds.2;";output;
      record="set &outds.2;";output;
      record="length __ce $ 200;";output;
      record="__ce=cats(__cntevt);";output;
      record="run;";output;
      record=" "; output;
      record="proc transpose data=&outds.2 out=__catcnt6 prefix=__colevt_;";output;
      record="      by &by __tby &groupvars __order   &var __grpid &decode &sortmod;";output;
      record="      id __trtid;";output;
      record="      var __ce;";output;
      record="run;";output;
      record=" "; output;
      record=" "; output;
      record="*-------------------------------------------------;";output;
      record="  * MERGE TRANSPOSED DATA SET WITH COUNTS OF EVENTS";output;
      record="    WITH TRANSPOSED DATA SET WITH COUNTS OF SUBJECTS;";output;
      record="*-------------------------------------------------;";output;
      record=" "; output;  
      record="data __catcnt4;";output;
      record="merge __catcnt4 __catcnt6; ";output;
      record="  by &by __tby &groupvars  __order   &var __grpid &decode &sortmod;";output;
      record="run;";output;
      record=" "; output;
      
       

%end;
    



record=" "; output;
record=" "; output;
record="*------------------------------------------------------------;";output;
record="* CALCULATE DENOMINATOR;";output;
record="*------------------------------------------------------------;";output;
record=" "; output;  




%if &denomincltrt=Y %then %do;
  %* default denominator is population count;

  %__getcntg(
            datain = &ds4denom  (where=(&denomwhere)), 
              unit = &unit, 
             group = __tby &by &denomvars __trtid,
               cnt = __denom, 
           dataout = __catdenom);
%end;

%else %do;
  %__getcntg(
          datain = &ds4denom  (where=(&denomwhere)), 
            unit = &unit, 
           group = __tby &by &denomvars ;
             cnt = __denom, 
         dataout = __catdenom);
  
%end;

** todo: currently &denomvars are on top of trtvars;


record=" "; output;
record=" "; output;

%if &denomincltrt=Y %then %do;
    record="proc transpose data=__catdenom out=__catdenom2 prefix=__den_;";output;
    record="    by __tby &by &denomvars;";output;
    record="    id __trtid;";output;
    record="    var __denom;";output;
    record="run;";output;
%end;
    
record=" "; output;
record=" "; output;  
record="*------------------------------------------------------------;";output;
record="* MERGE DENOMINATOR WITH COUNT DATASET;";output;
record="* CREATE DISPLAY OF STATISTICS;";output;
record="*------------------------------------------------------------;";output;
record=" "; output;
record="proc sort data=__catcnt4;";output;
record="by __tby &by &denomvars;";output;
record="run;";output;
record=" "; output;
record="proc sort data=__catdenom2;";output;
record="by __tby &by &denomvars;";output;
record="run;";output;
record=" "; output;


length __stat0 $ 20;
record="data &outds;";output;
record="length __col_0  $ 2000 __stat $ 20;";output;
record="merge __catcnt4 (in=__a) __catdenom2;";output;
record="by __tby &by &denomvars;";output;
record="if __a;";output;
record=" "; output;
record="if 0 then __total=0;";output;
record="if __total ne 1 then __total=0;";output;
record=" "; output;
record=   'array cnt{*} __cnt_1-__cnt_&maxtrt;';output;
record=   'array pct{*} __pct_1-__pct_&maxtrt;';output;
record=   'array denom{*} __den_1-__den_&maxtrt;';output;
record=   'array col{*} $ 2000 __col_1-__col_&maxtrt;';output;


%if %index(&aetable, EVENTS)>0 %then %do;
    record=   'array colevt{*} $ 2000 __colevt_1-__colevt_&maxtrt;';output;
    record=   'array cntevt{*} __cntevt_1-__cntevt_&maxtrt;';output;
    record=   'array pctevt{*} __pctevt_1-__pctevt_&maxtrt;';output;
%end;


%if &denomincltrt ne Y %then %do;
    record=" "; output;
    record=  '  do over denom;';output;
    record=  '    denom=__denom;';output;
    record=  '  end;';output;
    record=" "; output;
%end;
record=" "; output;

record="if missing(&var) and __total ne 1 then do;";output;
record="    __order=&missorder; ";output;
record="    __missing=1; ";output;
record="end;";output;
%if %length(&totaltext) >0 %then %do;
    record="if __total=1 then do;";output;
    record="  __col_0 = cats('" ||strip("&totaltext")||  "');";output;
    record="    __order=&totorder; ";output;
    record="end;";output;
%end;
%local s0 i tmp;
%do i=1 %to %sysfunc(countw(&simplestats, %str( )));
      %let s0 = %qscan(&simplestats,&i,%str( ));   
      %let sord0 = %scan(&simpleorder,1,%str( ));
      __stat0 = quote("&s0");
      record="if __total ne 1 then __col_0 = put(" ||strip(__stat0)||  ", &statf.);";output;
      record="__stat="||strip( __stat0)|| ";";output;
      
      record="do __i=1 to dim(cnt);";output;
         %__fmtcnt(cntvar=cnt[__i], pctvar=pct[__i], 
              denomvar=denom[__i], stat=%nrbquote(&s0), outvar=col[__i],
               pctfmt=&pctfmt);
      record="end;  ";output;
      %if %index(&allgrpcnt, EVENTS)>0 %then %do;
          record="do __i=1 to dim(cnt);";output;
           %__fmtcnt(cntvar=cntevt[__i], pctvar=pctevt[__i], 
              denomvar=denom[___i], stat=N, outvar=colevt[__i], 
              pctfmt=&pctfmt);
           record="end;  ";output;
      %end;
      record="__sid =&sord0;";output;
      record="output;";output;
%end;
record="run;"; output;

record=" "; output;



record= '%exca'|| "&varid.:"; output;
record=" "; output;
run;

proc append data=rrgpgmtmp base=rrgpgm;
run;


%mend;

