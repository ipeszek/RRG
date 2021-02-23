*-------------------------------------------------------------------------------------------;
* determine the location of the sas program being run ;
*   and define RRG-required macro variables which specify folders where RRG files are;
*   and the folders where output and RRG-generated programs will be placed ;
*-------------------------------------------------------------------------------------------;


%global rrgmacropath rrgpgmpath rrgoutpath rrg_configpath __sasshiato_home;


%*let rrg_configpath=K:\Sponsors\zzTest\rrg\iq_test_pgm\config.ini; 
*** rrg_configpath: where config file is stored;
*** note: configuration file is project-specific, and is optional;


%let rrgmacropath=C:\rrg_open_comp\cmacrosnew;  
*** location of compiled rrg macro catalog;

%let __sasshiato_home=C:\java_progs\sasshiato; 
*** __sasshiato_home: where sasshiato is stored;

%let rrgpgmpath=C:\tmp\generated_programs; 
*** rrgpgmpath: where generated rrg programs are saved;

%let rrgoutpath=C:\tmp\output; 
*** rrgoutpath: where outputs are saved;


** make sure sasautos are available;
/*options mautosource sasautos=('[mydir1]',  '[mydir2]',sasautos);*/


libname rrgmacr   "&rrgmacropath" access=readonly ;
options mstored sasmstore=rrgmacr  nodate;
