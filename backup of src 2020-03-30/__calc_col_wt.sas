/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __calc_col_wt/store;

%* note: for now, colsize (if in units) shoudl be number of chars if java2sas is used;


%* calculate column widths;

%* macro variables needed;
%* lasthrid =  last rowid for header;
%* colwidths, stretch, numcol, dist2next, indentsize;

data __fcw;
  infile "&rrgoutpath./&fname._j_info.txt" length=len lrecl=5000;
  length record $ 5000  ;
  input record $varying2000. len;
  colw=input( scan(record,2,','), best.);
  num = input(substr(scan(record,1,','),2), best.);
run;

proc transpose data=__fcw out=__fcw2 prefix=__wd_;
  var colw;
  id num;
run;


data &rrguri.fcw;
  set &rrguri;
  if __datatype = 'TBODY' or (__datatype='HEAD' and __rowid = &lasthrid);
  array cols __col_0-__col_&numcol;
  array al $ 20 __al_0-__al_&numcol;
  length __colwidths __tmp __tmp0   $ 2000;
  __colwidths = trim(left(symget("colwidths")));
  
  %* fulltext;
  array maxft __mft_0-__mft_&numcol;
  %* longest word;
  array maxlw __mlw_0-__mlw_&numcol;
  
    
    __align = upcase(compbl(__align)); 
    do __i=1 to dim(cols);
      al[__i]=scan(__align,__i,' ');
      
      __tmp = tranwrd(trim(left(cols[__i])),'//', byte(12));
      maxft[__i]=0;
      maxlw[__i]=0;
      __indpad=0;
      do __j = 1 to countw(__tmp, byte(12));
        __tmp0 = trim(left(scan(__tmp, __j, byte(12))));
        if index(__tmp0, '/t')=1 then do;
          __indpad = __indpad+input(substr(__tmp0, 3,1), best.);
          __tmp0 = substr(__tmp0, 4);  
        end;
        __tmp1 = length(__tmp0)+&indentsize*__indpad;
        maxft[__i] = max(maxft[__i], __tmp1);
        do __k= 1 to countw(__tmp0,' ');
          __tmp1 = length(scan(__tmp0,__k,' '))+&indentsize*__indpad;
          maxlw[__i] = max(maxlw[__i], __tmp1);
        end;     
      end;
      

      %* do not include header unless requested;
      if scan(__colwidths, __i,' ') not in ('LWH', 'NH') and  __datatype='HEAD' then do;
          maxft[__i]=0;
          maxlw[__i]=0;
      end;
    end;
  
run;

/*
&debugc proc print data=&rrguri.fcw ;
&debugc   var __col_: __align __mft: __mlw:;
&debugc run;
*/

proc means data=&rrguri.fcw  noprint;
  var __mft_0-__mft_&numcol 
      __mlw_0-__mlw_&numcol;
  output out=__maxes max =  
      __mft_0-__mft_&numcol 
      __mlw_0-__mlw_&numcol;
run;     



%local nofit;

data __maxes;
  set __maxes;
  if _n_=1 then set __fcw2;
  length __colwidths __stretch  __dist2next  __cl $ 2000;
  __colwidths = trim(left(symget("colwidths")));
  __stretch = trim(left(symget("stretch")));
  __dist2next = trim(left(symget("dist2next")));
  
  %* fulltext;
  array maxft __mft_0-__mft_&numcol;
  %* longest word;
  array maxlw __mlw_0-__mlw_&numcol;  

  array wd __wd_0-__wd_&numcol;
  array st $ 200 __st_0-__st_&numcol;
  array space __space_0-__space_&numcol;
  array wrap $ 200 __wrap_0-__wrap_&numcol;
  
  __fixed=0;
  __stretchable=0;
  __stretchable2=0;
  __used=0;
  __spacings=0;

  do __i=1 to dim(maxft);
    if maxft[__i]=. then maxft[__i]=0;
    if maxlw[__i]=. then maxlw[__i]=0;
    
    wrap[__i]=scan(__colwidths, __i, ' ');
    st[__i]=scan(__stretch, __i, ' ');

    if st[__i]='' then st[__i]='Y';
    space[__i]=scan(__dist2next, __i, ' ');
    
    if wrap[__i] not in ('N','NH','LW','LWH') then do;
      wd[__i] =  input(wrap[__i], best.);
    end;
    if wd[__i]=0 then wd[__i]=1;
    
    
    __used = __used + wd[__i];
    &debugc put wd[__i]=;
    if st[__i]='N' then __fixed = __fixed+wd[__i];
    else if 0<wd[__i]<maxft[__i] then __stretchable=__stretchable+(maxft[__i]/wd[__i]);
	__stretchable2 =__stretchable2+(maxft[__i]/wd[__i]);
    if __i<dim(maxft) then __spacings = __spacings+space[__i];
  end;
  __err=0;
  if __used>&ls - __spacings then do;
    __err='1';
    put 'ER' 'ROR: The table can not be fit with these widths';
    %do i=0 %to &numcol;
      put __wd_&i=;
    %end;    
  end;
  else do;
    diff=&ls-__used - __spacings;
    __used=0;
	
	
   
    %* first stretch "stretchables" that currently wrap to min needed to not wrap;
    do __i=1 to dim(maxft);
      if st[__i]='Y' and wd[__i]<maxft[__i] then do;
        wd[__i]=wd[__i]+floor(diff*maxft[__i]/(wd[__i]*__stretchable));
		    wd[__i]=min(wd[__i],maxft[__i]);
	  end;
    __used = __used+ wd[__i];
	end;

    diff=&ls-__used - __spacings;
	__used=0;

	%* if anything is left then stretch stretchables proportionally;
    do __i=1 to dim(maxft);
      if st[__i]='Y' then do;
         wd[__i]=wd[__i]+floor(diff*maxft[__i]/(wd[__i]*__stretchable2));
	  end;
    __used = __used+ wd[__i];
	end;

    diff = &ls-__used - __spacings; 
	

   if __stretchable>0 then do;
      do while(diff>0);
        do __i=1 to dim(maxft);
          if st[__i]='Y' then do;
            wd[__i]=wd[__i]+(diff>0);
            diff=diff-1;
          end;
        end;  
      end;
    end;
	else do;
     do while(diff>0);
        do __i=1 to dim(maxft);
            wd[__i]=wd[__i]+(diff>0);
            diff=diff-1;
        end;  
      end;
	end;
  end;
 __used=0;
 do __i=1 to dim(maxft);
   __used = __used+ wd[__i];
   *put wd[__i]=;
 end;
 __used = __used+__spacings;
  *put __used=;

  call symput("nofit", __err);
  __cl ='';
  if __err =0 then do;
  do __i=1 to dim(maxft);
    __cl = trim(left(__cl))||' '||trim(left(put(wd[__i], best.)));
  end;
  end;
run;



%if &nofit=1 %then %do;
%put The table cannot fit with the requested widths;
%end;


%mend;
