/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __UT_prtf2n(string=, num=)/store;
%*--------------------------------------------------------------------------
 REPONSIBILITY: converts string of numbers to have &num totkens               
                if string has 0 or 1 token then nothing happens               
                if string has 2 or more tokens but less than num              
                    then last token is repeated until string has num tokens   
                if string has 2 or more tokens and more than num              
                    then last tokens are removed until string has num tokens  

AUTHOR: Iza Peszek, 10NOV2007
                                                                              
                                                                              
 MACRO PARAMETERS:                                                            
      &string: input string                                                   
      &num   : how many tokens should there be                                
                                                                              
---------------------------------------------------------------------------;

%local string tmpstring i num tmp;

%if %length(&string) %then %do;
    %let string=%sysfunc(compbl(&string));
    %* expand or shrink string of numbers to have as many elements
       as there is columns;
    %let tmpstring=%scan(&string, 1, %str( ));
    %if %scan(&string,2,%str( ))>0 %then %do;
      %do i=2 %to &num;
        %let tmp = %scan(&string, &i, %str( ));
        %if %length(&tmp) %then %do;
          %let tmpstring = &tmpstring &tmp;
        %end;
        %else %do;
          %let tmpstring = &tmpstring %scan(&string, -1, %str( ));
        %end;
      %end;
      %let string=&tmpstring;
      %let string=%sysfunc(compbl(&string));
    %end;
%end;
&string

%mend;
