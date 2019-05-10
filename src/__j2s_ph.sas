/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __j2s_ph(ispage=, numcol=, fname=, cl=, ls=, ps=, type=)/store;
  
%* this macro processes headers, creating splits as needed;
%* and creates a dataset with the text for "columns" statement;
%* dependencies: clab&i cw&i __sp&i;


%* cl = column widths calculated by __calc_col_w;


%local ispage i numcol fname colstr clearh cntcs cl type;

%put;
%put *************************************************************************;
%put STARTNG EXECUTION OF __J2S_PH;
%put ispage=&ispage ;
%put numcol=&numcol ;
%put fname=&fname ;
%put cl=&cl;
%put;


data __colstr;

infile "&rrgoutpath./&fname._j_info2.txt" length=len lrecl=5000;  
length record $ 5000;
input record $varying2000. len;
run;

data __colstr;
set __colstr;
if _N_=1 then call symput("colstr", strip(record));
else call symput("clearh", strip(record));
run;

%* note: clearh is a SAS statement that clears labels for botomless headers if they are spanned; 



%if &ispage=1 %then %do;
  %local mvb;
  proc sql noprint;
  select max(__varbygrp) into:mvb separated by ' ' from __headers;
  quit;
   
  proc sort data=__headers (where=(__varbygrp=&mvb));
  by __varbygrp __rowid;
  run;
%end;
%else %do;
 
  proc sort data=__headers;
  by __rowid;
  run;
%end;
 
%do i=0 %to &numcol;
%local clab&i  cw&i;
%end;
 
 
data __headers;
  set __headers;
  __rowid=_n_;
  __len = strip(symget('cl'));
  array cols{*} __col_0 -__col_&numcol;
  array len{*} __len_0 -__len_&numcol;  
      

  do __ii=1 to  dim(cols);
    len[__ii]=input(scan(__len, __ii, ' '), best.);
    
  end;
  
  do __ii=1 to  dim(cols);
    __totlen=0;
  	__jj=__ii;
  	__oktogo=1;
    do while (__oktogo=1 and cols[__jj]=cols[__ii]);
      __totlen=__totlen+len[__jj];
		  __start=__ii;
		  __stop=__jj;
	    __jj=__jj+1;
  		if __jj>dim(cols) then do;
        __oktogo=0;
  		  __jj=dim(cols);
  		end;
	  end;
	  put;
    /*cols[__ii]=tranwrd(trim(cols[__ii]),' ', byte(20));*/
    %__rrg_splitstr(string=cols[__ii], len=__totlen, indentsize=&indentsize);
    /*cols[__ii]=tranwrd(trim(cols[__ii]),byte(20), ' ');*/

    do __k=__ii+1 to __stop;
  	  cols[__k]=cols[__ii];
  	end;
  	
    __ii=__stop;
    
  end;
  
  run;



 
data __headers;
length clab cw $ 20 /*start stop refcol htmp1 htmp2 htmp3 $ 2000*/;
set __headers end=eof;
 
array cols{*} __col_0 -__col_&numcol;
 
length colstr  __tmp __tmp2 $ 2000;
retain colstr;
__len = strip(symget('cl'));
 
if _n_=1 then do;
  colstr = strip(symget('colstr'));
end;
&debugc put;
&debugc put colstr=; 
do __i=1 to countw(colstr,'"() ');
  __tmp = scan(colstr, __i, '"() ');
  &debugc put __i= __tmp=;
  __ind =index(__tmp,'__c');
  if __ind>1 then do;
    __rid = input(substr(__tmp,1,__ind-1), best.);
    if __rid=__rowid then do;
      __ind2 = input(scan(substr(__tmp, __ind+6),1,'_| '), best.);
      __tmp2 = strip(cols[__ind2+1]);
      __tmp2 = tranwrd(__tmp2,'(', byte(13)); 
      __tmp2 = tranwrd(__tmp2,')', byte(14));
      __tmp2 = tranwrd(strip(__tmp2),' ', byte(15));
      __tmp2 = strip(tranwrd(__tmp2,'"', byte(12)))||"|__";
      colstr = tranwrd(colstr,strip(__tmp), strip(__tmp2));
      &debugc put colstr=;
    end;
  end;
end;   
if eof then do;
  colstr = tranwrd(colstr,byte(12), '"');
  colstr = tranwrd(colstr,byte(14), ')');
  colstr = tranwrd(colstr,byte(13), '(');
  colstr = tranwrd(colstr,byte(15), ' ');
end; 
%*put "done here";

/* 
tmpcnt=0;

do while(index(colstr,'"')>0 );
  tmpcnt=tmpcnt+1;
  htmp1 = scan(colstr, 2, '"');
__tmphh = index(htmp1,'__col_');
__tmph2 = substr(htmp1, 1, index(htmp1,'__col_')-1);


  rid = input(substr(htmp1, 1, index(htmp1,'__col_')-1), best.);
  put colstr=;
  put htmp1= __tmphh= __tmph2= rid= __rowid=;
  %*put;
  %*put colstr= htmp1= __rowid= rid=;
   
  if __rowid=rid then do;
   
    %* determine which columns are spanned;
    quotind = index(colstr, '"');
    htmp2 = substr(colstr, quotind+1);
    put  htmp2=;
    htmp2 = scan(htmp2,2,'")');
    put  htmp2=;
     
    totlen=0;
    start = scan(htmp2,1,' ');
    stop = scan(htmp2,-1,' ');
     
    start = scan(start,-1,'_');
    stop = scan(stop,-1,'_');
     
    put start= stop=;  
    do while (substr(start,1,1)='0');
      start = substr(start,2);
    end;
    do while (substr(stop,1,1)='0');
      stop = substr(stop,2);
    end;
    put start= stop=; 
     
    start_=input(start, best.)+1;
    stop_=input(stop, best.)+1;
     
    %*put quotind= htmp2= start_= stop_=;
     
    do ii=start_ to stop_;
      totlen = totlen + input(scan(__len, ii, ' '), best.);
    end;
    totlen = totlen-2;
    if index(htmp1,'|')<=0 then refcol = scan(htmp1,-1,'_');
    else refcol = scan(scan(htmp1,1,'|'),-1,'_');
    put refcol=; 
    if substr(refcol,1,1)='0' then do;
      do while (substr(refcol,1,1)='0');
        refcol = substr(refcol,2);
      end;
    end;
    refcol_ = input(refcol, best.);
    put refcol_= cols[refcol_+1]= totlen=;
     
    %__rrg_splitstr(string=cols[refcol_+1], len=totlen);
    %*put "passed splitstr";
    if index(htmp1,'|')>0 then
    htmp3 = byte(10)||strip(dequote(cols[refcol_+1]))||"|__"||byte(10);
    else htmp3 = byte(10)||strip(dequote(cols[refcol_+1]))||byte(10);
    colstr = tranwrd(strip(colstr), cats('"',htmp1,'"'), strip(htmp3));
    %*put colstr&i=;
    %* this puts the correct spanned text;
  
  end;
  
  else do;
    
    htmp3 = byte(183)||strip(strip(htmp1))||byte(183);
    colstr = tranwrd(strip(colstr), cats('"',htmp1,'"'), strip(htmp3));
  end;

end;
*/

*colstr = tranwrd(strip(colstr), byte(183), '"');
&debugc put colstr=;
&debugc put;
 
if eof then do;
 
  __hl = 0;
   
  &clearh;
   
  do __cc = 1 to dim(cols);
    __ll = input(scan(__len, __cc, ' '), best.);
    %*__rrg_splitstr(string=cols[__cc], len=__ll);
    clab = 'clab'||strip(put(__cc-1, best.));
    cw = 'cw'||strip(put(__cc-1, best.));
    call symput(clab, strip(cols[__cc]));

    call symput(cw, strip(put(__ll, best.)));
    __hl = max(__hl, countw(cols[__cc], '|'));
  end;
  call symput('hl', strip(put(__hl, best.)));
  *colstr = tranwrd(colstr,byte(10),'"');
  call symput("colstr", strip(colstr));
  
end;
  
keep __col_:;
run;
 
/*
%do i=0 %to &numcol;
%put clab&i=&&clab&i;
%end;
 
%put colstr=&colstr;

*/
%*put 4iza;
%*do i=0 %to &numcol;
%*put cw&i=&&cw&i;
%*end;
 
 
%* split colstr if it is too long;
 
data __colstr;
length tmp1 tmp2 colstr $ 2000;
cntcs=0;
colstr=strip(symget("colstr"));
if substr(colstr,1,1)='"' then mod1=1;
else mod1=0;
 
do i = 1 to countw(colstr, '"');
  tmp2=scan(colstr,i,'"');
  if mod(i,2)=mod1 then do;
    tmp1 = '"'||strip(tmp2)||'"';
    cntcs+1;
    output;
  end;
  else do;
    tmp1='';
    do j=1 to countw(tmp2,' ');
      if length(tmp1)+length(scan(tmp2,j,' '))<100 then do;
        tmp1=strip(tmp1)||' '||scan(tmp2,j,' ');
      end;
      else do;
        cntcs+1;
        output;
        tmp1=scan(tmp2,j,' ');
      end;
    end;
    if tmp1 ne '' then do;
      cntcs+1;
      output;
    end;
  end;
end;

call symput("cntcs", strip(input(cntcs,best.)));
run;
 
%do i=1 %to &cntcs;
%local colstr&i;
%end;
 
data __colstr;
set __colstr;
call symput(cats("colstr", put(_n_,best.)), strip(tmp1));
run;
 
%do i=1 %to &cntcs;
%put colstr&i=&&colstr&i;
%end;
 
%*-------------------------------------------------------------------; 
%**** run fake proc report to determine number of lines for header;
%*-------------------------------------------------------------------;

data __fake;
length __col_0 -__col_&numcol $ 200;
%do i=0 %to &numcol;
  __col_&i=byte(17);
%end;
run;

%do i=0 %to  &numcol;

%local sp&i nal&i;

%end;

data __colinfo;
  set __colinfo;
  length clab $ 2000;
  call symput('sp'||strip(put(colnum, best.)), strip(put(sp,best.)));
  call symput('nal'||strip(put(colnum, best.)), strip(nal));
  cw = symget('cw'||strip(put(colnum, best.)));
  clab = trim(left(symget('clab'||strip(put(colnum, best.)))));
run;
 
proc printto print = "&rrgoutpath./&fname..dummy" new;
options ls=&ls ps = &ps notes nomprint nocenter nodate nonumber;

title;
footnote;

proc report data=__fake headline formchar(2)='_' headskip missing split='|' nowd spacing=0;

columns  %do i=1 %to &cntcs; &&colstr&i %end;;
%if %length(&clab0) %then %do;
define __col_0 /width=&cw0 "&&clab0"  left flow;
%end;
%else %do;
define __col_0 /width=&cw0 ' ' left flow ;
%end;

%do i=1 %to &numcol;
%if %length(&&clab&i) %then %do;
define __col_&i /width=&&cw&i "&&clab&i"  left flow spacing=&&sp&i;
%end;
%else %do;
define __col_&i /width=&&cw&i ' ' left flow spacing=&&sp&i;
%end;
%end;
run;
quit;
 
proc printto print=print;
run;
 
data __fake;
infile "&rrgoutpath./&fname..dummy" lrecl=5000 length=len;
input record  $varying2000. len;
if index(record, byte(17))>0 then call symput('hl', strip(put(_n_, best.)));
run;
 
data __lpp;
  set __lpp;
  hl = &hl;
run;
 
 
%put; 
%put FINISHED EXECUTION OF __J2S_PH; 
%put *************************************************************************;

%mend;
