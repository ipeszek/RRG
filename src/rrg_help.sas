
%macro rrg_help(what);

options nomlogic nosymbolgen;


%local what;


%if %upcase(&what)=RRG_INIT  %then %do;

%put ;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put RRG_INIT macro is  required to be called before any  other RRG macros;
%put ;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put REQUIRED PARAMETERS:;
%put;
%put;
%PUT URI:        the string <=32 characters, must comply with sas dataset naming requirements;
%put %str(           )_the rtf/pdf and optional  RCD dataset will be named %nrstr(&uri).rtf/pdf/sas7bdat;
%put ;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put OPTIONAL PARAMETERS:;
%PUT;
%PUT;
%put OUTNAME:    the name of output rft/pdf file. If specified, rtf/pdf files will be name using %nrstr(&outname);
%put %str(           )_and the optional RCD dataset will be named using %nrstr(&uri);
%PUT;
%PUT TABLEPART:  (integer starting with 1): for multi-part tables, sequential number corresponding to each table part;
%PUT;
%PUT PURPOSE:    the text to be inserted in the header of the generated RRG program, describing program purpose;


%end;



%else %if %upcase(&what)=RRG_DEFREPORT  %then %do;

%put ;
%put RRG_DEFREPORT macro defines general proterties of the report;
%put;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put REQUIRED PARAMETERS:;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put;
%put;
%put DATASET:     name of the input dataset, e.g.:;
%put %str(             )dataset=final;
%put %str(             )dataset=ads.adsl(where=(saffl='Y'));
%put;
%put ;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put OPTIONAL PARAMETERS:;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put;
%put;
%put TITLE1 - TITLE6: titles;


%put;
%put FOOTNOT1 - FOOTNTOT14: footnotes ;
%put;
%put BOOKMARK_PDF:   If specified, bookmarks in PDF file are created from report titles. ;
%PUT %str(                )Example: BOOKMARK_PDF=Title1 title2 or BOOKMARK_PDF=%str(Title4 Title1-Title3);
%put;

%put BOOKMARK_RTF:   Has the same syntax as bookmarks_pdf, but refers to bookmarks in rtf file. ;
%PUT %str(                )However, current version of Microsoft Word RTF interpreter no longer supports Headings to Bookmark functionality;
%put;

%put POPWHERE:       where clause to be applied to the %nrstr(&dataset) before anything else is being done;
%put;

%put TABWHERE:       where clause to be applied to the %nrstr(&dataset) after N for header is calculated ;
%put %str(                )and before anything calculations for the table body are performed;

%put COLHEAD1:       Header for the first column(s). Use "!" as a separator. ;
%put %str(                )For example, if the 1st column shows Parameter and the 2nd column shows Visit, you can specify;
%put %str(                )COLHEAD1=Parameter!Visit;

%put;
%put COLWIDTHS:      A string of tokens specifying column widths. Each token is a number with unit, with no spaces, e.g. 1in or 3cm or 30pt;
%put %str(                )If only one token is specifued, it is applied to 1st column ;
%put %str(                )and RRG determines automatically the widths of the remaining columns;
%put %str(                )If >1 token is specified, e.g., COLWIDTHS=2in 1in, then the last token is applied to all remaining columns;
%put %str(                )If STRETCH=Y (see below) then the requested widths may be increased proportionally so that the table uses ;
%put %str(                )all available width of a page;
%put %str(                )It is strongly recommended to leave thsi parameter blank and let RRG calculate column widths automatically;


%put;
%put STRETCH:        Y (default) | N  (case insensitive) ;
%put %str(                )If set to Y then columns are proportionally stretched to use all available space on a page.;
%put %str(                )If set to N then columns widths are exactly as requested or as automatically calculated, ;
%put %str(                )which may result in a narrower table;

%put;
%put REPTYPE:        REGULAR (default) | EVENTS (case insensitive) ;
%put %str(                )type of the report, affecting how grouping variables and missing values are handled.;
%put %str(                )use REPTYPE=EVENTS for AE, CM, MH, PR and similar occurence-based tables;

%put;
%put EVENTCNT:       N (default) | Y | Y(SE) | Y (ES) (case insensitive) ;
%put %str(                )applicable only if REPTYPE=EVENTS. ;
%put %str(                )If set to N, only the count of subjects is produced.;
%put %str(                )If set to Y or Y(SE), each treatment column is split into 2 columns, one with the count of subjects ;
%put %str(                )followed by another with counts of events ;
%put %str(                )If set to Y(ES), each treatment column is split into 2 columns, one with the count of events ;
%put %str(                )followed by another with counts of subjects ;
%put %str(                )If set to Y, only the count of events is produced.;
%put %str(                )NOTE: if RRG_ADDCOND.COUNTWHAT=EVENTS then RRG_DEFREPORT.EVENTCNT is ignored;


%put;
%put STATSINCOLUMN:  N (default) | Y  (case insensitive) ;
%put %str(                )If set to Y then the names of the statistics are shown in a separate column;


%put;
%put STATSACROSS:    N (default) | Y  (case insensitive) ;
%put %str(                )If set to Y then the each statistic is shown in a separate column;


%put;
%put STATSINCOLUMNS: N (default) | Y  (case insensitive) ;
%put %str(                )DEPRECATED. Has the same effect as STATSACROSS;



%put;
%put PRINT:          Y (default) | N  (case insensitive) ;
%put %str(                )If set to N then RCD dataset is created but pdf/rtf files are not;


%put;
%put POOLED4STATS:   N (default) | Y  (case insensitive) ;
%put %str(                )If set to Y then treatment created in RRG_ADDTRT are included in the dataset passed to plugin macros;

%put;
%put APPEND:         N (default) | Y  (case insensitive) ;
%put APPENDABLE:     N (default) | Y  (case insensitive) ;
%put %str(                )Used to "knit" 2 or more RRG outputs into a single file. The outputs can have completely different structure;
%put %str(                )Tables can be combined with listings;
%put %str(                )Set to APPEND=N AND APPENDABLE=Y on the first table/listing (opens rtf output stream and leaves it open);
%put %str(                )Set to APPEND=Y AND APPENDABLE=N on the last table/listing (closes rtf output stream);
%put %str(                )Set to APPEND=Y AND APPENDABLE=Y on all other contributing parts in the middle;

%put;
%put DEBUG:          positive integer. Default is 0.;
%put %str(                )If >0 then some debugging messages are printed to the log;


%put;
%put LOWMEMORYMODE:  Y (default) | N;
%put %str(                )Controls how RRG generator behaves. If file I/O is slow then setting LOWMEMORYMODE= N may improve performance.;

%put ;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put OPTIONAL PARAMETERS WHICH OVERRIDE SETTINGS IN CONFIG.INI FILE;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put;


%put;
%put DEST:           APP (default) | CSR (case insensitive) ;
%put %str(                )Determines whether report properties are read from APP section or from CSR section of config.ini file ;
%put;

%put SUBJID:         name of the variable corresponding to subject ;

%put;
%put SAVERCD:        N | Y  (case insensitive) ;
%put %str(                )If set to Y, the RCD dataset is saved parmanently in %nrstr(&rrgoutpath) folder;

%put;
%put INDENTSIZE:     positive integer (default=2);
%put %str(                )the size of (in points) of a single indent (i point corresponds roughly to the width of letter "m");

%put;
%put NODATAMSG:      A text to display in the table if there is no data. ;
%put %str(                )Superseeds the NODATA text from config.ini file ;
%put;


%put;
%put WARNONNOMATCH:  N (default) | Y  (case insensitive) ;
%put %str(                )If set to N then it has no efect ;
%put %str(                )If set to Y then it applies only to the variables for which codelist or preloadfmt was specified. ;
%put %str(                )If a value is encountered that does not appear in codelist then a warning will be printed in the log file;


%put;
%put PAPERSIZE:      paper size, e.g. A4 or LETTER ;

%put;
%put ORIENT:         orientation, e.g. P (for portrait) or L (for landscape) ;

%put;
%put FONT:           font family, e.g. Helvetica or TimesNewRoman. See config file for supported fonts;

%put;
%put FONTSIZE:       font size.See config file for supported fonts;

%put;
%put MARGINS:        size of the margins, in order T L R B, e.g. 1in 0.5in 0.5in 0.7in;

%put;
%put SYSTITLE:       DEPRECATED. The title shown on the top of the page;
%put %str(                 )superseeded by shead_l , shead_m and shead_r in config.ini file;



%put ;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put OPTIONAL PARAMETERS MAINTAINED FOR BACKWARD COMPATIBILITY;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put;

%put;
%put ADDLINES:       small integer>0. If page rendering is incorrect, sometimes specifying this parameter fixes the issue;
%put EXTRALINES:     small integer>0. If page rendering is incorrect, sometimes specifying this parameter fixes the issue;



%put ;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put OPTIONAL PARAMETERS WHICH SPECIFIES SOME OUTPUT RENDERING OPTONS (BEST NOT TO MODIFY);
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put;

%put;
%put COLSPACING:     Distance between columns. Default is 1ch (1 character);

%put;
%put SPLITCHARS:     Characters defining word boundaries. Default is %Str(- );

%put;
%put ESC_CHAR:       RTF Escape character. Default is %str(/);

%put;
%put RTF_LINESPLIT:  CALC | HYPHEN. Method to achieve soft line breaks. Default is HYPHEN;




%end;




%else %if %upcase(&what)=RRG_DEFLIST  %then %do;

%put ;
%put RRG_DEFLIST macro defines general proterties of the report;
%put;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put REQUIRED PARAMETERS:;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put;
%put;
%put DATASET:     name of the input dataset, e.g.:;
%put %str(             )dataset=final;
%put %str(             )dataset=ads.adsl(where=(saffl='Y'));
%put;
%put ;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put OPTIONAL PARAMETERS:;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put;
%put;
%put TITLE1 - TITLE6: titles;


%put;
%put FOOTNOT1 - FOOTNTOT14: footnotes ;
%put;
%put BOOKMARK_PDF:   If specified, bookmarks in PDF file are created from report titles. ;
%PUT %str(                )Example: BOOKMARK_PDF=Title1 title2 or BOOKMARK_PDF=%str(Title4 Title1-Title3);
%put;

%put BOOKMARK_RTF:   Has the same syntax as bookmarks_pdf, but refers to bookmarks in rtf file. ;
%PUT %str(                )However, current version of Microsoft Word RTF interpreter no longer supports Headings to Bookmark functionality;
%put;


%put;
%put ORDERBY         list of variables to sort dataset prior to creating a listing;
%put %str(                )Not all the variables have to appear in the report;

%put;
%put PRINT:          Y (default) | N  (case insensitive) ;
%put %str(                )If set to N then RCD dataset is created but pdf/rtf files are not;


%put;
%put APPEND:         N (default) | Y  (case insensitive) ;
%put APPENDABLE:     N (default) | Y  (case insensitive) ;
%put %str(                )Used to "knit" 2 or more RRG outputs into a single file. The outputs can have completely different structure;
%put %str(                )Tables can be combined with listings;
%put %str(                )Set to APPEND=N AND APPENDABLE=Y on the first table/listing (opens rtf output stream and leaves it open);
%put %str(                )Set to APPEND=Y AND APPENDABLE=N on the last table/listing (closes rtf output stream);
%put %str(                )Set to APPEND=Y AND APPENDABLE=Y on all other contributing parts in the middle;

%put;
%put DEBUG:          positive integer. Default is 0.;
%put %str(                )If >0 then some debugging messages are printed to the log;


%put;
%put LOWMEMORYMODE:  Y (default) | N;
%put %str(                )Controls how RRG generator behaves. If file I/O is slow then setting LOWMEMORYMODE= N may improve performance.;

%put ;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put OPTIONAL PARAMETERS WHICH OVERRIDE SETTINGS IN CONFIG.INI FILE;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put;


%put;
%put DEST:           APP (default) | CSR (case insensitive) ;
%put %str(                )Determines whether report properties are read from APP section or from CSR section of config.ini file ;

%put;
%put SAVERCD:        N | Y  (case insensitive) ;
%put %str(                )If set to Y, the RCD dataset is saved parmanently in %nrstr(&rrgoutpath) folder;

%put;
%put INDENTSIZE:     positive integer (default=2);
%put %str(                )the size of (in points) of a single indent (i point corresponds roughly to the width of letter "m");

%put;
%put NODATAMSG:      A text to display in the table if there is no data. ;
%put %str(                )Superseeds the NODATA text from config.ini file ;
%put;


%put;
%put PAPERSIZE:      paper size, e.g. A4 or LETTER ;

%put;
%put ORIENT:         orientation, e.g. P (for portrait) or L (for landscape) ;

%put;
%put FONT:           font family, e.g. Helvetica or TimesNewRoman. See config file for supported fonts;

%put;
%put FONTSIZE:       font size.See config file for supported fonts;

%put;
%put MARGINS:        size of the margins, in order T L R B, e.g. 1in 0.5in 0.5in 0.7in;

%put;
%put SYSTITLE:       DEPRECATED. The title shown on the top of the page;
%put %str(                )superseeded by shead_l , shead_m and shead_r in config.ini file;



%put ;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put OPTIONAL PARAMETERS MAINTAINED FOR BACKWARD COMPATIBILITY;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put;

%put;
%put ADDLINES:       small integer>0. If page rendering is incorrect, sometimes specifying this parameter fixes the issue;
%put EXTRALINES:     small integer>0. If page rendering is incorrect, sometimes specifying this parameter fixes the issue;



%put ;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put OPTIONAL PARAMETERS WHICH SPECIFIES SOME OUTPUT RENDERING OPTONS (BEST NOT TO MODIFY);
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put;

%put;
%put COLSPACING:     Distance between columns. Default is 4 (roughly the width of one character);

%put;
%put SPLITCHARS:     Characters defining word boundaries. Default is %Str(- );

%put;
%put ESC_CHAR:       RTF Escape character. Default is %str(/);

%put;
%put RTF_LINESPLIT:  CALC | HYPHEN. Method to achieve soft line breaks. Default is HYPHEN;




%end;




%else %if %upcase(&what)=RRG_DEFCOL  %then %do;

%put ;
%put RRG_DEFCOL macro defines the properties of a column in the listing;
%put;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put REQUIRED PARAMETERS:;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put;
%put;
%put NAME:     name of the variable ;
%put;
%put ;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put OPTIONAL PARAMETERS:;
%put *-----------------------------------------------------------------------------------------------------------------------------------;


%put;
%put DECODE:   name of decode variable;
%put;

%put LABEL:   text to display in the header for this column;
%put %str(                )If PAGE=Y then the text will be displayed before the value of NAME variable;
%put %str(                )If not specified, the variable name will be shown.;

%put;

%put ID:      Y | N (default);
%put %str(                )applicable only to wide listings where all columns cannot fit on one page;
%put %str(                )If set to Y then this column (and all columns before it) will apear on each page;


%put;
%put FORMAT:  Previously defined format to apply to the variable NAME as an alternative to decode;
%put %str(                )If used, decode is ignored;
**?? check;


%put;
%put GROUP:   Y | N (default);
%put %str(                )If set to Y then the variable NAME must be included in ORDER parameter;
%put %str(                )If not set to Y then PAGE, KEEPTOGETHER, SPANROW and SKIPLINE parameters are ignored;


%put;
%put PAGE:    Y | N (default);
%put %str(                ) Indicates whether this is a page-by grouping variable;
%put %str(                ) If set to Y then page break will occur on each value change;
%put %str(                ) and the value will be placed below the titles and above the table header;

%put;
%put WIDTH:   the width of the column. Can be either absolute or can be RRG control word.;
%put %str(                )Absolute widths are specified as a number and unit (no spaces), e.g., 1in or 2.5cm ;
%put %str(                )Control words are one of the following: LW (default), LWH, N or NH;
%put %str(                )Control words cause RRG to calculate a minimum width as follows:;
%put %str(                )LW:  according to the longest word in a column across the table, excluding column header;
%put %str(                )LWH: according to the longest word in a column across the table, including column header;
%put %str(                )N:   according to the longest line in a column across the table, excluding column header;
%put %str(                )NH:  according to the longest line in a column across the table, including column header;
%put %str(                )The line is determined using "//" in the value of NAME ("//" is a line break);
%put %str(                )If there is no "//" in the value of NAME then the line is a full value;
%put;
%put ALIGN:   L (left, default) | R (right) | C (center) | RD (rigt-decimal) ;
%put %str(                )the alignment of the text in the cell;
%put %str(                )RD can be used for the text like "XX (XX.X)": The first word before the space will be right-aligned;
%put %str(                )and the rest (after the space) will be aligned by a decimal point;


%put;
%put HALIGN:  L | R | C  : the alignment of the column header ;
%put %str(                )If not specified then the value of ALIGN is used (with RD changed to C);


%put;
%put DIST2NEXT:   value with unit, no spaces, indicating the distance between this column and the next column, e.g., 0.5cm or 3in or 10pt;
%put %str(                )Overrides COLSPACING specified in configuration file or in RRG_DEFLIST;
%put %str(                )and applies only for the column where the value of this parameter is specified;


%put;
%put SKIPLINE: N (default) | Y : Whether to insert a blank row when value of NAME changes;
%put %str(                )applicable only if GROUP=Y;


%put;
%put STRETCH:   Y (default) | N : Whether the column is allowed to stretch so the table uses all availabe width on a page;
%put %str(                )If set to N then the column uses minimum width to comply with the WIDTH parameter value;
%put %str(                )If RRG_DEFLIST.STRETCH=Y then at least one column must have STRETCH=Y;


%put;
%put BREAKOK:   Y (default) | N : whether a page break is allowed at this column;
%put %str(                )Applicabel only to wide listings where all columns cannot fit on one page;


%put;
%put SPANROW:   N (default) | Y : If set to Y then the value of NAME is placed in separate row above the current record;
%put %str(                )spanning the whole table width;


%put;
%put KEEPTOGETHER:   N (default) | Y : whether all records with the same value of NAME should be kept on the same page;
%put %str(                )If this is not possible then KEEPTOGETHER is ignored;


%END;
    
  %else %if %upcase(&what)=RRG_ADDLABEL %then %do;  
    
    
  %put ;  
  %put *-----------------------------------------------------------------------------------------------------------------------------------;  
  %put RRG_ADDLABEL macro is used to request printing a text string without any statistics;  
  %put ;  
  %put *-----------------------------------------------------------------------------------------------------------------------------------;  
  %put REQUIRED PARAMETERS:;  
  %put;  
  %put;  
  %PUT LABEL:         the string to print (with or without quotes, quotes will be stripped by RRG);  
  **??;  
  %put ;  
  %put *-----------------------------------------------------------------------------------------------------------------------------------;  
  %put OPTIONAL PARAMETERS:;  
  %PUT;  
  %PUT;  
  %put SKIPLINE:      N (default) | Y : Whether to insert a blank row after this text;  
    
  %put;  
  %put INDENT:        an integer indicating indentation level. Use negative number to unindent. The default is 0;  
  %put;  
  %put KEEPWITHNEXT:  N (default) | Y : whether to request that this row is to be placed on the same page as the row that follows it;  
  %put %str(                ) If this is not possible then KEEPWITHNEXT is ignored;  
  %put %str(                 The situation when this is not possible is if many rows that follow have also KEEPWITHNEXT=Y );  
  %put %str(                   and there is too many of them to fit on one page);  
  %put;  
  %put WHOLEROW:      N (default) | Y : If set to Y then the specified text will span across all columns in the table;  
  %put %str(                            If set to N then the text will be placed in the 1st column);  
    
  %end;  
    
  %else %if %upcase(&what)=RRG_ADDVAR %then %do;  
    
    
  %put ;  
  %put *-----------------------------------------------------------------------------------------------------------------------------------;  
  %put RRG_ADDVAR macro is used to specify properties of a continous variable;  
  %put ;  
  %put *-----------------------------------------------------------------------------------------------------------------------------------;  
  %put REQUIRED PARAMETERS:;  
  %put;  
  %put;  
  %PUT NAME:         name of the variable;  
  %put ;  
  %put *-----------------------------------------------------------------------------------------------------------------------------------;  
  %put OPTIONAL PARAMETERS:;  
  %PUT;  
  %put;  
  %put WHERE:         an additional subsetting condition to be applied to the RRG_DEFREPORT.DATASET dataset before any calculations are performed;  
  %put %nrstr(                 after RRG_DEFREPORT.POPWHERE and RRG_DEFREPORT.TABWHERE);  
    
  %PUT;  
  %PUT LABEL:         a text to print before the names of statistics;  
    
  %put   ;
  %PUT LABELLINE:     0 (default) | 1 : If set to 1 then the label is printed on the same line as the 1st statistic;  
  %put %nrstr(                            instead of above the names of statistics);  
    
  %put;  
  %put SKIPLINE:      N (default) | Y : Whether to insert a blank row after the statistics for this variable;  
  %put;  
    
  %put;  
  %put STATS:         list of within-treatment statistics to calculate, overrides the default list specified config.ini file;  
  %put;  
    
  %put;  
  %put OVERALLSTATS:  list of between-treatment statistics. If requested, they will be placed in a separate column;  
    
  %put;  
  %put INDENT:        an integer indicating indentation level. Use negative number to unindent. The default is 0;  
    
  %put;  
  %put KEEPWITHNEXT:  N (default) | Y : whether to request that this row is to be placed on the same page as the row that follows it;  
  %put %str(                ) If this is not possible then KEEPWITHNEXT is ignored;  
  %put %str(                 The situation when this is not possible is if many rows that follow have also KEEPWITHNEXT=Y );  
  %put %str(                   and there is too many of them to fit on one page);  
  %put;  
    
  %put;  
  %put BASEDEC:       an integer %nrstr(>=0) indicating base decimal precision. The default is 0;  
  %put %str(          Statistic-specific modifiers specified in config.ini file are added to this number to control varying degrees of decimal precision);  
    
  %put;  
  %put POPGRP:       a list of variables (previously added using RRG_ADDGRP) which split the population;
  %put %str(         This is used to correctly determin NMISS value if population splitting grouping variables are used);
      
%put;  
%put CONDFMT:      the instructions to define "custom format" for display of calculated statistics;
%put %nrstr(         The syntax is CONDFMT=%nrbquote( string1, string2, etc) where string1, string2 etc define the format for individual statistics,);
%put %nrstr(         and consist of 3 parts:);
%put %nrstr(           1. Space-separated list of statistics );
%put %nrstr(           2. Name of the format (which is either buit-in (like 12.1) or was previously defined and is "visible" to RRG));
%put %nrstr(           3. Precision to which the calculated statistics should be rounded before applying the format (suggested precision is 0.00000001));
%put %nrstr(          EXAMPLE:);
%put %nrstr(            condfmt=%nrbquote( min max 12.2 0.000001, mean median stderr myfmt. 0.000001));
%put %nrstr(               as a result, MIN and MAX will be shown as specified with 2 decimals,  );
%put %nrstr(               while  MEAN, MEDIAN and STDERR will be shown as specified by myfmt. format,);
%put %nrstr(               and all other requested statistics will be shown as per BASEDEC and precision modifiers from config.ini file);                        
%put %nrstr(               MYFMT format can be defined based on value ranges, for example, );
%put %nrstr(                 proc format;                                    );  
%put %nrstr(                 value myfmt                                     );  
%put %nrstr(                  low - 0 = '<=0'                                );  
%put %nrstr(                  0 - < 0.2 = '<0.2'                             );  
%put %nrstr(                  0.2 - < 10 = [8.2]    %end;                    );  
%put %nrstr(                  10 - high = [8.1]                              );  
%put %nrstr(                   ;                                             );  

%put;  
%put MAXDEC:      The integer %nrstr(>=0) which limists the number of decimals displayed;

%put;                                                                                                                                                 
%put SHOWNEG0:    N (default) | Y: if set to Y and the calculated statistic is < 0 but the display due to application of BASEDEC shows it as, e.g.,  0.0;
%put %nrstr(         then minus sign is shown before the value (-0.0));

%put;                                                                                                                                                 
%put SUBJID  :    the name of the variable indcating a patient. Overrides RRG_DEFREPORT.SUBJID for this variable only;

%put;
%put STATLABFMT:  the name of previously defined format, to be used to display "names" of statistics;
%put %nrstr(         the default is $__rrglf. which RRG internally creates based on config.ini file);

%put;
%put STATDISPFMT: the name of previously defined format, which defines how combined statistics are to be displayed;
%put %nrstr(         the default is $__rrgcf. which RRG internally creates based on config.ini file);

%put;
%put STATDECINFMT: the name of previously defined format, which defines statistic-specific decimal precision modifiers;
%put %nrstr(         the default is $__rrgdf. which RRG internally creates based on config.ini file);

%put;
%put PVFMT:        the name of previously defined format, which defines how p-value is to be displayed;
%put %nrstr(         the default is $__rrgpf. which RRG internally creates based on config.ini file);
             

%put;
%put ALIGN:         L|C|R|RD: the alignment to be applied to all statistics. Overwrites default alignment assigned by RRG;
%put %nrstr(         If the table has many coumns and the default decimal alignment takes too much space, then setting ALIGN=C may improve the situation.);
              
%put;
%put TEMPLATEWHERE: a where clause to apply if the codelist is used. The default is RRG_DEFREPORT.POPWHERE and RRG_DEFREPORT.TABWHERE and RRG_ADDVAR.WHERE;
%put %nrstr(        May be useful in the following situation: the table shows summary stats by parameter and visit, and the codelists are used to ensure all visits and all parameters are shown);
%put %nrstr(           Normally RRG cross-joins codelist for all grouping variabls. If some parameters are only collected on a subset of visits then using TEMPLATEWHERE);
%put %nrstr(           we can keep only relevant parameters for each visit );

                                
%end;


%else %if %upcase(&what)=RRG_ADDCATVAR %then %do;
                    

%end;


%else %if %upcase(&what)=RRG_ADDCOND %then %do;


%end;



%else %if %upcase(&what)=RRG_ADDGROUP %then %do;

%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put ;
%put RRG_ADDGROUP macro defines the properties of the grouping variable;
%put;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put REQUIRED PARAMETERS:;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put;
%put;
%put NAME :          name of the variable;
%put;


%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put OPTIONAL PARAMETERS:;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put;
%put;
%put DECODE :        name of the decode (display) variable;
%put;

%put LABEL :         label of the variable (printed above variable values);
%put;

%put NLINE :         Y (default) | N (case insensitive). Whether to print "(N=xx)" after the variable value;
%put %str(                ) showing calculated counts of subject for each value;
%put;
  
%put CODELIST :      List of <value="display">, separated by defined delimiter, and enclosed in %nrstr(%str()); 
%put %nrstr(                The text to the left of "=" is the value of NAME variable and the text to the right of "=" (in quotes)) ; 
%put %nrstr(                is how this value should be displayed); 
%put %nrstr(                Only the values included in codelist will be shown in the table, in the order specified in codelist); 
%put %nrstr(                The default delimiter is comma); 
%put %nrstr(                Non-existing values will not be shown (unlike CODELIST for RRG_ADDCATVAR or RRG_ADDTRT)); 
%put %nrstr(                When specifying display values, do not use reserved characters like quotes, =, <, >, or / ); 
%put %nrstr(                Use ASCII-numeric representation of such characters if needed. or use abbreviations like "qt", "eq","ge", etc.,); 
%put %nrstr(                and replace them in RRG_CODEAFTER); 
%put %nrstr(                EXAMPLES:); 
%put %nrstr(                  CODELIST=%str('M'='Male', 'F'='Female')); 
%put %nrstr(                  CODELIST=%str(1='Grade 1', 2='Grade 2')); 
 

%put DELIMITER:      a character used to delimit "pairs" in CODELIST; 
%put; 

%put PRELOADFMT :    The name of the previously created character format (including ending dot);  
%put %nrstr(                PRELOADFMT is aconvenient alternative to CODELIST if codelist is awkward to specify due to , e.g.,);  
%put %nrstr(                commas in the display text. ); 
%put %nrstr(                The entries will be shown in the order in which they are specified in such format. ); 
%put %nrstr(                Non-existing values will not be shown); 
%put %nrstr(                If used, the preloadfmt should be created in RRG_CODEBEFORE and NOTSORTED option shoudl be used); 
%put %nrstr(                PRELOADFMT takes precedence over CODELIST ); 
%put; 
**??; 
 
%put CODELISTDS :    The name of previously created dataset representing codelist. The dataset must have the variables; 
%put %nrstr(                NAME, DECODE (which must be specified), and optionally a numeric __ORDER variable); 
%put %nrstr(                Without the __ORDER variable,   _n_ is used as an order); 
%put %nrstr(                If specified, RRG will create and use the CODELIST from this dataset       ); 
%put %nrstr(                The CODELISTDS takes precedence over CODELIST and PRELOADFMT       ); 
 
 
 
%put PAGE :        Y | N (default): whether each value of this groupig variable is to be shown on a separate page); 
%put %nrstr(                If so, the display value will be shown on top of the page, below the titles and above the table header);  
%put; 
  
%put;   
%put ACROSS :       Y  | N (default) (case insensitive). Whether group values are to be shown across the page, each value in a separate column;   
%put INCOLUMNS:     DEPRECATED. Same as ACROSS;   
%put %nrstr(                ________________________________________________________________________);   
%put %nrstr(                Preferred Term        Treatment A                  Treatment B          );   
%put %nrstr(                                  __________________________ ___________________________);   
%put %nrstr(                                   Male         Female          Male       Female       );   
%put %nrstr(                ________________________________________________________________________);   
                                 
%put;   
   
%put INCOLUMN  :    Y  | N (default) (case insensitive). Whether group values are to be shown in a separate column;   
%put %nrstr(                ________________________________________________________________________);   
%put %nrstr(                Parameter     Visit      Statistic    Treatment A        Treatment B          );   
%put %nrstr(                ________________________________________________________________________);   
%put %nrstr(                 Heart Rate   Baseline   n             x                    x        );   
%put %nrstr(                                         Mean         xx.x                 xx.x        );   
%put %nrstr(                ________________________________________________________________________);   
%put;   
   
%put SKIPLINE: N (default) | Y : Whether to insert a blank row when value of NAME changes;   
%put %nrstr(                Applicable mostly to the reports where RRG_DEFREPORT.STATSACROSS=Y );  
%put;   
     
%put AUTOSPAN :      Y | N (case insensitive). Overrides settings in config.ini file. ;   
%put %str(                ) Indcates whether common text is to be automatically extracted from display values and placed in separate row;   
%put %str(                ) For example, if treatment decode values are "Initial Dose 0.5 mg", "Initial Dose 1.0 mg"   and "Initial Dose 2.0 mg" ;   
%put %str(                ) and AUTOSPAN=Y then the header for treament columns will loke like this:  ;   
%put %str(                ) ___________________________________________;   
%put %str(                )             Initial Dose;   
%put %str(                ) ___________________________________________;   
%put %str(                )   0.5 mg        1.0 mg        2.0 mg;   
%put %str(                ) ___________________________________________;   
 
 
%put; 
%put POPSPLIT:       N | Y : Whether this grouping variable is to be considered dopulation splitting (e.g. gender or ethnicity);   
%put %nrstr(                If set to Y then denominator for categorical variable is calculated within each value of this grouping variable);   
%put %nrstr(                Defaults to Y if PAGE=Y, otherwise defaults to N);   
   
%put;   
%put FREQSORT:       N | Y : Whether frequency-based sorting is to be applied to this grouping variable;   
%put;   
%put AEGROUP:        Y (default) | N  applicable only where RRG_DEFREPORT,REPTYPE=EVENTS   ;
%put %nrstr(                If set to Y then this grouping variable is treated in non-hierarchical way);   
%put %nrstr(                Example where it could be useful are AE tables by Grade (e.g., "Grades 3/4/5" and "All Grades"));   
%put;   
%put SORTCOLUMN:     the value of this grouping variable to be used for frequency-based sorting;   
%put %nrstr(                Applicable only when ACROSS=Y and FREQSORT=Y and AEGROUP=N);   
  
  
  /*  */
/*  %put CUTOFFVAL:     the threshold value to apply the cutoff based on count or percentage of patients  */
/*  %put %nrstr(                If specified then first all records where the count of Applicable only when ACROSS=Y and FREQSORT=Y and AEGROUP=N);  */
/*  cutofftype, mincnt, minpct are not currently used??? ; */
/*  */

%end;


%else %if %upcase(&what)=RRG_ADDTRT %then %do;

%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put ;
%put RRG_ADDTRT macro defines the properties of the treatment variable;
%put;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put REQUIRED PARAMETERS:;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put;
%put;
%put NAME :          name of the variable;
%put;

%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put OPTIONAL PARAMETERS:;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put;
%put;
%put DECODE :        name of the decode (display) variable;
%put;

%put LABEL :         label of the variable (printed across treatment columns above treatment decodes);
%put;

%put NLINE :         Y (default) | N (case insensitive). Whether to print "(N=xx)" showing calculated population counts;
%put;

%put SUFFIX :        text to print after display value and (N=xx), e.g., SUFFIX=%nrstr(%str(//n (%%))) or SUFFIX='//n (%)'; 
%put;

%put ACROSS :        Y (default) | N (case insensitive). Whether treatments are to be shown in columns;
%put;

%put AUTOSPAN :      Y | N (case insensitive). Overrides settings in config.ini file. ;
%put %str(                ) Indcates whether common text is to be automatically extracted from display values and placed in separate row;
%put %str(                ) For example, if treatment decode values are "Initial Dose 0.5 mg", "Initial Dose 1.0 mg"   and "Initial Dose 2.0 mg" ;
%put %str(                ) and AUTOSPAN=Y then the header for treament columns will loke like this:  ;
%put %str(                ) ___________________________________________;
%put %str(                )             Initial Dose;
%put %str(                ) ___________________________________________;
%put %str(                )   0.5 mg        1.0 mg        2.0 mg;
%put %str(                ) ___________________________________________;
  
%put; 
%put SPLITROW :      A characer used to control appearance of headers when autospan=N; 
%put %str(                ) Set to the character on which the text in the headers should be split ; 
%put %str(                ) The text before the split character on the adjacent columns, if identical, will be extracted and placed ;
%put %str(                ) in a separate row in the header, with bottom border ; 
%put %str(                ) For example, if treatment decode values are "Miracle Drug|0.5 mg", "Miracle Drug|1.0 mg" , ;
%put %str(                ) "Comparator|1.0 mg"  and "Comparator|2.0 mg" and SPLITROW=| then the header for treament columns will loke like this:  ; 
%put %str(                ) ; 
%put %str(                ) _______________________________________________; 
%put %str(                )     Miracle Drug               Comparator; 
%put %str(                ) ________________________ ______________________; 
%put %str(                )   0.5 mg       1.0 mg      1.0 mg      2.0 mg; 
%put %str(                ) _______________________________________________; 
%put;                  
  
  
%put REMOVE:       List of space-delimited values of NAME which should be removed from display ; 
%put %str(               ) Useful if the table is to be sorted by total frequency but total column is not shown ; 
%put %str(               ) Another example is when total group is created but individual components of total group are not to be shown; 
%put %str(               ) After the table is created using all values of NAME, the column corresponding to REMOVE values is deleted;
%put %str(               ) This parameter is ignored if CODELIST is specified. ; 
%put %str(               ) Example: REMOVE=99 or REMOVE=1 2;  
%put; 
%put SORTCOLUMN :  Comma-separated list of values of NAME to apply frequency-based sorting to categorical variable; 
%put %str(               ) Specifies which columns to sort by. Table rows are sorted by descending frequency in the column corresponding ; 
%put %str(               ) to the first value on the list, then by descending frequency in the column corresponding to the second value, etc, ;
%put %str(               ) and finally alphabetically ; 
%put %str(               ) Example, SORTCOLUMN=99 or SORTCOLUMN=%nrstr(%str(99,2,1)); 
%put; 
%put CUTOFFCOLUMN: Comma-separated list of values of NAME to apply cutoff value specified in RRG_ADDCATVAR;
%put %str(               ) The cut-off rule is applied to all specified treatment values ;
%put %str(               ) (all specified treatments must have count and/or percent on or above specified cut-off value) ;
%put %str(               ) Example, CUTOFFCOLUMN=99 or CUTOFFCOLUMN=%nrstr(%str(99,2,1)); 
%put; 
%put CODELIST :    Used to show treatments in the table even if there is no data for a this treatment.  ;
%put %str(               ) Similar to CODELIST in RRG_ADDCATVAR, but with slightly limited functionality;
%put %str(               ) It lets you specify which values of NAME should be shown in the tabe, and how should they be displayed;
%put %str(               ) If used, follow the same rules as for RRG_ADDCATVAR.CODELIST ;
%put %str(               ) If there is one or more RRG_MAKETRT calls then the new values must be included in codelist ;
%put %str(               ) ;
%put %str(               ) LIMITATIONS:;
%put %str(                 ) CODELIST does not change the order of display (this feature is planned for future releases) ;
%put %str(                 ) CODELIST is not compatible with AUTOSPAN=Y and LABEL ;
%put %str(                 ) if CODELIST is specified then REMOVE parameter is ignored ;


%end;




%else %if %upcase(&what)=RRG_MAKETRT %then %do;

*-----------------------------------------------------------------------------------------------------------------------------------;
%put ;
%put RRG_MAKETRT macro is used to create pooled treatments that rrg recognizes as such;
%put %str(                ) and can exclude them from plugins calculating between-treatment statistics;
%put;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put REQUIRED PARAMETERS:;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put;
%put;
%put NAME :          name of the treatment variable, must be th same as RRG_ADDTRT.NAME;
%put;
%put VALUES :        space-delimited list of values of NAME to create new pooled trteatment. Character values must be in quotes;
%put;
%put NEWVALUES :     value of the new pooled treatment. Character values must be in quotes;
%put;
%put NEWDECODE :     decode value of new pooled treatment;
%put;

%end;


%else %if %upcase(&what)=RRG_DEFMODELPARMS %then %do;

%put ;
%put RRG_DEFMODELPARMS macro is used to provide parameters for macro plug-ins;
%put;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put REQUIRED PARAMETERS:;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put;
%put;
%put MACRONAME :   name of the plug-in macro;
%put;
%put MACRONAME :   alias for the plug-in macro. When requesting statistics, refer to the alias followed by STAT_NAME created by plug-in,;
%put %str(               )  (e.g. stats=myalias.pval);
%put;
%put PARMS :       list of parameter values, enclosed in %nrstr(%str());
%put;
%put %str(               ) EXAMPLE CALL:;
%put %nrstr(                   %rrg_defModelParms%( );                                                      
%put %str(                    )  Modelname = an1,       ;                                                  
%put %str(                    )  Macroname = rrg_anova,  ;                                                 
%put %nrstr(                     parms = %str(strata = center , interactions = center*trtpn, refvals= 0 1));
%put %str(                   %);) ;
%put;
%put %str(                    ) In RRG_ADDVAR you can request LSMEANS from anova model above as follows:;
%put %str(                    ) stats=m mean+se an1.lsmean+se;

%end;
                                                                        



%else %if %upcase(&what)=RRG_DEFINE_PYR %then %do;
  
  
*-----------------------------------------------------------------------------------------------------------------------------------;
%put ;
%put RRG_DEFINE_PYR macro is used to define how exposure-adjusted rates are calculated and displayed;
%put;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put REQUIRED PARAMETERS:;
%put *-----------------------------------------------------------------------------------------------------------------------------------;
%put;
%put;
%put PYDEC :         number of decimals for sum of patient-years statistics. Default is 1;

%put;
%put PYRDEC :        number of decimals for exposure-adjusted rate. Default is 4;


%put;
%put PATYEARVAR :    name of the variable indicating total exposure duration for a subject;


%put;
%put PATYEARUNIT :   DAY|WEEK|MONTH|YEAR : unit for PATYEARVAR. Default is YEAR;


%put;
%put ONSETVAR :      name of the variable indicating onset of adverse event. Default is ASTDT;


%put;
%put ONSETTYPE :     DATE | DAY : what ONSETVAR represents. Default is DATE;


%put;
%put REFSTARTVAR :   name of the variable representing the reference point from which duration of exposure is calculated;
%put %str(                    )Default is TRTSDT;


%put;
%put REFSTARTTYPE :  DATE | DAY : what REFSTARTVAR represents. Default is DATE; 


%put;
%put MULTIPLIER :    Adjustment factor. For example, if set to 1, then the exposure-adjusted rate is per 1 patient year;
%put %str(                    )If set to 100 then the exposure-adjusted rate is per 100 patient years;
%put %str(                    )Default is 1;

 
 
%end;




%mend rrg_help;

%*rrg_help(RRG_init);
%*rrg_help(RRG_defreport);
%*rrg_help(RRG_deflist);
%*rrg_help(RRG_defcol);
%*rrg_help(RRG_addtrt);
%*rrg_help(RRG_maketrt);
%*rrg_help(RRG_DEFINE_PYR);

%rrg_help(RRG_addgroup);