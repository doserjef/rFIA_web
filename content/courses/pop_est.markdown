---
title: Estimating population attributes
linktitle: Population Estimation
toc: true
type: docs
date: "2019-05-05T00:00:00+01:00"
draft: false
menu:
  courses:
    parent: FIA Demystified
    weight: 3

# Prev/next pager order (if `docs_section_pager` enabled in `params.toml`)
weight: 3
---
___

In the code below, we highlight the basic estimation procedures used to compute population estimates of forest attributes from Forest Inventory and Analysis (FIA) data. We will demonstrate these procedures with the `fiaRI` dataset (included in the `rFIA` package) so that you can follow along. Download the R script for these examples <a href="/files/pop_est.R" target="_blank">here</a>.

Our goal here is to estimate total tree biomass, total treecarbon (aboveground) and total forested area in the state of Rhode Island for the year 2018. From these totals, we will compute ratios of average tree biomass/ forested acre and average tree carbon/ forested acre. We will do this with and without sampling errors (without being much simpler), and show you how we handle grouped estimates in both cases. All estimates will be computed for live trees.

{{% alert note %}}
The source code for `rFIA` will vary slightly from that presented below as we designed `rFIA` to be as flexible and computationally efficient as possible. Despite the differences in syntax and structure, the estimation procedures presented below are identical to those in `rFIA`. You can find and download the full source code for `rFIA` from our <a href="https://github.com/hunter-stanke/rFIA" target="_blank">GitHub Repo</a>.
{{% /alert %}}

<br>
<br>
# 
## **Data Preparation**
First, let's load some packages and the `fiaRI` dataset:

```r
# Load some packages
library(rFIA)
library(dplyr)

# Load the fiaRI dataset (included in rFIA)
data(fiaRI)
db <- fiaRI
```

To compute population estimates of current area and current biomass/carbon from the FIADB, we need to identify and subset the necessary portions. To do this, we will use what FIA calls an EVALID, hence the name 'EVALIDator'.

```r
ids <- db$POP_EVAL %>%
  select('CN', 'END_INVYR', 'EVALID') %>%
  inner_join(select(db$POP_EVAL_TYP, c('EVAL_CN', 'EVAL_TYP')), by = c('CN' = 'EVAL_CN')) %>%
  ## Now we filter out everything except current area and 
  ## current volume ids
  filter(EVAL_TYP %in% c('EXPCURR', 'EXPVOL'))

## Now that we have those EVALIDs, let's use clipFIA to subset
db <- clipFIA(db, evalid = ids$EVALID)
```

Since we need some information stored in each of these tables to compute estimates, we will join them into one big dataframe (let's call that `data`) that we can operate on.

```r
## Select only the columns we need from each table, to keep things slim
PLOT <- select(db$PLOT, CN, MACRO_BREAKPOINT_DIA)
COND <- select(db$COND, PLT_CN, CONDID, CONDPROP_UNADJ, PROP_BASIS, COND_STATUS_CD, OWNGRPCD)
TREE <- select(db$TREE, PLT_CN, CONDID, SUBP, TREE, STATUSCD, DRYBIO_AG, CARBON_AG, TPA_UNADJ, DIA, SPCD)
POP_ESTN_UNIT <- select(db$POP_ESTN_UNIT, CN, EVAL_CN, AREA_USED, P1PNTCNT_EU)
POP_EVAL <- select(db$POP_EVAL, EVALID, EVAL_GRP_CN, ESTN_METHOD, CN, END_INVYR, REPORT_YEAR_NM)
POP_EVAL_TYP <- select(db$POP_EVAL_TYP, EVAL_TYP, EVAL_CN)
POP_PLOT_STRATUM_ASSGN <- select(db$POP_PLOT_STRATUM_ASSGN, STRATUM_CN, PLT_CN)
POP_STRATUM <- select(db$POP_STRATUM, ESTN_UNIT_CN, EXPNS, P2POINTCNT, 
                      ADJ_FACTOR_MICR, ADJ_FACTOR_SUBP, ADJ_FACTOR_MACR, CN, P1POINTCNT)

## Join the tables
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
```

Now let's make a column that will adjust for non-response in our sample (See <a href="https://www.srs.fs.usda.gov/pubs/gtr/gtr_srs080/gtr_srs080.pdf" target="_blank">Bechtold and Patterson (2005)</a>, 3.4.3 'Nonsampled Plots and Plot Replacement'). Since we know there are no macroplots in RI, we don't really need to worry about that here, but we will show you anyways.


```r
## Make some adjustment factors
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
```

Next, we need to construct what <a href="https://www.srs.fs.usda.gov/pubs/gtr/gtr_srs080/gtr_srs080.pdf" target="_blank">Bechtold and Patterson (2005)</a> called a 'domain indicator function'. (see Eq. 4.1, pg. 47 of the publication). This is essentially just a vector which indicates whether a tree (or plot, condition, etc.) is within our domain of interest (live trees on forest land). 

To construct the domain indicator, we just need a vector which is the same length as our joined table (`data`), and takes a value of 1 if the stem (or condition) is in the domain and 0 otherwise. We build seperate domain indicators for estimating tree totals and area totals, because we can specify different domains of interest for both. For example, if we used our tree domain (live trees on forest land) to estimate area, then we would not actually be estimating the full forested area in RI. Instead we would estimate the forested area ONLY where live trees are currently present.


```r
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
```

<br>
<br>

## **Without Sampling Errors**

Now we are ready to start computing estimates. If we don't care aboute sampling errors, we can use the `EXPNS` column in the `POP_STRATUM` table to make our lives easier. `EXPNS` is an expansion factor which descibes the area, in acres, that a stratum represents divided by the number of sampled plots in that stratum (see  <a href="https://www.srs.fs.usda.gov/pubs/gtr/gtr_srs080/gtr_srs080.pdf" target="_blank">Bechtold and Patterson (2005)</a>, section 4.2 for more information on FIA stratification procedures). When summed across summed across all plots in the population of interest, `EXPNS` allows us to easily obtain estimates of population totals, without worrying about fancy stratifaction procedures and variance estimators.

### _**No grouping variables**_
First we compute totals for biomass, carbon, and forested area:

```r
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
```

Then we can join these tables up, and produce ratio estimates: 

```r
bio <- left_join(tre_bio, area_bio) %>%
  mutate(BIO_AG_ACRE = BIO_AG_TOTAL / AREA_TOTAL,
         CARB_AG_ACRE = CARB_AG_TOTAL / AREA_TOTAL) %>%
  ## Reordering the columns
  select(YEAR, BIO_AG_ACRE, CARB_AG_ACRE, BIO_AG_TOTAL, CARB_AG_TOTAL, AREA_TOTAL)
```

```
## Joining, by = "YEAR"
```

Comparing with `rFIA`, we get a match!

```r
biomass(clipFIA(fiaRI), totals = TRUE)
```

```
##   YEAR NETVOL_ACRE SAWVOL_ACRE BIO_AG_ACRE BIO_BG_ACRE BIO_ACRE
## 1 2018    2491.167    1418.605    70.37259     13.9919 84.36449
##   CARB_AG_ACRE CARB_BG_ACRE CARB_ACRE NETVOL_ACRE_SE SAWVOL_ACRE_SE
## 1     35.18629     6.995952  42.18225       4.212767       7.184325
##   BIO_AG_ACRE_SE BIO_BG_ACRE_SE BIO_ACRE_SE CARB_AG_ACRE_SE
## 1       3.566183       3.555699    3.561156        3.566183
##   CARB_BG_ACRE_SE CARB_ACRE_SE NETVOL_TOTAL SAWVOL_TOTAL BIO_AG_TOTAL
## 1        3.555699     3.561156    914155471    520569323     25823833
##   BIO_BG_TOTAL BIO_TOTAL CARB_AG_TOTAL CARB_BG_TOTAL CARB_TOTAL AREA_TOTAL
## 1      5134451  30958284      12911916       2567225   15479142   366958.7
##   nPlots_VOL nPlots_AREA
## 1        126         127
```

```r
bio
```

```
## # A tibble: 1 x 6
##    YEAR BIO_AG_ACRE CARB_AG_ACRE BIO_AG_TOTAL CARB_AG_TOTAL AREA_TOTAL
##   <int>       <dbl>        <dbl>        <dbl>         <dbl>      <dbl>
## 1  2018        70.4         35.2    25823833.     12911916.    366959.
```

<br>

### _**Adding grouping variables**_
To add grouping variables to the above procedures, we can simply add the names of the variables we wish to group by to the `group_by` call:

```r
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
```

```
## Joining, by = c("YEAR", "OWNGRPCD")
```

```r
## Now let's compare with rFIA.... looks like a match!
biomass(clipFIA(fiaRI), totals = TRUE, grpBy = OWNGRPCD)
```

```
##   YEAR OWNGRPCD NETVOL_ACRE SAWVOL_ACRE BIO_AG_ACRE BIO_BG_ACRE BIO_ACRE
## 1 2018       30    2614.533    1614.125    71.78929    14.40813 86.19742
## 2 2018       40    2436.484    1331.938    69.74462    13.80741 83.55202
##   CARB_AG_ACRE CARB_BG_ACRE CARB_ACRE NETVOL_ACRE_SE SAWVOL_ACRE_SE
## 1     35.89464     7.204066  43.09871       8.836977      13.751081
## 2     34.87231     6.903703  41.77601       4.600828       8.185484
##   BIO_AG_ACRE_SE BIO_BG_ACRE_SE BIO_ACRE_SE CARB_AG_ACRE_SE
## 1       7.608977       7.567205    7.594343        7.608977
## 2       3.896017       3.874984    3.889238        3.896017
##   CARB_BG_ACRE_SE CARB_ACRE_SE NETVOL_TOTAL SAWVOL_TOTAL BIO_AG_TOTAL
## 1        7.567205     7.594343    294663824    181915597      8090815
## 2        3.874984     3.889238    619491647    338653726     17733018
##   BIO_BG_TOTAL BIO_TOTAL CARB_AG_TOTAL CARB_BG_TOTAL CARB_TOTAL AREA_TOTAL
## 1      1623829   9714644       4045408      811914.6    4857322   112702.3
## 2      3510622  21243639       8866509     1755310.9   10621820   254256.4
##   nPlots_VOL nPlots_AREA
## 1         40          41
## 2         89          89
```

```r
bioGrp
```

```
## # A tibble: 3 x 7
## # Groups:   YEAR [1]
##    YEAR OWNGRPCD BIO_AG_ACRE CARB_AG_ACRE BIO_AG_TOTAL CARB_AG_TOTAL
##   <int>    <int>       <dbl>        <dbl>        <dbl>         <dbl>
## 1  2018       30        71.8         35.9     8090815.      4045408.
## 2  2018       40        69.7         34.9    17733018.      8866509.
## 3  2018       NA       NaN          NaN             0             0 
## # … with 1 more variable: AREA_TOTAL <dbl>
```
{{% alert %}}
If adapting this code for your own use, make sure that your grouping variables are included in the `select` calls in
**Data Preperation**, otherwise the variable will not be found in `data`.
{{% /alert %}}

<br>
<br>

## **With Sampling Errors**
Computing estimates with associated sampling errors is a bit more complex than what we saw above, as we can no longer rely on `EXPNS` to do the heavy lifting for us. In short, we will add a few additional steps when computing tree totals and area totals, summarizing at the strata and estimation unit level along the way. When adding grouping variables, we will need to modify our code further, treating each group as a unique population and summarizing these populations individually. We will follow the procedures outlined by <a href="https://www.srs.fs.usda.gov/pubs/gtr/gtr_srs080/gtr_srs080.pdf" target="_blank">Bechtold and Patterson (2005)</a> (see section 4) for our computations. 

Before we get started, Let's check out what type of estimation methods were used to determine values in the POP tables, as this will influence which variance estimators we use.

```r
unique(db$POP_EVAL$ESTN_METHOD)
```

```
## [1] "Post-Stratification"
```
Looks like just `post-stratification`, so we will use the stratified random sampling estimation approach (known weights)


### _**No grouping variables**_
First we estimate both tree and area attributes at the plot level, and then join these estimates before proceeding to the strata level so that we can compute the covariance between area and tree attributes

```r
## Estimate Tree attributes -- plot level
tre_pop <- data %>%
  filter(EVAL_TYP == 'EXPVOL') %>%
  ## Make sure we only have unique observations of plots, trees, etc.
  distinct(ESTN_UNIT_CN, STRATUM_CN, PLT_CN, CONDID, SUBP, TREE, .keep_all = TRUE) %>%
  ## Plot-level estimates first (note we are NOT using EXPNS here)
  group_by(YEAR, ESTN_UNIT_CN, STRATUM_CN, PLT_CN) %>%
  summarize(bioPlot = sum(DRYBIO_AG * TPA_UNADJ * tAdj * tDI  / 2000, na.rm = TRUE),
            carbPlot = sum(CARBON_AG * TPA_UNADJ * tAdj * tDI  / 2000, na.rm = TRUE)) 

## Estimate Area attributes -- plot level
area_pop <- data %>%
  filter(EVAL_TYP == 'EXPCURR') %>%
  ## Make sure we only have unique observations of plots, trees, etc.
  distinct(ESTN_UNIT_CN, STRATUM_CN, PLT_CN, CONDID, .keep_all = TRUE) %>%
  ## Plot-level estimates first (multiplying by EXPNS here)
  ## Extra grouping variables are only here so they are carried through
  group_by(YEAR, P1POINTCNT, P1PNTCNT_EU, P2POINTCNT, AREA_USED, ESTN_UNIT_CN, STRATUM_CN, PLT_CN) %>%
  summarize(forArea = sum(CONDPROP_UNADJ * aAdj * aDI, na.rm = TRUE))
  
## Joining the two tables
bio_pop_plot <- left_join(tre_pop, area_pop)
```

```
## Joining, by = c("YEAR", "ESTN_UNIT_CN", "STRATUM_CN", "PLT_CN")
```

Now that we have both area and tree attributes in the same table, we can follow through with the remaining estimation procedures at the strata and estimation unit levels:

```r
## Strata level
bio_pop_strat <- bio_pop_plot %>%
  group_by(YEAR, ESTN_UNIT_CN, STRATUM_CN) %>%
  summarize(aStrat = mean(forArea, na.rm = TRUE), # Area mean
            bioStrat = mean(bioPlot, na.rm = TRUE), # Biomass mean
            carbStrat = mean(carbPlot, na.rm = TRUE), # Carbon mean
            ## We don't want a vector of these values, since they are repeated
            P2POINTCNT = first(P2POINTCNT),
            AREA_USED = first(AREA_USED),
            ## Strata weight, relative to estimation unit
            w = first(P1POINTCNT) / first(P1PNTCNT_EU),
            ## Strata level variances
            aVar = (sum(forArea^2) - sum(P2POINTCNT * aStrat^2)) / (P2POINTCNT * (P2POINTCNT-1)),
            bioVar = (sum(bioPlot^2) - sum(P2POINTCNT * bioStrat^2)) / (P2POINTCNT * (P2POINTCNT-1)),
            carbVar = (sum(carbPlot^2) - sum(P2POINTCNT * carbStrat^2)) / (P2POINTCNT * (P2POINTCNT-1)),
            ## Strata level co-varainces
            bioCV = (sum(forArea*bioPlot) - sum(P2POINTCNT * aStrat *bioStrat)) / (P2POINTCNT * (P2POINTCNT-1)),
            carbCV = (sum(forArea*carbPlot) - sum(P2POINTCNT * aStrat *carbStrat)) / (P2POINTCNT * (P2POINTCNT-1)))

## Moving on to the estimation unit
bio_pop_eu <- bio_pop_strat %>%
  group_by(YEAR, ESTN_UNIT_CN) %>%
  summarize(aEst = sum(aStrat * w, na.rm = TRUE) * first(AREA_USED), # Mean Area
            bioEst = sum(bioStrat * w, na.rm = TRUE) * first(AREA_USED), # Mean biomass
            carbEst = sum(carbStrat * w, na.rm = TRUE) * first(AREA_USED), # Mean carbon
            ## Estimation unit variances
            aVar = (first(AREA_USED)^2 / sum(P2POINTCNT)) * 
              (sum(P2POINTCNT*w*aVar) + sum((1-w)*(P2POINTCNT/sum(P2POINTCNT))*aVar)),
            bioVar = (first(AREA_USED)^2 / sum(P2POINTCNT)) * 
              (sum(P2POINTCNT*w*bioVar) + sum((1-w)*(P2POINTCNT/sum(P2POINTCNT))*bioVar)),
            carbVar = (first(AREA_USED)^2 / sum(P2POINTCNT)) * 
              (sum(P2POINTCNT*w*carbVar) + sum((1-w)*(P2POINTCNT/sum(P2POINTCNT))*carbVar)),
            ## Estimation unit covariances
            bioCV = (first(AREA_USED)^2 / sum(P2POINTCNT)) * 
              (sum(P2POINTCNT*w*bioCV) + sum((1-w)*(P2POINTCNT/sum(P2POINTCNT))*bioCV)),
            carbCV = (first(AREA_USED)^2 / sum(P2POINTCNT)) * 
              (sum(P2POINTCNT*w*carbCV) + sum((1-w)*(P2POINTCNT/sum(P2POINTCNT))*carbCV)))
```

Finally, we can sum attributes across estimation units to obtain totals for our region:

```r
## sum across Estimation Units for totals
bio_pop <- bio_pop_eu %>%
  group_by(YEAR) %>%
  summarize(AREA_TOTAL = sum(aEst, na.rm = TRUE),
            BIO_AG_TOTAL = sum(bioEst, na.rm = TRUE),
            CARB_AG_TOTAL = sum(carbEst, na.rm = TRUE),
            ## Ratios
            BIO_AG_ACRE = BIO_AG_TOTAL / AREA_TOTAL,
            CARB_AG_ACRE = CARB_AG_TOTAL / AREA_TOTAL,
            ## Total samping errors
            AREA_TOTAL_SE = sqrt(sum(aVar, na.rm = TRUE)) / AREA_TOTAL * 100,
            BIO_AG_TOTAL_SE = sqrt(sum(bioVar, na.rm = TRUE)) / BIO_AG_TOTAL * 100, 
            CARB_AG_TOTAL_SE = sqrt(sum(carbVar, na.rm = TRUE)) / CARB_AG_TOTAL * 100,
            ## Ratio variances
            bioAcreVar = (1 / AREA_TOTAL^2) * (sum(bioVar) + (BIO_AG_ACRE^2)*sum(aVar) - 2*BIO_AG_ACRE*sum(bioCV)),
            carbAcreVar = (1 / AREA_TOTAL^2) * (sum(carbVar) + (CARB_AG_ACRE^2)*sum(aVar) - 2*CARB_AG_ACRE*sum(carbCV)),
            BIO_AG_ACRE_SE = sqrt(sum(bioAcreVar, na.rm = TRUE)) / BIO_AG_ACRE * 100,
            CARB_AG_ACRE_SE = sqrt(sum(carbAcreVar, na.rm = TRUE)) / CARB_AG_ACRE * 100) %>%
  ## Re ordering, dropping variance
  select(YEAR, BIO_AG_ACRE, CARB_AG_ACRE, BIO_AG_TOTAL, CARB_AG_TOTAL, AREA_TOTAL, BIO_AG_ACRE_SE, 
         CARB_AG_ACRE_SE, BIO_AG_TOTAL_SE, CARB_AG_TOTAL_SE, AREA_TOTAL_SE)
```

Comparing with `rFIA`, we get a match!

```r
biomass(clipFIA(fiaRI), totals = TRUE)
```

```
##   YEAR NETVOL_ACRE SAWVOL_ACRE BIO_AG_ACRE BIO_BG_ACRE BIO_ACRE
## 1 2018    2491.167    1418.605    70.37259     13.9919 84.36449
##   CARB_AG_ACRE CARB_BG_ACRE CARB_ACRE NETVOL_ACRE_SE SAWVOL_ACRE_SE
## 1     35.18629     6.995952  42.18225       4.212767       7.184325
##   BIO_AG_ACRE_SE BIO_BG_ACRE_SE BIO_ACRE_SE CARB_AG_ACRE_SE
## 1       3.566183       3.555699    3.561156        3.566183
##   CARB_BG_ACRE_SE CARB_ACRE_SE NETVOL_TOTAL SAWVOL_TOTAL BIO_AG_TOTAL
## 1        3.555699     3.561156    914155471    520569323     25823833
##   BIO_BG_TOTAL BIO_TOTAL CARB_AG_TOTAL CARB_BG_TOTAL CARB_TOTAL AREA_TOTAL
## 1      5134451  30958284      12911916       2567225   15479142   366958.7
##   nPlots_VOL nPlots_AREA
## 1        126         127
```

```r
bio_pop
```

```
## # A tibble: 1 x 11
##    YEAR BIO_AG_ACRE CARB_AG_ACRE BIO_AG_TOTAL CARB_AG_TOTAL AREA_TOTAL
##   <int>       <dbl>        <dbl>        <dbl>         <dbl>      <dbl>
## 1  2018        70.4         35.2    25823833.     12911916.    366959.
## # … with 5 more variables: BIO_AG_ACRE_SE <dbl>, CARB_AG_ACRE_SE <dbl>,
## #   BIO_AG_TOTAL_SE <dbl>, CARB_AG_TOTAL_SE <dbl>, AREA_TOTAL_SE <dbl>
```

<br>

### _**Adding grouping variables**_
Unlike estimation without sampling errors, we can NOT just add grouping variables to the above procedures in our `group_by` call. Rather, we will need to account for absence points here (or zero-length outputs) or our estimates will be artificially inflated if groups are not mutually exclusive at the plot level. Example: The presence of red oak on a plot does not negate the potential presence of white ash on the same plot. Therefor, there should be a zero listed for each species not found on the plot. We accomplish this by treating each group as a seperate population, computing each individually, and then rejoining the groups at the end of the operation. 

First let's make a dataframe where each row defines a group that we want to estimate:

```r
## All groups we want to estimate 
grps <- data %>%
  group_by(YEAR, SPCD) %>%
  summarize()
```
  
Each row in `grps` now defines an individual population that we would like to produce estimates for, thus our end product should have the same number of rows. Thus, we can loop over each of the rows in `grps` and use the estimation procedures above to estimate attributes for each group.

Before we get started with the loop we need to find a way to define the population of interest for each interation (row). To do that, we will modify our  domain indicators from above to reflect whether or not an observation falls within the population defined by `grps[i,]`. Saving the original domain indicators as variables so they are not overwritten in the loop: 

```r
tDI <- data$tDI
aDI <- data$aDI
```

Now we can start our loop:

```r
## Let's store each output in a list
bio_pop <- list()
## Looping
for (i in 1:nrow(grps)){
  
  ## Tree domain indicator
  data$tDI <- tDI * if_else(data$SPCD == grps$SPCD[i], 1, 0) * if_else(data$YEAR == grps$YEAR[i], 1, 0)
  ## No need to modify the area domain indicator for SPCD, because
  ## we want to estimate all forested area within the year
  data$aDI <- aDI * if_else(data$YEAR == grps$YEAR[i], 1, 0)
  
  ## SAME AS ABOVE, JUST IN A LOOP NOW --> SIMILAR TO USING GROUP_BY
  ## Estimate Area attributes -- plot level
  tre_pop <- data %>%
    filter(EVAL_TYP == 'EXPVOL') %>%
    ## Make sure we only have unique observations of plots, trees, etc.
    distinct(ESTN_UNIT_CN, STRATUM_CN, PLT_CN, CONDID, SUBP, TREE, .keep_all = TRUE) %>%
    ## Plot-level estimates first (note we are NOT using EXPNS here)
    group_by(ESTN_UNIT_CN, STRATUM_CN, PLT_CN) %>%
    summarize(bioPlot = sum(DRYBIO_AG * TPA_UNADJ * tAdj * tDI  / 2000, na.rm = TRUE),
              carbPlot = sum(CARBON_AG * TPA_UNADJ * tAdj * tDI  / 2000, na.rm = TRUE)) 
  
  ## Estimate Area attributes -- plot level
  area_pop <- data %>%
    filter(EVAL_TYP == 'EXPCURR') %>%
    ## Make sure we only have unique observations of plots, trees, etc.
    distinct(ESTN_UNIT_CN, STRATUM_CN, PLT_CN, CONDID, .keep_all = TRUE) %>%
    ## Plot-level estimates first (multiplying by EXPNS here)
    ## Extra grouping variables are only here so they are carried through
    group_by(P1POINTCNT, P1PNTCNT_EU, P2POINTCNT, AREA_USED, ESTN_UNIT_CN, STRATUM_CN, PLT_CN) %>%
    summarize(forArea = sum(CONDPROP_UNADJ * aAdj * aDI, na.rm = TRUE))
  
  ## Joining the two tables
  bio_pop_plot <- left_join(tre_pop, area_pop)
  
  ## Now we can follow through with the remaining estimation procedures
  ## Strata level
  bio_pop_strat <- bio_pop_plot %>%
    group_by(ESTN_UNIT_CN, STRATUM_CN) %>%
    summarize(aStrat = mean(forArea, na.rm = TRUE), # Area mean
              bioStrat = mean(bioPlot, na.rm = TRUE), # Biomass mean
              carbStrat = mean(carbPlot, na.rm = TRUE), # Carbon mean
              ## We don't want a vector of these values, since they are repeated
              P2POINTCNT = first(P2POINTCNT),
              AREA_USED = first(AREA_USED),
              ## Strata weight, relative to estimation unit
              w = first(P1POINTCNT) / first(P1PNTCNT_EU),
              ## Strata level variances
              aVar = (sum(forArea^2) - sum(P2POINTCNT * aStrat^2)) / (P2POINTCNT * (P2POINTCNT-1)),
              bioVar = (sum(bioPlot^2) - sum(P2POINTCNT * bioStrat^2)) / (P2POINTCNT * (P2POINTCNT-1)),
              carbVar = (sum(carbPlot^2) - sum(P2POINTCNT * carbStrat^2)) / (P2POINTCNT * (P2POINTCNT-1)),
              ## Strata level co-varainces
              bioCV = (sum(forArea*bioPlot) - sum(P2POINTCNT * aStrat *bioStrat)) / (P2POINTCNT * (P2POINTCNT-1)),
              carbCV = (sum(forArea*carbPlot) - sum(P2POINTCNT * aStrat *carbStrat)) / (P2POINTCNT * (P2POINTCNT-1)))
  
  ## Moving on to the estimation unit
  bio_pop_eu <- bio_pop_strat %>%
    group_by(ESTN_UNIT_CN) %>%
    summarize(aEst = sum(aStrat * w, na.rm = TRUE) * first(AREA_USED), # Mean Area
              bioEst = sum(bioStrat * w, na.rm = TRUE) * first(AREA_USED), # Mean biomass
              carbEst = sum(carbStrat * w, na.rm = TRUE) * first(AREA_USED), # Mean carbon
              ## Estimation unit variances
              aVar = (first(AREA_USED)^2 / sum(P2POINTCNT)) * 
                (sum(P2POINTCNT*w*aVar) + sum((1-w)*(P2POINTCNT/sum(P2POINTCNT))*aVar)),
              bioVar = (first(AREA_USED)^2 / sum(P2POINTCNT)) * 
                (sum(P2POINTCNT*w*bioVar) + sum((1-w)*(P2POINTCNT/sum(P2POINTCNT))*bioVar)),
              carbVar = (first(AREA_USED)^2 / sum(P2POINTCNT)) * 
                (sum(P2POINTCNT*w*carbVar) + sum((1-w)*(P2POINTCNT/sum(P2POINTCNT))*carbVar)),
              ## Estimation unit covariances
              bioCV = (first(AREA_USED)^2 / sum(P2POINTCNT)) * 
                (sum(P2POINTCNT*w*bioCV) + sum((1-w)*(P2POINTCNT/sum(P2POINTCNT))*bioCV)),
              carbCV = (first(AREA_USED)^2 / sum(P2POINTCNT)) * 
                (sum(P2POINTCNT*w*carbCV) + sum((1-w)*(P2POINTCNT/sum(P2POINTCNT))*carbCV)))
  
  ## Finally, sum across Estimation Units for totals
  bio_pop_total <- bio_pop_eu %>%
    summarize(AREA_TOTAL = sum(aEst, na.rm = TRUE),
              BIO_AG_TOTAL = sum(bioEst, na.rm = TRUE),
              CARB_AG_TOTAL = sum(carbEst, na.rm = TRUE),
              ## Ratios
              BIO_AG_ACRE = BIO_AG_TOTAL / AREA_TOTAL,
              CARB_AG_ACRE = CARB_AG_TOTAL / AREA_TOTAL,
              ## Total samping errors
              AREA_TOTAL_SE = sqrt(sum(aVar, na.rm = TRUE)) / AREA_TOTAL * 100,
              BIO_AG_TOTAL_SE = sqrt(sum(bioVar, na.rm = TRUE)) / BIO_AG_TOTAL * 100, 
              CARB_AG_TOTAL_SE = sqrt(sum(carbVar, na.rm = TRUE)) / CARB_AG_TOTAL * 100,
              ## Ratio variances
              bioAcreVar = (1 / AREA_TOTAL^2) * (sum(bioVar) + (BIO_AG_ACRE^2)*sum(aVar) - 2*BIO_AG_ACRE*sum(bioCV)),
              carbAcreVar = (1 / AREA_TOTAL^2) * (sum(carbVar) + (CARB_AG_ACRE^2)*sum(aVar) - 2*CARB_AG_ACRE*sum(carbCV)),
              BIO_AG_ACRE_SE = sqrt(sum(bioAcreVar, na.rm = TRUE)) / BIO_AG_ACRE * 100,
              CARB_AG_ACRE_SE = sqrt(sum(carbAcreVar, na.rm = TRUE)) / CARB_AG_ACRE * 100) %>%
    ## Re ordering, dropping variance
    select(BIO_AG_ACRE, CARB_AG_ACRE, BIO_AG_TOTAL, CARB_AG_TOTAL, AREA_TOTAL, BIO_AG_ACRE_SE, 
           CARB_AG_ACRE_SE, BIO_AG_TOTAL_SE, CARB_AG_TOTAL_SE, AREA_TOTAL_SE)
  
  ## Saving the output in our list...
  bio_pop[[i]] <- bio_pop_total
}
```

Great, we have our estimates! Except they are locked up in a list. Converting back to a `data.frame` and rejoining with `grps`:

```r
bio_pop <- bind_rows(bio_pop)
bio_pop_sp <- bind_cols(grps, bio_pop)
```

Comparing with rFIA, we have a match!

```r
head(biomass(clipFIA(fiaRI), totals = TRUE, bySpecies = TRUE))
```

```
##   YEAR SPCD          COMMON_NAME        SCIENTIFIC_NAME NETVOL_ACRE
## 1 2018   12           balsam fir         Abies balsamea   0.4223927
## 2 2018   43 Atlantic white-cedar Chamaecyparis thyoides   2.6154887
## 3 2018   68     eastern redcedar   Juniperus virginiana   1.3420926
## 4 2018   96          blue spruce          Picea pungens   0.0000000
## 5 2018  126           pitch pine           Pinus rigida  55.7317053
## 6 2018  129   eastern white pine          Pinus strobus 480.8755624
##   SAWVOL_ACRE BIO_AG_ACRE BIO_BG_ACRE     BIO_ACRE CARB_AG_ACRE
## 1   0.0000000 0.006968316 0.001613069  0.008581385  0.003484158
## 2   0.7423384 0.040320445 0.009202693  0.049523139  0.020160223
## 3   0.0000000 0.030839290 0.007236642  0.038075931  0.015419645
## 4   0.0000000 0.000000000 0.000000000  0.000000000  0.000000000
## 5  43.7816108 1.182804881 0.269793871  1.452598752  0.591402441
## 6 405.6266240 8.523586094 1.937087954 10.460674048  4.261793056
##   CARB_BG_ACRE   CARB_ACRE NETVOL_ACRE_SE SAWVOL_ACRE_SE BIO_AG_ACRE_SE
## 1 0.0008065347 0.004290693      114.02897            NaN      114.02897
## 2 0.0046013467 0.024761569       57.53011       94.93053       56.39166
## 3 0.0036183212 0.019037966       71.57689            NaN       70.03731
## 4 0.0000000000 0.000000000            NaN            NaN            NaN
## 5 0.1348969363 0.726299378       47.90559       51.29705       47.60843
## 6 0.9685439854 5.230337042       19.28087       20.41315       18.68059
##   BIO_BG_ACRE_SE BIO_ACRE_SE CARB_AG_ACRE_SE CARB_BG_ACRE_SE CARB_ACRE_SE
## 1      114.02897   114.02897       114.02897       114.02897    114.02897
## 2       56.42615    56.39803        56.39166        56.42615     56.39803
## 3       69.42436    69.92003        70.03731        69.42436     69.92003
## 4            NaN         NaN             NaN             NaN          NaN
## 5       47.37650    47.56516        47.60843        47.37650     47.56516
## 6       18.60417    18.66636        18.68059        18.60417     18.66636
##   NETVOL_TOTAL SAWVOL_TOTAL BIO_AG_TOTAL BIO_BG_TOTAL   BIO_TOTAL
## 1     155000.7          0.0     2557.084     591.9299    3149.014
## 2     959776.3     272407.5    14795.938    3377.0084   18172.947
## 3     492492.6          0.0    11316.746    2655.5487   13972.294
## 4          0.0          0.0        0.000       0.0000       0.000
## 5   20451234.1   16066042.9   434040.540   99003.2079  533043.748
## 6  176461470.8  148848218.2  3127804.064  710831.2754 3838635.340
##   CARB_AG_TOTAL CARB_BG_TOTAL  CARB_TOTAL AREA_TOTAL nPlots_VOL
## 1      1278.542      295.9649    1574.507   366958.7          1
## 2      7397.969     1688.5042    9086.473   366958.7          3
## 3      5658.373     1327.7744    6986.147   366958.7          5
## 4         0.000        0.0000       0.000   366958.7          0
## 5    217020.270    49501.6043  266521.875   366958.7         10
## 6   1563902.036   355415.6408 1919317.676   366958.7         63
##   nPlots_AREA
## 1         127
## 2         127
## 3         127
## 4         127
## 5         127
## 6         127
```

```r
bio_pop_sp
```

```
## # A tibble: 50 x 12
## # Groups:   YEAR [1]
##     YEAR  SPCD BIO_AG_ACRE CARB_AG_ACRE BIO_AG_TOTAL CARB_AG_TOTAL
##    <int> <int>       <dbl>        <dbl>        <dbl>         <dbl>
##  1  2018    12     0.00697      0.00348        2557.         1279.
##  2  2018    43     0.0403       0.0202        14796.         7398.
##  3  2018    68     0.0308       0.0154        11317.         5658.
##  4  2018    96     0            0                 0             0 
##  5  2018   126     1.18         0.591        434041.       217020.
##  6  2018   129     8.52         4.26        3127804.      1563902.
##  7  2018   130     0.00314      0.00157        1153.          576.
##  8  2018   261     0.801        0.400        293835.       146918.
##  9  2018   313     0.0185       0.00924        6779.         3389.
## 10  2018   316    15.7          7.87        5777664.      2888832.
## # … with 40 more rows, and 6 more variables: AREA_TOTAL <dbl>,
## #   BIO_AG_ACRE_SE <dbl>, CARB_AG_ACRE_SE <dbl>, BIO_AG_TOTAL_SE <dbl>,
## #   CARB_AG_TOTAL_SE <dbl>, AREA_TOTAL_SE <dbl>
```

