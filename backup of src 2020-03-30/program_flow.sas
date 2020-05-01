/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

/*
RRg_Execute

1. TRTVAR = 1st variable added via add_trt (other are ignored) *** ensure on add_trt level;
2. NUMTRT = 0 of no trtvars are specified, 1 otherwise;

3. call makenewtrt macro:
   if numtrt=0 then create __dataset, applying &popwhere, and create variables 
    __trt, __suff___trt __dec___trt __nline___trt
    __dec___trt gets 'Combined Total', unless there is something added with blank name then it gets ''
    __nline___trt gets Y , unless there is something added with blank name then it gets N
    
    if numtrt>0 (=1) then create pooled treatment groups (if requested - only where type='NEWTRT)
       the get __grouped=1 (for nonpooled, __grouped=0)
    and add variables __nline_&trtname __suff_&trtname __dec_&trtname

4. If __dataset has 0 obs then skip to table generatign step

5. if numtrt=0 then set numtrt=1 and trtvar=__trt (makenewtrt created this variable)

6. groupby = all grouping variables with page ne Y, ngrpv = their number
   varby   =  all grouping variables with page = Y, nvarby = their number
     vb1, vb2, .. vbNVARBY: all varby variables
     
7. create dataset __pop with population count abd variables
    &varby __grouped &trt1 __dec_&trt1 __suff_&trt1 __nline_&trt1 __pop1
    
8. Cross-join __pop dataset (all distinct __grouped &trt1 __dec_&trt1 __suff_&trt1 __nline_&trt1 __pop1)
       with all combinations of varby variables; 
       if __grpid=.  then __grpid=999
       after that all records in __pop get __grpid=999
       
9. Create __trtid variable (1,2,3,...) for each valye of trt variable;
   merge into __pop and __dataset
   MAXTRT= number of distinct values of __TRTID
   
10 dataset __pop: __rowid=1, __col = display text for treatment variable, __grpid=999

11. For each grouping variable GRPX, if   codelist is specified then
    create codelist dataset   __grp_template_GRPX 
    (makecodesds) macro
    if decode was given for variable then this dataset has &decode variable,
    otherwise decode variable = __decode_varname, and __varinfo is updated with this name for decode
    it also has __order_varname variable
    
    *** T0DO: what of codelistds given for grouping variable? I think it is not allowed?
    
12. cross-join all datasets __grp_template_GRPX into __grpcodes_exec 
    in this dataset we have variables __order_grpname1, __order_grpname2, ..., __order_grpnameX
    (X = number fo all grouping variables)
    they are missing if grouping variable did not have codelist specified; otherwise they are taken from 
    codelist
    
    in __rrgpgminfo: create record with key  = isgrptemplate, value= Y
    at run time, create dataset __grpcodes (same as __grpcodes_exec)    
    at run time, create dataset __grptemplate (same as __grpcodes_exec)
    
    these datasets are not created if none of grouping variables have  codelist given 
    
13. record in__rrgpgminfo: 
       key=newgroupby, value = &groupby
       key=oldgroupby, value = &groupby
       
*******************************************************************************************
                                                                               TODO EXPLAIN
do calculations for each analysis block

CAT, CONT,LABEL: __grptype=1
COND: __grptype assigned by %__cond macro: XXXXXXX 


*******************************************************************************************

14. results from all calculations are set together in __all dataset
    __sid=1
    
15. If __all has no records, skip to table generatign step


********************************************************************************************
16.    add overall statistics to __all and __poph                              TODO EXPLAIN
********************************************************************************************

17. add grouping variabel labels:
    collect all decodes for groupign variables and for varby variables
    
    if  __rrgpgminfo has no records with key  = isgrptemplate, value= Y:
        create dataset __grpdisp which has all distinct combos of all &varby and &grp1 variables
        and their decodes
        (from __dataset)
        ordered by &varby &grp1
        create variables __order_GRPX=. (x=1,... . &ngrpv)
    
    if  __rrgpgminfo has a record with key  = isgrptemplate, value= Y:
     create dataset __grpdisp which has all distinct combos of al &varby and &grp1 variables
     and their decodes
        (from __grptemplate)
        ordered by &varby &grp1
        create variables __order_GRPX=. (x=1,... . &ngrpv)
        
        merge __all with __grpdisp by &varby &grp1 (keeping only records in __all)
        create __varbylab (using all &varby variables) and __grplabel_&grp1
        
        for all remaining &grouby variables:
          create dataset __grpdisp which has all distinct combos of all &varby and &grp1 variables
          and their decodes
        (from __dataset if no __grptemplate dataset, or from __grptemplate if exist)
        ordered by &varby &grp1 &grp2 ...
        
        merge with __all and create __grplabel_&grp2, __grplabel_grp3 etc
        if __grpid=. then __grpid=0;  *********************************************how can it happen?
        (__grpid is created by __getcntg macro)
        
18. if __grpcodes exits, merge it (using natural join) with __all dataset
       this brings all __order_&grpK variables into dataset __all*************************why do we need this step?
    redefine groupby by adding __order_&grpX variables: 
      groupby = __order_&grp1  &grp1 ... &__order_&grpX __grpX
      (x=1 to &ngrpv)
      
      update __rrgproginfo : keuy- newgroupby, value=&groupby
      
19. **************** transposeg;

20. In __poph, set __nospanh=0; *** FIX!;

21. **************** transposet;

22. **************** transposes;
      
*/              
