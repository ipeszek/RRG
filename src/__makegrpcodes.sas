/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __makegrpcodes (groupvars=)/store;
/*
PURPOSE: TO CREATE A DATASET WITH LIST OF CODES OF A VARIABLE 
         FOR EACH GROUPING VARIABLE

MACRO PARAMETERS:
GROUPVARS LIST OF GROUPING VARIABLES

NOTE: this macro is not being used in vurrent RRG version

*/


  
%local   groupvars;
%local i ngrp tmp;
%let ngrp = %sysfunc(countw(&groupvars,%str( )));
%do i=1 %to ngrp;
   %let tmp = %qscan(&groupvars, &i, %str( ));
   %__makecodeds (
     vinfods=__varinfo, 
     varname=&tmp, 
     dataset=__datatset, 
     outds=__grptemplate_&i);

%end;
  
%mend __makegrpcodes;
  
  
  
