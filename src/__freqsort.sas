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



%* determine values of modalities to sort by;
%local sortmods;
proc sql noprint;
  select sortcolumn into:sortmods separated by ' '
  from __VARINFO(where=(upcase(cats(name))=upcase(cats("&analvar"))));
quit;
    
data rrgpgmtmp;
length record $ 2000;
keep record;
set __tokends1 end =eof;
record = " ";output;
record = " ";output;
if _n_=1 then do;
    record =  "*---------------------------------------------------------------;";output;
    record =  "* DETERMINE COLUMN NUMBER OF COLUMN TO SORT BY;";output;
    record =  "*---------------------------------------------------------------;";output;
    record = " ";    output;
    record =  "data __sortinfo;";output;
    record =  "set __trt;";output;
end;
record =  strip(__cond);output;
if eof then do;
    record =  "run;";output;
    record = " ";output;
    record =  "proc sort data=__sortinfo(where=(__id>0));";output;
    record =  "by __id;";output;
    record =  "run;";output;
    record =  '%local sortcolumn;';output;
    record =  "proc sql noprint;";output;
    record = "   select 'descending '||cats('__cnt_',__trtid) into: sortcolumn separated by ' ' "; output;
    record =  "     from __sortinfo;";output;
    record =  "quit;";output;
    record = " ";output;
    record = " ";output;
    record =  '%if %length(&sortcolumn)=0 %then %do;';output;
    record =  '   %let sortcolumn = descending __cnt_1;';output;
    record =  '%end;';output;
    record = " ";output;
    record = " ";output;

    %if %upcase(&ordervar)=__ORDER and %upcase(&defreport_statsacross) ne Y
     and %length(&sortmods)=0 %then %do;
     
        record = " ";output;
        record =  "*-----------------------------------------------------------------;";output;
        record =  "* APPLY FREQUENCY-BASED SORTING TO &var;";output;
        record =  "*-----------------------------------------------------------------;";output;
        record = " ";output;
        record =  "proc sort data=&dsin;";output;
        record =  "by &by __tby &groupvars " ||' &sortcolumn '|| "&var;";output;
        record =  "run;";output;
        record = " ";output;
        record =  "  data &dsin;";output;
        record =  "  set &dsin;";output;
        record =  "  by &by __tby &groupvars "|| ' &sortcolumn '|| "&var;";output;
        record =  "  if not missing(&var) then &ordervar=_n_;";output;
        record =  "  * MISSING MODALITY  GOES LAST;";output;
        record =  "  run;";output;
        record = " ";output;
      

    %end;
end;
run;

proc append data=rrgpgmtmp base=rrgpgm;
run;


%if %upcase(&ordervar) ne __ORDER or %length(&sortmods)>0  %then %do;
  
    %if %upcase(&defreport_statsacross) ne Y and %length(&sortmods)=0  %then %do;
  
        
        data rrgpgmtmp;
        length record $ 2000;
        keep record;
        record = " ";output;
        record =  "*-----------------------------------------------------------------;";output;
        record =  "* APPLY FREQUENCY-BASED SORTING TO &var;";output;
        record =  "*-----------------------------------------------------------------;";output;
        record = " ";output;
        record =  "    proc sort data=&dsin  out=__tmp;";output;
        record =  "      by &by __tby &groupvars  &var "|| '&sortcolumn '|| ";";output;
        record =  "    run;";output;
        record = " ";output;
        record =  "    data __tmp;";output;
        record =  "    set __tmp;";output;
        record =  "    by &by __tby &groupvars  &var "|| '&sortcolumn ' ||";";output;
        record =  "      if first.&var;";output;
        record =  "    run;";output;
        record = " ";output;
        record =  "    proc sort data=__tmp;  ";output;
        record =  "    by &by __tby &groupvars   "|| '&sortcolumn '|| "&var;";output;
        record =  "    run;";output;
        record = " ";output;
        record =  "    data __tmp;";output;
        record =  "    set __tmp;";output;
        record =  "    by &by __tby &groupvars   " || '&sortcolumn '|| "&var;";output;
        record =  "    if not missing(&var) then &ordervar=_n_;";output;
        record =  "    * MISSING MODALITY  GOES LAST;";output;
        record =  "    keep &by __tby &groupvars  &var &ordervar;";output;
        record =  "    run;";output;
        
        record =  "    proc sort data=__tmp;";output;
        record =  "      by &by __tby &groupvars  &var ;";output;
        record =  "    run;";output;
          
        record =  "    proc sort data=&dsin;";output;
        record =  "      by &by __tby &groupvars  &var ;";output;
        record =  "  run;";output;
          
        record =  "    data &dsin;";output;
        record =  "      merge &dsin __tmp;";output;
        record =  "      by &by __tby &groupvars  &var ;";output;
        record =  "    run;";   output;
        run;
      
        proc append data=rrgpgmtmp base=rrgpgm;
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
     
        data rrgpgmtmp;
        length record $ 2000;
        keep record;

        record = " ";output;
        record =  "*-----------------------------------------------------------------;";output;
        record =  "* APPLY FREQUENCY-BASED SORTING TO &VAR;";output;
        record =  "*-----------------------------------------------------------------;";output;
        record = " ";output;
        record = " ";output;
        record =  "data &dsin;";output;
        record =  "set &dsin;";output;
        record =  "__tmporder_&var=1;";output;
        record =  "run;";output;
        record = " ";output;
        %local tmpsort;
        %do k = 1 %to &numsortc;
            record = " ";output;
            record =  '%local sortcolumntmp;';output;
            record =  '%let sortcolumntmp = %scan(&sortcolumn,'|| " %eval(2*&k),"|| '%str( ));';output;
            %local sortstr j descstr;  
            %let sortstr=;
            %let descstr=;
          
            %do i=1 %to &cntsortmods;
                %if %upcase(&sortmods) ne _TOTAL_ %then %do;
                    record =  "    proc sort data=&dsin(where=(&analvar=%qtrim(&&sortmod&i.)))";output;
                %end;
                %else %do;
                    record =  "    proc sort data=&dsin(where=(__total=1))";output;
                %end;
                record =  "      nodupkey out=__tmp;";output;
                record =  "      by &by __tby &groupvars &tmpsort &sortstr   &var;";output;
                record =  "    run;";output;
                record = " ";output;
                
        
                record =  "   data __tmp;";output;
                record =  "    set __tmp;";output;
                record =  "    __order_&var._&i="|| '&sortcolumntmp;';output;
                record =  "    keep  &by __tby &groupvars  &tmpsort &sortstr &var __order_&var._&i ;";output;
                record =  "    run;";output;
                record = " ";output;
            
                %let descstr=&descstr descending __order_&var._&i;
            
                %if &i=&cntsortmods %then %do;
                    record =  "   proc sort data=__tmp;";output;
                    record =  "      by  &by __tby &groupvars &tmpsort &descstr  &var;";output;
                    record =  "   run;";output;
                    record = " ";output;
                    record =  "   data __tmp;";output;
                    record =  "   set __tmp;";output;
                    record =  "    by  &by __tby &groupvars &tmpsort &descstr &var;";output;
                    record =  "    retain __tmporder&k;";output;
                    record =  "    if _n_=1 then __tmporder&k=0;";output;
                    record =  "    if first.__order_&var._&i then __tmporder&k+1;";output;
                    record =  "  run;";output;
                    record = " ";output;
                %end;
            
                record =  "    proc sort data=__tmp;";output;
                record =  "      by &by __tby &groupvars  &sortstr &tmpsort &var;";output;
                record =  "    run;";output;
                  
                record =  "    proc sort data=&dsin;";output;
                record =  "      by &by __tby &groupvars  &sortstr &tmpsort &var ;";output;
                record =  "  run;";output;
                  
                record =  "    data &dsin;";output;
                record =  "      merge &dsin __tmp;";output;
                record =  "      by &by __tby &groupvars &sortstr &tmpsort &var ;";output;
                record =  "    run;";   output;
                record = " ";output;
            
                %let sortstr=&sortstr __order_&var._&i;
            %end; %* end do i=1 to cntsortmods;
          
            record =  "data &dsin;";output;
            record =  "set &dsin;";output;
            record =  "drop __order_&var._:;";output;
            record =  "run;";output;
            %let tmpsort = &tmpsort __tmporder&k ;
        %end;  %* end do k = 1 to countw(numsortc);

        record =  "data &dsin;";output;
        record =  "set &dsin;";output;
        record =  "__order_&var=__tmporder&numsortc;";output;
        record =  "drop __tmporder:;";output;
        record =  "run;";output;
        run;  
        
        proc append data=rrgpgmtmp base=rrgpgm;
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
