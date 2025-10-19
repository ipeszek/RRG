/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

/*
  
  TODO:
 
  keeptogether for grouping (not just last one) -- not sure what it means???
  test labelvar - abandoned???
  test statsacross vs statsincolumn -- not sure what it means???
  

  *** implement eventcnt parameter for group -- delayed (too complicated)
  ***  total where countwhat=ALL  ---  delayed (too complicated)
  *** fix skiplines and indentation for ae tables
  
  test pyr with events ???
  
  test table parts with __varbygrp
  test cutoff with maxgrade  
  test table parts with __varby and with appending
  
  *-------------------------------------------------------------------------------------------------------------------;
26Aug2025 added nlinebyvars params to rrg_addtrt and rrg_addgroup to allow flexibility in calculating NLINE
           (if requested). It only applies to variables with page =N. and only to reports where reptype=regular
           the Nline is not automaticlly added, but the &rrguri dataset has additional variables
           __grpcnt_<group variable name> 
           calculated as count of subject in this value of grouping variables 
           (and nlinebyvars variabes, if specified)
           (and treatment if popsplit=y for this variable - bu then trtcount=subgroup count)
           if trt is in columns followed by grouping variable then use popsplit=n and  nlinebyvars=trt01an
           
           fixed a bug which did not sort properly by frequency if >1 treatment was specified

18Aug2025 fixed __cntaepy cutoff portion to avoid NOTEs in log about __pct_x__cnt_x uninnitialized
          fixed __transposet to avoid NOTEs in log about uninitialized __tmptrtvar

6Mar2025  set indent to 0 if null, fixed issue with unwanted skiplines when statsacross=y

19Feb2025 fixed a bug that had errant text in header when >1 group is placed in column

1Feb2025    fixed a bug that ignored orientation for CSR tables

25Nov2024   implemented codelistds parameter in rrg_addgroup
            added remove parameter
            

O1nOV2024   MISSINGSE can be read from D4 section of config file to populate value od SD.SE if missing.
                 leave blank to show as blank. default is "-"

23Sep2024   table can be generated with multiple "parts" (e.g. using different grouping).
            to do that, invoke full set of rrg macros with the same rrrg_init, rrg_defreport 
            (except for reptype which can vary) and same rrg_addtrt/page vars and across vars.
            This is controlled by rrg_init parameter TABLEPART which should be set sequentially,e.g. 1,2,3 etc.
            Also, rrg_defreport.print should be set to n in all but last set of rrg macros
            If used with append functionality, within each "append" invocation series, start with tablepart=1
            and make sure to use proper append/appendable for the last rrg macro set.
            
            
            
 9Sep2024  rrg_codeafter and rrg_codebefore can now have macro invocations and macro vars
          but have to be enclosed in %nrstr, e.g. %rrg_codebefore( %nrstr(xxx));        

28Aug2024:  nline can be requested for grouping vars with Page=Y
            in EVENT-type reports, grouping variable can be specified as aegroup=n and will be
             treated as regular group (not like hierarchical)
            
            exposure-adjusted rates can be requested. 
            available stats are PY, PYR, N/PY, N/PY(PYR),PYR(N/PY). 
            If requested, PY info has to be defined using MACRO
            
                  %rrg_define_pyr(
                    pydec = 1  -num of decimals for Patient-year variable
                   ,pyrdec = 4 -- num of decimals for eposure adjusted rate
                   ,patyearvar=patyr  - variable indicating patient exposure (e.g. last alive date)
                   ,patyearunit=YEAR -- unit for the variable above (year, day
                   ,onsetvar=ASTDT   -- variable indicating onset of AE
                   ,onsettype=DATE   -- unit for variable above
                   ,refstartvar=TRTSDT -- variable for reference startdate
                   ,refstarttype=DATE  -- unit for variable above
                  );



16Aug24 added cutoffval and cutofftype (cnt or pct) to rrg_addcatvar. 
   If specified, the rows below specified threshold (based on count or pct calculated  by groupvars aedecode )
      are removed before anything else is calculated. For AE by grade, specify cutoffval/cutofftype
      for aedecod grouping variable, not for grade variable.
      Cutoff uses rrg_addtrt cutoffcolumn which is a list of comma delimited vaalues of treatment variable

13May2024  if __col_0 ends with '//' then set __suffix to ~-2n  

4Apr2024  More than 1 statistic can be requested for AE tables (no multiple statistics when PY and countwhat=max)
         
  
21Nov23 added eventcnt parameter to rrg_addgroup to allow for count events line (values: ABOVE or BELOW)
  
13Nov23 added statlabel to rrg_addcod. applies to only 1st requested statistics. If >1 statistics are requsted, it will apply to all 
      added statindent (applies to additional indnetation when labelline=0, default=1)
      fixed issue with unit not being set properly in __cnts CALL
      fixed length of decode for total in cntsae 
  
8Nov2023 added subjid to rrg_addvar


20Jul2023 fixed rrg_addgroup and rrg_addcatvar handling of preload format to remove trailing blanks
  
16Jun2023 Fixed __makerepinfo : if last character was coded to ascii number, the blank after it was being stripped 
  
23Feb2023 in ae tables by severity, total counts can be placed on the same row as aebodsys etc, 
         by specifying totalpos=-1 in severity addcatvar. fixed issue in __cntsae when program bombs out
         if totaltext length is greater than length of specified decode variable


25Ja2023 removed comment from rrg_generate, updated __cond to handle labelvar parameter properly. 
          Labelvar indicates a variable in templateds dataset

20Jan2023 Fixed bug in __transposet which created crash when only one treatment was present (drop stmt caused crash)

14Nov2022 implemented labelvar in rrg_addcond (logic was already there but macro param labelvar was not defined with macro) 

 

  

3Aug2022  handled case when sortcolumn param has comma-separated values (which it shoul dnot)
         misc typos were fixed
         added rrg_defreport param lowmemorymode (if Y, __dataset is not handled as sasfile, default is N  )  
         fixed a bug in rrg_unindentv/rrg_unindent which caused col_0 header to be taken from table body when varbygrp is used
  

21apr2021  showmissing added to config ,
            remove works whether or not codelist is used 

7April 2022 removed changing % to /#0037 in rrg_generate
             changed %dolist ro %rrgdolist in rrg_genlist
             removed sasfile option for rrgpgm
             fixed saving of xml file
             
             
15APR2022 coded quotes and parentheses back from symbol to normal display , 
          rrg_generate at the end sorts by __datatype, __varbygrp, __rowid

30Mar2022 Fixed nodata msg for tables (in rrg_generate). Table headers/footnotes are displayed unless rrg_addtrt.across=n or there are page-by group variables



20Feb2020 changed handling of rrg_configpath, so it handles the case when  
          macro variable rrg_configpath is definedas global but is null 
09Feb2021 fixed handling of pct4total (logic flaw, was not taken from rrg_addcatvar but only from config file)
22Jan: accounted for missing__val in __condfmt
       accounted for not present __indentlev, __next_indentlev, __keepn in __savexml
       fixed handling of splitrow parameter in rrg_addtrt  
21Jan replaced % in fmt with /#0037 to avoid errors  
  
16Jan2021: removed notes about converting char to num and vice versa
           fixed bug where ")" was printed as "#/0041"
           fixed display of grouping variable with PAGE=Y
  
09Jan2021: 
fixed issue with cell borders when page splits into multiple pages
fixed issue with extra space before superscript in pdf
added support for subscript (syntax is ~{sub x}  
Up to 14 footnotes are supported
  
13Nov2020 changed __cont and __cntssimple to avoid warning about operation on missing values;
                  missing shown as blank except for SD/SE where it shows as "-"
  
08Oct2020 if rrg_debug is set to 1 prior to invoking rrg-init, additional info is printed/created. In particular, dataset __execution
  is created in rrgpgmpath folder with execution statistics.   
  
01Oct2020 rewrote to improve performance (generated program stored in dataset and written to file at the end, and many other performance improvements)
          removed metadata and gentxt functionality
          updated no-data functionality to create report with titles, headers and footnotes  
  
31Aug2020 Removed java2sas modules

18Aug2020: changed location of generated program to work directory (later it is copied to specified &rrgoutpath);

12Aug2020 modified listing module so if there is no data, the headers and footnotes are displayed.
          if it is desired not to show headers and footnotes (as before this realese)
          then user can delete all records from &rrguri, except where __datatype='RINFO', in rrg_codeafterlist  
          modified table module so if there is no data, the footnotes are displayed. 
          Adding header is not possible in such case because the headers are generated from of input dataset

09Jul2020
  RRG_ANOVA: removed untangling of interaction terms 

16Jun2020
   RRG_ADDVAR: added showneg0 parameter 
    (to show "-" if rounded value of stat =0 but is negative).
    Usage: specify showneg0=y in rrg_addvar.
    To apply to all tables in a project, add a line
    showneg0   Y 
    in section D3 of configuration file
    
  RRG_ANOVA, RRG_BINOMEX: fixed bug: parameter print_stats was referred to but not specified 
        as rrg_anova/rrg_binomex parameter
        
  made handling of missing stats consistent (if n=0, other stats are shown as blanks)   

27May2020
  RRG_ADDVAR: condfmt applied only to stats specified in condfmt
  stats=. replaced with blank
  (.) in stats replaced with (NA)
  added maxdec parameter (max number of decimals for continous stats)
  added pvfmt parameter (format to print p-vals from ttest)
  ALL: fixed __warning about __fordelete 
  ALL: fixed warning about "variable already exists" in proc sql
  ALL:  removed unnecessary proc sql printouts
  categorical plug-ins: fixed bug which resulted in error when stat models was used with MINPCT or MINCNT in event-like reports
  RRG_ANOVA: fixed bug when pairwise stats were printed in wrong columns
  RRG_BINOMEX: added print_stats parameter

--------------------------------------------------------------------------------------  
  11Nov2015
  implemented in rrg_defreport the value of eventcnt=Y(e) which will produce just the count of events
  without producing count of subjects. Applies only if reptype=EVENTS.


--------------------------------------------------------------------------------------  
  07Nov2015
  modified rrg_addcond and rrg_addcatvar so that denominator dose not have to include treatment
    variables (which is default). 
  To exclude treatment variables, use in %rrg_addcond and/or %rrg_addcatvar:
  denomincltrt=n (case-insensitive)
  Note: if   denomincltrt=n then some (or all) grouping variables MUST BE specified in denomgrp parameter 


  
--------------------------------------------------------------------------------------  
  06Nov2015
  modified %rrg_inc and %rrg_inc4list so that if path is not provided, rrg loooks for 
  this file in the ame folder as calling program
  
  
--------------------------------------------------------------------------------------
30Oct2015
 &rrguri dataset now has added variable __next_indentlev indicating indent level of next record
     this is useful if statsacross=y is specified in rrg_defreport (if skipline=y is ignored )
     so user can add skiplines in rrg_codeafter


  
  
--------------------------------------------------------------------------------------  
  09Oct2015
  
  added parameter "countwhat" to rrg_adcond. countwhat=events then the events - not subjects - will be counted.
  NOTE: countwhat=events in rrg_addcond is not compatible with eventcnt=Y in rrg_defreport 
  (eventcnt=Y is ignored))
  NOTE: this functionality will be shortly superseded by adding "eventsinrow" parameter to rrg_defreport
  added parameter  "outname" to rrg_init and rrg_initlist. I allows user to name the  output (pdf/rtf)
      without being confined to sas dataset naming restrictions and 26 char max
      Note: use $_date_$ to include date of generation in output file name. It uses yymmdd10 format.
  
  EXPERIMENTAL features until further testing is done:
      listing module: added parameter "finalize" to rrg_genlist. If set to N, then listing is not generated 
          until rrg_finalizelist is called
      added macro rrg_codeafterlist to allow for modification to &rguri dataset prior to finalizing 
          listings
      added macro rrg_inc4list which allows user to "%include" external program 
          (until now it only worked for table module with rrg_inc macro)
  --------------------------------------------------------------------------------------
  
  
  
  25Sep2015
  Added ability to display any combination of proc means statistics
    Usage: in  config file, in a section [A1] provide "templates" for display.
    The expression on the right hand side of display (the template) tells RRG
    how to display "composite" statistics. The statistics must be in upper case and
    must correspond to the actual names of statistics available in proc means, enclosed between dollar signs.
    The new section [A1L] is used only to specify label for statistics
    
  Added p-value parameter to rrg_addvar to display PROBT with desired format, specified in config.ini
  
  
  --------------------------------------------------------------------------------------
  
  17Jul2012 added condfmt parameter to rrg_addvar to do decimal precision based on how
            big the number is (conditional formatting) or any other custom format (e.g. picture)
            
            Usage
            %rrg_addvar(..., condfmt=%nrbquote( string1, string2, etc), ...)
            e.g.
            %rrg_addvar(..., condfmt=%nrbquote( min max myfmt. 0.000001, mean median stderr myfmt2. 0.000001), ...)
            
            condfmt parameter must be enclosed in %nrbquote if there are 2 or more different conditional formats specified
            
            strings are separated by commas and each string consists of 3 parts: 
            
              -list of statistics to which format will apply
              -format name
              -precision to which to round before applying specified format
              e.g.
              %rrg_addvar(..., condfmt=%nrbquote( min max     myfmt.    0.000001,    mean median stderr myfmt2. 0.000001), ...)
                                                  -------     ------    --------
                                                  list of     format    rounding
                                                  stats       name      precision
              
            the specified format(s) must be defined in rrg_codebefore or included in (myinit.sas and config.ini(header section))
              or included using %rrg_inc macro
              
            these formats will typically look something like this:
              
              proc format;
              value myfmt
              low  - 0    = '<= 0'
              0  < - 5    = [8.3]
              5  < - 40   = [8.2]
              40 < - high = [8.1]
              ;
              run; 

--------------------------------------------------------------------------------------
23Jun2011
rrg_added comprcd macro to compare RCDs from 2 different runs

--------------------------------------------------------------------------------------
04Mar2011
fixed bug that caused display problem if java2sas=Y was used and font sie was not = 9
If metadata dataset is requested: added scan of &tabwhere, &popwhere, &denomwhere, &totalwhere
   and %where parameters to determine which variables are used by the program



--------------------------------------------------------------------------------------
26Feb2011
modified bevaiour of saving XML, RCD and validation text file to minimize accidental 
unblinding: when generated code is run and new &rrgoutpath is specified then they are saved
in this new location (as is currently rtf/pdf file); if &rrgoutpath is not specified 
then they are saved (as is currently rtf/pdf file) in the location specified in original
RRG program

added check for illegal non-ascii characters (that are preventing output generation) 
if %rrg_finalize is run with debug>0

added creation of metadata dataset with basic information about the report (titles, permanent datasets used, variable used, 
popwhere, tabwhere, all other "where" clauses uses throughout the program etc.) It is created/updated
with each RRG run if cofiguration file has value specified for METADATADS in section D4.
If a valid sas name is given, the dataset with this name is created in &rrgoutpath (normally, 
with one record for each RRG program.). But if APPEND=Y then there is a record for each "part" of the RRG program.
Records (reports) are identified by RRGURI variable.
Rerun of the RRG program updates the record.
Note 1: this dataset is created only during run time of RRG program (notduring run of generated program)
Note 2: it includes variables that exisit in permanent (2-level) datasets used by the RRG program and that :
          specified as NAME or DECODE parameters in rrg building blocks, 
          appear in rrg_codebefore, 
          appear in rrg_joinds, 
          appear in PARMS parameter of rrg_defModelParms
          (note: this means that if , e.g. , rrg_codebefore has a statement "drop trt01a;" then TRT01A is listed
          as variable used)
Note 3: If macros are used via "rrg_inc" or "rrg_call_macro") then such macros shoudl be checked for additional datasets and variables 
        used. If "rrg_defModelParms" is used and the macro it refers to uses "implicitely" some datasets and/or variables then such macros 
        shoudl be checked for additional datasets and variables used.


corrected bug that sometimes prevented %rrg_inc or rrg_call_macro to be included in generated code

modified java2sas behaviour. It now creates a GLOBAL variable __rrgpn to store total number of pages

--------------------------------------------------------------------------------------

22Feb2011
showmissing corrected to apply to countwhat=max
sashiato updated to not print empty line when there is no system footers
--------------------------------------------------------------------------------------

17JAN2011

added REMOVE parameter to %rrg_addcatvar. It is used only if countwhat=max and codelist is given,
      and is used to remove values specified in REMOVE from display (this does not affect any calculations)

      Usage: %rrg_addcatvar(name=CTCGRD, countwhat=MAX, codelist=%str(.,1,2,3,4,5), remove = . 1 2 3 );
      (shows only grades 4 and 5)

modified TOTALPOS and misspos parameters to accept a number.

      Details:
      
      Regular nonmissing modalities  get order = 1, 2, 3 , ... 
       (corresponding to natural order according to values of analysis variable, 
        or to the order specified in codelist if codelist is given (reverse if desc=y))
      
      Missing: if misspos=FIRST then order = -999999
               if misspos=LAST then order = 999998
               if unspecified (and missing is not in codelist) then order = 999999
               if unspecified and missing is in codelist then order = position of missing in codelist
               if misspos = number then order = number
              
      Total:  if totalpos=FIRST or unspecified  then order = 0
              if totalpos=LAST then order = 999997
              if totalpos=number then order = number
              
      Examples: 
      
      To show CTC Grades (which take values Missing, 1,2,3,4,5) in the following order:
               1,2,3,4, 3+4, 5, Missing  (where "3+4" is obtained using TOTALTEXT/TOTALWHERE),
               specify:
      
      %rrg_addcatvar(name=CTCGRD, countwhat=MAX, 
                 ,codelist=%str(.,1,2,3,4,5), misspos=last,
                 totaltext='3+4', totalwhere=%str(CTCGRD in (3,4)), totalpos=5.5);         
               
      
      To show CTC Grades (which take values Missing, 1,2,3,4,5) in the following order:
               1,2,3,4,5, Missing, Any Grade  (where "Any Grade" is obtained using TOTALTEXT),
               specify:
      
      %rrg_addcatvar(name=CTCGRD, countwhat=MAX, 
                 ,codelist=%str(.,1,2,3,4,5), misspos=7 [* or any number >6 *],
                 totaltext='Any Grade', , totalpos=8 [* or any number > number given to misspos *]);         

----------------------------------------------------------------------------------------------------;

05JAN2011
fixed bug with event reports when countwhat=max and totalwhere is used.
Previous version: total where was applied before MAX was established. Fixed to establish
MAX first and only then apply TOTALWHERE


----------------------------------------------------------------------------------------------------;

08NOV2010

fixed bug when ae by (e.g.) relationship generated error whwn there were no AEs satisfying &tabwhere

----------------------------------------------------------------------------------------------------;

06SEP2010

fixed bug in calculation of condition when in some cases (when grouping=y) 
the dataset was not properly sorted by 
added warning to event reports when total is requested by countwhat is not MAX

added re-sorting of RCD after rrg_codeafter to address cases when usuer modified __rowid;

added __nvtype variable to RCD (next record type)

-------------------------------------------------------------------------------------------;

25AUG2010

modified __cond macro so __datasetp passed to custom model is not subset by &where ************************************
Instead, if &where then __condok=1 and else __condok=0


added labelvar to rrg_addcond. If specified then the value of &labelvar variable is used as label ************************************
and &label is ignored.



-------------------------------------------------------------------------------------------
23AUG2010

added popsplit= parameter to rrg_addgroup.   ************************************
If popsplit=Y (default FOR page=y) then the variable is 
assumed to be population splitting ad pop count is calculated within each of its values.
If popsplit=N (DEFAULT IF PAGE NE Y) then population count ignores values of this variable. It also fixes bug with calculation
of NMISS when PAGE=Y variable is used.

INCOMPATIBILITY NOTE: RRG NO LONGER AUTOMATICALLY ADDS GROPING VARIABLE TO POPGRP IF PAGE=Y AND POPGRP IS SPECIFIED
INCOMPATIBILITY NOTE: RRG NO LONGER AUTOMATICALLY ADDS GROPING VARIABLE TO DENOMGRP IF PAGE=Y AND DENOMGRP IS SPECIFIED


todo: fix population count etc for grouping variable
-------------------------------------------------------------------------------------------

17AUG2010

added check/warning that listing variable with group=y, skipline=y, page=y, keeptogether=y
  or spanrow=y appears on ORDERBY
 
aded handling of numeric variables in listings so vars specified without format do not trigger
SAS segmentation error
  
-------------------------------------------------------------------------------------------

04AUG2010

added compression to permanently saved RCD dataset so it takes much less space
added parameter desc (=Y|blank) to rrg_addcatvar. It takes effect only for AE tables, with countall=MAX, ************************************
  and allows to display modlaities of variables in "reversed" order to what is specified in codelist.
  Note that codelist order is still used to select max value for summary.
  Example: The table is to show relationship as 
    Related
    Not Related
    
  but if the subject has 2 or more AEs for the same aebodsys/aept , one or more related and one or more not related ,
  then it is counted under "related"  . Codelise is specified as 
  codelist=%str(0='Not Related', .='Missing', 1='Related'),
  and if desc is ommitted then the display order will follow codelist order:
        Not Related
        Missing
        Related
        
  But if desc=Y, then display order will be 
        Related
        Missing   
        Not Related
  Note that placment of "Missing" can be controlled by using misspos=first|last 

------------------------------------------------------------------------------------------

24JUN2010
added tablepart parameter to support "appending" records to table
added notcondition parameter to rrg_addcond to calculate count of subjects not 
      satisfying the conditon (does not apply to event count)

------------------------------------------------------------------------------------------

28MAY2010

added check for duplicates in dataset used by __cont, selecting only 1st value
For generated validation file (gentxt=Y): added steps to not print blank lines 
    and to change '//' to ' ' 


------------------------------------------------------------------------------------------

25MAY2010
added wholerow(y/n) parameter to rrg_addlabel -- causes label to span all columns
added replace parameter to rrg_finalize to allow replacement of special symbols for java2sas=y
      note that this may result in over or under calculation of column widths etc
      usage, e.g. rrg_finalize(replace=%str("/s#pm" : "+/-", "/s#ge" : ">="));
      For multi-part tables, use in last %rrg_finalize

------------------------------------------------------------------------------------------

15MAY2010
added support for "sas only" output allowing generated programs to run compltetely RRG and sasshiato free
(java2sas=y parameter)

java2sas limitations:
  font used must be courier
  only rtf output 
  no special symbols (but see above under 25MAY2010)
  center alignment not supported (at the moment)
  no vertical page splits
  KEEPTOGETHER (for listings) not implemented
  middle system header and system footer not supported
  If at RRG generation stage report has no data, this is what report will show when generated code is run
    (even if data changes and now report does have data)
  
  
------------------------------------------------------------------------------------------

21APR2010

added keeptogether (Y/N) to rrg_defcol to keep a whole "group" on one page, if possible


-------------------------------------------------------------------------------------------

15APR2010
added saving of rcd dataset and printing of rcd dataset (savercd and gentxt parameters)
(also added to config file the parameters JAVA2SAS SAVERCD GENTXT)  
rcd and text file are saved in rrgoutpath folder

-------------------------------------------------------------------------------------------

26MAR2010

added rrg_binomex macro to calculate exact CI for proportion

-------------------------------------------------------------------------------------------

25MAR2010

in rrg_binom: added whereafter parameter (to apply to output dataset) and contcorr (Y/N)
whether continuity correction is applied

------------------------------------------------------------------------------------------

05MAR2010

added SHOW0CNT parameter to rrg_addcond macro.
Default is Y.
If N, then the record is shown in table only if one or more columns have count>0

added POOLED4STATS parameter to rrg_defreport macro. -- not fully implemented yet
Default is N
If Y, the dataset "passed" to stat model macro will include pooled groups.
(the stat macro should handle pooled groups properly).
Otherwise pooled treatments will be excluded.
Please note: to "selectively" include/exclude pooled groups depending on particular stat model,
you must specify POOLED4STATS=Y and handle/exclude  pooled groups inside stat macro.

_________________________________________________________________________________________________

*/
