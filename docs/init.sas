*-------------------------------------------------------------------------------------------;
* determine the location of the sas program being run ;
*   and define RRG-required macro variables which specify folders where RRG files are;
*   and the folders where output and RRG-generated programs will be placed ;
*-------------------------------------------------------------------------------------------;


%global root rrg_root rrgmacropath;





%let rrgmacropath=C:\rrg_open_comp\cmacros;



%global rrgpgmpath rrgoutpath rrg_configpath __sasshiato_home ;






%let rrgoutpath=C:\rrg_open_test\rrgout;
** rrgoutpath: where output will be saved;


%let rrgpgmpath=C:\rrg_open_test\pgm\generated;


%let rrg_configpath=C:\rrg_open_test\config.ini;


options mprint nomfile ls=200 nocenter nodate nonumber;
options nofmterr;

%let __sasshiato_home=C:\rrg_open_installation\sasshiato;


** make sure sasautos are available;
/*options mautosource sasautos=('[mydir1]',  '[mydir2]',sasautos);*/


libname rrgmacr   "&rrgmacropath" access=readonly ;

options mstored sasmstore=rrgmacr  nodate;

*-------------------------------------------------------------------------------------------;
*** define LIBNAMES ;
*-------------------------------------------------------------------------------------------;

libname adam "Z:\IzaWork\RRG_test\401\adam\data";
libname sdtm "Z:\IzaWork\RRG_test\401\sdtm\data";


*-------------------------------------------------------------------------------------------;
* import titles/footnotes/output file names from central file ;
*-------------------------------------------------------------------------------------------;


libname tfls "Z:\IzaWork\RRG test\401\tfl\doc";


data tfls;
set tfls.t_n_f;
length PGMNAME TFLNUM $ 30 pop atitle1 - atitle3 foot1-foot8 $ 1000;
pgmname = strip(tranwrd(Program_Name,".sas",''));
tflnum=strip(Table__Listing_or_Figure_Number);
pop='';

array titles $ title_1-title_3;
array atitles $ atitle1-atitle3;
array foots $ foot1-foot8;
array footnotes $ footnote1-footnote8;
do over titles;
  atitles=strip(titles);
  if lowcase(atitles)='none' then atitles='';
end;
atitle1=strip(type)||' '||strip(tflnum)||'//'||strip(atitle1);

do over foots;
  
  foots=strip(footnotes);
  if lowcase(foots)='none' then foots='';
  if foots=:'File: x' then foots='';
  foots = tranwrd(strip(foots), byte(163),"/s#le ");
  foots = tranwrd(strip(foots), byte(179),"/s#ge ");
end;

outname= strip(Output_name);
keep PGMNAME TFLNUM  pop atitle1 - atitle3 foot1-foot8 outname type;
run;



*-------------------------------------------------------------------------------------------;
* obtain the date of latest SDTM file and store it in macro variable SDTMDATE;
*-------------------------------------------------------------------------------------------;

%global sdtmdate;

proc contents data=sdtm._all_ out=sdtm noprint;
run;

proc sql noprint;
select max(modate) into: modate separated by  ' ' from sdtm;
quit;

data null;
modate=&modate;
put modate=;
format modate datetime.;

sdtmdate=put(datepart(modate), date9.);

call symput('sdtmdate1',sdtmdate);

run;

%put sdtmdate1=&sdtmdate1;




%let war=WAR;
%let ning=NING;


proc format;
picture pct1d (round default= 10)
.,0=' '
0<-<0.1 = '(<0.1)'  (noedit)
0.1-<99.95= '09.9)' (prefix='(' mult=10)
99.95-<100='(99.9)' (noedit)
100 = '(100)'   (noedit)
;
run;