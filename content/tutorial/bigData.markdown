---
title: Tips for working with Big Data
linktitle: Big Data Tips
toc: true
type: docs
date: "2019-05-05T00:00:00+01:00"
draft: false
menu:
  tutorial:
    parent: Overview
    weight: 4

# Prev/next pager order (if `docs_section_pager` enabled in `params.toml`)
weight: 4
---

___



## _**Simple, easy parallelization**_
All `rFIA` estimator functions (as well as `readFIA` and `getFIA`) can be implemented in parallel, using the `nCores` argument. By default, processing is implemented serially `nCores = 1`, although users may find substantial increases in efficiency by increasing `nCores`. 

Parallelization is implemented with the parallel package. Parallel implementation is achieved using a snow type cluster on any Windows OS, and with multicore forking on any Unix OS (Linux, Mac). Implementing parallel processing may substantially decrease free memory during processing, particularly on Windows OS. Thus, users should be cautious when running in parallel, and consider implementing serial processing for this task if computational resources are limited (nCores = 1).


```r
## Check the number of cores available on your machine 
## Requires the parallel package, run library(parallel)
parallel::detectCores(logical = FALSE)

## On our machine, we find we have 4 physical cores. 
## To speed processing, we will split the workload 
## across 3 of these cores using nCores = 3
tpaRI_par <- tpa(fiaRI, nCores = 3)
```
<br>
