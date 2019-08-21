---
title: Estimating Forest Attributes
linktitle: Estimating Forest Attributes
toc: true
type: docs
date: "2019-05-05T00:00:00+01:00"
draft: false
menu:
  tutorial:
    parent: Overview
    weight: 2

# Prev/next pager order (if `docs_section_pager` enabled in `params.toml`)
weight: 2
---
___

Now that you have loaded your FIA data into R, it's time to put it to work. Let's explore the basic functionality of `rFIA` with `tpa`, a function to compute tree abundance estimates (TPA, BAA, & relative abundance (%)) from FIA data, and `fiaRI`, a subset of the FIA Database for Rhode Island including all inventories up to 2017.  

{{% alert note %}}
The two example datasets used below are included with `rFIA`. **Copy and paste the code below into R to follow along!**
{{% /alert %}}

<br>

## _**Spatial and temporal queries**_
Are you only interested in producing estimates for a specific inventory year or within a portion of your state? `clipFIA` allows you to easily query (subset) your FIA.Database object so you only use the data you need. This will conserve RAM on your machine and speed processing time. 

#### Load some data

```{r}
## Load rFIA package
library(rFIA)

## Load some data
data('fiaRI')
data('countiesRI')
```

#### Most recent subsets
To subset only the data needed to produce estimates for the most recent inventory year (2017 in our case), users can simply pass thier `FIA.Database` object to `clipFIA`, or more explicitly specify `mostRecent = TRUE` in the call:
```{r}
## Most Recent Subset (2017)
riMR <- clipFIA(fiaRI) 

# More explicity (identical to above)
riMR <- clipFIA(fiaRI, mostRecent = TRUE)
```

#### Spatial subsets
To subset the data required to produce estimates within an user-defined areal region (should be contained within the spatial extent of the FIA.Database object), simply pass a spatial polygon object (from `sp` or `sf` packages) to the `mask` argument of `clipFIA`. In our example below, the spatial subset does little to reduce the size of our FIA.Database object, although the effect is likely to be much more substantial if applied to larger state or region.
```{r}
## Select Kent County RI
kc <- countiesRI[2,] ## SF Multipolygon object

## Subset the data
riKC <- clipFIA(fiaRI, mask = kc, mostRecent = FALSE)

## Most recent subset, within Kent County
riKC <- clipFIA(fiaRI, mask = kc)
```
{{% alert note %}}
If you plot FIA plot locations following a spatial subset, you will often find that some FIA plots fall outside of the mask boundary. *The FIA plots falling beyond the bounds of your spatial mask are necessary to estimate sampling errors for the region within the mask, and do not affect population total or ratio estimates*.
{{% /alert %}}

<br>

## _**Basic estimates**_
To produce tree abundance estimates and associated sampling errors for the state of Rhode Island, simply hand your `FIA.Database` object to the `db` argument of `tpa()`:
```{r}
## TPA & BAA for the most recent inventory year
tpaRI_MR <- tpa(riMR)

## All Inventory Years Available (i.e., returns a time series)
tpaRI <- tpa(fiaRI)
```
{{% alert note %}}
If you would like to return estimates of population totals (e.g. total trees) along with ratio estimates (e.g. mean trees/acre), specify `totals = TRUE` in the call to `tpa`. If you do not want to estimate sampling errors, specify `SE = FALSE` (often much faster).
{{% /alert %}}

<br>

## _**Grouping by species and size class**_
What if I want to group estimates by species? How about by size class? Easy! Just specify `bySpecies` and/ or `bySizeClass` as `TRUE` in the call to `tpa`. By default, estimates are returned within 2 inch size classes, but you can make your own size classes using `makeClasses`!
```{r}
## Group estimates by species
tpaRI_species <- tpa(riMR, bySpecies = TRUE)

## Group estimates by size class
tpaRI_sizeClass <- tpa(fiaRI_MR, bySizeClass = TRUE)

## Group by species and size class, and plot the distribution 
tpaRI_spsc <- tpa(fiaRI_MR, bySpecies = TRUE, bySizeClass = TRUE)
```

<br>

## _**Grouping by other variables**_
To group estimates by a variable defined the FIA Database (other than species or size class), pass the variable name to the `grpBy` argument of `tpa`. You can find definitions of all variables in the FIA Database in the the [FIADB User Guide](https://www.fia.fs.fed.us/library/database-documentation/current/ver80/FIADB%20User%20Guide%20P2_8-0.pdf). Variables of interest will most likely be contained in the condition (COND), plot (PLOT), or tree (TREE) tables.

``` {r}
## grpBy specifies what to group estimates by (just like species and size class above)
## NOTICE the variable names passed to grpBy are NOT quoted

# Ownership Group
tpaRI_own <- tpa(fiaRI_MR, grpBy = OWNGRPCD)

# Site Productivity Class
tpaRI_spc <- tpa(fiaRI_MR, grpBy = SITECLCD)

# Forest Type
tpaRI_ft <- tpa(fiaRI_MR, grpBy = FORTYPCD)

## Combining multiple grouping variables: Site Productivity within Forest Types
tpaRI_ftspc <- tpa(fiaRI_MR, grpBy = c(FORTYPCD, SITECLCD))
```

{{% alert note %}}
Variable names passed to `grpBy` should NOT be quoted. Multiple grouping variables should be combined with c(), and grouping will occur heirarchically. For example, to produce seperate estimates for each ownership group within ecoregion subsections, specify c(ECOSUBCD, OWNGRPCD).
{{% /alert %}}


<br>

## _**Unique areas or trees of interest**_
Do you want estimates for a specific type of tree (ex. greater than 12-inches DBH and in a canopy dominant or subdominant position) in specific area (ex. growing on mesic sites)? Each of these specifications are described in the FIA Database, and all `rFIA` estimator functions can leverage these data to easily implement complex queries!

For a conditions related to trees of interest (e.g. diameter, height, crown class, etc.) pass a logical statement to `treeDomain`. For conditions related to area(e.g. ecoregions, counties, forest types, etc.), pass a logical statement to `areaDomain`. *These statements should NOT be quoted.*

```{r}
## Estimate abundance of trees greater than 12-inches DBH in a dominant 
## or subdominant canopy position growing on mesic sites
tpaRI_domain <- tpa(fiaRI_MR, 
                 treeDomain = DIA > 12 & CCLCD %in% c(1,2),
                 areaDomain = PHYSCLCD %in% 20:29)
                 
## In the code above, DIA describes the DBH of stems, 
## CCLCD thier canopy position, and PHYSCLCD the 
## physiographic class upon which the class occurs
```

<br>



## _**Visualization**_


<br>

## _**Simple, easy parallelization**_
All `rFIA` estimator functions (as well as `readFIA` and `getFIA`) can be implemented in parallel, using the `nCores` argument. By default, processing is implemented serially `nCores = 1`, although users may find substantial increases in efficiency by increasing `nCores`. 

Parallelization is implemented with the parallel package. Parallel implementation is achieved using a snow type cluster on any Windows OS, and with multicore forking on any Unix OS (Linux, Mac). Implementing parallel processing may substantially decrease free memory during processing, particularly on Windows OS. Thus, users should be cautious when running in parallel, and consider implementing serial processing for this task if computational resources are limited (nCores = 1).

``` {r}
## Check the number of cores available on your machine 
## Requires the parallel package, run library(parallel)
detectCores(logical = FALSE)

## On our machine, we find we have 4 physical cores. 
## To speed processing, we will split the workload 
## across 3 of these cores using nCores = 3
tpaRI_par <- tpa(fiaRI, nCores = 3)
```
<br>

## _**Other rFIA functions**_

