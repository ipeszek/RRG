/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro rrg_addlabel(
label=,
skipline=N,
indent=0,
keepwithnext=Y,
wholerow=)/store;

%local label skipline indent keepwithnext wholerow;

%PUT STARTING RRG_ADDLABEL USING LABEL &LABEL;

%if &skipline = 1 %then %let skipline=Y;
%if %length(skipline)=0 %then %let skipline=N;

%__rrgaddgenvar(
label=%nrbquote(&label),
skipline=%upcase(&skipline),
indent=&indent,
keepwithnext=&keepwithnext,
type=LABEL,
wholerow=&wholerow,
outds=__varinfo);

data __timer;
	set __timer end=eof;
	output;
	if eof then do;
		task = "Finished analysing label";
		time=time();output;
	end;
run;	

%put RRG_ADDLABEL USING LABEL &LABEL COMPLETED SUCESSULLY;

%mend;
