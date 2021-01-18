---
title: Separating estimation of tree biomass and merchantable volume
author:
date: '2021-01-18'
slug: []
categories: []
tags: []
subtitle: ''
summary: ''
authors: []
lastmod: '2021-01-18T13:13:16-08:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---


rFIA v0.3.1 introduced breaking changes to the `biomass` function. Though we try to avoid breaking changes whenever possible, they are almost certainly for the better. Prior to v0.3.1, `biomass` supported two primary estimation objectives: estimation of (1) tree biomass/carbon and (2) merchantable volume. This combination made sense when we originally wrote `biomass`, but as rFIA matures and our user group grows, it's becoming clear to us that this pairing limits the value and flexibility inherent to FIA data.

As such, we're proud to announce a handful of improvements in tree biomass and merchantable volume estimation in rFIA v0.3.1. Specifically, the `biomass` function has been overhauled to focus solely on estimation of tree biomass and carbon, and offers enhanced flexibility in the estimation of *biomass components* (e.g., bole, limbs, coarse roots, etc.). In addition, v0.3.1 gives rise to the new `volume` function, which supersedes and expands upon the previous merchantable volume estimators implemented in `biomass`. Check out the examples below to get started!

<br>

### Estimating tree biomass components
___

Let's take the updates for a test drive, and show off how the new `biomass` can be used to estimate tree biomass components! As always, you can check out our documentation with `?biomass`:


```r
## Load data from the rFIA package
library(rFIA)
data(fiaRI)

## Total live tree aboveground biomass, excluding foliage (default)
biomass(fiaRI)
```

```
## # A tibble: 5 x 7
##    YEAR BIO_ACRE CARB_ACRE BIO_ACRE_SE CARB_ACRE_SE nPlots_TREE nPlots_AREA
##   <int>    <dbl>     <dbl>       <dbl>        <dbl>       <dbl>       <dbl>
## 1  2014     68.0      34.0        3.70         3.70         121         123
## 2  2015     69.1      34.6        3.67         3.67         122         124
## 3  2016     70.6      35.3        3.50         3.50         124         125
## 4  2017     70.8      35.4        3.57         3.57         124         125
## 5  2018     70.4      35.2        3.57         3.57         126         127
```

By default, `biomass` estimates total aboveground live tree biomass for all reporting years available in the `FIA.Database` (`treeType = "live"`, `component = "AG"`). Here aboveground tree biomass is a simple summation of biomass in the bole (including bark), tops and limbs, and the stumps of individual trees, and carbon is always assumed to comprise half of biomass.

But what if we're interested in estimating biomass within each of these components separately, e.g., we want an individual estimate for bole, tops and limbs, and others? Simply set the new `byComponent` argument to `TRUE`:

```r
biomass(db = clipFIA(fiaRI), 
        byComponent = TRUE)
```

```
## # A tibble: 7 x 8
##    YEAR COMPONENT BIO_ACRE CARB_ACRE BIO_ACRE_SE CARB_ACRE_SE nPlots_TREE
##   <int> <chr>        <dbl>     <dbl>       <dbl>        <dbl>       <dbl>
## 1  2018 BOLE         52.4     26.2          3.89         3.89         126
## 2  2018 FOLIAGE       1.96     0.978        4.93         4.93         126
## 3  2018 ROOTS        14.0      7.00         3.56         3.56         126
## 4  2018 SAPLING       2.62     1.31        13.3         13.3          126
## 5  2018 STUMP         2.85     1.42         3.32         3.32         126
## 6  2018 TOP          12.5      6.24         3.36         3.36         126
## 7  2018 WDLD_SPP      0        0          NaN          NaN            126
## # … with 1 more variable: nPlots_AREA <dbl>
```

Awesome, but what if we want to estimate biomass for some combination of these components, e.g., bole plus stump? The new `component` argument has our backs. Users can specify any combination components seen in the output above. For example, say we want to estimate abovegound biomass (`"AG"`) plus foliage (`"FOLIAGE"`):

```r
biomass(db = clipFIA(fiaRI), 
        component = c("AG", "FOLIAGE"))
```

```
## # A tibble: 1 x 7
##    YEAR BIO_ACRE CARB_ACRE BIO_ACRE_SE CARB_ACRE_SE nPlots_TREE nPlots_AREA
##   <int>    <dbl>     <dbl>       <dbl>        <dbl>       <dbl>       <dbl>
## 1  2018     72.3      36.2        3.56         3.56         126         127
```

```r
## Equivelantly, break out the components of "AG"
biomass(db = clipFIA(fiaRI), 
        component = c("BOLE", "STUMP", "TOP", "SAPLING", "FOLIAGE"))
```

```
## # A tibble: 1 x 7
##    YEAR BIO_ACRE CARB_ACRE BIO_ACRE_SE CARB_ACRE_SE nPlots_TREE nPlots_AREA
##   <int>    <dbl>     <dbl>       <dbl>        <dbl>       <dbl>       <dbl>
## 1  2018     72.3      36.2        3.56         3.56         126         127
```



<br>

### Estimating merchantable tree volume
___

Previously, `biomass` included support for estimation of net merchantable volume and net sawlog volume in units of cubic feet. The new volume function expands on this previous capacity in two key ways: (1) allowing use of alternative volume definitions used by the FIA program (i.e., net, sound, and gross volume), and (2) offering estimates of sawlog volume in units of cubic feet (CF) and thousand board feet (MBF; International 1/4 inch rule). 

By default, `volume` will estimate net volume of live trees (`volType = "NET"` and `treeType = "live"`):

```r
volume(db = fiaRI)
```

```
## # A tibble: 5 x 9
##    YEAR BOLE_CF_ACRE SAW_CF_ACRE SAW_MBF_ACRE BOLE_CF_ACRE_SE SAW_CF_ACRE_SE
##   <int>        <dbl>       <dbl>        <dbl>           <dbl>          <dbl>
## 1  2014        2396.       1356.         7.24            4.33           7.29
## 2  2015        2438.       1385.         7.41            4.23           7.25
## 3  2016        2491.       1419.         7.58            4.13           7.11
## 4  2017        2500.       1422.         7.63            4.21           7.20
## 5  2018        2491.       1419.         7.64            4.21           7.18
## # … with 3 more variables: SAW_MBF_ACRE_SE <dbl>, nPlots_TREE <dbl>,
## #   nPlots_AREA <dbl>
```

Here, `BOLE_CF_ACRE` gives us merchantable bole volume per acre, `SAW_CF_ACRE` gives us sawlog volume in cubic feet per acre, and `SAW_MBF_ACRE` gives us sawlog volume in thousand board feet per acre. 

We can change our volume definition using the `volType` argument. Let's try gross volume instead:

```r
volume(db = fiaRI,
       volType = 'gross')
```

```
## # A tibble: 5 x 9
##    YEAR BOLE_CF_ACRE SAW_CF_ACRE SAW_MBF_ACRE BOLE_CF_ACRE_SE SAW_CF_ACRE_SE
##   <int>        <dbl>       <dbl>        <dbl>           <dbl>          <dbl>
## 1  2014        2805.       1536.         8.21            4.21           7.24
## 2  2015        2856.       1569.         8.41            4.09           7.20
## 3  2016        2924.       1606.         8.59            3.96           7.06
## 4  2017        2941.       1613.         8.68            4.02           7.15
## 5  2018        2929.       1611.         8.69            4.02           7.13
## # … with 3 more variables: SAW_MBF_ACRE_SE <dbl>, nPlots_TREE <dbl>,
## #   nPlots_AREA <dbl>
```

So what do these different definitions mean? FIA defines net volume (`volType="NET"`) as: "net volume of wood in the central stem of a sample tree 5.0 inches d.b.h., from a 1-foot stump to a minimum 4-inch top diameter, or to where the central stem breaks into limbs all of which are <4.0 inches in diameter... Does not include rotten, missing, and form cull (volume loss due to rotten, missing, and form cull defect has been deducted)". In `volume`, we could also choose from two alternative definitions: sound volume (`volType = "SOUND"`) or gross volume (`volType = "GROSS"`). Sound volume is identical to net volume except that sound includes volume from portions of the stem that are be considered "form cull" under the net volume definition (e.g., sweep). In contrast, gross volume is identical to the net volume definition except that gross includes volume from portions of the stem that are rotten, missing, and considered form cull.

