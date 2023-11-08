/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.

 * 2020-05-26 added handling of maxdec (max number of decimal for addvar stats)
 *            condfmt applied only to stats specified in condfmt
 *            stats=. replaced with blank
 *            (.) in stats replaced with (NA)
 * 2020-06-16 added handling of showneg0 parameter: if Y then small neg number which rounds to 0 is shown as e.g. -0.000
               otherwise e.g. -0.000 is shown as 0.000
               made handling of missing stats consistent

 */

%macro __cont (
varid=,
unit=, 
groupvars4pop=, 
groupvarsn4pop=,
by4pop=,
byn4pop=,
trtvars=,
outds=)/store;




%local varid  where unit var groupvars trtvars stat statsetid
       indent skipline   label labelline indent groupvars4pop groupvarsn4pop
       basedec basedecds outds align j outds by ovstat by4pop byn4pop
       decinfmt sdfmt keepn templatewhere popgrp  groupvars  condfmt 
       pvfmt maxdec showneg0 subjid;

%let by = &by4pop &byn4pop;
%if %length(&by) %then %let by = %sysfunc(compbl(&by));
%let groupvars = &groupvars4pop &groupvarsn4pop;
%if %length(&groupvars) %then %let groupvars = %sysfunc(compbl(&groupvars));



%local nums decvar;
%* assumes that __dataset exists and has all needed variables;
%* assumes that dataset __pop with all treatments exist;

 
%* DETERMINE ATTRIBUTES FOR CURRENT CONTINUOUS VARIABLE;

data __contv;
set __varinfo (where=(varid=&varid));
run;

%let indent=0;
proc sql noprint;
select 
  trim(left(where)),        
  trim(left(popgrp)),       
  trim(left(templatewhere)),
  trim(left(name)),         
  trim(left(stat)),         
  trim(left(statsetid)),    
  indent  ,                 
  upcase(skipline),         
  trim(left(label)),        
  labelline ,               
  basedec ,                 
  trim(left(align)) ,       
  trim(left(ovstat)),       
  trim(left(sdfmt)),        
  trim(left(slfmt)) ,       
  trim(left(pvalfmt)) ,     
  trim(left(decinfmt))  ,   
  trim(left(keepwithnext)),
  trim(left(condfmt)),      
  trim(left(maxdec)) ,      
  trim(left(showneg0)),
  trim(left(subjid))                               ,

  
into
  :where              separated by ' ' ,
  :popgrp             separated by ' ' ,
  :templatewhere      separated by ' ' ,
  :var                separated by ' ' ,
  :stat               separated by ' ' ,
  :statsetid          separated by ' ' ,
  :indent             separated by ' ' ,
  :skipline           separated by ' ' ,
  :label              separated by ' ' ,
  :labelline          separated by ' ' ,
  :basedec            separated by ' ' ,
  :align              separated by ' ' ,
  :ovstat             separated by ' ' ,
  :sdfmt              separated by ' ' ,
  :slfmt              separated by ' ' ,
  :pvfmt              separated by ' ' ,
  :decinfmt           separated by ' ' ,
  :keepn              separated by ' ' ,
  :condfmt            separated by ' ' ,
  :maxdec             separated by ' ' ,
  :showneg0           separated by ' ' ,
  :subjid           separated by ' ' 


from  __contv;
  
  
  
      
quit;



%if %length(&where)=0 %then %let where=%str(1=1);
%if %length(&templatewhere)=0 %then %let templatewhere = &where and &defreport_tabwhere;

%if %length(&popgrp)=0 %then %let popgrp=&groupvars4pop &by4pop;

%* BASEDEC CAN BE AN INTEGER OR THE NAME OF VARIABLE WITH INTEGER VALUES;
%* IF BASEDEC = VARIABLE NAME THEN SAVE THIS NAME IN &DECVAR;

%if %length(&subjid)>0 %then %let unit=&subjid;
%else %let unit=&defreport_subjid;


%if  %sysfunc(notdigit(&basedec))>0 %then %do;
  %let decvar=&basedec;
%end;



%* LABELLINE=1 MEANS THAT 1ST STATISTIC IS TO BE PUT ON THE SAME;
%* LINE AS VARIABLE LABEL;
%* FOR TABLES WITH STATISTICS IN COLUMNS, THIS IS IGNORED,;
%* AS WELL AS INDENTATION;
   
%if %upcase(&defreport_statsacross)=Y %then %do;
    %let labelline=0;
    %let indent=0;
%end;

%if %length(&where)=0  %then %let where=%str(1=1);

%*--------------------------------------------------------------------;
%* PREPARATION: CREATE (OR TRANSFORM) DATASET WITH LIST OF REQUESTED ;
%*   STATISTICS, THEIR ORDER, AND THEIR DISPLAY "NAMES";
%*--------------------------------------------------------------------;

data __contstatlist;
  if 0;
run;

%if %length(&statsetid)=0  %then %do;
  
     data __contstatlist;
     length string basedec name label __dispname $ 2000;
     drop string num;
     string = compbl(symget("stat"));
     num = countw(string,' ');
     basedec = compbl(symget("basedec"));

     do __order =1 to num;
          name = scan(string,__order, ' ');
          label = put(upcase(name), &slfmt); 
          
          __dispname = strip(put(upcase(name), &sdfmt));
          
          if upcase(name)='MEAN+SD' then do;
            __dispname=upcase(__dispname);
            __dispname=tranwrd(strip(__dispname), "MEAN", "$MEAN$");
            __dispname=tranwrd(strip(__dispname), "SD", "$STD$");
           
          end;
          
          if upcase(name)='MEAN+SE' then do;
            __dispname=upcase(__dispname);
            __dispname=tranwrd(strip(__dispname), "MEAN", "$MEAN$");
            __dispname=tranwrd(strip(__dispname), "SE", "$STDERR$");
           
          end;
          if upcase(name)='MIN+MAX' then do;
            __dispname=upcase(__dispname);
            __dispname=tranwrd(strip(__dispname), "MIN", "$MIN$");
            __dispname=tranwrd(strip(__dispname), "MAX", "$MAX$");
          end;
          
          
          if upcase(name)='STD' then __dispname='STD';
          if upcase(name)='STDERR' then __dispname='STDERR';
          output;
     end;
     run;
%end;

%else %do;
  proc sort data=__varinfo (where=(statsetid="&statsetid" and type="STATDEF"))
      out = __contstatlist;
      by varid;
  run;
    
  data  __contstatlist;
    set __contstatlist;
    keep name label basedec;
    run;
%end;



data __contstatlist ;
set __contstatlist;
length __fname __name  __disp $ 2000;
__overall=0;
__fname=name;
__disp=dequote(trim(left(label)));
__order=_n_;
__sid=0;
__basedec=.;
__name=name;

  if index(__name,'.')<=0 then __model=0;
  else __model=1;

if notdigit(trim(left(basedec)))=0 then do;
__basedec=input(basedec,12.);
end;
else do;
    call symput('decvar', compress(basedec));
end;

__fname=upcase(__fname);

if __fname='MEAN+SD' then __fname='MEAN+STD';
if __fname='MEAN+SE' then __fname='MEAN+STDERR';

if index(__name,'.')<=0 then do;
  do i=1 to countw(__fname,'+');
    __fname=upcase(__fname);
    __name=scan(__fname,i); 
    __sid+1;
    output;
  end;
end;

else do;
  
  __name=__fname;
  output;
end;
keep __order __sid __name __fname __disp __basedec __model __dispname;
run;

%local i vnames vtmp;



%* CREATE A VARIABLE HOLDING NUMBER OF DECIMAL PLACE;
     
%if %length(&decvar)=0 %then %do;
  
    %* &DECVAR IS MACRO VARIABLE HOLDING VARIABLE NAME ;
    %*  THAT HOLDS BASE DECIMAL PRECISION;
       data __contstatlist;
       set __contstatlist;
        %if %length (&basedec)<=0 %then %do;
          %let basedec=0;
        %end;
        if __name in('N','NMISS') then __basedec=0;
       
       else __basedec = &basedec + input(upcase(__name), &decinfmt);
       run;
%end;     


%* CREATE A DATASET HOLDING MODEL BASED STATISTICS;

data __contstatlist __contstatlistm;
  length __modelname $ 200;  
set __contstatlist;
if index(__fname,'.')<=0 then output __contstatlist;
else do;
    __fname = upcase(__fname);
    __modelname = scan(__fname,1,'.');
    __overall=0;
    output __contstatlistm;
end;    
run;

%* SELECT WHICH STATISTICS ARE TO BE CALCULATED BY PROC MEANS;

%local statlist statlist2 gmean nmiss;
proc sql noprint;
  select cats(__name,"=",__name) into: statlist2 separated by ' ' 
    from __contstatlist (where=(__model=0 and upcase(__name) not in ('GMEAN','NMISS')));
  select __name into: statlist separated by ' ' 
    from __contstatlist (where=(__model=0));
  select __name into: gmean separated by ' '
    from __contstatlist (where=(__model=0 and upcase(__name) = 'GMEAN'));
  select __name into: nmiss separated by ' '
    from __contstatlist (where=(__model=0 and upcase(__name) = 'NMISS'));

quit;

/*
%if %length(&statlist)=0 %then %do;
  data __contstat2;
    if 0;
  run;
%end;
*/
/*
%* create "template" including all statistics and groupign variables;

%* determine which grouping variables have template defined;
%local i gv_wt gv_nt gdsset tmp;
proc sql noprint;
  select value into:gdsset separated by ' ' from __rrgpgminfo
    (where=(key='gtemplate'));
quit;

%if %length(&groupby) %then %do;
    proc sql noprint;
    %do i=1 %to %sysfunc(countw(&groupby,%str( )));
        %let tmp=;
        select value into:tmp separated by ' ' from __rrgpgminfo
        (where=(
        upcase(value)=upcase("__grp_template_"||"%scan(&groupby,&i,%str( ))")
        ));
        %if %length(&tmp) %then %let gv_wt=&gv_wt %scan(&groupby,&i,%str( ));
        %else %do;
            %let gv_nt=&gv_nt %scan(&groupby,&i,%str( ));
        %end;
    %end;
    quit;
%end;

%local tmp;

%local tmp_wt tmp_nt ;
%let tmp_nt = %sysfunc(tranwrd(%sysfunc(compbl(&by &trtvars 
      __tby &gv_nt)) , 
       %str( ), %str(,)));
*/

data rrgpgmtmp;
length record $ 2000;
keep record;
record=" "; output;
record="  data &outds;"; output;
record="  if 0;"; output;
record=" "; output;
record="  *-------------------------------------------------------------;"; output;
record="  *  CALCULATE STATISTICS FOR &VAR      ;"; output;
record="  *-------------------------------------------------------------;"; output;
record=" "; output;
record="  data __contstat2; if 0; run;"; output;
record=" "; output;
run;

proc append data=rrgpgmtmp base=rrgpgm;
run;

%if %length(&statlist)=0 %then %do;
  %* IF &STAT HAS ONLY MODEL-BASED STATISTICS THEN SKIP THE REST OF STEPS;
  data __contstat2;
    if 0;
  run;
  %goto mstat;
%end;


data rrgpgmtmp;
length record $ 2000;
keep record;
set __contstatlist end=eof;

if missing(__basedec) then do;
  __basedec=0;

end;


if _n_=1 then do;
    record="  data __contstatlist;"; output;
    record="    length __fname __name __disp __dispname $ 2000;"; output;
    record=" "; output;
end;

record="    __fname     = '"||strip(__fname)|| "';"; output;
record="     __name     = '"|| strip(__name)|| "';"; output;
record="     __disp     = '"||strip(__disp)|| "';"; output;
record="     __dispname = '"||strip(__dispname)|| "';"; output;
record="    __order     = " ||put(__order, best.)|| ";"; output;
record="      __sid     = " ||put( __sid, best.)|| ";"; output;
record="  __basedec     = " ||put(__basedec, best.)|| ";";   output;
record="    __model     = " ||put( __model, best.)|| ";"; output;
record="  output;"; output;
record=" "; output;

if eof then do;
    record=" "; output;
    record="  run;"; output;
end;
run;

proc append data=rrgpgmtmp base=rrgpgm;
run;

data rrgpgmtmp;
length record $ 2000;
keep record;
record=" "; output;
record="  *------------------------------------------------------------------;"; output;
record="  * SELECT ONLY UNIQUE RECORDS PER GROUPING VARIABLE;"; output;
record="  *------------------------------------------------------------------;"; output;
record=" "; output;
%local tmp; output;
%let tmp = %sysfunc(tranwrd(%sysfunc(compbl(&by &trtvars  
      __tby &groupvars &decvar  &unit &var)) , 
       %str( ), %str(,)));
     

record="  proc sql noprint;"; output;
record="       create table __contds2 as select distinct"; output;
record="       &tmp"; output;
record="       from __dataset (where=( "|| strip(symget("defreport_tabwhere"))||" and "||strip(symget("where")) ||"))"; output;
record="       order by "; output;
record="       &tmp;"; output;
record="  quit;"; output;
record=" "; output;
record=" "; output;
record=" "; output;
record="  data __contds2;";output;
record="  set __contds2;";output;
record="  by &by &trtvars __tby &groupvars &decvar  &unit &var;";output;
%if %length(&decvar) %then %do;
    record="  if missing(&decvar) then &decvar=0;";output;
%end;  
record="  if first.%scan(&unit,-1,%str( )) then output;";output;
record="  if not first.%scan(&unit,-1,%str( )) or not last.%scan(&unit,-1,%str( )) then do;";output;
record="  put 'WAR' 'NING: duplicate data for ' %scan(&unit,-1,%str( ))= &var=;";output;
record="  end;";output;
record="  run;";output;
record=" ";output;
record="  *------------------------------------------------------------------;";output;
record="  * PERFORM CALCULATIONS USING PROC MEANS;";output;
record="  *------------------------------------------------------------------;";output;
record=" "; output;
record="  proc means data=__contds2 noprint;";output;
record="     by &by &trtvars __tby &groupvars &decvar;";output;
record="     var &var;";output;
record="     output out=__contstat ";output;
record="     &statlist2;";output;
record="  run;";output;
record=" ";output;
%if %length(&gmean)>0 %then %do;
    record="  *-----------------------------------------------------;";output;
    record="  * CALCULATE GEOMETRIC MEAN;";output;
    record="  *-----------------------------------------------------;";output;
    record=" ";output;
    record="    data __contds2;";output;
    record="      set __contds2;";output;
    record="      __gmean = log(&var);";output;
    record="    run;";output;
    record=" ";  output;
    record="    data __constatg;";output;
    record="      if 0;";output;
    record="    run;";output;
    record=" ";  output;
    record="    proc means data=__contds2 noprint;";output;
    record="       by &by &trtvars __tby &groupvars &decvar;";output;
    record="       var __gmean;";output;
    record="       output out=__contstatg mean=gmean;";output;
    record="    run;";output;
    record=" ";output;
    record="    data __contstatg;";output;
    record="      set __contstatg;";output;
    record="      gmean = exp(gmean);";output;
    record="    run;";output;
    record=" ";  output;
    record="    data __contstat;";output;
    record="      merge __contstat __contstatg;";output;
    record="      by &by &trtvars __tby &groupvars &decvar;";output;
    record="    run;    ";output;
    record=" ";output;
%end;

%if %length(&nmiss)>0 %then %do;
      record=" ";output;
      record="  *-----------------------------------------------------;";output;
      record="  * CALCULATE NUMBER OF MISSING;";output;
      record="  *-----------------------------------------------------;";output;
      record=" ";output;


      %* calculate number of missing;

      %local tmp tmp4pop;
      %let tmp = %sysfunc(compbl(&trtvars __tby &by &groupvars));
      %let tmp = %sysfunc(tranwrd(&tmp, %str( ), %str(,)));
      %let tmp4pop = %sysfunc(compbl(&popgrp &trtvars __pop));
      %let tmp4pop = %sysfunc(tranwrd(&tmp4pop, %str( ), %str(,)));

      record="  proc sql noprint;";output;
      record="    create table __nm as select count(*) as __totn, &tmp";output;
      record="    from (select distinct &tmp, &unit from __dataset (where=(&var ne . and "; output;
      record=   strip(symget("defreport_tabwhere")) || " and "  || strip(symget("where")) ||")))";output;
      record="    group by &tmp";output;
      record="    order by &tmp";output;
      record="    ;";output;
      record=" ";output;
      record="  create table __nmiss as select * from ";output;
      record="    (select * from __nm) natural left join ";output;
      record="    (select distinct &tmp4pop as __ptot from __pop) ;";output;
      record=" ";  output;
      record="  quit;";output;
      record=" ";  output;
      record="    data __nmiss;";output;
      record="    set __nmiss;";output;

      record="      if __totn=. then __totn=0;";output;
      record="      nmiss= __ptot-__totn;";output;
      record="      drop __totn __ptot;";output;
      record="    run;";output;
      record=" ";  output;
      record="    proc sort data=__nmiss;";output;
      record="      by  &trtvars __tby &by &groupvars;";output;
      record="    run;";output;
      record=" ";output;
      record="    proc sort data=__contstat;";output;
      record="      by &trtvars __tby &by &groupvars;";output;
      record="    run;";output;
      record=" ";output;
      record="    data  __contstat;";output;
      record="      merge __contstat __nmiss;   ";output;
      record="      by  &trtvars __tby &by &groupvars;";output;
      record="    run;";output;
      record=" ";output;


%end;





record="  *------------------------------------------------------------------;";output;
record="  * CHECK IF ANY STATISTICS ARE CALCULATED;";output;
record="  * IF NOT THEN CREATE DUMMY OUTPUT DATASET SHOWING N WITH VALUE=0;";output;
record="  *------------------------------------------------------------------;";output;
record=" ";output;
run;

proc append data=rrgpgmtmp base=rrgpgm;
run;

***;

%* create "template" including al statistics nd groupign variables;

%* determine which grouping variables have template defined;
%local i gv_wt gv_nt gdsset tmp;
proc sql noprint;
  select value into:gdsset separated by ' ' from __rrgpgminfo
    (where=(key='gtemplate'));
quit;

%if %length(&groupby) %then %do;
    proc sql noprint;
    %do i=1 %to %sysfunc(countw(&groupby,%str( )));
      %let tmp=;
      select value into:tmp separated by ' ' from __rrgpgminfo
      (where=(
      upcase(value)=upcase("__grp_template_"||"%scan(&groupby,&i,%str( ))")
      ));
      %if %length(&tmp) %then %let gv_wt=&gv_wt %scan(&groupby,&i,%str( ));
      %else %do;
        %let gv_nt=&gv_nt %scan(&groupby,&i,%str( ));
      %end;
    %end;
quit;
%end;

%local tmp;

%local tmp_wt tmp_nt ;
%let tmp_nt = %sysfunc(tranwrd(%sysfunc(compbl(&by &trtvars 
      __tby &gv_nt)) , 
       %str( ), %str(,)));
       
       

data rrgpgmtmp;
length record $ 2000;
keep record;




record = " ";                                                                                                             output;
record =   "data __contstat0;";                                                                                           output;
record =  ' length __name $ 2000;';                                                                                       output;
record =  "   __statlist = compbl(upcase('"|| "&statlist"|| "'));";                                                           output;
record =  "   do __i =1 to  countw(__statlist, ' ') ;";                                                                   output;
record =  "      __name = scan(__statlist,  __i, ' ');";                                                                  output;
record =  '      output;';                                                                                                output;
record =  '   end;';                                                                                                      output;
record =  " drop __i __statlist;";                                                                                        output;
record =   "run;";                                                                                                        output;
record = " ";                                                                                                             output;

%if %length(&gv_wt) %then %do;
    record =  "proc sql noprint nowarn;";                                                                                 output;
    record =  "  create table __tmp1 as select * from ";                                                                  output;
    record =  "  (select distinct";                                                                                       output;
    record =  "     &tmp_nt";                                                                                             output;
    record =  "     from __dataset (where=( "|| strip(symget("templatewhere")) ||")))";                                                      output;
    record =  "     cross join __grpcodes;";                                                                              output;
    record =  "  create table __tmp as select * from ";                                                                   output;
    record =  "  __tmp1 cross join __contstat0;";                                                                         output;
%end;
%else %do;
    record =  "proc sql noprint nowarn;";                                                                                 output;
    record =  "  create table __tmp as select * from ";                                                                   output;
    record =  "  (select distinct";                                                                                       output;
    record =  "     &tmp_nt";                                                                                             output;
    record =  "     from __dataset (where=( "|| strip(symget("templatewhere")) ||")))";                                                      output;
    record =  "     cross join __contstat0;";                                                                             output;
%end;

record =  "  create table __contstat0 as select * from __tmp order by __name;";                                           output;
record =  "quit;";                                                                                                        output;
record = " ";                                                                                                             output;
record = " ";                                                                                                             output;
record =  '  proc sort data=__contstatlist;';                                                                             output;
record =  '    by __name;';                                                                                               output;
record =  '  run;';                                                                                                       output;
record = " ";                                                                                                             output;
record =  '  data __contstat0;';                                                                                          output;
record =  '    merge __contstat0 (in=__a) __contstatlist ';                                                               output;
record =  '    (keep=__fname __name __order __sid __disp __dispname __basedec);';                                         output;
record =  '    by __name;';                                                                                               output;
record =  '    if __a;';                                                                                                  output;
record =  '  run;  ';                                                                                                     output;
record = " ";                                                                                                             output;
%* end of template;



record = " ";                                                                                                             output;
record =  '%local dsid rc nobs;';                                                                                         output;
record =  '%let dsid =%sysfunc(open(__contstat));';                                                                       output;
record =  '%let nobs = %sysfunc(attrn(&dsid, NOBS));';                                                                    output;
record =  '%let rc=%sysfunc(close(&dsid));';                                                                              output;
record = " ";                                                                                                             output;
record =  '%if &nobs>0 %then %do;';                                                                                       output;
record = " ";                                                                                                             output;
record = " ";                                                                                                             output;
record = " ";                                                                                                             output;
record = " ";                                                                                                             output;
record =  '  data __contstat;';                                                                                           output;
record =  '    set __contstat;';                                                                                          output;
record =  '    length __name __statlist $ 2000;';                                                                         output;
record =  "    __statlist = upcase('"||strip( "&statlist")|| "');";                                                                  output;
record =  "    array stats{*} &statlist;";                                                                                output;
record =  '      do __i =1 to dim(stats);';                                                                               output;
record =  "        __name = scan(__statlist,  __i, ' ');";                                                                output;
record =  '        __val = stats[__i];';                                                                                  output;
record =  '        output;';                                                                                              output;
record =  '      end;';                                                                                                   output;
record =  "      drop __statlist &statlist;";                                                                             output;
record =  '    run;';                                                                                                     output;
record = " ";                                                                                                             output;
record =  '  proc sort data=__contstat;';                                                                                 output;
record =  "    by &by &trtvars __tby &groupvars  __name;";                                                                output;
record =  '  run;';                                                                                                       output;
record = " ";                                                                                                             output;
record =  '  proc sort data=__contstat0;';                                                                                output;
record =  "    by &by &trtvars __tby &groupvars  __name;";                                                                output;
record =  '  run;';                                                                                                       output;
record = " ";                                                                                                             output;
record =  '  data __contstat;';                                                                                           output;
record =  '    merge __contstat  __contstat0(in=__a); ';                                                                  output;
record =  "    by &by &trtvars __tby &groupvars  __name;";                                                                output;
record =  "   if __a;";                                                                                                   output;
record =  "      if upcase(__name)='N' and __val=. then __val=0;";                                                        output;
record =  '  run;  ';                                                                                                     output;
record = " ";                                                                                                             output;
record =  '%end;';                                                                                                        output;

record=" ";output;
record=  '%else %do;';output;
record=" ";output;

record=" ";output;
record="      data __contstat;";output;
record="      set __contstat0;";output;
record="      if upcase(__name)='N' then __val=0;";output;
record=  '  run;  ';output;
record=" ";output;
record=  '%end;';output;



record=" ";output;
record=" ";output;
record="  *--------------------------------------------------------------;"; output; 
record="  * PRINT STATISTICS USING APPROPRIATE NUMBER OF DECIMAL PLACES;  ";output;
record="  *--------------------------------------------------------------;";output;
record=" ";output;
record="  data __contstat2;";output;
record="   set  __contstat;";output;
record="   length __col $ 2000;";output;
%if %length(&decvar)>0 %then %do;
    record="     if missing(&decvar) then &decvar=0;";output;
    record="     if __name in ('N','NMISS') then __basedec=0;";output;
    record="     else __basedec = &decvar + input(upcase(__name), &decinfmt);";output;
%end;
%if %length(&maxdec) %then %do;
    record="     if   __basedec>&maxdec then __basedec = &maxdec;";output;
%end;
record="         length __decfmt $ 20;";output;
record="         __decfmt = '12.'; ";output;
record="         if __basedec>0 then __decfmt = cats(__decfmt, __basedec);";output;
  
record=" ";output;


record=" ";output;

record="  *--------------------------------------------------------------;";output;
record="  * CREATE DISPLAY OF STATISTICS (FORMAT);";output;
record="  *--------------------------------------------------------------;";output;

record="     __sign='';";output;
record="     if __name='PROBT' then do;";output;
record="       if __val ne . then do;"; output;
record="         __val2=round(__val, 0.000000001);";output;
record="         __col = put(__val2, &pvfmt);";output;
record="       end;"; output;
record="       else __col='';"; output;
record="     end;";output;
record="     else do;"; output;
record="        if not missing(__val) then do;"; output;
record="          if __val<0 then __sign='-';"; output;
record="           __val2 = round(__val, 10**(-1*__basedec));";output;
record="           __col = compress(putn(__val2, __decfmt));";output;
record="        end;";output;
record="        else __col='';"; output;
record="     end;";output;

%if %length(&condfmt) %then %do;
   %__condfmt(condfmt=%nrbquote(&condfmt));
%end;

record=" ";output;

%if %upcase(&showneg0)=Y %then %do;
  record="    if compress(__col,'0.')='' and __sign='-' and __col ne '' then __col='-'||strip(__col);";output;
%end;
%else %do;
  record="    if compress(__col, '-0.')='' then __col = tranwrd(__col,'-','');";output;
%end;

record="     drop   __sign;";output;
record="     run;";output;
record=" ";output;
record=" ";output;
record="  *--------------------------------------------------------------;";output;
record="  * PUT STATISTICS ON THE SAME LINE, IF NEEDED;";output;
record="  *--------------------------------------------------------------;";output;
record=" ";output;
record="  proc sort data=__contstat2;";output;
record="    by &by &trtvars __tby &groupvars __order __sid ;";output;
record="  run;";output;
record=" ";output;
record=" ";output;
record="  data __contstat2;";output;
record="  set __contstat2;";output;
record="  by &by &trtvars __tby &groupvars __order __sid ;";output;
record="  length __ncol $ 2000 __tmpalign $ 8;";output;
record="     retain __ncol;";output;
record=" ";     output;
record="  if first.__order and last.__order then do;";output;
record="    __ncol =upcase(__name);";output;
record="    __col =tranwrd(strip(__ncol), strip(upcase(__name)), strip(__col));";output;
record="    if compress(__col, '.,(): ')='' then __col='';     ";   output;
record="    if __name in ('STD', 'STDERR') and __col='' then  __col='-';"; output;
record="    __tmpalign = cats('"|| "&align"|| "');";   output;
record="    output;";   output;
record="  end;";output;

record="  else do;";output;
record="    if first.__order then __ncol =__dispname;";output;

record="       __ncol =tranwrd(strip(__ncol), '$'||strip(upcase(__name))||'$', strip(__col));";output;
record="       if last.__order then do;";output;

record="          if compress(__ncol, '.,(): ')='' then __ncol='';     ";output;
record="          if __name in ('STD', 'STDERR') then __ncol=tranwrd(__ncol,'( )','(-)');"; output;

record="          __col=strip(__ncol);";output;

record="    __tmpalign = cats('"|| "&align"|| "');"; output;
record="          output;";output;
record="       end;";output;
record="  end;";output;

record="run;";output;

record="                                               ";output;
record="  data __contstat2;";output;
record="  set __contstat2;";output;
record="     __col = tranwrd(strip(__col),'(.','(NA');";output;
record="  run;"; output;

run;

proc append data=rrgpgmtmp base=rrgpgm;
run;

%* MODEL BASED STATISTICS;
%* DETERMINE HOW MANY MODELS;
%* FOR EACH MODEl:;
%*  CALL PLUGIN MACRO;
%*  CREATE __CONTSTATLISTx DATASET;
%*  DETERMINE WHICH GROUPING VARIABLES ARE IN PLUGIN DATASET;
%*  MERGE PLOGIN DATAESET WITH __TRT DATASET;
%*  TRANSPOSE PLUGIN DATASET TO GET STAT_VALUE IN COLUMNS;
%*  GET STATLABELS AND ALIGNMENTS;
%*  MERGE WITH __CONTSTATLISTx DATASET;
%*  ApPEND TO __CONTSTAT3;

%mstat:




%if %length(&ovstat)>0 %then %do;
    data __contstatlistm2;
      length __fname __name  __ovstat $ 2000 __modelname $ 200;  
      __overall=1;
      __ovstat=trim(left(symget("ovstat")));
     do __i=1 to countw(__ovstat,' ');
         __fname = upcase(scan(__ovstat,__i,' '));
         __modelname=scan(__fname, 1, '.');
         __name = scan(__fname, 2, '.');
         __order = __i;
          output;
     end;
    run;

    data __contstatlistm;
      set __contstatlistm __contstatlistm2;
    run;


%end;


%local dsid rc nobs i nmodels;
%let dsid =%sysfunc(open(__contstatlistm));;
%let nobs = %sysfunc(attrn(&dsid, NOBS));;
%let rc=%sysfunc(close(&dsid));;

%if &nobs>0  %then %do;
    proc sort data=__contstatlistm;
      by __modelname;
    run;
    
    data __contstatlistm;
      set __contstatlistm end=eof;
      by __modelname;
      retain __modelnum ;
      if _n_=1 then __modelnum=0;
      if first.__modelname then __modelnum+1;
      if eof then call symput("nmodels", cats(__modelnum));
    run;


    data rrgpgmtmp;
    length record $ 2000;
    keep record;
        set __contstatlistm end=eof;
        if _n_=1 then do;      
            %if %length(&ovstat) %then %do;
                record="    data __overallstats0;";output;
                record="    if 0;";output;
                record="    run;";output;
                record=" ";output;
            %end;
            record="  *-----------------------------------------------------;";output;
            record="  * CREATE A LIST OF REQUESTED MODEL-BASED STATISTICS   ;";output;
            record="  *-----------------------------------------------------;";output;
            record=" ";output;
            record="    data __modelstat;";output;
            record="      length __fname __name __disp  $ 2000;";output;
            record=" ";output;
        end;
        
        record="      __overall = "||put(__overall,best.)|| ";";      output;
        record="        __fname = '" ||strip(__fname)|| "';";output;
        record="         __name = '" ||strip(__name)|| "';";output;
        record="         __disp = '"|| strip(__disp)|| "';";output;
        record="        __order = "||put( __order,best.)|| ";";output;
        record="          __sid = "||put( __sid,best.)|| ";";output;
        record="      __basedec = "||put( __basedec,best.)|| ";";  output;
        record="    output;";output;
        record=" ";output;
        if eof then do;
            record=" ";output;
            record="    run;";output;
            record=" ";output;
            record=" ";output;
      
            record="  *-------------------------------------------------------------;";output;
            record="  * PREPARE DATASET FOR CUSTOM MODEL, REMOVING POOLED TREATMENTS;";output;
            record="  *-------------------------------------------------------------;";output;
            record=" ";output;
            
            record="  data __datasetp;";output;
            record="  set __dataset(where=("|| strip(symget("defreport_tabwhere"))|| " and "|| strip(symget("where")) || " &pooledstr));";output;
           
            %if %length(&decvar)=0 %then %do;
                record="  __decvar=&basedec;";output;
                record="  if missing(__decvar) then __decvar=0;";output;
            %end;
            %else %do;
               record="  if missing(&decvar) then &decvar=0;";output;
            %end;
           
            record="  run;";output;
            record=" ";output;
        end;
      run;
      
      proc append data=rrgpgmtmp base=rrgpgm;
      run;
    
      %do i = 1 %to &nmodels;
      
          data __modelstat;
            set __contstatlistm;
            if __modelnum=&i;
            length __fname $ 2000;
            call symput("currentmodel", cats(__modelname));
          run; 
         
           
          %local nmoddef; 
          %let nmoddef=0;
          
          data __modelp;
            set __varinfo
            (where=  (upcase(model) = upcase("&currentmodel")));
          run;

          proc sql noprint;
            select count(*) into:nmoddef from __modelp;
          quit;
          
          %if &nmoddef>0 %then %do;
              proc sort data=__modelp nodupkey;
                by model;
              run;  
          %end;
          %else %do;
              data __modelp;
                length name $ 2000;
                name = "&currentmodel";
                parms='';
              run;
          %end;
        
        
          %local modelds;
          
          data _null_;
            set __modelp end=eof;
            if eof then  call symput ('modelds', cats(name));
            run;
          
      
   
      
          data rrgpgmtmp;
          length record $ 2000;
          keep record;
          *length __macroname2  $ 2000;
          set __modelp end=eof;
          *__macroname2 = cats('%', name,'(');
          record=" ";output;
         
          /*record=strip(__macroname2); output;*/
          record=strip(cats('%', name,'('));output;
          record="     var=&var,";output;
          record="     trtvar=&trtvars,";output;
          record="     groupvars=&by &groupby,";    output;
          record="     dataset=__datasetp,";output;
          %* todo: decvar to custom parameters;
          %if %length(&decvar)=0 %then %do;
              record="     decvar=__decvar,";output;
          %end;
          %else %do;
              record="     decvar=&decvar,";output;
          %end;
          if parms ne '' then do;
              record=strip(parms)||",";output;
          end;
          record="     subjid=&subjid);";output;
          record=" ";output;
          
          
          if eof then do;
              
          
              %* collect overall statistics;
              %if %length(&ovstat) %Then %do;
              
                  record="  *---------------------------------------------------------;";output;
                  record="  * ADD OVERALL STATISTICS TO DATASET THAT COLLECTS THEM;";output;
                  record="  *---------------------------------------------------------;";output;
                  record=" ";output;
                  record=   'data __overallstats0;';output;
                  record="  length __fname $ 2000;";output;
                  record="  set __overallstats0 &modelds(in=__a where=(__overall=1));";output;
                  record="  __blockid = &varid;";output;
                  record="  if __a then __fname = upcase(cats('"||"&currentmodel"|| "','.',__stat_name));";output;
                  record=  'run;';output;
                  record=" ";output;
              %end;
              
            
              record=" "; output;
              record=" ";output;
              record="  *---------------------------------------------------------;";output;
              record="  * MERGE LIST OF REQUESTED MODEL-BASED STATISTICS      ;";output;
              record="  * WITH DATASET CREATED BY PLUGIN;";output;
              record="  * KEEP ONLY REQUESTED STATISTICS FROM CURRENT MODEL;";output;
              record="  *---------------------------------------------------------;";output;
              record=" ";output;
              record="    data __mdl_&modelds;";output;
              record="      length __fname $ 2000;";output;
              record="      set &modelds;";output;
              record="      if __overall ne 1;";output;
              record="      __fname = upcase(cats('"|| "&currentmodel"|| "', '.', __stat_name));";output;
              record="    run;";output;
              record=" ";output;
              
              
              record="  *---------------------------------------------------------;";output;
              record="  * CHECK IF PLUGIN PRODUCED ANY WITHIN-TREATMENT STATISTICS;";output;
              record="  *---------------------------------------------------------;";output;
              record=" ";output;
              record=   '%local dsid rc nobs;';output;
              record=   '%let dsid =';output;
              record=  '  %sysfunc(open('|| "__mdl_&modelds ));;";output;
              record=  '%let nobs = %sysfunc(attrn(&dsid, NOBS));;';output;
              record=  '%let rc=%sysfunc(close(&dsid));;';output;
              record=" ";output;
              record=  '%if &nobs>0 %then %do;';output;

              record="    proc sort data=__mdl_&modelds;";output;
              record="      by __fname __overall;";output;
              record="    run;";output;
              record="    proc sort data=__modelstat;";output;
              record="      by __fname __overall;";output;
              record="    run;";output;
              record=" ";output;
         
              record="    data __mdl_&modelds;";output;
              record="    length __disp __col __tmpdisp __tmpcol  $ 2000 __tmpalign __tmpal $ 8;";   output;  
              record="      merge __mdl_&modelds (in=__a) __modelstat (in=__b);";output;
              record="      by __fname __overall;";output;
              record="      __sid=__stat_order;";output;
              record="      if __a and __b;";output;
              record="      __tby=1;";output;
              record="      __tmpdisp = __stat_label;";output;
              record="      __tmpal = __stat_align;";output;
              record="      __tmpcol = cats(__stat_value);";output;
              record="      if index(__tmpdisp, '//')=1 then __tmpdisp='~-2n'||substr(__tmpdisp, 3);";      output;
              record="      __tmpal = tranwrd(__tmpal, '//', '-');";output;
              record="      __nline = countw(__tmpal,'-');";output;
              record="      do __i =1 to __nline;";output;
              record="         if index(__tmpdisp, '//')>0 then do;";output;
              record="           __disp = substr(__tmpdisp, 1, index(__tmpdisp, '//')-1); ";output;
              record="           __tmpdisp = substr(__tmpdisp, index(__tmpdisp, '//')+2); ";output;
              record="         end;";output;
              record="         else do;";output;
              record="           __disp = trim(left(__tmpdisp)); ";output;
              record="         end;";output;
              record="         if index(__tmpcol, '//')>0 then do;";output;
              record="           __col = substr(__tmpcol, 1, index(__tmpcol, '//')-1); ";output;
              record="           __tmpcol = substr(__tmpcol, index(__tmpcol, '//')+2); ";output;
              record="         end;";output;
              record="         else do;";output;
              record="           __col = trim(left(__tmpcol)); ";output;
              record="         end;";output;
              record="         __sid = __sid + (__i-1)/__nline;";output;
              record="         __tmpalign = scan(__tmpal,__i, '-');";output;
              record="         output;";output;
              record="      end;";output;
              record="      drop __stat_align __stat_order __stat_label __overall __nline";output;
              record="           __tmpal __tmpcol __tmpdisp;";    output;
              record="    run;";output;
              record=" ";output;
              record=" ";output;
              record="    proc sort data=__mdl_&modelds;";output;
              record="    by __order __sid __fname &trtvars &by &groupby;";output;
              record="    run;";output;
              record=" ";output;
              record="    data __mdl_&modelds (drop = __order rename=(__tmporder=__order));";output;
              record="    set __mdl_&modelds;"; output;
              record="    by __order __sid __fname &trtvars &by &groupby;";  output;
              record="      retain __tmporder;";output;
              record="      if first.__order then __tmporder=__order;";output;
              record="      if first.__sid then __tmporder+0.0001;";output;
              record="    run;";output;
              record=" ";output;
              record="  *---------------------------------------------------------;";output;
              record="  * ADD PLUGIN-GENERATED STATISTICS TO OTHER STATISTICS;";output;
              record="  *---------------------------------------------------------;";output;
              record=" ";output;
              record="    data __contstat2;";output;
              record="      set __contstat2 __mdl_&modelds;";output;
              record="    run;  ";output;
              record=" ";output;
              record=   '%end;';output;
          
          end;
          run;
          
          proc append data=rrgpgmtmp base=rrgpgm;
          run;

      %end;
  
  
      data rrgpgmtmp;
      length record $ 2000;
      keep record;
      record=" "; output;
      record=" ";output;
      %if %length(&ovstat) %then %do;
          record="  *---------------------------------------------------------;";output;
          record="  * COLLECT REQUESTED OVERALL STATISTICS ;";output;
          record="  * ADD TO DATASETS __OVERALLSTAT;";output;
          record="  *---------------------------------------------------------;";output;
          record=" ";output;
          record="  proc sort data=__modelstat;";output;
          record="    by __fname __overall;";output;
          record="  run;";output;
          record=" ";output;
          record="  proc sort data=__overallstats0;";output;
          record="    by __fname __overall;";output;
          record="  run;";output;
          record=" ";output;
          record="  data __overallstats0;";output;
          record="    merge __overallstats0(in=__a) __modelstat (in=__b);";output;
          record="    by __fname __overall;";output;
          record="    if __a and __b;";output;
          record="  run;";output;
          record=" ";output;
          record="  data __overallstats;";output;
          record="    set __overallstats __overallstats0;";output;
          record="  run;";output;
          record=" ";output;
      %end;
    run;
    
    proc append data=rrgpgmtmp base=rrgpgm;
    run;

%end;

data rrgpgmtmp;
length record $ 2000;
keep record;
record=" ";output;
record="  *----------------------------------------------------------------;";output;
record="  * MERGE WITHIN-TRT STATS WITH DATASET HAVING ALL TREATMENTS;";output;
record="  *----------------------------------------------------------------;";output;
record=" ";output;


%__joinds(data1 = __contstat2,
        data2 = __trt ,
           by = &trtvars,
    mergetype = inner,
      dataout = __contstat3);
      
     

record=" ";output;
record="  *----------------------------------------------------------------;";output;
record="  * TRANSPOSE DATASET;";output;
record="  *----------------------------------------------------------------;";output;
record=" ";output;

record=" ";output;

record="  proc sort data=__contstat3;";output;
record="     by  &by &groupvars __tby __order  __fname  __disp __tmpalign;";output;
record="  run;";output;
record=" ";output;

record=  '%local dsid rc nobs;';output;
record=  '%let dsid =%sysfunc(open(__contstat3));';output;
record=  '%let nobs = %sysfunc(attrn(&dsid, NOBS));';output;
record=  '%let rc=%sysfunc(close(&dsid));';output;
record=" ";output;
record=  '%if &nobs>0 %then %do;';output;
record=" ";output;

record="    proc transpose data=__contstat3 out=__contstat4 prefix=__col_;";output;
record="      by &by &groupvars __tby  __order   __fname __disp __tmpalign;";output;
record="      id __trtid;";output;
record="      var __col;";output;
record="    run;";output;

record=" ";output;
record="  data __contstat4;";output;
record="  length __fname $ 2000;";output;
record="    set __contstat4 ;";output;
record="    if 0 then do; __col_x=''; __fname=''; end;";output;
record="    array cols{*} __col_:;";output;
record="      __keep=0;";output;
record="      do __i=1 to dim(cols);";output;
record="        if cols[__i] not in ('' ,'0') then __keep=1;";output;
record="      end;";output;
record="    if __fname='NMISS' and __keep=0 then delete;";output;
record="    drop __keep __i __col_x;";output;
record="  run;";output;

record=" ";output;
record="  *-----------------------------------------------------------------;";output;
record="  * DEFINE ALIGNMENTS, SKIPLINES, INDENTATION;";output;
record="  *-----------------------------------------------------------------;";output;
record=" ";output;
record=" ";output;
record= '%local i;';output;
record="  data &outds ;";output;
record="  set __contstat4;";output;
record="  by &by &groupvars __tby ;";output;
record=   'length __varlabel __col_0-__col_&maxtrt __align  $ 2000 ';output;
record="         __suffix __vtype $ 20 __skipline $ 1;";output;
record=" ";output;
record="  if 0 then do;";output;
record=   '  %do i=0 %to &maxtrt;';output;
record=   '    __col_&i ='|| "' ';";output;
record=   '  %end;';output;
record="  end;";output;
record="  array cols{*} __col_:;";output;
record="  __col_0 = __disp;";output;
record="  __align = 'L';";output;
length __label $ 2000;
__label = quote(dequote(trim(left(symget("label")))));
record=  '__varlabel = '||strip(__label)|| ';';output;
record=" ";output;
record="  __tmpalign = cats(__tmpalign,'_');";output;
record="    __align = trim(left(__align))||' '||repeat(__tmpalign,"|| '&maxtrt );';output;
record="  __align = tranwrd(__align,'_',' ');";output;
record=" ";output;
record="  __keepn=1;";output;
record="  __keepnvar='"|| "&keepn"|| "';";output;

%local ngrpv;
%let ngrpv=0;
%if %length(&groupvars) %then %let ngrpv = %sysfunc(countw(&groupvars,%str( )));

%if %upcase(&defreport_statsacross)=Y and &ngrpv>0 %then %do;
    record="  __indentlev=max(&indent+&ngrpv-1,0);";output;
%end;
%else %do;
    record="  __indentlev=&indent+&ngrpv;";output;
%end;

record="  __suffix='';  ";output;
record=" ";output;
record="  if last.__tby then do;";output;
%if "&keepn" ne "Y" %then %do;
    record="     __keepn=0;";output;
%end;
%if &skipline=Y %then %do;
    record="     __suffix='~-2n';";output;
%end;
record="  end;";output;
record=" ";output;
record="  __blockid=&varid;";output;
record="  __tmprowid=_n_;";output;

record="  __labelline=&labelline;";output;
record=" ";output;
%if &labelline=1 %then %do;
    record="  if first.__tby  then do;";output;
    record="     * FOR LABELLINE=1, PUT 1ST STATISTICS ON THE SAME LINE AS LABEL;";output;
    record="     __col_0 = trim(left(dequote(__varlabel)))||' '";output;
    record="         ||trim(left(__col_0));";output;
    record="  end;";output;
%end;
record=" ";output;
record="  __vtype='CONT';";output;
record=   '__grpid=999;';output;
record="    __skipline=cats('"|| "&skipline"|| "');";output;
record="  do __i = 1 to dim(cols);";output;
record="    if index(cats(cols[__i]),'-')=1 and compress(cols[__i], '-0.')='' and length(cols[__i])>=2 then ";output;
record="      cols[__i] = substr(cats(cols[__i]),2);";output;
record="      if upcase(__fname) in( 'N','NMISS')  and cols[__i]='' then cols[__i]='0';";output;
record="  end;";output;
record="  __tby=1;";output;
record=" ";output;
record="  drop __i;";output;
record="  run;";output;
record=" ";output;
record=   '%end;';output;
record=" ";output;

record=  '%exit'|| "c&varid:";output;
run;
         
proc append data=rrgpgmtmp base=rrgpgm;
run;



%exit:

%mend;

