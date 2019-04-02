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




data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;

%if %length(&totaltext) %then %do;
  put @1 "data __datasetco ;";
  put @1 "set &ds4var;";
  put @1 "run;";
  put;
%end;


%if %index(&aetable, EVENTS)>0  %then %do;
  put @1 "data __datasetce ;";
  put @1 "set &ds4var;";
  put @1 "run;";
  put;

  %if %length(&totaltext) %then %do;
    put @1 "data __datasetceo ;";
    put @1 "set &ds4var;";
    put @1 "run;";
    put;
  %end;
%end;

    
put @1 "*--------------------------------------------------------------------;";
put @1 "* CALCULATE COUNT OF SUBJECTS;";
put @1 "*--------------------------------------------------------------------;";
put;
run;

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
    
      data _null_;
      file "&rrgpgmpath./&rrguri..sas" mod;
      put;    
      put @1 "*--------------------------------------------------------------------;";
      put @1 "* CALCULATE COUNT OF SUBJECTS for &totaltext;";
      put @1 "*--------------------------------------------------------------------;";
      put;
      run;    
      
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
          
        data _null_;
        file "&rrgpgmpath./&rrguri..sas" mod;
        put;
        
        put @1 "data &outds.2;";
        put @1 "set &outds.2 &outds.2b (in=__inb);";
        put @1 "if __inb then do;";
        put @1 "  __total=1;";
        put @1 "  &decode = cats('" "&totaltext" "');";
        put @1 "end;";
      run;    
    
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

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put @1 '%local dsid rc numobs;';
put @1 '%let dsid = %sysfunc(open(' "&outds.2));";
put @1 '%let numobs = %sysfunc(attrn(&dsid, NOBS));';
put @1 '%let rc = %sysfunc(close(&dsid));';
put;
put @1 '%if &numobs=0 %then %goto '  "exca&varid.;";
put;
put;
put @1 "*-------------------------------------------------;";
put @1 "* TRANSPOSE DATA SET WITH COUNTS OF SUBJECTS;";
put @1 "*-------------------------------------------------;";
put;
put @1 "proc sort data=&outds.2;";
put @1 "  by &by __tby &groupvars __order   &var __grpid &decode &sortmod;";
put @1 "run;";
put;  
put @1 "proc transpose data=&outds.2 out=__catcnt4 prefix=__cnt_;";
put @1 "  by &by __tby &groupvars __order   &var __grpid &decode &sortmod;";
put @1 "  id __trtid;";
put @1 "  var __cnt;";
put @1 "run;";
put;
put; 
run; 
    
   

%if %index(&aetable, EVENTS)>0 %then %do;

    data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    put;
    put @1 "*------------------------------------------------------------;";
    put @1 "* CALCULATE COUNT OF EVENTS;";
    put @1 "*------------------------------------------------------------;";
    run;

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
              
            data _null_;
            file "&rrgpgmpath./&rrguri..sas" mod;
            put;
            put @1 "data __catcntevt;";
            put @1 "set __catcntevt __catcntevtb (in=__inb);";
            put @1 "if __inb then do;";
            put @1 "  __total=1;";
            put @1 "  &decode = cats('" "&totaltext" "');";
            put @1 "end;";
          run;    
        
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
           
         
           
    data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    put;
    put;  
    put @1 "*------------------------------------------------------------;";
    put @1 "* MERGE COUNT OF SUBJECTS WITH WITH COUNT OF EVENTS;";
    put @1 "*------------------------------------------------------------;";
    put;  
    run;
      
     %__joinds(
          data1 = &outds.2 ,
          data2 = __catcntevt ,
             by = &by __trtid &trtvars __tby &groupvars __order  &var &decode &sortmod __grpid,
      mergetype = OUTER,
        dataout = &outds.2);
              
        
      data _null_;
      file "&rrgpgmpath./&rrguri..sas" mod;
      put;
      put;  
      put @1 " proc sort data=&outds.2;";
      put @1 "   by &by __tby &groupvars __order   &var __grpid &decode &sortmod;";
      put @1 " run;";
      put;
      put @1 "*------------------------------------------------;";
      put @1 "* TRANSPOSE DATA SET WITH COUNTS OF EVENTS;";
      put @1 "*-------------------------------------------------;";
      put;
      put;
      put @1 "data &outds.2;";
      put @1 "set &outds.2;";
      put @1 "length __ce $ 200;";
      put @1 "__ce=cats(__cntevt);";
      put @1 "run;";
      put;
      put @1 "proc transpose data=&outds.2 out=__catcnt6 prefix=__colevt_;";
      put @1 "      by &by __tby &groupvars __order   &var __grpid &decode &sortmod;";
      put @1 "      id __trtid;";
      put @1 "      var __ce;";
      put @1 "run;";
      put;
      put;
      put @1 "*-------------------------------------------------;";
      put @1 "  * MERGE TRANSPOSED DATA SET WITH COUNTS OF EVENTS";
      put @1 "    WITH TRANSPOSED DATA SET WITH COUNTS OF SUBJECTS;";
      put @1 "*-------------------------------------------------;";
      put;  
      put @1 "data __catcnt4;";
      put @1 "merge __catcnt4 __catcnt6; ";
      put @1 "  by &by __tby &groupvars  __order   &var __grpid &decode &sortmod;";
      put @1 "run;";
      put;
      run;              

%end;
    


data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put;
put @1 "*------------------------------------------------------------;";
put @1 "* CALCULATE DENOMINATOR;";
put @1 "*------------------------------------------------------------;";
put;  
run;


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

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put;

%if &denomincltrt=Y %then %do;
    put @1 "proc transpose data=__catdenom out=__catdenom2 prefix=__den_;";
    put @1 "    by __tby &by &denomvars;";
    put @1 "    id __trtid;";
    put @1 "    var __denom;";
    put @1 "run;";
%end;
    
put;
put;  
put @1 "*------------------------------------------------------------;";
put @1 "* MERGE DENOMINATOR WITH COUNT DATASET;";
put @1 "* CREATE DISPLAY OF STATISTICS;";
put @1 "*------------------------------------------------------------;";
put;
put @1 "proc sort data=__catcnt4;";
put @1 "by __tby &by &denomvars;";
put @1 "run;";
put;
put @1 "proc sort data=__catdenom2;";
put @1 "by __tby &by &denomvars;";
put @1 "run;";
put;
run;


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
    output;
  end;
  call symput('simplestats', cats(__simple));
  call symput('simpleorder', cats(__simpord));

run;

%local statf;
%let statf=%str($__rrgbl.);
%if %sysfunc(countw(&simplestats, %str( )))>1 %then %do;
%let statf = %str($__rrgsf.);
%end;


data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
length __stat0 $ 20;
put @1 "data &outds;";
put @1 "length __col_0  $ 2000 __stat $ 20;";
put @1 "merge __catcnt4 (in=__a) __catdenom2;";
put @1 "by __tby &by &denomvars;";
put @1 "if __a;";
put;
put @1 "if 0 then __total=0;";
put @1 "if __total ne 1 then __total=0;";
put;
put @1 'array cnt{*} __cnt_1-__cnt_&maxtrt;';
put @1 'array pct{*} __pct_1-__pct_&maxtrt;';
put @1 'array denom{*} __den_1-__den_&maxtrt;';
put @1 'array col{*} $ 2000 __col_1-__col_&maxtrt;';


%if %index(&aetable, EVENTS)>0 %then %do;
put @1 'array colevt{*} $ 2000 __colevt_1-__colevt_&maxtrt;';
put @1 'array cntevt{*} __cntevt_1-__cntevt_&maxtrt;';
put @1 'array pctevt{*} __pctevt_1-__pctevt_&maxtrt;';
%end;


%if &denomincltrt ne Y %then %do;
put;
put @1 '  do over denom;';
put @1 '    denom=__denom;';
put @1 '  end;';
put;
%end;
put;

put @1 "if missing(&var) and __total ne 1 then do;";
put @1 "    __order=&missorder; ";
put @1 "    __missing=1; ";
put @1 "end;";
%if %length(&totaltext) >0 %then %do;
put @1 "if __total=1 then do;";
put @1 "  __col_0 = cats('" "&totaltext"  "');";
put @1 "    __order=&totorder; ";
put @1 "end;";
%end;
%local s0 i tmp;
%do i=1 %to %sysfunc(countw(&simplestats, %str( )));
  %let s0 = %qscan(&simplestats,&i,%str( ));   
  %let sord0 = %scan(&simpleorder,1,%str( ));
  __stat0 = quote("&s0");
  put @1 "if __total ne 1 then __col_0 = put(" __stat0  ", &statf.);";
  put @1 "__stat=" __stat0 ";";
  
  put @1 "do __i=1 to dim(cnt);";
     %__fmtcnt(cntvar=cnt[__i], pctvar=pct[__i], 
          denomvar=denom[__i], stat=%nrbquote(&s0), outvar=col[__i],
           pctfmt=&pctfmt);
  put @1 "end;  ";
  %if %index(&allgrpcnt, EVENTS)>0 %then %do;
     put @1 "do __i=1 to dim(cnt);";
       %__fmtcnt(cntvar=cntevt[__i], pctvar=pctevt[__i], 
          denomvar=denom[___i], stat=N, outvar=colevt[__i], 
          pctfmt=&pctfmt);
     put @1 "end;  ";
  %end;
  put @1 "__sid =&sord0;";
  
  
  put @1 "output;";
%end;
put @1 "run;"; 

put;
put '%exca' "&varid.:";
put;
run;

%mend;

