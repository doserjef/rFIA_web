---
title: Estimating individual-tree and population growth rates
author: hunter
date: '2021-01-21'
slug: []
categories: []
tags: []
subtitle: ''
summary: ''
authors: []
lastmod: '2021-01-21T17:59:57-08:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---
<script src="{{< blogdown/postref >}}index.en_files/kePrint/kePrint.js"></script>
<link href="{{< blogdown/postref >}}index.en_files/lightable/lightable.css" rel="stylesheet" />
<script src="{{< blogdown/postref >}}index.en_files/kePrint/kePrint.js"></script>
<link href="{{< blogdown/postref >}}index.en_files/lightable/lightable.css" rel="stylesheet" />

We can use FIA data to estimate how forest structure has changed over time (i.e., has density increased or declined) or to estimate the average rate at which individual trees grow. Here we show how we can use the `vitalRates` function in rFIA to do just that.

For this specific example, we'll focus on estimating average annual change in individual tree basal area and cumulative tree basal area per acre, by site productivity class (SITECLCD) and species across the states of Washington and Oregon. 

Before we get started, you'll need rFIA v0.3.2 to run the examples below. You can check which version you have installed with `packageVersion('rFIA')`. If you have an older version, you can update with `devtools::install_github('hunter-stanke/rFIA')`. Also, if you'd rather download the script that details the analysis presented below, you can get it <a href="/files/ba_growth_example_pnw.R" target="_blank">here</a>.

<br>

So first, we'll need to download some data (you can skip this step if you already have FIA data for WA and OR). Here we use `getFIA` to download and save the state subsets to our computer:

```r
library(rFIA)
library(dplyr)

## Download some FIA data from the DataMart ------------------------------------
getFIA(states = c('OR', 'WA'),
       dir = 'path/to/save/FIA/data',
       load = FALSE) # Download, but don't load yet
```


Next we'll read our data into R with `readFIA` and take a most recent subset across states with `clipFIA`:

```r
## Setting up the database - "remote" in this case, but you can read all the data
## into RAM if you want to modify columns/ etc by setting inMemory = TRUE
db <- readFIA(dir = fiaPath,
              states = c('OR', 'WA'), # If you keep all your data together
              nCores = cores,
              inMemory = FALSE) # Set to TRUE if your computer has enough RAM


## Take the most recent subset -------------------------------------------------
db <- clipFIA(db,
              mostRecent = TRUE)
```

<br>

Now that we have our data loaded, we can start estimating tree growth rates! First, we'll estimate *net* growth rates, i.e., we will include trees that have recruited or died in our estimates of tree growth. Note that net growth can be negative if mortality exceeds recruitment and growth on live trees. This type of growth estimate is most useful if we're interested in characterizing population-level change. For example, if we'd like to know how the average rate at which cumulative basal area per acre has changed in our population of interest, we'd shoot for net growth. Here's how we do it with rFIA, where net growth is indicated by the argument `treeType = 'all'`:

```r
## Net annual change
net <- vitalRates(db,
                  treeType = 'all', # "all" indicates net growth
                  grpBy = SITECLCD, # Grouping by site productivity class
                  bySpecies = TRUE, # also grouping by species
                  variance = TRUE)
```

If we are instead interested in characterizing the average annual growth rate of individual trees, we'd most likely want to exclude stems that died or recruited into the population between plot measurements. To do this with rFIA, simply set `treeType = 'live'`:

```r
## Annual growth on live trees that remained live
live <- vitalRates(db,
                   treeType = 'live', # "live" excludes mortality and recruitment
                   grpBy = SITECLCD, # Grouping by site productivity class
                   bySpecies = TRUE, # also grouping by species
                   variance = TRUE)
```


<br>

By default, `vitalRates` will estimate average annual DBH, basal area, biomass, and net volume growth rates for *individual stems*, along with average annual basal area, biomass, and net volume growth *per acre*. Here we'll focus in on basal area, so let's simplify and pretty up our tables a bit:

```r
## Net annual change
net <- net %>%
  ## Dropping unnecessary columns
  select(SITECLCD, COMMON_NAME, SCIENTIFIC_NAME, SPCD,
         BA_GROW, BA_GROW_AC, BA_GROW_VAR, BA_GROW_AC_VAR, nPlots_TREE, N) %>%
  ## Dropping rows with no live trees (growth was NA)
  filter(!is.na(BA_GROW)) %>%
  ## Making SITECLCD more informative
  mutate(site = case_when(SITECLCD == 1 ~ "225+ cubic feet/acre/year",
                          SITECLCD == 2 ~ "165-224 cubic feet/acre/year",
                          SITECLCD == 3 ~ "120-164 cubic feet/acre/year",
                          SITECLCD == 4 ~ "85-119 cubic feet/acre/year",
                          SITECLCD == 5 ~ "50-84 cubic feet/acre/year",
                          SITECLCD == 6 ~ "20-49 cubic feet/acre/year",
                          SITECLCD == 7 ~ "0-19 cubic feet/acre/year")) %>%
  ## Arrange it nicely
  select(COMMON_NAME, SCIENTIFIC_NAME, SITECLCD, site, everything()) %>%
  arrange(COMMON_NAME, SCIENTIFIC_NAME, SITECLCD, site)

## Annual growth on live trees that remained live
live <- live %>%
  ## Dropping unnecessary columns
  select(SITECLCD, COMMON_NAME, SCIENTIFIC_NAME, SPCD,
         BA_GROW, BA_GROW_AC, BA_GROW_VAR, BA_GROW_AC_VAR, nPlots_TREE, N) %>%
  ## Dropping rows with no live trees (growth was NA)
  filter(!is.na(BA_GROW)) %>%
  ## Making SITECLCD more informative
  mutate(siteProd = case_when(SITECLCD == 1 ~ "225+ cubic feet/acre/year",
                          SITECLCD == 2 ~ "165-224 cubic feet/acre/year",
                          SITECLCD == 3 ~ "120-164 cubic feet/acre/year",
                          SITECLCD == 4 ~ "85-119 cubic feet/acre/year",
                          SITECLCD == 5 ~ "50-84 cubic feet/acre/year",
                          SITECLCD == 6 ~ "20-49 cubic feet/acre/year",
                          SITECLCD == 7 ~ "0-19 cubic feet/acre/year")) %>%
  ## Arrange it nicely
  select(COMMON_NAME, SCIENTIFIC_NAME, SITECLCD, siteProd, everything()) %>%
  arrange(COMMON_NAME, SCIENTIFIC_NAME, SITECLCD, siteProd)
```

<br>

Here `BA_GROW` gives us annual basal area growth per tree in square feet/year, and `BA_GROW_AC` gives us average basal area growth per acre in square feet/acre/year. But maybe we'd prefer units to be square centimeters instead - just remember to multiply the variance by the square of the conversion factor!


```r
## Net annual change
net <- net %>%
  ## Convert to square centimeters instead of square feet
  mutate(BA_GROW = BA_GROW * 929.03,
         BA_GROW_AC = BA_GROW_AC * 929.03,
         BA_GROW_VAR = BA_GROW_VAR * (929.03^2),
          BA_GROW_AC_VAR = BA_GROW_AC_VAR * (929.03^2))

## Annual growth on live trees that remained live
live <- live %>%
  ## Convert to square centimeters instead of square feet
  mutate(BA_GROW = BA_GROW * 929.03,
         BA_GROW_AC = BA_GROW_AC * 929.03,
         BA_GROW_VAR = BA_GROW_VAR * (929.03^2),
          BA_GROW_AC_VAR = BA_GROW_AC_VAR * (929.03^2))
```


<br>

Now let's take a look at what we've got!




## Net Growth
<div style="border: 1px solid #ddd; padding: 0px; overflow-y: scroll; height:500px; overflow-x: scroll; width:100%; "><table class=" lightable-material lightable-striped lightable-hover table" style='font-family: "Source Sans Pro", helvetica, sans-serif; margin-left: auto; margin-right: auto; font-size: 13px; margin-left: auto; margin-right: auto;'>
 <thead>
  <tr>
   <th style="text-align:left;position: sticky; top:0; background-color: #FFFFFF;"> COMMON_NAME </th>
   <th style="text-align:left;position: sticky; top:0; background-color: #FFFFFF;"> SCIENTIFIC_NAME </th>
   <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> SITECLCD </th>
   <th style="text-align:left;position: sticky; top:0; background-color: #FFFFFF;"> siteProd </th>
   <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> SPCD </th>
   <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> BA_GROW </th>
   <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> BA_GROW_AC </th>
   <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> BA_GROW_VAR </th>
   <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> BA_GROW_AC_VAR </th>
   <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> nPlots_TREE </th>
   <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> N </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Alaska yellow-cedar </td>
   <td style="text-align:left;"> Chamaecyparis nootkatensis </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 42 </td>
   <td style="text-align:right;"> 4.5302522 </td>
   <td style="text-align:right;"> 0.1333847 </td>
   <td style="text-align:right;"> 2.436709e+01 </td>
   <td style="text-align:right;"> 1.336820e-02 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 2621 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Alaska yellow-cedar </td>
   <td style="text-align:left;"> Chamaecyparis nootkatensis </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 42 </td>
   <td style="text-align:right;"> -2.0692878 </td>
   <td style="text-align:right;"> -0.3750559 </td>
   <td style="text-align:right;"> 8.127647e+01 </td>
   <td style="text-align:right;"> 2.678506e+00 </td>
   <td style="text-align:right;"> 36 </td>
   <td style="text-align:right;"> 20188 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Alaska yellow-cedar </td>
   <td style="text-align:left;"> Chamaecyparis nootkatensis </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 42 </td>
   <td style="text-align:right;"> 4.6571817 </td>
   <td style="text-align:right;"> 3.6370030 </td>
   <td style="text-align:right;"> 4.996272e+00 </td>
   <td style="text-align:right;"> 4.453081e+00 </td>
   <td style="text-align:right;"> 26 </td>
   <td style="text-align:right;"> 13582 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Alaska yellow-cedar </td>
   <td style="text-align:left;"> Chamaecyparis nootkatensis </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 42 </td>
   <td style="text-align:right;"> 2.2751397 </td>
   <td style="text-align:right;"> 2.0323542 </td>
   <td style="text-align:right;"> 2.444168e+00 </td>
   <td style="text-align:right;"> 2.066196e+00 </td>
   <td style="text-align:right;"> 39 </td>
   <td style="text-align:right;"> 13871 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Alaska yellow-cedar </td>
   <td style="text-align:left;"> Chamaecyparis nootkatensis </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 42 </td>
   <td style="text-align:right;"> 3.7005685 </td>
   <td style="text-align:right;"> 3.1719687 </td>
   <td style="text-align:right;"> 8.495847e-01 </td>
   <td style="text-align:right;"> 1.432161e+00 </td>
   <td style="text-align:right;"> 30 </td>
   <td style="text-align:right;"> 13582 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Alaska yellow-cedar </td>
   <td style="text-align:left;"> Chamaecyparis nootkatensis </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 42 </td>
   <td style="text-align:right;"> 0.8739005 </td>
   <td style="text-align:right;"> 0.3445023 </td>
   <td style="text-align:right;"> 1.640684e+01 </td>
   <td style="text-align:right;"> 2.420063e+00 </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 7427 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> bigleaf maple </td>
   <td style="text-align:left;"> Acer macrophyllum </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 312 </td>
   <td style="text-align:right;"> 2.3720068 </td>
   <td style="text-align:right;"> 2.7563090 </td>
   <td style="text-align:right;"> 4.017581e+01 </td>
   <td style="text-align:right;"> 6.033207e+01 </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> bigleaf maple </td>
   <td style="text-align:left;"> Acer macrophyllum </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 312 </td>
   <td style="text-align:right;"> 12.7997953 </td>
   <td style="text-align:right;"> 110.1075103 </td>
   <td style="text-align:right;"> 1.684897e+00 </td>
   <td style="text-align:right;"> 2.273716e+02 </td>
   <td style="text-align:right;"> 334 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> bigleaf maple </td>
   <td style="text-align:left;"> Acer macrophyllum </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 312 </td>
   <td style="text-align:right;"> 11.4093970 </td>
   <td style="text-align:right;"> 87.4847640 </td>
   <td style="text-align:right;"> 7.489134e-01 </td>
   <td style="text-align:right;"> 1.660946e+02 </td>
   <td style="text-align:right;"> 413 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> bigleaf maple </td>
   <td style="text-align:left;"> Acer macrophyllum </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 312 </td>
   <td style="text-align:right;"> 11.1969059 </td>
   <td style="text-align:right;"> 26.7989459 </td>
   <td style="text-align:right;"> 2.502400e+00 </td>
   <td style="text-align:right;"> 3.538977e+01 </td>
   <td style="text-align:right;"> 181 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> bigleaf maple </td>
   <td style="text-align:left;"> Acer macrophyllum </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 312 </td>
   <td style="text-align:right;"> 1.8722052 </td>
   <td style="text-align:right;"> 0.9832745 </td>
   <td style="text-align:right;"> 2.687023e+01 </td>
   <td style="text-align:right;"> 7.595077e+00 </td>
   <td style="text-align:right;"> 62 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> bigleaf maple </td>
   <td style="text-align:left;"> Acer macrophyllum </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 312 </td>
   <td style="text-align:right;"> 9.5137831 </td>
   <td style="text-align:right;"> 2.7939586 </td>
   <td style="text-align:right;"> 4.986263e-01 </td>
   <td style="text-align:right;"> 2.514876e+00 </td>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> bigleaf maple </td>
   <td style="text-align:left;"> Acer macrophyllum </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 312 </td>
   <td style="text-align:right;"> -9.3956027 </td>
   <td style="text-align:right;"> -4.8032456 </td>
   <td style="text-align:right;"> 1.665452e+02 </td>
   <td style="text-align:right;"> 6.699915e+01 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 20188 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> bitter cherry </td>
   <td style="text-align:left;"> Prunus emarginata </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 768 </td>
   <td style="text-align:right;"> -13.7282288 </td>
   <td style="text-align:right;"> -1.0508242 </td>
   <td style="text-align:right;"> 8.268660e-02 </td>
   <td style="text-align:right;"> 5.768732e-01 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 13792 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> bitter cherry </td>
   <td style="text-align:left;"> Prunus emarginata </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 768 </td>
   <td style="text-align:right;"> 8.7746400 </td>
   <td style="text-align:right;"> 11.8133756 </td>
   <td style="text-align:right;"> 3.550604e+00 </td>
   <td style="text-align:right;"> 1.123246e+01 </td>
   <td style="text-align:right;"> 130 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> bitter cherry </td>
   <td style="text-align:left;"> Prunus emarginata </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 768 </td>
   <td style="text-align:right;"> 7.1064021 </td>
   <td style="text-align:right;"> 5.5988933 </td>
   <td style="text-align:right;"> 3.246697e+00 </td>
   <td style="text-align:right;"> 3.032597e+00 </td>
   <td style="text-align:right;"> 113 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> bitter cherry </td>
   <td style="text-align:left;"> Prunus emarginata </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 768 </td>
   <td style="text-align:right;"> 9.3232217 </td>
   <td style="text-align:right;"> 1.5997823 </td>
   <td style="text-align:right;"> 8.542575e+00 </td>
   <td style="text-align:right;"> 5.190801e-01 </td>
   <td style="text-align:right;"> 38 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> bitter cherry </td>
   <td style="text-align:left;"> Prunus emarginata </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 768 </td>
   <td style="text-align:right;"> 5.1079515 </td>
   <td style="text-align:right;"> 0.5712330 </td>
   <td style="text-align:right;"> 1.265928e+01 </td>
   <td style="text-align:right;"> 1.109897e-01 </td>
   <td style="text-align:right;"> 35 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> bitter cherry </td>
   <td style="text-align:left;"> Prunus emarginata </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 768 </td>
   <td style="text-align:right;"> 12.7973991 </td>
   <td style="text-align:right;"> 0.8906745 </td>
   <td style="text-align:right;"> 1.501824e+01 </td>
   <td style="text-align:right;"> 2.892905e-01 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> bitter cherry </td>
   <td style="text-align:left;"> Prunus emarginata </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 768 </td>
   <td style="text-align:right;"> 4.0696924 </td>
   <td style="text-align:right;"> 0.1606563 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 2.391970e-02 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 11171 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> black cottonwood </td>
   <td style="text-align:left;"> Populus balsamifera </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 747 </td>
   <td style="text-align:right;"> 40.4678846 </td>
   <td style="text-align:right;"> 2.5139709 </td>
   <td style="text-align:right;"> 4.242229e+00 </td>
   <td style="text-align:right;"> 3.859107e+00 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 4565 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> black cottonwood </td>
   <td style="text-align:left;"> Populus balsamifera </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 747 </td>
   <td style="text-align:right;"> 12.8225826 </td>
   <td style="text-align:right;"> 7.7020155 </td>
   <td style="text-align:right;"> 1.188693e+02 </td>
   <td style="text-align:right;"> 4.945638e+01 </td>
   <td style="text-align:right;"> 53 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> black cottonwood </td>
   <td style="text-align:left;"> Populus balsamifera </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 747 </td>
   <td style="text-align:right;"> 19.9345175 </td>
   <td style="text-align:right;"> 11.6047028 </td>
   <td style="text-align:right;"> 5.744631e+01 </td>
   <td style="text-align:right;"> 2.431097e+01 </td>
   <td style="text-align:right;"> 70 </td>
   <td style="text-align:right;"> 20188 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> black cottonwood </td>
   <td style="text-align:left;"> Populus balsamifera </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 747 </td>
   <td style="text-align:right;"> 27.3881639 </td>
   <td style="text-align:right;"> 9.6660780 </td>
   <td style="text-align:right;"> 3.537348e+01 </td>
   <td style="text-align:right;"> 1.750373e+01 </td>
   <td style="text-align:right;"> 47 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> black cottonwood </td>
   <td style="text-align:left;"> Populus balsamifera </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 747 </td>
   <td style="text-align:right;"> 23.2490837 </td>
   <td style="text-align:right;"> 1.6994976 </td>
   <td style="text-align:right;"> 3.610421e+01 </td>
   <td style="text-align:right;"> 4.415301e-01 </td>
   <td style="text-align:right;"> 26 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> black cottonwood </td>
   <td style="text-align:left;"> Populus balsamifera </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 747 </td>
   <td style="text-align:right;"> 17.8258755 </td>
   <td style="text-align:right;"> 0.0649802 </td>
   <td style="text-align:right;"> 1.583883e+01 </td>
   <td style="text-align:right;"> 1.158800e-03 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 15382 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> black cottonwood </td>
   <td style="text-align:left;"> Populus balsamifera </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 747 </td>
   <td style="text-align:right;"> 33.0864214 </td>
   <td style="text-align:right;"> 32.7710770 </td>
   <td style="text-align:right;"> 3.703242e+01 </td>
   <td style="text-align:right;"> 1.890986e+02 </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> black locust </td>
   <td style="text-align:left;"> Robinia pseudoacacia </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 901 </td>
   <td style="text-align:right;"> -10.3179301 </td>
   <td style="text-align:right;"> -0.7507736 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 5.232877e-01 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 6606 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> black locust </td>
   <td style="text-align:left;"> Robinia pseudoacacia </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 901 </td>
   <td style="text-align:right;"> 25.5423922 </td>
   <td style="text-align:right;"> 0.0375762 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 1.567400e-03 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> black locust </td>
   <td style="text-align:left;"> Robinia pseudoacacia </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 901 </td>
   <td style="text-align:right;"> -460.4946280 </td>
   <td style="text-align:right;"> -1.7703456 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 3.372616e+00 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 11171 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Brewer spruce </td>
   <td style="text-align:left;"> Picea breweriana </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 92 </td>
   <td style="text-align:right;"> 3.7516174 </td>
   <td style="text-align:right;"> 0.0315957 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 9.437000e-04 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 6155 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California black oak </td>
   <td style="text-align:left;"> Quercus kelloggii </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 818 </td>
   <td style="text-align:right;"> 0.7563905 </td>
   <td style="text-align:right;"> 0.0236452 </td>
   <td style="text-align:right;"> 5.166004e+00 </td>
   <td style="text-align:right;"> 4.752700e-03 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 6606 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California black oak </td>
   <td style="text-align:left;"> Quercus kelloggii </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 818 </td>
   <td style="text-align:right;"> -4.2158911 </td>
   <td style="text-align:right;"> -0.5449098 </td>
   <td style="text-align:right;"> 3.945167e+01 </td>
   <td style="text-align:right;"> 6.602636e-01 </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California black oak </td>
   <td style="text-align:left;"> Quercus kelloggii </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 818 </td>
   <td style="text-align:right;"> 1.2024407 </td>
   <td style="text-align:right;"> 0.6950103 </td>
   <td style="text-align:right;"> 9.045076e+00 </td>
   <td style="text-align:right;"> 3.204137e+00 </td>
   <td style="text-align:right;"> 26 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California black oak </td>
   <td style="text-align:left;"> Quercus kelloggii </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 818 </td>
   <td style="text-align:right;"> 0.1517601 </td>
   <td style="text-align:right;"> 0.1130198 </td>
   <td style="text-align:right;"> 2.124869e+00 </td>
   <td style="text-align:right;"> 1.182697e+00 </td>
   <td style="text-align:right;"> 47 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California black oak </td>
   <td style="text-align:left;"> Quercus kelloggii </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 818 </td>
   <td style="text-align:right;"> 3.5288383 </td>
   <td style="text-align:right;"> 1.9355689 </td>
   <td style="text-align:right;"> 1.948534e+00 </td>
   <td style="text-align:right;"> 7.774245e-01 </td>
   <td style="text-align:right;"> 23 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California black oak </td>
   <td style="text-align:left;"> Quercus kelloggii </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 818 </td>
   <td style="text-align:right;"> 0.2830946 </td>
   <td style="text-align:right;"> 0.1712915 </td>
   <td style="text-align:right;"> 9.603735e+00 </td>
   <td style="text-align:right;"> 3.538936e+00 </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:right;"> 6606 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California laurel </td>
   <td style="text-align:left;"> Umbellularia californica </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 981 </td>
   <td style="text-align:right;"> 8.1321146 </td>
   <td style="text-align:right;"> 4.0177978 </td>
   <td style="text-align:right;"> 3.176229e+00 </td>
   <td style="text-align:right;"> 2.544639e+00 </td>
   <td style="text-align:right;"> 19 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California laurel </td>
   <td style="text-align:left;"> Umbellularia californica </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 981 </td>
   <td style="text-align:right;"> 9.4310310 </td>
   <td style="text-align:right;"> 6.4815209 </td>
   <td style="text-align:right;"> 4.091675e+00 </td>
   <td style="text-align:right;"> 6.274204e+00 </td>
   <td style="text-align:right;"> 40 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California laurel </td>
   <td style="text-align:left;"> Umbellularia californica </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 981 </td>
   <td style="text-align:right;"> 3.2637122 </td>
   <td style="text-align:right;"> 2.3122518 </td>
   <td style="text-align:right;"> 6.720890e+00 </td>
   <td style="text-align:right;"> 4.724306e+00 </td>
   <td style="text-align:right;"> 31 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California laurel </td>
   <td style="text-align:left;"> Umbellularia californica </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 981 </td>
   <td style="text-align:right;"> 27.8723894 </td>
   <td style="text-align:right;"> 1.9066848 </td>
   <td style="text-align:right;"> 1.020967e+02 </td>
   <td style="text-align:right;"> 3.750040e+00 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California laurel </td>
   <td style="text-align:left;"> Umbellularia californica </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 981 </td>
   <td style="text-align:right;"> -1.0404793 </td>
   <td style="text-align:right;"> -0.0156455 </td>
   <td style="text-align:right;"> 1.023375e+00 </td>
   <td style="text-align:right;"> 2.997000e-04 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California red fir </td>
   <td style="text-align:left;"> Abies magnifica </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 20 </td>
   <td style="text-align:right;"> 17.1693273 </td>
   <td style="text-align:right;"> 0.7486362 </td>
   <td style="text-align:right;"> 7.523157e+00 </td>
   <td style="text-align:right;"> 2.878654e-01 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 6444 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California red fir </td>
   <td style="text-align:left;"> Abies magnifica </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 20 </td>
   <td style="text-align:right;"> 10.3192637 </td>
   <td style="text-align:right;"> 0.5103769 </td>
   <td style="text-align:right;"> 9.193015e+00 </td>
   <td style="text-align:right;"> 1.374623e-01 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California red fir </td>
   <td style="text-align:left;"> Abies magnifica </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 20 </td>
   <td style="text-align:right;"> 9.9707487 </td>
   <td style="text-align:right;"> 0.6116875 </td>
   <td style="text-align:right;"> 1.432531e+00 </td>
   <td style="text-align:right;"> 2.191901e-01 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 6444 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California red fir </td>
   <td style="text-align:left;"> Abies magnifica </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 20 </td>
   <td style="text-align:right;"> -45.4022229 </td>
   <td style="text-align:right;"> -0.0886642 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 8.569900e-03 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 6155 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> canyon live oak </td>
   <td style="text-align:left;"> Quercus chrysolepis </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 805 </td>
   <td style="text-align:right;"> 3.4885810 </td>
   <td style="text-align:right;"> 0.0401474 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 1.776800e-03 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 6606 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> canyon live oak </td>
   <td style="text-align:left;"> Quercus chrysolepis </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 805 </td>
   <td style="text-align:right;"> -3.4296077 </td>
   <td style="text-align:right;"> -0.4269362 </td>
   <td style="text-align:right;"> 1.925583e+01 </td>
   <td style="text-align:right;"> 2.875948e-01 </td>
   <td style="text-align:right;"> 26 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> canyon live oak </td>
   <td style="text-align:left;"> Quercus chrysolepis </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 805 </td>
   <td style="text-align:right;"> 1.6911372 </td>
   <td style="text-align:right;"> 1.3295368 </td>
   <td style="text-align:right;"> 4.752191e+00 </td>
   <td style="text-align:right;"> 2.631303e+00 </td>
   <td style="text-align:right;"> 68 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> canyon live oak </td>
   <td style="text-align:left;"> Quercus chrysolepis </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 805 </td>
   <td style="text-align:right;"> 1.3635400 </td>
   <td style="text-align:right;"> 1.0765897 </td>
   <td style="text-align:right;"> 1.337648e+00 </td>
   <td style="text-align:right;"> 8.559550e-01 </td>
   <td style="text-align:right;"> 60 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> canyon live oak </td>
   <td style="text-align:left;"> Quercus chrysolepis </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 805 </td>
   <td style="text-align:right;"> 3.8052313 </td>
   <td style="text-align:right;"> 2.3229683 </td>
   <td style="text-align:right;"> 6.659816e-01 </td>
   <td style="text-align:right;"> 9.178053e-01 </td>
   <td style="text-align:right;"> 27 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> canyon live oak </td>
   <td style="text-align:left;"> Quercus chrysolepis </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 805 </td>
   <td style="text-align:right;"> 1.2450302 </td>
   <td style="text-align:right;"> 1.5968137 </td>
   <td style="text-align:right;"> 8.825192e+00 </td>
   <td style="text-align:right;"> 1.552348e+01 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> chokecherry </td>
   <td style="text-align:left;"> Prunus virginiana </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 763 </td>
   <td style="text-align:right;"> 1.1975146 </td>
   <td style="text-align:right;"> 0.1516328 </td>
   <td style="text-align:right;"> 4.806721e+01 </td>
   <td style="text-align:right;"> 7.747758e-01 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 13792 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> chokecherry </td>
   <td style="text-align:left;"> Prunus virginiana </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 763 </td>
   <td style="text-align:right;"> 11.9396432 </td>
   <td style="text-align:right;"> 0.3697614 </td>
   <td style="text-align:right;"> 4.906593e+00 </td>
   <td style="text-align:right;"> 3.799860e-02 </td>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> chokecherry </td>
   <td style="text-align:left;"> Prunus virginiana </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 763 </td>
   <td style="text-align:right;"> -0.7956102 </td>
   <td style="text-align:right;"> -0.0083494 </td>
   <td style="text-align:right;"> 1.655967e+01 </td>
   <td style="text-align:right;"> 1.900900e-03 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> chokecherry </td>
   <td style="text-align:left;"> Prunus virginiana </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 763 </td>
   <td style="text-align:right;"> -0.0209118 </td>
   <td style="text-align:right;"> -0.0002811 </td>
   <td style="text-align:right;"> 7.709382e+00 </td>
   <td style="text-align:right;"> 1.388700e-03 </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 20188 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> chokecherry </td>
   <td style="text-align:left;"> Prunus virginiana </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 763 </td>
   <td style="text-align:right;"> -20.8075286 </td>
   <td style="text-align:right;"> -0.6196799 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 4.641963e-01 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 17326 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Douglas-fir </td>
   <td style="text-align:left;"> Pseudotsuga menziesii </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 202 </td>
   <td style="text-align:right;"> 21.9645545 </td>
   <td style="text-align:right;"> 825.1085349 </td>
   <td style="text-align:right;"> 1.579034e+00 </td>
   <td style="text-align:right;"> 1.544303e+04 </td>
   <td style="text-align:right;"> 149 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Douglas-fir </td>
   <td style="text-align:left;"> Pseudotsuga menziesii </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 202 </td>
   <td style="text-align:right;"> 21.2101033 </td>
   <td style="text-align:right;"> 2473.9150801 </td>
   <td style="text-align:right;"> 1.576793e-01 </td>
   <td style="text-align:right;"> 5.722290e+03 </td>
   <td style="text-align:right;"> 1218 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Douglas-fir </td>
   <td style="text-align:left;"> Pseudotsuga menziesii </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 202 </td>
   <td style="text-align:right;"> 19.3228000 </td>
   <td style="text-align:right;"> 1873.2119948 </td>
   <td style="text-align:right;"> 1.425466e-01 </td>
   <td style="text-align:right;"> 2.988977e+03 </td>
   <td style="text-align:right;"> 2072 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Douglas-fir </td>
   <td style="text-align:left;"> Pseudotsuga menziesii </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 202 </td>
   <td style="text-align:right;"> 14.4807654 </td>
   <td style="text-align:right;"> 811.2510829 </td>
   <td style="text-align:right;"> 2.946248e-01 </td>
   <td style="text-align:right;"> 1.613896e+03 </td>
   <td style="text-align:right;"> 1716 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Douglas-fir </td>
   <td style="text-align:left;"> Pseudotsuga menziesii </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 202 </td>
   <td style="text-align:right;"> 8.5186983 </td>
   <td style="text-align:right;"> 335.2637322 </td>
   <td style="text-align:right;"> 3.655097e-01 </td>
   <td style="text-align:right;"> 6.622594e+02 </td>
   <td style="text-align:right;"> 2103 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Douglas-fir </td>
   <td style="text-align:left;"> Pseudotsuga menziesii </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 202 </td>
   <td style="text-align:right;"> 2.8772921 </td>
   <td style="text-align:right;"> 86.0288968 </td>
   <td style="text-align:right;"> 8.312483e-01 </td>
   <td style="text-align:right;"> 7.625763e+02 </td>
   <td style="text-align:right;"> 1217 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Douglas-fir </td>
   <td style="text-align:left;"> Pseudotsuga menziesii </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 202 </td>
   <td style="text-align:right;"> -3.0114179 </td>
   <td style="text-align:right;"> -21.8479771 </td>
   <td style="text-align:right;"> 9.692436e+00 </td>
   <td style="text-align:right;"> 5.439486e+02 </td>
   <td style="text-align:right;"> 170 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Engelmann spruce </td>
   <td style="text-align:left;"> Picea engelmannii </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 93 </td>
   <td style="text-align:right;"> 42.0090097 </td>
   <td style="text-align:right;"> 1.3144897 </td>
   <td style="text-align:right;"> 6.552678e+02 </td>
   <td style="text-align:right;"> 8.253423e-01 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 7186 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Engelmann spruce </td>
   <td style="text-align:left;"> Picea engelmannii </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 93 </td>
   <td style="text-align:right;"> 20.2307036 </td>
   <td style="text-align:right;"> 6.4931809 </td>
   <td style="text-align:right;"> 6.224230e+00 </td>
   <td style="text-align:right;"> 4.455752e+00 </td>
   <td style="text-align:right;"> 23 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Engelmann spruce </td>
   <td style="text-align:left;"> Picea engelmannii </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 93 </td>
   <td style="text-align:right;"> -0.9183344 </td>
   <td style="text-align:right;"> -1.1760053 </td>
   <td style="text-align:right;"> 5.499741e+01 </td>
   <td style="text-align:right;"> 9.055330e+01 </td>
   <td style="text-align:right;"> 129 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Engelmann spruce </td>
   <td style="text-align:left;"> Picea engelmannii </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 93 </td>
   <td style="text-align:right;"> -10.3693462 </td>
   <td style="text-align:right;"> -45.9432027 </td>
   <td style="text-align:right;"> 3.565369e+01 </td>
   <td style="text-align:right;"> 8.519031e+02 </td>
   <td style="text-align:right;"> 301 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Engelmann spruce </td>
   <td style="text-align:left;"> Picea engelmannii </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 93 </td>
   <td style="text-align:right;"> -8.5905234 </td>
   <td style="text-align:right;"> -22.9737244 </td>
   <td style="text-align:right;"> 2.795311e+01 </td>
   <td style="text-align:right;"> 2.095354e+02 </td>
   <td style="text-align:right;"> 344 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Engelmann spruce </td>
   <td style="text-align:left;"> Picea engelmannii </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 93 </td>
   <td style="text-align:right;"> -36.1482636 </td>
   <td style="text-align:right;"> -69.7847871 </td>
   <td style="text-align:right;"> 2.640883e+02 </td>
   <td style="text-align:right;"> 1.284247e+03 </td>
   <td style="text-align:right;"> 181 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Engelmann spruce </td>
   <td style="text-align:left;"> Picea engelmannii </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 93 </td>
   <td style="text-align:right;"> -23.3482404 </td>
   <td style="text-align:right;"> -35.7479981 </td>
   <td style="text-align:right;"> 2.683860e+02 </td>
   <td style="text-align:right;"> 6.458195e+02 </td>
   <td style="text-align:right;"> 54 </td>
   <td style="text-align:right;"> 13871 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> giant chinkapin, golden chinkapin </td>
   <td style="text-align:left;"> Chrysolepis chrysophylla </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 431 </td>
   <td style="text-align:right;"> 5.1976896 </td>
   <td style="text-align:right;"> 1.2476672 </td>
   <td style="text-align:right;"> 6.434309e+00 </td>
   <td style="text-align:right;"> 6.986671e-01 </td>
   <td style="text-align:right;"> 34 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> giant chinkapin, golden chinkapin </td>
   <td style="text-align:left;"> Chrysolepis chrysophylla </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 431 </td>
   <td style="text-align:right;"> 1.7150000 </td>
   <td style="text-align:right;"> 2.5651814 </td>
   <td style="text-align:right;"> 1.508470e+00 </td>
   <td style="text-align:right;"> 3.400720e+00 </td>
   <td style="text-align:right;"> 170 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> giant chinkapin, golden chinkapin </td>
   <td style="text-align:left;"> Chrysolepis chrysophylla </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 431 </td>
   <td style="text-align:right;"> 2.8832066 </td>
   <td style="text-align:right;"> 2.7199259 </td>
   <td style="text-align:right;"> 1.634412e+00 </td>
   <td style="text-align:right;"> 1.667532e+00 </td>
   <td style="text-align:right;"> 151 </td>
   <td style="text-align:right;"> 17615 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> giant chinkapin, golden chinkapin </td>
   <td style="text-align:left;"> Chrysolepis chrysophylla </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 431 </td>
   <td style="text-align:right;"> 3.2071198 </td>
   <td style="text-align:right;"> 2.5278413 </td>
   <td style="text-align:right;"> 2.595981e+00 </td>
   <td style="text-align:right;"> 2.568875e+00 </td>
   <td style="text-align:right;"> 105 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> giant chinkapin, golden chinkapin </td>
   <td style="text-align:left;"> Chrysolepis chrysophylla </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 431 </td>
   <td style="text-align:right;"> 3.7807406 </td>
   <td style="text-align:right;"> 0.8902555 </td>
   <td style="text-align:right;"> 7.431853e-01 </td>
   <td style="text-align:right;"> 1.331153e-01 </td>
   <td style="text-align:right;"> 24 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> giant chinkapin, golden chinkapin </td>
   <td style="text-align:left;"> Chrysolepis chrysophylla </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 431 </td>
   <td style="text-align:right;"> -11.1438765 </td>
   <td style="text-align:right;"> -6.8600943 </td>
   <td style="text-align:right;"> 1.126113e+02 </td>
   <td style="text-align:right;"> 6.053634e+01 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> giant sequoia </td>
   <td style="text-align:left;"> Sequoiadendron giganteum </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 212 </td>
   <td style="text-align:right;"> 24.0141755 </td>
   <td style="text-align:right;"> 0.4138111 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 1.300860e-01 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 6606 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> grand fir </td>
   <td style="text-align:left;"> Abies grandis </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 0.6898315 </td>
   <td style="text-align:right;"> 0.2197390 </td>
   <td style="text-align:right;"> 5.007469e+02 </td>
   <td style="text-align:right;"> 5.113607e+01 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 13792 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> grand fir </td>
   <td style="text-align:left;"> Abies grandis </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 18.3077756 </td>
   <td style="text-align:right;"> 17.9208452 </td>
   <td style="text-align:right;"> 1.459884e+01 </td>
   <td style="text-align:right;"> 2.923865e+01 </td>
   <td style="text-align:right;"> 65 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> grand fir </td>
   <td style="text-align:left;"> Abies grandis </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 10.7139963 </td>
   <td style="text-align:right;"> 53.7374749 </td>
   <td style="text-align:right;"> 3.041299e+00 </td>
   <td style="text-align:right;"> 1.009037e+02 </td>
   <td style="text-align:right;"> 379 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> grand fir </td>
   <td style="text-align:left;"> Abies grandis </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 5.5354737 </td>
   <td style="text-align:right;"> 72.0372129 </td>
   <td style="text-align:right;"> 2.876637e+00 </td>
   <td style="text-align:right;"> 4.915705e+02 </td>
   <td style="text-align:right;"> 656 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> grand fir </td>
   <td style="text-align:left;"> Abies grandis </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 3.5228401 </td>
   <td style="text-align:right;"> 39.1682201 </td>
   <td style="text-align:right;"> 2.017304e+00 </td>
   <td style="text-align:right;"> 2.381348e+02 </td>
   <td style="text-align:right;"> 819 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> grand fir </td>
   <td style="text-align:left;"> Abies grandis </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 5.4378129 </td>
   <td style="text-align:right;"> 28.4429160 </td>
   <td style="text-align:right;"> 4.002021e+00 </td>
   <td style="text-align:right;"> 1.086297e+02 </td>
   <td style="text-align:right;"> 396 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> grand fir </td>
   <td style="text-align:left;"> Abies grandis </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> -4.9408277 </td>
   <td style="text-align:right;"> -1.5995320 </td>
   <td style="text-align:right;"> 3.858472e+01 </td>
   <td style="text-align:right;"> 4.573619e+00 </td>
   <td style="text-align:right;"> 22 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> incense-cedar </td>
   <td style="text-align:left;"> Calocedrus decurrens </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 81 </td>
   <td style="text-align:right;"> 12.9714197 </td>
   <td style="text-align:right;"> 2.4501219 </td>
   <td style="text-align:right;"> 1.444605e+01 </td>
   <td style="text-align:right;"> 1.376339e+00 </td>
   <td style="text-align:right;"> 21 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> incense-cedar </td>
   <td style="text-align:left;"> Calocedrus decurrens </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 81 </td>
   <td style="text-align:right;"> 15.1823127 </td>
   <td style="text-align:right;"> 19.7065667 </td>
   <td style="text-align:right;"> 2.971632e+00 </td>
   <td style="text-align:right;"> 2.018181e+01 </td>
   <td style="text-align:right;"> 177 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> incense-cedar </td>
   <td style="text-align:left;"> Calocedrus decurrens </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 81 </td>
   <td style="text-align:right;"> 10.9475170 </td>
   <td style="text-align:right;"> 19.5767181 </td>
   <td style="text-align:right;"> 6.227810e+00 </td>
   <td style="text-align:right;"> 2.797932e+01 </td>
   <td style="text-align:right;"> 195 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> incense-cedar </td>
   <td style="text-align:left;"> Calocedrus decurrens </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 81 </td>
   <td style="text-align:right;"> 12.6829158 </td>
   <td style="text-align:right;"> 14.8442046 </td>
   <td style="text-align:right;"> 3.754200e+00 </td>
   <td style="text-align:right;"> 7.496598e+00 </td>
   <td style="text-align:right;"> 170 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> incense-cedar </td>
   <td style="text-align:left;"> Calocedrus decurrens </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 81 </td>
   <td style="text-align:right;"> 4.9226539 </td>
   <td style="text-align:right;"> 4.8307923 </td>
   <td style="text-align:right;"> 5.394217e+00 </td>
   <td style="text-align:right;"> 7.063172e+00 </td>
   <td style="text-align:right;"> 99 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> incense-cedar </td>
   <td style="text-align:left;"> Calocedrus decurrens </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 81 </td>
   <td style="text-align:right;"> 17.8946973 </td>
   <td style="text-align:right;"> 4.8556442 </td>
   <td style="text-align:right;"> 2.218307e+01 </td>
   <td style="text-align:right;"> 5.355612e+00 </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Jeffrey pine </td>
   <td style="text-align:left;"> Pinus jeffreyi </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 116 </td>
   <td style="text-align:right;"> -31.0822864 </td>
   <td style="text-align:right;"> -0.0736931 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 6.312900e-03 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 6155 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Jeffrey pine </td>
   <td style="text-align:left;"> Pinus jeffreyi </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 116 </td>
   <td style="text-align:right;"> 16.7767216 </td>
   <td style="text-align:right;"> 1.3051427 </td>
   <td style="text-align:right;"> 2.247640e+00 </td>
   <td style="text-align:right;"> 7.450710e-01 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Jeffrey pine </td>
   <td style="text-align:left;"> Pinus jeffreyi </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 116 </td>
   <td style="text-align:right;"> 7.4808212 </td>
   <td style="text-align:right;"> 1.4958160 </td>
   <td style="text-align:right;"> 1.792294e+01 </td>
   <td style="text-align:right;"> 4.978653e-01 </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Jeffrey pine </td>
   <td style="text-align:left;"> Pinus jeffreyi </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 116 </td>
   <td style="text-align:right;"> 5.5032234 </td>
   <td style="text-align:right;"> 0.6905499 </td>
   <td style="text-align:right;"> 9.507497e+00 </td>
   <td style="text-align:right;"> 1.726339e-01 </td>
   <td style="text-align:right;"> 21 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Jeffrey pine </td>
   <td style="text-align:left;"> Pinus jeffreyi </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 116 </td>
   <td style="text-align:right;"> -8.5298895 </td>
   <td style="text-align:right;"> -0.7333555 </td>
   <td style="text-align:right;"> 6.874193e+01 </td>
   <td style="text-align:right;"> 1.132564e+00 </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:right;"> 6155 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> knobcone pine </td>
   <td style="text-align:left;"> Pinus attenuata </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 103 </td>
   <td style="text-align:right;"> 0.5192349 </td>
   <td style="text-align:right;"> 0.0013575 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 1.900000e-06 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 6155 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> knobcone pine </td>
   <td style="text-align:left;"> Pinus attenuata </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 103 </td>
   <td style="text-align:right;"> 1.0394577 </td>
   <td style="text-align:right;"> 0.0755248 </td>
   <td style="text-align:right;"> 1.057282e+02 </td>
   <td style="text-align:right;"> 5.776285e-01 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> knobcone pine </td>
   <td style="text-align:left;"> Pinus attenuata </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 103 </td>
   <td style="text-align:right;"> -17.6957672 </td>
   <td style="text-align:right;"> -0.8594479 </td>
   <td style="text-align:right;"> 5.885333e+01 </td>
   <td style="text-align:right;"> 3.049516e-01 </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> knobcone pine </td>
   <td style="text-align:left;"> Pinus attenuata </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 103 </td>
   <td style="text-align:right;"> -5.6050632 </td>
   <td style="text-align:right;"> -0.3300119 </td>
   <td style="text-align:right;"> 8.658546e+00 </td>
   <td style="text-align:right;"> 2.589640e-02 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 6444 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> knobcone pine </td>
   <td style="text-align:left;"> Pinus attenuata </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 103 </td>
   <td style="text-align:right;"> 0.6275328 </td>
   <td style="text-align:right;"> 0.0231886 </td>
   <td style="text-align:right;"> 1.336690e+01 </td>
   <td style="text-align:right;"> 1.610230e-02 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 6155 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> lodgepole pine </td>
   <td style="text-align:left;"> Pinus contorta </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 108 </td>
   <td style="text-align:right;"> 12.2256903 </td>
   <td style="text-align:right;"> 3.6646828 </td>
   <td style="text-align:right;"> 7.132886e+00 </td>
   <td style="text-align:right;"> 5.250482e+00 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 9227 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> lodgepole pine </td>
   <td style="text-align:left;"> Pinus contorta </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 108 </td>
   <td style="text-align:right;"> -1.0852522 </td>
   <td style="text-align:right;"> -0.2983384 </td>
   <td style="text-align:right;"> 4.101097e+01 </td>
   <td style="text-align:right;"> 3.223734e+00 </td>
   <td style="text-align:right;"> 23 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> lodgepole pine </td>
   <td style="text-align:left;"> Pinus contorta </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 108 </td>
   <td style="text-align:right;"> -2.9392169 </td>
   <td style="text-align:right;"> -4.3562110 </td>
   <td style="text-align:right;"> 5.902306e+00 </td>
   <td style="text-align:right;"> 1.470093e+01 </td>
   <td style="text-align:right;"> 123 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> lodgepole pine </td>
   <td style="text-align:left;"> Pinus contorta </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 108 </td>
   <td style="text-align:right;"> -2.4615918 </td>
   <td style="text-align:right;"> -23.5889926 </td>
   <td style="text-align:right;"> 2.357992e+00 </td>
   <td style="text-align:right;"> 2.066626e+02 </td>
   <td style="text-align:right;"> 428 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> lodgepole pine </td>
   <td style="text-align:left;"> Pinus contorta </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 108 </td>
   <td style="text-align:right;"> -1.9636720 </td>
   <td style="text-align:right;"> -36.1304442 </td>
   <td style="text-align:right;"> 1.367881e+00 </td>
   <td style="text-align:right;"> 4.700340e+02 </td>
   <td style="text-align:right;"> 970 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> lodgepole pine </td>
   <td style="text-align:left;"> Pinus contorta </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 108 </td>
   <td style="text-align:right;"> -1.7964994 </td>
   <td style="text-align:right;"> -61.1156935 </td>
   <td style="text-align:right;"> 1.049293e+00 </td>
   <td style="text-align:right;"> 1.281790e+03 </td>
   <td style="text-align:right;"> 930 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> lodgepole pine </td>
   <td style="text-align:left;"> Pinus contorta </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 108 </td>
   <td style="text-align:right;"> -2.1419816 </td>
   <td style="text-align:right;"> -14.3989724 </td>
   <td style="text-align:right;"> 3.199629e+00 </td>
   <td style="text-align:right;"> 1.483100e+02 </td>
   <td style="text-align:right;"> 94 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> mountain hemlock </td>
   <td style="text-align:left;"> Tsuga mertensiana </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 264 </td>
   <td style="text-align:right;"> 12.9206705 </td>
   <td style="text-align:right;"> 0.1565663 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 2.600890e-02 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 2621 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> mountain hemlock </td>
   <td style="text-align:left;"> Tsuga mertensiana </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 264 </td>
   <td style="text-align:right;"> 8.1236843 </td>
   <td style="text-align:right;"> 1.9129927 </td>
   <td style="text-align:right;"> 4.122669e+00 </td>
   <td style="text-align:right;"> 1.422621e+00 </td>
   <td style="text-align:right;"> 24 </td>
   <td style="text-align:right;"> 20188 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> mountain hemlock </td>
   <td style="text-align:left;"> Tsuga mertensiana </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 264 </td>
   <td style="text-align:right;"> 9.3974507 </td>
   <td style="text-align:right;"> 6.9207445 </td>
   <td style="text-align:right;"> 1.355313e+00 </td>
   <td style="text-align:right;"> 2.652331e+00 </td>
   <td style="text-align:right;"> 93 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> mountain hemlock </td>
   <td style="text-align:left;"> Tsuga mertensiana </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 264 </td>
   <td style="text-align:right;"> 2.5131451 </td>
   <td style="text-align:right;"> 7.4003903 </td>
   <td style="text-align:right;"> 1.366828e+00 </td>
   <td style="text-align:right;"> 1.366808e+01 </td>
   <td style="text-align:right;"> 148 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> mountain hemlock </td>
   <td style="text-align:left;"> Tsuga mertensiana </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 264 </td>
   <td style="text-align:right;"> -0.9821895 </td>
   <td style="text-align:right;"> -6.0859616 </td>
   <td style="text-align:right;"> 5.638001e+00 </td>
   <td style="text-align:right;"> 2.161423e+02 </td>
   <td style="text-align:right;"> 236 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> mountain hemlock </td>
   <td style="text-align:left;"> Tsuga mertensiana </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 264 </td>
   <td style="text-align:right;"> 0.0511024 </td>
   <td style="text-align:right;"> 0.5969380 </td>
   <td style="text-align:right;"> 2.767619e+00 </td>
   <td style="text-align:right;"> 3.778236e+02 </td>
   <td style="text-align:right;"> 252 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> mountain hemlock </td>
   <td style="text-align:left;"> Tsuga mertensiana </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 264 </td>
   <td style="text-align:right;"> -1.1852831 </td>
   <td style="text-align:right;"> -12.7916773 </td>
   <td style="text-align:right;"> 1.146176e+01 </td>
   <td style="text-align:right;"> 1.343736e+03 </td>
   <td style="text-align:right;"> 97 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> noble fir </td>
   <td style="text-align:left;"> Abies procera </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 22 </td>
   <td style="text-align:right;"> 21.6916823 </td>
   <td style="text-align:right;"> 51.4935982 </td>
   <td style="text-align:right;"> 4.704940e+01 </td>
   <td style="text-align:right;"> 1.652408e+03 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> noble fir </td>
   <td style="text-align:left;"> Abies procera </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 22 </td>
   <td style="text-align:right;"> 24.4675823 </td>
   <td style="text-align:right;"> 76.4818364 </td>
   <td style="text-align:right;"> 5.001278e+00 </td>
   <td style="text-align:right;"> 1.935701e+02 </td>
   <td style="text-align:right;"> 102 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> noble fir </td>
   <td style="text-align:left;"> Abies procera </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 22 </td>
   <td style="text-align:right;"> 18.0002227 </td>
   <td style="text-align:right;"> 31.8094820 </td>
   <td style="text-align:right;"> 4.558875e+00 </td>
   <td style="text-align:right;"> 3.423902e+01 </td>
   <td style="text-align:right;"> 168 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> noble fir </td>
   <td style="text-align:left;"> Abies procera </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 22 </td>
   <td style="text-align:right;"> 11.6285346 </td>
   <td style="text-align:right;"> 18.7271717 </td>
   <td style="text-align:right;"> 5.947601e+00 </td>
   <td style="text-align:right;"> 4.330517e+01 </td>
   <td style="text-align:right;"> 128 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> noble fir </td>
   <td style="text-align:left;"> Abies procera </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 22 </td>
   <td style="text-align:right;"> 12.7062223 </td>
   <td style="text-align:right;"> 9.7709721 </td>
   <td style="text-align:right;"> 8.276048e+00 </td>
   <td style="text-align:right;"> 1.374122e+01 </td>
   <td style="text-align:right;"> 90 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> noble fir </td>
   <td style="text-align:left;"> Abies procera </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 22 </td>
   <td style="text-align:right;"> -21.4525349 </td>
   <td style="text-align:right;"> -12.3565641 </td>
   <td style="text-align:right;"> 4.383994e+02 </td>
   <td style="text-align:right;"> 2.541881e+02 </td>
   <td style="text-align:right;"> 29 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> noble fir </td>
   <td style="text-align:left;"> Abies procera </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 22 </td>
   <td style="text-align:right;"> 7.9546984 </td>
   <td style="text-align:right;"> 0.2196159 </td>
   <td style="text-align:right;"> 4.837665e+01 </td>
   <td style="text-align:right;"> 3.568320e-02 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 15382 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> northern California black walnut </td>
   <td style="text-align:left;"> Juglans hindsii </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 603 </td>
   <td style="text-align:right;"> -15.1502567 </td>
   <td style="text-align:right;"> -1.7717847 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 3.370098e+00 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 4565 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Norway maple </td>
   <td style="text-align:left;"> Acer platanoides </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 320 </td>
   <td style="text-align:right;"> 21.6467591 </td>
   <td style="text-align:right;"> 0.1884499 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 2.598240e-02 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 6606 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon ash </td>
   <td style="text-align:left;"> Fraxinus latifolia </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 542 </td>
   <td style="text-align:right;"> 11.9365557 </td>
   <td style="text-align:right;"> 0.8088886 </td>
   <td style="text-align:right;"> 2.403170e+01 </td>
   <td style="text-align:right;"> 1.776134e-01 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 11171 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon ash </td>
   <td style="text-align:left;"> Fraxinus latifolia </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 542 </td>
   <td style="text-align:right;"> 10.7193470 </td>
   <td style="text-align:right;"> 9.7976872 </td>
   <td style="text-align:right;"> 3.073330e+00 </td>
   <td style="text-align:right;"> 7.418363e+00 </td>
   <td style="text-align:right;"> 36 </td>
   <td style="text-align:right;"> 17326 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon ash </td>
   <td style="text-align:left;"> Fraxinus latifolia </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 542 </td>
   <td style="text-align:right;"> 11.5836336 </td>
   <td style="text-align:right;"> 3.0997599 </td>
   <td style="text-align:right;"> 3.331655e+01 </td>
   <td style="text-align:right;"> 7.415469e+00 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 17326 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon ash </td>
   <td style="text-align:left;"> Fraxinus latifolia </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 542 </td>
   <td style="text-align:right;"> 13.7984077 </td>
   <td style="text-align:right;"> 2.0286553 </td>
   <td style="text-align:right;"> 1.710502e+00 </td>
   <td style="text-align:right;"> 2.219836e+00 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon ash </td>
   <td style="text-align:left;"> Fraxinus latifolia </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 542 </td>
   <td style="text-align:right;"> 23.6546794 </td>
   <td style="text-align:right;"> 0.5708896 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 2.150339e-01 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 6606 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon ash </td>
   <td style="text-align:left;"> Fraxinus latifolia </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 542 </td>
   <td style="text-align:right;"> 13.1870300 </td>
   <td style="text-align:right;"> 5.9057166 </td>
   <td style="text-align:right;"> 1.360856e+00 </td>
   <td style="text-align:right;"> 1.126517e+01 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon crab apple </td>
   <td style="text-align:left;"> Malus fusca </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 661 </td>
   <td style="text-align:right;"> 1.9985044 </td>
   <td style="text-align:right;"> 0.0451534 </td>
   <td style="text-align:right;"> 6.570716e+01 </td>
   <td style="text-align:right;"> 3.498580e-02 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 11171 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon crab apple </td>
   <td style="text-align:left;"> Malus fusca </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 661 </td>
   <td style="text-align:right;"> 12.4275628 </td>
   <td style="text-align:right;"> 0.5241215 </td>
   <td style="text-align:right;"> 5.453404e+00 </td>
   <td style="text-align:right;"> 5.761580e-02 </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:right;"> 13792 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon crab apple </td>
   <td style="text-align:left;"> Malus fusca </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 661 </td>
   <td style="text-align:right;"> 5.5063294 </td>
   <td style="text-align:right;"> 0.1798704 </td>
   <td style="text-align:right;"> 5.877938e+00 </td>
   <td style="text-align:right;"> 1.145400e-02 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 7186 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon crab apple </td>
   <td style="text-align:left;"> Malus fusca </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 661 </td>
   <td style="text-align:right;"> 17.1005310 </td>
   <td style="text-align:right;"> 0.1364549 </td>
   <td style="text-align:right;"> 3.306845e+00 </td>
   <td style="text-align:right;"> 9.698700e-03 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 4565 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon crab apple </td>
   <td style="text-align:left;"> Malus fusca </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 661 </td>
   <td style="text-align:right;"> 7.4798378 </td>
   <td style="text-align:right;"> 0.1206187 </td>
   <td style="text-align:right;"> 8.637382e+00 </td>
   <td style="text-align:right;"> 7.535500e-03 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 11171 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon crab apple </td>
   <td style="text-align:left;"> Malus fusca </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 661 </td>
   <td style="text-align:right;"> 19.4772775 </td>
   <td style="text-align:right;"> 0.2334416 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 5.839890e-02 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 4565 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon white oak </td>
   <td style="text-align:left;"> Quercus garryana </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 815 </td>
   <td style="text-align:right;"> 2.1473701 </td>
   <td style="text-align:right;"> 0.4012939 </td>
   <td style="text-align:right;"> 1.559712e+01 </td>
   <td style="text-align:right;"> 5.126987e-01 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 6606 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon white oak </td>
   <td style="text-align:left;"> Quercus garryana </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 815 </td>
   <td style="text-align:right;"> 4.5929763 </td>
   <td style="text-align:right;"> 3.1990004 </td>
   <td style="text-align:right;"> 2.042448e+00 </td>
   <td style="text-align:right;"> 1.289921e+00 </td>
   <td style="text-align:right;"> 37 </td>
   <td style="text-align:right;"> 17326 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon white oak </td>
   <td style="text-align:left;"> Quercus garryana </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 815 </td>
   <td style="text-align:right;"> 2.7788013 </td>
   <td style="text-align:right;"> 1.7086782 </td>
   <td style="text-align:right;"> 3.123976e+00 </td>
   <td style="text-align:right;"> 1.735686e+00 </td>
   <td style="text-align:right;"> 28 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon white oak </td>
   <td style="text-align:left;"> Quercus garryana </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 815 </td>
   <td style="text-align:right;"> 3.9549571 </td>
   <td style="text-align:right;"> 3.6174948 </td>
   <td style="text-align:right;"> 8.925477e-01 </td>
   <td style="text-align:right;"> 1.303267e+00 </td>
   <td style="text-align:right;"> 46 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon white oak </td>
   <td style="text-align:left;"> Quercus garryana </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 815 </td>
   <td style="text-align:right;"> 4.7460088 </td>
   <td style="text-align:right;"> 5.3340941 </td>
   <td style="text-align:right;"> 7.479357e-01 </td>
   <td style="text-align:right;"> 2.134966e+00 </td>
   <td style="text-align:right;"> 32 </td>
   <td style="text-align:right;"> 17326 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon white oak </td>
   <td style="text-align:left;"> Quercus garryana </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 815 </td>
   <td style="text-align:right;"> 3.4642290 </td>
   <td style="text-align:right;"> 45.8506593 </td>
   <td style="text-align:right;"> 4.070618e-01 </td>
   <td style="text-align:right;"> 1.217205e+02 </td>
   <td style="text-align:right;"> 75 </td>
   <td style="text-align:right;"> 17326 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific dogwood </td>
   <td style="text-align:left;"> Cornus nuttallii </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 492 </td>
   <td style="text-align:right;"> 1.1375257 </td>
   <td style="text-align:right;"> 0.1140434 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 9.444400e-03 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 6606 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific dogwood </td>
   <td style="text-align:left;"> Cornus nuttallii </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 492 </td>
   <td style="text-align:right;"> -5.3238628 </td>
   <td style="text-align:right;"> -0.3812312 </td>
   <td style="text-align:right;"> 2.694765e+01 </td>
   <td style="text-align:right;"> 1.582662e-01 </td>
   <td style="text-align:right;"> 26 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific dogwood </td>
   <td style="text-align:left;"> Cornus nuttallii </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 492 </td>
   <td style="text-align:right;"> 1.5919070 </td>
   <td style="text-align:right;"> 0.3179593 </td>
   <td style="text-align:right;"> 3.139798e+00 </td>
   <td style="text-align:right;"> 1.459265e-01 </td>
   <td style="text-align:right;"> 76 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific dogwood </td>
   <td style="text-align:left;"> Cornus nuttallii </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 492 </td>
   <td style="text-align:right;"> -0.7535925 </td>
   <td style="text-align:right;"> -0.0618302 </td>
   <td style="text-align:right;"> 6.091429e+00 </td>
   <td style="text-align:right;"> 4.025250e-02 </td>
   <td style="text-align:right;"> 40 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific dogwood </td>
   <td style="text-align:left;"> Cornus nuttallii </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 492 </td>
   <td style="text-align:right;"> 3.5318675 </td>
   <td style="text-align:right;"> 0.0938847 </td>
   <td style="text-align:right;"> 1.462789e+01 </td>
   <td style="text-align:right;"> 2.120580e-02 </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific dogwood </td>
   <td style="text-align:left;"> Cornus nuttallii </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 492 </td>
   <td style="text-align:right;"> 10.7400400 </td>
   <td style="text-align:right;"> 0.0820962 </td>
   <td style="text-align:right;"> 5.182936e+00 </td>
   <td style="text-align:right;"> 5.208200e-03 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific madrone </td>
   <td style="text-align:left;"> Arbutus menziesii </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 361 </td>
   <td style="text-align:right;"> -3.1562285 </td>
   <td style="text-align:right;"> -1.1810724 </td>
   <td style="text-align:right;"> 4.117459e+01 </td>
   <td style="text-align:right;"> 5.586476e+00 </td>
   <td style="text-align:right;"> 26 </td>
   <td style="text-align:right;"> 17326 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific madrone </td>
   <td style="text-align:left;"> Arbutus menziesii </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 361 </td>
   <td style="text-align:right;"> -1.4856128 </td>
   <td style="text-align:right;"> -3.1193678 </td>
   <td style="text-align:right;"> 2.816884e+00 </td>
   <td style="text-align:right;"> 1.228496e+01 </td>
   <td style="text-align:right;"> 144 </td>
   <td style="text-align:right;"> 17615 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific madrone </td>
   <td style="text-align:left;"> Arbutus menziesii </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 361 </td>
   <td style="text-align:right;"> 2.9601400 </td>
   <td style="text-align:right;"> 11.3579321 </td>
   <td style="text-align:right;"> 1.318357e+00 </td>
   <td style="text-align:right;"> 2.665478e+01 </td>
   <td style="text-align:right;"> 179 </td>
   <td style="text-align:right;"> 17615 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific madrone </td>
   <td style="text-align:left;"> Arbutus menziesii </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 361 </td>
   <td style="text-align:right;"> 3.8083194 </td>
   <td style="text-align:right;"> 7.7484771 </td>
   <td style="text-align:right;"> 5.603340e-01 </td>
   <td style="text-align:right;"> 3.776562e+00 </td>
   <td style="text-align:right;"> 134 </td>
   <td style="text-align:right;"> 17615 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific madrone </td>
   <td style="text-align:left;"> Arbutus menziesii </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 361 </td>
   <td style="text-align:right;"> 1.7670607 </td>
   <td style="text-align:right;"> 3.0129873 </td>
   <td style="text-align:right;"> 5.022846e+00 </td>
   <td style="text-align:right;"> 1.526922e+01 </td>
   <td style="text-align:right;"> 56 </td>
   <td style="text-align:right;"> 17615 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific madrone </td>
   <td style="text-align:left;"> Arbutus menziesii </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 361 </td>
   <td style="text-align:right;"> -0.4356656 </td>
   <td style="text-align:right;"> -1.1151161 </td>
   <td style="text-align:right;"> 2.287871e+01 </td>
   <td style="text-align:right;"> 1.480166e+02 </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific silver fir </td>
   <td style="text-align:left;"> Abies amabilis </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 8.0256258 </td>
   <td style="text-align:right;"> 19.6186708 </td>
   <td style="text-align:right;"> 1.438916e+01 </td>
   <td style="text-align:right;"> 9.834676e+01 </td>
   <td style="text-align:right;"> 31 </td>
   <td style="text-align:right;"> 7186 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific silver fir </td>
   <td style="text-align:left;"> Abies amabilis </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 8.9043582 </td>
   <td style="text-align:right;"> 72.5089245 </td>
   <td style="text-align:right;"> 2.403260e+00 </td>
   <td style="text-align:right;"> 2.361626e+02 </td>
   <td style="text-align:right;"> 227 </td>
   <td style="text-align:right;"> 20188 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific silver fir </td>
   <td style="text-align:left;"> Abies amabilis </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 7.6267985 </td>
   <td style="text-align:right;"> 79.7551046 </td>
   <td style="text-align:right;"> 9.141808e-01 </td>
   <td style="text-align:right;"> 2.251663e+02 </td>
   <td style="text-align:right;"> 371 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific silver fir </td>
   <td style="text-align:left;"> Abies amabilis </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 0.7512809 </td>
   <td style="text-align:right;"> 8.2780988 </td>
   <td style="text-align:right;"> 8.252339e+00 </td>
   <td style="text-align:right;"> 9.917423e+02 </td>
   <td style="text-align:right;"> 324 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific silver fir </td>
   <td style="text-align:left;"> Abies amabilis </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 0.7350701 </td>
   <td style="text-align:right;"> 7.3030002 </td>
   <td style="text-align:right;"> 1.360557e+00 </td>
   <td style="text-align:right;"> 1.364001e+02 </td>
   <td style="text-align:right;"> 281 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific silver fir </td>
   <td style="text-align:left;"> Abies amabilis </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> -0.0838796 </td>
   <td style="text-align:right;"> -0.6039542 </td>
   <td style="text-align:right;"> 1.926988e+00 </td>
   <td style="text-align:right;"> 9.990048e+01 </td>
   <td style="text-align:right;"> 163 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific silver fir </td>
   <td style="text-align:left;"> Abies amabilis </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 3.6075477 </td>
   <td style="text-align:right;"> 17.4553455 </td>
   <td style="text-align:right;"> 3.849545e+00 </td>
   <td style="text-align:right;"> 1.025673e+02 </td>
   <td style="text-align:right;"> 57 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific yew </td>
   <td style="text-align:left;"> Taxus brevifolia </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 231 </td>
   <td style="text-align:right;"> 3.4472353 </td>
   <td style="text-align:right;"> 0.2596162 </td>
   <td style="text-align:right;"> 5.507567e+00 </td>
   <td style="text-align:right;"> 3.726870e-02 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 7186 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific yew </td>
   <td style="text-align:left;"> Taxus brevifolia </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 231 </td>
   <td style="text-align:right;"> 0.6109985 </td>
   <td style="text-align:right;"> 0.0730960 </td>
   <td style="text-align:right;"> 3.866275e+00 </td>
   <td style="text-align:right;"> 5.731770e-02 </td>
   <td style="text-align:right;"> 34 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific yew </td>
   <td style="text-align:left;"> Taxus brevifolia </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 231 </td>
   <td style="text-align:right;"> -1.7025715 </td>
   <td style="text-align:right;"> -0.7063404 </td>
   <td style="text-align:right;"> 2.653404e+00 </td>
   <td style="text-align:right;"> 4.516751e-01 </td>
   <td style="text-align:right;"> 131 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific yew </td>
   <td style="text-align:left;"> Taxus brevifolia </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 231 </td>
   <td style="text-align:right;"> 3.4989553 </td>
   <td style="text-align:right;"> 1.3796092 </td>
   <td style="text-align:right;"> 3.454262e+00 </td>
   <td style="text-align:right;"> 6.358782e-01 </td>
   <td style="text-align:right;"> 99 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific yew </td>
   <td style="text-align:left;"> Taxus brevifolia </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 231 </td>
   <td style="text-align:right;"> 1.7430623 </td>
   <td style="text-align:right;"> 0.1782191 </td>
   <td style="text-align:right;"> 1.441908e+00 </td>
   <td style="text-align:right;"> 1.725050e-02 </td>
   <td style="text-align:right;"> 52 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific yew </td>
   <td style="text-align:left;"> Taxus brevifolia </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 231 </td>
   <td style="text-align:right;"> 0.3458752 </td>
   <td style="text-align:right;"> 0.0171815 </td>
   <td style="text-align:right;"> 3.269068e+00 </td>
   <td style="text-align:right;"> 8.186400e-03 </td>
   <td style="text-align:right;"> 20 </td>
   <td style="text-align:right;"> 20188 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific yew </td>
   <td style="text-align:left;"> Taxus brevifolia </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 231 </td>
   <td style="text-align:right;"> 3.0848660 </td>
   <td style="text-align:right;"> 0.0104205 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 1.117000e-04 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 8776 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> paper birch </td>
   <td style="text-align:left;"> Betula papyrifera </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 375 </td>
   <td style="text-align:right;"> 9.7854491 </td>
   <td style="text-align:right;"> 1.7473372 </td>
   <td style="text-align:right;"> 3.534636e+01 </td>
   <td style="text-align:right;"> 3.271945e+00 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 4565 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> paper birch </td>
   <td style="text-align:left;"> Betula papyrifera </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 375 </td>
   <td style="text-align:right;"> 0.4271853 </td>
   <td style="text-align:right;"> 0.1148045 </td>
   <td style="text-align:right;"> 7.505205e+00 </td>
   <td style="text-align:right;"> 5.033623e-01 </td>
   <td style="text-align:right;"> 20 </td>
   <td style="text-align:right;"> 7186 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> paper birch </td>
   <td style="text-align:left;"> Betula papyrifera </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 375 </td>
   <td style="text-align:right;"> -6.6618014 </td>
   <td style="text-align:right;"> -5.2999644 </td>
   <td style="text-align:right;"> 1.774197e+00 </td>
   <td style="text-align:right;"> 3.022460e+00 </td>
   <td style="text-align:right;"> 43 </td>
   <td style="text-align:right;"> 13341 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> paper birch </td>
   <td style="text-align:left;"> Betula papyrifera </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 375 </td>
   <td style="text-align:right;"> -6.8768104 </td>
   <td style="text-align:right;"> -1.9453421 </td>
   <td style="text-align:right;"> 2.193429e+01 </td>
   <td style="text-align:right;"> 2.462986e+00 </td>
   <td style="text-align:right;"> 32 </td>
   <td style="text-align:right;"> 7186 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> paper birch </td>
   <td style="text-align:left;"> Betula papyrifera </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 375 </td>
   <td style="text-align:right;"> -4.6408888 </td>
   <td style="text-align:right;"> -0.7374500 </td>
   <td style="text-align:right;"> 5.254145e+01 </td>
   <td style="text-align:right;"> 1.073313e+00 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 7186 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> paper birch </td>
   <td style="text-align:left;"> Betula papyrifera </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 375 </td>
   <td style="text-align:right;"> 5.0871973 </td>
   <td style="text-align:right;"> 0.0934410 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 9.470900e-03 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 2621 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> ponderosa pine </td>
   <td style="text-align:left;"> Pinus ponderosa </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 122 </td>
   <td style="text-align:right;"> 21.9886289 </td>
   <td style="text-align:right;"> 0.6858470 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 5.045678e-01 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 2621 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> ponderosa pine </td>
   <td style="text-align:left;"> Pinus ponderosa </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 122 </td>
   <td style="text-align:right;"> -4.7569732 </td>
   <td style="text-align:right;"> -1.0933957 </td>
   <td style="text-align:right;"> 2.396036e+02 </td>
   <td style="text-align:right;"> 1.243987e+01 </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> ponderosa pine </td>
   <td style="text-align:left;"> Pinus ponderosa </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 122 </td>
   <td style="text-align:right;"> 16.1265057 </td>
   <td style="text-align:right;"> 45.4891901 </td>
   <td style="text-align:right;"> 2.128656e+00 </td>
   <td style="text-align:right;"> 6.888714e+01 </td>
   <td style="text-align:right;"> 207 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> ponderosa pine </td>
   <td style="text-align:left;"> Pinus ponderosa </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 122 </td>
   <td style="text-align:right;"> 13.6781922 </td>
   <td style="text-align:right;"> 170.1584406 </td>
   <td style="text-align:right;"> 1.185979e+00 </td>
   <td style="text-align:right;"> 2.972662e+02 </td>
   <td style="text-align:right;"> 709 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> ponderosa pine </td>
   <td style="text-align:left;"> Pinus ponderosa </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 122 </td>
   <td style="text-align:right;"> 9.9676127 </td>
   <td style="text-align:right;"> 278.8301002 </td>
   <td style="text-align:right;"> 2.451932e-01 </td>
   <td style="text-align:right;"> 2.702763e+02 </td>
   <td style="text-align:right;"> 1908 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> ponderosa pine </td>
   <td style="text-align:left;"> Pinus ponderosa </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 122 </td>
   <td style="text-align:right;"> 6.6409480 </td>
   <td style="text-align:right;"> 201.6382564 </td>
   <td style="text-align:right;"> 3.260236e-01 </td>
   <td style="text-align:right;"> 3.602224e+02 </td>
   <td style="text-align:right;"> 1527 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> ponderosa pine </td>
   <td style="text-align:left;"> Pinus ponderosa </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 122 </td>
   <td style="text-align:right;"> 4.4145175 </td>
   <td style="text-align:right;"> 8.2234292 </td>
   <td style="text-align:right;"> 1.553260e+01 </td>
   <td style="text-align:right;"> 5.736471e+01 </td>
   <td style="text-align:right;"> 134 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Port-Orford-cedar </td>
   <td style="text-align:left;"> Chamaecyparis lawsoniana </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 41 </td>
   <td style="text-align:right;"> 8.3493502 </td>
   <td style="text-align:right;"> 5.3212798 </td>
   <td style="text-align:right;"> 1.026112e+01 </td>
   <td style="text-align:right;"> 1.182747e+01 </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Port-Orford-cedar </td>
   <td style="text-align:left;"> Chamaecyparis lawsoniana </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 41 </td>
   <td style="text-align:right;"> 9.7095189 </td>
   <td style="text-align:right;"> 2.5029442 </td>
   <td style="text-align:right;"> 1.958183e+01 </td>
   <td style="text-align:right;"> 1.840740e+00 </td>
   <td style="text-align:right;"> 32 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Port-Orford-cedar </td>
   <td style="text-align:left;"> Chamaecyparis lawsoniana </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 41 </td>
   <td style="text-align:right;"> 5.9586842 </td>
   <td style="text-align:right;"> 0.6811018 </td>
   <td style="text-align:right;"> 2.751942e+01 </td>
   <td style="text-align:right;"> 3.657435e-01 </td>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Port-Orford-cedar </td>
   <td style="text-align:left;"> Chamaecyparis lawsoniana </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 41 </td>
   <td style="text-align:right;"> 7.8600542 </td>
   <td style="text-align:right;"> 0.4280412 </td>
   <td style="text-align:right;"> 1.014799e+01 </td>
   <td style="text-align:right;"> 4.906000e-02 </td>
   <td style="text-align:right;"> 12 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Port-Orford-cedar </td>
   <td style="text-align:left;"> Chamaecyparis lawsoniana </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 41 </td>
   <td style="text-align:right;"> 3.2808142 </td>
   <td style="text-align:right;"> 0.3283570 </td>
   <td style="text-align:right;"> 6.706302e+00 </td>
   <td style="text-align:right;"> 7.023240e-02 </td>
   <td style="text-align:right;"> 19 </td>
   <td style="text-align:right;"> 6444 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Port-Orford-cedar </td>
   <td style="text-align:left;"> Chamaecyparis lawsoniana </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 41 </td>
   <td style="text-align:right;"> 15.2225294 </td>
   <td style="text-align:right;"> 1.3773278 </td>
   <td style="text-align:right;"> 4.862226e-01 </td>
   <td style="text-align:right;"> 4.359923e-01 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> quaking aspen </td>
   <td style="text-align:left;"> Populus tremuloides </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 746 </td>
   <td style="text-align:right;"> -45.5045381 </td>
   <td style="text-align:right;"> -0.2778607 </td>
   <td style="text-align:right;"> 6.087942e+02 </td>
   <td style="text-align:right;"> 8.905860e-02 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 2621 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> quaking aspen </td>
   <td style="text-align:left;"> Populus tremuloides </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 746 </td>
   <td style="text-align:right;"> -38.2119350 </td>
   <td style="text-align:right;"> -2.6666898 </td>
   <td style="text-align:right;"> 1.236596e+02 </td>
   <td style="text-align:right;"> 4.273725e+00 </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:right;"> 7186 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> quaking aspen </td>
   <td style="text-align:left;"> Populus tremuloides </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 746 </td>
   <td style="text-align:right;"> 3.7624910 </td>
   <td style="text-align:right;"> 2.4577876 </td>
   <td style="text-align:right;"> 2.368971e+01 </td>
   <td style="text-align:right;"> 1.637847e+01 </td>
   <td style="text-align:right;"> 44 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> quaking aspen </td>
   <td style="text-align:left;"> Populus tremuloides </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 746 </td>
   <td style="text-align:right;"> -6.4179821 </td>
   <td style="text-align:right;"> -3.0067090 </td>
   <td style="text-align:right;"> 2.316569e+01 </td>
   <td style="text-align:right;"> 5.350695e+00 </td>
   <td style="text-align:right;"> 56 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> quaking aspen </td>
   <td style="text-align:left;"> Populus tremuloides </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 746 </td>
   <td style="text-align:right;"> -8.1933784 </td>
   <td style="text-align:right;"> -0.6831457 </td>
   <td style="text-align:right;"> 6.046326e+01 </td>
   <td style="text-align:right;"> 5.563321e-01 </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> quaking aspen </td>
   <td style="text-align:left;"> Populus tremuloides </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 746 </td>
   <td style="text-align:right;"> 5.8607099 </td>
   <td style="text-align:right;"> 5.5563652 </td>
   <td style="text-align:right;"> 2.830875e+00 </td>
   <td style="text-align:right;"> 9.271883e+00 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 15382 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> red alder </td>
   <td style="text-align:left;"> Alnus rubra </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 351 </td>
   <td style="text-align:right;"> 7.1297681 </td>
   <td style="text-align:right;"> 229.6429640 </td>
   <td style="text-align:right;"> 3.712340e+00 </td>
   <td style="text-align:right;"> 4.777234e+03 </td>
   <td style="text-align:right;"> 124 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> red alder </td>
   <td style="text-align:left;"> Alnus rubra </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 351 </td>
   <td style="text-align:right;"> 7.6219324 </td>
   <td style="text-align:right;"> 198.0619862 </td>
   <td style="text-align:right;"> 7.334701e-01 </td>
   <td style="text-align:right;"> 7.035704e+02 </td>
   <td style="text-align:right;"> 670 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> red alder </td>
   <td style="text-align:left;"> Alnus rubra </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 351 </td>
   <td style="text-align:right;"> 5.9730190 </td>
   <td style="text-align:right;"> 95.1288589 </td>
   <td style="text-align:right;"> 8.334300e-01 </td>
   <td style="text-align:right;"> 2.617784e+02 </td>
   <td style="text-align:right;"> 602 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> red alder </td>
   <td style="text-align:left;"> Alnus rubra </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 351 </td>
   <td style="text-align:right;"> 4.5131436 </td>
   <td style="text-align:right;"> 30.5642666 </td>
   <td style="text-align:right;"> 3.331587e+00 </td>
   <td style="text-align:right;"> 1.804198e+02 </td>
   <td style="text-align:right;"> 193 </td>
   <td style="text-align:right;"> 20188 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> red alder </td>
   <td style="text-align:left;"> Alnus rubra </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 351 </td>
   <td style="text-align:right;"> 6.3191142 </td>
   <td style="text-align:right;"> 8.5294280 </td>
   <td style="text-align:right;"> 7.251963e+00 </td>
   <td style="text-align:right;"> 2.461707e+01 </td>
   <td style="text-align:right;"> 67 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> red alder </td>
   <td style="text-align:left;"> Alnus rubra </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 351 </td>
   <td style="text-align:right;"> 0.2241094 </td>
   <td style="text-align:right;"> 0.0808908 </td>
   <td style="text-align:right;"> 2.426770e+01 </td>
   <td style="text-align:right;"> 3.139991e+00 </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> red alder </td>
   <td style="text-align:left;"> Alnus rubra </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 351 </td>
   <td style="text-align:right;"> 6.1960347 </td>
   <td style="text-align:right;"> 8.2606431 </td>
   <td style="text-align:right;"> 1.998636e+01 </td>
   <td style="text-align:right;"> 5.261437e+01 </td>
   <td style="text-align:right;"> 21 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> redwood </td>
   <td style="text-align:left;"> Sequoia sempervirens </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 211 </td>
   <td style="text-align:right;"> 18.6832888 </td>
   <td style="text-align:right;"> 9.4127137 </td>
   <td style="text-align:right;"> 5.835450e-02 </td>
   <td style="text-align:right;"> 9.445635e+01 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> redwood </td>
   <td style="text-align:left;"> Sequoia sempervirens </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 211 </td>
   <td style="text-align:right;"> 12.8208077 </td>
   <td style="text-align:right;"> 0.3301873 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 1.120518e-01 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 6155 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> redwood </td>
   <td style="text-align:left;"> Sequoia sempervirens </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 211 </td>
   <td style="text-align:right;"> 28.5435999 </td>
   <td style="text-align:right;"> 0.3733940 </td>
   <td style="text-align:right;"> 7.889245e+01 </td>
   <td style="text-align:right;"> 7.746300e-02 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Rocky Mountain juniper </td>
   <td style="text-align:left;"> Juniperus scopulorum </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 66 </td>
   <td style="text-align:right;"> 2.4883140 </td>
   <td style="text-align:right;"> 0.0107888 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 1.460000e-04 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 6606 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Scotch pine </td>
   <td style="text-align:left;"> Pinus sylvestris </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 130 </td>
   <td style="text-align:right;"> 22.5202446 </td>
   <td style="text-align:right;"> 0.1316492 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 1.628450e-02 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 6606 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Shasta red fir </td>
   <td style="text-align:left;"> Abies shastensis </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 21 </td>
   <td style="text-align:right;"> -138.3425389 </td>
   <td style="text-align:right;"> -7.7212421 </td>
   <td style="text-align:right;"> 1.378359e+04 </td>
   <td style="text-align:right;"> 7.961740e+01 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 6155 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Shasta red fir </td>
   <td style="text-align:left;"> Abies shastensis </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 21 </td>
   <td style="text-align:right;"> 13.9444144 </td>
   <td style="text-align:right;"> 8.1563825 </td>
   <td style="text-align:right;"> 1.310027e+01 </td>
   <td style="text-align:right;"> 1.082629e+01 </td>
   <td style="text-align:right;"> 41 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Shasta red fir </td>
   <td style="text-align:left;"> Abies shastensis </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 21 </td>
   <td style="text-align:right;"> 6.3846328 </td>
   <td style="text-align:right;"> 6.8100034 </td>
   <td style="text-align:right;"> 5.605894e+00 </td>
   <td style="text-align:right;"> 1.040664e+01 </td>
   <td style="text-align:right;"> 49 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Shasta red fir </td>
   <td style="text-align:left;"> Abies shastensis </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 21 </td>
   <td style="text-align:right;"> 4.0823675 </td>
   <td style="text-align:right;"> 4.1457808 </td>
   <td style="text-align:right;"> 1.621217e+01 </td>
   <td style="text-align:right;"> 1.869942e+01 </td>
   <td style="text-align:right;"> 68 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Shasta red fir </td>
   <td style="text-align:left;"> Abies shastensis </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 21 </td>
   <td style="text-align:right;"> 4.4245617 </td>
   <td style="text-align:right;"> 3.9374882 </td>
   <td style="text-align:right;"> 5.006893e+00 </td>
   <td style="text-align:right;"> 2.665108e+00 </td>
   <td style="text-align:right;"> 51 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Shasta red fir </td>
   <td style="text-align:left;"> Abies shastensis </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 21 </td>
   <td style="text-align:right;"> 16.3758425 </td>
   <td style="text-align:right;"> 6.7278323 </td>
   <td style="text-align:right;"> 2.603071e+01 </td>
   <td style="text-align:right;"> 2.443900e+01 </td>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Sitka spruce </td>
   <td style="text-align:left;"> Picea sitchensis </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 98 </td>
   <td style="text-align:right;"> 17.1416585 </td>
   <td style="text-align:right;"> 302.0032649 </td>
   <td style="text-align:right;"> 1.405597e+01 </td>
   <td style="text-align:right;"> 5.781853e+03 </td>
   <td style="text-align:right;"> 87 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Sitka spruce </td>
   <td style="text-align:left;"> Picea sitchensis </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 98 </td>
   <td style="text-align:right;"> 25.5026183 </td>
   <td style="text-align:right;"> 71.4772792 </td>
   <td style="text-align:right;"> 6.727952e+00 </td>
   <td style="text-align:right;"> 1.857885e+02 </td>
   <td style="text-align:right;"> 115 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Sitka spruce </td>
   <td style="text-align:left;"> Picea sitchensis </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 98 </td>
   <td style="text-align:right;"> 16.2315442 </td>
   <td style="text-align:right;"> 14.8329027 </td>
   <td style="text-align:right;"> 1.348636e+01 </td>
   <td style="text-align:right;"> 1.246862e+01 </td>
   <td style="text-align:right;"> 101 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Sitka spruce </td>
   <td style="text-align:left;"> Picea sitchensis </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 98 </td>
   <td style="text-align:right;"> 12.5855799 </td>
   <td style="text-align:right;"> 4.9162011 </td>
   <td style="text-align:right;"> 7.331814e+01 </td>
   <td style="text-align:right;"> 1.733629e+01 </td>
   <td style="text-align:right;"> 21 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Sitka spruce </td>
   <td style="text-align:left;"> Picea sitchensis </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 98 </td>
   <td style="text-align:right;"> 30.6482260 </td>
   <td style="text-align:right;"> 0.7393228 </td>
   <td style="text-align:right;"> 4.977513e+02 </td>
   <td style="text-align:right;"> 3.988613e-01 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 13792 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Sitka spruce </td>
   <td style="text-align:left;"> Picea sitchensis </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 98 </td>
   <td style="text-align:right;"> 26.7353683 </td>
   <td style="text-align:right;"> 1.3364066 </td>
   <td style="text-align:right;"> 5.236929e+02 </td>
   <td style="text-align:right;"> 1.701430e+00 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 17326 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Sitka spruce </td>
   <td style="text-align:left;"> Picea sitchensis </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 98 </td>
   <td style="text-align:right;"> 22.3517969 </td>
   <td style="text-align:right;"> 4.2772302 </td>
   <td style="text-align:right;"> 2.861052e+01 </td>
   <td style="text-align:right;"> 6.952636e+00 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 17326 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> subalpine fir </td>
   <td style="text-align:left;"> Abies lasiocarpa </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 19 </td>
   <td style="text-align:right;"> 2.5504116 </td>
   <td style="text-align:right;"> 0.3551808 </td>
   <td style="text-align:right;"> 1.349575e+00 </td>
   <td style="text-align:right;"> 4.628280e-02 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 7427 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> subalpine fir </td>
   <td style="text-align:left;"> Abies lasiocarpa </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 19 </td>
   <td style="text-align:right;"> -5.8127730 </td>
   <td style="text-align:right;"> -4.9099151 </td>
   <td style="text-align:right;"> 2.102957e+01 </td>
   <td style="text-align:right;"> 1.713112e+01 </td>
   <td style="text-align:right;"> 93 </td>
   <td style="text-align:right;"> 13871 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> subalpine fir </td>
   <td style="text-align:left;"> Abies lasiocarpa </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 19 </td>
   <td style="text-align:right;"> -3.0963841 </td>
   <td style="text-align:right;"> -18.9192026 </td>
   <td style="text-align:right;"> 3.585704e+00 </td>
   <td style="text-align:right;"> 1.599515e+02 </td>
   <td style="text-align:right;"> 240 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> subalpine fir </td>
   <td style="text-align:left;"> Abies lasiocarpa </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 19 </td>
   <td style="text-align:right;"> -3.4477538 </td>
   <td style="text-align:right;"> -26.7151871 </td>
   <td style="text-align:right;"> 3.449849e+00 </td>
   <td style="text-align:right;"> 2.087140e+02 </td>
   <td style="text-align:right;"> 351 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> subalpine fir </td>
   <td style="text-align:left;"> Abies lasiocarpa </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 19 </td>
   <td style="text-align:right;"> -7.7866228 </td>
   <td style="text-align:right;"> -59.3106239 </td>
   <td style="text-align:right;"> 4.801686e+00 </td>
   <td style="text-align:right;"> 3.174819e+02 </td>
   <td style="text-align:right;"> 281 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> subalpine fir </td>
   <td style="text-align:left;"> Abies lasiocarpa </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 19 </td>
   <td style="text-align:right;"> 1.7103392 </td>
   <td style="text-align:right;"> 22.9212678 </td>
   <td style="text-align:right;"> 2.022612e+00 </td>
   <td style="text-align:right;"> 3.650698e+02 </td>
   <td style="text-align:right;"> 117 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> subalpine larch </td>
   <td style="text-align:left;"> Larix lyallii </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 72 </td>
   <td style="text-align:right;"> 2.0010307 </td>
   <td style="text-align:right;"> 0.2938483 </td>
   <td style="text-align:right;"> 1.922998e+01 </td>
   <td style="text-align:right;"> 4.898044e-01 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 2862 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> subalpine larch </td>
   <td style="text-align:left;"> Larix lyallii </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 72 </td>
   <td style="text-align:right;"> 4.0780736 </td>
   <td style="text-align:right;"> 2.0022813 </td>
   <td style="text-align:right;"> 1.877336e+00 </td>
   <td style="text-align:right;"> 1.966305e+00 </td>
   <td style="text-align:right;"> 12 </td>
   <td style="text-align:right;"> 7427 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> subalpine larch </td>
   <td style="text-align:left;"> Larix lyallii </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 72 </td>
   <td style="text-align:right;"> 4.0775233 </td>
   <td style="text-align:right;"> 3.1197624 </td>
   <td style="text-align:right;"> 2.459515e-01 </td>
   <td style="text-align:right;"> 2.476530e+00 </td>
   <td style="text-align:right;"> 12 </td>
   <td style="text-align:right;"> 2862 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> sugar pine </td>
   <td style="text-align:left;"> Pinus lambertiana </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 117 </td>
   <td style="text-align:right;"> -161.6109886 </td>
   <td style="text-align:right;"> -0.6441689 </td>
   <td style="text-align:right;"> 2.556896e+04 </td>
   <td style="text-align:right;"> 3.302210e-01 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 6155 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> sugar pine </td>
   <td style="text-align:left;"> Pinus lambertiana </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 117 </td>
   <td style="text-align:right;"> -33.1645100 </td>
   <td style="text-align:right;"> -2.9342455 </td>
   <td style="text-align:right;"> 3.534974e+02 </td>
   <td style="text-align:right;"> 3.074079e+00 </td>
   <td style="text-align:right;"> 73 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> sugar pine </td>
   <td style="text-align:left;"> Pinus lambertiana </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 117 </td>
   <td style="text-align:right;"> 11.8157341 </td>
   <td style="text-align:right;"> 4.7722076 </td>
   <td style="text-align:right;"> 1.895696e+01 </td>
   <td style="text-align:right;"> 4.275020e+00 </td>
   <td style="text-align:right;"> 129 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> sugar pine </td>
   <td style="text-align:left;"> Pinus lambertiana </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 117 </td>
   <td style="text-align:right;"> 8.9673241 </td>
   <td style="text-align:right;"> 2.8371254 </td>
   <td style="text-align:right;"> 1.978639e+01 </td>
   <td style="text-align:right;"> 2.225624e+00 </td>
   <td style="text-align:right;"> 129 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> sugar pine </td>
   <td style="text-align:left;"> Pinus lambertiana </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 117 </td>
   <td style="text-align:right;"> -3.6588407 </td>
   <td style="text-align:right;"> -1.0603300 </td>
   <td style="text-align:right;"> 1.113656e+02 </td>
   <td style="text-align:right;"> 9.077759e+00 </td>
   <td style="text-align:right;"> 63 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> sugar pine </td>
   <td style="text-align:left;"> Pinus lambertiana </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 117 </td>
   <td style="text-align:right;"> 11.9044436 </td>
   <td style="text-align:right;"> 0.2377299 </td>
   <td style="text-align:right;"> 2.894228e-01 </td>
   <td style="text-align:right;"> 3.016380e-02 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 6444 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> sweet cherry </td>
   <td style="text-align:left;"> Prunus avium </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 771 </td>
   <td style="text-align:right;"> 14.9249805 </td>
   <td style="text-align:right;"> 0.7529054 </td>
   <td style="text-align:right;"> 1.736425e+00 </td>
   <td style="text-align:right;"> 1.630633e-01 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 6606 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> sweet cherry </td>
   <td style="text-align:left;"> Prunus avium </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 771 </td>
   <td style="text-align:right;"> 28.8925370 </td>
   <td style="text-align:right;"> 0.9398244 </td>
   <td style="text-align:right;"> 1.294513e+01 </td>
   <td style="text-align:right;"> 2.749392e-01 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 6606 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> sweet cherry </td>
   <td style="text-align:left;"> Prunus avium </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 771 </td>
   <td style="text-align:right;"> 9.6072721 </td>
   <td style="text-align:right;"> 1.0111012 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 6.532961e-01 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 6606 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> sweet cherry </td>
   <td style="text-align:left;"> Prunus avium </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 771 </td>
   <td style="text-align:right;"> 24.1236519 </td>
   <td style="text-align:right;"> 0.1578445 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 1.609300e-02 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 4565 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> tanoak </td>
   <td style="text-align:left;"> Lithocarpus densiflorus </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 631 </td>
   <td style="text-align:right;"> -3.9110677 </td>
   <td style="text-align:right;"> -3.8693001 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 1.429057e+01 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 6606 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> tanoak </td>
   <td style="text-align:left;"> Lithocarpus densiflorus </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 631 </td>
   <td style="text-align:right;"> 7.0807777 </td>
   <td style="text-align:right;"> 4.4251763 </td>
   <td style="text-align:right;"> 5.052160e+00 </td>
   <td style="text-align:right;"> 4.480041e+00 </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> tanoak </td>
   <td style="text-align:left;"> Lithocarpus densiflorus </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 631 </td>
   <td style="text-align:right;"> -1.3838765 </td>
   <td style="text-align:right;"> -4.9081121 </td>
   <td style="text-align:right;"> 6.483444e+00 </td>
   <td style="text-align:right;"> 8.408406e+01 </td>
   <td style="text-align:right;"> 100 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> tanoak </td>
   <td style="text-align:left;"> Lithocarpus densiflorus </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 631 </td>
   <td style="text-align:right;"> -1.0609156 </td>
   <td style="text-align:right;"> -4.0704973 </td>
   <td style="text-align:right;"> 4.036744e+00 </td>
   <td style="text-align:right;"> 5.753070e+01 </td>
   <td style="text-align:right;"> 98 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> tanoak </td>
   <td style="text-align:left;"> Lithocarpus densiflorus </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 631 </td>
   <td style="text-align:right;"> 1.6776474 </td>
   <td style="text-align:right;"> 1.9455206 </td>
   <td style="text-align:right;"> 5.169195e+00 </td>
   <td style="text-align:right;"> 7.870438e+00 </td>
   <td style="text-align:right;"> 62 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> tanoak </td>
   <td style="text-align:left;"> Lithocarpus densiflorus </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 631 </td>
   <td style="text-align:right;"> 5.7380454 </td>
   <td style="text-align:right;"> 2.5043308 </td>
   <td style="text-align:right;"> 1.762463e+00 </td>
   <td style="text-align:right;"> 1.354847e+00 </td>
   <td style="text-align:right;"> 23 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> tanoak </td>
   <td style="text-align:left;"> Lithocarpus densiflorus </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 631 </td>
   <td style="text-align:right;"> 1.4969161 </td>
   <td style="text-align:right;"> 0.8350097 </td>
   <td style="text-align:right;"> 4.711100e+00 </td>
   <td style="text-align:right;"> 1.703063e+00 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> water birch </td>
   <td style="text-align:left;"> Betula occidentalis </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 374 </td>
   <td style="text-align:right;"> 7.1276155 </td>
   <td style="text-align:right;"> 0.0709417 </td>
   <td style="text-align:right;"> 1.142645e+01 </td>
   <td style="text-align:right;"> 3.079200e-03 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 10720 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> water birch </td>
   <td style="text-align:left;"> Betula occidentalis </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 374 </td>
   <td style="text-align:right;"> 5.1572228 </td>
   <td style="text-align:right;"> 0.1532402 </td>
   <td style="text-align:right;"> 1.002356e+02 </td>
   <td style="text-align:right;"> 1.314476e-01 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> water birch </td>
   <td style="text-align:left;"> Betula occidentalis </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 374 </td>
   <td style="text-align:right;"> -1.2722698 </td>
   <td style="text-align:right;"> -0.1162493 </td>
   <td style="text-align:right;"> 1.371847e+01 </td>
   <td style="text-align:right;"> 1.508787e-01 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 7186 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> water birch </td>
   <td style="text-align:left;"> Betula occidentalis </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 374 </td>
   <td style="text-align:right;"> -9.3996715 </td>
   <td style="text-align:right;"> -0.0690608 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 5.174000e-03 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 7186 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western hemlock </td>
   <td style="text-align:left;"> Tsuga heterophylla </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 263 </td>
   <td style="text-align:right;"> 13.9711093 </td>
   <td style="text-align:right;"> 1806.7809270 </td>
   <td style="text-align:right;"> 1.243023e+00 </td>
   <td style="text-align:right;"> 3.533177e+04 </td>
   <td style="text-align:right;"> 186 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western hemlock </td>
   <td style="text-align:left;"> Tsuga heterophylla </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 263 </td>
   <td style="text-align:right;"> 11.6032088 </td>
   <td style="text-align:right;"> 476.9074615 </td>
   <td style="text-align:right;"> 5.340153e-01 </td>
   <td style="text-align:right;"> 1.620847e+03 </td>
   <td style="text-align:right;"> 841 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western hemlock </td>
   <td style="text-align:left;"> Tsuga heterophylla </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 263 </td>
   <td style="text-align:right;"> 10.9503259 </td>
   <td style="text-align:right;"> 328.1578780 </td>
   <td style="text-align:right;"> 3.586815e-01 </td>
   <td style="text-align:right;"> 5.068620e+02 </td>
   <td style="text-align:right;"> 1226 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western hemlock </td>
   <td style="text-align:left;"> Tsuga heterophylla </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 263 </td>
   <td style="text-align:right;"> 7.7789842 </td>
   <td style="text-align:right;"> 138.9264201 </td>
   <td style="text-align:right;"> 4.490759e-01 </td>
   <td style="text-align:right;"> 1.963703e+02 </td>
   <td style="text-align:right;"> 684 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western hemlock </td>
   <td style="text-align:left;"> Tsuga heterophylla </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 263 </td>
   <td style="text-align:right;"> 6.2773438 </td>
   <td style="text-align:right;"> 43.8233548 </td>
   <td style="text-align:right;"> 5.824087e-01 </td>
   <td style="text-align:right;"> 4.206041e+01 </td>
   <td style="text-align:right;"> 392 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western hemlock </td>
   <td style="text-align:left;"> Tsuga heterophylla </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 263 </td>
   <td style="text-align:right;"> 3.5564190 </td>
   <td style="text-align:right;"> 15.5842573 </td>
   <td style="text-align:right;"> 8.466108e-01 </td>
   <td style="text-align:right;"> 2.125531e+01 </td>
   <td style="text-align:right;"> 137 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western hemlock </td>
   <td style="text-align:left;"> Tsuga heterophylla </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 263 </td>
   <td style="text-align:right;"> 7.4423427 </td>
   <td style="text-align:right;"> 11.4336641 </td>
   <td style="text-align:right;"> 3.004550e+00 </td>
   <td style="text-align:right;"> 2.208326e+01 </td>
   <td style="text-align:right;"> 23 </td>
   <td style="text-align:right;"> 13341 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western juniper </td>
   <td style="text-align:left;"> Juniperus occidentalis </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 64 </td>
   <td style="text-align:right;"> 3.6248035 </td>
   <td style="text-align:right;"> 0.0041715 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 1.970000e-05 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 6155 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western juniper </td>
   <td style="text-align:left;"> Juniperus occidentalis </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 64 </td>
   <td style="text-align:right;"> 6.2823664 </td>
   <td style="text-align:right;"> 1.2303433 </td>
   <td style="text-align:right;"> 3.358288e+00 </td>
   <td style="text-align:right;"> 3.319834e-01 </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western juniper </td>
   <td style="text-align:left;"> Juniperus occidentalis </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 64 </td>
   <td style="text-align:right;"> 4.0070633 </td>
   <td style="text-align:right;"> 3.3154511 </td>
   <td style="text-align:right;"> 1.498833e+00 </td>
   <td style="text-align:right;"> 9.471210e-01 </td>
   <td style="text-align:right;"> 141 </td>
   <td style="text-align:right;"> 15382 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western juniper </td>
   <td style="text-align:left;"> Juniperus occidentalis </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 64 </td>
   <td style="text-align:right;"> 4.2276375 </td>
   <td style="text-align:right;"> 9.7049910 </td>
   <td style="text-align:right;"> 8.560947e-01 </td>
   <td style="text-align:right;"> 5.392453e+00 </td>
   <td style="text-align:right;"> 304 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western juniper </td>
   <td style="text-align:left;"> Juniperus occidentalis </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 64 </td>
   <td style="text-align:right;"> 5.3451692 </td>
   <td style="text-align:right;"> 129.7615961 </td>
   <td style="text-align:right;"> 3.681867e-01 </td>
   <td style="text-align:right;"> 2.511377e+02 </td>
   <td style="text-align:right;"> 371 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western larch </td>
   <td style="text-align:left;"> Larix occidentalis </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 73 </td>
   <td style="text-align:right;"> 20.7108648 </td>
   <td style="text-align:right;"> 12.1365619 </td>
   <td style="text-align:right;"> 1.047038e+00 </td>
   <td style="text-align:right;"> 4.741380e+01 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 2621 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western larch </td>
   <td style="text-align:left;"> Larix occidentalis </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 73 </td>
   <td style="text-align:right;"> 16.4570716 </td>
   <td style="text-align:right;"> 3.9695771 </td>
   <td style="text-align:right;"> 1.546710e+00 </td>
   <td style="text-align:right;"> 4.744493e+00 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western larch </td>
   <td style="text-align:left;"> Larix occidentalis </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 73 </td>
   <td style="text-align:right;"> 10.9281145 </td>
   <td style="text-align:right;"> 11.8661330 </td>
   <td style="text-align:right;"> 2.075961e+00 </td>
   <td style="text-align:right;"> 6.005368e+00 </td>
   <td style="text-align:right;"> 133 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western larch </td>
   <td style="text-align:left;"> Larix occidentalis </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 73 </td>
   <td style="text-align:right;"> 6.4730684 </td>
   <td style="text-align:right;"> 24.5948543 </td>
   <td style="text-align:right;"> 1.169129e+00 </td>
   <td style="text-align:right;"> 1.966041e+01 </td>
   <td style="text-align:right;"> 401 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western larch </td>
   <td style="text-align:left;"> Larix occidentalis </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 73 </td>
   <td style="text-align:right;"> 1.5964652 </td>
   <td style="text-align:right;"> 7.2661322 </td>
   <td style="text-align:right;"> 1.800628e+00 </td>
   <td style="text-align:right;"> 3.835558e+01 </td>
   <td style="text-align:right;"> 682 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western larch </td>
   <td style="text-align:left;"> Larix occidentalis </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 73 </td>
   <td style="text-align:right;"> 3.9340694 </td>
   <td style="text-align:right;"> 8.8568711 </td>
   <td style="text-align:right;"> 1.823710e+00 </td>
   <td style="text-align:right;"> 1.388926e+01 </td>
   <td style="text-align:right;"> 294 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western larch </td>
   <td style="text-align:left;"> Larix occidentalis </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 73 </td>
   <td style="text-align:right;"> 2.7564279 </td>
   <td style="text-align:right;"> 0.3537571 </td>
   <td style="text-align:right;"> 7.087769e+01 </td>
   <td style="text-align:right;"> 1.296308e+00 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 9017 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western redcedar </td>
   <td style="text-align:left;"> Thuja plicata </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 242 </td>
   <td style="text-align:right;"> 14.0039545 </td>
   <td style="text-align:right;"> 104.3767678 </td>
   <td style="text-align:right;"> 9.480019e+00 </td>
   <td style="text-align:right;"> 6.627769e+02 </td>
   <td style="text-align:right;"> 72 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western redcedar </td>
   <td style="text-align:left;"> Thuja plicata </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 242 </td>
   <td style="text-align:right;"> 19.1241334 </td>
   <td style="text-align:right;"> 124.0590425 </td>
   <td style="text-align:right;"> 1.872302e+00 </td>
   <td style="text-align:right;"> 1.466850e+02 </td>
   <td style="text-align:right;"> 452 </td>
   <td style="text-align:right;"> 20188 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western redcedar </td>
   <td style="text-align:left;"> Thuja plicata </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 242 </td>
   <td style="text-align:right;"> 18.7439945 </td>
   <td style="text-align:right;"> 150.3001383 </td>
   <td style="text-align:right;"> 1.651261e+00 </td>
   <td style="text-align:right;"> 1.798805e+02 </td>
   <td style="text-align:right;"> 698 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western redcedar </td>
   <td style="text-align:left;"> Thuja plicata </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 242 </td>
   <td style="text-align:right;"> 15.4163517 </td>
   <td style="text-align:right;"> 142.4365719 </td>
   <td style="text-align:right;"> 1.416838e+00 </td>
   <td style="text-align:right;"> 2.343808e+02 </td>
   <td style="text-align:right;"> 411 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western redcedar </td>
   <td style="text-align:left;"> Thuja plicata </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 242 </td>
   <td style="text-align:right;"> 13.4046353 </td>
   <td style="text-align:right;"> 51.2246122 </td>
   <td style="text-align:right;"> 1.678616e+00 </td>
   <td style="text-align:right;"> 4.395508e+01 </td>
   <td style="text-align:right;"> 270 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western redcedar </td>
   <td style="text-align:left;"> Thuja plicata </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 242 </td>
   <td style="text-align:right;"> 6.9925751 </td>
   <td style="text-align:right;"> 10.5286179 </td>
   <td style="text-align:right;"> 6.881865e+00 </td>
   <td style="text-align:right;"> 1.521535e+01 </td>
   <td style="text-align:right;"> 75 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western redcedar </td>
   <td style="text-align:left;"> Thuja plicata </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 242 </td>
   <td style="text-align:right;"> 15.0019459 </td>
   <td style="text-align:right;"> 7.0039403 </td>
   <td style="text-align:right;"> 7.202967e+01 </td>
   <td style="text-align:right;"> 1.372917e+01 </td>
   <td style="text-align:right;"> 19 </td>
   <td style="text-align:right;"> 13341 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western white pine </td>
   <td style="text-align:left;"> Pinus monticola </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 119 </td>
   <td style="text-align:right;"> 13.8393714 </td>
   <td style="text-align:right;"> 0.1478066 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 2.710940e-02 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 2621 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western white pine </td>
   <td style="text-align:left;"> Pinus monticola </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 119 </td>
   <td style="text-align:right;"> 14.6486501 </td>
   <td style="text-align:right;"> 1.3671523 </td>
   <td style="text-align:right;"> 3.994928e+01 </td>
   <td style="text-align:right;"> 8.235595e-01 </td>
   <td style="text-align:right;"> 27 </td>
   <td style="text-align:right;"> 13582 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western white pine </td>
   <td style="text-align:left;"> Pinus monticola </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 119 </td>
   <td style="text-align:right;"> 0.7577405 </td>
   <td style="text-align:right;"> 0.1907470 </td>
   <td style="text-align:right;"> 1.352289e+01 </td>
   <td style="text-align:right;"> 8.643539e-01 </td>
   <td style="text-align:right;"> 105 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western white pine </td>
   <td style="text-align:left;"> Pinus monticola </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 119 </td>
   <td style="text-align:right;"> 2.5900168 </td>
   <td style="text-align:right;"> 1.6272730 </td>
   <td style="text-align:right;"> 1.505820e+01 </td>
   <td style="text-align:right;"> 6.188912e+00 </td>
   <td style="text-align:right;"> 177 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western white pine </td>
   <td style="text-align:left;"> Pinus monticola </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 119 </td>
   <td style="text-align:right;"> -5.9903064 </td>
   <td style="text-align:right;"> -3.4593429 </td>
   <td style="text-align:right;"> 1.572541e+01 </td>
   <td style="text-align:right;"> 5.743584e+00 </td>
   <td style="text-align:right;"> 187 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western white pine </td>
   <td style="text-align:left;"> Pinus monticola </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 119 </td>
   <td style="text-align:right;"> -3.6062527 </td>
   <td style="text-align:right;"> -3.3009505 </td>
   <td style="text-align:right;"> 5.230641e+00 </td>
   <td style="text-align:right;"> 5.160228e+00 </td>
   <td style="text-align:right;"> 184 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western white pine </td>
   <td style="text-align:left;"> Pinus monticola </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 119 </td>
   <td style="text-align:right;"> -26.4906165 </td>
   <td style="text-align:right;"> -8.2653630 </td>
   <td style="text-align:right;"> 1.714661e+02 </td>
   <td style="text-align:right;"> 2.002729e+01 </td>
   <td style="text-align:right;"> 53 </td>
   <td style="text-align:right;"> 15912 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> white alder </td>
   <td style="text-align:left;"> Alnus rhombifolia </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 352 </td>
   <td style="text-align:right;"> -15.4888585 </td>
   <td style="text-align:right;"> -0.2101120 </td>
   <td style="text-align:right;"> 8.555412e+01 </td>
   <td style="text-align:right;"> 4.442920e-02 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 15382 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> white alder </td>
   <td style="text-align:left;"> Alnus rhombifolia </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 352 </td>
   <td style="text-align:right;"> 7.1767200 </td>
   <td style="text-align:right;"> 0.3942611 </td>
   <td style="text-align:right;"> 2.438845e+02 </td>
   <td style="text-align:right;"> 5.561424e-01 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> white alder </td>
   <td style="text-align:left;"> Alnus rhombifolia </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 352 </td>
   <td style="text-align:right;"> -2.9352234 </td>
   <td style="text-align:right;"> -0.4171741 </td>
   <td style="text-align:right;"> 2.078068e+01 </td>
   <td style="text-align:right;"> 5.861076e-01 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 10720 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> white alder </td>
   <td style="text-align:left;"> Alnus rhombifolia </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 352 </td>
   <td style="text-align:right;"> -18.5453394 </td>
   <td style="text-align:right;"> -0.9060697 </td>
   <td style="text-align:right;"> 5.207336e+01 </td>
   <td style="text-align:right;"> 5.408481e-01 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 10720 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> white alder </td>
   <td style="text-align:left;"> Alnus rhombifolia </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 352 </td>
   <td style="text-align:right;"> 2.2708576 </td>
   <td style="text-align:right;"> 1.1332215 </td>
   <td style="text-align:right;"> 0.000000e+00 </td>
   <td style="text-align:right;"> 1.075207e+00 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 4565 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> white fir </td>
   <td style="text-align:left;"> Abies concolor </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 11.2927852 </td>
   <td style="text-align:right;"> 2.8239072 </td>
   <td style="text-align:right;"> 1.284057e+01 </td>
   <td style="text-align:right;"> 2.163358e+00 </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> white fir </td>
   <td style="text-align:left;"> Abies concolor </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 9.5714683 </td>
   <td style="text-align:right;"> 23.0391388 </td>
   <td style="text-align:right;"> 5.884922e+00 </td>
   <td style="text-align:right;"> 5.255844e+01 </td>
   <td style="text-align:right;"> 180 </td>
   <td style="text-align:right;"> 15671 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> white fir </td>
   <td style="text-align:left;"> Abies concolor </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 8.6567690 </td>
   <td style="text-align:right;"> 51.9501014 </td>
   <td style="text-align:right;"> 1.663981e+00 </td>
   <td style="text-align:right;"> 8.051275e+01 </td>
   <td style="text-align:right;"> 295 </td>
   <td style="text-align:right;"> 17856 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> white fir </td>
   <td style="text-align:left;"> Abies concolor </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 6.3886130 </td>
   <td style="text-align:right;"> 38.4038608 </td>
   <td style="text-align:right;"> 8.469574e-01 </td>
   <td style="text-align:right;"> 4.542618e+01 </td>
   <td style="text-align:right;"> 381 </td>
   <td style="text-align:right;"> 17615 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> white fir </td>
   <td style="text-align:left;"> Abies concolor </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 5.8338550 </td>
   <td style="text-align:right;"> 19.4189282 </td>
   <td style="text-align:right;"> 1.667326e+00 </td>
   <td style="text-align:right;"> 2.932530e+01 </td>
   <td style="text-align:right;"> 214 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> white fir </td>
   <td style="text-align:left;"> Abies concolor </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 21.2586478 </td>
   <td style="text-align:right;"> 2.4802101 </td>
   <td style="text-align:right;"> 1.464982e+01 </td>
   <td style="text-align:right;"> 1.761227e+00 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> whitebark pine </td>
   <td style="text-align:left;"> Pinus albicaulis </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 101 </td>
   <td style="text-align:right;"> -3.0008572 </td>
   <td style="text-align:right;"> -0.1364328 </td>
   <td style="text-align:right;"> 1.714970e+00 </td>
   <td style="text-align:right;"> 2.438500e-02 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 6155 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> whitebark pine </td>
   <td style="text-align:left;"> Pinus albicaulis </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 101 </td>
   <td style="text-align:right;"> -20.8151866 </td>
   <td style="text-align:right;"> -0.9804298 </td>
   <td style="text-align:right;"> 8.239305e+01 </td>
   <td style="text-align:right;"> 4.039680e-01 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 13630 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> whitebark pine </td>
   <td style="text-align:left;"> Pinus albicaulis </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 101 </td>
   <td style="text-align:right;"> -24.8665724 </td>
   <td style="text-align:right;"> -7.8795321 </td>
   <td style="text-align:right;"> 7.968168e+01 </td>
   <td style="text-align:right;"> 1.663543e+01 </td>
   <td style="text-align:right;"> 52 </td>
   <td style="text-align:right;"> 13871 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> whitebark pine </td>
   <td style="text-align:left;"> Pinus albicaulis </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 101 </td>
   <td style="text-align:right;"> -7.4252030 </td>
   <td style="text-align:right;"> -5.4576165 </td>
   <td style="text-align:right;"> 1.065393e+01 </td>
   <td style="text-align:right;"> 5.290435e+00 </td>
   <td style="text-align:right;"> 97 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> whitebark pine </td>
   <td style="text-align:left;"> Pinus albicaulis </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 101 </td>
   <td style="text-align:right;"> -10.1291956 </td>
   <td style="text-align:right;"> -25.4662804 </td>
   <td style="text-align:right;"> 2.145157e+01 </td>
   <td style="text-align:right;"> 1.236803e+02 </td>
   <td style="text-align:right;"> 71 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
</tbody>
</table></div>


## Live Tree Growth
<div style="border: 1px solid #ddd; padding: 0px; overflow-y: scroll; height:500px; overflow-x: scroll; width:100%; "><table class=" lightable-material lightable-striped lightable-hover table" style='font-family: "Source Sans Pro", helvetica, sans-serif; margin-left: auto; margin-right: auto; font-size: 13px; margin-left: auto; margin-right: auto;'>
 <thead>
  <tr>
   <th style="text-align:left;position: sticky; top:0; background-color: #FFFFFF;"> COMMON_NAME </th>
   <th style="text-align:left;position: sticky; top:0; background-color: #FFFFFF;"> SCIENTIFIC_NAME </th>
   <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> SITECLCD </th>
   <th style="text-align:left;position: sticky; top:0; background-color: #FFFFFF;"> siteProd </th>
   <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> SPCD </th>
   <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> BA_GROW </th>
   <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> BA_GROW_AC </th>
   <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> BA_GROW_VAR </th>
   <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> BA_GROW_AC_VAR </th>
   <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> nPlots_TREE </th>
   <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> N </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Alaska yellow-cedar </td>
   <td style="text-align:left;"> Chamaecyparis nootkatensis </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 42 </td>
   <td style="text-align:right;"> 9.5537006 </td>
   <td style="text-align:right;"> 0.2040035 </td>
   <td style="text-align:right;"> 9.6694082 </td>
   <td style="text-align:right;"> 1.190010e-02 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 2621 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Alaska yellow-cedar </td>
   <td style="text-align:left;"> Chamaecyparis nootkatensis </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 42 </td>
   <td style="text-align:right;"> 10.8149649 </td>
   <td style="text-align:right;"> 1.2067632 </td>
   <td style="text-align:right;"> 8.0813156 </td>
   <td style="text-align:right;"> 1.812694e-01 </td>
   <td style="text-align:right;"> 27 </td>
   <td style="text-align:right;"> 20188 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Alaska yellow-cedar </td>
   <td style="text-align:left;"> Chamaecyparis nootkatensis </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 42 </td>
   <td style="text-align:right;"> 7.0318743 </td>
   <td style="text-align:right;"> 4.8576100 </td>
   <td style="text-align:right;"> 3.5592218 </td>
   <td style="text-align:right;"> 4.176727e+00 </td>
   <td style="text-align:right;"> 25 </td>
   <td style="text-align:right;"> 13582 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Alaska yellow-cedar </td>
   <td style="text-align:left;"> Chamaecyparis nootkatensis </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 42 </td>
   <td style="text-align:right;"> 3.9392019 </td>
   <td style="text-align:right;"> 2.8262767 </td>
   <td style="text-align:right;"> 0.3864393 </td>
   <td style="text-align:right;"> 4.461794e-01 </td>
   <td style="text-align:right;"> 35 </td>
   <td style="text-align:right;"> 13871 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Alaska yellow-cedar </td>
   <td style="text-align:left;"> Chamaecyparis nootkatensis </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 42 </td>
   <td style="text-align:right;"> 4.3773462 </td>
   <td style="text-align:right;"> 3.5770356 </td>
   <td style="text-align:right;"> 0.5018419 </td>
   <td style="text-align:right;"> 1.354426e+00 </td>
   <td style="text-align:right;"> 30 </td>
   <td style="text-align:right;"> 13582 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Alaska yellow-cedar </td>
   <td style="text-align:left;"> Chamaecyparis nootkatensis </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 42 </td>
   <td style="text-align:right;"> 6.9479066 </td>
   <td style="text-align:right;"> 2.3817958 </td>
   <td style="text-align:right;"> 4.7342038 </td>
   <td style="text-align:right;"> 1.083495e+00 </td>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:right;"> 7427 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> bigleaf maple </td>
   <td style="text-align:left;"> Acer macrophyllum </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 312 </td>
   <td style="text-align:right;"> 16.1952164 </td>
   <td style="text-align:right;"> 10.3120139 </td>
   <td style="text-align:right;"> 13.6991239 </td>
   <td style="text-align:right;"> 2.367889e+01 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> bigleaf maple </td>
   <td style="text-align:left;"> Acer macrophyllum </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 312 </td>
   <td style="text-align:right;"> 17.2635392 </td>
   <td style="text-align:right;"> 92.8296462 </td>
   <td style="text-align:right;"> 0.8886836 </td>
   <td style="text-align:right;"> 1.005198e+02 </td>
   <td style="text-align:right;"> 254 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> bigleaf maple </td>
   <td style="text-align:left;"> Acer macrophyllum </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 312 </td>
   <td style="text-align:right;"> 15.7609633 </td>
   <td style="text-align:right;"> 82.5429639 </td>
   <td style="text-align:right;"> 0.6237964 </td>
   <td style="text-align:right;"> 1.050067e+02 </td>
   <td style="text-align:right;"> 314 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> bigleaf maple </td>
   <td style="text-align:left;"> Acer macrophyllum </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 312 </td>
   <td style="text-align:right;"> 13.6310548 </td>
   <td style="text-align:right;"> 22.6415252 </td>
   <td style="text-align:right;"> 2.7378253 </td>
   <td style="text-align:right;"> 1.971277e+01 </td>
   <td style="text-align:right;"> 141 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> bigleaf maple </td>
   <td style="text-align:left;"> Acer macrophyllum </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 312 </td>
   <td style="text-align:right;"> 13.0590414 </td>
   <td style="text-align:right;"> 4.6361452 </td>
   <td style="text-align:right;"> 5.5574911 </td>
   <td style="text-align:right;"> 1.334311e+00 </td>
   <td style="text-align:right;"> 43 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> bigleaf maple </td>
   <td style="text-align:left;"> Acer macrophyllum </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 312 </td>
   <td style="text-align:right;"> 11.0333827 </td>
   <td style="text-align:right;"> 3.1456747 </td>
   <td style="text-align:right;"> 0.9547846 </td>
   <td style="text-align:right;"> 3.499111e+00 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> bigleaf maple </td>
   <td style="text-align:left;"> Acer macrophyllum </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 312 </td>
   <td style="text-align:right;"> 15.2472639 </td>
   <td style="text-align:right;"> 3.7002891 </td>
   <td style="text-align:right;"> 8.9974191 </td>
   <td style="text-align:right;"> 3.833988e+00 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 20188 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> bitter cherry </td>
   <td style="text-align:left;"> Prunus emarginata </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 768 </td>
   <td style="text-align:right;"> 11.6483047 </td>
   <td style="text-align:right;"> 4.9852288 </td>
   <td style="text-align:right;"> 2.6395705 </td>
   <td style="text-align:right;"> 2.164233e+00 </td>
   <td style="text-align:right;"> 43 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> bitter cherry </td>
   <td style="text-align:left;"> Prunus emarginata </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 768 </td>
   <td style="text-align:right;"> 9.4310702 </td>
   <td style="text-align:right;"> 2.4812125 </td>
   <td style="text-align:right;"> 1.7204908 </td>
   <td style="text-align:right;"> 2.786283e-01 </td>
   <td style="text-align:right;"> 44 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> bitter cherry </td>
   <td style="text-align:left;"> Prunus emarginata </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 768 </td>
   <td style="text-align:right;"> 9.5194663 </td>
   <td style="text-align:right;"> 0.6155751 </td>
   <td style="text-align:right;"> 3.4399437 </td>
   <td style="text-align:right;"> 5.477760e-02 </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> bitter cherry </td>
   <td style="text-align:left;"> Prunus emarginata </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 768 </td>
   <td style="text-align:right;"> 4.7326356 </td>
   <td style="text-align:right;"> 0.0985011 </td>
   <td style="text-align:right;"> 2.0132891 </td>
   <td style="text-align:right;"> 2.829900e-03 </td>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> bitter cherry </td>
   <td style="text-align:left;"> Prunus emarginata </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 768 </td>
   <td style="text-align:right;"> 8.0726919 </td>
   <td style="text-align:right;"> 0.1951893 </td>
   <td style="text-align:right;"> 0.8713665 </td>
   <td style="text-align:right;"> 3.362980e-02 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> bitter cherry </td>
   <td style="text-align:left;"> Prunus emarginata </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 768 </td>
   <td style="text-align:right;"> 5.4598752 </td>
   <td style="text-align:right;"> 0.0718452 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 4.783600e-03 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 11171 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> black cottonwood </td>
   <td style="text-align:left;"> Populus balsamifera </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 747 </td>
   <td style="text-align:right;"> 94.9135931 </td>
   <td style="text-align:right;"> 1.4991317 </td>
   <td style="text-align:right;"> 802.0200790 </td>
   <td style="text-align:right;"> 1.127102e+00 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 4565 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> black cottonwood </td>
   <td style="text-align:left;"> Populus balsamifera </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 747 </td>
   <td style="text-align:right;"> 43.1253199 </td>
   <td style="text-align:right;"> 16.3606928 </td>
   <td style="text-align:right;"> 31.6003049 </td>
   <td style="text-align:right;"> 1.920744e+01 </td>
   <td style="text-align:right;"> 35 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> black cottonwood </td>
   <td style="text-align:left;"> Populus balsamifera </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 747 </td>
   <td style="text-align:right;"> 41.1263557 </td>
   <td style="text-align:right;"> 15.9412883 </td>
   <td style="text-align:right;"> 19.5777944 </td>
   <td style="text-align:right;"> 1.298598e+01 </td>
   <td style="text-align:right;"> 55 </td>
   <td style="text-align:right;"> 20188 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> black cottonwood </td>
   <td style="text-align:left;"> Populus balsamifera </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 747 </td>
   <td style="text-align:right;"> 41.4838891 </td>
   <td style="text-align:right;"> 8.7218322 </td>
   <td style="text-align:right;"> 55.4733665 </td>
   <td style="text-align:right;"> 1.254003e+01 </td>
   <td style="text-align:right;"> 24 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> black cottonwood </td>
   <td style="text-align:left;"> Populus balsamifera </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 747 </td>
   <td style="text-align:right;"> 33.4710276 </td>
   <td style="text-align:right;"> 1.4567809 </td>
   <td style="text-align:right;"> 60.8605658 </td>
   <td style="text-align:right;"> 3.328781e-01 </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> black cottonwood </td>
   <td style="text-align:left;"> Populus balsamifera </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 747 </td>
   <td style="text-align:right;"> 17.8258755 </td>
   <td style="text-align:right;"> 0.0649802 </td>
   <td style="text-align:right;"> 15.8388270 </td>
   <td style="text-align:right;"> 1.158800e-03 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 15382 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> black cottonwood </td>
   <td style="text-align:left;"> Populus balsamifera </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 747 </td>
   <td style="text-align:right;"> 40.0071046 </td>
   <td style="text-align:right;"> 17.8052466 </td>
   <td style="text-align:right;"> 147.1053692 </td>
   <td style="text-align:right;"> 7.509306e+01 </td>
   <td style="text-align:right;"> 12 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> black locust </td>
   <td style="text-align:left;"> Robinia pseudoacacia </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 901 </td>
   <td style="text-align:right;"> 11.7673289 </td>
   <td style="text-align:right;"> 0.6849901 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 4.356033e-01 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 6606 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Brewer spruce </td>
   <td style="text-align:left;"> Picea breweriana </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 92 </td>
   <td style="text-align:right;"> 3.7516174 </td>
   <td style="text-align:right;"> 0.0315957 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 9.437000e-04 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 6155 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California black oak </td>
   <td style="text-align:left;"> Quercus kelloggii </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 818 </td>
   <td style="text-align:right;"> 11.0990916 </td>
   <td style="text-align:right;"> 0.1420526 </td>
   <td style="text-align:right;"> 2.1042517 </td>
   <td style="text-align:right;"> 1.063870e-02 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 6606 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California black oak </td>
   <td style="text-align:left;"> Quercus kelloggii </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 818 </td>
   <td style="text-align:right;"> 6.2472959 </td>
   <td style="text-align:right;"> 0.3833236 </td>
   <td style="text-align:right;"> 3.6984403 </td>
   <td style="text-align:right;"> 2.562010e-02 </td>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California black oak </td>
   <td style="text-align:left;"> Quercus kelloggii </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 818 </td>
   <td style="text-align:right;"> 4.9848270 </td>
   <td style="text-align:right;"> 2.3274357 </td>
   <td style="text-align:right;"> 0.5500499 </td>
   <td style="text-align:right;"> 4.285670e-01 </td>
   <td style="text-align:right;"> 20 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California black oak </td>
   <td style="text-align:left;"> Quercus kelloggii </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 818 </td>
   <td style="text-align:right;"> 3.7267700 </td>
   <td style="text-align:right;"> 2.3093566 </td>
   <td style="text-align:right;"> 0.1339447 </td>
   <td style="text-align:right;"> 3.886427e-01 </td>
   <td style="text-align:right;"> 41 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California black oak </td>
   <td style="text-align:left;"> Quercus kelloggii </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 818 </td>
   <td style="text-align:right;"> 5.6834571 </td>
   <td style="text-align:right;"> 2.4971743 </td>
   <td style="text-align:right;"> 1.0363232 </td>
   <td style="text-align:right;"> 5.678315e-01 </td>
   <td style="text-align:right;"> 20 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California black oak </td>
   <td style="text-align:left;"> Quercus kelloggii </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 818 </td>
   <td style="text-align:right;"> 7.0782790 </td>
   <td style="text-align:right;"> 3.5352138 </td>
   <td style="text-align:right;"> 1.0991376 </td>
   <td style="text-align:right;"> 1.281379e+00 </td>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:right;"> 6606 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California laurel </td>
   <td style="text-align:left;"> Umbellularia californica </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 981 </td>
   <td style="text-align:right;"> 10.1114976 </td>
   <td style="text-align:right;"> 3.2697000 </td>
   <td style="text-align:right;"> 3.0873976 </td>
   <td style="text-align:right;"> 2.158208e+00 </td>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California laurel </td>
   <td style="text-align:left;"> Umbellularia californica </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 981 </td>
   <td style="text-align:right;"> 10.7523053 </td>
   <td style="text-align:right;"> 5.1611025 </td>
   <td style="text-align:right;"> 2.4898258 </td>
   <td style="text-align:right;"> 2.529402e+00 </td>
   <td style="text-align:right;"> 30 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California laurel </td>
   <td style="text-align:left;"> Umbellularia californica </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 981 </td>
   <td style="text-align:right;"> 6.6443176 </td>
   <td style="text-align:right;"> 3.3232364 </td>
   <td style="text-align:right;"> 0.5131621 </td>
   <td style="text-align:right;"> 1.301529e+00 </td>
   <td style="text-align:right;"> 26 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California laurel </td>
   <td style="text-align:left;"> Umbellularia californica </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 981 </td>
   <td style="text-align:right;"> 31.0540079 </td>
   <td style="text-align:right;"> 1.8565105 </td>
   <td style="text-align:right;"> 103.2445986 </td>
   <td style="text-align:right;"> 3.577018e+00 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California laurel </td>
   <td style="text-align:left;"> Umbellularia californica </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 981 </td>
   <td style="text-align:right;"> -0.2728196 </td>
   <td style="text-align:right;"> -0.0032956 </td>
   <td style="text-align:right;"> 0.9540861 </td>
   <td style="text-align:right;"> 1.407000e-04 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California red fir </td>
   <td style="text-align:left;"> Abies magnifica </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 20 </td>
   <td style="text-align:right;"> 17.9113946 </td>
   <td style="text-align:right;"> 0.6417324 </td>
   <td style="text-align:right;"> 7.8264472 </td>
   <td style="text-align:right;"> 2.129499e-01 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 6444 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California red fir </td>
   <td style="text-align:left;"> Abies magnifica </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 20 </td>
   <td style="text-align:right;"> 15.3904996 </td>
   <td style="text-align:right;"> 0.6410166 </td>
   <td style="text-align:right;"> 10.2246732 </td>
   <td style="text-align:right;"> 2.086941e-01 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California red fir </td>
   <td style="text-align:left;"> Abies magnifica </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 20 </td>
   <td style="text-align:right;"> 17.0764385 </td>
   <td style="text-align:right;"> 0.9417633 </td>
   <td style="text-align:right;"> 0.4636227 </td>
   <td style="text-align:right;"> 5.820901e-01 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 6444 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> California red fir </td>
   <td style="text-align:left;"> Abies magnifica </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 20 </td>
   <td style="text-align:right;"> 31.7884687 </td>
   <td style="text-align:right;"> 0.0543186 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 3.216500e-03 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 6155 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> canyon live oak </td>
   <td style="text-align:left;"> Quercus chrysolepis </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 805 </td>
   <td style="text-align:right;"> 3.4885810 </td>
   <td style="text-align:right;"> 0.0401474 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 1.776800e-03 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 6606 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> canyon live oak </td>
   <td style="text-align:left;"> Quercus chrysolepis </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 805 </td>
   <td style="text-align:right;"> 3.5152811 </td>
   <td style="text-align:right;"> 0.2990265 </td>
   <td style="text-align:right;"> 2.8482214 </td>
   <td style="text-align:right;"> 3.877570e-02 </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> canyon live oak </td>
   <td style="text-align:left;"> Quercus chrysolepis </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 805 </td>
   <td style="text-align:right;"> 4.9713466 </td>
   <td style="text-align:right;"> 3.1073115 </td>
   <td style="text-align:right;"> 0.3296798 </td>
   <td style="text-align:right;"> 5.350884e-01 </td>
   <td style="text-align:right;"> 54 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> canyon live oak </td>
   <td style="text-align:left;"> Quercus chrysolepis </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 805 </td>
   <td style="text-align:right;"> 3.2186928 </td>
   <td style="text-align:right;"> 1.9960630 </td>
   <td style="text-align:right;"> 0.0681074 </td>
   <td style="text-align:right;"> 2.432184e-01 </td>
   <td style="text-align:right;"> 47 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> canyon live oak </td>
   <td style="text-align:left;"> Quercus chrysolepis </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 805 </td>
   <td style="text-align:right;"> 3.2251421 </td>
   <td style="text-align:right;"> 1.3709366 </td>
   <td style="text-align:right;"> 0.2190768 </td>
   <td style="text-align:right;"> 1.847040e-01 </td>
   <td style="text-align:right;"> 23 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> canyon live oak </td>
   <td style="text-align:left;"> Quercus chrysolepis </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 805 </td>
   <td style="text-align:right;"> 3.0948177 </td>
   <td style="text-align:right;"> 2.8897093 </td>
   <td style="text-align:right;"> 0.0515899 </td>
   <td style="text-align:right;"> 2.126489e+00 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> chokecherry </td>
   <td style="text-align:left;"> Prunus virginiana </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 763 </td>
   <td style="text-align:right;"> 3.3038067 </td>
   <td style="text-align:right;"> 0.1032037 </td>
   <td style="text-align:right;"> 5.4311176 </td>
   <td style="text-align:right;"> 5.216600e-03 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 13792 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> chokecherry </td>
   <td style="text-align:left;"> Prunus virginiana </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 763 </td>
   <td style="text-align:right;"> 14.5609197 </td>
   <td style="text-align:right;"> 0.2780307 </td>
   <td style="text-align:right;"> 3.1393963 </td>
   <td style="text-align:right;"> 3.379850e-02 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> chokecherry </td>
   <td style="text-align:left;"> Prunus virginiana </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 763 </td>
   <td style="text-align:right;"> 0.4800293 </td>
   <td style="text-align:right;"> 0.0032071 </td>
   <td style="text-align:right;"> 0.2413183 </td>
   <td style="text-align:right;"> 9.400000e-06 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> chokecherry </td>
   <td style="text-align:left;"> Prunus virginiana </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 763 </td>
   <td style="text-align:right;"> 3.7697956 </td>
   <td style="text-align:right;"> 0.0215816 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 3.074000e-04 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 20188 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Douglas-fir </td>
   <td style="text-align:left;"> Pseudotsuga menziesii </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 202 </td>
   <td style="text-align:right;"> 28.4005477 </td>
   <td style="text-align:right;"> 386.6207359 </td>
   <td style="text-align:right;"> 2.0982639 </td>
   <td style="text-align:right;"> 3.699274e+03 </td>
   <td style="text-align:right;"> 97 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Douglas-fir </td>
   <td style="text-align:left;"> Pseudotsuga menziesii </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 202 </td>
   <td style="text-align:right;"> 30.0843164 </td>
   <td style="text-align:right;"> 2067.8559637 </td>
   <td style="text-align:right;"> 0.2002046 </td>
   <td style="text-align:right;"> 4.113197e+03 </td>
   <td style="text-align:right;"> 1057 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Douglas-fir </td>
   <td style="text-align:left;"> Pseudotsuga menziesii </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 202 </td>
   <td style="text-align:right;"> 27.3199572 </td>
   <td style="text-align:right;"> 1529.6969908 </td>
   <td style="text-align:right;"> 0.1153132 </td>
   <td style="text-align:right;"> 1.691670e+03 </td>
   <td style="text-align:right;"> 1816 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Douglas-fir </td>
   <td style="text-align:left;"> Pseudotsuga menziesii </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 202 </td>
   <td style="text-align:right;"> 21.6361055 </td>
   <td style="text-align:right;"> 806.3845258 </td>
   <td style="text-align:right;"> 0.1741386 </td>
   <td style="text-align:right;"> 7.317781e+02 </td>
   <td style="text-align:right;"> 1546 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Douglas-fir </td>
   <td style="text-align:left;"> Pseudotsuga menziesii </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 202 </td>
   <td style="text-align:right;"> 16.2672756 </td>
   <td style="text-align:right;"> 462.6685908 </td>
   <td style="text-align:right;"> 0.0982437 </td>
   <td style="text-align:right;"> 1.989767e+02 </td>
   <td style="text-align:right;"> 1866 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Douglas-fir </td>
   <td style="text-align:left;"> Pseudotsuga menziesii </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 202 </td>
   <td style="text-align:right;"> 11.6950140 </td>
   <td style="text-align:right;"> 266.7255762 </td>
   <td style="text-align:right;"> 0.1138966 </td>
   <td style="text-align:right;"> 1.383054e+02 </td>
   <td style="text-align:right;"> 1072 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Douglas-fir </td>
   <td style="text-align:left;"> Pseudotsuga menziesii </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 202 </td>
   <td style="text-align:right;"> 10.2589720 </td>
   <td style="text-align:right;"> 48.8410967 </td>
   <td style="text-align:right;"> 1.0126682 </td>
   <td style="text-align:right;"> 5.737141e+01 </td>
   <td style="text-align:right;"> 132 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Engelmann spruce </td>
   <td style="text-align:left;"> Picea engelmannii </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 93 </td>
   <td style="text-align:right;"> 21.5629580 </td>
   <td style="text-align:right;"> 4.9369645 </td>
   <td style="text-align:right;"> 11.3502305 </td>
   <td style="text-align:right;"> 3.164587e+00 </td>
   <td style="text-align:right;"> 22 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Engelmann spruce </td>
   <td style="text-align:left;"> Picea engelmannii </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 93 </td>
   <td style="text-align:right;"> 16.1011992 </td>
   <td style="text-align:right;"> 15.6848501 </td>
   <td style="text-align:right;"> 1.5561077 </td>
   <td style="text-align:right;"> 9.448806e+00 </td>
   <td style="text-align:right;"> 100 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Engelmann spruce </td>
   <td style="text-align:left;"> Picea engelmannii </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 93 </td>
   <td style="text-align:right;"> 14.8807090 </td>
   <td style="text-align:right;"> 39.4417426 </td>
   <td style="text-align:right;"> 0.9180589 </td>
   <td style="text-align:right;"> 2.124317e+01 </td>
   <td style="text-align:right;"> 240 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Engelmann spruce </td>
   <td style="text-align:left;"> Picea engelmannii </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 93 </td>
   <td style="text-align:right;"> 12.0730220 </td>
   <td style="text-align:right;"> 20.8737682 </td>
   <td style="text-align:right;"> 0.5258341 </td>
   <td style="text-align:right;"> 4.699746e+00 </td>
   <td style="text-align:right;"> 261 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Engelmann spruce </td>
   <td style="text-align:left;"> Picea engelmannii </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 93 </td>
   <td style="text-align:right;"> 10.4734324 </td>
   <td style="text-align:right;"> 9.8869327 </td>
   <td style="text-align:right;"> 0.5001386 </td>
   <td style="text-align:right;"> 2.093032e+00 </td>
   <td style="text-align:right;"> 122 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Engelmann spruce </td>
   <td style="text-align:left;"> Picea engelmannii </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 93 </td>
   <td style="text-align:right;"> 12.0652735 </td>
   <td style="text-align:right;"> 11.9937624 </td>
   <td style="text-align:right;"> 1.2223055 </td>
   <td style="text-align:right;"> 1.783406e+01 </td>
   <td style="text-align:right;"> 32 </td>
   <td style="text-align:right;"> 13871 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> giant chinkapin, golden chinkapin </td>
   <td style="text-align:left;"> Chrysolepis chrysophylla </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 431 </td>
   <td style="text-align:right;"> 10.0982957 </td>
   <td style="text-align:right;"> 1.5651559 </td>
   <td style="text-align:right;"> 3.0673215 </td>
   <td style="text-align:right;"> 3.785701e-01 </td>
   <td style="text-align:right;"> 19 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> giant chinkapin, golden chinkapin </td>
   <td style="text-align:left;"> Chrysolepis chrysophylla </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 431 </td>
   <td style="text-align:right;"> 5.8282506 </td>
   <td style="text-align:right;"> 4.9046217 </td>
   <td style="text-align:right;"> 0.5103934 </td>
   <td style="text-align:right;"> 1.064509e+00 </td>
   <td style="text-align:right;"> 113 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> giant chinkapin, golden chinkapin </td>
   <td style="text-align:left;"> Chrysolepis chrysophylla </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 431 </td>
   <td style="text-align:right;"> 6.9348653 </td>
   <td style="text-align:right;"> 3.8618633 </td>
   <td style="text-align:right;"> 0.3980129 </td>
   <td style="text-align:right;"> 5.940505e-01 </td>
   <td style="text-align:right;"> 88 </td>
   <td style="text-align:right;"> 17615 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> giant chinkapin, golden chinkapin </td>
   <td style="text-align:left;"> Chrysolepis chrysophylla </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 431 </td>
   <td style="text-align:right;"> 6.0238755 </td>
   <td style="text-align:right;"> 3.5447472 </td>
   <td style="text-align:right;"> 0.3553251 </td>
   <td style="text-align:right;"> 9.153744e-01 </td>
   <td style="text-align:right;"> 68 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> giant chinkapin, golden chinkapin </td>
   <td style="text-align:left;"> Chrysolepis chrysophylla </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 431 </td>
   <td style="text-align:right;"> 3.5847002 </td>
   <td style="text-align:right;"> 0.4569762 </td>
   <td style="text-align:right;"> 0.1504295 </td>
   <td style="text-align:right;"> 4.403750e-02 </td>
   <td style="text-align:right;"> 19 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> giant chinkapin, golden chinkapin </td>
   <td style="text-align:left;"> Chrysolepis chrysophylla </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 431 </td>
   <td style="text-align:right;"> 6.0923491 </td>
   <td style="text-align:right;"> 1.7979597 </td>
   <td style="text-align:right;"> 1.9067154 </td>
   <td style="text-align:right;"> 1.392374e+00 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> giant sequoia </td>
   <td style="text-align:left;"> Sequoiadendron giganteum </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 212 </td>
   <td style="text-align:right;"> 33.1039402 </td>
   <td style="text-align:right;"> 0.2852228 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 6.180090e-02 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 6606 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> grand fir </td>
   <td style="text-align:left;"> Abies grandis </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 27.3253673 </td>
   <td style="text-align:right;"> 5.5859680 </td>
   <td style="text-align:right;"> 46.3599028 </td>
   <td style="text-align:right;"> 1.457426e+01 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 13792 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> grand fir </td>
   <td style="text-align:left;"> Abies grandis </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 34.5541155 </td>
   <td style="text-align:right;"> 20.1760132 </td>
   <td style="text-align:right;"> 13.5227429 </td>
   <td style="text-align:right;"> 3.097876e+01 </td>
   <td style="text-align:right;"> 48 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> grand fir </td>
   <td style="text-align:left;"> Abies grandis </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 23.4939915 </td>
   <td style="text-align:right;"> 72.3790180 </td>
   <td style="text-align:right;"> 0.9525761 </td>
   <td style="text-align:right;"> 5.333162e+01 </td>
   <td style="text-align:right;"> 297 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> grand fir </td>
   <td style="text-align:left;"> Abies grandis </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 19.5949061 </td>
   <td style="text-align:right;"> 159.4196124 </td>
   <td style="text-align:right;"> 0.4216187 </td>
   <td style="text-align:right;"> 1.176019e+02 </td>
   <td style="text-align:right;"> 547 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> grand fir </td>
   <td style="text-align:left;"> Abies grandis </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 15.2904644 </td>
   <td style="text-align:right;"> 110.7330003 </td>
   <td style="text-align:right;"> 0.2801903 </td>
   <td style="text-align:right;"> 4.153451e+01 </td>
   <td style="text-align:right;"> 663 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> grand fir </td>
   <td style="text-align:left;"> Abies grandis </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 14.2532297 </td>
   <td style="text-align:right;"> 51.2767800 </td>
   <td style="text-align:right;"> 0.3655289 </td>
   <td style="text-align:right;"> 1.621179e+01 </td>
   <td style="text-align:right;"> 319 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> grand fir </td>
   <td style="text-align:left;"> Abies grandis </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 11.5401585 </td>
   <td style="text-align:right;"> 2.4721795 </td>
   <td style="text-align:right;"> 3.0458993 </td>
   <td style="text-align:right;"> 1.075467e+00 </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> incense-cedar </td>
   <td style="text-align:left;"> Calocedrus decurrens </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 81 </td>
   <td style="text-align:right;"> 14.7051737 </td>
   <td style="text-align:right;"> 2.0908690 </td>
   <td style="text-align:right;"> 17.1888981 </td>
   <td style="text-align:right;"> 1.101220e+00 </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> incense-cedar </td>
   <td style="text-align:left;"> Calocedrus decurrens </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 81 </td>
   <td style="text-align:right;"> 18.8643436 </td>
   <td style="text-align:right;"> 16.9361240 </td>
   <td style="text-align:right;"> 2.4840950 </td>
   <td style="text-align:right;"> 1.374600e+01 </td>
   <td style="text-align:right;"> 143 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> incense-cedar </td>
   <td style="text-align:left;"> Calocedrus decurrens </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 81 </td>
   <td style="text-align:right;"> 17.6380103 </td>
   <td style="text-align:right;"> 22.2842929 </td>
   <td style="text-align:right;"> 1.9997702 </td>
   <td style="text-align:right;"> 1.014950e+01 </td>
   <td style="text-align:right;"> 166 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> incense-cedar </td>
   <td style="text-align:left;"> Calocedrus decurrens </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 81 </td>
   <td style="text-align:right;"> 16.2433075 </td>
   <td style="text-align:right;"> 15.0794547 </td>
   <td style="text-align:right;"> 3.7954458 </td>
   <td style="text-align:right;"> 5.117961e+00 </td>
   <td style="text-align:right;"> 150 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> incense-cedar </td>
   <td style="text-align:left;"> Calocedrus decurrens </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 81 </td>
   <td style="text-align:right;"> 11.7101405 </td>
   <td style="text-align:right;"> 7.0707574 </td>
   <td style="text-align:right;"> 1.5715279 </td>
   <td style="text-align:right;"> 2.354820e+00 </td>
   <td style="text-align:right;"> 74 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> incense-cedar </td>
   <td style="text-align:left;"> Calocedrus decurrens </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 81 </td>
   <td style="text-align:right;"> 19.2688573 </td>
   <td style="text-align:right;"> 4.6854195 </td>
   <td style="text-align:right;"> 23.5707119 </td>
   <td style="text-align:right;"> 4.760422e+00 </td>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Jeffrey pine </td>
   <td style="text-align:left;"> Pinus jeffreyi </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 116 </td>
   <td style="text-align:right;"> 16.3525974 </td>
   <td style="text-align:right;"> 0.7383777 </td>
   <td style="text-align:right;"> 7.0480089 </td>
   <td style="text-align:right;"> 1.987167e-01 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Jeffrey pine </td>
   <td style="text-align:left;"> Pinus jeffreyi </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 116 </td>
   <td style="text-align:right;"> 12.4919279 </td>
   <td style="text-align:right;"> 1.9535439 </td>
   <td style="text-align:right;"> 16.5004017 </td>
   <td style="text-align:right;"> 5.973718e-01 </td>
   <td style="text-align:right;"> 12 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Jeffrey pine </td>
   <td style="text-align:left;"> Pinus jeffreyi </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 116 </td>
   <td style="text-align:right;"> 9.6257986 </td>
   <td style="text-align:right;"> 1.0797878 </td>
   <td style="text-align:right;"> 4.4705667 </td>
   <td style="text-align:right;"> 1.311076e-01 </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Jeffrey pine </td>
   <td style="text-align:left;"> Pinus jeffreyi </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 116 </td>
   <td style="text-align:right;"> 7.8549536 </td>
   <td style="text-align:right;"> 0.5043418 </td>
   <td style="text-align:right;"> 2.1281982 </td>
   <td style="text-align:right;"> 7.140530e-02 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 6155 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> knobcone pine </td>
   <td style="text-align:left;"> Pinus attenuata </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 103 </td>
   <td style="text-align:right;"> 0.5192349 </td>
   <td style="text-align:right;"> 0.0013575 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 1.900000e-06 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 6155 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> knobcone pine </td>
   <td style="text-align:left;"> Pinus attenuata </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 103 </td>
   <td style="text-align:right;"> 8.4194811 </td>
   <td style="text-align:right;"> 0.1418515 </td>
   <td style="text-align:right;"> 13.2522958 </td>
   <td style="text-align:right;"> 1.870090e-02 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> knobcone pine </td>
   <td style="text-align:left;"> Pinus attenuata </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 103 </td>
   <td style="text-align:right;"> 7.5308248 </td>
   <td style="text-align:right;"> 0.1899895 </td>
   <td style="text-align:right;"> 9.6325800 </td>
   <td style="text-align:right;"> 8.393900e-03 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> knobcone pine </td>
   <td style="text-align:left;"> Pinus attenuata </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 103 </td>
   <td style="text-align:right;"> 2.3148365 </td>
   <td style="text-align:right;"> 0.0633968 </td>
   <td style="text-align:right;"> 0.2183638 </td>
   <td style="text-align:right;"> 1.361000e-03 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 6444 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> knobcone pine </td>
   <td style="text-align:left;"> Pinus attenuata </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 103 </td>
   <td style="text-align:right;"> 6.3038812 </td>
   <td style="text-align:right;"> 0.1455629 </td>
   <td style="text-align:right;"> 0.1974948 </td>
   <td style="text-align:right;"> 1.188590e-02 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 6155 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> lodgepole pine </td>
   <td style="text-align:left;"> Pinus contorta </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 108 </td>
   <td style="text-align:right;"> 9.9720606 </td>
   <td style="text-align:right;"> 0.9431780 </td>
   <td style="text-align:right;"> 3.9853640 </td>
   <td style="text-align:right;"> 4.237147e-01 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 9227 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> lodgepole pine </td>
   <td style="text-align:left;"> Pinus contorta </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 108 </td>
   <td style="text-align:right;"> 14.3590955 </td>
   <td style="text-align:right;"> 2.5904921 </td>
   <td style="text-align:right;"> 5.7703837 </td>
   <td style="text-align:right;"> 1.434346e+00 </td>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> lodgepole pine </td>
   <td style="text-align:left;"> Pinus contorta </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 108 </td>
   <td style="text-align:right;"> 8.6079033 </td>
   <td style="text-align:right;"> 7.1479627 </td>
   <td style="text-align:right;"> 0.8711567 </td>
   <td style="text-align:right;"> 2.809562e+00 </td>
   <td style="text-align:right;"> 84 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> lodgepole pine </td>
   <td style="text-align:left;"> Pinus contorta </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 108 </td>
   <td style="text-align:right;"> 6.9903522 </td>
   <td style="text-align:right;"> 39.9188072 </td>
   <td style="text-align:right;"> 0.4858539 </td>
   <td style="text-align:right;"> 2.624551e+01 </td>
   <td style="text-align:right;"> 323 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> lodgepole pine </td>
   <td style="text-align:left;"> Pinus contorta </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 108 </td>
   <td style="text-align:right;"> 6.9943373 </td>
   <td style="text-align:right;"> 73.3754570 </td>
   <td style="text-align:right;"> 0.0585048 </td>
   <td style="text-align:right;"> 2.214534e+01 </td>
   <td style="text-align:right;"> 785 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> lodgepole pine </td>
   <td style="text-align:left;"> Pinus contorta </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 108 </td>
   <td style="text-align:right;"> 6.0532761 </td>
   <td style="text-align:right;"> 122.2253611 </td>
   <td style="text-align:right;"> 0.0693882 </td>
   <td style="text-align:right;"> 4.248116e+01 </td>
   <td style="text-align:right;"> 782 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> lodgepole pine </td>
   <td style="text-align:left;"> Pinus contorta </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 108 </td>
   <td style="text-align:right;"> 5.4179031 </td>
   <td style="text-align:right;"> 24.2551359 </td>
   <td style="text-align:right;"> 0.4080050 </td>
   <td style="text-align:right;"> 3.344979e+01 </td>
   <td style="text-align:right;"> 64 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> mountain hemlock </td>
   <td style="text-align:left;"> Tsuga mertensiana </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 264 </td>
   <td style="text-align:right;"> 12.9206705 </td>
   <td style="text-align:right;"> 0.1565663 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 2.600890e-02 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 2621 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> mountain hemlock </td>
   <td style="text-align:left;"> Tsuga mertensiana </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 264 </td>
   <td style="text-align:right;"> 10.3285081 </td>
   <td style="text-align:right;"> 1.6820950 </td>
   <td style="text-align:right;"> 7.0958166 </td>
   <td style="text-align:right;"> 4.973425e-01 </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 20188 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> mountain hemlock </td>
   <td style="text-align:left;"> Tsuga mertensiana </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 264 </td>
   <td style="text-align:right;"> 11.0209828 </td>
   <td style="text-align:right;"> 6.6993198 </td>
   <td style="text-align:right;"> 2.7878635 </td>
   <td style="text-align:right;"> 2.941611e+00 </td>
   <td style="text-align:right;"> 74 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> mountain hemlock </td>
   <td style="text-align:left;"> Tsuga mertensiana </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 264 </td>
   <td style="text-align:right;"> 8.6262635 </td>
   <td style="text-align:right;"> 22.2918217 </td>
   <td style="text-align:right;"> 0.3337825 </td>
   <td style="text-align:right;"> 1.225324e+01 </td>
   <td style="text-align:right;"> 138 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> mountain hemlock </td>
   <td style="text-align:left;"> Tsuga mertensiana </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 264 </td>
   <td style="text-align:right;"> 7.2652411 </td>
   <td style="text-align:right;"> 37.1802109 </td>
   <td style="text-align:right;"> 0.1386062 </td>
   <td style="text-align:right;"> 1.703446e+01 </td>
   <td style="text-align:right;"> 221 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> mountain hemlock </td>
   <td style="text-align:left;"> Tsuga mertensiana </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 264 </td>
   <td style="text-align:right;"> 6.6725145 </td>
   <td style="text-align:right;"> 65.3227588 </td>
   <td style="text-align:right;"> 0.1640031 </td>
   <td style="text-align:right;"> 5.110672e+01 </td>
   <td style="text-align:right;"> 228 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> mountain hemlock </td>
   <td style="text-align:left;"> Tsuga mertensiana </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 264 </td>
   <td style="text-align:right;"> 6.0400169 </td>
   <td style="text-align:right;"> 53.5595399 </td>
   <td style="text-align:right;"> 0.1161137 </td>
   <td style="text-align:right;"> 7.142533e+01 </td>
   <td style="text-align:right;"> 88 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> noble fir </td>
   <td style="text-align:left;"> Abies procera </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 22 </td>
   <td style="text-align:right;"> 29.9504190 </td>
   <td style="text-align:right;"> 56.7133012 </td>
   <td style="text-align:right;"> 6.2152995 </td>
   <td style="text-align:right;"> 1.393788e+03 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> noble fir </td>
   <td style="text-align:left;"> Abies procera </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 22 </td>
   <td style="text-align:right;"> 30.9025968 </td>
   <td style="text-align:right;"> 60.1635188 </td>
   <td style="text-align:right;"> 4.1306974 </td>
   <td style="text-align:right;"> 9.652984e+01 </td>
   <td style="text-align:right;"> 93 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> noble fir </td>
   <td style="text-align:left;"> Abies procera </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 22 </td>
   <td style="text-align:right;"> 27.1596610 </td>
   <td style="text-align:right;"> 33.0523734 </td>
   <td style="text-align:right;"> 4.5875794 </td>
   <td style="text-align:right;"> 3.579556e+01 </td>
   <td style="text-align:right;"> 133 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> noble fir </td>
   <td style="text-align:left;"> Abies procera </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 22 </td>
   <td style="text-align:right;"> 19.4197528 </td>
   <td style="text-align:right;"> 23.0855104 </td>
   <td style="text-align:right;"> 4.0099407 </td>
   <td style="text-align:right;"> 2.149512e+01 </td>
   <td style="text-align:right;"> 98 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> noble fir </td>
   <td style="text-align:left;"> Abies procera </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 22 </td>
   <td style="text-align:right;"> 19.2798496 </td>
   <td style="text-align:right;"> 9.2264323 </td>
   <td style="text-align:right;"> 5.7725118 </td>
   <td style="text-align:right;"> 5.116688e+00 </td>
   <td style="text-align:right;"> 72 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> noble fir </td>
   <td style="text-align:left;"> Abies procera </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 22 </td>
   <td style="text-align:right;"> 10.7682855 </td>
   <td style="text-align:right;"> 3.7876080 </td>
   <td style="text-align:right;"> 0.9814897 </td>
   <td style="text-align:right;"> 1.874157e+00 </td>
   <td style="text-align:right;"> 22 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> noble fir </td>
   <td style="text-align:left;"> Abies procera </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 22 </td>
   <td style="text-align:right;"> 15.1625997 </td>
   <td style="text-align:right;"> 0.3686904 </td>
   <td style="text-align:right;"> 25.0815312 </td>
   <td style="text-align:right;"> 3.988550e-02 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 15382 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> northern California black walnut </td>
   <td style="text-align:left;"> Juglans hindsii </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 603 </td>
   <td style="text-align:right;"> 7.5124929 </td>
   <td style="text-align:right;"> 0.5746596 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 3.545210e-01 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 4565 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Norway maple </td>
   <td style="text-align:left;"> Acer platanoides </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 320 </td>
   <td style="text-align:right;"> 21.6467591 </td>
   <td style="text-align:right;"> 0.1884499 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 2.598240e-02 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 6606 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon ash </td>
   <td style="text-align:left;"> Fraxinus latifolia </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 542 </td>
   <td style="text-align:right;"> 11.3925421 </td>
   <td style="text-align:right;"> 0.5483010 </td>
   <td style="text-align:right;"> 0.0411800 </td>
   <td style="text-align:right;"> 1.756043e-01 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 11171 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon ash </td>
   <td style="text-align:left;"> Fraxinus latifolia </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 542 </td>
   <td style="text-align:right;"> 13.9234743 </td>
   <td style="text-align:right;"> 7.9031205 </td>
   <td style="text-align:right;"> 3.2944583 </td>
   <td style="text-align:right;"> 4.682458e+00 </td>
   <td style="text-align:right;"> 31 </td>
   <td style="text-align:right;"> 17326 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon ash </td>
   <td style="text-align:left;"> Fraxinus latifolia </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 542 </td>
   <td style="text-align:right;"> 17.6832555 </td>
   <td style="text-align:right;"> 3.8223843 </td>
   <td style="text-align:right;"> 9.9202453 </td>
   <td style="text-align:right;"> 6.102264e+00 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 17326 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon ash </td>
   <td style="text-align:left;"> Fraxinus latifolia </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 542 </td>
   <td style="text-align:right;"> 12.9669345 </td>
   <td style="text-align:right;"> 1.5159875 </td>
   <td style="text-align:right;"> 1.1649951 </td>
   <td style="text-align:right;"> 1.067116e+00 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon ash </td>
   <td style="text-align:left;"> Fraxinus latifolia </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 542 </td>
   <td style="text-align:right;"> 11.6534980 </td>
   <td style="text-align:right;"> 2.8599824 </td>
   <td style="text-align:right;"> 6.0891516 </td>
   <td style="text-align:right;"> 3.496937e+00 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon crab apple </td>
   <td style="text-align:left;"> Malus fusca </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 661 </td>
   <td style="text-align:right;"> -2.2579813 </td>
   <td style="text-align:right;"> -0.0133808 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 1.916000e-04 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 11171 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon crab apple </td>
   <td style="text-align:left;"> Malus fusca </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 661 </td>
   <td style="text-align:right;"> 4.3541352 </td>
   <td style="text-align:right;"> 0.0590537 </td>
   <td style="text-align:right;"> 6.9157974 </td>
   <td style="text-align:right;"> 2.488000e-03 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 13792 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon crab apple </td>
   <td style="text-align:left;"> Malus fusca </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 661 </td>
   <td style="text-align:right;"> 5.5063294 </td>
   <td style="text-align:right;"> 0.1798704 </td>
   <td style="text-align:right;"> 5.8779384 </td>
   <td style="text-align:right;"> 1.145400e-02 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 7186 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon crab apple </td>
   <td style="text-align:left;"> Malus fusca </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 661 </td>
   <td style="text-align:right;"> 7.4798378 </td>
   <td style="text-align:right;"> 0.1206187 </td>
   <td style="text-align:right;"> 8.6373825 </td>
   <td style="text-align:right;"> 7.535500e-03 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 11171 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon white oak </td>
   <td style="text-align:left;"> Quercus garryana </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 815 </td>
   <td style="text-align:right;"> 11.8387472 </td>
   <td style="text-align:right;"> 1.7529606 </td>
   <td style="text-align:right;"> 2.9732679 </td>
   <td style="text-align:right;"> 7.800004e-01 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 6606 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon white oak </td>
   <td style="text-align:left;"> Quercus garryana </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 815 </td>
   <td style="text-align:right;"> 8.8195841 </td>
   <td style="text-align:right;"> 3.0433471 </td>
   <td style="text-align:right;"> 2.2516001 </td>
   <td style="text-align:right;"> 5.533537e-01 </td>
   <td style="text-align:right;"> 26 </td>
   <td style="text-align:right;"> 17326 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon white oak </td>
   <td style="text-align:left;"> Quercus garryana </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 815 </td>
   <td style="text-align:right;"> 5.2006599 </td>
   <td style="text-align:right;"> 2.1075509 </td>
   <td style="text-align:right;"> 0.7297635 </td>
   <td style="text-align:right;"> 5.202536e-01 </td>
   <td style="text-align:right;"> 24 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon white oak </td>
   <td style="text-align:left;"> Quercus garryana </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 815 </td>
   <td style="text-align:right;"> 4.7813103 </td>
   <td style="text-align:right;"> 3.5563263 </td>
   <td style="text-align:right;"> 0.5509361 </td>
   <td style="text-align:right;"> 8.794718e-01 </td>
   <td style="text-align:right;"> 39 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon white oak </td>
   <td style="text-align:left;"> Quercus garryana </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 815 </td>
   <td style="text-align:right;"> 3.3820555 </td>
   <td style="text-align:right;"> 3.0393956 </td>
   <td style="text-align:right;"> 0.1481661 </td>
   <td style="text-align:right;"> 5.951892e-01 </td>
   <td style="text-align:right;"> 28 </td>
   <td style="text-align:right;"> 17326 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Oregon white oak </td>
   <td style="text-align:left;"> Quercus garryana </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 815 </td>
   <td style="text-align:right;"> 4.6319552 </td>
   <td style="text-align:right;"> 47.9113595 </td>
   <td style="text-align:right;"> 0.2310496 </td>
   <td style="text-align:right;"> 5.774532e+01 </td>
   <td style="text-align:right;"> 71 </td>
   <td style="text-align:right;"> 17326 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific dogwood </td>
   <td style="text-align:left;"> Cornus nuttallii </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 492 </td>
   <td style="text-align:right;"> 1.1375257 </td>
   <td style="text-align:right;"> 0.1140434 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 9.444400e-03 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 6606 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific dogwood </td>
   <td style="text-align:left;"> Cornus nuttallii </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 492 </td>
   <td style="text-align:right;"> 1.9247708 </td>
   <td style="text-align:right;"> 0.0108962 </td>
   <td style="text-align:right;"> 0.3116047 </td>
   <td style="text-align:right;"> 5.010000e-05 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific dogwood </td>
   <td style="text-align:left;"> Cornus nuttallii </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 492 </td>
   <td style="text-align:right;"> 3.8938591 </td>
   <td style="text-align:right;"> 0.4307239 </td>
   <td style="text-align:right;"> 0.3713392 </td>
   <td style="text-align:right;"> 2.791160e-02 </td>
   <td style="text-align:right;"> 36 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific dogwood </td>
   <td style="text-align:left;"> Cornus nuttallii </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 492 </td>
   <td style="text-align:right;"> 2.8704639 </td>
   <td style="text-align:right;"> 0.1487877 </td>
   <td style="text-align:right;"> 0.2758383 </td>
   <td style="text-align:right;"> 5.078200e-03 </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific dogwood </td>
   <td style="text-align:left;"> Cornus nuttallii </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 492 </td>
   <td style="text-align:right;"> 5.2627114 </td>
   <td style="text-align:right;"> 0.0687307 </td>
   <td style="text-align:right;"> 3.1055430 </td>
   <td style="text-align:right;"> 4.576800e-03 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific dogwood </td>
   <td style="text-align:left;"> Cornus nuttallii </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 492 </td>
   <td style="text-align:right;"> 2.1700789 </td>
   <td style="text-align:right;"> 0.0032086 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 1.080000e-05 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific madrone </td>
   <td style="text-align:left;"> Arbutus menziesii </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 361 </td>
   <td style="text-align:right;"> 9.7221737 </td>
   <td style="text-align:right;"> 1.7226602 </td>
   <td style="text-align:right;"> 10.3245068 </td>
   <td style="text-align:right;"> 6.809191e-01 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 17326 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific madrone </td>
   <td style="text-align:left;"> Arbutus menziesii </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 361 </td>
   <td style="text-align:right;"> 6.4126753 </td>
   <td style="text-align:right;"> 8.2302525 </td>
   <td style="text-align:right;"> 0.5858031 </td>
   <td style="text-align:right;"> 2.282415e+00 </td>
   <td style="text-align:right;"> 98 </td>
   <td style="text-align:right;"> 17615 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific madrone </td>
   <td style="text-align:left;"> Arbutus menziesii </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 361 </td>
   <td style="text-align:right;"> 6.8349339 </td>
   <td style="text-align:right;"> 19.0014588 </td>
   <td style="text-align:right;"> 0.2564338 </td>
   <td style="text-align:right;"> 9.861929e+00 </td>
   <td style="text-align:right;"> 138 </td>
   <td style="text-align:right;"> 17615 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific madrone </td>
   <td style="text-align:left;"> Arbutus menziesii </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 361 </td>
   <td style="text-align:right;"> 6.3089307 </td>
   <td style="text-align:right;"> 10.3184479 </td>
   <td style="text-align:right;"> 0.3721740 </td>
   <td style="text-align:right;"> 3.259076e+00 </td>
   <td style="text-align:right;"> 113 </td>
   <td style="text-align:right;"> 17615 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific madrone </td>
   <td style="text-align:left;"> Arbutus menziesii </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 361 </td>
   <td style="text-align:right;"> 6.5861950 </td>
   <td style="text-align:right;"> 9.1315164 </td>
   <td style="text-align:right;"> 0.5230792 </td>
   <td style="text-align:right;"> 3.568343e+00 </td>
   <td style="text-align:right;"> 46 </td>
   <td style="text-align:right;"> 17615 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific madrone </td>
   <td style="text-align:left;"> Arbutus menziesii </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 361 </td>
   <td style="text-align:right;"> 6.2322310 </td>
   <td style="text-align:right;"> 11.2545902 </td>
   <td style="text-align:right;"> 0.2028938 </td>
   <td style="text-align:right;"> 4.057634e+01 </td>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific silver fir </td>
   <td style="text-align:left;"> Abies amabilis </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 20.7492892 </td>
   <td style="text-align:right;"> 23.5793422 </td>
   <td style="text-align:right;"> 8.0865865 </td>
   <td style="text-align:right;"> 4.101643e+01 </td>
   <td style="text-align:right;"> 20 </td>
   <td style="text-align:right;"> 7186 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific silver fir </td>
   <td style="text-align:left;"> Abies amabilis </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 16.2288503 </td>
   <td style="text-align:right;"> 93.4381185 </td>
   <td style="text-align:right;"> 0.6637845 </td>
   <td style="text-align:right;"> 1.294329e+02 </td>
   <td style="text-align:right;"> 203 </td>
   <td style="text-align:right;"> 20188 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific silver fir </td>
   <td style="text-align:left;"> Abies amabilis </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 14.0070977 </td>
   <td style="text-align:right;"> 103.3354358 </td>
   <td style="text-align:right;"> 1.0192784 </td>
   <td style="text-align:right;"> 1.444077e+02 </td>
   <td style="text-align:right;"> 338 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific silver fir </td>
   <td style="text-align:left;"> Abies amabilis </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 10.9633402 </td>
   <td style="text-align:right;"> 90.0854174 </td>
   <td style="text-align:right;"> 0.2824829 </td>
   <td style="text-align:right;"> 7.951745e+01 </td>
   <td style="text-align:right;"> 296 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific silver fir </td>
   <td style="text-align:left;"> Abies amabilis </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 8.5852902 </td>
   <td style="text-align:right;"> 68.7909559 </td>
   <td style="text-align:right;"> 0.1747795 </td>
   <td style="text-align:right;"> 4.873354e+01 </td>
   <td style="text-align:right;"> 260 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific silver fir </td>
   <td style="text-align:left;"> Abies amabilis </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 6.2618535 </td>
   <td style="text-align:right;"> 35.7574625 </td>
   <td style="text-align:right;"> 0.1383478 </td>
   <td style="text-align:right;"> 2.197425e+01 </td>
   <td style="text-align:right;"> 147 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific silver fir </td>
   <td style="text-align:left;"> Abies amabilis </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 8.3971432 </td>
   <td style="text-align:right;"> 34.2701590 </td>
   <td style="text-align:right;"> 1.4667547 </td>
   <td style="text-align:right;"> 6.530714e+01 </td>
   <td style="text-align:right;"> 55 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific yew </td>
   <td style="text-align:left;"> Taxus brevifolia </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 231 </td>
   <td style="text-align:right;"> 1.2915703 </td>
   <td style="text-align:right;"> 0.0810677 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 4.366400e-03 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 7186 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific yew </td>
   <td style="text-align:left;"> Taxus brevifolia </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 231 </td>
   <td style="text-align:right;"> 0.9827344 </td>
   <td style="text-align:right;"> 0.0748056 </td>
   <td style="text-align:right;"> 2.3372903 </td>
   <td style="text-align:right;"> 1.470990e-02 </td>
   <td style="text-align:right;"> 24 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific yew </td>
   <td style="text-align:left;"> Taxus brevifolia </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 231 </td>
   <td style="text-align:right;"> 2.6711549 </td>
   <td style="text-align:right;"> 0.7812381 </td>
   <td style="text-align:right;"> 0.3341251 </td>
   <td style="text-align:right;"> 4.054450e-02 </td>
   <td style="text-align:right;"> 98 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific yew </td>
   <td style="text-align:left;"> Taxus brevifolia </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 231 </td>
   <td style="text-align:right;"> 4.6181142 </td>
   <td style="text-align:right;"> 1.3667816 </td>
   <td style="text-align:right;"> 1.8037950 </td>
   <td style="text-align:right;"> 2.170626e-01 </td>
   <td style="text-align:right;"> 75 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific yew </td>
   <td style="text-align:left;"> Taxus brevifolia </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 231 </td>
   <td style="text-align:right;"> 2.6098391 </td>
   <td style="text-align:right;"> 0.2423403 </td>
   <td style="text-align:right;"> 0.2440688 </td>
   <td style="text-align:right;"> 5.670900e-03 </td>
   <td style="text-align:right;"> 42 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific yew </td>
   <td style="text-align:left;"> Taxus brevifolia </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 231 </td>
   <td style="text-align:right;"> 1.2113130 </td>
   <td style="text-align:right;"> 0.0476022 </td>
   <td style="text-align:right;"> 0.1067966 </td>
   <td style="text-align:right;"> 4.341000e-04 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 20188 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pacific yew </td>
   <td style="text-align:left;"> Taxus brevifolia </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 231 </td>
   <td style="text-align:right;"> 3.0848660 </td>
   <td style="text-align:right;"> 0.0104205 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 1.117000e-04 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 8776 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> paper birch </td>
   <td style="text-align:left;"> Betula papyrifera </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 375 </td>
   <td style="text-align:right;"> 15.9420177 </td>
   <td style="text-align:right;"> 1.7998220 </td>
   <td style="text-align:right;"> 2.1334288 </td>
   <td style="text-align:right;"> 1.477876e+00 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 4565 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> paper birch </td>
   <td style="text-align:left;"> Betula papyrifera </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 375 </td>
   <td style="text-align:right;"> 4.7068166 </td>
   <td style="text-align:right;"> 0.8575281 </td>
   <td style="text-align:right;"> 0.4903327 </td>
   <td style="text-align:right;"> 1.759516e-01 </td>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:right;"> 7186 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> paper birch </td>
   <td style="text-align:left;"> Betula papyrifera </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 375 </td>
   <td style="text-align:right;"> 3.0426768 </td>
   <td style="text-align:right;"> 1.6418617 </td>
   <td style="text-align:right;"> 0.1258212 </td>
   <td style="text-align:right;"> 3.526658e-01 </td>
   <td style="text-align:right;"> 34 </td>
   <td style="text-align:right;"> 13341 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> paper birch </td>
   <td style="text-align:left;"> Betula papyrifera </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 375 </td>
   <td style="text-align:right;"> 2.3891806 </td>
   <td style="text-align:right;"> 0.3121753 </td>
   <td style="text-align:right;"> 1.0113764 </td>
   <td style="text-align:right;"> 2.140280e-02 </td>
   <td style="text-align:right;"> 23 </td>
   <td style="text-align:right;"> 7186 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> paper birch </td>
   <td style="text-align:left;"> Betula papyrifera </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 375 </td>
   <td style="text-align:right;"> 5.8760241 </td>
   <td style="text-align:right;"> 0.6387813 </td>
   <td style="text-align:right;"> 1.7034408 </td>
   <td style="text-align:right;"> 1.554502e-01 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 7186 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> paper birch </td>
   <td style="text-align:left;"> Betula papyrifera </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 375 </td>
   <td style="text-align:right;"> 5.0871973 </td>
   <td style="text-align:right;"> 0.0934410 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 9.470900e-03 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 2621 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> ponderosa pine </td>
   <td style="text-align:left;"> Pinus ponderosa </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 122 </td>
   <td style="text-align:right;"> 21.9886289 </td>
   <td style="text-align:right;"> 0.6858470 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 5.045678e-01 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 2621 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> ponderosa pine </td>
   <td style="text-align:left;"> Pinus ponderosa </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 122 </td>
   <td style="text-align:right;"> 27.8368506 </td>
   <td style="text-align:right;"> 3.2815039 </td>
   <td style="text-align:right;"> 6.3749833 </td>
   <td style="text-align:right;"> 2.582218e+00 </td>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> ponderosa pine </td>
   <td style="text-align:left;"> Pinus ponderosa </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 122 </td>
   <td style="text-align:right;"> 23.6998719 </td>
   <td style="text-align:right;"> 36.4432519 </td>
   <td style="text-align:right;"> 1.2614141 </td>
   <td style="text-align:right;"> 2.822601e+01 </td>
   <td style="text-align:right;"> 156 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> ponderosa pine </td>
   <td style="text-align:left;"> Pinus ponderosa </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 122 </td>
   <td style="text-align:right;"> 22.4168368 </td>
   <td style="text-align:right;"> 189.3186002 </td>
   <td style="text-align:right;"> 0.5700391 </td>
   <td style="text-align:right;"> 1.895066e+02 </td>
   <td style="text-align:right;"> 604 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> ponderosa pine </td>
   <td style="text-align:left;"> Pinus ponderosa </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 122 </td>
   <td style="text-align:right;"> 15.9521153 </td>
   <td style="text-align:right;"> 318.5124892 </td>
   <td style="text-align:right;"> 0.0914038 </td>
   <td style="text-align:right;"> 1.171052e+02 </td>
   <td style="text-align:right;"> 1708 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> ponderosa pine </td>
   <td style="text-align:left;"> Pinus ponderosa </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 122 </td>
   <td style="text-align:right;"> 12.6722817 </td>
   <td style="text-align:right;"> 280.9209134 </td>
   <td style="text-align:right;"> 0.0586813 </td>
   <td style="text-align:right;"> 1.211018e+02 </td>
   <td style="text-align:right;"> 1364 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> ponderosa pine </td>
   <td style="text-align:left;"> Pinus ponderosa </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 122 </td>
   <td style="text-align:right;"> 17.2618144 </td>
   <td style="text-align:right;"> 24.0131924 </td>
   <td style="text-align:right;"> 2.7660827 </td>
   <td style="text-align:right;"> 1.378240e+01 </td>
   <td style="text-align:right;"> 99 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Port-Orford-cedar </td>
   <td style="text-align:left;"> Chamaecyparis lawsoniana </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 41 </td>
   <td style="text-align:right;"> 22.8881582 </td>
   <td style="text-align:right;"> 2.4063127 </td>
   <td style="text-align:right;"> 14.2422362 </td>
   <td style="text-align:right;"> 1.424597e+00 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Port-Orford-cedar </td>
   <td style="text-align:left;"> Chamaecyparis lawsoniana </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 41 </td>
   <td style="text-align:right;"> 16.0250069 </td>
   <td style="text-align:right;"> 2.6712088 </td>
   <td style="text-align:right;"> 19.4214343 </td>
   <td style="text-align:right;"> 1.122229e+00 </td>
   <td style="text-align:right;"> 22 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Port-Orford-cedar </td>
   <td style="text-align:left;"> Chamaecyparis lawsoniana </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 41 </td>
   <td style="text-align:right;"> 12.0677140 </td>
   <td style="text-align:right;"> 1.1343406 </td>
   <td style="text-align:right;"> 5.9998005 </td>
   <td style="text-align:right;"> 2.225079e-01 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Port-Orford-cedar </td>
   <td style="text-align:left;"> Chamaecyparis lawsoniana </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 41 </td>
   <td style="text-align:right;"> 11.5747842 </td>
   <td style="text-align:right;"> 0.4722832 </td>
   <td style="text-align:right;"> 3.9334318 </td>
   <td style="text-align:right;"> 2.788910e-02 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Port-Orford-cedar </td>
   <td style="text-align:left;"> Chamaecyparis lawsoniana </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 41 </td>
   <td style="text-align:right;"> 9.2655034 </td>
   <td style="text-align:right;"> 0.6844928 </td>
   <td style="text-align:right;"> 3.1024300 </td>
   <td style="text-align:right;"> 7.732620e-02 </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 6444 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Port-Orford-cedar </td>
   <td style="text-align:left;"> Chamaecyparis lawsoniana </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 41 </td>
   <td style="text-align:right;"> 15.2771433 </td>
   <td style="text-align:right;"> 1.1682510 </td>
   <td style="text-align:right;"> 0.6737779 </td>
   <td style="text-align:right;"> 4.012142e-01 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> quaking aspen </td>
   <td style="text-align:left;"> Populus tremuloides </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 746 </td>
   <td style="text-align:right;"> 10.8257674 </td>
   <td style="text-align:right;"> 0.0440926 </td>
   <td style="text-align:right;"> 17.9169845 </td>
   <td style="text-align:right;"> 1.337100e-03 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 2621 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> quaking aspen </td>
   <td style="text-align:left;"> Populus tremuloides </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 746 </td>
   <td style="text-align:right;"> 17.1551391 </td>
   <td style="text-align:right;"> 0.6140459 </td>
   <td style="text-align:right;"> 5.5260424 </td>
   <td style="text-align:right;"> 2.502060e-01 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 7186 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> quaking aspen </td>
   <td style="text-align:left;"> Populus tremuloides </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 746 </td>
   <td style="text-align:right;"> 12.9918763 </td>
   <td style="text-align:right;"> 5.7924217 </td>
   <td style="text-align:right;"> 2.5629308 </td>
   <td style="text-align:right;"> 1.004732e+01 </td>
   <td style="text-align:right;"> 32 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> quaking aspen </td>
   <td style="text-align:left;"> Populus tremuloides </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 746 </td>
   <td style="text-align:right;"> 12.4751492 </td>
   <td style="text-align:right;"> 2.9472574 </td>
   <td style="text-align:right;"> 7.0166606 </td>
   <td style="text-align:right;"> 1.099190e+00 </td>
   <td style="text-align:right;"> 28 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> quaking aspen </td>
   <td style="text-align:left;"> Populus tremuloides </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 746 </td>
   <td style="text-align:right;"> 12.4261857 </td>
   <td style="text-align:right;"> 0.3721800 </td>
   <td style="text-align:right;"> 6.2479440 </td>
   <td style="text-align:right;"> 3.641770e-02 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> quaking aspen </td>
   <td style="text-align:left;"> Populus tremuloides </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 746 </td>
   <td style="text-align:right;"> 8.4624927 </td>
   <td style="text-align:right;"> 3.7110930 </td>
   <td style="text-align:right;"> 3.1180357 </td>
   <td style="text-align:right;"> 1.785352e+00 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 15382 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> red alder </td>
   <td style="text-align:left;"> Alnus rubra </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 351 </td>
   <td style="text-align:right;"> 15.1316264 </td>
   <td style="text-align:right;"> 253.6103495 </td>
   <td style="text-align:right;"> 2.7198053 </td>
   <td style="text-align:right;"> 2.042789e+03 </td>
   <td style="text-align:right;"> 78 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> red alder </td>
   <td style="text-align:left;"> Alnus rubra </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 351 </td>
   <td style="text-align:right;"> 16.0942813 </td>
   <td style="text-align:right;"> 221.2503201 </td>
   <td style="text-align:right;"> 0.2033357 </td>
   <td style="text-align:right;"> 2.245166e+02 </td>
   <td style="text-align:right;"> 491 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> red alder </td>
   <td style="text-align:left;"> Alnus rubra </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 351 </td>
   <td style="text-align:right;"> 14.9755527 </td>
   <td style="text-align:right;"> 132.1277362 </td>
   <td style="text-align:right;"> 0.2816338 </td>
   <td style="text-align:right;"> 1.171461e+02 </td>
   <td style="text-align:right;"> 432 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> red alder </td>
   <td style="text-align:left;"> Alnus rubra </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 351 </td>
   <td style="text-align:right;"> 13.8108442 </td>
   <td style="text-align:right;"> 57.7988787 </td>
   <td style="text-align:right;"> 0.7436402 </td>
   <td style="text-align:right;"> 7.637899e+01 </td>
   <td style="text-align:right;"> 137 </td>
   <td style="text-align:right;"> 20188 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> red alder </td>
   <td style="text-align:left;"> Alnus rubra </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 351 </td>
   <td style="text-align:right;"> 13.9188662 </td>
   <td style="text-align:right;"> 11.1070199 </td>
   <td style="text-align:right;"> 0.5790521 </td>
   <td style="text-align:right;"> 6.805989e+00 </td>
   <td style="text-align:right;"> 47 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> red alder </td>
   <td style="text-align:left;"> Alnus rubra </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 351 </td>
   <td style="text-align:right;"> 14.1119627 </td>
   <td style="text-align:right;"> 3.0015137 </td>
   <td style="text-align:right;"> 1.5517214 </td>
   <td style="text-align:right;"> 1.762441e+00 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> red alder </td>
   <td style="text-align:left;"> Alnus rubra </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 351 </td>
   <td style="text-align:right;"> 15.3464275 </td>
   <td style="text-align:right;"> 12.7245695 </td>
   <td style="text-align:right;"> 4.2762876 </td>
   <td style="text-align:right;"> 2.529326e+01 </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> redwood </td>
   <td style="text-align:left;"> Sequoia sempervirens </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 211 </td>
   <td style="text-align:right;"> 61.3711177 </td>
   <td style="text-align:right;"> 2.5816762 </td>
   <td style="text-align:right;"> 0.4350367 </td>
   <td style="text-align:right;"> 6.674979e+00 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> redwood </td>
   <td style="text-align:left;"> Sequoia sempervirens </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 211 </td>
   <td style="text-align:right;"> 12.5604649 </td>
   <td style="text-align:right;"> 0.2911342 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 8.711330e-02 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 6155 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> redwood </td>
   <td style="text-align:left;"> Sequoia sempervirens </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 211 </td>
   <td style="text-align:right;"> 43.5920035 </td>
   <td style="text-align:right;"> 0.2519892 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 6.667230e-02 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Rocky Mountain juniper </td>
   <td style="text-align:left;"> Juniperus scopulorum </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 66 </td>
   <td style="text-align:right;"> 2.4883140 </td>
   <td style="text-align:right;"> 0.0107888 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 1.460000e-04 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 6606 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Shasta red fir </td>
   <td style="text-align:left;"> Abies shastensis </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 21 </td>
   <td style="text-align:right;"> 37.8300684 </td>
   <td style="text-align:right;"> 1.3055649 </td>
   <td style="text-align:right;"> 72.9654835 </td>
   <td style="text-align:right;"> 8.669177e-01 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 6155 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Shasta red fir </td>
   <td style="text-align:left;"> Abies shastensis </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 21 </td>
   <td style="text-align:right;"> 25.4507093 </td>
   <td style="text-align:right;"> 10.9568849 </td>
   <td style="text-align:right;"> 7.7036831 </td>
   <td style="text-align:right;"> 9.916793e+00 </td>
   <td style="text-align:right;"> 35 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Shasta red fir </td>
   <td style="text-align:left;"> Abies shastensis </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 21 </td>
   <td style="text-align:right;"> 14.3603661 </td>
   <td style="text-align:right;"> 12.0047124 </td>
   <td style="text-align:right;"> 1.1284241 </td>
   <td style="text-align:right;"> 8.912858e+00 </td>
   <td style="text-align:right;"> 45 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Shasta red fir </td>
   <td style="text-align:left;"> Abies shastensis </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 21 </td>
   <td style="text-align:right;"> 14.7714987 </td>
   <td style="text-align:right;"> 11.7624779 </td>
   <td style="text-align:right;"> 1.1383310 </td>
   <td style="text-align:right;"> 6.430450e+00 </td>
   <td style="text-align:right;"> 62 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Shasta red fir </td>
   <td style="text-align:left;"> Abies shastensis </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 21 </td>
   <td style="text-align:right;"> 14.8418822 </td>
   <td style="text-align:right;"> 10.4975227 </td>
   <td style="text-align:right;"> 1.5397121 </td>
   <td style="text-align:right;"> 6.128024e+00 </td>
   <td style="text-align:right;"> 41 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Shasta red fir </td>
   <td style="text-align:left;"> Abies shastensis </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 21 </td>
   <td style="text-align:right;"> 21.3308683 </td>
   <td style="text-align:right;"> 8.1876715 </td>
   <td style="text-align:right;"> 4.0946647 </td>
   <td style="text-align:right;"> 2.348563e+01 </td>
   <td style="text-align:right;"> 12 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Sitka spruce </td>
   <td style="text-align:left;"> Picea sitchensis </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 98 </td>
   <td style="text-align:right;"> 32.6143741 </td>
   <td style="text-align:right;"> 297.4585511 </td>
   <td style="text-align:right;"> 19.1783363 </td>
   <td style="text-align:right;"> 3.025005e+03 </td>
   <td style="text-align:right;"> 60 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Sitka spruce </td>
   <td style="text-align:left;"> Picea sitchensis </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 98 </td>
   <td style="text-align:right;"> 39.9091826 </td>
   <td style="text-align:right;"> 66.6976365 </td>
   <td style="text-align:right;"> 12.1163351 </td>
   <td style="text-align:right;"> 1.551220e+02 </td>
   <td style="text-align:right;"> 87 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Sitka spruce </td>
   <td style="text-align:left;"> Picea sitchensis </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 98 </td>
   <td style="text-align:right;"> 30.5173488 </td>
   <td style="text-align:right;"> 16.3171853 </td>
   <td style="text-align:right;"> 12.6203423 </td>
   <td style="text-align:right;"> 7.572467e+00 </td>
   <td style="text-align:right;"> 75 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Sitka spruce </td>
   <td style="text-align:left;"> Picea sitchensis </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 98 </td>
   <td style="text-align:right;"> 28.5914903 </td>
   <td style="text-align:right;"> 8.2953660 </td>
   <td style="text-align:right;"> 15.9488200 </td>
   <td style="text-align:right;"> 1.366086e+01 </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Sitka spruce </td>
   <td style="text-align:left;"> Picea sitchensis </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 98 </td>
   <td style="text-align:right;"> 69.7219592 </td>
   <td style="text-align:right;"> 1.1036536 </td>
   <td style="text-align:right;"> 648.5337143 </td>
   <td style="text-align:right;"> 3.656530e-01 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 13792 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Sitka spruce </td>
   <td style="text-align:left;"> Picea sitchensis </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 98 </td>
   <td style="text-align:right;"> 45.2417408 </td>
   <td style="text-align:right;"> 1.5800161 </td>
   <td style="text-align:right;"> 735.6994231 </td>
   <td style="text-align:right;"> 1.398051e+00 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 17326 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Sitka spruce </td>
   <td style="text-align:left;"> Picea sitchensis </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 98 </td>
   <td style="text-align:right;"> 29.3785913 </td>
   <td style="text-align:right;"> 3.0426425 </td>
   <td style="text-align:right;"> 54.5411768 </td>
   <td style="text-align:right;"> 4.446932e+00 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 17326 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> subalpine fir </td>
   <td style="text-align:left;"> Abies lasiocarpa </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 19 </td>
   <td style="text-align:right;"> 7.9451884 </td>
   <td style="text-align:right;"> 0.8349858 </td>
   <td style="text-align:right;"> 1.2770907 </td>
   <td style="text-align:right;"> 4.600655e-01 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 7427 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> subalpine fir </td>
   <td style="text-align:left;"> Abies lasiocarpa </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 19 </td>
   <td style="text-align:right;"> 9.5509297 </td>
   <td style="text-align:right;"> 5.0025484 </td>
   <td style="text-align:right;"> 1.4452978 </td>
   <td style="text-align:right;"> 1.240924e+00 </td>
   <td style="text-align:right;"> 65 </td>
   <td style="text-align:right;"> 13871 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> subalpine fir </td>
   <td style="text-align:left;"> Abies lasiocarpa </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 19 </td>
   <td style="text-align:right;"> 9.8750644 </td>
   <td style="text-align:right;"> 38.8873427 </td>
   <td style="text-align:right;"> 0.4258555 </td>
   <td style="text-align:right;"> 3.801449e+01 </td>
   <td style="text-align:right;"> 173 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> subalpine fir </td>
   <td style="text-align:left;"> Abies lasiocarpa </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 19 </td>
   <td style="text-align:right;"> 7.0228273 </td>
   <td style="text-align:right;"> 37.0283955 </td>
   <td style="text-align:right;"> 0.2505330 </td>
   <td style="text-align:right;"> 1.926763e+01 </td>
   <td style="text-align:right;"> 272 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> subalpine fir </td>
   <td style="text-align:left;"> Abies lasiocarpa </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 19 </td>
   <td style="text-align:right;"> 6.1202122 </td>
   <td style="text-align:right;"> 29.4457750 </td>
   <td style="text-align:right;"> 0.1162825 </td>
   <td style="text-align:right;"> 1.683378e+01 </td>
   <td style="text-align:right;"> 200 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> subalpine fir </td>
   <td style="text-align:left;"> Abies lasiocarpa </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 19 </td>
   <td style="text-align:right;"> 7.1652912 </td>
   <td style="text-align:right;"> 70.6552750 </td>
   <td style="text-align:right;"> 0.3325737 </td>
   <td style="text-align:right;"> 1.567267e+02 </td>
   <td style="text-align:right;"> 94 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> subalpine larch </td>
   <td style="text-align:left;"> Larix lyallii </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 72 </td>
   <td style="text-align:right;"> 8.9619618 </td>
   <td style="text-align:right;"> 0.8605142 </td>
   <td style="text-align:right;"> 1.7709329 </td>
   <td style="text-align:right;"> 2.182132e-01 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 2862 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> subalpine larch </td>
   <td style="text-align:left;"> Larix lyallii </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 72 </td>
   <td style="text-align:right;"> 4.2547219 </td>
   <td style="text-align:right;"> 1.9111216 </td>
   <td style="text-align:right;"> 0.4664565 </td>
   <td style="text-align:right;"> 9.098974e-01 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 7427 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> subalpine larch </td>
   <td style="text-align:left;"> Larix lyallii </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 72 </td>
   <td style="text-align:right;"> 3.6238715 </td>
   <td style="text-align:right;"> 2.6478634 </td>
   <td style="text-align:right;"> 0.0849933 </td>
   <td style="text-align:right;"> 1.799894e+00 </td>
   <td style="text-align:right;"> 12 </td>
   <td style="text-align:right;"> 2862 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> sugar pine </td>
   <td style="text-align:left;"> Pinus lambertiana </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 117 </td>
   <td style="text-align:right;"> 54.7229290 </td>
   <td style="text-align:right;"> 0.0842926 </td>
   <td style="text-align:right;"> 427.7352472 </td>
   <td style="text-align:right;"> 4.027900e-03 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 6155 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> sugar pine </td>
   <td style="text-align:left;"> Pinus lambertiana </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 117 </td>
   <td style="text-align:right;"> 41.9808070 </td>
   <td style="text-align:right;"> 2.1806701 </td>
   <td style="text-align:right;"> 19.3185767 </td>
   <td style="text-align:right;"> 2.606681e-01 </td>
   <td style="text-align:right;"> 41 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> sugar pine </td>
   <td style="text-align:left;"> Pinus lambertiana </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 117 </td>
   <td style="text-align:right;"> 27.1231096 </td>
   <td style="text-align:right;"> 8.6486992 </td>
   <td style="text-align:right;"> 7.4343851 </td>
   <td style="text-align:right;"> 2.246010e+00 </td>
   <td style="text-align:right;"> 94 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> sugar pine </td>
   <td style="text-align:left;"> Pinus lambertiana </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 117 </td>
   <td style="text-align:right;"> 23.5706804 </td>
   <td style="text-align:right;"> 5.1392036 </td>
   <td style="text-align:right;"> 4.6536167 </td>
   <td style="text-align:right;"> 5.791434e-01 </td>
   <td style="text-align:right;"> 101 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> sugar pine </td>
   <td style="text-align:left;"> Pinus lambertiana </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 117 </td>
   <td style="text-align:right;"> 20.4147396 </td>
   <td style="text-align:right;"> 4.3987020 </td>
   <td style="text-align:right;"> 2.5622247 </td>
   <td style="text-align:right;"> 3.450639e+00 </td>
   <td style="text-align:right;"> 41 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> sugar pine </td>
   <td style="text-align:left;"> Pinus lambertiana </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 117 </td>
   <td style="text-align:right;"> 11.9044436 </td>
   <td style="text-align:right;"> 0.2377299 </td>
   <td style="text-align:right;"> 0.2894228 </td>
   <td style="text-align:right;"> 3.016380e-02 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 6444 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> sweet cherry </td>
   <td style="text-align:left;"> Prunus avium </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 771 </td>
   <td style="text-align:right;"> 11.5052503 </td>
   <td style="text-align:right;"> 0.1828457 </td>
   <td style="text-align:right;"> 4.9084159 </td>
   <td style="text-align:right;"> 1.506730e-02 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 6606 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> sweet cherry </td>
   <td style="text-align:left;"> Prunus avium </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 771 </td>
   <td style="text-align:right;"> 7.2008865 </td>
   <td style="text-align:right;"> 0.5052301 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 1.631170e-01 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 6606 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> sweet cherry </td>
   <td style="text-align:left;"> Prunus avium </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 771 </td>
   <td style="text-align:right;"> 24.1236519 </td>
   <td style="text-align:right;"> 0.1578445 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 1.609300e-02 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 4565 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> tanoak </td>
   <td style="text-align:left;"> Lithocarpus densiflorus </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 631 </td>
   <td style="text-align:right;"> 8.4288145 </td>
   <td style="text-align:right;"> 7.6716964 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 5.617817e+01 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 6606 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> tanoak </td>
   <td style="text-align:left;"> Lithocarpus densiflorus </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 631 </td>
   <td style="text-align:right;"> 9.5810464 </td>
   <td style="text-align:right;"> 3.6475797 </td>
   <td style="text-align:right;"> 2.8613926 </td>
   <td style="text-align:right;"> 2.991815e+00 </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> tanoak </td>
   <td style="text-align:left;"> Lithocarpus densiflorus </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 631 </td>
   <td style="text-align:right;"> 6.5369439 </td>
   <td style="text-align:right;"> 12.3282628 </td>
   <td style="text-align:right;"> 0.3148735 </td>
   <td style="text-align:right;"> 4.863780e+00 </td>
   <td style="text-align:right;"> 78 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> tanoak </td>
   <td style="text-align:left;"> Lithocarpus densiflorus </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 631 </td>
   <td style="text-align:right;"> 6.3994406 </td>
   <td style="text-align:right;"> 15.0743605 </td>
   <td style="text-align:right;"> 0.2851970 </td>
   <td style="text-align:right;"> 8.773504e+00 </td>
   <td style="text-align:right;"> 76 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> tanoak </td>
   <td style="text-align:left;"> Lithocarpus densiflorus </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 631 </td>
   <td style="text-align:right;"> 5.3525858 </td>
   <td style="text-align:right;"> 4.4473303 </td>
   <td style="text-align:right;"> 0.1373561 </td>
   <td style="text-align:right;"> 1.005829e+00 </td>
   <td style="text-align:right;"> 48 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> tanoak </td>
   <td style="text-align:left;"> Lithocarpus densiflorus </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 631 </td>
   <td style="text-align:right;"> 6.0193178 </td>
   <td style="text-align:right;"> 2.1264747 </td>
   <td style="text-align:right;"> 0.8065294 </td>
   <td style="text-align:right;"> 7.806804e-01 </td>
   <td style="text-align:right;"> 20 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> tanoak </td>
   <td style="text-align:left;"> Lithocarpus densiflorus </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 631 </td>
   <td style="text-align:right;"> 4.4772048 </td>
   <td style="text-align:right;"> 1.8707954 </td>
   <td style="text-align:right;"> 0.9506075 </td>
   <td style="text-align:right;"> 7.198945e-01 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> water birch </td>
   <td style="text-align:left;"> Betula occidentalis </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 374 </td>
   <td style="text-align:right;"> 6.4520467 </td>
   <td style="text-align:right;"> 0.0570938 </td>
   <td style="text-align:right;"> 13.5257292 </td>
   <td style="text-align:right;"> 2.845300e-03 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 10720 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> water birch </td>
   <td style="text-align:left;"> Betula occidentalis </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 374 </td>
   <td style="text-align:right;"> 5.8334210 </td>
   <td style="text-align:right;"> 0.0290019 </td>
   <td style="text-align:right;"> 1.1376056 </td>
   <td style="text-align:right;"> 3.345000e-04 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> water birch </td>
   <td style="text-align:left;"> Betula occidentalis </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 374 </td>
   <td style="text-align:right;"> 5.0486752 </td>
   <td style="text-align:right;"> 0.3850271 </td>
   <td style="text-align:right;"> 2.6428890 </td>
   <td style="text-align:right;"> 6.194240e-02 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 7186 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> water birch </td>
   <td style="text-align:left;"> Betula occidentalis </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 374 </td>
   <td style="text-align:right;"> 1.7217220 </td>
   <td style="text-align:right;"> 0.0063249 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 4.340000e-05 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 7186 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western hemlock </td>
   <td style="text-align:left;"> Tsuga heterophylla </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 263 </td>
   <td style="text-align:right;"> 23.7998280 </td>
   <td style="text-align:right;"> 1737.7775242 </td>
   <td style="text-align:right;"> 1.1218563 </td>
   <td style="text-align:right;"> 2.384656e+04 </td>
   <td style="text-align:right;"> 151 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western hemlock </td>
   <td style="text-align:left;"> Tsuga heterophylla </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 263 </td>
   <td style="text-align:right;"> 19.6010724 </td>
   <td style="text-align:right;"> 499.8583237 </td>
   <td style="text-align:right;"> 0.3021835 </td>
   <td style="text-align:right;"> 8.805463e+02 </td>
   <td style="text-align:right;"> 693 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western hemlock </td>
   <td style="text-align:left;"> Tsuga heterophylla </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 263 </td>
   <td style="text-align:right;"> 17.5206085 </td>
   <td style="text-align:right;"> 336.4355812 </td>
   <td style="text-align:right;"> 0.1923139 </td>
   <td style="text-align:right;"> 2.676496e+02 </td>
   <td style="text-align:right;"> 1032 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western hemlock </td>
   <td style="text-align:left;"> Tsuga heterophylla </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 263 </td>
   <td style="text-align:right;"> 13.3989352 </td>
   <td style="text-align:right;"> 176.0558709 </td>
   <td style="text-align:right;"> 0.2866469 </td>
   <td style="text-align:right;"> 1.268397e+02 </td>
   <td style="text-align:right;"> 602 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western hemlock </td>
   <td style="text-align:left;"> Tsuga heterophylla </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 263 </td>
   <td style="text-align:right;"> 10.8608235 </td>
   <td style="text-align:right;"> 62.3116667 </td>
   <td style="text-align:right;"> 0.2859332 </td>
   <td style="text-align:right;"> 2.690874e+01 </td>
   <td style="text-align:right;"> 359 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western hemlock </td>
   <td style="text-align:left;"> Tsuga heterophylla </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 263 </td>
   <td style="text-align:right;"> 6.6058141 </td>
   <td style="text-align:right;"> 22.8538533 </td>
   <td style="text-align:right;"> 0.2513985 </td>
   <td style="text-align:right;"> 9.387380e+00 </td>
   <td style="text-align:right;"> 122 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western hemlock </td>
   <td style="text-align:left;"> Tsuga heterophylla </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 263 </td>
   <td style="text-align:right;"> 7.5562856 </td>
   <td style="text-align:right;"> 10.4582382 </td>
   <td style="text-align:right;"> 1.4649343 </td>
   <td style="text-align:right;"> 1.485068e+01 </td>
   <td style="text-align:right;"> 20 </td>
   <td style="text-align:right;"> 13341 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western juniper </td>
   <td style="text-align:left;"> Juniperus occidentalis </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 64 </td>
   <td style="text-align:right;"> 3.6248035 </td>
   <td style="text-align:right;"> 0.0041715 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 1.970000e-05 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 6155 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western juniper </td>
   <td style="text-align:left;"> Juniperus occidentalis </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 64 </td>
   <td style="text-align:right;"> 7.9610308 </td>
   <td style="text-align:right;"> 1.0543908 </td>
   <td style="text-align:right;"> 2.7615984 </td>
   <td style="text-align:right;"> 3.142583e-01 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western juniper </td>
   <td style="text-align:left;"> Juniperus occidentalis </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 64 </td>
   <td style="text-align:right;"> 6.6776122 </td>
   <td style="text-align:right;"> 4.0294480 </td>
   <td style="text-align:right;"> 0.4394057 </td>
   <td style="text-align:right;"> 3.799497e-01 </td>
   <td style="text-align:right;"> 117 </td>
   <td style="text-align:right;"> 15382 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western juniper </td>
   <td style="text-align:left;"> Juniperus occidentalis </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 64 </td>
   <td style="text-align:right;"> 6.4376020 </td>
   <td style="text-align:right;"> 11.7284547 </td>
   <td style="text-align:right;"> 0.1699237 </td>
   <td style="text-align:right;"> 1.582060e+00 </td>
   <td style="text-align:right;"> 257 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western juniper </td>
   <td style="text-align:left;"> Juniperus occidentalis </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 64 </td>
   <td style="text-align:right;"> 6.8161997 </td>
   <td style="text-align:right;"> 139.8719082 </td>
   <td style="text-align:right;"> 0.0551664 </td>
   <td style="text-align:right;"> 6.046620e+01 </td>
   <td style="text-align:right;"> 350 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western larch </td>
   <td style="text-align:left;"> Larix occidentalis </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 73 </td>
   <td style="text-align:right;"> 18.0961593 </td>
   <td style="text-align:right;"> 3.8721024 </td>
   <td style="text-align:right;"> 0.0439249 </td>
   <td style="text-align:right;"> 1.115991e+01 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 2621 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western larch </td>
   <td style="text-align:left;"> Larix occidentalis </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 73 </td>
   <td style="text-align:right;"> 14.6961307 </td>
   <td style="text-align:right;"> 1.6021236 </td>
   <td style="text-align:right;"> 1.1483263 </td>
   <td style="text-align:right;"> 5.188125e-01 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western larch </td>
   <td style="text-align:left;"> Larix occidentalis </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 73 </td>
   <td style="text-align:right;"> 13.8106288 </td>
   <td style="text-align:right;"> 11.3450658 </td>
   <td style="text-align:right;"> 2.0337182 </td>
   <td style="text-align:right;"> 4.198673e+00 </td>
   <td style="text-align:right;"> 97 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western larch </td>
   <td style="text-align:left;"> Larix occidentalis </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 73 </td>
   <td style="text-align:right;"> 11.8882833 </td>
   <td style="text-align:right;"> 31.4273336 </td>
   <td style="text-align:right;"> 0.2707815 </td>
   <td style="text-align:right;"> 8.885280e+00 </td>
   <td style="text-align:right;"> 317 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western larch </td>
   <td style="text-align:left;"> Larix occidentalis </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 73 </td>
   <td style="text-align:right;"> 9.6984206 </td>
   <td style="text-align:right;"> 30.2586495 </td>
   <td style="text-align:right;"> 0.1846479 </td>
   <td style="text-align:right;"> 5.693189e+00 </td>
   <td style="text-align:right;"> 545 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western larch </td>
   <td style="text-align:left;"> Larix occidentalis </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 73 </td>
   <td style="text-align:right;"> 8.3530898 </td>
   <td style="text-align:right;"> 12.7979841 </td>
   <td style="text-align:right;"> 0.5426367 </td>
   <td style="text-align:right;"> 2.233947e+00 </td>
   <td style="text-align:right;"> 233 </td>
   <td style="text-align:right;"> 20236 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western larch </td>
   <td style="text-align:left;"> Larix occidentalis </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 73 </td>
   <td style="text-align:right;"> 13.6844403 </td>
   <td style="text-align:right;"> 1.1797604 </td>
   <td style="text-align:right;"> 8.5852710 </td>
   <td style="text-align:right;"> 4.850687e-01 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 9017 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western redcedar </td>
   <td style="text-align:left;"> Thuja plicata </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 225+ cubic feet/acre/year </td>
   <td style="text-align:right;"> 242 </td>
   <td style="text-align:right;"> 25.5587237 </td>
   <td style="text-align:right;"> 90.3455490 </td>
   <td style="text-align:right;"> 19.2011069 </td>
   <td style="text-align:right;"> 4.145878e+02 </td>
   <td style="text-align:right;"> 42 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western redcedar </td>
   <td style="text-align:left;"> Thuja plicata </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 242 </td>
   <td style="text-align:right;"> 24.4761581 </td>
   <td style="text-align:right;"> 113.1509131 </td>
   <td style="text-align:right;"> 2.8373492 </td>
   <td style="text-align:right;"> 1.316134e+02 </td>
   <td style="text-align:right;"> 320 </td>
   <td style="text-align:right;"> 20188 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western redcedar </td>
   <td style="text-align:left;"> Thuja plicata </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 242 </td>
   <td style="text-align:right;"> 25.4230753 </td>
   <td style="text-align:right;"> 147.2426004 </td>
   <td style="text-align:right;"> 2.1874132 </td>
   <td style="text-align:right;"> 1.318581e+02 </td>
   <td style="text-align:right;"> 564 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western redcedar </td>
   <td style="text-align:left;"> Thuja plicata </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 242 </td>
   <td style="text-align:right;"> 18.5023432 </td>
   <td style="text-align:right;"> 129.8142956 </td>
   <td style="text-align:right;"> 1.6743511 </td>
   <td style="text-align:right;"> 1.857817e+02 </td>
   <td style="text-align:right;"> 360 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western redcedar </td>
   <td style="text-align:left;"> Thuja plicata </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 242 </td>
   <td style="text-align:right;"> 15.1370886 </td>
   <td style="text-align:right;"> 48.0469222 </td>
   <td style="text-align:right;"> 1.5637802 </td>
   <td style="text-align:right;"> 3.268294e+01 </td>
   <td style="text-align:right;"> 240 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western redcedar </td>
   <td style="text-align:left;"> Thuja plicata </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 242 </td>
   <td style="text-align:right;"> 11.4649402 </td>
   <td style="text-align:right;"> 13.2615722 </td>
   <td style="text-align:right;"> 3.3315943 </td>
   <td style="text-align:right;"> 1.226277e+01 </td>
   <td style="text-align:right;"> 63 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western redcedar </td>
   <td style="text-align:left;"> Thuja plicata </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 242 </td>
   <td style="text-align:right;"> 26.3900502 </td>
   <td style="text-align:right;"> 9.8081606 </td>
   <td style="text-align:right;"> 198.2739763 </td>
   <td style="text-align:right;"> 3.273084e+01 </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:right;"> 13341 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western white pine </td>
   <td style="text-align:left;"> Pinus monticola </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 119 </td>
   <td style="text-align:right;"> 27.7346181 </td>
   <td style="text-align:right;"> 1.7405935 </td>
   <td style="text-align:right;"> 15.0148100 </td>
   <td style="text-align:right;"> 6.589381e-01 </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:right;"> 13582 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western white pine </td>
   <td style="text-align:left;"> Pinus monticola </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 119 </td>
   <td style="text-align:right;"> 24.5685595 </td>
   <td style="text-align:right;"> 2.2331535 </td>
   <td style="text-align:right;"> 5.3538559 </td>
   <td style="text-align:right;"> 2.521758e-01 </td>
   <td style="text-align:right;"> 46 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western white pine </td>
   <td style="text-align:left;"> Pinus monticola </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 119 </td>
   <td style="text-align:right;"> 21.5448709 </td>
   <td style="text-align:right;"> 6.1378029 </td>
   <td style="text-align:right;"> 3.6717560 </td>
   <td style="text-align:right;"> 1.165595e+00 </td>
   <td style="text-align:right;"> 100 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western white pine </td>
   <td style="text-align:left;"> Pinus monticola </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 119 </td>
   <td style="text-align:right;"> 13.5164945 </td>
   <td style="text-align:right;"> 4.5491220 </td>
   <td style="text-align:right;"> 1.4772469 </td>
   <td style="text-align:right;"> 6.476924e-01 </td>
   <td style="text-align:right;"> 102 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western white pine </td>
   <td style="text-align:left;"> Pinus monticola </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 119 </td>
   <td style="text-align:right;"> 9.1330981 </td>
   <td style="text-align:right;"> 5.3716617 </td>
   <td style="text-align:right;"> 0.3957910 </td>
   <td style="text-align:right;"> 6.007847e-01 </td>
   <td style="text-align:right;"> 118 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> western white pine </td>
   <td style="text-align:left;"> Pinus monticola </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 119 </td>
   <td style="text-align:right;"> 5.8384557 </td>
   <td style="text-align:right;"> 1.1863105 </td>
   <td style="text-align:right;"> 3.6463841 </td>
   <td style="text-align:right;"> 1.472294e-01 </td>
   <td style="text-align:right;"> 27 </td>
   <td style="text-align:right;"> 15912 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> white alder </td>
   <td style="text-align:left;"> Alnus rhombifolia </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 352 </td>
   <td style="text-align:right;"> 27.0633653 </td>
   <td style="text-align:right;"> 0.0490490 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 2.533800e-03 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 15382 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> white alder </td>
   <td style="text-align:left;"> Alnus rhombifolia </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 352 </td>
   <td style="text-align:right;"> 29.3001058 </td>
   <td style="text-align:right;"> 0.7287180 </td>
   <td style="text-align:right;"> 498.2796435 </td>
   <td style="text-align:right;"> 3.000365e-01 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 19947 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> white alder </td>
   <td style="text-align:left;"> Alnus rhombifolia </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 352 </td>
   <td style="text-align:right;"> 8.1748914 </td>
   <td style="text-align:right;"> 0.6188410 </td>
   <td style="text-align:right;"> 6.1267209 </td>
   <td style="text-align:right;"> 1.411793e-01 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 10720 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> white alder </td>
   <td style="text-align:left;"> Alnus rhombifolia </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 352 </td>
   <td style="text-align:right;"> 10.3196916 </td>
   <td style="text-align:right;"> 0.0811285 </td>
   <td style="text-align:right;"> 39.2882500 </td>
   <td style="text-align:right;"> 5.015700e-03 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 10720 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> white alder </td>
   <td style="text-align:left;"> Alnus rhombifolia </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 352 </td>
   <td style="text-align:right;"> 7.4108913 </td>
   <td style="text-align:right;"> 1.1447267 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 1.097150e+00 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 4565 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> white fir </td>
   <td style="text-align:left;"> Abies concolor </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 165-224 cubic feet/acre/year </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 21.0826212 </td>
   <td style="text-align:right;"> 4.5804059 </td>
   <td style="text-align:right;"> 11.5999723 </td>
   <td style="text-align:right;"> 3.072334e+00 </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> white fir </td>
   <td style="text-align:left;"> Abies concolor </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 22.1729247 </td>
   <td style="text-align:right;"> 40.7740320 </td>
   <td style="text-align:right;"> 0.9804116 </td>
   <td style="text-align:right;"> 3.729721e+01 </td>
   <td style="text-align:right;"> 140 </td>
   <td style="text-align:right;"> 15671 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> white fir </td>
   <td style="text-align:left;"> Abies concolor </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 17.5926557 </td>
   <td style="text-align:right;"> 74.1299363 </td>
   <td style="text-align:right;"> 0.5281383 </td>
   <td style="text-align:right;"> 5.123679e+01 </td>
   <td style="text-align:right;"> 257 </td>
   <td style="text-align:right;"> 17856 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> white fir </td>
   <td style="text-align:left;"> Abies concolor </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 15.2043025 </td>
   <td style="text-align:right;"> 58.3893528 </td>
   <td style="text-align:right;"> 0.3039714 </td>
   <td style="text-align:right;"> 2.156609e+01 </td>
   <td style="text-align:right;"> 303 </td>
   <td style="text-align:right;"> 17615 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> white fir </td>
   <td style="text-align:left;"> Abies concolor </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 13.0473226 </td>
   <td style="text-align:right;"> 30.9237071 </td>
   <td style="text-align:right;"> 0.3553001 </td>
   <td style="text-align:right;"> 1.810195e+01 </td>
   <td style="text-align:right;"> 160 </td>
   <td style="text-align:right;"> 13050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> white fir </td>
   <td style="text-align:left;"> Abies concolor </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 21.4280155 </td>
   <td style="text-align:right;"> 2.4275877 </td>
   <td style="text-align:right;"> 16.9573042 </td>
   <td style="text-align:right;"> 1.716857e+00 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 12761 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> whitebark pine </td>
   <td style="text-align:left;"> Pinus albicaulis </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 120-164 cubic feet/acre/year </td>
   <td style="text-align:right;"> 101 </td>
   <td style="text-align:right;"> 3.3925683 </td>
   <td style="text-align:right;"> 0.0942947 </td>
   <td style="text-align:right;"> 0.0291786 </td>
   <td style="text-align:right;"> 5.480300e-03 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 6155 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> whitebark pine </td>
   <td style="text-align:left;"> Pinus albicaulis </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 85-119 cubic feet/acre/year </td>
   <td style="text-align:right;"> 101 </td>
   <td style="text-align:right;"> 5.0769738 </td>
   <td style="text-align:right;"> 0.1276137 </td>
   <td style="text-align:right;"> 2.6602857 </td>
   <td style="text-align:right;"> 1.016080e-02 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 13630 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> whitebark pine </td>
   <td style="text-align:left;"> Pinus albicaulis </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 50-84 cubic feet/acre/year </td>
   <td style="text-align:right;"> 101 </td>
   <td style="text-align:right;"> 3.4882876 </td>
   <td style="text-align:right;"> 0.3816957 </td>
   <td style="text-align:right;"> 0.2359677 </td>
   <td style="text-align:right;"> 1.354260e-02 </td>
   <td style="text-align:right;"> 27 </td>
   <td style="text-align:right;"> 13871 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> whitebark pine </td>
   <td style="text-align:left;"> Pinus albicaulis </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 20-49 cubic feet/acre/year </td>
   <td style="text-align:right;"> 101 </td>
   <td style="text-align:right;"> 6.2228759 </td>
   <td style="text-align:right;"> 2.5918053 </td>
   <td style="text-align:right;"> 0.1405614 </td>
   <td style="text-align:right;"> 4.774129e-01 </td>
   <td style="text-align:right;"> 59 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> whitebark pine </td>
   <td style="text-align:left;"> Pinus albicaulis </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> 0-19 cubic feet/acre/year </td>
   <td style="text-align:right;"> 101 </td>
   <td style="text-align:right;"> 5.8001017 </td>
   <td style="text-align:right;"> 8.9136909 </td>
   <td style="text-align:right;"> 0.2195558 </td>
   <td style="text-align:right;"> 5.112983e+00 </td>
   <td style="text-align:right;"> 49 </td>
   <td style="text-align:right;"> 20477 </td>
  </tr>
</tbody>
</table></div>

