
%macro test;
  
  options ls=200 nocenter mprint;
  
%let Missdec=Missing;

%let codes=1;
%let groupvars=siteid sex;
%let warn_on_nomatch=1;
%let remove='F';
%let showmiss=Y;
%let fmt=sexf.;
%let decode=sexc;
%let codesds=;
%let codelistds=;
%let countds=cnts;
%let by=;
%let var=age;
%let dsin=__dataset;
%let missorder=99;
%let tmpgrp=;
%let aetable=EVENTS;

data test;
  length record $ 200;
  keep record;


record=" "; output;
record=" "; output;
length __missdec $ %eval(%length(&missdec)+2);
__missdec = dequote(symget("missdec"));
__missdec=quote(strip(__missdec));
*__missdec = symget("missdec");

%if &codes=1 or &codesds=1  %then %do; 

    record= "*----------------------------------------------------------------;";      output;
    record= "* TAKE ONLY COUNTS FOR MODALITIES NOT IN DATASET FROM codelist  ;";       output;
    record= "*----------------------------------------------------------------;";      output;
    record=" ";                                                                        output;
    record= "data &codelistds;";                                                       output;
    record= "  set &countds;";                                                         output;
    record= "  if 0 then __total=.;";                                                  output;
    record= "  if __trtid<0 and __total ne 1;";                                        output;
    record= "  keep &by __tby &groupvars __order &var __grpid &decode ;";              output;
    record= "run;";                                                                    output;
    record=" ";                                                                        output;
                                                                                       
    %if %length(&by.&groupvars)>0 and &codes ne 1  %then %do;                         

        record= "*------------------------------------------------------;";            output;
        record= "* MERGE COUNTS DATASET WITH 'GROUP TEMPLATE' DATASET   ;";            output;
        record= "* KEEPING ONLY GROUPING VARIABLES VALUES FROM TEMPLATE ;";            output;
        record= "*------------------------------------------------------;";            output;
        record=" ";                                                                    output;
                                                                                       
                                                                                      
        record= "proc sort data=&grptemplateds;";                                      output;
        record= "  by &by &groupvars;";                                                output;
        record= "run;";                                                                output;
        record=" ";                                                                    output;
        record= "proc sort data=&dsin;";                                               output;
        record= "  by &by &groupvars;";                                                output;
        record= "run;";                                                                output;
        record=" ";                                                                    output;
        record= "data &dsin;";                                                         output;
        record= "  merge &dsin &grptemplateds (in=__a keep = &by &groupvars);";        output;
        record= "  by &by &groupvars;";                                                output;
        record= "  if not __a then do;";                                               output;
        %if &warn_on_nomatch=1 %then %do;                                              
            record= "    put 'WAR' 'NING: deleting the following group ;'";            output;
            record= "'    as not found in codelist :' &tmpgrp;";                       output;
        %end;                                                                          
        record= "    delete;";                                                         output;
        record= "  end;  ";                                                            output;
        record= "run;";                                                                output;
        record=" " ;                                                                   output;
    %end;                                                                              
    record= "*------------------------------------------------------;";                output;
    record= "* MERGE COUNTS DATASET WITH CODELIST DATASET           ;";                output;
    record= "* KEEPING ONLY ANALYSIS VARIABLE VALUES FROM TEMPLATE  ;";                output;
    record= "*------------------------------------------------------;";                output;
    record=" ";                                                                        output;
                                                                                       
    record= "data &codelistds;";                                                       output;
    record= "set &codelistds;";                                                        output;
    record= "if missing(&var) then __order=&missorder; ";                              output;
    record= "run;";                                                                    output;
    record=" ";                                                                        output;
                                                                                       
    record= "proc sort data=&codelistds nodupkey;";                                    output;
    record= "  by &by __tby &groupvars __order  &var __grpid &decode ;";               output;
    record= "run;";                                                                    output;
    record=" ";                                                                        output;
    record= "proc sort data=&dsin;";                                                   output;
    record= "  by &by __tby &groupvars   __order &var __grpid &decode ;";              output;
    record= "run;";                                                                    output;
    record=" ";                                                                        output;
                                                                                       
    record= "data &dsin;";                                                             output;
    record= "  merge &dsin &codelistds (in=__a);";                                     output;
    record= "  by &by __tby &groupvars   __order &var __grpid &decode ;";              output;
    record= "  if 0 then do;";                                                         output;
    record= "    __total=1;";                                                          output;
    record= "    __missing=0;";                                                        output;
    record= "  end;";                                                                  output;
                                                                                       
    record= "** KEEP ONLY REQUESTED MODLAITIES;";                                      output;
    record= "**  and MISSIGN MODALITY AND TOTAL IF REQUESTED;";                        output;
    record= "if not __a and __total ne 1 and __missing ne 1 then do;";                 output;
    %if &warn_on_nomatch=1 %then %do;                                                  
          record= "   put 'WAR' 'NING: deleting the following modality ;'";            output;
          record= "'     as not found in codelist : ' &tmpgrp &var.=;";                 output;
    %end;                                                                              
    record= "   delete;";                                                              output;
    record= "end;  ";                                                                  output;
    %if %length(&remove)>0 %then %do;                                                  
        length remove $ %length(&remove);                                              
        remove = strip(symget("remove"));                                              
        record= "if __total ne 1  then do;";                                           output;
        record= "   if &var  in ( "||strip(remove)||" ) then delete;";                 output;
        record= "end;  ";                                                              output;
    %end;                                                                              output;
                                                                                       
    record= "run;";                                                                    
    record=" " ;                                                                       output;
%end;                                                                                 
%else %do;                                                                             
    record= "proc sort data=&dsin;";                                                   output;
    record= "  by &by __tby &groupvars   __order &var __grpid &decode ;";              output;
    record= "run;";                                                                    output;
    record=" " ;                                                                       output;
%end;                                                                              
                                                                                       
record=" ";                                                                            output;
record= "*-----------------------------------------------------------------;";         output;
record= "* CREATE DISPLAY OF ANALYSIS VARIABLE;";                                      output;
record= "*-----------------------------------------------------------------;";         output;
record= " " ;                                                                          output;
record= "data &dsin;";                                                                 output;
record= "  length __col_0 $ 2000;";                                                    output;
record= "  set &dsin;";                                                                output;
record= "  by &by __tby &groupvars   __order &var __grpid &decode ;";                  output;
record=" ";                                                                            output;
record= '  array __col{*} $ 2000 __col_1 -__col_&maxtrt;';                             output;
record= '  array __cnt{*} __cnt_1 -__cnt_&maxtrt;';                                    output;
record= '  array __colevt{*} $ 2000 __colevt_1 -__colevt_&maxtrt;';                    output;
record=" " ;                                                                           output;
record= "  if 0 then do;";                                                             output;
record= "    __total=0;";                                                              output;
record= "    __missing=0;";                                                            output;
record= "    __fordelete=.;";                                                          output;
record= "    do __i =1 to dim(__col);";                                                output;
record= "      __cnt[__i]=0;";                                                         output;
record= "      __colevt[__i]='';";                                                     output;
record= "    end;";                                                                    output;
record= "   end;";                                                                     output;
record=" " ;                                                                           output;
record=" ";                                                                            output;
record= "  __rowtotal=0;";                                                             output;
record= "  do __i =1 to dim(__col);";                                                  output;
record= "    if __col[__i]='' then __col[__i]='0';";                                   output;
record= "    if __cnt[__i]=.  then __cnt[__i]=0;";                                     output;
record= "    if __colevt[__i]='' then __colevt[__i]='0';";                             output;
record= "     __rowtotal=__rowtotal+__cnt[__i];";                                      output;
record= "  end;";                                                                      output;
record=" " ;                                                                           output;
record= "  if __missing ne 1 and __total ne 1 then do;";                               output;
record= "    __col_0 = cats(&var);";                                                   output;
record=" " ;                                                                           output;
%if %index(&aetable, EVENTS)>0 or &showmiss ne A %then %do;                            output;
    record= "    %* THIS CLEARS 0-COUNT ROWS FOR MISSING MODALITY: ;";                 output;
    record= "    if missing(&var) and __rowtotal=0 then delete;";                      output;
%end;                                                                                  output;
                                                                                     
record= "    if __grpid=999 and  missing(&var) and __col_0 = '' ";                     output;
record= "       and not first.__grpid then do;";                                       output;
record= "    * __GRPID = 999 CORRESPONDS TO COUNT OF &VAR;";                           output;
record= "     __col_0 = cats('"||"&missdec"||"');";                                    output;
record= "     __order = &missorder;";                                                  output;
record= "    end;";                                                                    output;
record= "    else do;";                                                                output;
%if %length(&fmt) %then %do;                                                           
    record= "       __col_0=put(&var, &fmt);";                                         output;
%end;                                                                                 
%if %length(&decode) %then %do;                                                        
    record= "       __col_0=&decode;";                                                 output;
%end;                                                                                  
record= "    end;";                                                                    output;
record= "  end;";                                                                      output;
record= "  else if __missing=1 then do;";                                              output;
record= "    __order = &missorder;";                                                   output;
%if &showmiss ne A %then %do;                                                          
    record= "    if missing(&var) and __rowtotal=0 then delete;";                      output;
%end;                                                                                  
%if %length(&decode) %then %do;                                                        
    record= "    __col_0=&decode;";                                                    output;
    record= "    if missing(&var) then __col_0 =" ||strip(__missdec)|| ";";                       output;
%end;                                                                                  output;
record= "    if __col_0='' then __col_0="||strip(__missdec)|| ";";                            output;
record= "  end;";                                                                      output;
record= "__col__0=''; __cnt__0=.; __pct__0=.; __colevt__0='';";                        output;
record= "if __fordelete=1 then delete;";                                               output;
record= "drop __col__: __cnt__: __pct__: __colevt__:;  ";                              output;
                                                                                      
record= "run;";                                                                        output;
record=" ";                                                                            output;
run;

proc print data=test width=min;
run;

%mend;

%test;
