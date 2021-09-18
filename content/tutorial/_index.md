---
#title: Getting Started
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

## **Installation**

You can install the released version from <a href="https://cran.r-project.org/web/packages/rFIA/index.html" target="_blank">CRAN</a>:

``` r
install.packages("rFIA")
```

Alternatively, you can install the development version from GitHub:
```r
devtools::install_github('hunter-stanke/rFIA')
```


<br>

## **Functionality Overview**

|`rFIA` Function  | Description                                                          |
|---------------- |----------------------------------------------------------------------|
|`area`           | Estimate land area in various classes                                |
|`areaChange`     | Estimate annual change in land area in various classes               |
|`biomass`        | Estimate biomass & carbon stocks of standing trees                   |
|`carbon`         | Estimate carbon stocks by IPCC forest carbon pools                   |
|`customPSE`      | Estimate custom variables                                            |
|`clipFIA`        | Spatial & temporal queries for FIA data                              |
|`diversity`      | Estimate diversity indices (e.g. species diversity)                  |
|`dwm`            | Estimate volume, biomass, and carbon stocks of down woody material   |
|`fsi`            | Estimate Forest Stability Index for live tree populations            |
|`getDesignInfo`  | Summarize attributes of FIA's post-stratified inventories            |
|`getFIA`         | Download FIA data, load into R, and optionally save to disk          |
|`growMort`       | Estimate recruitment, mortality, and harvest rates                   |
|`intersectFIA`   | Join attributes of a spatial polygon(s) to FIA's PLOT table          |
|`invasive`       | Estimate areal coverage of invasive species                          |
|`plotFIA`        | Produce static & animated plots of FIA summaries                     |
|`readFIA`        | Load FIA database into R environment from disk                       |
|`seedling`       | Estimate seedling abundance (TPA)                                    |
|`standStruct`    | Estimate forest structural stage distributions                       |
|`tpa`            | Estimate abundance of standing trees (TPA & BAA)                     |
|`vitalRates`     | Estimate live tree growth rates                                      |
|`volume`         | Estimate merchantable volume of standing trees                       | 
|`writeFIA`       | Write in-memory FIA Database to disk                                 |

<br>

## _**Learn More!**_
- [Downloading FIA Data] ( {{< ref "/tutorial/downloading.markdown" >}} )
- [Estimating Forest Attributes] ( {{< ref "/tutorial/basicAnalysis.markdown" >}} )
- [Incorporating Spatial Data] ( {{< ref "/tutorial/spatial.markdown" >}} )
- [Using alternative estimators] ( {{< ref "/tutorial/ae.markdown" >}} )
- [Tips for Handling Big Data] ( {{< ref "/tutorial/bigData.markdown" >}} )
- [Handling Custom Variables] ( {{< ref "/tutorial/customVariables.markdown" >}} )