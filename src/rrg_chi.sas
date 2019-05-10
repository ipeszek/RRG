/*
 * RRG: statistical reporting system.
 *  
 * This file is part of the RRG project (https://github.com/ipeszek/RRG) which is released under GNU General Public License v3.0.
 * You can use RRG source code for statistical reporting but not to create for-profit selleable product. 
 * See the LICENSE file in the root directory or go to https://www.gnu.org/licenses/gpl-3.0.en.html for full license details.
 */

%macro rrg_chi(
  dataset=,
  where=,
  trtvar=,
  groupvars=,
  var=,
  refvals=,
  subjid=,
  label_pval=%str(p-Value),
  label_opval=%str(p-Value),
  pvalf=__rrgpf.
)/store;

%*-------------------------------------------------------------------------------
* RRG SUPPLEMENTAL MACRO FOR DISTRIBUTION ON SYSTEMS WITHOUT RRG INSTALLED
* THIS MACRO CALCULATES P-VALUE FROM CHI-SQUARE DISTRIBUTION

* PARAMETERS:
*  DATASET         =  input dataset
*  WHERE           =  where clause to apply to input dataset
*  TRTVAR          =  name of treatment variable
*  GROUPVARS       =  names of grouping variables
*  VAR             =  name of analysis variable
*  REFVALS         =  the value(s) of analysis variables which are reference 
*                     (for pairwise comp)
*  SUBJID          = name of variabel denoting unique subject id
*  LABEL_PVAL      = display label for pairwise p-values
*  LABEL_OPVAL     = display label for pairwise p-value
*  PVALF           = format to display p-values

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

%local  dataset where trtvar groupvars  var  refvals subjid label_pval 
        label_opval pvalf;


%if %length(&var)=0 %then %do;
%__rrg_chiCond(
  dataset=%nrbquote(&dataset),
  where=%nrbquote(&where),
  trtvar=&trtvar,
  groupvars=&groupvars,
  refvals=%nrbquote(&refvals),
  subjid=&subjid,
  label_pval=&label_pval,
  label_opval=&label_opval,
  pvalf=&pvalf
);
%end;

%else %do;
%__rrg_chi(
  var = &var,
  dataset = %nrbquote(&dataset),
  where=%nrbquote(&where),
  trtvar = &trtvar,
  groupvars = &groupvars,
  refvals = %nrbquote(&refvals),
  subjid = &subjid,
  label_pval=&label_pval,
  label_opval=&label_opval,
  pvalf=&pvalf

);

%end;

data rrg_chi;
   set rrg_chi;
   output;
   __stat_name = cats("//", __stat_name);
   __stat_label = cats("//", __stat_label);
   output;
run;
%mend;
