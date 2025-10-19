/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 
 13Nov2023 fixed length of display variable when total is used
 */
 /* some macro variables used inside:
 
 vinfods : __varinfo where varid=&varid
 ds4var  : __datasetc: __dataset where defreport_tabwhere and addcatvar.where
 ds4denom: __dataset (rrg_defreport where &popwhere)
groupvars: all group vars with page ne Y and aegroup=y
notaegroupvars: group vars with page ne Y and aegroup ne Y
byvars:         all group variables with page=Y 
unit:         &defreport_subjid __theid (unless rrg_addcatvar.asubjid is spcified - then asubjid __theid) 
aetable:     &defreport_aetable : if rrg_defreport=Events then takes values EVENTS | EVENTSES| EVENTSSE|Y (no events)
outds:  __catcn4

&missorder       999999 if __catv.misspos is not specifed, 
                 else 999998 if misspos=last, 
                 else -999999 if misspos=first, 
                 else %scan(misspos,1, %str( )) 
                 
&totorder        0 if __catv.totalpos is not specifed, 
                 else 999997 if totalpos=last, 
                 else 0 if totalpos=first, 
                 else %scan(totalpos,1, %str( ))                  
 
 */

%macro __cntsaepy(
vinfods=,
ds4var=,
ds4pop=,
ds4denom=,
outds=,
unit=,
groupvars=,
byvars=,
notaegroupvars=,
varid=,
aetable=,
missorder=,
totorder=)/store;



%* allgrpcnt macro variabel seems to be never initialized nor used anywhere;
%* notaegroupvars: thouse are grouping variables that are not to be treated as "AE" - that is, group vounts are not shown;

%local  vinfods ds4var ds4pop ds4denom  outds unit aetable
        countwhat varid groupvars pctfmt byvars notaegroupvars
        decode   var fmt denomvars denomwhere allstat  stat 
        totaltext totalpos totalwhere missorder totorder denomincltrt
        pydec pyrdec multiplier;

%if %length(&groupvars) %then %let groupvars=%sysfunc(compbl(&groupvars));
%local rgroupvars i;

%let rgroupvars=;

%if %length(&groupvars) or %length(&var) %then %do;
  %do i=1 %to %sysfunc(countw(&groupvars &var));
  %let rgroupvars = %scan(&groupvars &var, &i) &rgroupvars;
  %end;
  %let rgroupvars = %sysfunc(tranwrd (&rgroupvars, %str( ), %str(,)));
%end;

%* determine whether cutoff was requested;
data __varinfo_cutoff;
  set __varinfo (where=( upcase(strip(type)) not in ('TRT',"'MODEL'",'NEWTRT')));
run;

data __varinfo_cutoff;
  set __varinfo_cutoff end=eof;
  __grpid=_n_;
  if eof then __grpid=999;
run;

%local grpsrt mincntpctvar grpidminpct mincnt minpct;

proc sql noprint;
select name into: grpsrt separated by ' '
  from __varinfo_cutoff where type not in ('TRT',"'MODEL'", 'NEWTRT')
  order by __grpid;
select name into: mincntpctvar    separated by ''
from __varinfo_cutoff
where not missing (minpct) or not missing (mincnt);


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
  
 /*  select trim(left(showgroupcnt)), trim(left(showemptygroups)) */
/*    into :showgrpcnt  separated by ' ', :showemptygroups  separated by ' '  */
/*    from &vinfods; */
    
quit;



%if %length(&mincnt) or %length(&minpct) %then %do;

      %* DETERMINE CUTOFF COLUMN NUMBER;
      %local currval;
      proc sql noprint;
      select  cutoffcolumn into:currval separated by ' '
        from __trtinfo (where =(cutoffcolumn ne ''));
      quit;
      
      
      
%end;

%* if currval=total then handle accordingly;

%local freqsort sortcolumn;
*----------------------------------------------------------------------;
proc sql noprint;
  
select
  trim(left(decode))                                  ,
  trim(left(name))                                    ,
  trim(left(fmt))                                     ,
  trim(left(denom))                                   ,
  trim(left(denomwhere))                              ,
  upcase(trim(left(denomincltrt)))                    ,
  upcase(trim(left(stat)))                            ,
  trim(left(countwhat))                               ,
  trim(left(pctfmt))                                  ,
  dequote(trim(left(totaltext)))                      ,
  dequote(trim(left(totalpos)))                       ,
  dequote(trim(left(totalwhere)))                     ,
  upcase(trim(left(freqsort)))                        ,
  upcase(trim(left(sortcolumn)))                      

  
into
  :decode                                             separated by ' ' ,
  :var                                                separated by ' ' ,
  :fmt                                                separated by ' ' ,
  :denomvars                                          separated by ' ' ,
  :denomwhere                                         separated by ' ' ,
  :denomincltrt                                       separated by ' ' ,
  :allstat                                            separated by ' ' ,
  :countwhat                                          separated by ' ' ,
  :pctfmt                                             separated by ' ' ,
  :totaltext                                          separated by ' ' ,
  :totalpos                                           separated by ' ' ,
  :totalwhere                                         separated by ' ' ,
  :freqsort                                           separated by ' ' ,
  :sortcolumn                                         separated by ' ' 

from &vinfods;  
  
 
quit;


%if %upcase(&countwhat)=MAX %then %let defreport_ae_max=Y;

%put DEBUG INFO totalpos=&totalpos totaltext=&totaltext;

%if %upcase(&countwhat) ne MAX and %length(&totaltext)>0 %then %do;
    /*    %put &WAR.&NING.: TOTAL in event-like tables can only be requested if COUNTWHAT=MAX. Request for TOTAL was ignored.; */
    /*     %let totaltext=; */
    /*     %let totalpos=; */
    %* create total category;

    %local dsid rc vnum vtype vtyped vlen vlend;
    %let dsid = %sysfunc(open(&defreport_dataset));
    %let vnum = %sysfunc(varnum(&dsid,&var));
    %let vtype=%sysfunc(vartype(&dsid, &vnum));
    %let vlen = %sysfunc(varlen(&dsid, &vnum));
    %if %length(&decode) %then %do;
      %let vnum = %sysfunc(varnum(&dsid,&decode));
      %let vtyped=%sysfunc(vartype(&dsid, &vnum));
      %let vlend = %sysfunc(varlen(&dsid, &vnum));
    %end;  
    %let rc = %sysfunc(close(&dsid));
 

    data rrgpgmtmp;
    length record $ 2000;
    keep record;
    
    %if &vtype=N %then %do;   
       %* cat variable is numeric;  
       %if %upcase(&totalpos) ne FIRST and %upcase(&totalpos) ne LAST %then  %do;
          record="  %let   val4total=&totalpos;                                        "; output  ;
          record="                                                                      "; output;       
       %end;
       %else %if  %upcase(&totalpos) = FIRST %then %do;
         record="  proc sql;                                                           "; output  ;
         record="    select max(&var)-1 into: val4total separated by ' ' from &ds4var; "; output;
         record="  quit;                                                               "; output;
         record="                                                                      "; output;       
        %end;
       %else %if  %upcase(&totalpos) = LAST %then %do;
         record="  proc sql;                                                           "; output  ;
         record="    select max(&var)+1 into: val4total separated by ' ' from &ds4var; "; output;
         record="  quit;                                                               "; output;
         record="                                                                      "; output;       
        %end;
    %end;
    %else %do;
       %let val4total=&totaltext;
       %if &vlen<%length(&val4total) %then %let vlen=%length(&val4total);
    %end;      
    
    
    %if %length(&decode)>0 and &vtype=N %then %do;    
      %* decode provided,  if length < length of totaltext; 
      %*    then decode var length needs to be adjusted;
      %if &vlend<%length(&totaltext) %then %let vlend=%length(&totaltext);
      record=""; output;
      record="  data &ds4var;                                        "; output;
      record="  length &decode $ &vlend;                             "; output;
      record="    set &ds4var;                                       "; output;
      record="    output;                                            "; output;
      record="    &var="||'&val4total;'                               ; output;
      record="    &decode='"||"&totaltext"||"';                      "; output;
      record="    output;                                            "; output;
      record="  run;                                                 "; output;                  
      record="                                                       "; output          
    %end;

    %else %if %length(&decode)>0 and &vtype=C %then %do;    
      %* var is categorical;
      %* var length needs to be adjusted;
      %if &vlend<%length(&totaltext) %then %let vlend=%length(&totaltext);      
      %if &vlen<%length(&totaltext) %then %let vlen=%length(&totaltext);      
      record=""; output;
      record="  data &ds4var;                                        "; output;
      record="  length &decode $ &vlend &var $ &vlen;                "; output;
      record="    set &ds4var;                                       "; output;
      record="    output;                                            "; output;
      record="    &var='"||"&totaltext"||"';                         "; output;  
      record="    &decode='"||"&totaltext"||"';                      "; output;
      record="    output;                                            "; output;
      record="  run;                                                 "; output;                  
      record="                                                       "; output          
    %end;
    %else %if &decode= and &vtype=C %then %do;    
    %* no decode;
      %* var is categorical;
      %* var length needs to be adjusted;
      %if &vlen < 7 %then %let vlen = 7;
      %let vlend=%length(&totaltext);
      record=""; output;
      record="  data &ds4var;                                        "; output;
      record="  length &decode $ &vlend &var $ &vlen;                "; output;
      record="    set &ds4var;                                       "; output;
      record="    output;                                            "; output;
      record="    &var='"||"&totaltext"||"';                         "; output;  
      record="    output;                                            "; output;
      record="  run;                                                 "; output;                  
      record="                                                       "; output          
    %end;    
   %else %if &decode= and &vtype=N %then %do;    
    %* no decode;
      %* var is numeric;

      record="                                                       "; output;
      record="  data &ds4var;                                        "; output;
      record="  length &decode $ &vlend &var $ &vlen;                "; output;
      record="    set &ds4var;                                       "; output;
      record="    output;                                            "; output;
      record="    &var="||'&val4total;'                               ; output;  
      record="    output;                                            "; output;
      record="  run;                                                 "; output;                  
      record="                                                       "; output          
    %end;        
    run;

    proc append data=rrgpgmtmp base=rrgpgm;
    run;


%end;
     
%put DEBUG INFO totalpos=&totalpos totaltext=&totaltext; 
     
%local pydec pyrdec onsetvar onsettype patyearvar patyearunit refstartvar refstarttype;



%put DEBUG INFO allstat=&allstat;

%* process PY information;

%if %index(%upcase(&allstat), PY) %then %do;


    %*-----------------------------------------------------------------------------------------;
    %* check if __pyrinfo dataset exist and store the values pf  pyr params;

      


    %if  %sysfunc(exist(__pyrinfo)) =0 %then %do;

      %put &er.&ror.: PY or PYR statistics are requested but RRG_DEFINE_PYR macro has not been called;
      %put PLEASE RUN THIS MACRO AND PROVIDE THE REQUIRED PARAMETERS:;
      %PUT pydec         = /* number of decimals for total patient-years */ ;
      %PUT pyrdec        = /* number of decimals for Patient-year rate   */ ;
      %PUT onsetvar     = /* name of variable  for onset of 1st AE occurence, e.g. ASTDT or ASTDY*/ ;
      %PUT onsettype     = /* type of variabe for onset of 1st AE occurence, DAY or DATE */ ;
      %PUT patyearvar    = /* name of variable with patient-year, e.g. PTYEAR */ ;
      %PUT patyearunit   = /* unit of variable with patient-year, YEAR or MONTH or WEEK or DAY */ ;
      %PUT refstartvar   = /* name of reference variable to calculate time to event if provided in DATE format, e.g. TRTSDT */ ;
      %PUT refstarttype  = /* type of reference variable, DAY or DATE */ ;

      %abort abend;
    %end;


    %else %do;
      
     

      data __pyrinfo;
        set __pyrinfo;
        call symput("pydec"             , strip(pydec          ));
        call symput("pyrdec"            , strip(pyrdec         ));
        call symput("onsetvar"          , strip(onsetvar       ));
        call symput("onsettype"         , strip(onsettype      ));
        call symput("patyearvar"        , strip(patyearvar     ));
        call symput("patyearunit"       , strip(patyearunit    ));
        call symput("refstartvar"       , strip(refstartvar    ));
        call symput("refstarttype"      , strip(refstarttype   ));
        call symput("multiplier"      , strip(multiplier   ));
      run;
      
      %if &freqsort=Y and &sortcolumn=__PYR %then %do;
        
        data __varinfo;
          set __varinfo;
          if type='GROUP' and upcase(freqsort)='Y' and sortcolumn='' then sortcolumn='__PYR';        
      %end;  
      
      %if &freqsort=Y and &sortcolumn ne __PYR %then %do;
        
        data __varinfo;
          set __varinfo;
          if type='GROUP' and upcase(freqsort)='Y' and sortcolumn='' then sortcolumn='__CNT';   
          if type='CAT' and upcase(name)=upcase("&var")  and sortcolumn='' then sortcolumn='__CNT'   ;
      %end;  

    %end;
    
%end;    

%if &pydec= %then %let pydec=1;
%if &pyrdec= %then %let pyrdec=3;

%*-----------------------------------------------------------------------------------------;


%if %length(&totalwhere)=0 %then %let totalwhere=%str(1=1);

%let stat=&allstat;
%if %length(&denomwhere)=0  %then %let denomwhere=%str(1=1);

%local i tmp j lasttmp grpvarbl sortmod;
%if %length(&totaltext) or %length(&totalpos) %then %do;

      %let tmp=;
      %let j = %sysfunc(countw(&grpvarbl, %str( )));
      %let j = %eval(&j-1);
      %do i=1 %to &j;
        %let tmp = &tmp %scan(&groupby4ae, &i, %str( ));
      %end;
      %let grpvarbl=&tmp;
      %let lasttmp = %scan(&groupby4ae, -1, %str( ));

      %let sortmod=__total;
%end;

%put DEBUG INFO grpvarbl=&grpvarbl;

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

data __statnames;
  length statnames $ 200;
  statnames=symget("simplestats");
run;

%local statf;
%let statf=%str($__rrgbl.);
%if %sysfunc(countw(&simplestats, %str( )))>1 %then %do;
    %let statf = %str($__rrgsf.);
%end;

/* mld is the maximum length of decode variable */

%local mld;
%let mld=1;

%* if cutoff requested, create cutoff statement;
%* e,g." __cnt_1>5 and __cnt_99">=5  or "__pct_99>=10";

%local   tmp cutoffvarlist cutoffval cutofftype cutofftrtvals;  



proc sql noprint;
      
select max(varid) into: tmp separated by ' ' from __varinfo (where=(not missing(cutoffval)));
      %* tmp if varid correponding to variable or group variable to apply cutoff;
      %* normally this would be current variable;
      %* for ae by severity it is to be applied to last groupig variable - that is, any grade;
      
%if %length(&tmp) %then %do;
        
  select cutoffval, cutofftype into: cutoffval separated by ' ', :cutofftype  separated by ' '
          from __varinfo (where=(varid=&tmp ));
        %* this is cuttof value and type (count or percent); 
        
  select name into: cutoffvarlist separated by ' '
          from __varinfo (where=(varid<=&tmp and type in ('GROUP','CAT')));
        %* this is lst ov variables to get "by" count;
          
  select cutoffcolumn into: cutofftrtvals separated by ' ' 
          from __trtinfo (where =(cutoffcolumn ne ''));

  quit;        


%end;
quit;




    
%put DEBUG INFO: cutoffvarlist=&cutoffvarlist;  




data rrgpgmtmp;
length record $ 2000;
keep record;
record="data __hold ;"; output;
record="set &ds4var;";output;
record="run;";output;
record=" "; output;


%* if cutoff was requested, remove &var below specified threshold;
    
%if %length(&cutoffval)=0 %then %goto skipcutoff;  

%*prepare cutoff statement;

record="%local  cutofftrtids cutoffstmt;"; output;
record="proc sql noprint;"; output;    
record="  select __trtid into: cutofftrtids separated by ',' from __pop (where=(&trtvars in (&cutofftrtvals)));"; output;    
record="quit;"; output;    

record=" "; output;                 
output; record="data __tmp;    "; output;
record='  do i=&cutofftrtids;'; output;
record="    output;"; output;
record="  end;"; output;
record="run;       "; output;
record=" "; output;
record="proc sql noprint;"; output;
%if %upcase(&cutofftype)=PCT %then %do;
record="  select '__pct_'||strip(put(i, best.))||'>=" ||"&cutoffval"||"' into: cutoffstmt separated by ' and '"; output;
%end;
%else %do;
record="  select '__cnt_'||strip(put(i, best.))||'>=" ||"&cutoffval"||"' into: cutoffstmt separated by ' and '"; output;  
%end;
record="        from __tmp ; "; output;
record="quit;     "; output;
record="       "; output;


%* calculate counts ;  
%__getcntg(  
                      datain = &ds4var,   
                        unit = &unit,   
                       group = __tby &cutoffvarlist __trtid,  
                         cnt = __cnt,   
                     dataout = __forcutoff);   
                     
         
    
%if &cutofftype=PCT %then %do;                       
%* calculate denominator ;        
    
        %if &denomincltrt=Y %then %do;  
    
            %__getcntg(  
                    datain = &ds4denom  (where=(&denomwhere)),   
                      unit = &unit,   
                     group = __tby &byvars __trtid &denomvars ,  
                       cnt = __denom,   
                   dataout = __cutoffdenom);  
        %end;  
    
        %else %do;  
            %__getcntg(  
                  datain = &ds4denom  (where=(&denomwhere)),   
                    unit = &unit,   
                   group = __tby &byvars &denomvars ;  
                     cnt = __denom,   
                 dataout = __cutoffdenom);  
            
        %end;  
 
        %* merge counts with denominator and calculate percents;
        
        record="proc sql noprint;"; output;
        record="  create table __forcutoff2 as select * from __forcutoff natural left join __cutoffdenom;"; output;
        record="quit;"; output;
        record=" "; output;
        record="data __forcutoff2;"; output;
        record="  set __forcutoff2;"; output;
        record="  __pct=100*__cnt/__denom;"; output;
        record="run;"; output;
        record=" "; output;
        
        %* transpose to get treatments in columns;
        record="proc sort data=__forcutoff2;"; output;
        record="  by __tby &cutoffvarlist;"; output;
        record="run;"; output;
        record=" "; output;
        record="proc transpose data=__forcutoff2 out=__forcutoff3 prefix=__pct_;"; output;
        record="  by __tby &cutoffvarlist;"; output;
        record="  id __trtid;"; output;
        record="  var __pct;"; output;
        record="run;"; output;
        record=" "; output;
        
        %* keep only records above specified threshold;
        record="data  __forcutoff_fin;"; output;
        record="  set __forcutoff3 ;"; output;
        record='  if &cutoffstmt ;'; output;
        record="  keep __tby &cutoffvarlist;"; output;
        record="run;  "; output;
        record=" "; output;

%end;

%else %do;
  
        record="proc sort data=__forcutoff out=__forcutoff2;"; output;
        record="  by __tby &cutoffvarlist;"; output;
        record="run;"; output;
        record=" "; output;
        %* transpose to get treatments in columns;
        record="proc transpose data=__forcutoff2 out=__forcutoff3 prefix=__cnt_;"; output;
        record="  by __tby &cutoffvarlist;"; output;
        record="  id __trtid;"; output;
        record="  var __cnt;"; output;
        record="run;"; output;
        record=" "; output;
        %* keep only records above specified threshold;
        record="data  __forcutoff_fin;"; output;
        record="  set __forcutoff3; "; output;
        record='  if &cutoffstmt ;'; output;
        record="  keep __tby &cutoffvarlist;"; output;
        record="run;  "; output;
        record=" "; output;

%end;          
          
record="proc sql noprint;"; output;
record="  create table &ds4var as select * from __hold natural right join  __forcutoff_fin;"; output;  
record="quit;                                       "; output;  
record="                                           "; output;  

%skipcutoff:


%if %index(&aetable, EVENTS)>0  %then %do;
    record="data __datasetce ;"; output;
    record="set &ds4var;"; output;
    record="run;"; output;
    record=" "; output;

    %if %length(&totaltext) or %length(&totalpos) %then %do;
        record="data __datasetceo ;"; output;
        record="set &ds4var;"; output;
        record="run;"; output;
        record=" "; output;
    %end;
%end;




%if %index(%upcase(&allstat), PY) %then %do;
      
      %* create  PY variables according to PY setup information;

      record=' '; output; 
      record="data __dataset; "; output;
      record="set __dataset; "; output;

      %if %upcase(&patyearunit)=MONTH %then %do;
        record="__patdays= 30.4375*"||&patyearvar||";" ; output;
      %end;
      %else   %if %upcase(&patyearunit)=WEEK %then %do;
        record="__patdays= 7*"||&patyearvar||";" ; output;
      %end;
      %else   %if %upcase(&patyearunit)=DAY %then %do;
        record="__patdays= "||&patyearvar||";" ; output;
      %end;
      %else %do;
        %* assumed default (years);
        record="__patdays= 365.25*&patyearvar;" ; output;
      %end;
      record="run;" ; output;
            
      record=' '; output; 
      record="data &ds4var __datasetco; "; output;
      record="set &ds4var; "; output;

      %if %upcase(&patyearunit)=MONTH %then %do;
        record="__patdays= 30.4375*"||&patyearvar||";" ; output;
      %end;
      %else   %if %upcase(&patyearunit)=WEEK %then %do;
        record="__patdays= 7*"||&patyearvar||";" ; output;
      %end;
      %else   %if %upcase(&patyearunit)=DAY %then %do;
        record="__patdays= "||&patyearvar||";" ; output;
      %end;
      %else %do;
        %* assumed default (years);
        record="__patdays= 365.25*&patyearvar;" ; output;
      %end;

      %if %upcase(&onsettype)=DAY %then %do;
          record="__days2firstevent= &onsetvar;" ; output;
      %end;
      %else %do;
          record="__days2firstevent= &onsetvar-&refstartvar+1;" ; output;
      %end;  
      record="run;" ; output;
          
      record="*--------------------------------------------------------------------;"; output;
      record="* CALCULATE COUNT OF SUBJECTS;"; output;
      record="*--------------------------------------------------------------------;"; output;
      record=" "; output;


      %* multiple stats do not work when countall=max (not yet);

      %put DEBUG INFO  using PY version of the macros;
            
      %if %upcase(&countwhat)=MAX %then %do;

/*           %put &er.&ror.: PY or PYR statistics are not yet supported when countwhat=max; */
/*           %abort abend; */

          
       
                 %__getcntaewpy(    
                         datain = &ds4var,    
                           unit =  &unit,     
                          group = __tby &groupby4ae ,     
                            var = __order &var &decode,    
                         trtvar = &byvars &notaegroupvars __trtid &trtvars ,    
                            cnt = __cnt,     
                        dataout = &outds.2,    
                           desc = &desc);    
                    
                
                 
    
                %if %length(&totaltext) or %length(&totalpos) %then %do;  
                     
                    record=" "; output;      
                    record="*--------------------------------------------------------------------;";output;  
                    record="* CALCULATE COUNT OF SUBJECTS for &totaltext;";output;  
                    record="*--------------------------------------------------------------------;";output;  
                    record=" "; output;  
                      
                      /*  */
/*                    %__getcntaewpy_withtot(   */
/*                            datain = __datasetco ,   */
/*                            where = (&totalwhere),   */
/*                              unit =  &unit,    */
/*                             group = __tby &groupby4ae ,    */
/*                               var = __order &var &decode,   */
/*                            trtvar = &byvars &notaegroupvars __trtid &trtvars ,   */
/*                               cnt = __cnt,    */
/*                           dataout = &outds.2b);   */
/*                          */

                 
                    %local i j numgroups tmp groupby4ae_nolast lastgroup4ae;
                    %let numgroups=0;
                    %if %length(&groupby4ae) %then %let numgroups = %sysfunc(countw(&groupby4ae, %str( )));
                    %do i=1 %to %eval(&numgroups-1);
                        %let groupby4ae_nolast=&groupby4ae_nolast  %scan(&groupby4ae, &i, %str( ));
                    %end;
                    %if &numgroups>0 %then %let lastgroup4ae= %scan(&groupby4ae, &numgroups, %str( ));
                    %else %let lastgroup4ae=;
                    

                 %__getcntaepy(
                       datain = __datasetco (where=(&totalwhere)),
                         unit =  &unit, 
                         group = __tby  &groupby4ae_nolast , 
                          var = &lastgroup4ae, 
                       trtvar = &byvars &notaegroupvars  __trtid &trtvars ,
                          cnt = __cnt, 
                      dataout = &outds.2b);
                 
                                        
                      record=" "; output;  
                        
                      %if %length(&decode) %then %do;  
    
                         record='proc sql noprint;'; output;  
                         record="  select max(length(&decode)) into: mld separated by '' from &outds.2;"; output;  
                         record='  quit;'; output;  
                         record=" "; output;  
                      %end;    
                        
                      record="data &outds.2;";output;  
                      record="length &decode $ "||'%sysfunc(max(&mld,'||"%length(&totaltext)));";output;  
                      record="set &outds.2 &outds.2b (in=__inb);";output;  
                      record="if __inb then do;";output;  
                      record="  __total=1;";output;  
                      record="  &decode = '"|| strip("&totaltext")|| "';";output;  
                      record="end;";output;  
                      
                  
                  
                %end;        
      %end;

      %else %do;
            %* PY and No countwhat=MAX;
            %* this allows for multiple stats;
            
            %__getcntaepy(
                       datain = &ds4var,
                         unit =  &unit, 
                         group = __tby &groupby4ae , 
                          var = __order &var &decode , 
                       trtvar = &byvars &notaegroupvars  __trtid &trtvars ,
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
      record="  by &byvars &notaegroupvars __tby &groupby4ae __order   &var __grpid &decode &sortmod __trtid;";output;
      record="run;";output;
      record=" "; output;  
      record=" data &outds.2;";output;
      record=" set &outds.2;";output;
      record="  by &byvars &notaegroupvars __tby &groupby4ae __order   &var __grpid &decode &sortmod __trtid;";output;
      record=" if last.__trtid;";output;
      record="run;";output;
      record=" "; output;  
      record="proc transpose data=&outds.2 out=__catcnt4_cnt prefix=__cnt_;";output;
      record="  by &byvars &notaegroupvars __tby &groupby4ae __order   &var __grpid &decode &sortmod;";output;
      record="  id __trtid;";output;
      record="  var __cnt;";output;
      record="run;";output;
      record=" "; output;  
      record="proc transpose data=&outds.2 out=__catcnt4_py prefix=__py_;";output;
      record="  by &byvars &notaegroupvars __tby &groupby4ae __order   &var __grpid &decode &sortmod;";output;
      record="  id __trtid;";output;
      record="  var __py;";output;
      record="run;";output;
      record=" "; output;  
      record="proc transpose data=&outds.2 out=__catcnt4_pyr prefix=__pyr_;";output;
      record="  by &byvars &notaegroupvars __tby &groupby4ae __order   &var __grpid &decode &sortmod;";output;
      record="  id __trtid;";output;
      record="  var __pyr;";output;
      record="run;";output;    
      record=" "; output;
      record=" "; output; 
      record=" "; output;  
      record="data __catcnt4;";output;
      record="merge __catcnt4_cnt __catcnt4_py __catcnt4_pyr;";output;
      record="  by &byvars &notaegroupvars __tby &groupby4ae __order   &var __grpid &decode &sortmod;";output;
      record="run;";output;    
      record=" "; output;
      record=" "; output; 

              
             

      %if %index(&aetable, EVENTS)>0 %then %do;

              
              record=" "; output;
              record="*------------------------------------------------------------;";output;
              record="* CALCULATE COUNT OF EVENTS;";output;
              record="*------------------------------------------------------------;";output;
              

                 %__getcntaepy(
                          datain = __datasetce,
                            unit = __eventid, 
                           group = __tby &groupby4ae,
                             var =  __order &var &decode , 
                          trtvar = &byvars &notaegroupvars __trtid &trtvars ,
                             cnt = __cntevt, 
                         dataout = __catcntevt);
 
                     
             
              record=" "; output;
              record=" "; output;  
              record="*------------------------------------------------------------;";output;
              record="* MERGE COUNT OF SUBJECTS WITH WITH COUNT OF EVENTS;";output;
              record="*------------------------------------------------------------;";output;
              record=" "; output;  output;
              

                
               %__joinds(
                    data1 = &outds.2 ,
                    data2 = __catcntevt ,
                       by = &byvars &notaegroupvars __trtid &trtvars __tby &groupby4ae __order  &var &decode &sortmod __grpid,
                mergetype = OUTER,
                  dataout = &outds.2);
                        
                  
              
                record=" "; output;
                record=" "; output;  
                record=" proc sort data=&outds.2;";output;
                record="   by &byvars &notaegroupvars __tby &groupby4ae __order   &var __grpid &decode &sortmod;";output;
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
                record="      by &byvars &notaegroupvars __tby &groupby4ae __order   &var __grpid &decode &sortmod;";output;
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
                record="  by &byvars &notaegroupvars __tby &groupby4ae  __order   &var __grpid &decode &sortmod;";output;
                record="run;";output;
                record=" "; output;
                
                 
          %* end of adding events;
          %end;
%* end of PY statistics requested;
%end;

%else %do;

%put DEBUG INFO using usual  version of the macros;

    %if %upcase(&countwhat)=MAX %then %do;

      
       %__getcntaew(
               datain = &ds4var,
                 unit =  &unit, 
                group = __tby &groupby4ae , 
                  var = __order &var &decode,
               trtvar = &byvars &notaegroupvars __trtid &trtvars ,
                  cnt = __cnt, 
              dataout = &outds.2,
                 desc = &desc);
              
          
           

        %if %length(&totaltext) or %length(&totalpos) %then %do;
        
           %local i j numgroups tmp groupby4ae_nolast lastgroup4ae;
                    %let numgroups=0;
                    %if %length(&groupby4ae) %then %let numgroups = %sysfunc(countw(&groupby4ae, %str( )));
                    %do i=1 %to %eval(&numgroups-1);
                        %let groupby4ae_nolast=&groupby4ae_nolast  %scan(&groupby4ae, &i, %str( ));
                    %end;
                   %if &numgroups>0 %then %let lastgroup4ae= %scan(&groupby4ae, &numgroups, %str( ));
                    %else %let lastgroup4ae=;
           
            record=" "; output;    
            record="*--------------------------------------------------------------------;";output;
            record="* CALCULATE COUNT OF SUBJECTS for &totaltext;";output;
            record="*--------------------------------------------------------------------;";output;
            record=" "; output;

              
            %__getcntae(
                 datain = &ds4var (where=(&totalwhere)),
                   unit =  &unit, 
                  group = __tby &groupby4ae_nolast ,  
                    var = &lastgroup4ae , 
                 trtvar = &byvars &notaegroupvars  __trtid &trtvars ,
                    cnt = __cnt, 
                dataout = &outds.2b);              
             
              record=" "; output;

              
              record="data &outds.2;";output;
              record="length &decode $ 2000;";output; 
            
              record="set &outds.2 &outds.2b (in=__inb);";output;
              record="if __inb then do;";output;
              record="  __total=1;";output;
              record="  &decode = '"|| strip("&totaltext")|| "';";output;
              record="end;";output;
            
        
        %* end of no PY, countwhat=max and total;
        %end;  
        %* end of no py and count  what=max;  
    %end;

    %else %do;
      
      %* countwhat=all and no py;
      %put DEBUG INFO 10JUN groupby4ae=&groupby4ae trtvar = &byvars &notaegroupvars  __trtid &trtvars ;
      %__getcntae(
                 datain = &ds4var,
                   unit =  &unit, 
                  group = __tby &groupby4ae ,  
                    var = __order &var &decode , 
                 trtvar = &byvars &notaegroupvars  __trtid &trtvars ,
                    cnt = __cnt, 
                dataout = &outds.2);
           
           
      %* end of no py and count all;
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
    record="  by &byvars &notaegroupvars  __tby &groupby4ae __order   &var __grpid &decode &sortmod;";output;
    record="run;";output;
    record=" "; output;  
    record="proc transpose data=&outds.2 out=__catcnt4 prefix=__cnt_;";output;
    record="  by &byvars &notaegroupvars __tby &groupby4ae __order   &var __grpid &decode &sortmod;";output;
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
                    group = __tby &groupby4ae , 
                      var = __order &var &decode,
                   trtvar = &byvars &notaegroupvars __trtid &trtvars ,
                      cnt = __cntevt, 
                  dataout = __catcntevt);
                  
            %if %length(&totaltext) or %length(&totalpos) %then %do;
         
                 %__getcntae(
                         datain = __datasetceo(where=(&totalwhere)),
                           unit = __eventid,
                          group = __tby &grpvarbl , 
                            var =  &lasttmp,
                         trtvar = &byvars &notaegroupvars __trtid &trtvars ,
                            cnt = __cntevt, 
                        dataout = __catcntevtb);
                      
                       
                    record=" "; output;
                    record="data __catcntevt;";output;
                    record="set __catcntevt __catcntevtb (in=__inb);";output;
                    record="if __inb then do;";output;
                    record="  __total=1;";output;
                    record="  &decode = cats('"||"&totaltext"||"');";output;
                    record="end;";output;
                  
           
          %* end of no py and events and countwhat=max and total;  
          %end;                
         %* end of no py and events and countwhat=max;            
        %end;

        %else %do;
                  
           %__getcntae(
                    datain = __datasetce,
                      unit = __eventid, 
                     group = __tby &groupby4ae,
                       var =  __order &var &decode , 
                    trtvar = &byvars &notaegroupvars __trtid &trtvars ,
                       cnt = __cntevt, 
                   dataout = __catcntevt);
                   
         %* end of no py and events and countwhat=all;            
                   
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
                 by = &byvars &notaegroupvars __trtid &trtvars __tby &groupby4ae __order  &var &decode &sortmod __grpid,
          mergetype = OUTER,
            dataout = &outds.2);
                  
            
        
          record=" "; output;
          record=" "; output;  
          record=" proc sort data=&outds.2;";output;
          record="   by &byvars &notaegroupvars __tby &groupby4ae __order   &var __grpid &decode &sortmod;";output;
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
          record="      by &byvars &notaegroupvars __tby &groupby4ae __order   &var __grpid &decode &sortmod;";output;
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
          record="  by &byvars &notaegroupvars __tby &groupby4ae  __order   &var __grpid &decode &sortmod;";output;
          record="run;";output;
          record=" "; output;
          
           
        %* end of no py and events ;            

    %end;  
 %* end of no py; 
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
             group = __tby &byvars &denomvars __trtid,
               cnt = __denom, 
           dataout = __catdenom);
           
        %if %index(%upcase(&allstat), PY) %then %do;
    
        record=" ";                                                                                 output;
        /* @TODO: &byvars &denomvars may be repeated */
        
        record="proc sql;                                                                                                       "; output;
        record="  create table __4patdays_allpats as select distinct                                                            "; output;
        record="    %sysfunc(tranwrd(%sysfunc(compbl(__tby &byvars &denomvars __trtid &unit __patdays)), %str( ), %str(, )))  "; output;
        record="  from __dataset;                                                                                               "; output;
        record="                                                                                                                "; output;
        record="  create table __patdays_allpats as select distinct                                                             "; output;
        record="   %sysfunc(tranwrd(%sysfunc(compbl(__tby &byvars &denomvars __trtid )), %str( ), %str(, ))),                 "; output;
        record="  sum(__patdays)/365.25 as __allpatyears                                                                                "; output;
        record="   from __4patdays_allpats                                                                                               "; output;
        record="   group by %sysfunc(tranwrd(%sysfunc(compbl(__tby &byvars &denomvars __trtid )), %str( ), %str(, )));        "; output;
        record="                                                                                                                "; output;
        record="  create table __catdenom0 as select * from __catdenom;                                                         "; output;
        record="                                                                                                                "; output;
        record="  create table __catdenom as select * from __catdenom0 natural left join __patdays_allpats;                     "; output;
        record="quit;                                                                                                           "; output;
          
        record=" ";                                                                                 output;        
        
        record="proc transpose data=__catdenom out=__catdenom2_4py (drop=_name_)  prefix=__allpatyr_;";output;
        record="    by __tby &byvars &denomvars;";output;
        record="    id __trtid;";output;
        record="    var __allpatyears;";output;
        record="run;";output;
        record=""; output;
        %* end of if PY;
        %end;   
    %* end of denom include trt;
%end;

%else %do;
  %__getcntg(
          datain = &ds4denom  (where=(&denomwhere)), 
            unit = &unit, 
           group = __tby &byvars &denomvars ;
             cnt = __denom, 
         dataout = __catdenom);

        %if %index(%upcase(&allstat), PY) %then %do;
          
                                                                                                                                
        record="proc sql;"; output; 
        record="  create table __4patdays_allpats as select distinct                                                           "; output;
        record="    %sysfunc(tranwrd(%sysfunc(compbl(__tby &byvars &denomvars  &unit __patdays)), %str( ), %str(, )))        "; output;
        record="  from __dataset;                                                                                              "; output;
        record="                                                                                                               "; output;
        record="  create table __patdays_allpats as select distinct                                                            "; output;
        record="   %sysfunc(tranwrd(%sysfunc(compbl(__tby &byvars &denomvars  )), %str( ), %str(, ))),                       "; output;
        record="  sum(__patdays)/365.25 as __allpatyears                                                                               "; output;
        record="   from __dataset                                                                                              "; output;
        record="   group by %sysfunc(tranwrd(%sysfunc(compbl(__tby &byvars &denomvars  )), %str( ), %str(, )));              "; output;
        record="                                                                                                               "; output;
        record="  create table __catdenom0 as select * from __catdenom;                                                        "; output;
        record="                                                                                                               "; output;
        record="  create table __catdenom as select * from __catdenom0 natural left join __patdays_allpats;                    "; output;
        record="quit;                                                                                                          "; output;
           
        %* end of py;
        %end;   
%* end of denon does not include treatment;
  
%end;

record=" "; output;
record=" "; output;

%if &denomincltrt=Y %then %do;
    record="proc transpose data=__catdenom out=__catdenom2 (drop=_name_) prefix=__den_;";output;
    record="    by __tby &byvars &denomvars;";output;
    record="    id __trtid;";output;
    record="    var __denom;";output;
    record="run;";output;
    record=""; output;
    
    %if %index(%upcase(&allstat), PY) %then %do;
      
      record="  proc sql ;"; output;
      record="  create table __catdenom2a as select * from __catdenom2 ;                    "; output;

      record="  create table __catdenom2 as select * from __catdenom2a natural left join __catdenom2_4py;                    "; output;
      record="quit;                                                                                                          "; output;
      record=""; output;
  
     %* end of PY; 
    %end;;
    
%* end of denom include treatment;    
%end;



%else %do;
  
  record="data __catdenom2; "; output;
  record="  set __catdenom; "; output;
  %do i=1 %to &maxtrt;
    record="__den_&i=__denom;"; output;
  %end;  
  record="run;              "; output;
  record=""; output;

%* end of denom oes not include treatment;    
%end;  
    
record=" "; output;
record=" "; output;  
record="*------------------------------------------------------------;";output;
record="* MERGE DENOMINATOR WITH COUNT DATASET;";output;
record="* CREATE DISPLAY OF STATISTICS;";output;
record="*------------------------------------------------------------;";output;
record=" "; output;
record="proc sort data=__catcnt4;";output;
record="by __tby &byvars &denomvars;";output;
record="run;";output;
record=" "; output;
record="proc sort data=__catdenom2;";output;
record="by __tby &byvars &denomvars;";output;
record="run;";output;
record=" "; output;


/* length __stat0 $ 20; */
record="data &outds;";output;
record="length __col_0  $ 2000 __pydecfmt __pyrdecfmt $ 20 __stat $ 200;";output;
record="merge __catcnt4 (in=__a) __catdenom2;";output;
record="by __tby &byvars &denomvars;";output;
record="if __a;";output;
record=" "; output;
record="if 0 then do; __total=0; __py=.; __pyr=.; __col_0=''; end;";output;
record="if __total ne 1 then __total=0;";output;
record=" "; output;
record="__pydec="||"&pydec"||";"; output;
record="__pyrdec="||"&pyrdec"||";"; output;
record=" "; output;

record='__pydecfmt = "12.'||"&pydec"||'";';output;
record='__pyrdecfmt = "12.'||"&pyrdec"||'";';output;

record=   'array cnt{*} __cnt_1-__cnt_&maxtrt;';output;
record=   'array pct{*} __pct_1-__pct_&maxtrt;';output;
record=   'array denom{*} __den_1-__den_&maxtrt;';output;

record=   'array col{*} $ 2000 __col_1-__col_&maxtrt;';output;
record=   'array py{*}   __py_1-__py_&maxtrt;';output;
record=   'array pyr{*}  __pyr_1-__pyr_&maxtrt;';output;
record=   'array allpy{*}  __allpatyr_1-__allpatyr_&maxtrt;';output;

%if %index(%upcase(&allstat), PY) %then %do;

record="do __i=1 to dim(py);                "; output;
record="  if py[__i]=. then py[__i]=allpy[__i];   "; output;

record="end;                       "; output;
record="do __i=1 to dim(pyr);              "; output;
record="  if   pyr[__i]=. then pyr[__i]=0;   "; output;
record="end;                       "; output;
%end;

%if %index(&aetable, EVENTS)>0 %then %do;
    record=   'array colevt{*} $ 2000 __colevt_1-__colevt_&maxtrt;';output;
    record=   'array cntevt{*} __cntevt_1-__cntevt_&maxtrt;';output;
    record=   'array pctevt{*} __pctevt_1-__pctevt_&maxtrt;';output;
%end;

record=" "; output;

record="if missing(&var) and __total ne 1 then do;";output;
record="    __order=&missorder; ";output;
record="    __missing=1; ";output;
record="end;";output;
%if %length(&totaltext) >0 or %length(&totalpos) %then %do;
    record="if __total=1 then do;";output;
    record="  __col_0 = cats('" ||strip("&totaltext")||  "');";output;
    record="    __order=&totorder; ";output;
    record="end;";output;
%end;

%local s0 i tmp;


      %let s0 = %qscan(&simplestats,1,%str( ));   
      %let sord0 = %scan(&simpleorder,1,%str( ));
      record=   "array col1{*} $ 2000 __col1_1-__col1_"||'&maxtrt;';output;
%if %length(&rgroupvars) %then %do;
      record="if __total ne 1 then __col_0 = coalescec(&rgroupvars);";output;
%end;      
      record="__stat='"||symget("simplestats")|| "';";output; 
      record="do __i=1 to dim(cnt);";output;
         %__fmtcnt(cntvar=cnt[__i], pctvar=pct[__i], pyvar=py[__i],  pyrvar=pyr[__i],
              denomvar=denom[__i], stat=%nrbquote(&s0), outvar=col1[__i],
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
 

%if %sysfunc(countw(&simplestats, %str( )))>1 %then %do;
  %let splitcolumns=&simplestats;
 

%do i=2 %to %sysfunc(countw(&simplestats, %str( )));
      record=   "array col&i.{*} $ 2000 __col&i._1-__col&i._"||'&maxtrt;';output;

      %let s0 = %qscan(&simplestats,&i,%str( ));   
      %let sord0 = %scan(&simpleorder,1,%str( ));
 /*  */
/*       record="if __total ne 1 then __col_0 = coalescec(&rgroupvars);";output; */
/*       record="__stat='"||symget("simplestats")|| "';";output; */ 
      record="do __i=1 to dim(cnt);";output;
         %__fmtcnt(cntvar=cnt[__i], pctvar=pct[__i], pyvar=py[__i],  pyrvar=pyr[__i],
              denomvar=denom[__i], stat=%nrbquote(&s0), outvar=col&i.[__i],
               pctfmt=&pctfmt);
      record="col1[__i]=strip(col1[__i])||'!'||strip(col&i.[__i]);  ";output;
              
      record="end;  ";output;
     /*  %if %index(&allgrpcnt, EVENTS)>0 %then %do; */
/*           record="do __i=1 to dim(cnt);";output; */
/*            %__fmtcnt(cntvar=cntevt[__i], pctvar=pctevt[__i],  */
/*               denomvar=denom[___i], stat=N, outvar=colevt[__i],  */
/*               pctfmt=&pctfmt); */
/*            record="end;  ";output; */
/*       %end; */
      record="__sid =&sord0;";output;
         
%end;
%end;
  record = "__stat=compbl(__stat);"; output;
  record="do __i=1 to dim(col);"; output;
  record="  col[__i]=col1[__i];"; output;


  record=" end;  "; output;
record="output;";output;

%let tmp = ;
%do i=1 %to %sysfunc(countw(&simplestats, %str( )));; 
  %let tmp  =&tmp __col&i._:;
%end;;
/* record = "drop  &tmp ;"; output;  */
/*  */
/*   record = "drop __py: &tmp ;"; output;   */
/*  */    
record="run;"; output;

record=" "; output;
record='%local aestats; ';output;
record=" "; output;

record="data &outds;";output;
record="set &outds end=eof;";output;
record="if eof then call symput('aestats', __stat);";output;
record="run;";output;


record= '%exca'|| "&varid.:"; output;
record=" "; output;


record="data &ds4var ;"; output;
   record="set __hold;";output;
    record="run;";output;
    record=" "; output;

run;

proc append data=rrgpgmtmp base=rrgpgm;
run;


%mend;
