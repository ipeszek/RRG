/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */
 
 /* PROGRAM FLOW:
    14Sep2020     
    
    note: this.xxx below refers to macro parameter xxx of this macro; yyy.xxx refers to variable xxx in yyy dataset                                 


    - Collects info from __repinfo, __varinfo, updates them
    - if append=N then appends __rrght to rrgpgmtmp which creates macro to create 
       &rrguri ds for listings 
    - if finalize=Y then appends to rrgpgmtmp records to call sasshiato
    - appends rrgpgmtmp to rrgpgm ds
    - if finalize=Y then : 
        writes rrgpgmds to &rrguri.sas file, 
        submits &rrguri.sas,
        saves rcd (if requested), saves gentxt (if requested)
    
    
    
    ds used __repinfo, __varinfo, __rrght
    ds created
    ds updated __varinfo, __repinfo
    ds initialized
    
    

*/

%macro rrg_genlist(debug=0, savexml=, finalize=N)/store;
%* note: for now, colsize and dist2next (if in units) shoudl be number of chars if java2sas is used; 
%* assumes __tcol takes only one line between //;
%* assumes varbygrp has only one line;
%* ignores __keepn;

%* Revision notes:  07Apr2014 commented out recoding of curly braces to #123 and #125 (superscript did not work except in header);
%*                  12Aug2020 added handling of no data so that headers and footnotes are displayed 
 
%local numvars i dataset orderby j isspanrow ispage debug  
       indentsize filename savexml finalize;
       
%let rrgfinalize=%upcase(&finalize);

 
%local debugc;
%let debugc=%str(%%*);
%if &debug>0 %then %let debugc=;
 
 

 


%local numcol numpagev numspanv lastvb lastspan;
%let numcol=-1;
%let numpagev=0;
%let numspanv=0;

%local  z   appendm nodatamsg savercd gentxt;

 

proc sql noprint;
  select dataset,  orderby, indentsize,  nodatamsg, 
    savercd, gentxt , filename, print            
           into
         :dataset,:orderby, :indentsize,  :nodatamsg, 
         :savercd, :gentxt   ,:filename,:print
         separated by ' '
       from __repinfo;
  select max(varid) into: numvars separated by ' ' from __varinfo;    
quit;






%do i=1 %to &numvars;
    %local label&i  width&i group&i spanrow&i align&i halign&i
    page&i id&i name&i  decode&i format&i stretch&i
    break&i d2n&i keeptogether&i;
%end;

data __varinfo;
  set __varinfo end=eof;
  length __orderby $ 2000;
  __orderby = strip(symget("orderby"));
  __fm=0;
  
  do __kk=1 to countw(__orderby, ' ');
   if upcase(name)=upcase(scan(__orderby, __kk, ' ')) then __fm=1;
  end;
  if __fm = 0 then do;
    if upcase(group)='Y' then do;
      put 'WAR' 'NING: GROUP=Y requested for ' name ' but ' name ' is not specified in ORDERBY. GROUP=Y is ignored.';
      group='N';
    end;  
    if upcase(skipline)='Y' then  do;
      put 'WAR' 'NING: SKIPLINE=Y requested for ' name ' but ' name ' is not specified in ORDERBY. SKIPLINE=Y is ignored.';
      skipline='N';
    end;
    if upcase(keeptogether)='Y' then  do;
      put 'WAR' 'NING: KEEPTOGETHER=Y requested for ' name ' but ' name ' is not specified in ORDERBY. KEEPTOGETHER=Y is ignored.';
      keeptogether='N';
    end;
    if upcase(spanrow)='Y' then  do;
      put 'WAR' 'NING: SPANROW=Y requested for ' name ' but ' name ' is not specified in ORDERBY. SPANROW=Y is ignored.';
      SPANROW='N';
    end;
    if upcase(PAGE)='Y' then  do;
      put 'WAR' 'NING: PAGE=Y requested for ' name ' but ' name ' is not specified in ORDERBY. PAGE=Y is ignored.';
      PAGE='N';
    end;
  end;
  
    call symput(cats("label",varid)       ,strip(dequote(label)));     
    call symput(cats("width",varid)       ,strip(upcase(width)        ));               
    call symput(cats("group",varid)       ,strip(upcase(group)        ));
    call symput(cats("spanrow",varid)     ,strip(upcase(spanrow)      ));
    call symput(cats("align",varid)       ,strip(upcase(align)        ));
    call symput(cats("halign",varid)      ,strip(upcase(halign)       ));
    call symput(cats("page",varid)        ,strip(upcase(page)         ));
    call symput(cats("id",varid)          ,strip(upcase(id)           ));
    call symput(cats("name",varid)        ,strip(upcase(name)         ));
    call symput(cats("skipline",varid)    ,strip(upcase(skipline)     ));
    call symput(cats("decode",varid)      ,strip(upcase(decode)       ));
    call symput(cats("format",varid)      ,strip(upcase(format)       ));
    call symput(cats("stretch",varid)     ,strip(upcase(stretch)      ));
    call symput(cats("keeptogether",varid),strip(upcase(keeptogether) ));
    call symput(cats("break",varid)       ,strip(upcase(breakok)      ));
    call symput(cats("d2n",varid)         ,strip(upcase(dist2next)    ));
run;

  

   
 
%let isspanrow=0;
%let ispage=0;
 
%do i=1 %to &numvars;
  
    %if &&spanrow&i=Y %then %let isspanrow=1;
    %if &&page&i=Y %then %let ispage=1;
    

    %if %length(&&d2n&i)=0 %then %let d2n&i=D;
    %if "&&stretch&i" ne "N" %then %let stretch&i=Y;
 
    %if &&page&i=Y %then %do;
        %let spanrow&i=;
        %let group&i=;
        %let id&i =;
    %end;
    
    %if &&spanrow&i=Y %then %do;
        %let group&i=;
        %let id&i =;
    %end;
 
    %if &&page&i ne Y and &&spanrow&i ne Y %then %do;
          %let numcol = %eval(&numcol+1);
          %local vcn&numcol;
          %let vcn&numcol=&i;
    %end;
    
    %else %if &&page&i = Y %then %do;
        %let numpagev = %eval(&numpagev+1);
        %local pvn&numpagev;
        %let pvn&numpagev=&i;
        %let lastvb=&&name&i;
    %end;
    
    %else %if &&spanrow&i = Y %then %do;
        %let numspanv = %eval(&numspanv+1);
        %local svn&numspanv;
        %let svn&numspanv=&i;
      %let lastspan=&&name&i;
    %end;
 
    %if %length(&&align&i)=0 %then %let align&i = L;
    %if %length(&&halign&i)=0 %then %let halign&i = &&align&i;
    %if %length(&&width&i)=0 %then %let width&i=LW;
     
%end;



 
%* define breakokat;
%local breakokat;
%let breakokat=&numcol;
%do i=0 %to &numcol;
    %let z = &&vcn&i;
    %if &&break&z=Y %then %let breakokat=&breakokat &i;
%end;
 
 
%local lastcheadid gcols colwidths stretch dist2next align;
%let lastcheadid=0;
%do i=0 %to &numcol;
    %let z = &&vcn&i;
    %if &&id&z=Y %then %let lastcheadid=&i;
    %if &&group&z=Y %then %let gcols = &gcols &i;
    %let colwidths = &colwidths &&width&z;
    %let dist2next = &dist2next &&d2n&z;
    %let stretch = &stretch &&stretch&z;
    %let align = &align &&align&z;

%end;

%local rrgoutpathlazy;
%let rrgoutpathlazy=&rrgoutpath;


data __repinfo;
  set __repinfo;
  lastcheadid=&lastcheadid;
  gcols = cats(symget("gcols"));
  colwidths = cats(symget("colwidths"));
  dist2next = cats(symget("dist2next"));
  stretch = cats(symget("stretch"));
  breakokat = trim(left(symget("breakokat")));
  rtype = 'LISTING';
run;  



%__makerepinfo( numcol=&numcol, islist=Y); 
 


/*
%if &append ne Y %then %do;
  
    proc append data=__rrght (keep=record) base=rrgpgmtmp;
    run;
   
%end;
*/

%* DEFINE COLUMN HEADERS;


%local numspan;

data   __head0;
length __datatype $ 8
%do i=0 %to &numcol; __col_&i  __ncol_&i %end; $ 2000 ;
numspan=0; *** added to account for more than one level;
*** test this;
%do i=0 %to &numcol;
    %let z = &&vcn&i;
    __ncol_&i = cats("&&label&z");
    numspan0 = count(__ncol_&i, '/-/');
    __ncol_&i = tranwrd(cats(__ncol_&i), '/-/', byte(30));
     
    if numspan0>numspan then numspan=numspan0; *** numspan not defined yet?;
%end;
__datatype='HEAD';
call symput('numspan', strip(put(numspan, best.)));
 
if numspan=0 then do;
    __rowid=1;
    %do i=0 %to &numcol;
        __col_&i=cats(__ncol_&i);
    %end;
    output;
end;
else do;
    do __i=numspan+1 to 1 by -1;
        %do i=0 %to &numcol;
        __col_&i = scan(__ncol_&i, -1*__i, byte(30));
        %end;
        __rowid=numspan+2-__i;
        output;
    end;
end;
drop __ncol_:;
run;



data rrgpgmtmp;
  length record $ 2000;
  keep record;
  set __head0 end=eof;
  
  
  if _n_=1 then do;

        record=" ";  output;
        record=" ";  output;
        record= "proc format;";  output;
        record= "  value $ best";  output;
        record= "  ' ' = ' ';";  output;
        record= "run;";  output;
        record=" ";  output;
        record=" ";  output;

        record= '%macro dolist;';  output;

        record= "*---------------------------------------------------------------------;";  output;
        record= "** TRANSFORM DATASET APPLYING FORMATS AND DECODES AS NEEDED;";  output;
        record= "*---------------------------------------------------------------------;";
        record=" ";  output;
        record= "proc sort data=&dataset out = &rrguri;";  output;
        record= "  by &orderby;";  output;
        record= "run;";  output;
        record=" ";  output;
        record= "*---------------------------------------------------------------------;";  output;
        record= "** CHECK IF INPUT DATASET HAS ANY RECORDS ;";  output;
        record= "*---------------------------------------------------------------------;";  output;
        record=" ";  output;


        record= '%local dsid  numobs rc;';  output;
        record= '  %let dsid = %sysfunc(open('||"&rrguri));";  output;
        record= '  %let numobs = %sysfunc(attrn(&dsid, nobs));';  output;
        record= '  %let rc = %sysfunc(close(&dsid));';  output;
        record= '  %put numobs=&numobs;';  output;




        record= "data &rrguri __head;";  output;
        record= '%IF &NUMOBS>0 %then %do;';  output;
        record= "  set &rrguri end=eof;";  output;
        record= "  by &orderby;";  output;

        record= "  length __datatype $ 8 __suffix  $ 2000";  output;
        record= "  __spanrowtmp __varbylab  __tcol __align __tmp __tmp2 $ 2000";  output;
        %do i=0 %to &numcol; 
            record=  "    __col_&i ";  output;
        %end;
        record=  "      $ 2000 ; ";  output;
        record=" ";  output;
        record=" ";  output;
        record= "retain ";  output;
        %do i=1 %to &numvars; 
            record= "   __vtype&i";  output;
        %end;
        record = "    ;";  output;
        record=" ";  output;
        record= "if _n_=1 then do;";  output;
        record= "  __dsid = open('" ||"&rrguri"|| "');";  output;
        %do i=1 %to &numvars;
            record= "  __vtype&i = upcase(vartype(__dsid, varnum(__dsid, '"|| "&&name&i"|| "')));";  output;
        %end;
        record= "  __rc = close(__dsid);";  output;
        record= "end;  ";  output;
        record=" ";  output;
        record=" ";  output;

        record= "  __spanrowtmp='';";  output;
        record= "  __varbylab='';";  output;
        record= "  __tcol='';";  output;
        record= "  __varbylab='';";  output;
        record= "  __suffix='';";  output;
        record= "  __keepn=0;";  output;
        record= "  __datatype='TBODY';";  output;
        record= "  __rowid=_n_;";  output;
        record= "  __tmp='';";  output;
        record= "  __tmp2='';";  output;
        record=" ";

        %if &isspanrow=1 %then %do;
            record= "retain __fospanvar;";  output;
            record= "if _n_=1 then __fospanvar=0;";  output;
        %end;

        %if &ispage=1 %then %do;
            record= "  %* DEFINE __VARBYGRP;";  output;
            record= "    retain __varbygrp 0;";  output;
            %let z = &pvn1;
            %if %length(&&format&z) %then %do;
                record= '      __varbylab = cats("'||
                     "&&label&z"|| '"'|| "||' '||put(&&name&z, &&format&z));";  output;
            %end;
            %else %if %length(&&decode&z) %then %do;
                record= '      __varbylab = cats("'|| "&&label&z"|| '"'|| "||' '||&&decode&z);";  output;
            %end;
            %else %do;

                record= "      if __vtype&z = 'C' then  __varbylab = cats(" ||
                            '"'|| "&&label&z"|| '"'|| "||' '||&&name&z);";  output;
                record= '      else __varbylab = cats("'||
                            "&&label&z"|| '"'|| "||' '||strip(put(&&name&z, best.)));";  output;
                
            %end;
           
            %do i=2 %to &numpagev;
                %let z = &&pvn&i;
                %if %length(&&format&z) %then %do;
                    record= '        __varbylab = cats(__varbylab,"//","'||
                       "&&label&z"|| '"||" "'|| "||put(&&name&z, &&format&z));";  output;
                %end;
                %else %if %length(&&decode&z) %then %do;
                    record= '        __varbylab = cats(__varbylab,"//","' ||
                        "&&label&z" ||'"||" "' ||"||&&decode&z);";  output;
                %end;
                %else %do;
                   record= "        if __vtype&z = 'C' then __varbylab = " ||
                       'cats(__varbylab,"//","'|| "&&label&z"|| '"||" "'|| "||&&name&z);";  output;
                   record= '        else __varbylab = cats(__varbylab,"//","' ||
                        "&&label&z" ||'"||" "'|| "||strip(put(&&name&z, best.)));";  output;

                %end;

            
            %end;
         
            record= "    if first.&lastvb then do;";  output;
            record= "       __varbygrp=__varbygrp+1;";  output;
            record= "    end;";  output;
            record=" ";  output;
        %end;
         
        %if &isspanrow=1 %then %do;
         
            record= "  %* DEFINE SPAN ROW VARIABLE;";  output;
            record= "    __tcol='';";  output;
            %do i=1 %to &numspanv;
                %let z = &&svn&i;
                record= "       __tmp = '';";  output;
                %if %length(&&format&z) %then %do;
                    record= "       __tmp = put(&&name&z, &&format&z);";  output;
                %end;
                %else %if %length(&&decode&z) %then %do;
                    record= "       __tmp = &&decode&z;";  output;
                %end;
                %else %do;
                     record= "       if __vtype&z ='C' then __tmp = &&name&z;";  output;
                     record= "       else __tmp = strip(put(&&name&z, best.));";  output;

                %end;
              %if %length(&&label&z) %then %do;
                  record= "       __tmp2"|| ' = cats("'|| "&&label&z"|| '")||" "||cats(__tmp);';  output;
              %end;
              
              %else %do;
                  record= "       &&name&z"|| ' = cats(__tmp);';  output;
                  record= "       __tmp2"|| ' = cats(__tmp);';  output;
              %end;
              
              %if &i>1 %then %do;
                  record= "          __tcol = cats(__tcol,'//',__tmp2);";  output;
              %end;
              %else %do;
                  record= "          __tcol = cats(__tmp2);";  output;
              %end;
             
              %if &&keeptogether&z=Y %then %do;
                  record= "        if last.&&name&z then __keepn = 0; else __keepn=1;";  output;
              %end;
            
            
           %end;
         
            record= "     if first.&lastspan then do;";  output;
            record= "      __fospan=1;";  output;
            record= "      __fospanvar+1;";  output;
            record= "     end; ";  output;
            record=" ";  output;
        %end;
         
        record= "  %* DEFINE __COL_0, __COL_1 ETC;";  output;
        record= "  %* DEFINE __ALIGN AND __SUFFIX;";  output;
        record= "  __align = '';";  output;

        %do i=0 %to &numcol;
            %let z = &&vcn&i;
            %if %length(&&format&z) %then %do;
                record= "     __col_&i = cats(put(&&name&z, &&format&z));";  output;
            %end;
            %else %if %length(&&decode&z) %then %do;
                record= "     __col_&i = cats(&&decode&z);";  output;
            %end;
            %else %do;
                record= "     if __vtype&z='C' then __col_&i = strip(&&name&z);";  output;
                record= "     else __col_&i = strip(put(&&name&z, best.));";  output;

            %end;
            record= '     __align = cats(__align)||" "||cats("' ||"&&align&z"|| '");';  output;
            %if &&skipline&z=Y %then %do;
                record= "        if last.&&name&z then __suffix = '~-2n';";  output;
            %end;

           
            %if &&group&z=Y %then %do;
                record= "        if  first.&&name&z then __first_&i=1;";  output;
                %if &&keeptogether&z=Y %then %do;
                    record= "        if last.&&name&z then __keepn = 0; else __keepn=1;";  output;
                %end;
            %end;
        %end;
         
         
         
        record= "  output &rrguri;";  output;
        record= '%end;';  output;


        record= '%else %do;';  output;
        record= "  length  __align  $ 2000;";  output;
        record= "__varbygrp=.; __varbylab='';";  output;
        %do i=0 %to &numcol;
            record= "__first_&i=0;";  output;
        %end;
        /* create "no data" as __tcol;*/
        record= "__tcol='&nodatamsg';";  output;
        record= "__col_0=' ';";  output;
        record= "__datatype='TBODY';";  output;
        record= "__align='C';";  output;
        record= "__rowid=1;";  output;


        record= "  output &rrguri;";  output;

        record= '%end;';  output;

        record=" ";  output;
        record= "***-------------FOR HEADER: --------------------------------------------***;";  output;
        record=" ";  output;



        record=" ";  output;
        record= "__align='';";  output;
        %do i=0 %to &numcol;
            %let z = &&vcn&i;
            record= '     __align = cats(__align)||" "||cats("'|| "&&halign&z"|| '");';  output;
        %end;
        record=" ";  output;
        %if &ispage=1 %then %do;
            record= '%if &numobs>0 %then %do;';  output;
            record= "  if first.&lastvb then output __head;";  output;
            record= '%end;';  output;
            record= '%else %do;';  output;
            record= "  output __head;";  output;
            record= '%end;';  output;
        %end;
        %else %do;
            record= '%if &numobs>0 %then %do;';  output;
              record= "  if eof then do;";  output;
              record= "     output __head;";  output;
              record= "  end;";  output;
            record= '%end;';  output;
            record= '%else %do;';  output;
            record= "     output __head;";  output;
            record= '%end;';  output;
            record=" ";  output;
        %end;
         
        record= "  keep __:;";  output;
        record= "run;       ";  output;
        record=" ";  output;
        record= '%mend;';  output;
        record=" ";  output;
        record= '%dolist;';  output;

        record=" ";  output;
        record=" ";  output;
        record= "data __head0;";  output;
        record= "length __col_0  - __col_&numcol  $ 2000 __datatype $ 8 ;";  output;
        record=" ";  output;
        record= "__datatype='HEAD';";  output;


end;

%do i=0 %to &numcol;
    record= "__col_&i = " ||'"' ||strip(__col_&i)|| '";';  output;
%end;
record= "__rowid = "||strip(put(__rowid, best.))|| ";";  output;
record= "output;";  output;
record=" ";   output;


if eof then do;
  
    record=" ";  output;
    record=" ";  output;
 
    %if &ispage=1 %then %do;
     
        record= "data __head;";  output;
        record= "set __head;";  output;
        record= "keep __varbygrp __varbylab __ALIGN;";  output;
        record= "run;";  output;
        record=" ";   output;
    %end;
    %else %do;
        record= "data __head;";  output;
        record= "set __head;";  output;
        record= "keep __ALIGN;";  output;
        record= "run;";  output;
        record=" ";  output;
    %end;
     
    record= "proc sql noprint;";  output;
    record= "create table __head1 as select * from";  output;
    record= "__head0 cross join __head;";  output;
    record= "quit;";  output;
    record=" ";  output;
 
 
 
    %if &numspan>0 %then %do;
          record= "data __head1;";  output;
          record= "set __head1;";  output;
          record= "if __rowid<&numspan then do;";  output;
          record= "__align = repeat('C ', &numcol);";  output;
          record= "end;";  output;
          record= "run;";  output;
          record=" ";  output;
    %end;
     
     
    record= "data &rrguri;";  output;
    record= "set __head1 &&rrguri;";  output;
    record= "  length __cellfonts __cellborders __title1_cont __label_cont $ 500 __topborderstyle __bottomborderstyle $ 2;";  output;
    record= "  __cellfonts = '';";  output;
    record= "  __cellborders = '';";  output;
    record= "  __topborderstyle='';";  output;
    record= "  __bottomborderstyle='';";  output;
    record= "  __label_cont='';";  output;
    record= "  __title1_cont='';";  output;
    record= "run;";  output;
    record=" ";   output;
    record= "proc sort data=&rrguri;";  output;
    %if &ispage=1 %then %do; 
        record= "by   __varbygrp __datatype __rowid;";  output;
    %end;
    %else %do;
        record= "by    __datatype __rowid;";  output;
    %end;
    record= "run;";  output;
    record=" ";  output;
    record= "data &rrguri;";  output;
    record= "set __report &rrguri ;";  output;
    record= "run;";  output;
    record=" ";   output;
    
  
end;
    
run;

proc append base=rrgpgm data=rrgpgmtmp;
run;


%let __workdir = %sysfunc(getoption(work));
%let __workdir=%sysfunc(tranwrd(&__workdir, %str(\), %str(/) ));


data _null_;
  set rrgpgm;
 
  file "&__workdir./rrgpgm.sas"  lrecl=1000;
  put record  ;
  
run;

data __timer;
  set __timer end=eof;
	length task $ 100;
	output;
		if eof then do; 
		  task = "ANALYSING RRG MACROS finished";
		  dt=datetime(); 
		  output;
		end;
run;

%inc "&__workdir./rrgpgm.sas";

data __timer;
  set __timer end=eof;
	length task $ 100;
	output;
		if eof then do; 
		  task = "MACRO EXECUTION FOR LISTING FINISHED ";
		  dt=datetime(); 
		  output;
		end;
run;

%if %upcase(&finalize) =Y %then %do;
  
    %rrg_finalize(debug=&debug, savexml=&savexml);
    %let rrgfinalize_done=1;

%end;



%mend;

