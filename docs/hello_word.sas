/*******************************************************************
*  RRG sample program
*  Program name     : hello_world.sas
*  Project          : RRG Installation Qualification
*  Written by       : Iza Peszek
*  Date of creation : 2021-02-11
*  Description      : Test Listing program
*  Macros called    : RRG macros
*  Input file       : n/a
*  Output file      : hello_world.pdf/rtf
*  Revision History :
*  Date      Author      Description of the change
*******************************************************************/
%global rrgmacropath rrgpgmpath rrgoutpath rrg_configpath __sasshiato_home;


%*let rrg_configpath=K:\Sponsors\zzTest\rrg\iq_test_pgm\config.ini; 
*** rrg_configpath: where config file is stored;
*** note: configuration file is project-specific, and is optional;


**** -------------------------------------------------------------;
**** PLEASE EDIT ACCORDING TO WHERE THE FOLDERS BELOW ARE LOCATED ;
**** -------------------------------------------------------------;

%let rrgmacropath=C:\rrg_open_comp\cmacrosnew;  
*** location of compiled rrg macro catalog;

%let __sasshiato_home=C:\java_progs\sasshiato; 
*** __sasshiato_home: where sasshiato is stored;

%let rrgpgmpath=C:\tmp\generated_programs; 
*** rrgpgmpath: where generated rrg programs are saved;

%let rrgoutpath=C:\tmp\output; 
*** rrgoutpath: where outputs are saved;

**** -------------------------------------------------------------;
*** DO NOT EDIT BELOW THIS LINE ;
**** -------------------------------------------------------------;

libname rrgmacr   "&rrgmacropath" access=readonly ;
options mstored sasmstore=rrgmacr  nodate; 

%rrg_initlist(uri=hello_world, outname=hello world);

%rrg_codebefore(

data indata;
id=1;
idc='';
text='Hello, {/bf World! /bf}';
run;

);

%rrg_deflist(
dataset=indata,
orderby=id,
title1=Hello World Test Program
);

%rrg_defcol(name=id, decode=idc, label='  ');
%rrg_defcol(name=text, label='  ');

%rrg_genlist;
%rrg_finalize;





 
