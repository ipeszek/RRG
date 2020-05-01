/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 
 * there are no user-provided parameters for this macro
 
 */


%macro rrg_codebefore(string)/parmbuff store;

%local string inlibs;

data _null_;
  set __rrgconfig(where=(type='[E2]'));
  call symput('inlibs',cats(w1));
run;

%local st ;
%let st=;

data __tmpcba;
length string ns tmp  $ 32000;
string = symget("syspbuff");
string = trim(left(string));
retain __word;
__word=0;
__ls = 100;
string = substr(string, 2);
if length(string)>1 then string = substr(string, 1, length(string)-1);
__whole=0;
if compress(string,"()") = '' then do;
  ns='';
  output;
end;
else do;
  call symput("st", string);
  do z =1 to countw(string, ";");
    __word=__word+1;
    tmp = cats(scan(string, z, ";"));
    if length(tmp)<=100 then do;
        ns= cats(tmp,";");
    __whole=1;
        output;
  end;
    else do;
    __whole=0;
    tmp = tranwrd(trim(left(tmp)), ' ', '/#32');
    tmp = tranwrd(trim(left(tmp)), '""', '"'||byte(12)||'"');
    tmp = tranwrd(trim(left(tmp)), "''", "'"||byte(12)||"'");
      if index(tmp, '"')>0 then do;
         if index(tmp, '"')=1 then do;
            do i=1 to countw(tmp, '"');
               if mod(i,2)=1 then ns = cats('"',scan(tmp,i, '"'),'"');
         else ns = cats(scan(tmp,i, '"'));
         output;
      end;
     end;
     else do;
            do i=1 to countw(tmp, '"');
               if mod(i,2)=0 then ns = cats('"',scan(tmp,i, '"'),'"');
         else ns = cats(scan(tmp,i, '"'));
         output;
      end;
     end;
    end;
      else if index(tmp, "'")>0 then do;
         if index(tmp, "'")=1 then do;
            do i=1 to countw(tmp, "'");
               if mod(i,2)=1 then ns = cats("'",scan(tmp,i, "'"),"'");
         else ns = cats(scan(tmp,i, "'"));
         output;
      end;
     end;
     else do;
            do i=1 to countw(tmp, "'");
               if mod(i,2)=0 then ns = cats("'",scan(tmp,i, "'"),"'");
         else ns = cats(scan(tmp,i, "'"));
         output;
      end;
     end;
    end;
      else do;
        ns= cats(tmp);
    output;
    end;
    ns = ";";
    output;
  end;
  end;
end;
keep ns __whole __word;
run;



%*** need second scan;

data __tmpcba;
set __tmpcba (rename=(ns=tmp));
length ns $ 32000;

if length(tmp)<=100 or index(tmp, '"')>0 or index(tmp,"'")<=0 then do;
  ns=tmp;
  output;
end;

else do;
    if index(tmp, "'")=1 then do;
        do i=1 to countw(tmp, "'");
           if mod(i,2)=1 then ns = cats("'",scan(tmp,i, "'"),"'");
         else ns = cats(scan(tmp,i, "'"));
       output;
    end;
  end;
  else do;
        do i=1 to countw(tmp, "'");
           if mod(i,2)=0 then ns = cats("'",scan(tmp,i, "'"),"'");
       else ns = cats(scan(tmp,i, "'"));
       output;
    end;
  end;
end;
keep ns __whole;
run;  



%* third scan - split all sentences not in quotes into <100 chars;

data __tmpcba;
set __tmpcba(rename=(ns=string));
length ns tmp1 tmp2 tmp3 $ 32000;
if length(string)<=100 or index(string, '"')>0 or index(string,"'") >0 then do;
  ns = cats(string);
  output;
end;
else do;
  cntw = countw(string,' ');
  tmp1='';
  do i=1 to cntw;
    tmp2 = cats(scan(string, i, ' '));
  tmp3 = cats(tmp1)||' '||cats(tmp2);
  if length(tmp3)>100 then do;
       ns = cats(tmp1);
     output;
     tmp1=cats(tmp2);
  end;
  else do;
      tmp1=cats(tmp3);
    tmp2='';
  end;
  end;
  if tmp1 ne '' then do;
     ns = cats(tmp1);
   output;
  end;
end;
keep ns __whole;
run;



data __tmpcba;
set  __tmpcba end=eof;
length ns2 tmp tmp2 $ 2000;
retain ns2;
if _n_=1 then ns2='';
if __whole=1 then do; 
   tmp = cats(ns);
   if ns2 ne ''  then do;
      ns = cats(ns2);
      output;
    ns = cats(tmp);
   end;
   output; 
   ns2=''; 
end;
else do;
  ** if current record is >100 in length then output buffer, current record and then flush buffer;
  ** else if previous record + current record > 100 then output buffer and put current record in buffer;
  ** else append to buffer;
  if length(ns)>100 then do;
     tmp = cats(ns); 
     if ns2 ne '' then do; 
         ns=cats(ns2); 
         output; 
     ns2='';
     end;
     ns = cats(tmp); 
     output; 
   ns2='';
  end;

  else do;
    tmp2 = cats(ns2);
  tmp = cats(ns);
  ns2  = cats(ns2)||' '||cats(ns);
  if length(ns2)>100 then do;
       ns = cats(tmp2);
     output;
     ns2=cats(tmp);
  end;
  end;
end;
if eof then do;
  if ns2 ne '' then do; 
    ns=ns2; 
    output; 
  end;
end;
run;

data __rrght0;
set __tmpcba end=eof;
length record $ 2000;
if index(ns,';')>0 then xx=1;
else xx=0;
wascolon=lag(xx);

if _n_=1 then do;
  record=''; output;
  record=''; output;
  record= '*----------------------------------------------------------------;'; output;
  record= '*   BEGIN CUSTOM CODE;'; output;
  record= '*----------------------------------------------------------------;'; output;
  record=' '; output;
end;
ns = tranwrd(ns, '/#32', ' ');
ns = tranwrd(trim(left(ns)), '"'||byte(12)||'"','""');
ns = tranwrd(trim(left(ns)), "'"||byte(12)||"'","''");
    
if _n_=1 or wascolon=1  then do; record= cats(ns); output; end;
else do; record = "     "||cats(ns); output; end;
if upcase(ns) in ('RUN;','QUIT;') then do;
  record='';
  output;
end;

if eof then do;
  record=  ' '; output;
  record=  '*----------------------------------------------------------------;'; output;
  record=  '*   END CUSTOM CODE;'; output;
  record=  '*----------------------------------------------------------------;'; output;
end;
keep record;
run;


data __rrght;
  set  __rrght __rrght0;
run;


%if %length(&inlibs)>0 %then %do;
/*
 data __rrginlibs0;
  length tmp tmp1 dataset $ 200;
  set __rrght0;
  tmp = upcase(cats(symget("inlibs")));

  if index(upcase(record), cats(tmp))>0 then do;
      do i = 1 to countw(record);
       tmp1 = scan(record, i, ' =(');
       
       if index(upcase(tmp1), cats(tmp))>0 then do;
         %* dataset = scan(upcase(tmp1),2, '.; ')||'.SAS7BDAT';
         dataset = scan(upcase(tmp1),1, '; ');
         
         output;
       end;
      end;    
  end;
  keep dataset;
 run; 
 
 data __rrginlibs;
  set __rrginlibs __rrginlibs0;
run;
*/

%end;

%***************************************************************************************;
%*  scan codebefore for datasets and variables;
%***************************************************************************************;

%if %length(&inlibs)=0 %then %goto skipmeta;


data __tmp1;
length string  tmp   $ 32000;
string = symget("syspbuff");
string = trim(left(string));
do i=1 to countw(string,';');
  tmp = scan(string,i,';');
  output;
end;
keep tmp;
run;

*** get names of variables;
data __tmp2;
set __tmp1;
length name $ 32;
keep name;
length tmp2 $ 2000;
do i=1 to length(tmp);
  tmp2 = scan(tmp,i, "!@#$%^&*()+[{-=}]|\:;<,>.?/ ");
  if index(tmp2, '"') ne 1 and index(tmp2, "'") ne 1 then do;
     name = upcase(strip(tmp2));
     if name ne '' then output;
  end;
end; 
run;

data __tmp2;
  length name $ 32;
  set __tmp2;
run;

proc sort data=__tmp2 nodupkey;
by name;
run;


***get datasets with options;
%local inlibs0 i;

data __tmp3;
  if 0;
run;

%do i=1 %to %sysfunc(countw(&inlibs, %str( )));
  %let inlibs0 = %upcase(%scan(&inlibs, &i, %str( )));
  
  data __tmp30;
  length tmp2 str tmp dataset $ 32000 xx $ 2;
  set __tmp1;
  tmp2 = upcase(tmp);
  xx = byte(160)||byte(161);
  tmp2 = tranwrd(tmp2, "&inlibs0..", xx);
  num = countw(tmp2, byte(160));
  do i=1 to num;
    str = scan(tmp2,i, byte(160));
    if index(str, byte(161))=1 then do;
    tmp='';
    found1=0; found2=0;
    do while (str ne ''  );
      ind1 = index(str,'(');
      ind2 = index(str,')');
      if ind1=0 and ind2=0 then do;
        case=1;
        put 'case1 ' str= found1= found2=;
        str='';
        tmp=strip(tmp)||strip(str);
        put tmp=;
        if found1=found2 then str='';
      end;
      else if ind1=0 and ind2>0 then do;
        case=2;
        found2+1;
        put 'case2 ' str= found1= found2=;
        tmp = strip(tmp)||substr(str,1, ind2);
        if length(str)>ind2 then str = substr(str,ind2+1);
        else str='';
        put tmp=;
        if found1=found2 then str='';
      end;
      else if ind2=0 and ind1>0 then do;
        case=3;
        found1+1;
        put 'case3 ' str= found1= found2=;
        tmp = strip(tmp)||substr(str,1, ind1);
        if length(str)>ind1 then str = substr(str,ind1+1);
        else str='';
        put tmp=;
        if found1=found2 then str='';
      end;
      else if ind2 >0 and ind1>0 and ind1<ind2 then do;
        case=4;
        found1+1;
        put 'case4 ' str= found1= found2=;
        tmp = strip(tmp)||substr(str,1, ind1);
        if length(str)>ind1 then str = substr(str,ind1+1);
        else str='';
        put tmp=;
        if found1=found2 then str='';
      end;
      else if ind2>0 and ind1>0 and ind1>ind2 then do;
        case=5;
        found2+1;
        put 'case5 ' str= found1= found2=;
        tmp = strip(tmp)||substr(str,1, ind2);
        if length(str)>ind2 then str = substr(str,ind2+1);
        else str='';
        put tmp=;
        if found1=found2 then str='';
      end;
     end;
       dataset=tranwrd(tmp, byte(161), "&inlibs0..");
       if found1 ne found2 then dataset = scan(dataset,1,' (');
       output;
     end;
  end; 
  keep dataset;
  run;

  data __tmp3;
    set __tmp3 __tmp30;
  run;

%end;

*------ create list of variables from each used dataset;
   
   %local numds i;
   
   
   
   data __tmp3;
   set __tmp3 end=eof;
   dataset = scan(dataset,1,'( ');
   length stmt $ 2000;
   stmt = "data __tmp; set "||strip(dataset)||'; run; proc contents data=__tmp noprint out=__cont'||strip(put(_N_, best.))||
          '; run;  data __cont'||strip(put(_N_, best.))||'; length dsname $ 200; set __cont'||strip(put(_N_, best.))||
          '; dsname = "'||strip(scan(dataset,2,'.('))||'";';
   call execute(stmt);
   if eof then call symput('numds', strip(put(_N_, best.)));
   run;
   
  
   
  
   
   data __cont;
    if 0;
   run;
   
   *--- check which variable is in which dataset;
   %if &numds>0 %then %do;
   %do i=1 %to &numds;
        data __cont&i;
          length name $ 40;
          set __cont&i;
          name= upcase(name);
          dsname= upcase(dsname);
          keep name dsname;
        run;
        
        proc sort data=__cont&i nodupkey;
          by name;
        run;
        
        data __cont&i;
          merge __cont&i (in=a) __tmp2 (in=b);
          by name;
          if a and b;
          dsname = strip(dsname)||'.'||strip(name);
        run;
          
        data __codebvars;
          set __cont __cont&i (keep=dsname);
         run;
         
      
   %end;
 
%end;
     data __tmp4;
          length ds $ 2000;
          set __tmp3;
          ds = scan(dataset, 1,'(');
          keep ds;
        run;
        
         data __usedds;
          set __usedds __tmp4;
        run;

%skipmeta:

&st;

%mend;

