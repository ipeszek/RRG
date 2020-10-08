/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 
 
 Macro parameters specified by User:
 - URI (required) the name of the report. Must be allowable SAS dataset name.
 - PURPOSE (optional, rarely used) writes to generated program a comment about 
     the purpose of this macro. 
     the default is " to clean up work directory of files starting with __
         and to initialize __varinfo data set and __statinfo datasets"
 - OUTNAME (optional) name of output RTF and/or PDF file, without extension, 
      if it is desired to name the output file in different lenght/naming convention 
      than SAS dataset rules allow. The length/value is limited only by OS restrictions. 
 */
 
 
   

%macro RRG_initlist (URI=, purpose=, outname=)/store;
  
  
  %rrg_init(uri=&uri, purpose=&purpose, outname=outname);



%mend;




