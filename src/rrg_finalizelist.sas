/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro rrg_finalizelist(debug=0, savexml=, output_engine=JAVA, replace=)/store;

%local debug  savexml output_engine;  

%rrg_finalize(debug=&debug, savexml=, output_engine=JAVA, replace=)  ;

    
 
    
%mend;
