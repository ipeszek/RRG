/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */
 
 /* PROGRAM FLOW:
   14Sep2020 
    
    creates or updates metadata dataset
    
    ds used __repinfo, __rrgpgminfo, __listinfo,__codebvars, __mout.&metadatads
    ds created __cont
    ds updated __rrginlibs, __usedds, __cont&i, __mout.&metadatads
    ds initialized

*/
 
%*----------------------------------------------------------------------;
%* save metadata;
%*----------------------------------------------------------------------;

%macro __meta(fname)/store;

%local  fname useddatasets usedvars tt1 tt2 tt3 tt4 tt5 tt6 i subjid 
       where n_analvar macrosinc1 macrosinc2 metadatads ;
       
data _null_;
  set __repinfo;
  %do i=1 %to 6;
    call symput("tt&i", strip(title&i));
  %end;
  call symput("metadatads", strip(METADATADS));
run;


proc sql noprint;
 select strip(value) into:macrosinc1 separated by '; '
   from __rrgpgminfo (where =(key='rrg_inc'));
 select strip(value) into:macrosinc2 separated by '; '
   from __rrgpgminfo (where =(key='rrg_call_macro'));

quit;  

libname __mout "&rrgoutpath";  

data __rrginlibs;
 length dataset  $ 2000;
 set __rrginlibs;
 if 0 then dataset='';
run;

data __usedds;
 set __usedds __repinfo (keep = dataset rename=(dataset=ds)) __rrginlibs(rename=(dataset=ds));
run;

*--- keep only "permanent datasets" in __usedds;

data  __usedds;
 set __usedds;
 if index(ds, '.')>0;
 run;   
  
  proc sql noprint;
    select distinct scan(ds,1,'(') into:useddatasets separated by '; '  from __usedds;
  quit;
  
  data __vars;
    set __listinfo end=eof;
    length name $ 32;
    name= upcase(alias);
    if name ne '' then output;
    name=upcase(decode);
    if name ne '' then output;
    if eof then do;
      name = upcase(symget("subjid"));
      output;
    end;  
    keep name;
   run;
   
   data __vars2;
    set __usedds;
    length tmp $ 2000 name $ 32;
    tmp  = scan(ds,2,'(');
      do i=1 to length(tmp);
      tmp2 = scan(tmp,i, "!@#$%^&*()+[{-=}]|\:;<,>.?/ ");
      if index(tmp2, '"') ne 1 and index(tmp2, "'") ne 1 then do;
        name = upcase(strip(tmp2));
        if name ne '' then output;
      end;
    end; 
    keep name;
  run;
  
  data __vars;
    set __vars __vars2;
  run;
    
   proc sort data=__vars nodupkey;
      by name;
    run;

   
   
   *------ create list of variables from each used dataset;
   
   %local i numds;
   
   data __usedds;
   set __usedds end=eof;
   length stmt $ 2000;
   ds = scan(ds,1,'( ');
   stmt = "data __tmp; set "||strip(ds)||'; run; proc contents data=__tmp noprint out=__cont'||strip(put(_N_, best.))||
          '; run;  data __cont'||strip(put(_N_, best.))||'; length dsname $ 200; set __cont'||strip(put(_N_, best.))||
          '; dsname = "'||strip(scan(ds,2,'.('))||'";';
   call execute(cats('%nrstr(',stmt,')'));
   if eof then call symput('numds', strip(put(_N_, best.)));
   run;
   
   
   data __cont;
    if 0;
   run;
   
   *--- check which variable is in which dataset;
   %if &numds>0 %then %do;
     %do i=1 %to &numds;
          data __cont&i;
            length name $ 32;
            set __cont&i;
            name= upcase(name);
            dsname= upcase(dsname);
            keep name dsname;
          run;
          
          proc sort data=__cont&i nodupkey;
            by name;
          run;
          
          data __cont&i;
            merge __cont&i (in=a) __vars (in=b);
            by name;
            if a and b;
            dsname = strip(dsname)||'.'||strip(name);
          run;
            
          data __cont;
            set __cont __cont&i (keep=dsname);
           run;
     %end;
     
   data __cont;
    set __cont __codebvars;
   run;
  
   proc sort data=__cont nodupkey;
    by dsname;
  run;
   
     proc sql noprint;
      select distinct dsname into:usedvars separated by '; '  from __cont;
     quit;
  
   %end;   
   
 *--- check if metadata file exist, if not then create it ---;

   %if %sysfunc(exist(__mout.&metadatads))=0 %then %do;
       data __mout.&metadatads;
        if 0;
        length rrguri $ 100 datasets variables popwhere tabwhere invarwhere title1-title6 o_where  fname 
               macrosused $ 2000;
        rrguri='';
        datasets='';
        variables='';
        popwhere='';
        tabwhere ='';
        title1='';
        title2='';
        title3='';
        title4='';
        title5='';
        title6='';
        o_where ='';
        invarwhere='';
        fname='';
        macrosused='';
       run; 
   %end;   
   
  *--- if append=n then delete existing entries for the program;
   
   %if %upcase(&append)=N  %then %do;
     data __mout.&metadatads;
      set __mout.&metadatads;
      if rrguri = strip("&rrguri") then delete;
     run; 
   %end; 
   
   *--- insert entries for the program;
   
      data __meta;
        length rrguri $ 100 datasets variables popwhere tabwhere invarwhere title1-title6 o_where fname 
               macrosused tmp1 tmp2 $ 2000;
        rrguri = strip(symget("rrguri"));
        fname =  strip(symget("fname"));
        datasets = strip(symget("useddatasets"));
        variables = strip(symget("usedvars"));
        tabwhere='';
        popwhere='';
        invarwhere='';
        o_where = '';
        %do i=1 %to 6;
          title&i = strip(symget("tt&i"));
        %end;
        macrosused = '';
        tmp1 = strip(symget("macrosinc1"));
        tmp2 = strip(symget("macrosinc2"));
        macrosused = catx('; ',strip(tmp1),strip(tmp2));
        
        drop tmp1 tmp2;
      run;  

      data __mout.&metadatads;
      set __mout.&metadatads __meta;
      run;
      
  
%mend __meta;  