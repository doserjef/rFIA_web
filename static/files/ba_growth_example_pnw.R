##==============================================================================
##==============================================================================
##
## Quick intro on using rFIA to estimate annual tree growth rates from FIA data.
## Specifically, we'll use the most recent inventory from PNW states (WA & OR)
## to estimate annual basal area increment on a per tree and per area basis, by
## species, site productivity class, and other groups.
##
## Created:       21 January 2020 - Hunter Stanke (stankehu@uw.edu)
## Last modified: 21 January 2020 - Hunter Stanke (stankehu@uw.edu)
##
##==============================================================================
##==============================================================================


## First thing: install dev version of rFIA from GitHub ------------------------
## I just made a change to vitalRates that will make life easier below
devtools::install_github('hunter-stanke/rFIA')





## Some setup ------------------------------------------------------------------
## Load some packages
library(rFIA)
library(dplyr)

## If you have FIA data already, where is it?
## If you don't have it yet, where would you like it to go?
fiaPath <- 'path/to/FIA/data'

## Want to use multiple cores?
## Use parallel::detectCores(logical=FALSE) to check how many you have.
## I recommend leaving at least one free
cores <- 1





## Download some FIA data from the DataMart ------------------------------------
## Only need to run this once! The data will be saved to the 'dir' directory
## and can be loaded again with readFIA (see below)
getFIA(states = c('OR', 'WA'),
       dir = fiaPath,
       load = FALSE) # Download, but don't load yet




## Set up a "remote" database --------------------------------------------------
db <- readFIA(dir = fiaPath,
              states = c('OR', 'WA'), # If you keep all your data together
              nCores = cores,
              inMemory = FALSE) # Set to TRUE if your computer has enough RAM




## Take the most recent subset -------------------------------------------------
db <- clipFIA(db,
              mostRecent = TRUE)




## Estimate NET growth rates ---------------------------------------------------
# Mean annual change in individual tree basal area (BA_GROW) and basal area per
# acre (BA_GROW_AC) summarized by species and site productivity codes (SITECLCD)
# Note that net growth is the average annual change in each variable, including
# recruitment, mortality, and growth processes. As such, estimates may be
# negative. If you're more interested in growth rates for trees that started out
# alive and stayed alive, set treeType = 'live' (like below)
net <- vitalRates(db,
                  treeType = 'all',
                  grpBy = SITECLCD,
                  bySpecies = TRUE,
                  variance = TRUE,
                  nCores = cores)


## Same as above, but only estimating growth using trees that were alive and in
## our sample (>= 5 inches dbh) at first measurement and stayed that way for the
## second measurement. More realistic estimates of individual tree growth
live <- vitalRates(db,
                  treeType = 'live',
                  grpBy = SITECLCD,
                  bySpecies = TRUE,
                  variance = TRUE,
                  nCores = cores)




## Pretty up the results -------------------------------------------------------
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


live <- live %>%
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




## Convert units ---------------------------------------------------------------
net <- net %>%
  ## Convert to square centimeters instead of square feet
  mutate(BA_GROW = BA_GROW * 929.03,
         BA_GROW_AC = BA_GROW_AC * 929.03,
         BA_GROW_VAR = BA_GROW_VAR * (929.03^2),
         BA_GROW_AC_VAR = BA_GROW_AC_VAR * (929.03^2))

live <- live %>%
  ## Convert to square centimeters instead of square feet
  mutate(BA_GROW = BA_GROW * 929.03,
         BA_GROW_AC = BA_GROW_AC * 929.03,
         BA_GROW_VAR = BA_GROW_VAR * (929.03^2),
         BA_GROW_AC_VAR = BA_GROW_AC_VAR * (929.03^2))

