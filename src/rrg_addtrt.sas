/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro rrg_addtrt(
name=,
label=,
decode=,
suffix=,
nline=Y,
totaltext=,
sortcolumn=,
cutoffcolumn=,
incolumns=,
autospan=,
splitrow=,
across=Y,
remove=
)/store;


%* totaltext seems to be never used;

%local name label decode suffix nline totaltext sortcolumn 
       incolumns cutoffcolumn autospan splitrow across remove;

%put STARTING RRG_ADDTRT USING VARIABLE &NAME;

%if %length(&incolumns)>0 %then %let across=&incolumns;

%if %length(&cutoffcolumn) %then %do;
data _null_;
  length tmp $ 2000;
  cc = dequote(symget("cutoffcolumn"));
  do i=1 to countw(cc, ' ');
    tmp = cats(tmp)||" "||quote(dequote(scan(cc,i,' ')));
  end;
  tmp = tranwrd(tmp,'"',"'");
  call symput("cutoffcolumn", cats(tmp));
run;

%end;

%if %length(&autospan)=0 %then %do;

data _null_;
  set __rrgconfig(where=(type='[D2]'));
  call symput(w1,w2);
run;

%end;


%__rrgaddgenvar(
name=%nrbquote(&name),
label=%nrbquote(&label),
decode=%nrbquote(&decode),
suffix=%nrbquote(&suffix),
sortcolumn=%nrbquote(&sortcolumn),
cutoffcolumn=%nrbquote(&cutoffcolumn),
outds=__varinfo,
nline=&nline,
totaltext=%nrbquote(&totaltext),
splitrow = %nrbquote(&splitrow),
type=TRT,
autospan=%nrbquote(&autospan),
across=&across,
delmods=%nrbquote(&remove)
);

data __timer;
	set __timer end=eof;
	output;
	if eof then do;
		task = "Finished analysing trt";
		time=time(); output;
	end;
run;	

%put RRG_ADDTRT USING VARIABLE &NAME COMPLETED SUCESSULLY;

%mend;