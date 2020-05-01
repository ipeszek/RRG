/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __UT_prtacw(datain=, dataout=, part1=, part2a=, lastcheadid=,
               stretch=, debug=0)/store;

%*---------------------------------------------------------------------------
 REPONSIBILITY:
 this macro adjusts the column widths and tab stops for each clumn group
   depending on value of STRETCH parametr. It updates &datain
   and creates new sataset &dataout with per-column-group iinformation
   on width of columns and tabstops

 AUTHOR:        Iza Peszek, 10NOV2007

 MACRO PARAMETERS:
    &datain:     input dataset with specified column groups
    &dataout:    output dataset with new column widt info
    &part1:      string of numbers in twips indicating 1st tab stop
    &part1:      string of numbers in twips indicating 2nd tab stop
    &lastcheadid: id of last column being an ID column
    %stretch:    if N, table is not stretched to fill all width of page
    &debug:      level of debugging

----------------------------------------------------------------------------;



%local datain part1 part2a lastcheadid stretch i j k ncpp debug dataout;

%let part1 = %sysfunc(compbl(&part1));
%let part2a = %sysfunc(compbl(&part2a));
%if &debug>0 %then %put part1=&part1 part2a=&part2a;

%* new cpp;
proc sql noprint;
select count(*) into:ncpp from &datain;
  %do i=1 %to &ncpp;
      %local cstart&i cstop&i cpp&i;
      select __startcol into:cstart&i from &datain where group=&i;
      select __endcol into:cstop&i from &datain where group=&i;
      %let cpp&i = %eval(&&cstop&i-&&cstart&i+1);
  %end;
quit;

%do j=1 %to &ncpp;
   %local part2a&j part1&j tab1stop&j tab2stop&j;
         %do i=0 %to &lastcheadid;
              %let k=%eval(&i+1);
              %let part2a&j = &&part2a&j %scan(&part2a, &k, %str( ));
              %let part1&j = &&part1&j %scan(&part1, &k, %str( ));
              %let tab1stop&j = &&tab1stop&j %scan(&tab1stop, &k, %str( ));
              %let tab2stop&j = &&tab2stop&j %scan(&tab2stop, &k, %str( ));
         %end;
         %do i=&&cstart&j %to &&cstop&j;
              %let k=%eval(&i+1);
              %let part2a&j = &&part2a&j %scan(&part2a, &k, %str( ));
              %let part1&j = &&part1&j %scan(&part1, &k, %str( ));
              %let tab1stop&j = &&tab1stop&j %scan(&tab1stop, &k, %str( ));
              %let tab2stop&j = &&tab2stop&j %scan(&tab2stop, &k, %str( ));
         %end;
%end;


%do i=1 %to &ncpp;
  %local colw&i newcolw&i    partialcolw&j;;
%end;


data &datain;
   length __tmp1 __tmp2 __tmp4$ 2000;
   set &datain end=eof;
   array cw{*} __colw_0-__colw_&lastcol;
   __acttw=0;
   do __i=0 to &lastcol;
      if cw[__i+1] ne . then __acttw = __acttw+cw[__i+1];
   end;
   __tmp3=.;
   %if &stretch=N %then %do;
      __factor=1;
   %end;
   %else %do;
      __factor = __tw/__acttw;
   %end;

   __tmp1='';
   __tmp2='';
   __tmp4='';
   if __factor ne 1 then do;

      do __i=0 to &lastcol;
         if cw[__i+1] ne . then do;
              __tmp3 = floor(__factor*cw[__i+1]);
              __tmp2 = trim(left(__tmp2))||" "||compress(put(cw[__i+1],12.));
              __tmp1 = trim(left(__tmp1))||" "||compress(put(__tmp3,12.));
              cw[__i+1]=__tmp3;
         end;
      end;
   end;
   else do;
       do __i=0 to &lastcol;
         if cw[__i+1] ne . then do;
            __tmp2 = trim(left(__tmp2))||" "||compress(put(cw[__i+1],12.));
            __tmp1 = trim(left(__tmp1))||" "||compress(put(cw[__i+1],12.));
         end;
       end;
   end;
   do __i=%eval(&lastcheadid+1) to &lastcol;
      if cw[__i+1] ne . then do;
            __tmp4 = trim(left(__tmp4))||" "||compress(put(cw[__i+1],12.));
      end;
      %* these are partial widths, excluding repeated columns;
   end;
   call symput("partialcolw"||compress(put(group,12.)), compbl(__tmp4));
   call symput("colw"||compress(put(group,12.)), compbl(__tmp2));
   call symput("newcolw"||compress(put(group,12.)), compbl(__tmp1));

   drop __tmp1 __tmp2 __tmp3 __factor __i;
run;

%if &debug>0 %then %do;
   %put adjusted colwidths after stretch info applied: ;
   %do i=1 %to &ncpp;
      %put  colw&i = &&colw&i;
   %end;
%end;


%*----------------------------------------------------------------------------;
%* adjust rpar;
%*----------------------------------------------------------------------------;


%do j=1 %to &ncpp;
   %local newrpar&j newcolw&j  newpart2a&j;
   %* if &isdata>0 %then %do;

      %let newrpar&j=;
      %let newpart2a&j=;
      %do i=0 %to %eval(&lastcheadid+&&cpp&j);
         %local  tmp1 tmp2 tmp3 tmp4 tmp1a ist1 ist2;
         %let tmp1  = %scan(&&part1&j,  %eval(&i+1), %str( ));
         %let tmp1a = %scan(&&part2a&j,  %eval(&i+1), %str( ));
         %let tmp2  = %scan(&&colw&j,   %eval(&i+1), %str( ));
         %let tmp3  = %scan(&&newcolw&j,%eval(&i+1), %str( ));
         %let ist1 = %scan(&&tab1stop&j, %eval(&i+1), %str( ));
         %let ist2 = %scan(&&tab2stop&j, %eval(&i+1), %str( ));
         %if &tmp3>&tmp2  %then %do;
            %let tmp4 = %eval(&tmp3-&tmp2);
            %let tmp4 = %sysevalf(0.5*&tmp4, floor);
            %if &tmp1=0 and %length(&ist2)=0 %then %do;
               %let tmp1a = %eval(&tmp4+&tmp1a);
            %end;
            %if &tmp1>0 and %length(&ist1)=0 %then %do;
               %let tmp1 = %eval(&tmp4+&tmp1);
            %end;
         %end;
         %let newrpar&j=&&newrpar&j &tmp1;
         %let newpart2a&j = &&newpart2a&j &tmp1a;
      %end;
   %* end;
   /*
   %else %do;
      %let newrpar&j=100;
   %end;
   */

   %if &debug>0 %then %do;
      %put after scaling colwidths and tabstops so they add up to table width:;
      %put colw&j=&&colw&j newcolw&j=&&newcolw&j;
      %put part1&j=&&part1&j newrpar&j=&&newrpar&j part2a&j=&&part2a&j;
   %end;

   %let colw&j =&&newcolw&j;
   %let part1&j = &&newrpar&j;
   %let part2a&j = &&newpart2a&j;

%end;



data &dataout;
length __colw __part1 __part2 __partcolw $ 2000;
%do i=1 %to &ncpp;
   __colgrp=&i;
   __colw = symget("colw&i");
   __part1 = symget("newrpar&i");
   __part2 = symget("newpart2a&i");
   __allcols = %eval(&lastcheadid+&&cpp&i);
   __cpp = &&cpp&i;
   __partcolw = "&&partialcolw&i";
   output;
%end;
run;

%mend;
