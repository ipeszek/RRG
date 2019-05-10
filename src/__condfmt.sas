/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */



%macro __condfmt(condfmt=)/store;


%local condfmt i j;




%local i j tmp tmp2 statl tmpr prec fmtname;

%do i=1 %to %sysfunc(countw(&condfmt, %str(,)));
 %let tmp = %scan(&condfmt, &i, %str(,));
 %let prec = %scan(&tmp,-1,%str( ));
 %let fmtname = %scan(&tmp,-2,%str( ));
 
 
 %let statl=;
 
   %do j=1 %to %eval(%sysfunc(countw(&tmp, %str( )))-2);
   
     %let tmp2 = %scan(&tmp, &j, %str( ));
     %let statl =&statl  %str(%')&tmp2%str(%' );


   %end;
   
   
   

 
  put @1 "if __name in ( &statl.) then do;";
  put @4 "__val = round(__val, &prec.);";
  put @4 "__col = compress(put(__val, &fmtname.));";
  put @1 "end;"; 
%end;



%mend;

