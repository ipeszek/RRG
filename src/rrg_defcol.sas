/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro rrg_defcol(
 /* formula=,*/
  name=,
  format=,
  decode=,
  label=,
  width=,
  group=,
  page=,
  spanrow=,
  align=,
  halign=,
  dist2next=,
  skipline=,
  stretch=,
  breakok=,
  keeptogether=,
  id=)/store;

 %* -----------------------------------------------------------------------
  adds records to __listinfo dataset with properties of listing column
  macro parameters:

      formula     name of variable or SAS expression to create variable
      name        name of the variable 
      decode      decode to use with variable
      format       format to use to print variable
      label       label to put in column header (or before value if
                  page=Y). Use /-/ to indicate splitting label into header
                  "levels". Always enclose label in quotes.
      width       width of the column (e.g. 2in)
                  alternatively allow for automatic calculations:
                  Use N (no wrapping), LW (words are not allowed to wrap) or
                  NH (no wrapping including header) 
                  LW (words are not allowed to wrap including header) 
      align       alignment of text in the column. Use L (left, default),
                  R (right), C (center), D (decimal) or RD (right-decimal)
      halign      alignment for headers
      dist2next   overrides defautl column spacing between this and next column
      page        Y or blank. If Y, this is "page by" variable the value
                   is printed on top of every page. Note: all columns
                   designated as PAGE columns must appear, in order of definition,
                   in ORDERBY parameter of rrg_deflist, before GROUP columns.
                   Define PAGE columns before all other columns
      spanrow     Y or blank. If Y, this is grouping variable that is to be printed
                  spanning all columns. It is printed
                   is printed on change in value (and on top of new page, below headers).
                   Note: all columns
                   designated as SPANROW columns must appear, in order of definition,
                   in ORDERBY parameter of rrg_deflist.
                   Define SPANROW columns after PAGE columns
                   and before all other columns
      group       Y or blank. If Y, this is grouping column and the value
                   is printed on change in value (and on top of new page). Note: all columns
                   designated as GROUP columns must appear, in order of definition,
                   in ORDERBY parameter of rrg_deflist.
                   Define GROUP  columns after PAGE and SPANROW columns
                   and before all other columns
     skipline     Y or blank. Ignored unless this  is GROUP variable. If Y then blank line is printed 
                  before  value changes.             
      id          Y or blank. The last column identified with ID=Y implies that all
                  prceedign columns are also ID columns. ID columns are repeated
                  if "page" has to be split vertically into multiple pages
                  (because it si to wide)
     stretch      Y or N. If N, column is not stretched 
  keeptogether    Y or N (for grouping variable). If yes, the group is not allowed to break in the midddle         



   Use // to indicate new line, and /t1, /t2 etc to indicate tab
   
   ds used __listinfo
   ds initialized __listinfo (if does not exist)
   ds created none
   ds updated   __listinfo (if exists)


  -----------------------------------------------------------------------;

  %local formula format decode name label width  group 
         spanrow align page id skipline stretch breakok
         halign dist2next keeptogether ;

  %local varid;
  %let varid=0;

  %if &skipline = 1 %then %let skipline=Y;
  %if %length(skipline)=0 %then %let skipline=Y;

  
%* check if __listinfo exist, if not, create it.;

%if %sysfunc(exist(__listinfo))=0 %then %do;
  data __listinfo;
    if 0;
    length label $ 2000
    width align halign alias  format decode dist2next $ 40
    group page spanrow id skipline stretch keeptogether breakok $ 1
    ;

  

    varid=.;
    format = '';
    decode = '';
    label = '';
    align = '';
    halign = '';
    dist2next = '';
    group = '';
    page = '';
    spanrow = '';
    id = .;
    alias = '';
    width = '';
    skipline ='';
    stretch = '';
    breakok= '';
    keeptogether= '';
  run;
%end;

  
%* check how many records in __vlist dataset has any observations;
%local numvar dsid rc;
%let numvar = 0;
%let dsid=%sysfunc(open(__listinfo));
%let numvar = %sysfunc(attrn(&dsid, NOBS));
%let rc= %sysfunc(close(&dsid));

%if &numvar=0 %then %let varid=1;
%else %let varid = %eval(&numvar+1);
%if %length(&width)=0 %then %let width=LWH;


  

  data __tmp;
    length /*formula */label $ 2000
    width align halign alias  format decode  dist2next $ 40
    group page spanrow id skipline stretch keeptogether  breakok $ 1
    ;

  

    varid=&varid;
    format = cats(symget("format"));
    decode = cats(symget("decode"));
    label = cats(symget("label"));
    align = cats(symget("align"));
    halign = cats(symget("halign"));
    dist2next = cats(symget("dist2next"));
    group = cats(symget("group"));
    page = cats(symget("page"));
    spanrow = cats(symget("spanrow"));
    id = cats(symget("id"));
    alias = cats(symget("name"));
    width = cats(symget("width"));
    skipline = upcase(cats(symget("skipline")));
    stretch = cats(symget("stretch"));
    breakok= cats(symget("breakok"));
    keeptogether= upcase(cats(symget("keeptogether")));
  run;

  proc append base=__listinfo data=__tmp;
  run;
 


    
%mend;
