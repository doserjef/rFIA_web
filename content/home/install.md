+++
# blank widget.
widget = "hero"  # See https://sourcethemes.com/academic/docs/page-builder/
headless = true  # This file represents a page section.
active = true  # Activate this widget? true/false
weight = 3  # Order that this section will appear.
hero_media = "rLogo.png"

#title = "Unlocking the FIA Database in R"

[design]
  # Choose how many columns the section has. Valid values: 1 or 2.
  columns = '2'

[design.background]
  # Apply a background color, gradient, or image.
  #   Uncomment (by removing `#`) an option to apply it.
  #   Choose a light or dark text color by setting `text_color_light`.
  #   Any HTML color name or Hex value is valid.

  # Background color.
  #color = '#f8f9f9'
  
  # Background gradient.
  #gradient_start = "#4bb4e3"
  #gradient_end = "#2b94c3"
  
  # Background image.
  image = "hja_tower_sunset.jpg"  # Name of image in `static/img/`.
  image_darken = 0.5 # Darken the image? Range 0-1 where 0 is transparent and 1 is opaque.

  # Text color (true=light or false=dark).
  text_color_light = true

# Call to action links (optional).
#   Display link(s) by specifying a URL and label below. Icon is optional for `[cta]`.
#   Remove a link/note by deleting a cta/note block.
[cta]
  url = "https://github.com/hunter-stanke/rFIA"
  label = "Find us on Github"
  icon_pack = "fab"
  icon = "github"

[cta_alt]
  url = "files/rFIA-manual.pdf"
  label = "View Documentation"
  target = "_blank"
  
  
# Note. An optional note to show underneath the links.

+++

<p float="center">
<a href="https://cran.r-project.org/package=rFIA" style="display:inline-block;">
  <img src="https://www.r-pkg.org/badges/version/rFIA" style="border:0;">
</a> <a href="https://cran.r-project.org/package=rFIA" style="display:inline-block;">
  <img src="https://cranlogs.r-pkg.org/badges/grand-total/rFIA" style="border:0;">
</a> <a href="https://travis-ci.org/hunter-stanke/rFIA" style="display:inline-block;">
  <img src="https://travis-ci.org/hunter-stanke/rFIA.svg?branch=master" style="border:0;">
</a> <a href="https://www.tidyverse.org/lifecycle/#maturing" style="display:inline-block">
  <img src="https://img.shields.io/badge/lifecycle-maturing-blue.svg" style="border:0;">
</a>

</p>
  



Install the released version from [CRAN](https://CRAN.R-project.org):

``` r
install.packages("rFIA")
```


Or, the development version from GitHub:
```r
devtools::install_github('hunter-stanke/rFIA')
```