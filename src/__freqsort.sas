/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __freqsort(
dsin=,
by=,
groupvars=,
trtvars=,
var=,
vinfods= ,
trtds=,
trtinfods=,
ordervar=__order,
analvar=
)/store;


%local dsin  by groupvars   trtvars var vinfods
       trtds trtinfods ordervar sortcolumn freqsort analvar;

%* DETERMINE WHETHER TO DO FREQUENCY BASED FREQSORT FOR THIS VARIABLE;

%local i j k;

proc sql noprint;
  select upcase(trim(left(freqsort))) into:freqsort 
  from &vinfods(where=(name="&var"));
quit;

%if %length(&freqsort)=0  or &freqsort=N %then %goto exit;

%* DETERMINE SORT COLUMN NUMBER;

  
data __sortinfo;
   set &trtinfods;
   where sortcolumn ne '';
run;
    
data __sortinfo;
  set __sortinfo;
  __id=_n_;
run;
    
proc sql noprint;
select count(*) into:numsortvars from __sortinfo;
%local i;
%do i=1 %to  &numsortvars;
  %local sortvar&i sortvalue&i;
  select sortcolumn into:sortvalue&i separated by ' '
    from __sortinfo(where=(__id=&i));
  select name into:sortvar&i separated by ' '  
  from __sortinfo(where=(__id=&i));
%end;
quit;

%do i=1 %to  &numsortvars;
  %local tmpsortcolumn;
  
  data __tokenize;
    if 0;
  run;
      
  %__tokenize(&&sortvalue&i);

  data __tokends&i;
    set __tokends;
    length __name&i $ 20 __sortval&i $ 2000;
    __sortvar&i=_n_;
    __name&i = "&&sortvar&i";
    __sortval&i = nstring;
    drop nstring;
  run;
  
  %if &i>1 %then %do;
    proc sql noprint nowarn;
      create table tmp as select * from __tokends1
       cross join __tokends&i;
    create table __tokends1 as select * from __tmp;
    quit;
  %end;

%end;

proc sort data=__tokends1;
  by %do i=1 %to &numsortvars; __sortvar&i %end;;
run;

%local numsortc;

data __tokends1;
  set __tokends1 end=eof;
  length __cond $ 2000;
  __id = _n_;
  __cond = "if "||cats(__name1,'=')||trim(left(__sortval1));
  %do i=2 %to &numsortvars;
  __cond = trim(left(__cond))||' and '||
      cats(__name&i,'=')||trim(left(__sortval&i));
  %end;
  __cond = trim(left(__cond))||' then __id ='||cats(__id)||';';
  if eof then call symput("numsortc", cats(__id));
run;

    
data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
set __tokends1 end =eof;
put;
put;
if _n_=1 then do;
  put @1 "*---------------------------------------------------------------;";
  put @1 "* DETERMINE COLUMN NUMBER OF COLUMN TO SORT BY;";
  put @1 "*---------------------------------------------------------------;";
  put;    
  put @1 "data __sortinfo;";
  put @1 "set __trt;";
end;
put @1 __cond;
if eof then do;
  put @1 "run;";
  put;
  put @1 "proc sort data=__sortinfo(where=(__id>0));";
  put @1 "by __id;";
  put @1 "run;";
end;
run;


data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put @1 '%local sortcolumn;';
put @1 "proc sql noprint;";
put @1 "   select 'descending '||cats('__cnt_',__trtid) into: sortcolumn separated by ' ' ";
put @1 "     from __sortinfo;";
put @1 "quit;";
put;

put;
put @1 '%if %length(&sortcolumn)=0 %then %do;';
put @1 '   %let sortcolumn = descending __cnt_1;';
put @1 '%end;';
put;
put;
run;

%* determine values of modalities to sort by;
%local sortmods;
proc sql noprint;
  select sortcolumn into:sortmods separated by ' '
  from __VARINFO(where=(upcase(cats(name))=upcase(cats("&analvar"))));
quit;


    

%if %upcase(&ordervar)=__ORDER and %upcase(&Statsacross) ne Y
 and %length(&sortmods)=0 %then %do;
 
  data _null_;
  file "&rrgpgmpath./&rrguri..sas" mod;
  put;
  put @1 "*-----------------------------------------------------------------;";
  put @1 "* APPLY FREQUENCY-BASED SORTING TO &var;";
  put @1 "*-----------------------------------------------------------------;";
  put;
  put @1 "proc sort data=&dsin;";
  put @1 "by &by __tby &groupvars " ' &sortcolumn ' "&var;";
  put @1 "run;";
  put;
  put @1 "  data &dsin;";
  put @1 "  set &dsin;";
  put @1 "  by &by __tby &groupvars " ' &sortcolumn ' "&var;";
  put @1 "  if not missing(&var) then &ordervar=_n_;";
  put @1 "  * MISSING MODALITY  GOES LAST;";
  put @1 "  run;";
  put;
  run;
%end;
%if %upcase(&ordervar) ne __ORDER or %length(&sortmods)>0  %then %do;
  %if %upcase(&Statsacross) ne Y and %length(&sortmods)=0  %then %do;
  
    data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    put;
    put @1 "*-----------------------------------------------------------------;";
    put @1 "* APPLY FREQUENCY-BASED SORTING TO &var;";
    put @1 "*-----------------------------------------------------------------;";
    put;
    put @1 "    proc sort data=&dsin  out=__tmp;";
    put @1 "      by &by __tby &groupvars  &var " '&sortcolumn ' ";";
    put @1 "    run;";
    put;
    put @1 "    data __tmp;";
    put @1 "    set __tmp;";
    put @1 "    by &by __tby &groupvars  &var " '&sortcolumn ' ";";
    put @1 "      if first.&var;";
    put @1 "    run;";
    put;
    put @1 "    proc sort data=__tmp;  ";
    put @1 "    by &by __tby &groupvars   " '&sortcolumn ' "&var;";
    put @1 "    run;";
    put;
    put @1 "    data __tmp;";
    put @1 "    set __tmp;";
    put @1 "    by &by __tby &groupvars   "  '&sortcolumn ' "&var;";
    put @1 "    if not missing(&var) then &ordervar=_n_;";
    put @1 "    * MISSING MODALITY  GOES LAST;";
    put @1 "    keep &by __tby &groupvars  &var &ordervar;";
    put @1 "    run;";
    
    put @1 "    proc sort data=__tmp;";
    put @1 "      by &by __tby &groupvars  &var ;";
    put @1 "    run;";
      
    put @1 "    proc sort data=&dsin;";
    put @1 "      by &by __tby &groupvars  &var ;";
    put @1 "  run;";
      
    put @1 "    data &dsin;";
    put @1 "      merge &dsin __tmp;";
    put @1 "      by &by __tby &groupvars  &var ;";
    put @1 "    run;";   
    run;
  %end;
    
  %else %do;
   
    data __tokenize;
      if 0;
    run;
    
    %local cntsortmods;
        
    %if %upcase(&sortmods)=_TOTAL_ %then %do;
      %let cntsortmods=1;
    %end;
    
    %else %do;
    %__tokenize(&sortmods);
      
    
    %let cntsortmods=0;
    proc sql noprint;
      select count(*) into:cntsortmods from __tokends;
    quit;
      
    %do i=1 %to &cntsortmods;
      %local sortmod&i;
    %end;
    
    data __tokends;
      set __tokends;
      call symput  (cats("sortmod", _n_), trim(nstring));
    run;
    
    %end;
    
    
    
 
    
    data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    put;
    put @1 "*-----------------------------------------------------------------;";
    put @1 "* APPLY FREQUENCY-BASED SORTING TO &VAR;";
    put @1 "*-----------------------------------------------------------------;";
    put;
    put;
    put @1 "data &dsin;";
    put @1 "set &dsin;";
    put @1 "__tmporder_&var=1;";
    put @1 "run;";
    put;
    %local tmpsort;
    %do k = 1 %to &numsortc;
      put;
      put @1 '%local sortcolumntmp;';
      put @1 '%let sortcolumntmp = %scan(&sortcolumn,' " %eval(2*&k)," '%str( ));';
        %local sortstr j descstr;  
        %let sortstr=;
        %let descstr=;
      
      %do i=1 %to &cntsortmods;
        %if %upcase(&sortmods) ne _TOTAL_ %then %do;
        put @1 "    proc sort data=&dsin(where=(&analvar=%qtrim(&&sortmod&i.)))";
        %end;
        %else %do;
        put @1 "    proc sort data=&dsin(where=(__total=1))";
        %end;
        put @1 "      nodupkey out=__tmp;";
        put @1 "      by &by __tby &groupvars &tmpsort &sortstr   &var;";
        put @1 "    run;";
        put;
        
  
        put @1 "   data __tmp;";
        put @1 "    set __tmp;";
        put @1 "    __order_&var._&i=" '&sortcolumntmp;';
        put @1 "    keep  &by __tby &groupvars  &tmpsort &sortstr &var __order_&var._&i ;";
        put @1 "    run;";
        put;
        
        %let descstr=&descstr descending __order_&var._&i;
        
        %if &i=&cntsortmods %then %do;
          put @1 "   proc sort data=__tmp;";
          put @1 "      by  &by __tby &groupvars &tmpsort &descstr  &var;";
          put @1 "   run;";
          put;
          put @1 "   data __tmp;";
          put @1 "   set __tmp;";
          put @1 "    by  &by __tby &groupvars &tmpsort &descstr &var;";
          put @1 "    retain __tmporder&k;";
          put @1 "    if _n_=1 then __tmporder&k=0;";
          put @1 "    if first.__order_&var._&i then __tmporder&k+1;";
          put @1 "  run;";
          put;
        %end;
        
        put @1 "    proc sort data=__tmp;";
        put @1 "      by &by __tby &groupvars  &sortstr &tmpsort &var;";
        put @1 "    run;";
          
        put @1 "    proc sort data=&dsin;";
        put @1 "      by &by __tby &groupvars  &sortstr &tmpsort &var ;";
        put @1 "  run;";
          
        put @1 "    data &dsin;";
        put @1 "      merge &dsin __tmp;";
        put @1 "      by &by __tby &groupvars &sortstr &tmpsort &var ;";
        put @1 "    run;";   
        PUT;
        %let sortstr=&sortstr __order_&var._&i;
      %end; %* end do i=1 to cntsortmods;
      put @1 "data &dsin;";
      put @1 "set &dsin;";
      put @1 "drop __order_&var._:;";
      put @1 "run;";
      %let tmpsort = &tmpsort __tmporder&k ;
    %end;  %* end do k = 1 to countw(numsortc);

    put @1 "data &dsin;";
    put @1 "set &dsin;";
    put @1 "__order_&var=__tmporder&numsortc;";
    put @1 "drop __tmporder:;";
    put @1 "run;";
    run;  
  %end; %* Statsacross;    
  %local ngb gb cgb i tmp;
  proc sql noprint;
   select value into:gb separated by ' ' from __rrgpgminfo
    (where =(key = "newgroupby"));
  quit;
  %let cgb = %sysfunc(countw(&gb, %str( )));
  %let ngb=;
  %do i=1 %to &cgb;
        %let tmp = %scan(&gb,&i, %str( ));
        %if %upcase(&tmp)=%upcase(&var) %then 
            %let ngb = &ngb &ordervar;
         %let ngb = &ngb &tmp;
  %end; 
    
  proc sql noprint;
  update __rrgpgminfo set value="&ngb" where key = "newgroupby";
  quit;
    
%end;%* not __order;


  


%exit:

  
%mend;
