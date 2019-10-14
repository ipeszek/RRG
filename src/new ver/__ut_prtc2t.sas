/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __UT_prtc2t(string=, unit=)/store;
%*---------------------------------------------------------------------------
 REPONSIBILITY:
 this macro converts the string of column widths to twips

 AUTHOR:        Iza Peszek, 10NOV2007


 MACRO PARAMETERS:
      &string: input string
      &unit  : defult unit to be used if unit is not specified

 NOTE: it updates the macro parameter minwidth declared in calling macro
-----------------------------------------------------------------------------;

%local i tmp tmpstring string unit tmp2 isw minwidth;

%if %length(&string) %then %do;
    %let unit=%upcase(&unit);
    %let string=%sysfunc(compbl(%upcase(&string)));
    %do i=1 %to %length(&string);
        %let isw=0;
        %let tmp=;
        %let tmp2 = %scan(&string,&i, %str( ));
        %if %length(&tmp2) %then %do;
           %let tmp = %substr(&tmp2, 1, 1);
           %if &tmp=W %then %do;
                %let isw=1;
                %if &tmp2 ne W %then %let tmp = %substr(&tmp2, 2);
           %end;
           %else %let tmp=&tmp2;
        %end;
        %if %length(&tmp) %then %do;
            %if &tmp ne W and &tmp ne N %then %do;
               %if %index(&tmp, CM)>0 %then %do;
                   %let tmp=%sysfunc(tranwrd(&tmp, CM, %str()));
                   %let tmp = %sysevalf(&tmp*1440/2.54, ceil);
               %end;
               %else %do;
                  %if %index(&tmp, IN)>0 %then %do;
                      %let tmp=%sysfunc(tranwrd(&tmp, IN, %str()));
                      %let tmp = %sysevalf(&tmp*1440, ceil);
                  %end;
                  %else %do;
                      %if %qupcase(&unit)=%quote(IN) %then %do;
                          %let tmp = %sysevalf(&tmp*1440, ceil);
                      %end;
                      %else %do;
                          %let tmp = %sysevalf(&tmp*1440/2.54, ceil);
                      %end;
                  %end;
               %end;
            %end;
            %if &isw=0 %then %do;
                %let tmpstring=&tmpstring &tmp;
                %let minwidth = &minwidth X;
            %end;
            %else %do;
               %let tmpstring=&tmpstring W;
               %if &tmp=W %then %let minwidth = &minwidth X;
               %else %let minwidth = &minwidth &tmp;
            %end;
        %end;
        %else %do;
             %if &isw =1 %then %let minwidth = &minwidth X;
             %let tmpstring=&tmpstring &tmp2;
        %end;
    %end;
    %let string=&tmpstring;
    %let string=%sysfunc(compbl(&string));
%end;
&string

%mend;
