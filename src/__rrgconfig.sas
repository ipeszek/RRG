/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __rrgconfig/STORE;
  


data _null_;
file "&__workdir.&__dirdel.rrgconfig.ini" lrecl=1000;
  
put "[A1]";
put "#STAT LABELS";
put "N           N";
put "MEAN        Mean";
put "GMEAN       Geometric Mean";
put "NMISS       Missing";
put "STD         SD";
put "STDERR      SE";
put "MEAN+SD     Mean (SD)";
put "MEAN+STDERR Mean (SE)";
put "MEDIAN      Median";
put "MIN         Minimum";
put "MAX         Maximum";
put "MIN+MAX     Minimum, Maximum";
put "LCLM+LCLM   CI for the Mean";

put "[A2]";
put "# STAT PRECISION MODIFIERS";
put "MEAN       1";
put "GMEAN      1";
put "STD        2";
put "STDERR     2";
put "CV         2";
put "MEDIAN     1";
put "MIN        0";
put "MAX        0";
put "UCLM       1";
put "LCLM       1";
put "other      1";


put "[A3]";
put "# PERCENT FORMAT";
put @1 "ENTRY .,0 = ' '";
put @1 "ENTRY 0<-<0.1 = '(<0.1%)'  (noedit)";
put @1 "ENTRY 0.1-<99.95= '09.9%)' (prefix='(' mult=10)";
put @1 "ENTRY 99.95-<100='(99.9%)' (noedit)";
put @1 "ENTRY 100 = '(100%)'   (noedit)";

put "[A4]";
put "# PVALUE FORMAT";
put @1 "ENTRY low-<0.001 = '<0.001' (noedit)";
put @1 "other = '9.999'";


put "[B0]";
put "# TFL METADATA";
put "TFL_FILE_NAME";
put "TFL_FILE_KEY tflnum";
put 'TFL_FILE_KEY tflnum2="' "&rrguri" '";';
put "TFL_FILE_TITLES title0 title1 title2 title3 title4 title5";
put "TFL_FILE_FOOTNOTES foot1 foot2 foot3 foot4 foot5 foot6 foot7 foot8";
put "TABL_AFTER  Note 1:";
put "TABL_AFTER  Note 2:";
put "TABL_AFTER  Note 3:";
put "TABL_AFTER  Note 4:";
put "TABL_AFTER  Note 5:";
put "TABL_AFTER  Note 6:";
put "TABL_AFTER  Note:";
put "TABR_AFTER  (a)";
put "TABR_AFTER  (b)";
put "TABR_AFTER  (c)";
put "TABR_AFTER  (d)";
put "TABR_AFTER  (e)";
put "TABR_AFTER  (f)";
put "TABR_AFTER  *";


put "[C1]";
put "# DOCUMENT PROPERTIES  APPENDIX";
put "papersize   LETTER";
put "fontsize    10";
put "font        TIMESROMAN";
put "margins     1in 1in 1in 1in";
put "shead_l  TGRD//PROTOCOL: AFX01_202";
put "shead_r  DRAFT   _DATE_//_PAGE_";
put "shead_m";
put "sfoot_l     _PGMNAME_ (_USERID_  SAS Win 9.1.3)   ";
put "sfoot_m";
put "sfoot_r       ";
put "nodatamsg  No data";
put "orient L";

put "[C1]";
put "# DOCUMENT PROPERTIES  APENDIX";
put "outformat   PDF";
put "papersize   LETTER";
put "margins     1in 1in 1in 1in";
put "orient      L   "; 
put "fontsize    9";
put "font        COURIER";
put "body_pd     2";
put "title_al    L";
put "title_pd    4";
put "head_pd     4";
put "headu_sp    2";
put "foot_pd     4";
put "rtfpl_foot  t";
put "foot_pos    B";
put "foot_ftsp   4";
put "shead_l  ";
put "shead_r     _PAGE_";
put "shead_m";
put "shead_pd    4";
put "rtfpl_shead t";
put "date_fmt    ddMMMyyyy HH:mm";
put "date_fmt_uc true";
put "sfoot_l     _PGMNAME_ (_USERID_)";
put "sfoot_m";
put "sfoot_r   ";
put "sfoot_pd    4";
put "rtfpl_sfoot t";
put "sfoot_fs    9";
put "super_rs    3";


put "[C2]";
put "# DOCUMENT PROPERTIES  IN-TEXT";
put "outformat   RTF";
put "papersize   LETTER";
put "margins     1in 1in 1in 1in";
put "orient      p   "; 
put "fontsize    9";
put "font        COURIER";
put "body_pd     2";
put "title_al    L";
put "title_pd    4";
put "head_pd     4";
put "headu_sp    2";
put "foot_pd     4";
put "rtfpl_foot  t";
put "foot_pos    B";
put "foot_ftsp   4";
put "shead_l  ";
put "shead_r     _PAGE_";
put "shead_m";
put "shead_pd    4";
put "rtfpl_shead t";
put "date_fmt    ddMMMyyyy HH:mm";
put "date_fmt_uc true";
put "sfoot_l     _PGMNAME_ (_USERID_)";
put "sfoot_m";
put "sfoot_r   ";
put "sfoot_pd    4";
put "rtfpl_sfoot t";
put "sfoot_fs    9";
put "super_rs    3";

put "[D1]";
put "# DEFAULTS FOR RRG_ADDCOND AND RRG_ADDCATVAR";
put "pct4missing   Y";
put "pct4missing   N";

put "[D2]";
put "# DEFAULTS FOR RRG_ADDTRT";
put "autospan     Y";

put "[D3]";
put "# DEFAULTS FOR RRG_ADDVAR";
put "stats           n MEAN+SD Median MIN+MAX";
put "ALIGN           D";
put "showneg0        N";

put "[D4]";
put "# DEFAULTS FOR RRG_defreport";
put "subjid          usubjid";
put "indentsize      2";
put "warnonnomatch   N  ";
put "nodatamsg       No data";
put "dest            APP";
put "savercd         N";
put "gentxt          N";


run;

%mend;
