/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __cont (
varid=,
tabwhere=, 
unit=, 
groupvars4pop=, 
groupvarsn4pop=,
by4pop=,
byn4pop=,
trtvars=,
outds=)/store;


data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
run;

%local varid tabwhere where unit var groupvars trtvars stat statsetid
       indent skipline   label labelline indent groupvars4pop groupvarsn4pop
       basedec basedecds outds align j outds by ovstat by4pop byn4pop
       decinfmt sdfmt keepn templatewhere popgrp popwhere groupvars  condfmt pvfmt;

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
  select trim(left(where))     into:where     separated by ' ' from  __contv;
  select trim(left(popwhere))  into:popwhere  separated by ' ' from  __contv;
  select trim(left(popgrp))    into:popgrp    separated by ' ' from  __contv;
  select trim(left(templatewhere))    
     into:templatewhere     separated by ' ' from  __contv;
  select trim(left(name))      into:var       separated by ' ' from  __contv;
  select trim(left(stat))      into:stat      separated by ' ' from  __contv;
  select trim(left(statsetid)) into:statsetid separated by ' ' from  __contv;
  select indent                into:indent    separated by ' ' from  __contv;
  select upcase(skipline)      into:skipline  separated by ' ' from  __contv;
  select trim(left(label))     into:label     separated by ' ' from  __contv;
  select labelline             into:labelline separated by ' ' from  __contv;
  select basedec               into:basedec   separated by ' ' from  __contv;
  select trim(left(align))     into:align     separated by ' ' from  __contv;
  select trim(left(ovstat))    into:ovstat    separated by ' ' from  __contv;
  select trim(left(sdfmt))     into:sdfmt     separated by ' ' from  __contv;
  select trim(left(slfmt))     into:slfmt     separated by ' ' from  __contv;
  select trim(left(pvalfmt))     into:pvfmt     separated by ' ' from  __contv;
  select trim(left(decinfmt))  into:decinfmt  separated by ' ' from  __contv;
  select trim(left(keepwithnext))   into:keepn  separated by ' ' from  __contv;
  select trim(left(condfmt))   into:condfmt  separated by ' ' from  __contv;
quit;

%*put 4iza slfmt=&slfmt sdfmt=&sdfmt;

%if %length(&where)=0 %then %let where=%str(1=1);
%if %length(&tabwhere)=0 %then %let tabwhere=%str(1=1);
%if %length(&templatewhere)=0 %then %let templatewhere = &where and &tabwhere;

%*put popgrp=&popgrp;
%if %length(&popgrp)=0 %then %let popgrp=&groupvars4pop &by4pop;
%*put popgrp=&popgrp;

%* BASEDEC CAN BE AN INTEGER OR THE NAME OF VARIABLE WITH INTEGER VALUES;
%* IF BASEDEC = VARIABLE NAME THEN SAVE THIS NAME IN &DECVAR;



%if  %sysfunc(notdigit(&basedec))>0 %then %do;
  %let decvar=&basedec;
%end;



%* LABELLINE=1 MEANS THAT 1ST STATISTIC IS TO BE PUT ON THE SAME;
%* LINE AS VARIABLE LABEL;
%* FOR TABLES WITH STATISTICS IN COLUMNS, THIS IS IGNORED,;
%* AS WELL AS INDENTATION;
   
%if %upcase(&Statsacross)=Y %then %do;
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

%*put 4iza statlist=&statlist;
%*put 4iza statlist2=&statlist2;

%* IF &STAT HAS ONLY MODEL-BASED STATISTICS THEN SKIP THE REST OF STEPS;
   

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put @1 "data &outds;";
put @1 "if 0;";
put @1 "run;";
put;
run;


data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put @1 "*-------------------------------------------------------------;";
put @1 "*  CALCULATE STATISTICS FOR &VAR      ;";
put @1 "*-------------------------------------------------------------;";
PUT;
put @1 "data __contstat2; if 0; run;";
put;
run;

%if %length(&statlist)=0 %then %do;
  %* IF &STAT HAS ONLY MODEL-BASED STATISTICS THEN SKIP THE REST OF STEPS;
  data __contstat2;
    if 0;
  run;
  %goto mstat;
%end;


data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
set __contstatlist end=eof;
/*put '4iza in contstatlist ' __basedec=;*/
if missing(__basedec) then do;
  __basedec=0;
/*  put '4iza __basedec is missing';*/
end;

/*put '4iza in contstatlist after setting to 0 ' __basedec=;*/
if _n_=1 then do;
  put @1 "data __contstatlist;";
  put @1 "  length __fname __name __disp __dispname $ 2000;";
  put;
end;

put @1 "  __fname = '" __fname "';";
put @1 "   __name = '" __name "';";
put @1 "   __disp = '" __disp "';";
put @1 "   __dispname = '" __dispname "';";
put @1 "  __order = " __order ";";
put @1 "    __sid = " __sid ";";
put @1 "__basedec = " __basedec ";";  
put @1 "  __model = " __model ";";
put @1 "output;";
put;

if eof then do;
  put;
  put @1 "run;";
end;
put;
run;

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
__tabwhere = cats(symget("tabwhere"));
__where = cats(symget("where"));
put;
put @1 "*------------------------------------------------------------------;";
put @1 "* SELECT ONLY UNIQUE RECORDS PER GROUPING VARIABLE;";
put @1 "*------------------------------------------------------------------;";
put;
%local tmp;
%let tmp = %sysfunc(tranwrd(%sysfunc(compbl(&by &trtvars 
      __tby &groupvars &decvar  &unit &var)) , 
       %str( ), %str(,)));
%*put 4iza decvar=&decvar;       

put @1 "proc sql noprint;";
put @1 "     create table __contds2 as select distinct";
put @1 "     &tmp";
put @1 "     from __dataset (where=( " __tabwhere " and " __where "))";
put @1 "     order by ";
put @1 "     &tmp;";
put @1 "quit;";
put;
put;
put;
put @1 "data __contds2;";
put @1 "set __contds2;";
put @1 "by &by &trtvars __tby &groupvars &decvar  &unit &var;";
%if %length(&decvar) %then %do;
  put @1 "if missing(&decvar) then &decvar=0;";
%end;  
put @1 "if first.%scan(&unit,-1,%str( )) then output;";
put @1 "if not first.%scan(&unit,-1,%str( )) or not last.%scan(&unit,-1,%str( )) then do;";
put @1 "put 'WAR' 'NING: duplicate data for ' %scan(&unit,-1,%str( ))= &var=;";
put @1 "end;";
put @1 "run;";
put;
put @1 "*------------------------------------------------------------------;";
put @1 "* PERFORM CALCULATIONS USING PROC MEANS;";
put @1 "*------------------------------------------------------------------;";
put; 
put @1 "proc means data=__contds2 noprint;";
put @1 "   by &by &trtvars __tby &groupvars &decvar;";
put @1 "   var &var;";
put @1 "   output out=__contstat ";
put @1 "   &statlist2;";
put @1 "run;";
put;
%if %length(&gmean)>0 %then %do;
put @1 "*-----------------------------------------------------;";
put @1 "* CALCULATE GEOMETRIC MEAN;";
put @1 "*-----------------------------------------------------;";
put;
put @1 "  data __contds2;";
put @1 "    set __contds2;";
put @1 "    __gmean = log(&var);";
put @1 "  run;";
put;  
put @1 "  data __constatg;";
put @1 "    if 0;";
put @1 "  run;";
put;  
put @1 "  proc means data=__contds2 noprint;";
put @1 "     by &by &trtvars __tby &groupvars &decvar;";
put @1 "     var __gmean;";
put @1 "     output out=__contstatg mean=gmean;";
put @1 "  run;";
put;
put @1 "  data __contstatg;";
put @1 "    set __contstatg;";
put @1 "    gmean = exp(gmean);";
put @1 "  run;";
put;  
put @1 "  data __contstat;";
put @1 "    merge __contstat __contstatg;";
put @1 "    by &by &trtvars __tby &groupvars &decvar;";
put @1 "  run;    ";
put;
%end;

%if %length(&nmiss)>0 %then %do;
      put;
      put @1 "*-----------------------------------------------------;";
      PUT @1 "* CALCULATE NUMBER OF MISSING;";
      put @1 "*-----------------------------------------------------;";
      put;

      %if %length(&popwhere)=0 %then %let popwhere=%str(1=1);

      %* calculate number of missing;

      %local tmp tmp4pop;
      %let tmp = %sysfunc(compbl(&trtvars __tby &by &groupvars));
      %let tmp = %sysfunc(tranwrd(&tmp, %str( ), %str(,)));
      %let tmp4pop = %sysfunc(compbl(&popgrp &trtvars __pop));
      %let tmp4pop = %sysfunc(tranwrd(&tmp4pop, %str( ), %str(,)));

      put @1 "proc sql noprint;";
      put @1 "  create table __nm as select count(*) as __totn, &tmp";
      put @1 "  from (select distinct &tmp, &unit from __dataset(where=(&var ne . and &tabwhere and &where )))";
      put @1 "  group by &tmp";
      put @1 "  order by &tmp";
      put @1 "  ;";
      put;
      put @1 "create table __nmiss as select * from ";
      put @1 "  (select * from __nm) natural left join ";
      put @1 "  (select distinct &tmp4pop as __ptot from __pop) ;";
      put;  
      put @1 "quit;";
      put;  
      put @1 "  data __nmiss;";
      put @1 "  set __nmiss;";

      put @1 "    if __totn=. then __totn=0;";
      put @1 "    nmiss= __ptot-__totn;";
      put @1 "    drop __totn __ptot;";
      put @1 "  run;";
      put;  
      put @1 "  proc sort data=__nmiss;";
      put @1 "    by  &trtvars __tby &by &groupvars;";
      put @1 "  run;";
      put;
      put @1 "  proc sort data=__contstat;";
      put @1 "    by &trtvars __tby &by &groupvars;";
      put @1 "  run;";
      put;
      put @1 "  data  __contstat;";
      put @1 "    merge __contstat __nmiss;   ";
      put @1 "    by  &trtvars __tby &by &groupvars;";
      put @1 "  run;";
      put;


%end;





put @1 "*------------------------------------------------------------------;";
put @1 "* CHECK IF ANY STATISTICS ARE CALCULATED;";
put @1 "* IF NOT THEN CREATE DUMMY OUTPUT DATASET SHOWING N WITH VALUE=0;";
put @1 "*------------------------------------------------------------------;";
put;
run;

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


%*put 4iza statlist=&statlist;

data _null_;
length __tabwhere __where $ 2000;
__tabwhere = cats(symget("tabwhere"));
__where = cats(symget("where"));
__templatewhere = cats(symget("templatewhere"));
if __templatewhere='' then __templatewhere='1=1';

file "&rrgpgmpath./&rrguri..sas" mod;
put;

put @1  "data __contstat0;";
put @1 ' length __name $ 2000;';
put @1 "   __statlist = compbl(upcase('" "&statlist" "'));";

put @1 "   do __i =1 to  countw(__statlist, ' ') ;";
put @1 "      __name = scan(__statlist,  __i, ' ');"; 
put @1 '      output;';
put @1 '   end;';
put @1 " drop __i __statlist;";
put @1  "run;";
put;
%if %length(&gv_wt) %then %do;
put @1 "proc sql noprint;";
put @1 "  create table __tmp1 as select * from ";
put @1 "  (select distinct";
put @1 "     &tmp_nt";
put @1 "     from __dataset (where=( " __templatewhere ")))";
put @1 "     cross join __grpcodes;";
put @1 "  create table __tmp as select * from ";
put @1 "  __tmp1 cross join __contstat0;";
%end;
%else %do;
put @1 "proc sql noprint;";
put @1 "  create table __tmp as select * from ";
put @1 "  (select distinct";
put @1 "     &tmp_nt";
put @1 "     from __dataset (where=( " __templatewhere ")))";
put @1 "     cross join __contstat0;";
%end;

put @1 "  create table __contstat0 as select * from __tmp order by __name;";
put @1 "quit;";
put;
put;   
put @1 '  proc sort data=__contstatlist;';
put @1 '    by __name;';
put @1 '  run;';
put;  
put @1 '  data __contstat0;';
put @1 '    merge __contstat0 (in=__a) __contstatlist ';
put @1 '    (keep=__fname __name __order __sid __disp __dispname __basedec);';
put @1 '    by __name;';
put @1 '    if __a;';
put @1 '  run;  ';

put;
%* end of template;

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put @1 '%local dsid rc nobs;';
put @1 '%let dsid =%sysfunc(open(__contstat));';
put @1 '%let nobs = %sysfunc(attrn(&dsid, NOBS));';
put @1 '%let rc=%sysfunc(close(&dsid));';
put;  
put @1 '%if &nobs>0 %then %do;';
put;
put;

put;
put;
put @1 '  data __contstat;';
put @1 '    set __contstat;';
put @1 '    length __name __statlist $ 2000;';
put @1 "    __statlist = upcase('" "&statlist" "');";
put @1 "    array stats{*} &statlist;";
put @1 '      do __i =1 to dim(stats);';
put @1 "        __name = scan(__statlist,  __i, ' ');"; 
put @1 '        __val = stats[__i];';
put @1 '        output;';
put @1 '      end;';
put @1 "      drop __statlist &statlist;";
put @1 '    run;';
put;        
put @1 '  proc sort data=__contstat;';
put @1 "    by &by &trtvars __tby &groupvars  __name;";
put @1 '  run;';
put;   
put @1 '  proc sort data=__contstat0;';
put @1 "    by &by &trtvars __tby &groupvars  __name;";
put @1 '  run;';
put;  
put @1 '  data __contstat;';
put @1 '    merge __contstat  __contstat0(in=__a); ';
put @1 "    by &by &trtvars __tby &groupvars  __name;";
put @1 "   if __a;";
put @1 "      if upcase(__name)='N' and __val=. then __val=0;";
put @1 '  run;  ';
put;
put @1 '%end;';
run;

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put @1 '%else %do;';
put;

put;
put @1  "   data __contstat;";
put @1  "   set __contstat0;";
put @1 "    if upcase(__name)='N' then __val=0;";
put @1 '  run;  ';
put;
put @1 '%end;';
run;

%local i vnames vtmp;

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put;
put @1 "*--------------------------------------------------------------;";  
put @1 "* PRINT STATISTICS USING APPROPRIATE NUMBER OF DECIMAL PLACES;  ";
put @1 "*--------------------------------------------------------------;";
put;
put @1 "data __contstat2;";
put @1 " set  __contstat;";
put @1 " length __col $ 2000;";
%if %length(&decvar)>0 %then %do;
    put @1 "    if missing(&decvar) then &decvar=0;";
put @1 "   if __name in ('N','NMISS') then __basedec=0;";
put @1 "   else __basedec = &decvar + input(upcase(__name), &decinfmt);";
%end;

put @1 "   length __decfmt $ 20;";
put @1 "   __decfmt = '12.'; ";
put @1 "   if __basedec>0 then __decfmt = cats(__decfmt, __basedec);";

put;

run;

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;

put @1 "*--------------------------------------------------------------;";
put @1 "* CREATE DISPLAY OF STATISTICS (FORMAT);";
put @1 "*--------------------------------------------------------------;";

%if %length(&condfmt)=0 %then %do;
    put @1 "   if __name='PROBT' then do;";
    put @1 "     __val=round(__val, 0.000000001);";
    put @1 "     __col = put(__val, &pvfmt);";
    put @1 "   end;";
    put @1 "   else do;";
    put @1 "     __val = round(__val, 10**(-1*__basedec));";
    put @1 "     __col = compress(putn(__val, __decfmt));";
    put @1 "   end;";
%end;

%else %do;

  %put condfmt=&condfmt;
  %__condfmt(condfmt=%nrbquote(&condfmt));
%end;

put;
put @1 "   if compress(__col, '-0.')='' then __col = tranwrd(__col,'-','');";
put @1 "   run;";
put;
put;

put;

run;

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put @1 "*--------------------------------------------------------------;";
put @1 "* PUT STATISTICS ON THE SAME LINE, IF NEEDED;";
put @1 "*--------------------------------------------------------------;";
put;
put @1 "proc sort data=__contstat2;";
put @1 "  by &by &trtvars __tby &groupvars __order __sid ;";
put @1 "run;";
put;

put;
put @1 "data __contstat2;";
put @1 "set __contstat2;";
put @1 "by &by &trtvars __tby &groupvars __order __sid ;";
put @1 "length __ncol $ 2000 __tmpalign $ 8;";
put @1 "   retain __ncol;";
put;     
put @1 "if first.__order and last.__order then do;";
put @1 "  __ncol =upcase(__name);";
put @1 "  __col =tranwrd(strip(__ncol), strip(upcase(__name)), strip(__col));";
put @1 "  if compress(__col, '.,(): ')='' then __col='';     ";
put @1 "  __tmpalign = cats('" "&align" "');";   
put @1 "  output;";
put @1 "end;";

put @1 "else do;";
put @1 "  if first.__order then __ncol =__dispname;";

put @1 "     __ncol =tranwrd(strip(__ncol), '$'||strip(upcase(__name))||'$', strip(__col));";
put @1 "     if last.__order then do;";

put @1 "        if compress(__ncol, '.,(): ')='' then __ncol='';     ";
put @1 "        __col=strip(__ncol);";

put @1 "        __tmpalign = 'C';";   
put @1 "        output;";
put @1 "     end;";
put @1 "end;";
put @1 "run;";
put;


put;
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


%*put 4iza ovstat ovstat=&ovstat;

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


 data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    set __contstatlistm end=eof;
    if _n_=1 then do;      
      %if %length(&ovstat) %then %do;
          put @1 "  data __overallstats0;";
          put @1 "  if 0;";
          put @1 "  run;";
          put;
      %end;
      put @1 "*-----------------------------------------------------;";
      put @1 "* CREATE A LIST OF REQUESTED MODEL-BASED STATISTICS   ;";
      put @1 "*-----------------------------------------------------;";
      put;
      put @1 "  data __modelstat;";
      put @1 "    length __fname __name __disp  $ 2000;";
      put;
    end;
    
    put @1 "    __overall = " __overall ";";      
    put @1 "    __fname = '" __fname "';";
    put @1 "     __name = '" __name "';";
    put @1 "     __disp = '" __disp "';";
    put @1 "    __order = " __order ";";
    put @1 "      __sid = " __sid ";";
    put @1 "  __basedec = " __basedec ";";  
    put @1 "  output;";
    put;
    if eof then do;
      put;
      put @1 "  run;";
      put;
      put;
    end;
    put;
 run;



    data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    put;
    put @1 "*-------------------------------------------------------------;";
    put @1 "* PREPARE DATASET FOR CUSTOM MODEL, REMOVING POOLED TREATMENTS;";
    put @1 "*-------------------------------------------------------------;";
    put;
    
    put @1 "data __dataset;";
    put @1 "set __dataset;";
    %if %length(&decvar)=0 %then %do;
        put @1 "__decvar=&basedec;";
        put @1 "if missing(__decvar) then __decvar=0;";
    %end;
    %else %do;
       put @1 "if missing(&decvar) then &decvar=0;";
    %end;
    
    put @1 "run;";
    
    put;
    
    put @1 "data __datasetp;";
    put @1 "set __dataset(where=(&tabwhere and &where &pooledstr));";
   
    put @1 "run;";
    put;
  run;
    

    
    
    
   


  %do i = 1 %to &nmodels;
  
    data __modelstat;
      set __contstatlistm;
      if __modelnum=&i;
      length __fname $ 2000;
      call symput("currentmodel", cats(__modelname));
    run; 
    
    libname tmpout "&rrgoutpath";
    data tmpout.__modelstat;
      set __modelstat;
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
    
 %*put 4iza pass99 decvar=&decvar;  
    
    data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    length __macroname2  $ 2000;
    set __modelp;
    __macroname2 = cats('%', name,'(');
    put;
   /* put @1 "4iza pass99 decvar=&decvar;";*/
    put @1 __macroname2;
    put @1 "   var=&var,";
    put @1 "   trtvar=&trtvars,";
    put @1 "   groupvars=&by &groupby,";    
    put @1 "   dataset=__datasetp,";
    %* todo: decvar to custom parameters;
    %if %length(&decvar)=0 %then %do;
        put @1 "   decvar=__decvar,";
    %end;
    %else %do;
        put @1 "   decvar=&decvar,";
        /*put @1 "   if missing(decvar) then decvar=0;";*/
    %end;
    if parms ne '' then do;
      put @1 parms ",";
    end;
    put @1 "   subjid=&subjid);";
    put;
    %local modelds;
    call symput ('modelds', cats(name));
    run;
    
    data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    
    %* collect overall statistics;
    %if %length(&ovstat) %Then %do;
    
        put @1 "*---------------------------------------------------------;";
        put @1 "* ADD OVERALL STATISTICS TO DATASET THAT COLLECTS THEM;";
        put @1 "*---------------------------------------------------------;";
        put;
        put @1 'data __overallstats0;';
        put @1 "length __fname $ 2000;";
        put @1 "set __overallstats0 &modelds(in=__a where=(__overall=1));";
        put @1 "__blockid = &varid;";
        put @1 "if __a then __fname = upcase(cats('" "&currentmodel" "','.',__stat_name));";
        put @1 'run;';
        put;
    %end;
    
  
    run;  
      
   data _null_;
    file "&rrgpgmpath./&rrguri..sas" mod;
    put; 
    put;
    put @1 "*---------------------------------------------------------;";
    put @1 "* MERGE LIST OF REQUESTED MODEL-BASED STATISTICS      ;";
    put @1 "* WITH DATASET CREATED BY PLUGIN;";
    put @1 "* KEEP ONLY REQUESTED STATISTICS FROM CURRENT MODEL;";
    put @1 "*---------------------------------------------------------;";
    put;
    put @1 "  data __mdl_&modelds;";
    put @1 "    length __fname $ 2000;";
    put @1 "    set &modelds;";
    put @1 "    if __overall ne 1;";
    put @1 "    __fname = upcase(cats('" "&currentmodel" "', '.', __stat_name));";
    put @1 "  run;";
    put;
    
    
    put @1 "*---------------------------------------------------------;";
    put @1 "* CHECK IF PLUGIN PRODUCED ANY WITHIN-TREATMENT STATISTICS;";
    put @1 "*---------------------------------------------------------;";
    put;
    put @1 '%local dsid rc nobs;';
    put @1 '%let dsid =';
    put @1 '  %sysfunc(open(' "__mdl_&modelds ));;";
    put @1 '%let nobs = %sysfunc(attrn(&dsid, NOBS));;';
    put @1 '%let rc=%sysfunc(close(&dsid));;';
    put;
    put @1 '%if &nobs>0 %then %do;';

    put @1 "  proc sort data=__mdl_&modelds;";
    put @1 "    by __fname __overall;";
    put @1 "  run;";
    put @1 "  proc sort data=__modelstat;";
    put @1 "    by __fname __overall;";
    put @1 "  run;";
    put;
   
    put @1 "  data __mdl_&modelds;";
    put @1 "  length __disp __col __tmpdisp __tmpcol  $ 2000 __tmpalign __tmpal $ 8;";     
    put @1 "    merge __mdl_&modelds (in=__a) __modelstat (in=__b);";
    put @1 "    by __fname __overall;";
    put @1 "    __sid=__stat_order;";
    put @1 "    if __a and __b;";
    put @1 "    __tby=1;";
    put @1 "    __tmpdisp = __stat_label;";
    put @1 "    __tmpal = __stat_align;";
    put @1 "    __tmpcol = cats(__stat_value);";
    put @1 "    if index(__tmpdisp, '//')=1 then __tmpdisp='~-2n'||substr(__tmpdisp, 3);";      
    put @1 "    __tmpal = tranwrd(__tmpal, '//', '-');";
    put @1 "    __nline = countw(__tmpal,'-');";
    put @1 "    do __i =1 to __nline;";
    put @1 "       if index(__tmpdisp, '//')>0 then do;";
    put @1 "         __disp = substr(__tmpdisp, 1, index(__tmpdisp, '//')-1); ";
    put @1 "         __tmpdisp = substr(__tmpdisp, index(__tmpdisp, '//')+2); ";
    put @1 "       end;";
    put @1 "       else do;";
    put @1 "         __disp = trim(left(__tmpdisp)); ";
    put @1 "       end;";
    put @1 "       if index(__tmpcol, '//')>0 then do;";
    put @1 "         __col = substr(__tmpcol, 1, index(__tmpcol, '//')-1); ";
    put @1 "         __tmpcol = substr(__tmpcol, index(__tmpcol, '//')+2); ";
    put @1 "       end;";
    put @1 "       else do;";
    put @1 "         __col = trim(left(__tmpcol)); ";
    put @1 "       end;";
    put @1 "       __sid = __sid + (__i-1)/__nline;";
    put @1 "       __tmpalign = scan(__tmpal,__i, '-');";
    put @1 "       output;";
    put @1 "    end;";
    put @1 "    drop __stat_align __stat_order __stat_label __overall __nline";
    put @1 "         __tmpal __tmpcol __tmpdisp;";    
    put @1 "  run;";
    put;
     put;
    put @1 "  proc sort data=__mdl_&modelds;";
    put @1 "  by __order __sid __fname &trtvars &by &groupby;";
    put @1 "  run;";
    put;
    put @1 "  data __mdl_&modelds (drop = __order rename=(__tmporder=__order));";
    put @1 "  set __mdl_&modelds;"; 
    put @1 "  by __order __sid __fname &trtvars &by &groupby;";  
    put @1 "    retain __tmporder;";
    put @1 "    if first.__order then __tmporder=__order;";
    put @1 "    if first.__sid then __tmporder+0.0001;";
    put @1 "  run;";
    PUT;
    put @1 "*---------------------------------------------------------;";
    put @1 "* ADD PLUGIN-GENERATED STATISTICS TO OTHER STATISTICS;";
    put @1 "*---------------------------------------------------------;";
    put;
    put @1 "  data __contstat2;";
    put @1 "    set __contstat2 __mdl_&modelds;";
    put @1 "  run;  ";
    put;
    put @1 '%end;';
   run;
  %end;
  
  
  data _null_;
  file "&rrgpgmpath./&rrguri..sas" mod;
  put; 
  put;
  %if %length(&ovstat) %then %do;
  put @1 "*---------------------------------------------------------;";
  put @1 "* COLLECT REQUESTED OVERALL STATISTICS ;";
  put @1 "* ADD TO DATASETS __OVERALLSTAT;";
  put @1 "*---------------------------------------------------------;";
  put;
  put @1 "proc sort data=__modelstat;";
  put @1 "  by __fname __overall;";
  put @1 "run;";
  put;
  put @1 "proc sort data=__overallstats0;";
  put @1 "  by __fname __overall;";
  put @1 "run;";
  put;
  put @1 "data __overallstats0;";
  put @1 "  merge __overallstats0(in=__a) __modelstat (in=__b);";
  put @1 "  by __fname __overall;";
  put @1 "  if __a and __b;";
  put @1 "run;";
  put;
  put @1 "data __overallstats;";
  put @1 "  set __overallstats __overallstats0;";
  put @1 "run;";
  put;
  %end;
run;
%end;

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put @1 "*----------------------------------------------------------------;";
put @1 "* MERGE WITHIN-TRT STATS WITH DATASET HAVING ALL TREATMENTS;";
put @1 "*----------------------------------------------------------------;";
put;


run;

%__joinds(data1 = __contstat2,
        data2 = __trt ,
           by = &trtvars,
    mergetype = inner,
      dataout = __contstat3);
      
     

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put @1 "*----------------------------------------------------------------;";
put @1 "* TRANSPOSE DATASET;";
put @1 "*----------------------------------------------------------------;";
put;

run;
data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;

/*
put @1 "proc print data=__contstat3;";
put @1 "  title '4iza __contstat3 in __cont';";
put @1 "run;";
*/

put @1 "proc sort data=__contstat3;";
put @1 "   by  &by &groupvars __tby __order  __fname  __disp __tmpalign;";
put @1 "run;";
put;

put @1 '%local dsid rc nobs;';
put @1 '%let dsid =%sysfunc(open(__contstat3));';
put @1 '%let nobs = %sysfunc(attrn(&dsid, NOBS));';
put @1 '%let rc=%sysfunc(close(&dsid));';
put;
put @1 '%if &nobs>0 %then %do;';
put;

put @1 "  proc transpose data=__contstat3 out=__contstat4 prefix=__col_;";
put @1 "    by &by &groupvars __tby  __order   __fname __disp __tmpalign;";
put @1 "    id __trtid;";
put @1 "    var __col;";
put @1 "  run;";


put;
put @1 "data __contstat4;";
put @1 "length __fname $ 2000;";
put @1 "  set __contstat4 ;";
put @1 "  if 0 then do; __col_x=''; __fname=''; end;";
put @1 "  array cols{*} __col_:;";
put @1 "    __keep=0;";
put @1 "    do __i=1 to dim(cols);";
put @1 "      if cols[__i] not in ('' ,'0') then __keep=1;";
put @1 "    end;";
put @1 "  if __fname='NMISS' and __keep=0 then delete;";
put @1 "  drop __keep __i __col_x;";
put @1 "run;";


run;



data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put @1 "*-----------------------------------------------------------------;";
put @1 "* DEFINE ALIGNMENTS, SKIPLINES, INDENTATION;";
put @1 "*-----------------------------------------------------------------;";
put;
put;
put '%local i;';
put @1 "data &outds ;";
put @1 "set __contstat4;";
put @1 "by &by &groupvars __tby ;";
put @1 'length __varlabel __col_0-__col_&maxtrt __align  $ 2000 ';
put @1 "       __suffix __vtype $ 20 __skipline $ 1;";
put;
put @1 "if 0 then do;";
put @1 '  %do i=0 %to &maxtrt;';
put @1 '    __col_&i =' "' ';";
put @1 '  %end;';
put @1 "end;";
put @1 "array cols{*} __col_:;";
put @1 "__col_0 = __disp;";
put @1 "__align = 'L';";
length __label $ 2000;
__label = quote(dequote(trim(left(symget("label")))));
put @1 '__varlabel = ' __label ';';
put;
put @1 "__tmpalign = cats(__tmpalign,'_');";
put @1 "  __align = trim(left(__align))||' '||repeat(__tmpalign," '&maxtrt );';
put @1 "__align = tranwrd(__align,'_',' ');";
put;
put @1 "__keepn=1;";
put @1 "__keepnvar='" "&keepn" "';";

%local ngrpv;
%let ngrpv=0;
%if %length(&groupvars) %then %let ngrpv = %sysfunc(countw(&groupvars,%str( )));

%if %upcase(&Statsacross)=Y and &ngrpv>0 %then %do;
put @1 "__indentlev=max(&indent+&ngrpv-1,0);";
%end;
%else %do;
put @1 "__indentlev=&indent+&ngrpv;";
%end;

put @1 "__suffix='';  ";
put;
put @1 "if last.__tby then do;";
%if "&keepn" ne "Y" %then %do;
put @1 "   __keepn=0;";
%end;
%if &skipline=Y %then %do;
put @1 "   __suffix='~-2n';";
%end;
put @1 "end;";
put;
put @1 "__blockid=&varid;";
put @1 "__tmprowid=_n_;";

put @1 "__labelline=&labelline;";
put;
%if &labelline=1 %then %do;
put @1 "if first.__tby  then do;";
put @1 "   * FOR LABELLINE=1, PUT 1ST STATISTICS ON THE SAME LINE AS LABEL;";
put @1 "   __col_0 = trim(left(dequote(__varlabel)))||' '";
put @1 "       ||trim(left(__col_0));";
put @1 "end;";
%end;
put;
put @1 "__vtype='CONT';";
put @1 '__grpid=999;';
put @1 "  __skipline=cats('" "&skipline" "');";
put @1 "do __i = 1 to dim(cols);";
put @1 "  if index(cats(cols[__i]),'-')=1 and compress(cols[__i], '-0.')='' then ";
put @1 "    cols[__i] = substr(cats(cols[__i]),2);";
put @1 "    if upcase(__fname) in( 'N','NMISS')  and cols[__i]='' then cols[__i]='0';";
put @1 "end;";
put @1 "__tby=1;";
put;
put @1 "drop __i;";
put @1 "run;";
put;
%*__rrgpd(ds=__fcont4, title2='line 1266');
put @1 '%end;';
put;

put @1 '%exit' "c&varid:";
run;



%exit:

%mend;

