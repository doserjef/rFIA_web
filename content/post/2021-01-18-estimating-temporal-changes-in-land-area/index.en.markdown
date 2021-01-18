---
title: Estimating temporal changes in land area
author: hunter
date: '2021-01-18'
slug: []
categories: []
tags: []
subtitle: ''
summary: ''
authors: []
lastmod: '2021-01-18T13:29:20-08:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---

The increasing availability of remeasured FIA plots offers the unique opportunity to move from asking questions about the *status* of forest resources, to questions of how resources has *changed* over time. For example, we could use the `area` function in rFIA to determine the relative land area occupied by various forest types in a landscape or region of interest, i.e., it's current composition. But how has the composition of that landscape changed in recent decades? What are the primary drivers of such change? And how does this shape our thinking of what the landscape will look like in the future? 

rFIA v0.3.1 gave rise to the `areaChange` function, which allows us to address such questions using FIA data alone. 

By default, `areaChange` will estimate *net* annual change in forest land area within a region over time. As always, you can check out our complete documentation with `?areaChange`:

```r
library(rFIA)

## Get a subset fo data for Rhode Island
ri <- getFIA('RI')

## Estimate change in forestland area
areaChange(ri)
```

```
## # A tibble: 12 x 8
##     YEAR PERC_CHNG AREA_CHNG PREV_AREA PERC_CHNG_SE AREA_CHNG_SE PREV_AREA_SE
##    <int>     <dbl>     <dbl>     <dbl>        <dbl>        <dbl>        <dbl>
##  1  2008   -0.612     -2383.   389114.        10.5          84.0        10.4 
##  2  2009   -0.424     -1411.   332902.         6.37         92.5         6.17
##  3  2010   -0.590     -2108.   357309.         4.97         61.4         4.82
##  4  2011   -0.131      -466.   356992.         5.59        302.          4.52
##  5  2012    0.104       377.   363420.         5.56        369.          3.89
##  6  2013    0.224       833.   371634.         4.21        175.          3.57
##  7  2014    0.329      1213.   368937.         4.08        114.          3.74
##  8  2015    0.383      1404.   366790.         4.07         90.4         3.78
##  9  2016    0.0473      173.   366439.         9.12        702.          3.91
## 10  2017    0.0909      331.   363600.         6.50        413.          3.86
## 11  2018   -0.0656     -238.   363831.         5.46        535.          3.85
## 12  2019   -0.567     -2099.   370239.         3.36         58.6         3.45
## # … with 1 more variable: nPlots_AREA <dbl>
```

Here `AREA_CHNG` is the estimated annual change in forest land area in acres, and `PERC_CHNG` is the estimated annual change as a percentage of previous total forestland. Importantly, the values estimated above are *net* changes (`chngType="NET"`), i.e., representing the combined effects of reversion (non-forest becoming forest) and diversion (forest becoming non-forest). 

Often, however, examining the *components of change* can yield valuable insight unto the drivers of net changes in forest resources. As such, `areaChange` allows us to explicitly estimate change components when `chngType = "component"`. In our simple example, this means estimating the annual rates of reversion and diversion in our region:

```r
## Estimate change in forestland area
areaChange(ri,
           chngType = 'component')
```

```
## # A tibble: 24 x 6
##     YEAR STATUS1    STATUS2    AREA_CHNG AREA_CHNG_SE nPlots_AREA
##    <int> <chr>      <chr>          <dbl>        <dbl>       <dbl>
##  1  2008 Forest     Non-forest     2654.         73.9           3
##  2  2008 Non-forest Forest          272.        106.            2
##  3  2009 Forest     Non-forest     2281.         53.3           5
##  4  2009 Non-forest Forest          869.         49.7           5
##  5  2010 Forest     Non-forest     3313.         35.8          10
##  6  2010 Non-forest Forest         1205.         40.1           9
##  7  2011 Forest     Non-forest     2648.         35.7          10
##  8  2011 Non-forest Forest         2182.         46.8          12
##  9  2012 Forest     Non-forest     2397.         33.5          11
## 10  2012 Non-forest Forest         2774.         39.8          16
## # … with 14 more rows
```
Here `STATUS1` and `STATUS2` represent the land classification at first and second measurements, respectively. For the 2018 inventory, we estimate that 6,827 acres of forestland were diverted to a non-forest land use annually, and 3,614 acres of non-forest were reverted back to the forest land base. Here our losses (3,102 acres) exceed our gains (1,003 acres), and their difference is equal to the net change we estimated two steps above (-2,099 acres). 

We can extend this example by examining patterns of change across some variable of interest, let's say ownership classes:

```r
## Estimate NET change in forestland area
areaChange(clipFIA(ri),
           grpBy = OWNGRPCD,
           chngType = 'net')
```

```
## # A tibble: 2 x 9
##    YEAR OWNGRPCD PERC_CHNG AREA_CHNG PREV_AREA PERC_CHNG_SE AREA_CHNG_SE
##   <int>    <int>     <dbl>     <dbl>     <dbl>        <dbl>        <dbl>
## 1  2019       30    -0.111     -126.   113858.        11.3         722. 
## 2  2019       40    -0.770    -1973.   256381.         5.45         55.0
## # … with 2 more variables: PREV_AREA_SE <dbl>, nPlots_AREA <dbl>
```

```r
## Estimate COMPONENT change in forestland area
areaChange(clipFIA(ri),
           grpBy = OWNGRPCD,
           chngType = 'component')
```

```
## # A tibble: 6 x 8
##    YEAR OWNGRPCD1 OWNGRPCD2 STATUS1  STATUS2  AREA_CHNG AREA_CHNG_SE nPlots_AREA
##   <int>     <int>     <int> <chr>    <chr>        <dbl>        <dbl>       <dbl>
## 1  2019        30        40 Forest   Forest        152.         92.5           1
## 2  2019        30        NA Forest   Non-for…     1019.         49.2           6
## 3  2019        40        30 Forest   Forest        454.         91.7           1
## 4  2019        40        NA Forest   Non-for…     2083.         45.5          10
## 5  2019        NA        30 Non-for… Forest        591.         91.1           2
## 6  2019        NA        40 Non-for… Forest        413.         58.8           6
```
Note that when, `grpBy` is specified, change components are estimated for all shifts in forest land area across the classified attributes represented by the variables (first and second measurements again denoted by the suffix 1 and 2). In our case this means `OWNGRPCD1` indicates ownership at initial measurement and `OWNGRPCD2` is ownership at final measurement. Unfortunately, ownership group is unavailable for non-forest conditions and hence initial ownership is listed as `NA` for all non-forest to forest conversions. 
