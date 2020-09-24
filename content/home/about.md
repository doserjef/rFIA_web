+++
# A brief intro to rFIA
# Main points: Why, how, what. Get specific here and include some future directions

widget = "blank"  # See https://sourcethemes.com/academic/docs/page-builder/
headless = true  # This file represents a page section.
active = true  # Activate this widget? true/false
weight = 4  # Order that this section will appear.

title = ""
subtitle = ""

[design]
  # Choose how many columns the section has. Valid values: 1 or 2.
  columns = "1"

[design.background]
  # Apply a background color, gradient, or image.
  #   Uncomment (by removing `#`) an option to apply it.
  #   Choose a light or dark text color by setting `text_color_light`.
  #   Any HTML color name or Hex value is valid.

  # Background color.
  # color = "navy"
  
  # Background gradient.
  # gradient_start = "DeepSkyBlue"
  # gradient_end = "SkyBlue"
  
  # Background image.
  #image = "headers/bubbles-wide.jpg"  # Name of image in `static/img/`.
  #image_darken = 0.6  # Darken the image? Range 0-1 where 0 is transparent and 1 is opaque.

  # Text color (true=light or false=dark).
  text_color_light = false

[design.spacing]
  # Customize the section spacing. Order is top, right, bottom, left.
  padding = ["20px", "0", "60px", "0"]

[advanced]
 # Custom CSS. 
 css_style = ""
 
 # CSS class.
 css_class = ""
+++
# _**About rFIA**_

-----------------------------------------





rFIA is an R package aimed at increasing the accessibility and use of the USFS Forest Inventory and Analysis (FIA) Database. Providing a user-friendly, open source toolset to easily query and analyze FIA Data, rFIA simplifies the estimation of forest variables from the FIA Database and allows all R users (experts and newcomers alike) to unlock the flexibility and potential inherent to the Enhanced FIA design.

Specifically, rFIA improves accessibility to the spatio-temporal estimation capacity of the FIA Database by producing space-time indexed summaries of forest variables within user-defined population boundaries. Direct integration with other popular R packages (e.g., `dplyr`, `sp`, and `sf`) facilitates efficient space-time query and data summary, and supports common data representations and API design. The package implements design-based estimation procedures outlined by Bechtold & Patterson (2005), and has been validated against estimates and sampling errors produced by FIA'S EVALIDator. 

Current development is focused on the implementation of spatially-enabled model-assisted estimators to improve point and change estimation at small spatial and temporal scales. We envision rFIA as a key component in the future of the FIA Program, targeting expansion in small area estimation, timber product monitoring, urban inventory, and the development of long-term monitoring and reporting tools.

See [Example Usage] ( {{< ref "/tutorial/_index.md" >}} ) to get started. To report a bug or suggest additions to rFIA, please use our [active issues](https://github.com/hunter-stanke/rFIA/issues) page on GitHub, or contact [Hunter Stanke](https://hunter-stanke.com/) (lead developer and maintainer). _**To cite**_ rFIA, please refer to our recent publication in [Environmental Modeling and Software](https://doi.org/10.1016/j.envsoft.2020.104664) (doi: https://doi.org/10.1016/j.envsoft.2020.104664).



