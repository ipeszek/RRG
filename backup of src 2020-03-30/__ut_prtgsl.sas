/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __UT_prtgsl(varin=, lenvar=len, fs=10, alignvar=)/store;

%*----------------------------------------------------------------------------
 REPONSIBILITY: determines the width in twips of the text variable           
                based on specified font size and alignment                                 
                assumes that AFM (font metrics data) is read in data step     
                prior to calling the macro                                    

 AUTHOR:        Iza Peszek, 10NOV2007                                                                              
                                                                              
 MACRO PARAMETERS:                                                            
                   &varin:   name of character variable                       
                   &lenvar:  name of variable to store width of varin         
                   &fs:      font size                                        
                   &alignvar:variabe holding alignment
                                                                              
 WARNING: creates several variables inside data set:                          
             __indp __tmpa  z k  &lenvar._(1-7)         
            __wor0 __wod1 __word1a __word1b __word2 __word2a __word2b
                                                                              
 ASSUMPTIONS: assumes that an array __afm (with font metrics data for         
              each ascii character from 31 to 255) has been created inside    
              data step prior to calling the macro                            
------------------------------------------------------------------------------;

%local varin lenvar fs alignvar;

length __word1  __word2 __word1a __word1b __word2a __word2b 
        __word0 __tmpwrd $ 2000;

&lenvar._1=0;  %** length before tab;
&lenvar._2=0;  %** length after tab;
&lenvar._6=0; %** before tab before period;
&lenvar._7=0; %** before tab after period;
&lenvar._5=0;  %** total length;
&lenvar._3=0;  %** length after tab and before period;
&lenvar._4=0;  %** length after tab and after period;


__word1="";
__word2="";

&varin=left(trim(&varin));
__word0 = tranwrd(&varin, '{\super',''); 
__word0 = tranwrd(__word0, '~{super','');
__word0 = tranwrd(__word0, '0%','0.%');
if __word0='0' then __word0='0.';


__word1 = scan(__word0, 1, ' ');
__indp = index(__word0, ' ');
__word2='';
if __indp>0 and __indp<length(__word0) then __word2 = substr(__word0, __indp+1);
%*__word2 = scan(__word0, 2, ' ');
__word1a = scan(__word1, 1, '.');
__word1b = scan(__word1, 2, '.');
__word2a = scan(__word2, 1, '.');
__word2b = scan(__word2, 2, '.');

if &alignvar in ('L', 'R', 'C') then do;
   %*put "here1" __word0;
   &lenvar._9 = 0;
   &lenvar._5 = 0;
   __indp=index(__word0, '~-2n'); 
   if __indp=1 then do;
      __word0 = substr(__word0, 5);
      __indp=index(__word0, '~-2n'); ;
   end;
   if __indp=0 then do;
      %*put "here2" ;
      do z=1 to length(__word0);
            k = rank(substr(__word0,z,1));
            __tmpl = __afm[k]; 
            if __tmpl=. then __tmpl=__afm[35];
           &lenvar._5=&lenvar._5+ __tmpl;
      end;
   end;

   else do;
     %*put "here3 __word0= " __word0 __indp= &lenvar._5=;
     do while (__indp>0);
         &lenvar._9=0;
         if __indp>1 then __word1 = substr(__word0, 1, __indp-1);
         else __word1='';
         %*put "__word1=" __word1;
         do z=1 to length(__word1);
               k = rank(substr(__word1,z,1));
               __tmpl = __afm[k]; 
               if __tmpl=. then __tmpl=__afm[35];
              &lenvar._9=&lenvar._9+ __tmpl;
         end;
         %*put &lenvar._9=;
         &lenvar._5 = max(&lenvar._9, &lenvar._5);
         %*put &lenvar._5=;
         __word0 = substr(__word0, __indp+4);
         __indp=index(__word0, '~-2n');
         %*put "__word0=" __word0;
     end;
   end;   
   %*put &lenvar._5=;
end;
else do;
   if __word0 ne '' then do;
      do z=1 to length(__word1);
            k = rank(substr(__word1,z,1));
              __tmpl = __afm[k]; 
              if __tmpl=. then __tmpl=__afm[35];
            &lenvar._1=&lenvar._1+ __tmpl;
      end;
      do z=1 to length(__word1a);
               k = rank(substr(__word1a,z,1));
                 __tmpl = __afm[k]; 
                 if __tmpl=. then __tmpl=__afm[35];
               &lenvar._6=&lenvar._6+ __tmpl;
      end;
      &lenvar._7 = &lenvar._1-&lenvar._6;
      if __word2 ne '' then do; 
         do z=1 to length(__word2);
               k = rank(substr(__word2,z,1));
                 __tmpl = __afm[k]; 
                 if __tmpl=. then __tmpl=__afm[35];
               &lenvar._2=&lenvar._2+ __tmpl;
         end;
         &lenvar._2=&lenvar._2+ __afm[35];
         do z=1 to length(__word2a);
               k = rank(substr(__word2a,z,1));
                 __tmpl = __afm[k]; 
                 if __tmpl=. then __tmpl=__afm[35];
               &lenvar._3=&lenvar._3+ __tmpl;
         end;
         %* add space;
         &lenvar._3=&lenvar._3+ __afm[35];
         &lenvar._4 = &lenvar._2-&lenvar._3;
      end;   
      &lenvar._5 = &lenvar._1+&lenvar._2; 
      %* this is total length needed;
   end;
end;  
if &alignvar='D' then do;
  &lenvar._3=0;
  &lenvar._4=0;
end;

&lenvar._1=ceil(&fs*20*&lenvar._1/1000);
&lenvar._2=ceil(&fs*20*&lenvar._2/1000);
&lenvar._3=ceil(&fs*20*&lenvar._3/1000);
&lenvar._4=ceil(&fs*20*&lenvar._4/1000);
&lenvar._5=ceil(&fs*20*&lenvar._5/1000);
&lenvar._6=ceil(&fs*20*&lenvar._6/1000);
&lenvar._7=ceil(&fs*20*&lenvar._7/1000);

%* &lenvar8 = width needed to avoid words breaking in the middle;

__ind=1;
&lenvar._8=0;
__tmpl=0;
__wrdcnt=0;
do __i=1 to length(__word0);
  __tmpwrd = scan(__word0, __i, " ");
  __tmp2=0;
  if __tmpwrd ne " " then do;
      do z=1 to length(__tmpwrd);
            k = rank(substr(__tmpwrd,z,1));
                 __tmpl = __afm[k]; 
                 if __tmpl=. then __tmpl=__afm[35];
               __tmp2=__tmp2+ __tmpl;
      end;
      if __tmp2>&lenvar._8 then &lenvar._8=__tmp2;
   end;   
   *put "tmpwrd=" __tmpwrd "__tmp2=" __tmp2 12.;
end;
&lenvar._8=ceil(&fs*20*&lenvar._8/1000);

%mend;
