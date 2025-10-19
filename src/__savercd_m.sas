/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro __savercd_m/store;
 %local rrgoutpathlazy ;
 %let rrgoutpathlazy=&rrgoutpath;
 %local __path;
 
  %if %length(&rrgoutpath)=0 %then %let __path=&rrgoutpathlazy;
  %else %let __path = &rrgoutpath;
  
  libname out "&__path";
 
  *---------------------------------------------------------;
  *  SAVE RCD DATASET;
  *---------------------------------------------------------;
 
  
    data __tmp ;
        length __varbylab $ 2000;
          set %do i=1 %to &rrgtablepartnum; rrgtablepart&i %end;;;
       
    
         if 0 then do;
            __dsid=.;
            __tcol='';
            __gcols='';
            __datatype='';
            __varbygrp=.;
            __varbylab='';
            __vtype='';
            __fname='';
            __rowid=.;
            __col_0='';
            %do i=1 %to 14;
              __footnot1='';
            %end;
              
            
            __title1='';
            __title2='';
            __title3='';
            __title4='';
            __title5='';
            __title6='';
            __shead_l='';
            __shead_m='';
            __shead_r='';
            __sfoot_l='';
            __sfoot_m='';
            __sfoot_r='';
            __nodatamsg='';
            __align='';
            __suffix='';
            __keepn=.;
            __blockid=.;
            __indentlev =.;
            __dsid=.;
            __first=.;
            __next_indentlev=.;
            __tablepart=.;
          end;
          
        
          
        run;
        
        
%macro unmakestring(name);
    %local name;
  
    &name=tranwrd(strip(&name),"/#0034 ",'"');
    &name=tranwrd(strip(&name),"/#0039 ","'");
   /*  &name=tranwrd(strip(&name),"/#0040 ",'('); */ 
   /** 2024-09-27;*/
   /*  &name=tranwrd(strip(&name),"/#0041 ",')'); */
    /** 2024-09-27;*/

    /* record=  "__"|| "&name="||'"'|| strip(&name)||'";';  output; */
%mend;  

        
         data out.&rrguri (compress=YES);
        
        
    
         retain __col_:  __rowid __datatype __varbygrp __varbylab __vtype 
                __indentlev  __next_indentlev __align __suffix __keepn __blockid 
               __dsid __tcol __gcols __first:  __fname __cell: __topborderstyle 
              __bottomborderstyle __foot: __title: __shead_: __sfoot_: __nodatamsg;
         set __tmp end=eof;
         if eof then __last=1;
         
         if __datatype='RINFO' then do;
            %unmakestring(__nodatamsg);


            %do jj=1 %to 6;
              %unmakestring(__title&jj);
            %end;

            %do jj=1 %to 14;
              %unmakestring(__footnot&jj);
            %end;

           
            %unmakestring(__shead_l); 
            %unmakestring(__shead_r); 
            %unmakestring(__shead_m );
            %unmakestring(__sfoot_r );
            %unmakestring(__sfoot_l );
            %unmakestring(__sfoot_m );
            %unmakestring(__sprops); 
      
         end;


         keep __datatype __vtype __rowid __col_: __foot: __title: __next_indentlev 
          __shead_: __sfoot_: __nodatamsg __align __suffix __keepn __blockid __cell:
          __indentlev __dsid __tcol __gcols __first: __last: __varbygrp __varbylab __fname 
          __topborderstyle __bottomborderstyle __tablepart;
          
        run;
   
  
  
%mend;    
