---
date: "2020-01-15T00:00:00Z"
external_link: ""
image:
  caption: 
  focal_point: Smart
links:
slides: 
summary: We present three case studies chosen to demonstrate some aspects of rFIA’s potential to advance forest health evaluation and monitoring in the United States.
tags:
#- Deep Learning
title: 2020 Forest Health Monitoring National Report
url_code: "https://github.com/hunter-stanke/2020_FHM_Chapter_code"
url_pdf: ""
url_slides: ""
url_video: ""
authors: ["hunter"]
---


## _**Overview**_
___

The U.S. Department of Agriculture Forest Inventory and Analysis (FIA) program collects data describing the condition and change of forest ecosystems across all lands in the United States. The extraordinary size of the spatial domain and breadth of forest variables sampled by the FIA program make it a unique and powerful resource for determining the extent and severity of undesirable changes in forest health across large spatial domains in the United States. Due to a lack of flexible, user-friendly tools for estimation of forest variables, the richness and utility of the FIA data are not always realized for forest health assessment. We developed rFIA, an open-source R package, to reduce these data accessibility hurdles and unlock the potential of FIA for broad-scale forest health evaluation and monitoring.

rFIA achieves two primary objectives: (1) improve the accessibility of FIA data for the estimation of status and change in forest ecosystems and (2) offer enhanced flexibility in estimation strategies and defining populations of interest. Using a simple yet powerful design, rFIA implements the design-based estimation procedures described in Bechtold and Patterson (2005) for more than 60 forest variables and allows users to return intermediate (i.e., plot, condition, and/or tree-level) estimates of all variables for use in modeling studies. With rFIA, users can easily summarize forest variables for populations defined by any combination of spatial units (i.e., spatial polygons), temporal domains (e.g., most recent measurements), and/or biophysical attributes (e.g., species, site classifications). Furthermore, rFIA implements five design-based estimators that enhance the value of FIA for temporal change detection and offer flexibility in a tradeoff between precision and temporal specificity.

Here we present three case studies chosen to demonstrate some aspects of rFIA’s potential to advance forest health evaluation and monitoring in the United States. First, we highlight rFIA’s spatiotemporal estimation capacity by estimating current down woody material (DWM) biomass within HUC6 watershed boundaries across the conterminous United States (CONUS) by combining the most recent FIA inventories available in each State. We next illustrate how rFIA enhances the value of FIA for temporal change detection by examining trends in lodgepole pine (_Pinus contorta_) mortality in Colorado using multiple design-based estimators. Finally, we use rFIA to estimate plot-level live tree density and develop a Bayesian hierarchical model to estimate changes in live tree abundance (i.e., net response of recruitment, growth, and mortality) within ecoregion subsections across the CONUS (excluding Wyoming due to a lack of remeasurements), thereby demonstrating how rFIA can aid model-based analyses.


## _**Get the Code!**_  
{{% alert note %}}
**Download all data, code, and results** from this project <a href="https://github.com/hunter-stanke/2020_FHM_Chapter_code" target="_blank">HERE</a>!
{{% /alert %}}



