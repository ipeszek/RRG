/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __ut_prtgcw(tw=, repeatc=, outds=, breakokat=, debug=0, stretch=)/store;

%*----------------------------------------------------------------------------
REPONSIBILITY:
   creates a dataset with information about column widths
   for each page needed to display &allcols columns

AUTHOR: Iza Peszek, 10NOV2007

MACRO PARAMETERS:
  &tw:      table width in twips
  &repeatc: id of last row header column (0, 1, 2, ...)
  &outds:   output dataset with column width information
  &breakokat:string of integers indicating at wchich columns column splits
            can occur
  &debug:   debug level

ASSUMPTION:
  this macro utilizes some macro variables defined in calling macro:
    &F2P, &COLLSIZE, &LASTCOL
-----------------------------------------------------------------------------;

%local  tw repeatc outds breakokat debug stretch;
%*put tw=&tw repeatc=&repeatc ;
%*put autom=&autom;

%local i j allcols repeat sum colw autocolw spaceleft scaledsum
      factor nofit remove cannotfit nbp tmp;

%let allcols = %eval(&lastcol+1);
%let repeat = %eval(&repeatc+1);
%if %length(&colwidths)=0 %then %let colwidths=&autom;
%if &f2p=Y %then %do;
   %let colwidths=;
   %do i=1 %to &repeat;
     %let colwidths=&colwidths W;
   %end;
   %do i=%eval(&repeat+1) %to  &allcols;
      %let colwidths=&colwidths N;
   %end;
%end;
%if &debug>0 %then %do;
%end;
%let colw = %sysfunc(compbl(&colwidths));
%let autocolw = %sysfunc(compbl(&autom));

%* determine minimum widths;
%local i tmp finalw hw;


%do i=1 %to &allcols;
    %let tmp = %scan(&colwidths, &i, %str( ));
  %* min column width = 0.5in;
    %if &tmp = W %then %let finalw = &finalw 700;
  %else %if  &tmp = N %then %let finalw = &finalw %scan(&autom, &i, %str( ));
  %else %let finalw = &finalw %scan(&colwidths, &i, %str( ));
%end;

%* get required width for repeated columns;

%let hw=0;
%do i=1 %to &repeat;
  %let hw = %eval(&hw + %scan(&finalw, &i, %str( )));
%end;

%* determine minimum widths for each "page group";
%local rst cnt;
%let cnt=0;
%let rst= %eval(&repeat+1);
%*put rst=&rst allcols=&allcols;

%local start1 stop1 start stop;
%let start1=1;
%if %length(&breakokat)=0 %then %do;
  %do i=&rst %to &allcols;
  %let cnt = %eval(&cnt+1);
  %local grp&cnt width&cnt start&cnt stop&cnt;
    %let start&cnt=&i; ** this is on 1 to &allcols scale;
  %let stop&cnt=&i;  ** this is on 1 to &allcols scale;
  %let width&cnt = %scan(&finalw, &i, %str( ));
  %end;
%end;

%else %do;
  %local numgrp;
  %let numgrp = %eval(%sysfunc(countw(&breakokat),%str( ))+1);
  %*put numgrp=&numgrp;
  
  
  %* 1st page group;
  %let start = &rst;
  %let stop = %scan(&breakokat,1,%str( ));
  %if &stop>= &start %then %do;
    %let start1=&start;
    %let stop1=&stop;
    %let cnt = %eval(&cnt+1);
    %local grp&cnt width&cnt;
    %let width&cnt=0;
    
    %do i=&start %to &stop;
      %let width&cnt = %eval(&&width&cnt+%scan(&finalw, &i, %str( )));
    %end;
    %*put cnt=&cnt start&cnt=&&start&cnt stop&cnt=&&stop&cnt width&cnt=&&width&cnt;    
  %end;

  %do i=1 %to %eval(&numgrp-1);
    %local j k;
    %let k=&cnt;
    %let cnt = %eval(&cnt+1);
    %local grp&cnt width&cnt start&cnt end&cnt;
    %let width&cnt=0;
    %let start&cnt = %eval(&stop+1);
  
    %let j = %eval(&i+1);
	%if &i=%eval(&numgrp-1) %then %let stop&cnt=&allcols;
    %else %let stop&cnt = %scan(&breakokat,&j,%str( ));
    %let stop = &&stop&cnt;
    
    %do k=&&start&cnt %to &&stop&cnt;
      %let width&cnt = %eval(&&width&cnt+ %scan(&finalw, &k, %str( )));
    %end;
    %*put cnt=&cnt start&cnt=&&start&cnt stop&cnt=&&stop&cnt width&cnt=&&width&cnt;
  %end;
%end;


%* check if all page groups fit on a page, if not then break;

%local nofit;
%let nofit=0;
%do i=1 %to &cnt;
  %if &&width&i>%eval(&tw-&hw) %then %do;
     %let nofit=1;
   data &outds;
     __nofit=1;
   run;
   %goto exit;
  %end;
%end;

%* figure out how many page groups can be fit on a page;
%do i=1 %to &cnt;
%*put start&i=&&start&i stop&i=&&stop&i width&i=&&width&i;
%end;

data &outds;
length  __acolw __finalw $ 2000;
*__colw = symget("colwidths");
*__autom = symget("autom");
__finalw = symget("finalw");
__acolw = symget("autom");
array colw{*} __colw_0-__colw_&lastcol;
array acolw{*} __acolw_0-__acolw_&lastcol;
do i=1 to dim(colw);
  colw[i]=input(scan(__finalw,i,' '), best12.);
  acolw[i]=input(scan(__acolw,i,' '), best12.);
end;
__tw=&tw;

spaceleft = &tw-&hw;
__startcol = &start1-1;
__endcol = &lastcol;

%do i=1 %to &cnt;
    
    if &&width&i<spaceleft then do;
       __endcol = &&stop&i-1;
     spaceleft= spaceleft-&&width&i;
  end;
  else do;
    output;
    __startcol = &&start&i-1;
    __endcol = &&stop&i-1;
    spaceleft = &tw - &hw - &&width&i;
  end;
  if &i = &cnt then output;
%end;
run;



data &outds;
set &outds;

array colw{*} __colw_0-__colw_&lastcol;
array acolw{*} __acolw_0-__acolw_&lastcol;
actualw = 0;
scaledw = 0;
fixed=0;

do i=&repeat+1 to __startcol;
  colw[i]=.;
end;
do i=__endcol+2 to &allcols;
  colw[i]=.;
end;

do i=0 to &lastcol;
  if colw[i+1] ne . then do;
    actualw = actualw+colw[i+1];
    %if &stretch=Y %then %do;
      if colw[i+1]<acolw[i+1] then scaledw=scaledw+acolw[i+1];
      else fixed=fixed+colw[i+1];
    %end;
    %else %do;
        fixed = fixed+colw[i+1];
    %end;
  end;
end;
nactualw=0;
diff = __tw - actualw;
if scaledw>0 then do;

do i=0 to &lastcol;
  if colw[i+1] ne . and colw[i+1]<acolw[i+1] then do;
    colw[i+1]=floor(colw[i+1]+diff*acolw[i+1]/scaledw);
  end;
if colw[i+1] ne . then nactualw = nactualw +colw[i+1];
end;

end;

__nofit=0;
group=_n_;
drop i spaceleft __finalw __acolw  ;
run;



%exit:

%mend ;


