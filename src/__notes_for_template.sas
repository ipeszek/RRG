/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

/*

dataset __&codelistds._exec is created in __MAKECODEDS MACRO
  and is used in __applycodesds and __usecodesds macros
  
dataset __grpcodes_exec is created in rrg_generate (line 710)  
  
__APPLYCODESDS  macro is used in __cnts.sas (line 290)

__USECODESDS macro is used in __cnts.sas (line 220)

__MAKECODEDS macro is used in rrg_generate (line 676), __CNTS (line 212), __MAKEGRPCODES (line 18)
--- can be ignored if working on template , except it copies &codelstds to __&codelistds._exec
and to __&codelist  ----

__MAKEGRPCODES macro is NOT USED

__CNTS macro is used in rrg_generate (line 862)

-------------------------------------------------------------------------------
__MAKECODEDS macro flow

inputs: 
&dsin specified in rrg_defreport
&varname: name of variable being processed
&varid:   id of variable being processes
&id:     a number passed to macro

If &codelistds is specified for the variable bein gprocessed, then at runtime
this macro copies &codelistds into __&codelistds._exec __&codelistds and exists.

If codelist is not provided in rrg_addcatvar or rrg_addgroup (for the variable being processed)
then macro exits

Otherwise:


AT RUNTIME:

create dataset &outds._exec with the following variables:
   
   &varname (of type and length the same as in input dataset). If &varname not given but varid given 
              then macro determines &varname from __varinfo dataset
   __display_&varname or __display_&varid (if &varname not given), Character length 2000
               this is decode from decodelist. If format was also specified, then 
               formatted value replaces "decoded" value from codelist 
   __order_&varname (according to order of modalites in &codelist for the variable,
                   if in rrg_addcatvar desc=Y  then order is reversed (read from right to left)   
   
   If &varname was provided:                
       Updates __varinfo datset to specify decode="__display_&varname" for variable being processed
       Updates __rrgpgminfo dataset to specify  gtemplate="&outds", id=&id                             

   If &varname was not provided (as when calling this macro in cnts macro):
       Updates __catv (which is __varinfo subset on variable being processed)
        to set set codelistds="&outds" and decode="__display_&varid"
  
in GENERATED PROGRAM:

   creates dataset &outds with the same content as runtime dataset &outds._exec.
   But if decode was specified in rrg_addcatvar and it exists in input dataset 
   then length of __display_&varname / __display_&varid is the same as length of decode
   variable input dataset
   
   sorts this dataset by __order&suff


-----------------------------------------

__USECODESDS macro flow:

&var = variable being processed
&decode: decode for this variable

if codelistds is NOT specified then this macro does nothing

--------------------------------------------------------------------------------------------

if &codelistds starts with __ then at runtime set RUNTIME_CODELIST_DATASET = &codelistds._exec,
  otherwise at runtime set RUNTIME_CODELIST_DATASET = __&codelistds._exec
  
  __&codelistds._exec is a copy of &codelistds (provided by user in RRG program)
  and is created in __makecodesds
  
--------------------------------------------------------------------------------------------
  
1. if dataset __grpcodes_exec  exists:
      this dataset is created in rrg_generate and contains variable names , decode values 
      (stored in __display_<variable name>), and order (stored in __order_<variable name>)
      of all grouping variables for which codelist was provided. 
      All grouping variables for which codelist was proveded are cross-joined.
      For those grouping variables for which codelist was not provided, dummy __order_<variable name>
      variables are created with null values.
      This dataset is then sorted by __order_vn1, __order__vn2 etc and a variable __orderb=_n_ is added to it
      
 
      at runtime:
        augment RUNTIME_CODELIST_DATASET by cross-joining it with __grpcodes_exec  
        drop from RUNTIME_CODELIST_DATASET variables  &var, &decode and __order (if exists) 
           and store this new dataset in runtime dataset __grpcodes_exec
    
      IN GENERATED PROGRAM:
        update &codelistds by cross-joining it with dataset __grpcodes  
        (this is "generated program" version of __grpcodes_exec before being updated as
        described in th eparagraph above) 
                
        replace __grpcodes with &codelistds and drop &var, &decode and __order (if exists)
        
2. If dataset __grpcodes_exec  does not exist:

   at runtime:
     drop &var, &decode and __order from RUNTIME_CODELIST_DATASET and check if  after that there 
       are some variables left in the dataset.
       If not, do nothing.
       If yes:
         store names of all grouping variables (regular and pageby)  in &grpnames
         store names of decodes for grouping variables in &grpdec
         
         create macro variable &allgrp using all grouping variables (lets call it &grpname1, grpname2 etc), 
         their decodes and __order_&grpnameX
           which exist in RUNTIME_CODELIST_DATASET as:
         &grpname1 __order_&grpname1 &grpname2 __order_&grpname2 ... 
         decode for &grpname1 decode for &grpname2 ...
         
             
         create dataset __grpcodes_exec by selecting distinct &allgrp from RUNTIME_CODELIST_DATASET
     
         IN GENERATED PROGRAM:
          create able __grpcodes by selecting  distinct &allgrp from &codelistds (after dropping
          from it &var &decode and __order (if exists)
          
 Under either scenario, IN GENERATED PROGRAM,  __grpcodes  dataset has variables containing
     names, decodes, and __order_<name> for all grouping variables
     if grouping variable had codelist specified then its decode is __display_vn (vn=variable name)
     else it is it's decode provided in rrg_addgroup. If neither decode nor codelist was provided
     then __grpcodes will not have any decode for this grouping vrariable (TODO: DOUBLE CHECK)
 
--------------------------------------------------------------------------------------------

at runtime:
  create macro variable &alldecodes which contains names and decodes for each grouping variables
    (name1 decode1 name2 decode2 etc)
  create macro variable &missgrp which contains names and decodes (if specified in rrg_addgroup) 
     of grouping variables NOT PRESENT in RUNTIME_CODELIST_DATASET (name1 decode1 name2 decode2 etc)
  create macro variable &missgrpdecode which contains decodes  (if specified in rrg_addgroup) 
    of grouping variables NOT PRESENT in RUNTIME_CODELIST_DATASET (decode1 decode2 etc)
  For each grouping variable whic IS PRESENT in RUNTIME_CODELIST_DATASET :
    create macro variables dec1, dec2 etc which has decodes for these grouping variables 
    
  If decode is given for var, and if it is present in RUNTIME_CODELIST_DATASET, then 
    create macro variable &decX = &decode 
  (X is (number of grouping variables present in RUNTIME_CODELIST_DATASET)+1 )
  
  If decode is given for var, and is NOT present in RUNTIME_CODELIST_DATASET, then 
    append &decode to &missgrpdecode and &missgrp
  
  If &var is not present in RUNTIME_CODELIST_DATASET, then  append &var to &missgrp  
  
  create macro variable &decodes2drop which contains list of all decodes 
    (for grouping variables and for &var) which exist in  RUNTIME_CODELIST_DATASET   

--------------------------------------------------------------------------------------------  
  at runtime:
  
  if variable __order does not exist in RUNTIME_CODELIST_DATASET, and &var exists in in RUNTIME_CODELIST_DATASET
  then create dataset &outds._exec (__catcodes&varid_exec)  
  by adding a variable "__order" to RUNTIME_CODELIST_DATASET 
  (by sorting RUNTIME_CODELIST_DATASET by &var and incrementing   __order on change in &var. )
    
  if variables &var and  __order both exist in RUNTIME_CODELIST_DATASET, 
  then copy  &codelistds into &outds._exec (__catcodes&varid_exec) dataset

  if variable &var is NOT present in RUNTIME_CODELIST_DATASET  
  then copy  &codelistds into &outds._exec (__catcodes&varid_exec) dataset

--------------------------------------------------------------------------------------------    
  
  
IN GENERATED PROGRAM:
  if variable __order does not exist in RUNTIME_CODELIST_DATASET, and &var exists in in RUNTIME_CODELIST_DATASET
  then create dataset &outds (__catcodes&varid)  by adding a variable "__order" to &codelistds 
  (by sorting &codelistds by &var and incrementing   __order on change in &var. )
  Create &outds.2 (__catcodes&varid2)  as a copy of &outds (__catcodes&varid)  
    

  if variables &var and  __order both exist in RUNTIME_CODELIST_DATASET, 
  then copy  &codelistds into &outds (__catcodes&varid)   and &outds.2  (__catcodes&varid2)  datasets
   
   
  if variable &var is NOT present in RUNTIME_CODELIST_DATASET  
  then copy  &codelistds into &outds (__catcodes&varid)  and &outds.2 (__catcodes&varid2)  
      datasets and create variable __order=_n_  
   
--------------------------------------------------------------------------------------------    

IN GENERATED PROGRAM:

if either &var , it's decode, or decodes for some grouping vaiables do not exist in RUNTIME_CODELIST_DATASET:
   
   
  select distinct values of these missing variables (specified above, from &missgrp) from &dsin
  (which is dataset passed to rrg_defreport after subsetting on where (from varinfo for variable being
  processed) and tabwhere (from rrg_defreport)
  and cross-join them with &outds (__catcodes&varid)  and store in &outds.2 (__catcodes&varid2)  
  
   Now &OUTDS.2 (__catcodes&varid2), which is a final codelist,  contains names, decodes, and order variable for all
   grouping variables and for variable being processed, as well as __orderg variable
  
   Take the first record from input dataset  and drop all grouping variables,
   decodes, &varname and its decode, treatment variable and __order
   (that is, we are keeping all other variables which potentially may be needed for 
   modelling etc). This is dataset &outds.3 (__catcodes&varid3)
   Merge this single record onto &OUTDS.2 (__catcodes&varid2) and create a __trtid (negative number)=-1*_n_
   (&outds.4 (__catcodes&varid4))
   Add this "augmented" dataset &outds.4 (__catcodes&varid4) to input dataset 
   
  
---------------------------------------------------------------------------------------------------  

IN GENERATED PROGRAM:

   TODO: decipher what does it do;  
put @1 "data &outds.2;";
put @1 "  set &outds.2;";
put @1 "  __theid=_n_;";
put @1 "  __tby=1;";
put @1 "run;";
put;
put @1 "data &outds.3;";
put @1 "  set &dsin;";
put @1 "  __order=1;";
put @1 "  __tby=1;";
put @1 "  drop &by  &alldecodes &var &decode &trtvars __order;";
put @1 "run;";
put;
put @1 "data &outds.3;";
put @1 "  set &outds.3;";
put @1 "  if _n_=1;";
put @1 "run;";
put;
put @1 "proc sort data=&outds.3;";
put @1 "  by __tby;";
put @1 "run;";
put;    
put @1 "proc sort data=&outds.2;";
put @1 "  by __tby;";
put @1 "run;";
put;
put @1 "data &outds.4;";
put @1 "  merge &outds.2 &outds.3;";
put @1 "  by __tby;";
put @1 "  __trtid=-1*_n_;";
put @1 "run;";
put;
put @1 "data &dsin;";
put @1 "  set &dsin (in=__a) &outds.4;";
put @1 "  if __a then __theid=0;";
put @1 "  __tby=1;";
put @1 "run;";  

-------------------------------------------------------------------------------------------------;
IN GENERATED PROGRAM:

If grouping variables exist, then 
create dataset __grptemplate which has distinct values of all grouping variables and their decodes 
(if provided in rrg_addgroup) from &outds.2 (__catcodes&varid2))
  
*/
