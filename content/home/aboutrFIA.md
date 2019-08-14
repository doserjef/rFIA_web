+++
# A Demo section created with the Blank widget.
# Any elements can be added in the body: https://sourcethemes.com/academic/docs/writing-markdown-latex/
# Add more sections by duplicating this file and customizing to your requirements.

widget = "blank"  # See https://sourcethemes.com/academic/docs/page-builder/
headless = false  # This file represents a page section.
active = true  # Activate this widget? true/false
weight = 2  # Order that this section will appear.

#title = "Unlocking the FIA Database in R"

[design]
  # Choose how many columns the section has. Valid values: 1 or 2.
  columns = "1"

[design.background]
  # Apply a background color, gradient, or image.
  #   Uncomment (by removing `#`) an option to apply it.
  #   Choose a light or dark text color by setting `text_color_light`.
  #   Any HTML color name or Hex value is valid.

  # Background color.
  #color = "black"
  
  # Background gradient.
  # gradient_start = "DeepSkyBlue"
  # gradient_end = "SkyBlue"
  
  # Background image.
  #image = "drone_borealCanopy.png"  # Name of image in `static/img/`.
  #image_darken = 0.8 # Darken the image? Range 0-1 where 0 is transparent and 1 is opaque.


  # Text color (true=light or false=dark).
  text_color_light = false

[design.spacing]
  # Customize the section spacing. Order is top, right, bottom, left.
  padding = ["0", "20px", "120px", "0"]

[advanced]
 # Custom CSS. 
 css_style = ""
 
 # CSS class.
 css_class = ""
+++
# _**Unlocking the FIA Database in R**_


The goal of `rFIA` is to increase the accessibility and use of the USFS Forest Inventory and Analysis (FIA) Database by providing a user-friendly, open source platform to easily query and analyze FIA Data. Designed to accommodate a wide range of potential user objectives, `rFIA` simplifies the estimation of forest variables from the FIA Database and allows all R users (experts and newcomers alike) to unlock the flexibility and potential inherent to the Enhanced FIA design.

Specifically, `rFIA` improves accessibility to the spatio-temporal estimation capacity of the FIA Database by producing space-time indexed summaries of forest variables within user-defined population boundaries. Direct integration with other popular R packages (e.g., dplyr, sp, and sf) facilitates efficient space-time query and data summary, and supports common data representations and API design. The package implements design-based estimation procedures outlined by Bechtold & Patterson (2005), and has been validated against estimates and sampling errors produced by EVALIDator. Current development is focused on the implementation of spatially-enabled model-assisted estimators to improve population, change, and ratio estimates.

You can download subsets of the FIA Database at the FIA Datamart: https://apps.fs.usda.gov/fia/datamart/CSV/datamart_csv.html






















