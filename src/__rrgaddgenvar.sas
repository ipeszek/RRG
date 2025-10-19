/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 
 * 2002-05-26 added maxdec parameter (max number of decimals for continous stats)
 *    TODO: handle ordervar same as other parms
 *    2020-06-16 added showneg0 parameter, see __cont for functionality 
 *    2023-11-13 added statlabel parameter to modify display of statistic labels (N, %, etc)


*/
 

%macro __rrgaddgenvar(
where=,
popwhere=,
cond=,
name=,
decode=,
label=,
labelvar=,
labelline=0,
statlabel=,
statindent=,
suffix=,
stat=, 
ovstat=,
countwhat=all,
totaltext=,
misstext=,
totalpos=last,
misspos=last,
skipline=Y,
indent=0,
denom=,
denomwhere=,
DENOMINClTRT=,
popgrp=,
totalgrp=,
totalwhere=,
templatewhere=,
fmt=, 
codelist=,
codelistds=,
ordervar=,
basedec=1,
type=,
page=,
popsplit=,
align=,
statds=,
events=n,
worst=,
sortcolumn=,
cutoffcolumn=,
cutoffval=,
cutofftype=,
cutoffvar=,
freqsort=,
templateds=,
grouping=,
mincnt=,
minpct=,
delimiter=,
nline=,
newvalue=,
newlabel=,
splitrow=,
values=,
outds=,
model=,
setid=,
wholerow=,
showgroupcnt=,
showemptygroups=,
showmissing=Y,
show0cnt=,
noshow0cntvals=,
pct4missing=,
pct4total=,
parms=,
autospan=,
preloadfmt=,
keepwithnext=,
pctfmt=,
decinfmt=,
across=,
incolumn=,
colhead=,
subjid=,
delmods=,
sdfmt=,
slfmt=,
pvalfmt=,
notcondition=,
desc=,
condfmt=,
condfmtstats=,
maxdec=,
showneg0=,
eventcnt=,
aegroup=,
multiplier=)/store;

%local where popwhere cond name decode label labelline suffix stat countwhat 
       totaltext totalpos skipline indent denom denomwhere  popgrp fmt
       codelist codelistds ordervar basedec  type page align statds events  
       worst sortcolumn freqsort templateds  grouping mincnt minpct delimiter
       nline newvalue newlabel values outds  model setid showmissing 
       showgroupcnt showemptygroups pctfmt cutoffcolumn parms ovstat autospan
       splitrow preloadfmt pct4missing keepwithnext sdfmt decinfmt totalgrp
       totalwhere across incolumn colhead subjid misspos misstext delmods
       templatewhere show0cnt wholerow notcondition desc popsplit labelvar
       condfmt condfmtstats slfmt pvalfmt DENOMINClTRT noshow0cntvals pct4total
       maxdec showneg0 statlabel statindent eventcnt aegroup cutoffval cutofftype cutoffvar
       multiplier;




%* check how many records in __vlist dataset has any observations;
%local numvar dsid rc;
%let numvar = 0;
%let dsid=%sysfunc(open(&outds));
%let numvar = %sysfunc(attrn(&dsid, NOBS));
%let rc= %sysfunc(close(&dsid));

%let numvar = %eval(&numvar+1);
%if %upcase(&across)=Y  %then %do;
    %let numvar = %eval(&numvar+1000);
%end;
/*
%if %upcase(&incolumn)=Y %then %do;
    %let numvar = %eval(&numvar-1000);
%end;
*/
%if "%upcase(&skipline)" ne "Y" %then %let skipline=N;


data __tmp;
  if 0;
run;


data __tmp;
length name fmt  decode align countwhat ordervar type statds page basedec eventcnt $ 20 
       delimiter nline  showmissing showgroupcnt showemptygroups wholerow
       autospan splitrow pct4missing keepwithnext across incolumn skipline show0cnt 
       notcondition desc popsplit DENOMINClTRT pct4total statindent aegroup $ 1
       cond where popwhere label suffix stat codelist codelistds denomwhere  
       denom worst totaltext events templateds sortcolumn freqsort mincnt 
       minpct popgrp newvalue values newlabel model statsetid cutoffcolumn 
       parms ovstat totalgrp totalwhere colhead delmods labelvar condfmt pvalfmt condfmtstats 
       noshow0cntvals statlabel $ 2000 pctfmt  preloadfmt decinfmt 
       sdfmt subjid maxdec showneg0 $ 40;
  eventcnt= strip(symget("eventcnt"));  
  events='';
  delmods = (trim(left(symget("delmods"))));  
  desc = (trim(left(symget("desc")))); 
  subjid=(trim(left(symget("subjid"))));
  sortcolumn=(trim(left(symget("sortcolumn"))));
  sortcolumn=tranwrd(sortcolumn,',',' ');
  parms = (trim(left(symget("parms"))));
  cutoffcolumn=(trim(left(symget("cutoffcolumn"))));
  cutoffval=(trim(left(symget("cutoffval"))));
  cutoffvar=(trim(left(symget("cutoffvar"))));
  cutofftype=upcase((trim(left(symget("cutofftype")))));
  freqsort=(trim(left(dequote(symget("freqsort")))));
  notcondition=(trim(left(dequote(symget("notcondition")))));
  varid = &numvar;
  type=upcase(trim(left(symget("type"))));
  worst=trim(left(symget("worst")));
  countwhat=upcase(trim(left(symget("countwhat"))));
  totalpos=upcase(trim(left(symget("totalpos"))));
  wholerow=upcase(trim(left(symget("wholerow"))));
  misspos=upcase(trim(left(symget("misspos"))));
  totaltext=trim(left(symget("totaltext")));
  misstext=trim(left(symget("misstext")));
  splitrow=dequote(trim(left(symget("splitrow"))));
  cond=trim(left(symget("cond")));
  name=trim(left(symget("name")));

  where=cats("(",trim(left(symget("where"))),")");
  where=tranwrd(where, '"',"'");
  if compress(where, '()')='' then where='';

  popwhere=cats("(",trim(left(symget("popwhere"))),")");
  popwhere=tranwrd(popwhere, '"',"'");
  if compress(popwhere, '()')='' then popwhere='';

  totalwhere=cats("(",trim(left(symget("totalwhere"))),")");
  totalwhere=tranwrd(totalwhere, '"',"'");
  if compress(totalwhere, '()')='' then totalwhere='';

  denomwhere=cats("(",trim(left(symget("denomwhere"))),")");
  denomwhere=tranwrd(denomwhere, '"',"'");

  if compress(denomwhere, '()')='' then denomwhere='';

  templatewhere=cats("(",trim(left(symget("templatewhere"))),")");
  templatewhere=tranwrd(templatewhere, '"',"'");

  if compress(templatewhere, '()')='' then templatewhere='';
    
  
  totalgrp=trim(left(symget("totalgrp")));
  popgrp=trim(left(symget("popgrp")));
  statds=trim(left(symget("statds")));
  label=trim(left(dequote(symget("label"))));
  labelvar=trim(left(dequote(symget("labelvar"))));
  statlabel=trim(left(dequote(symget("statlabel"))));

  labelline=&labelline;
  decode=trim(left(symget("decode")));
  align=trim(left(symget("align")));
  suffix=dequote(trim(left(symget("suffix"))));
  basedec=trim(left(symget("basedec")));
  stat=trim(left(symget("stat")));
  ovstat=trim(left(symget("ovstat")));
  skipline = upcase("&skipline");
  show0cnt = upcase("&show0cnt");
  indent=&indent;
  page = upcase(trim(left(symget("page"))));
  popsplit = upcase(trim(left(symget("popsplit"))));
  grouping = upcase(trim(left(symget("grouping"))));
  denom=upcase(trim(left(symget("denom"))));
  fmt=upcase(trim(left(symget("fmt"))));
  codelist=trim(left(symget("codelist")));
  codelistds=trim(left(symget("codelistds")));
  templateds=trim(left(symget("templateds")));
  ordervar=trim(left(symget("ordervar")));
 
  denom=trim(left(symget("denom")));
  DENOMINClTRT=upcase(trim(left(symget("DENOMINClTRT"))));
  
  
  mincnt=trim(left(symget("mincnt")));
  minpct=trim(left(symget("minpct")));
  delimiter=trim(left(symget("delimiter")));
  newvalue=trim(left(symget("newvalue")));
  newlabel=trim(left(symget("newlabel")));
  values=trim(left(symget("values")));
  nline=trim(left(symget("nline")));;
  model=trim(left(symget("model")));;
  statsetid = dequote(trim(left(symget("setid"))));;
  showgroupcnt = upcase(trim(left(symget("showgroupcnt"))));
  showemptygroups = upcase(trim(left(symget("showemptygroups"))));
  pct4missing = upcase(trim(left(symget("pct4missing"))));
  pct4total = upcase(trim(left(symget("pct4total"))));
  statindent = upcase(trim(left(symget("statindent"))));
  keepwithnext = upcase(trim(left(symget("keepwithnext"))));
  showmissing = upcase(trim(left(symget("showmissing"))));
  autospan = upcase(trim(left(symget("autospan"))));
  pctfmt = upcase(trim(left(symget("pctfmt"))));
  preloadfmt = upcase(trim(left(symget("preloadfmt"))));
  decinfmt = upcase(trim(left(symget("decinfmt"))));
  sdfmt = upcase(trim(left(symget("sdfmt"))));
  slfmt = upcase(trim(left(symget("slfmt"))));
  pvalfmt = upcase(trim(left(symget("pvalfmt"))));
  across = upcase(trim(left(symget("across"))));
  incolumn = upcase(trim(left(symget("incolumn"))));
  colhead = upcase(trim(left(symget("colhead"))));
  
  condfmt = upcase(trim(left(symget("condfmt"))));
  condfmtstats=upcase(trim(left(symget("condfmtstats"))));

  noshow0cntvals=upcase(trim(left(symget("noshow0cntvals"))));
  maxdec = upcase(trim(left(symget("maxdec"))));
  showneg0 = upcase(trim(left(symget("showneg0"))));
  aegroup = upcase(trim(left(symget("aegroup"))));
  multiplier = upcase(trim(left(symget("multiplier"))));

  output;
run;

%if %length(&ordervar)<=0 %then %do;
  %let ordervar=&name;
%end;



data &outds;
set &outds __tmp;
run;


  


%mend;
