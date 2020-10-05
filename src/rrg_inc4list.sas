/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 
 * the only user-specified parameter is STRING. Depending  on system configuration it can be just a name of sas program (typically, macro, e.g. mymacro.sas) but often fully qualified path needs to be used, e.g. C:\pgm\mymacro.sas
 
 * COPY OF RRG_INC
 * EXECUTES THIS.STRING AND CREATES/APPENDS RECORD WITH THIS.STRING TO __RRGINC;

 */


%macro rrg_inc4list(string)/ store;

%local string pgmpath;
%local st dost;
%let st=%str();

%if not (%index(&string, %str(\)) or %index(&string,%str(/))) %then %do;
  
    data _null_;
    set sashelp.vextfl;
    
     if index(upcase(xpath), ".SAS") then do;
        xpath = tranwrd(xpath,'\','/');
        xpath = reverse(strip(xpath));
        lastslash=index(xpath,"/");
        xpath = reverse(substr(xpath, lastslash));
        call symput('pgmpath', strip(xpath));
      end;
    run;  
    
    %let string = &pgmpath.&string;
    
%end;  


%if %sysfunc(exist(__rrginc))=0 %then %do;
    data __tmp;
    length record $ 2000;
    record =  '%inc '||"'"||cats(symget("string"))||"' ;";;
    call execute(cats('%nrstr(',record,')'));
    run;
    
    proc append data=__tmp base=__rrginc;
    run;

%end;

%else %do;
  
   data __rrginc;
    length record $ 2000;
    record =  '%inc '||"'"||cats(symget("string"))||"' ;";;
   call execute(cats('%nrstr(',record,')'));
   run;
  
%end;




%mend;

