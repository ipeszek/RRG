/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro rrg_odds(
  dataset=,
  where=,
  trtvar=,
  groupvars=,
  var=,
  refvals=,
  subjid=,
  oddsfmt=6.2,
  alpha=0.05,
  label_or=%str(Odds Ratio vs _VS_),
  label_ci=_ALPHA_% CI for Odds Ratio vs _VS_,
  label_orci = Odds Ratio and _ALPHA_% CI vs _VS_
)/store;

%*-------------------------------------------------------------------------------
* RRG SUPPLEMENTAL MACRO FOR DISTRIBUTION ON SYSTEMS WITHOUT RRG INSTALLED
* THIS MACRO CALCULATES SIMPLE ODDS RATIO BASED ON RELATIVE RISK

* PARAMETERS:
*  DATASET         =  input dataset
*  WHERE           =  where clause to apply to input dataset
*  TRTVAR          =  name of treatment variable
*  GROUPVARS       =  names of grouping variables
*  VAR             =  name of analysis variable
*  REFVALS         =  the value(s) of analysis variables which are reference 
*                     (for pairwise comp)
*  SUBJID          = name of variabel denoting unique subject id
*  ODDSFMT         = format to display odds ratio
*  ALPHA           = alpha level for confidence intervals
*  LABEL_OR        = display label for ods ratio
*  LABEL_CI        = display label for CI for odds ratio 
*  LABEL_ORCI      = display label for odds ratio and CI

* DO NOT MODIFY THIS FILE IN ANY WAY

* 
* THIS PROGRAM IS PROVIDED "AS IS," WITHOUT A WARRANTY OF ANY KIND. ALL
* EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, INCLUDING
* ANY IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
* OR NON-INFRINGEMENT, ARE HEREBY EXCLUDED. IZABELLA PESZEK SHALL NOT
* BE LIABLE FOR ANY DAMAGES OR LIABILITIES SUFFERED BY LICENSEE AS A RESULT
* OF OR RELATING TO USE, MODIFICATION OR DISTRIBUTION OF THE SOFTWARE OR ITS
* DERIVATIVES. IN NO EVENT WILL IZABELLA PESZEK BE LIABLE FOR ANY LOST
* REVENUE, PROFIT OR DATA, OR FOR DIRECT, INDIRECT, SPECIAL, CONSEQUENTIAL,
* INCIDENTAL OR PUNITIVE DAMAGES, HOWEVER CAUSED AND REGARDLESS OF THE THEORY
* OF LIABILITY, ARISING OUT OF THE USE OF OR INABILITY TO USE SOFTWARE, EVEN
* IF IZABELLA PESZEK HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
 

%*-------------------------------------------------------------------------------;

%local  dataset where trtvar groupvars  var  refvals subjid oddsfmt alpha label_or label_ci
label_orci;



%if %length(&var)=0 %then %do;
%__rrg_oddsCond(
  dataset=%nrbquote(&dataset),
  where=%nrbquote(&where),
  trtvar=&trtvar,
  groupvars=&groupvars,
  refvals=%nrbquote(&refvals),
  subjid=&subjid,
  oddsfmt=&oddsfmt,
  alpha=&alpha,
  label_or=&label_or,
  label_ci=&label_ci,
  label_orci=&label_orci
);
%end;

%else %do;
%__rrg_odds(
  var = &var,
  dataset = %nrbquote(&dataset),
  where=%nrbquote(&where),
  trtvar = &trtvar,
  groupvars = &groupvars,
  refvals = %nrbquote(&refvals),
  subjid = &subjid,
  oddsfmt=&oddsfmt,
  alpha=&alpha,
  label_or=&label_or,
  label_ci=&label_ci,
  label_orci=&label_orci
 
);

%end;

data rrg_odds;
   set rrg_odds;
   output;
   __stat_name = cats("//", __stat_name);
   __stat_label = cats("//", __stat_label);
   output;
run;
%mend;
