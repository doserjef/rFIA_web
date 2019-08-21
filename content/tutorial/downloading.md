---
title: Downloading FIA data and getting it into R
linktitle: Downloading FIA data
toc: true
type: docs
date: "2019-05-05T00:00:00+01:00"
draft: false
menu:
  tutorial:
    parent: Overview
    weight: 1

# Prev/next pager order (if `docs_section_pager` enabled in `params.toml`)
weight: 1
---

___


## _**Download data**_
The first step to using `rFIA` is to download subsets of the FIA Database. The easiest way to accomplish this is using `getFIA`, although users may also choose to download subsets as .csv files from the [FIA Datamart](https://apps.fs.usda.gov/fia/datamart/CSV/datamart_csv.html) and load into R using `readFIA`.

```{r}
## Download the state subset or Connecticut (requires an internet connection)
## Save as an object to automatically load the data into your current R session!
ct <- getFIA(states = 'CT', dir = '/path/to/save/data')
```

{{% alert note %}}
If you are interested in large subsets of the FIA Database (even large states), downloading these data from the [FIA Datamart](https://apps.fs.usda.gov/fia/datamart/CSV/datamart_csv.html) and loading with `readFIA` may be faster than using `getFIA`.
{{% /alert %}}


<br>

## _**Load data into R**_
If you used `getFIA` to download data, then the database is automatically loaded into your current R session.  If you downloaded data manually from the [FIA Datamart](https://apps.fs.usda.gov/fia/datamart/CSV/datamart_csv.html), simply unzip the object, and save the .csv files in a local directory, and load them into R using `readFIA`: 

```{r}
## Load FIA Data from a local directory
db <- readFIA('/path/to/your/directory/')
```

{{% alert note %}}
Data previously downloaded with `getFIA` can be reloaded into a new R session with `readFIA`.
{{% /alert %}}

<br>

## _**Loading multiple states**_
Need to load multiple state subsets of FIA data for regional analyses? No problem! Using `getFIA`, specify mutiple state abbreviations in the `states` argument (e.g. `states = c('MI', 'IN', 'WI', 'IL')`). Alternatively, download state subsets manually from the FIA Datamart as .zip files  (*recommended for large subsets*), unzip files into the same local directory, and load using `readFIA`.

When multiple state subsets of data are loaded into R using `getFIA` or `readFIA`, subsets will be merged into a single `FIA.Database` object. This will allow you to use other `rFIA` functions to produce estimates for areas which straddle state boundaries!

{{% alert note %}}
Note: given the massive size of the full FIA Database, users are cautioned to only download the subsets containing their region of interest.
{{% /alert %}}

<br>

## _**Loading specific tables**_
If you are only interested in loading/downloading a specific table from the FIA database, simply specify the names of those tables in the `tables` argument of `readFIA` or `getFIA` (e.g. specify `tables = c('TREE', 'PLOT')` for the TREE and PLOT tables). See the [FIADB User Guide](https://www.fia.fs.fed.us/library/database-documentation/current/ver80/FIADB%20User%20Guide%20P2_8-0.pdf) for a complete description of the database.

By default, `getFIA` and `readFIA` only loads/downloads the portions of the database required to produce summaries with other `rFIA` functions (`common = TRUE`). This conserves memory on your machine and speeds download time. If you would like to load/download all available tables for a state, simple specify `common = FALSE` in the call to  `readFIA` or `getFIA`.

<br>

## _**The FIA.Database object**_
When FIA data is loaded into R with `readFIA` or `getFIA`, those data are stored in an `FIA.Database` object. An `FIA.Database` object is essentially just a list, and users can access individual tables with `$`, `[''], and `[['']]` operators: 

```{r}
## Access the TREE, PLOT, and COND tables 
# Tree
db$TREE

# Plot
db['PLOT']

# Condition
db[['COND']]

## Check spatial coverage of plots held in the database
plot(db$PLOT$LON, db$PLOT$LAT)
```
