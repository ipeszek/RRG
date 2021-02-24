*----------------------------------------;
**** Edit the following 2 lines;
*----------------------------------------;


%let catpath = %str(C:\rrg_open_comp\cmacrosnew);   *** location of catalog to be created;
%let path2src=%str(C:\rrg_github\RRG\src);          *** location of downloaded SAS macros;

**** DO NOT EDIT BELOW THIS LINE ;

*---------------------------------------------------;

libname cdarmacr   "&catpath" ;
options mstored sasmstore=cdarmacr  nodate;

%macro incmac;


filename fin "&path2src";


%local dirid rc numfiles i fname;
%let dirid = %sysfunc(dopen(fin));
%let numfiles=%sysfunc(dnum(&dirid));

%if &numfiles<=0 %then %do;
  %put 'no source files found';
%end;
%else %do;
  %put found &numfiles files;
%end;


%do i=1 %to &numfiles;
	%let fname = %upcase(%sysfunc(dread(&dirid, &i)));
	%let rname = %upcase(%sysfunc(reverse(&fname)));
	%if %substr(&rname,1,4)=%str(SAS.) %then %do;
  %put compiling &fname;
	%inc "&path2src.\&fname";
	%end;
%end;

%let rc=%sysfunc(dclose(&dirid));

%put;
%put FINISHED;

%mend;

%incmac;

