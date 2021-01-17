/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __savexml(data=, out=,  reptype=)/store;

%local dsid rc varnum1 varnum2 varnumfo firstonly fospan ;
%local data  reptype out  i maxtrt;  
%let varnum1=0;
%let varnum2=0;
%let dsid = %sysfunc(open(&data));
%let varnum1= %sysfunc(varnum(&dsid, __varbygrp));
%let varnum2= %sysfunc(varnum(&dsid, __varbylab));
%let varnumfo= %sysfunc(varnum(&dsid, __gcols));
%let fospan= %sysfunc(varnum(&dsid, __fospan));
%let rc = %sysfunc(close(&dsid));
%if %symexist(rrg_debug)=0 %then %let rrg_debug=0;
%if &rrg_debug>0 %then %do;
  data __timer;
  set __timer end=eof;
	length task $ 100;
	output;
		if eof then do; 
		  task = "SAVE XML STARTED";
		  dt=datetime(); 
		  output;
		end;
run;
%end;
%local numfo i;
%let numfo=0;
 
 %if &varnumfo>0 %then %do;
   proc sql noprint;
    select __gcols into:firstonly separated by ' '
    from &data (where=(__datatype='RINFO' and __gcols ne ''));
   quit; 
   
   %if %length(&firstonly) >0 %then %do;
   %let numfo = %sysfunc(countw(&firstonly, %str( )));
   %do i=1 %to &numfo;
     %local fo&i;
     %let fo&i = %scan(&firstonly,&i, %str( ));
   %end;
   %end;
 %end;
 
 %* fo&i is column id of columns that are to be cleared unless __first_colid =1;



options missing='';
  
data _null_;
  set &data;
  
  if 0 then __col_0='';
  array cols{*} $ 2000 __col_:;
    n = dim(cols)-1;
    call symput("maxtrt", cats(n));
run;
   
 

    
%macro __printvar(var=, name=);
    %local %nrbquote(&var) ;
    %local name %nrbquote(&var);
    %if &name= %then %let name=&var;
    
    &var = tranwrd(trim(&var), '&', '&amp;');
    &var = tranwrd(trim(&var), '<', '&lt;');
    &var = tranwrd(trim(&var), '"', '&quot;');
    &var = tranwrd(trim(&var), '>', '&gt;');
    &var = tranwrd(trim(&var), '–', '-');
    &var = tranwrd(trim(&var), '±', '+/-');
    
    
    put "    <&name.>"  &var  "</&name>";
%mend;

%macro __printvarl(var=, name=);
    %local name %nrbquote(&var) ;
    %if &name= %then %let name=&var;
    &var = tranwrd(trim(left(&var)), '&', '&amp;');
    &var = tranwrd(trim(left(&var)), '<', '&lt;');
    &var = tranwrd(trim(left(&var)), '"', '&quot;');
    &var = tranwrd(trim(left(&var)), '>', '&gt;');
    &var = tranwrd(trim(left(&var)), '–', '-');
    &var = tranwrd(trim(left(&var)), '±', '+/-');
    
    put "    <&name.>"  &var  "</&name>";
 
%mend;

%macro __printvarn(var=, name=);
    %local name %nrbquote(&var) ;
   %if &name= %then %let name=&var;
    
    put "    <&name.>"  &var best. "</&name>";
 
%mend;

%macro __checkic(var);
  %local var ;
     do __i=1 to length(&var);
      __y = substr(&var,__i,1);
       __x=rank(__y);
        if __x < 32 or  __x=96 or __x > 126 then do;
          put 'ER' 'ROR: ' "variable &var contains illegal character not allowed in xml files. ";
          PUT "This may prevent output generation.";
          put "illegal character is " __y " ITS ASCII NUMBER IS " __x &VAR=;
          put __rowid= __varbylab=;
          do __j=1 to dim(cols);
            put cols[__j]=;
          end;  
       end;
     end;  
%mend;  

%local i;

%if &debug>0 %then %do;
data _null_;
    set &data end = eof;
    if 0 then do;
      __varbylab='';
      __tcol='';
         %do i=0 %to &maxtrt;
          __col_&i='';
        %end;
      
    end;
    array cols{*} __col_0 - __col_&maxtrt;
    if __datatype ne 'RINFO' then do;
      
      %do i=0 %to &maxtrt;
        %__checkic(__col_&i);
      %end;
      
      %__checkic(__varbylab);
      %__checkic(__tcol);

    end;
    else do;
     
      %__checkic(__sprops);
      %__checkic(__nodatamsg);
      %__checkic(__title1);
      %__checkic(__title2);
      %__checkic(__title3);
      %__checkic(__title4);
      %__checkic(__title5);
      %__checkic(__title6);
      %do i=1 %to 14;
         %__checkic(__footnot&i);
      %end;
      
      %__checkic(__shead_l);
      %__checkic(__shead_m);
      %__checkic(__shead_r);
      %__checkic(__sfoot_l);
      %__checkic(__sfoot_m);
      %__checkic(__sfoot_r);
      
    end;
run;    

%end;
  
  
  data _null_;
    set &data end = eof;
      drop tmp:;
      if 0 then do;
        __dist2next='';
        __indentsize='';
        __orient='';
        __breakokat='';
        __pgmname='';
      end;
      
    file "&out" Lrecl=32000;
    length __layouttype $ 8;
  
    tmpx=index(upcase(__filename), '$_DATE_$');
    if tmpx>1 then do;
      __filename=substr(__filename,1,tmpx-1)||put(date(), yymmdd10.)||substr(__filename, tmpx+8);
    end;
    if tmpx=1 then do;
      __filename=put(date(), yymmdd10.)||substr(__filename, tmpx+8);
    end;
    
    __align = upcase(__align);
    __stretch = upcase (__stretch);
    if __datatype='TBODY' then do;
        %do i=1 %to &numfo;
           if __first_&&fo&i ne 1 then __col_&&fo&i='';
        %end;
        %if &fospan>0 %then %do;
          if __fospan ne 1 then __tcol='';
        %end;
        %if &varnum1>0 %then %do;
          __varbylab='';
        %end;

    end;
    if _n_=1 then do;
      put "<TABLE>";
    end;  
    put "  <&data.>";
    %do i=0 %to &maxtrt;
      %__printvarl(var=__col_&i);
    %end;  
    %__printvarl(var=__align);
    %__printvarl(var=__dist2next);
    %__printvarl(var=__suffix);
    %__printvarn(var=__indentlev);  **num;
    %__printvarn(var=__next_indentlev); ***num;
    %__printvarn(var=__keepn); ***num;
    %__printvarn(var=__rowid); *** num;
    %__printvarl(var=__cellfonts);
    %__printvarl(var=__cellborders);
    %__printvarl(var=__topborderstyle);
    %__printvarl(var=__bottomborderstyle);
    %__printvarl(var=__label_cont);
    
    
    %if &varnum1>0 %then %do;
    %__printvarn(var=__varbygrp); ***num;
    %end;
    %if &varnum2>0 %then %do;
    %__printvarl(var=__varbylab);
    %end;
    %__printvarl(var=__datatype);
  
    if __tcol ne '' then do;
      %__printvarl(var=__tcol, name=__tcol);
    end;
    if __datatype='RINFO'  then do;
      __colwidths = compbl(__colwidths);
       if countw(__colwidths,' ')=1 then do;
         __colwidths = compbl(__colwidths)||repeat(' NH', &maxtrt-1);
       end;  
       else if countw(__colwidths,' ')<&maxtrt+1 then do;
       colwidths = compbl(__colwidths)||repeat(' '||scan(__colwidths,-1,' '), &maxtrt-countw(__colwidths,' '));
      end;

      %__printvarl(var=__title1_cont);
      if __sprops ne '' then do;
      %__printvarl(var=__sprops);
      end;
      if index(upcase(__outformat),'SRTF')>0 then do;
         __layouttype='INTEXT';
      end;
      else  __layouttype='STD';
      %__printvarl(var=__outformat);
      %__printvarl(var=__layouttype);
      %__printvarl(var=__fontsize);
      %__printvarl(var=__indentsize);
      %__printvarl(var=__orient);
      %__printvarl(var=__breakokat);
      %__printvarl(var=__outformat, name=__dest);
      %__printvarl(var=__filename);
      %__printvarl(var=__pgmname );
      %__printvarl(var=__nodatamsg);
      %__printvarl(var=__title1);
      %__printvarl(var=__title2);
      %__printvarl(var=__title3);
      %__printvarl(var=__title4);
      %__printvarl(var=__title5);
      %__printvarl(var=__title6);
      %do i=1 %to 14;
         %__printvarl(var=__footnot&i);
      %end;
      
      %__printvarl(var=__shead_l);
      %__printvarl(var=__shead_m);
      %__printvarl(var=__shead_r);
      %__printvarl(var=__sfoot_l);
      %__printvarl(var=__sfoot_m);
      %__printvarl(var=__sfoot_r);
      %__printvarl(var=__path );
      %__printvarl(var=__extralines);
      %__printvarl(var= __colwidths);
      %__printvarl(var=__papersize);
      %__printvarl(var=__stretch);
      %__printvarl(var=__font);
      %__printvarl(var=__margins);
      %__printvar(var=__lastcheadid);
      %__printvar(var=__gcols);
      %__printvar(var=__sfoot_fs); 
      %__printvar(var=__watermark); 
      if __bookmarks_pdf ne '' then do;
        %__printvar(var=__bookmarks_pdf); 
      end;  
      if __bookmarks_rtf ne '' then do;
        %__printvar(var=__bookmarks_rtf); 
      end;
    end;
    put "  </&data.>";
    if eof then do;
      put "</TABLE>";
    end;  
  run;
  
  %if &rrg_debug>0 %then %do;
  data __timer;
  set __timer end=eof;
	length task $ 100;
	output;
		if eof then do; 
		  task = "SAVE XML FINISHED";
		  dt=datetime(); 
		  output;
		end;
run;
%end;

%mend;
