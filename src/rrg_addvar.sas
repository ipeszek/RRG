/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 
 * 2020-05-26 added maxdec parameter (max number of decimals for continous stats)
 * 2020-06-16 added showneg0 parameter, see __cont for functionality 
 */

%macro rrg_addvar(
where=,
name=,
label=,
labelline=0,
suffix=,
stats=,
statsetid=, 
overallstats=,
skipline=Y,
indent=0,
align=,
basedec=0,
statdispfmt=$__rrgcf.,
statlabfmt=$__rrglf.,
pvfmt=__rrgpf.,
statdecinfmt=__rrgdf.,
keepwithnext=N,
templatewhere=,
popgrp=,
condfmt=,
condfmtstats=, /* not used */
maxdec=,
showneg0=N,
subjid=
)/store;


%local where name label labelline suffix stats statsetid
       skipline indent align basedec ovstats keepwithnext
       templatewhere popgrp condfmt condfmtstats maxdec showneg0 subjid;

%PUT STARTING RRG_ADDVAR USING VARIABLE &NAME;

%local nalign nstats;
%if &skipline = 1 %then %let skipline=Y;
%if %length(skipline)=0 %then %let skipline=Y;


data _null_;
  set __rrgconfig(where=(type='[D3]'));
  call symput(cats('n',w1),w2);
run;

%if %length(&stats)=0 %then %let stats=&nstats;
%if %length(&align)=0 %then %let align=&nalign;

%__rrgaddgenvar(
where=%nrbquote(&where),
templatewhere=%nrbquote(&templatewhere),
name=%nrbquote(&name),
label=%nrbquote(&label),
suffix=%nrbquote(&suffix),
stat=%nrbquote(&stats), 
skipline=%upcase(&skipline),
indent=&indent,
basedec=&basedec,
type=CONT,
popgrp=&popgrp,
ovstat=%nrbquote(&overallstats),
keepwithnext=&keepwithnext,
align=&align,
labelline=&labelline,
setid=%nrbquote(&statsetid),
sdfmt=%nrbquote(&statdispfmt),
slfmt=%nrbquote(&statlabfmt),
pvalfmt=%nrbquote(&pvfmt),
decinfmt=%nrbquote(&statdecinfmt),
condfmt=%nrbquote(&condfmt),
condfmtstats=%nrbquote(&condfmtstats),
maxdec=%nrbquote(&maxdec),
showneg0=%nrbquote(&showneg0),
outds=__varinfo,
subjid=%nrbquote(&subjid),
);



%put RRG_ADDVAR USING VARIABLE &NAME COMPLETED SUCESSULLY;

%mend;
