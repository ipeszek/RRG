/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.

 * 24Sep2020 Program Flow
     writes to rrgpgmtmp records to call sasshiato
    - appends rrgpgmtmp to rrgpgm ds
    - writes rrgpgmds to &rrguri.sas, 
    - submits &rrguri.sas,
    - saves rcd (if requested), saves gentxt (if requested), updates metadata (if requested)

 */

%macro rrg_finalizelist(debug=0, savexml=)/store;
  
%local debug savexml savercd gentxt fname metadatads;
  
proc sql noprint;
  select   savercd, gentxt , fname, metadatads            
           into
           :savercd, :gentxt   ,:fname,:metadatads
         separated by ' '
       from __repinfo;
quit;



  data rrgpgmtmp;
    length record $ 200;
    keep record;
      
      
        record=" ";  output;
        record=" ";   output;
        record= '%macro rrgout;';   output;
        record=" ";  output;
        record= '  %local objname;';  output;
        record=" ";  output;
        record= "  proc sql noprint;";  output;
        record= "  select upcase(objname) into:objname from sashelp.vcatalg";  output;
        record= "  where libname='RRGMACR' and upcase(objname)='__SASSHIATO';";  output;
        record= "  quit;";  output;
        record= " ";  output;
        record= '%local __path;';  output;
        record= '%if %length(&rrgoutpath)=0 %then';  output;
        record= '  %let __path='|| "&rrgoutpathlazy;";  output;
        record= '%else %let __path = &rrgoutpath;';  output;
        record=" ";  output;
        %if %symexist(__sasshiato_home) %then %do;
            record= '  %if %symexist(__sasshiato_home) %then %do;';  output;
            record= '    %if &objname=__SASSHIATO  and  %length(&__sasshiato_home) %then %do;';  output;
            %if %upcase(&savexml)=Y %then %do;
                record= '   %__sasshiato(path=&__path,' ||
                   " debug=&debug, dataset=&rrguri, reptype=L);";  output;
            %end; 
            %else %do;
                  record= '     %__sasshiato(' ||"debug=&debug,dataset=&rrguri,reptype=L);";  output;
            %end;
            record= '    %end;';  output;
            record= '  %end;';  output;
        %end;
        record=" ";  output;
        record= '%mend rrgout;';  output;
        record=" ";  output;
        record= '%rrgout;';  output;
     
   
run;

proc append base=rrgpgm data=rrgpgmtmp;
run;


data _null_;
  set rrgpgm;
  file " &rrgpgmpath./&rrguri..sas" lrecl=1000;
  put record;
run;

%inc "&rrgpgmpath./&rrguri..sas";

%if %upcase(&savercd)=Y  %then %do;
%__savercd_m; *** make it after program is submitted generated;
%end;

%if %upcase(&gentxt)=Y  %then %do;
    %__gentxt_m; 
%end;

%if %length(&metadatads) %then %do;
    %__meta(&fname);
%end;





%mend;

