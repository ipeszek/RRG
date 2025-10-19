/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro rrg_define_pyr(
  pydec = 1
 ,pyrdec = 1
 ,multiplier=1   /* if 1 the rate is presented per patient year, if 100 then rate is per 100 patient years */
 ,patyearvar=patyear
 ,patyearunit=YEAR
 ,onsetvar=ASDT 
 ,onsettype=DATE
 ,refstartvar=TRTSDT
 ,refstarttype=DATE

)/store;

%local pydec pyrdec onsetvar onsettype patyearvar patyearunit refstartvar refstarttype multiplier;

data __pyrinfo;
  length pydec pyrdec onsetvar onsettype patyearvar patyearunit refstartvar refstarttype $ 8;
  pydec             =symget("pydec")  ;
  pyrdec            =symget("pyrdec")  ;        
  multiplier        =symget("multiplier")  ;        
  onsetvar          =upcase(symget("onsetvar") ) ;      
  onsettype         =upcase(symget("onsettype") ) ;     
  patyearvar        =symget("patyearvar")  ;    
  patyearunit       =upcase(symget("patyearunit") ) ;   
  refstartvar       =upcase(symget("refstartvar"))  ;   
  refstarttype      =upcase(symget("refstarttype "))  ; 
run;  


%mend;



