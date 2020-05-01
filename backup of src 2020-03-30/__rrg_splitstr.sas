/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __rrg_splitstr(string=, len=, indentsize=)/store;
%local string len indentsize;

length __tmpf2 __tmpf __tmp0  $ 2000;
length __tmp1 __tmp __tmpw $ 2000;

%* split string at the tab positions;
__tmp0 = tranwrd(strip(&string), '//', byte(12));
__tabsize=0;
__tmpf2='';
&debugc put;
&debugc put "4iza " &string= __tmp0=;
do while (__tmp0 ne '');
  __tabpos = index(__tmp0, '/t');
  if __tabpos<=0 then do;
     __tmpf2 = strip(__tmpf2)||strip(__tmp0);
     __tmp0 = '';
  end;
  else do;
     __tabsize = __tabsize+input(substr(__tmp0, __tabpos+2,1), best.);
     &debugc  put __tabsize= __tabpos= __tmp0=;
       __padx = repeat(byte(11), &indentsize*__tabsize-1);
     if __tabpos>1 then do;
       if __tmpf2 = '' then __tmpf2 = strip(substr(__tmp0, 1, __tabpos-1))||byte(12)||strip(__padx);
       else __tmpf2 = strip(__tmpf2)||strip(substr(__tmp0, 1, __tabpos-1))||byte(12)||strip(__padx);
     end;
     else do;
       if __tmpf2 = '' then __tmpf2 = byte(12)||strip(__padx);
       else __tmpf2 = strip(__tmpf2)||byte(12)||strip(__padx);
     end;
     &debugc  put __tmpf=;
     __tmp0 = strip(substr(__tmp0, __tabpos+3));
     __tmp0 = tranwrd(strip(__tmp0), byte(12), byte(12)||strip(__padx));
  end;
  &debugc put __tmpf2=;
end;

__tmpf='';



if substr(__tmpf2,1,1)=byte(12) then __startsplit=1;
else __startsplit=0;

&debugc put __startsplit=;

do __j=1 to countw(__tmpf2, byte(12));
  &debugc put __j=;
  __tmp1=strip(scan(__tmpf2,__j,byte(12)));
  &debugc put __tmp1=;
  __padnum = count(__tmp1, byte(11));
  &debugc put __padnum= __tmp1=;
  __tmp1 = substr(__tmp1,__padnum+1);
  &debugc put  __tmp1= __padnum=;
  __tmp='';
  __spaceleft = &len-__padnum;
  
  if __spaceleft>=length(__tmp1) then do;
   if __padnum>0 then do;
      __pad='|'||repeat(byte(11),__padnum-1);;
      __tmp1 = repeat(byte(11),__padnum-1)||tranwrd(strip(__tmp1),'|', strip(__pad)); 
    end;    
    if __tmpf='' then __tmpf = strip(__tmp1);
    else __tmpf = strip(__tmpf)||'|'||strip(__tmp1);
  end;
  else do;
    __cw = countw(__tmp1, ' ');
    &debugc put __spaceleft= __cw=;
    do __i=1 to __cw;
       __tmpl = length(scan(__tmp1,__i,' '));
       if __tmpl>&len-__padnum then do;
          &debugc put "__tmpl>&len-__padnum " __tmpl= &len= __padnum=;
          __tmpw = scan(__tmp1, __i, ' ');
          if __spaceleft<=1 then do;
             &debugc put "case1";
             __tmp = strip(__tmp)||'|'||substr(__tmpw,1,&len);
             if length(__tmpw)>&len then  __tmpw = substr(__tmpw, &len+1);
             else __tmpw='';
             __spaceleft=&len-__padnum;
          end;
          else do;
            &debugc put "case2";
            __tmp = strip(__tmp)||' '||substr(__tmpw,1,__spaceleft-1);
            __tmpw = substr(__tmpw, __spaceleft);
            __spaceleft =&len-__padnum;
          end;
          &debugc put __tmpw= __spaceleft=;
          do while (__tmpw ne '');
            if length(__tmpw)>=__spaceleft then do;
               __tmp = strip(__tmp)||'|'||substr(__tmpw,1,__spaceleft);
               if length(__tmpw)>__spaceleft then __tmpw = substr(__tmpw, __spaceleft+1);
               else __tmpw='';
            end;
            else do;
               __tmp = strip(__tmp)||'|'||substr(__tmpw,1);
               __tmpw='';
            end;
            __spaceleft=&len-__padnum;
          end;
       %* end of if __tmpl>&len-__padnum ;   
       end;
       else do;
         &debugc put "__tmpl<=&len-__padnum ";
         if __tmp ne '' then __mod=1;
         else __mod=0;
         if __spaceleft-__mod-__tmpl<0 then do;
              %* word does not fit;
              __tmp = strip(__tmp)||'|'||scan(__tmp1,__i,' ');
              __spaceleft = &len - __padnum - __tmpl;
         end; 
         else do;
             %*word fits;
             if __tmp ne '' then do;
                __tmp = strip(__tmp)||' '||scan(__tmp1,__i,' ');
                __spaceleft = __spaceleft-1-__tmpl - __padnum;
             end;
             else do;
                __tmp = scan(__tmp1,__i,' ');
                __spaceleft = __spaceleft-__tmpl - __padnum;
             end;
         end;
       %* %* end of if __tmpl<=&len-__padnum;
       end;
    %* end of do __i=1 to __cw;
    end;
  
    
    if __padnum>0 then do;
      __pad='|'||repeat(byte(11),__padnum-1);;
      __tmp = repeat(byte(11),__padnum-1)||tranwrd(strip(__tmp),'|', strip(__pad)); 
    end;
  
    if __tmpf='' then __tmpf = strip(__tmp);
    else __tmpf = strip(__tmpf)||'|'||strip(__tmp);
  %* end of if __spaceleft<length(__tmp1) then do;
  end;  

%*end of do __j=1 to countw(__tmpf2, byte(12));
end;

if __startsplit=1 then __tmpf='|'||strip(__tmpf);
&debugc put __tmpf=;

&string = tranwrd(strip(__tmpf), byte(11), byte(160));
%* try 183 also;

%mend;

