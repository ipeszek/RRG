/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __spanh(dsin=)/store;
  
%* this macro extracts a common text from column headers;
%* to present it as a spanned header;
%* it tries to find the longest set of columns sharing common 1st word;

%local dsin ;

data _null_;
file "&rrgpgmpath./&rrguri..sas" mod;
put;
put;
put "*--------------------------------------------------------;";
put "* extract common text from column headers to create";
put "   spanned headers;";
put "*--------------------------------------------------------;";
put "data &dsin;";
put "set &dsin;";
put 'array cols{*} __col_1-__col_&maxtrt;';
put "__nw=1;";
put "__notblank=0;";
put "if __col_0 ne '' then __notblank=1;";
put 'do __i =1 to &maxtrt;';
put "   if cols[__i] ne '' then __notblank=1;"; 
put "   do __j =1 to length(cols[__i]);";
put "     if scan(cols[__i],__j, ' ') ne '' then __nw = max(__nw, __j);";
put "   end; ";
put "end;";
put "if __notblank=1 then output;";
put "drop __i __j;";
put "run;";
put;

put;
put "proc sort data=&dsin;";
put "by descending __rowid;";
put "run;";

put "data &dsin;";
put "set &dsin;";
put 'length __tmp1 __tmp2 __com_1-__com_&maxtrt $ 2000;';
put 'array cols{*} __col_1-__col_&maxtrt;';
put 'array s{*} __s_1-__s_&maxtrt;';
put 'array e{*} __e_1-__e_&maxtrt;';
put 'array com{*} $ 2000 __com_1-__com_&maxtrt;';
put "if __autospan='N' then output;";
put "else do;";
put "__tmp1='';";
put "__tmp2='';";
put;
put "__start=1;";
put "__found=0;";
put "__chg=0;";
put;
put 'do __i=1 to &maxtrt;';
put "  cols[__i]=trim(left(cols[__i]));";
put "  if __found>0 or __i=__start+1 then do;";
put "   if scan(cols[__start],1,' ') = scan(cols[__i],1,' ') then __found=1;";
put "   else __found=0;";
put "  end;";
put "  if __found=0 then do;";
put "      do __j=__start to __i;";
put "         s[__j]=__start;";
put "         e[__j]=__i-1;";
put "      end;";
put "      __start=__i;";
put "  end;";
put "end;";
put;
put 'do __j=__start to &maxtrt;';
put "   s[__j]=__start;";
put '   e[__j]=&maxtrt;';
put "end;";
put;
put 'do __i=1 to &maxtrt;';
put "   com[__i]='';";
put "   if e[__i]>s[__i] then do;";
put "      com[__i]=scan(cols[__i],1,' ');";
put "      __diff2=0;";
put "      do __j=2 to __nw;";
put "         if __diff2=0 then do;";
put "            __diff=0;";
put "            __tmp2 = scan(cols[__i], __j, ' ');";
put "            do __k=s[__i] to e[__i];";
put "               __tmp1 = scan(cols[__k], __j, ' ');";
put "               if __tmp1 ne __tmp2 then __diff=1;";
put "            end;";
put "            if __diff=0 then ";
put "              com[__i]=trim(left(com[__i]))||' '||trim(left(__tmp2));";
put "            __diff2=__diff2+__diff;";
put "         end;";
put "      end;";
put "      do __j = s[__i]+1 to e[__i];";
put "         com[__j]=com[s[__i]];";
put "      end;";
put "      __i = e[__i];";
put "   end;";
put "end;";
put;
put "__iscomm=0;";
put;
put 'do __i =1 to &maxtrt;';
put "   if com[__i] ne '' and cats(com[__i]) ne cats(cols[__i]) then __iscomm=1;";
put "end;";
put;
put "if __iscomm=1 then do;";
put '   do __i =1 to &maxtrt;';
put "      __k = length(com[__i])+1;";
put "      if com[__i] ne '' then do;";
put "         if __k < length(cols[__i]) then ";
put "            cols[__i]=trim(left(substr(cols[__i], __k)));";
put "         else cols[__i]='';";
put "      end;";
put "      if cols[__i] ne '' then __gotcommon=1;";
put "   end;";
put "   if __gotcommon=1 then output;";
put "   __col_0 ='';";
put '   do __i =1 to &maxtrt;';
put "      cols[__i]=com[__i];";
put "   end;";
put "   __rowid=__rowid-0.1;";
put "   output;";
put "end;";
put "else output;";
put "end;";
put "drop __i __k __j __tmp: __diff: __s: __e: ";
put "     __com: __found __iscomm __nw __gotcommon;";
put "run;";
put;
put;
put "proc sort data=&dsin;";
put "by &varby __rowid;";
put "run;";
put;
put "data &dsin ;";
put "set &dsin (drop=__rowid);";
put "__rowid=_n_;";
put "run;";
put;
put "data &dsin ;";
put "set &dsin ;";
put "output;";
put "if __prefix ne '' then do;";
put "  __rowid=__rowid-0.1;";
put "  array cols __col_:;";
put "  do __i=1 to dim(cols);";
put "    cols[__i]=cats(__prefix);";
put "  end;";
put "  __col_0='';";
put "  output;";
put "end;";
put "run;";
put;
put "proc sort data=&dsin;";
put "by &varby __rowid;";
put "run;";
put;

run;


%mend;

