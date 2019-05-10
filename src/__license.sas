/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __license/store;

%* this macro function resolves to blank if site id is one of the authorized
   and the date is on or prior expiration (enddate);
%* it resolves to 0 if site id is not authorized;   
%* it resolves to enddate if system date is after enddate;
  

%*-----------------------------------------------------------------------;  
%* 0032422001   iza;
%* 32422001     iza;
%* 70110201     iza;
%*   25866005   REGENERON;
%* 0025866005   REGENERON;
%* 0025866010   REGENERON;
%*   25866010   REGENERON;
%*   25866011   REGENERON;
%* 70072741   regeneron 9.2;
%* 70072742   regeneron 9.2;
%* 0049720001   MITSUBISHI;
%*   49720001   MITSUBISHI;
%*   70047524   MITSUBISHI;
%* 0070047524   MITSUBISHI;
%* 0032436001   Icon;
%* 0030477001   Icon iza;
%*  70011327  BDM
%*  70146885  Relypsa
%* 70125568   vifor
%* 70178963   vifor
%* 70205873  iza


%*-----------------------------------------------------------------------;   

%local siteids i tmp  __license enddate;

%*-----------------------------------------------------------------------;
%*   ADD AS NEEDED BELOW;
%* FOR THE WORLD;

%let siteids = 0032422001 32422001 25866005 0025866005 0025866010 25866010 70014989 0070014989 70011327 0070011327;
%let siteids = &siteids 0025866011 25866011 70072741 0070072741 70072742 0070072742 70110201 0070110201 70146885 ;
%let siteids = &siteids 0070146885 70125568 0070125568 70178963 0070178963 70205873 0070205873

;

%let enddate = 2112-08-31;

/*
%* FOR JAMES WU;
%let siteids = 0032422001 32422001 0032436001 0030477001 ;
%let siteids = &siteids 0049720001 49720001 70047524 00 70047524 ;
%let enddate = 2011-03-01;
*/
%*-----------------------------------------------------------------------;

%let __license=0;

%do i=1 %to %sysfunc(countw(&siteids, %str( )));
  %let tmp = %scan(&siteids,&i, %str( ));

   %if &syssite=&tmp %then %let __license=; 
/*
    %if &syssite=&tmp and 
    (%upcase(&sysuserid)=JLI or %upcase(&sysuserid)=JWU or %upcase(&sysuserid)=IZA)  
    %then %let __license=;
*/
%end;

%if %length(&__license)<=0 %then %do;
%local todayd enddate2;
%let todayd = %sysfunc(date());
%let enddate2 = %sysfunc(mdy(%scan(&enddate,2, %str(-)), 
   %scan(&enddate,3, %str(-)), %scan(&enddate, 1,%str(-))));
   %if &todayd>&enddate2 %then %let __license = &enddate;  
/* %if %upcase(&sysuserid)=JWU and &todayd>&enddate2 %then %let __license = &enddate;*/
%end;

&__license

%mend;  
