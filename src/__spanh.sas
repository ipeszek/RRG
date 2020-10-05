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


data rrgpgmtmp;
length record $ 2000;
keep record;
record=" ";
output; record=" ";
output; record=" *--------------------------------------------------------;";
output; record=" * extract common text from column headers to create";
output; record="    spanned headers;";
output; record=" *--------------------------------------------------------;";
output; record=" data &dsin;";
output; record=" set &dsin;";
output; record='array cols{*} __col_1-__col_&maxtrt;';
output; record=" __nw=1;";
output; record=" __notblank=0;";
output; record=" if __col_0 ne '' then __notblank=1;";
output; record='do __i =1 to &maxtrt;';
output; record="    if cols[__i] ne '' then __notblank=1;"; 
output; record="    do __j =1 to length(cols[__i]);";
output; record="      if scan(cols[__i],__j, ' ') ne '' then __nw = max(__nw, __j);";
output; record="    end; ";
output; record=" end;";
output; record=" if __notblank=1 then output;";
output; record=" drop __i __j;";
output; record=" run;";
output; record=" ";
output; record=" ";
output; record=" proc sort data=&dsin;";
output; record=" by descending __rowid;";
output; record=" run;";
output; record=" data &dsin;";
output; record=" set &dsin;";
output; record='length __tmp1 __tmp2 __com_1-__com_&maxtrt $ 2000;';
output; record='array cols{*} __col_1-__col_&maxtrt;';
output; record='array s{*} __s_1-__s_&maxtrt;';
output; record='array e{*} __e_1-__e_&maxtrt;';
output; record='array com{*} $ 2000 __com_1-__com_&maxtrt;';
output; record=" if __autospan='N' then output;";
output; record=" else do;";
output; record=" __tmp1='';";
output; record=" __tmp2='';";
output; record=" ";
output; record=" __start=1;";
output; record=" __found=0;";
output; record=" __chg=0;";
output; record=" ";
output; record='do __i=1 to &maxtrt;';
output; record="   cols[__i]=trim(left(cols[__i]));";
output; record="   if __found>0 or __i=__start+1 then do;";
output; record="    if scan(cols[__start],1,' ') = scan(cols[__i],1,' ') then __found=1;";
output; record="    else __found=0;";
output; record="   end;";
output; record="   if __found=0 then do;";
output; record="       do __j=__start to __i;";
output; record="          s[__j]=__start;";
output; record="          e[__j]=__i-1;";
output; record="       end;";
output; record="       __start=__i;";
output; record="   end;";
output; record=" end;";
output; record=" ";
output; record='do __j=__start to &maxtrt;';
output; record="    s[__j]=__start;";
output; record='   e[__j]=&maxtrt;';
output; record=" end;";
output; record=" ";
output; record='do __i=1 to &maxtrt;';
output; record="    com[__i]='';";
output; record="    if e[__i]>s[__i] then do;";
output; record="       com[__i]=scan(cols[__i],1,' ');";
output; record="       __diff2=0;";
output; record="       do __j=2 to __nw;";
output; record="          if __diff2=0 then do;";
output; record="             __diff=0;";
output; record="             __tmp2 = scan(cols[__i], __j, ' ');";
output; record="             do __k=s[__i] to e[__i];";
output; record="                __tmp1 = scan(cols[__k], __j, ' ');";
output; record="                if __tmp1 ne __tmp2 then __diff=1;";
output; record="             end;";
output; record="             if __diff=0 then ";
output; record="               com[__i]=trim(left(com[__i]))||' '||trim(left(__tmp2));";
output; record="             __diff2=__diff2+__diff;";
output; record="          end;";
output; record="       end;";
output; record="       do __j = s[__i]+1 to e[__i];";
output; record="          com[__j]=com[s[__i]];";
output; record="       end;";
output; record="       __i = e[__i];";
output; record="    end;";
output; record=" end;";
output; record=" ";
output; record=" __iscomm=0;";
output; record=" ";
output; record='do __i =1 to &maxtrt;';
output; record="    if com[__i] ne '' and cats(com[__i]) ne cats(cols[__i]) then __iscomm=1;";
output; record=" end;";
output; record=" ";
output; record=" if __iscomm=1 then do;";
output; record='   do __i =1 to &maxtrt;';
output; record="       __k = length(com[__i])+1;";
output; record="       if com[__i] ne '' then do;";
output; record="          if __k < length(cols[__i]) then ";
output; record="             cols[__i]=trim(left(substr(cols[__i], __k)));";
output; record="          else cols[__i]='';";
output; record="       end;";
output; record="       if cols[__i] ne '' then __gotcommon=1;";
output; record="    end;";
output; record="    if __gotcommon=1 then output;";
output; record="    __col_0 ='';";
output; record='   do __i =1 to &maxtrt;';
output; record="       cols[__i]=com[__i];";
output; record="    end;";
output; record="    __rowid=__rowid-0.1;";
output; record="    output;";
output; record=" end;";
output; record=" else output;";
output; record=" end;";
output; record=" drop __i __k __j __tmp: __diff: __s: __e: ";
output; record="      __com: __found __iscomm __nw __gotcommon;";
output; record=" run;";
output; record=" ";
output; record=" ";
output; record=" proc sort data=&dsin;";
output; record=" by &varby __rowid;";
output; record=" run;";
output; record=" ";
output; record=" data &dsin ;";
output; record=" set &dsin (drop=__rowid);";
output; record=" __rowid=_n_;";
output; record=" run;";
output; record=" ";
output; record=" data &dsin ;";
output; record=" set &dsin ;";
output; record=" output;";
output; record=" if __prefix ne '' then do;";
output; record="   __rowid=__rowid-0.1;";
output; record="   array cols __col_:;";
output; record="   do __i=1 to dim(cols);";
output; record="     cols[__i]=cats(__prefix);";
output; record="   end;";
output; record="   __col_0='';";
output; record="   output;";
output; record=" end;";
output; record=" run;";
output; record=" ";
output; record=" proc sort data=&dsin;";
output; record=" by &varby __rowid;";
output; record=" run;";
output; record=" ";
output;
run;



proc append data=rrgpgmtmp base=rrgpgm;
run;

%mend;

