/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro rrg_codeafterlist(string)/ parmbuff store ;

%local string;
%local st dost;
%let st=;

data __tmpcba;
length string ns tmp  $ 32000;
string = symget("syspbuff");
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
  string=trim(left(string));
  do z =1 to countw(string, ";");
    __word=__word+1;
    tmp = cats(scan(string, z, ";"));
    if length(tmp)<=100 then do;
        ns= cats(tmp,";");
    __whole=1;
        output;
    end;
    else do;
    tmp = tranwrd(trim(left(tmp)), ' ', '/#32'); 
    tmp = tranwrd(trim(left(tmp)), '""', '"'||byte(12)||'"');
    tmp = tranwrd(trim(left(tmp)), "''", "'"||byte(12)||"'");
         
    __whole=0;
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

data __tmpcba;
file "&rrgpgmpath./&rrguri.0.sas" mod lrecl=8192;
set __tmpcba end=eof;
if index(ns,';')>0 then xx=1;
else xx=0;
wascolon=lag(xx);

if _n_=1 then do;
  put '*----------------------------------------------------------------;';
  put '*   BEGIN CUSTOM CODE;';
  put '*----------------------------------------------------------------;';
  put;
end;
ns = tranwrd(ns, '/#32', ' ');
ns = tranwrd(trim(left(ns)), '"'||byte(12)||'"','""');
ns = tranwrd(trim(left(ns)), "'"||byte(12)||"'","''");

if _n_=1 or wascolon=1  then put @1 ns;
else put @5 ns;
if upcase(ns) in ('RUN;','QUIT;') then put;

if eof then do;
  put ;
  put @1 '*----------------------------------------------------------------;';
  put @1 '*   END CUSTOM CODE;';
  put @1 '*----------------------------------------------------------------;';
end;

run;


%mend rrg_codeafterlist;
