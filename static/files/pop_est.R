##################################################################
##################################################################
##                                        
##        EXAMPLE POPULATION ESTIMATATION PROCEDURES
##            IMPLEMENTED BY THE rFIA PACKAGE
##
##       Case study: Estimating biomass & carbon stocks 
##
##                     Hunter Stanke
##                    15 October 2019
##
##################################################################
##################################################################


## In the code below, we highlight the basic estimation procedures
## used to compute population estimates of forest attributes from 
## Forest Inventory and Analysis (FIA) data. We will demonstrate 
## these procedures with the 'fiaRI' dataset (included in the 
## rFIA package) so that you can follow along.


## Our goal here is to estimate total tree biomass, total tree
## carbon (aboveground) and total forested area in the state of Rhode Island
## for the year 2018. From these totals, we will compute ratios
## of average tree biomass / forested acre and average tree 
## carbon / forested acre. We will do this with and without 
## sampling errors (without being much simpler), and show you 
## how we handle grouped estimates in both cases. All estimates
## will be computed for live trees


## NOTE: The source code for rFIA will vary slightly from that 
## presented below as we designed rFIA to be as flexible and 
## computationally efficient as possible. Despite the differences
## in syntax and structure, the estimation procedures presented
## below are identical to those in rFIA. You can find and 
## download the full source code for rFIA from our GitHub repo:
## https://github.com/hunter-stanke/rFIA

# Load some packages
library(rFIA)
library(dplyr)

# Load the fiaRI dataset (included in rFIA)
data(fiaRI)

## Let's just use the most recent subset of 'fiaRI', 2018
db <- clipFIA(fiaRI)


####################### DATA PREPERATION #########################
## First we need to identify which portion of the FIA Database
## we need to compute estimates of current area and current volume 
## (biomass/carbon). To do this, we will use what FIA calls an
## EVALID, hence the name 'EVALIDator'.
ids <- db$POP_EVAL %>%
  select('CN', 'END_INVYR', 'EVALID') %>%
  inner_join(select(db$POP_EVAL_TYP, c('EVAL_CN', 'EVAL_TYP')), by = c('CN' = 'EVAL_CN')) %>%
  ## Now we filter out everything except current area and 
  ## current volume ids
  filter(EVAL_TYP %in% c('EXPCURR', 'EXPVOL'))

## Now that we have those EVALIDs, let's use clipFIA to subset
db <- clipFIA(db, evalid = ids$EVALID)


## Select only the columns we need from each table, to keep things slim
PLOT <- select(db$PLOT, CN, MACRO_BREAKPOINT_DIA)
COND <- select(db$COND, PLT_CN, CONDID, CONDPROP_UNADJ, PROP_BASIS, COND_STATUS_CD, OWNGRPCD)
TREE <- select(db$TREE, PLT_CN, CONDID, SUBP, TREE, STATUSCD, DRYBIO_AG, CARBON_AG, TPA_UNADJ, DIA)
POP_ESTN_UNIT <- select(db$POP_ESTN_UNIT, CN, EVAL_CN, AREA_USED, P1PNTCNT_EU)
POP_EVAL <- select(db$POP_EVAL, EVALID, EVAL_GRP_CN, ESTN_METHOD, CN, END_INVYR, REPORT_YEAR_NM)
POP_EVAL_TYP <- select(db$POP_EVAL_TYP, EVAL_TYP, EVAL_CN)
POP_PLOT_STRATUM_ASSGN <- select(db$POP_PLOT_STRATUM_ASSGN, STRATUM_CN, PLT_CN)
POP_STRATUM <- select(db$POP_STRATUM, ESTN_UNIT_CN, EXPNS, P2POINTCNT, 
                      ADJ_FACTOR_MICR, ADJ_FACTOR_SUBP, ADJ_FACTOR_MACR, CN, P1POINTCNT)

## Since we need some information stored in each of these tables
## to compute estimates, we will join them into one big data
## dataframe (let's call that 'data') that we can operate on.
data <- PLOT %>%
  ## Add a PLT_CN column for easy joining
  mutate(PLT_CN = CN) %>%
  ## Join COND & TREE
  left_join(COND, by = 'PLT_CN') %>%
  left_join(TREE, by = c('PLT_CN', 'CONDID')) %>%
  ## Population tables
  left_join(POP_PLOT_STRATUM_ASSGN, by = 'PLT_CN') %>%
  left_join(POP_STRATUM, by = c('STRATUM_CN' = 'CN')) %>%
  left_join(POP_ESTN_UNIT, by = c('ESTN_UNIT_CN' = 'CN')) %>%
  left_join(POP_EVAL, by = c('EVAL_CN' = 'CN')) %>%
  left_join(POP_EVAL_TYP, by = 'EVAL_CN')


## Now let's make a column that will adjust for non-response
## in our sample (See Bechtold & Patterson, 3.4.3 'Nonsampled 
## Plots and Plot Replacement')
# Since we know there are no macroplots in RI, we don't really 
# need to worry about that here, but we will show you anyways.
data <- data %>%
  mutate(
    ## AREA
    aAdj = case_when(
           ## When NA, stay NA
           is.na(PROP_BASIS) ~ NA_real_,
           ## If the proportion was measured for a macroplot,
           ## use the macroplot value
           PROP_BASIS == 'MACR' ~ as.numeric(ADJ_FACTOR_MACR),
           ## Otherwise, use the subpplot value
           PROP_BASIS == 'SUBP' ~ ADJ_FACTOR_SUBP),
    ## TREE
    tAdj = case_when(
           ## When DIA is na, adjustment is NA
           is.na(DIA) ~ ADJ_FACTOR_SUBP,
           ## When DIA is less than 5", use microplot value
           DIA < 5 ~ ADJ_FACTOR_MICR,
           ## When DIA is greater than 5", use subplot value
           DIA >= 5 ~ ADJ_FACTOR_SUBP
         ))

## Next, we need to construct what Bechtold and Patterson called
## a 'domain indicator function'. (see Eq. 4.1, pg. 47 of the 
## publication). This is essentially just a vector which indicates
## whether a tree (or plot, condition, etc.) is within our domain 
## of interest (live trees on forest land). 

## To construct the domain indicator, we just need a vector which 
## is the same length as our joined table, and takes a value of 1 
## if the stem (or condition) is in the domain and 0 otherwise. 
## We build seperate domain indicators for estimating tree totals
## and area totals, because we can specify different domains of 
## interest for both. For example, if we used our tree domain 
## (live trees on forest land) to estimate area, then we would 
## not actually be estimating the full forested area in RI. Instead
## we would estimate the forested area ONLY where live trees
## are currently present.

## Build a domain indicator for land type and live trees
## Land type (all forested area)
data$aDI <- if_else(data$COND_STATUS_CD == 1, 1, 0)
## Live trees only (on forested area)
data$tDI <- if_else(data$STATUSCD == 1, 1, 0) * data$aDI

## Now, let's just rename the END_INVYR column to 'YEAR'
## for a pretty output like rFIA
data <- data %>%
  mutate(YEAR = END_INVYR) %>%
  ## remove any NAs
  filter(!is.na(YEAR))


################## WITHOUT SAMPLING ERRORS #####################
####### NO GROUPS
## Now we are ready to start computing estimates. If we don't 
## care aboute sampling errors, we can use the EXPNS column 
## in the POP_STRATUM table to make our lives easier. EXPNS
## an expansion factor which descibes the area, in acres, 
## that a stratum represents divided by the number of sampled 
## plots in that stratum (see Bechtold & Patterson 2005, section
## 4.2 for more information on FIA stratification procedures).
## When summed across summed across all plots in the population 
## of interest, EXPNS allows us to easily obtain estimates of 
## population totals, without worrying about fancy stratifaction
## procedures and variance estimators.

## Estimate Tree totals
tre_bio <- data %>%
  filter(EVAL_TYP == 'EXPVOL') %>%
  ## Make sure we only have unique observations of plots, trees, etc.
  distinct(ESTN_UNIT_CN, STRATUM_CN, PLT_CN, CONDID, SUBP, TREE, .keep_all = TRUE) %>%
  ## Plot-level estimates first (multiplying by EXPNS here)
  group_by(YEAR, ESTN_UNIT_CN, ESTN_METHOD, STRATUM_CN, PLT_CN) %>%
  summarize(bioPlot = sum(DRYBIO_AG * TPA_UNADJ * tAdj * tDI * EXPNS  / 2000, na.rm = TRUE),
            carbPlot = sum(CARBON_AG * TPA_UNADJ * tAdj * tDI * EXPNS  / 2000, na.rm = TRUE)) %>%
  ## Now we simply sum the values of each plot (expanded w/ EXPNS)
  ## to obtain population totals
  group_by(YEAR) %>%
  summarize(BIO_AG_TOTAL = sum(bioPlot, na.rm = TRUE),
            CARB_AG_TOTAL = sum(carbPlot, na.rm = TRUE))

## Estimate Area totals
area_bio <- data %>%
  filter(EVAL_TYP == 'EXPCURR') %>%
  ## Make sure we only have unique observations of plots, trees, etc.
  distinct(ESTN_UNIT_CN, STRATUM_CN, PLT_CN, CONDID, .keep_all = TRUE) %>%
  ## Plot-level estimates first (multiplying by EXPNS here)
  group_by(YEAR, ESTN_UNIT_CN, ESTN_METHOD, STRATUM_CN, PLT_CN) %>%
  summarize(forArea = sum(CONDPROP_UNADJ * aAdj * aDI * EXPNS, na.rm = TRUE)) %>%
  ## Now we simply sum the values of each plot (expanded w/ EXPNS)
  ## to obtain population totals
  group_by(YEAR) %>%
  summarize(AREA_TOTAL = sum(forArea, na.rm = TRUE))


## Now we can simply join these two up, and produce ratio estimates
bio <- left_join(tre_bio, area_bio) %>%
  mutate(BIO_AG_ACRE = BIO_AG_TOTAL / AREA_TOTAL,
         CARB_AG_ACRE = CARB_AG_TOTAL / AREA_TOTAL) %>%
  ## Reordering the columns
  select(YEAR, BIO_AG_ACRE, CARB_AG_ACRE, BIO_AG_TOTAL, CARB_AG_TOTAL, AREA_TOTAL)

## Now let's compare with rFIA.... looks like a match!
biomass(clipFIA(fiaRI), totals = TRUE)
bio



################## WITHOUT SAMPLING ERRORS #####################
####### WITH GROUPING VARIABLES
## To add grouping variables to the above procedures, we can 
## simply add the names of the variables we wish to group by 
## to the 'group_by' call. 
## NOTE: If adapting this code for your own use, make sure that
## your grouping variables are included in the 'select' calls in
## lines 68 -77, otherwise the variable will not be found in 'data'

## Grouping by Ownership group (OWNGRPCD)
## Estimate Tree totals
tre_bioGrp <- data %>%
  filter(EVAL_TYP == 'EXPVOL') %>%
  ## Make sure we only have unique observations of plots, trees, etc.
  distinct(ESTN_UNIT_CN, STRATUM_CN, PLT_CN, CONDID, SUBP, TREE, .keep_all = TRUE) %>%
  ## Plot-level estimates first (multiplying by EXPNS here)
  group_by(YEAR, OWNGRPCD, ESTN_UNIT_CN, ESTN_METHOD, STRATUM_CN, PLT_CN) %>%
  summarize(bioPlot = sum(DRYBIO_AG * TPA_UNADJ * tAdj * tDI * EXPNS  / 2000, na.rm = TRUE),
            carbPlot = sum(CARBON_AG * TPA_UNADJ * tAdj * tDI * EXPNS  / 2000, na.rm = TRUE)) %>%
  ## Now we simply sum the values of each plot (expanded w/ EXPNS)
  ## to obtain population totals
  group_by(YEAR, OWNGRPCD) %>%
  summarize(BIO_AG_TOTAL = sum(bioPlot, na.rm = TRUE),
            CARB_AG_TOTAL = sum(carbPlot, na.rm = TRUE))

## Estimate Area totals
area_bioGrp <- data %>%
  filter(EVAL_TYP == 'EXPCURR') %>%
  ## Make sure we only have unique observations of plots, trees, etc.
  distinct(ESTN_UNIT_CN, STRATUM_CN, PLT_CN, CONDID, .keep_all = TRUE) %>%
  ## Plot-level estimates first (multiplying by EXPNS here)
  group_by(YEAR, OWNGRPCD, ESTN_UNIT_CN, ESTN_METHOD, STRATUM_CN, PLT_CN) %>%
  summarize(forArea = sum(CONDPROP_UNADJ * aAdj * aDI * EXPNS, na.rm = TRUE)) %>%
  ## Now we simply sum the values of each plot (expanded w/ EXPNS)
  ## to obtain population totals
  group_by(YEAR, OWNGRPCD) %>%
  summarize(AREA_TOTAL = sum(forArea, na.rm = TRUE))


## Now we can simply join these two up, and produce ratio estimates
bioGrp <- left_join(tre_bioGrp, area_bioGrp) %>%
  mutate(BIO_AG_ACRE = BIO_AG_TOTAL / AREA_TOTAL,
         CARB_AG_ACRE = CARB_AG_TOTAL / AREA_TOTAL) %>%
  ## Reordering the columns
  select(YEAR, OWNGRPCD, BIO_AG_ACRE, CARB_AG_ACRE, BIO_AG_TOTAL, CARB_AG_TOTAL, AREA_TOTAL)

## Now let's compare with rFIA.... looks like a match!
biomass(clipFIA(fiaRI), totals = TRUE, grpBy = OWNGRPCD)
bioGrp







##################### WITH SAMPLING ERRORS #####################
####### NO GROUPS
# Keep it simple, groups and combos w/ a loop
## We need to rebuild that domain indicator each time we run
## a group through 


