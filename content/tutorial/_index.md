---
title: Getting Started
layout: docs  # Do not modify.

  
  
# Page metadata.
#title: Getting started
date: "2018-09-09T00:00:00Z"
lastmod: "2018-09-09T00:00:00Z"
draft: false  # Is this a draft? true/false
toc: true  # Show table of contents? true/false
type: docs  # Do not modify.


# Add menu entry to sidebar.
# - name: Declare this menu item as a parent with ID `name`.
# - weight: Position of link in menu.
menu:
  tutorial:
    name: Overview
    weight: 1
---

___

## _**Installation**_

You can install the released version from<a href="https://CRAN.R-project.org" target="_blank">CRAB</a> (COMING SOON!):

``` r
install.packages("rFIA")
```

Alternatively, you can install the development version from GitHub:
```r
devtools::install_github('hunter-stanke/rFIA')
```

<br>

## _**Functionality Overview**_

|`rFIA` Function  | Description                                                          |
|---------------- |----------------------------------------------------------------------|
|`biomass`        | Estimate volume, biomass, & carbon stocks of standing trees          |
|`clipFIA`        | Spatial & temporal queries                                           |
|`diversity`      | Estimate species diversity                                           |
|`dwm`            | Estimate volume, biomass, and carbon stocks of down woody material   |
|`getFIA`         | Download FIA data, load into R, and optionally save to disk      |
|`growMort`       | Estimate recruitment, mortality, and harvest rates                   |
|`invasive`       | Estimate areal coverage of invasive species                          |
|`plotFIA`        | Produce static & animated plots of spatial FIA summaries             |
|`readFIA`        | Load FIA database into R environment                                 |
|`standStruct`    | Estimate forest structural stage distributions                       |
|`tpa`            | Estimate abundance of standing trees (TPA & BAA)                     |
|`vitalRates`     | Estimate live tree growth rates                                      |

<br>

## _**Learn More!**_
- [Downloading FIA Data] ( {{< ref "/tutorial/downloading.md" >}} )
- [Estimating Forest Attributes] ( {{< ref "/tutorial/basicAnalysis.md" >}} )
- [Incorporating Spatial Data] ( {{< ref "/tutorial/spatial.md" >}} )
- [Tips for Handling Big Data] ( {{< ref "/tutorial/bigData.md" >}} )