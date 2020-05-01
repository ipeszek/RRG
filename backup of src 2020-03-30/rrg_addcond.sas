/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro rrg_addcond(
where=,
label=,
stats=npct, 
skipline=Y,
labelline=1,
indent=0,
templateds=,
overallstats=,
denom=,
denomgrp=,
grouping=N,
keepwithnext=N,
subjid=,
pctfmt=%nrbquote(__rrgp1d.),
denomwhere=,
DENOMINClTRT=Y,
templatewhere=,
show0cnt=y,
notcondition=N,
countwhat=subjid)/store;

%local where  label stats skipline indent templateds denom 
       grouping pctfmt denomwhere overallstats labelline
       keepwithnext subjid denomgrp templatewhere show0cnt
       notcondition countwhat DENOMINClTRT;

%put STARTING RRG_ADDCOND USING WHERE: &WHERE ;

%if %length(&denom) %then %let denomgrp=&denom;
%if &skipline = 1 %then %let skipline=Y;
%if %length(skipline)=0 %then %let skipline=Y;

%__rrgaddgenvar(
where=%nrbquote(&where),
label=%nrbquote(&label),
stat=%nrbquote(&stats), 
ovstat=%nrbquote(&overallstats),
skipline=%upcase(&skipline),
indent=&indent,
denom=%nrbquote(&denomgrp),
subjid=%nrbquote(&subjid),
denomwhere=%nrbquote(&denomwhere),
templateds=%nrbquote(&templateds),
type=COND,
pctfmt=%nrbquote(&pctfmt),
grouping=&grouping,
labelline=&labelline,
keepwithnext=%upcase(&keepwithnext),
templatewhere=%nrbquote(&templatewhere),
show0cnt=&show0cnt,
notcondition=&notcondition,
countwhat=&countwhat,
outds=__varinfo,
DENOMINClTRT=%upcase(&DENOMINClTRT)
);


data __timer;
	set __timer end=eof;
	output;
	if eof then do;
		task = "Finished analysing condition";
		time=time(); output;
	end;
run;	

%put RRG_ADDCOND USING WHERE: &WHERE COMPLETED SUCESSULLY;

%mend;
