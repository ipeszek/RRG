/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __sasshiato(
dataset=,
path=,
debug=0,
reptype=
)/store;

  
%local dataset path debug __shs __sh __outpathc __tmpfilepath __xmlpath
      __runc __security_token __xmlfile __dirdel reptype;
%local __workdir;

%if %length(&dataset)=0 %then %let dataset=&rrguri;

%local watermark;

proc optsave out=__sasoptions0;

proc sql noprint;
  select __watermark into:watermark separated by ' '
  from &dataset(where=(__datatype='RINFO'));
quit;



%if %length(&path)>0 %then %let path = %sysfunc(tranwrd(&path, %str(\), %str(/)));

%let __xmlfile=&dataset;

%let __workdir = %sysfunc(getoption(work));
%*let __workdir = &rrgoutpath;

%if %index(&__workdir, %str(\))>0 %then %let __dirdel=%str(\);
%else %let __dirdel=%str(/);


%let __tmpfilepath = &__workdir.&__dirdel.&__xmlfile;
%let __tmpfilepath2 = /sasdata/Data/Development/BDM/ToolsDev/Macros/RRG_v4/tmp/&__xmlfile;
%put  __tmpfilepath=&__tmpfilepath ;
%put __tmpfilepath2=&__tmpfilepath2;
/*  */
/* %if %length(&path)>0 %then */
/*     %let  __xmlpath = &path.%str(/)&__xmlfile; */
/* %else */
	%let __xmlpath = &__tmpfilepath;



%if %length(&rrgoutpath)>0 %then 
	%let __outpath_c = %str(-Dout_dir=)"&rrgoutpath.";
%else
    %let __outpath_c=; 


%put RRG INFO: THE XML FILE IS TO BE SAVED IN &__xmlpath..xml;


%__savexml(
data=&dataset, 
out=&__xmlpath..xml ,
reptype=&reptype
);


%if %length(&path) %then %do;
	
	filename rrgfin "&__xmlpath..xml" recfm=n;
	filename rrgfout "&path.%str(/)&__xmlfile..xml" recfm=n;
	%local rc;
	%if %sysfunc(fexist(rrgfin)) %then %do;
		%let rc = %sysfunc(FCOPY(rrgfin,rrgfout));
   	%put %sysfunc(SYSMSG());
   	%put File &__xmlpath..xml was copied to &path.%str(/)&__xmlfile..xml;
	%end;
	%else %do;
		%put File &__xmlpath..xml was not found and was not copied;
	%end;
%end;

%*let __security_token = ad6128a9623ca1c222cd7cc176334d15;
%local sc;
%let sc = white pelikan;

data _null_;
length tmp $ 200;
tmp = cats(symget('sc'))||put(today(), yymmdd10.);
tmp2 = md5(trim(tmp));
tmp3 = put(tmp2,hex32.);
call symput('__security_token', tmp3);
run;


data _null_;
 length tmp $ 1000;
 file "&__workdir.&__dirdel.sasshiato.props" lrecl=1000;
 tmp = "xml_in_file=&__xmlpath..xml";
 tmp = tranwrd(tmp, "\", "/");
 put tmp;
 
 %if %length(&rrgoutpath)>0 %then %do;
   tmp ="out_dir=&rrgoutpath.";
   tmp = tranwrd(tmp, "\", "/");
   put tmp;
   *tmp ="work_dir=&__workdir.";
   *tmp ="work_dir=&rrgoutpath.";
   *tmp = tranwrd(tmp, "\", "/");
   *put tmp;
 %end;

 put "log2=file";
* tmp="log2f=&__tmpfilepath2..str";
 tmp="log2f=&__tmpfilepath..str";
 tmp = tranwrd(tmp, "\", "/");
 put tmp;
 put "log2lev=&debug";
 tmp = cats(symget("__security_token")); 
 put "sec=" tmp;
 %if %length(&watermark)>0 %then %do;
 tmp = cats('watermark_file=', "&watermark");
 tmp = tranwrd(tmp, "\", "/");
 %end;
 %else %do; 
 tmp = "watermark_file=none";
 %end;
 put tmp;

run; 

*** PROPS FILE;
data _null_;
	infile "&__workdir.&__dirdel.sasshiato.props" length=len lrecl=2000; 
   input record $varying2000. len; 
   put record $varying2000. len; 
run;

*** END OF PROPS FILE;




 
data _null_;
  if fileexist("&__workdir.&__dirdel.sasshiato.props") then put 
  'RRG INFO:  the props file was created successfully.';
  else put 'WAR' 'NING:  the props file could not be created.';
run; 
   
%* delete log if exists;


data _null_;
  fname="tempfile";
    ** log file;
    *rc=filename(fname,"&__tmpfilepath2..str");
    rc=filename(fname,"&__tmpfilepath..str");
    if rc = 0 and fexist(fname) then
    rc=fdelete(fname);
    rc=filename(fname);
run;

%put INFO ABOUT OS: sysscp=&sysscp;

%if  &SYSSCP ne WIN %then %do;
  
  data _null_;
  length tmp $ 2000;
  /*tmp = "sh &__sasshiato_home./sasshiato.sh "||quote("&__workdir.&__dirdel.sasshiato.props")||
 ' > /sasdata/Data/Development/BDM/ToolsDev/Macros/RRG_v4/tmp/logme.log 2>&1';
 put 'COMMAND IS ' tmp;*/
 tmp = "sh &__sasshiato_home./sasshiato.sh "||quote("&__workdir.&__dirdel.sasshiato.props");
  tmp = tranwrd(tmp,'\','/');
  call system(tmp);
  run;  
  
%end;

%else %do;

  options noxwait;

  data _null_;
  length tmp $ 2000;
  tmp = "&__sasshiato_home./sasshiato.bat "||quote("&__workdir.&__dirdel.sasshiato.props");
  tmp = tranwrd(tmp,'/','\');
  
  put tmp=;
  
 if not fileexist("&__workdir") then put
 'WAR' "NING: THE FOLDER &__workdir CAN NOT BE FOUND";
 ELSE PUT "RRG INFO: FOLDER &__workdir was found.";
  
  call system(tmp);
  run;
  

%end;


%put BRGIN SASSHIATO INVOCATION LOG;
%put - - - - - - - - - - - - - - - - ;
data _null_; 
   *infile "&__tmpfilepath2..str" length=len lrecl=2000; 
   infile "&__tmpfilepath..str" length=len lrecl=2000; 
   input record $varying2000. len; 
   put record $varying2000. len; 
   *if _n_=15 then stop; 
run;
%put - - - - - - - - - - - - - - - - ;
%put END OF SASSHIATO INVOCATION LOG;




%if &debug < 50 %then %do;
%put file cleanup;

data _null_;
  fname="tempfile";
    ** log file;
    *rc=filename(fname,"&__tmpfilepath2..str");
    rc=filename(fname,"&__tmpfilepath..str");
    if rc = 0 and fexist(fname) then
    	rc=fdelete(fname);
    rc=filename(fname);
    ** XML file;
    rc=filename(fname,"&__tmpfilepath..xml");
    if rc = 0 and fexist(fname) then
    	rc=fdelete(fname);
    rc=filename(fname);
run;
%end;



proc optload 
   data=__sasoptions0(where=(
    lowcase(optname) in 
    ( 'mprint',
      'notes',
      'mlogic', 
      'symbolgen', 
      'macrogen',
      'mfile', 
      'source', 
      'source2', 
      'byline',
      'orientation',
      'date', 
      'number', 
      'center', 
      'byline',
      'missing')));
run;


%mend;


