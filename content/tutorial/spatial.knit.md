---
title: Estimating forest attributes within unique spatial zones
linktitle: Incorporating Spatial Data
toc: true
type: docs
date: "2019-05-05T00:00:00+01:00"
draft: false
menu:
  tutorial:
    parent: Overview
    weight: 3

# Prev/next pager order (if `docs_section_pager` enabled in `params.toml`)
weight: 3
---



___
## **Grouping estimates by user-defined areal units**
Want to compute estimates within your own areal units (spatial polygons)? All `rFIA` estimator functions make this task fast and easy. Simply hand your spatial polygons to the `polys` argument of an estimator function, like `tpa` or `biomass`, and estimates will be grouped within those spatial zones. No need to worry about projections, *`rFIA` functions will reproject FIA data to match that of your input polygon.*

```r
## Most recent subset
riMR <- clipFIA(fiaRI)

## Group estimates by the areal units, and return as a dataframe
tpa_polys <- tpa(riMR, polys = countiesRI)

## Same as above, but return an sf mulitpolygon object (spatially enabled)
tpa_polysSF <- tpa(riMR, polys = countiesRI, returnSpatial = TRUE)
```
{{% alert note %}}
`polys` object must be of class `SpatialPolygons` (`sp` package), `SpatialPolygonsDataFrame` (`sp` package), or `MultiPolygon` (`sf` package). See below for help on loading data in R.
{{% /alert %}}

<br>

## **Returning estimates at the plot-level**
Want to return estimates at the plot level and retain the spatial data associated with each FIA plot? Just specify `returnSpatial = TRUE` and `byPlot = TRUE` in any `rFIA` estimator function, and you've got it!







