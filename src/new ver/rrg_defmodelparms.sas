/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro rrg_defModelParms(modelname=, macroname=, parms=)/store;
  
  %local modelname varname parms;
  
  %__rrgaddgenvar(
  model=%upcase(&modelname),
  name=&macroname,
  parms = %nrbquote(&parms),
  outds=__varinfo,
  type='MODEL'
  );
  
  
%mend;
