---
title: Forests of the Appalachian National Scenic Trail
layout: docs  # Do not modify.

  
  
# Page metadata.
date: "2019-10-14T00:00:00Z"
lastmod: "2018-09-09T00:00:00Z"
draft: false  # Is this a draft? true/false
toc: true  # Show table of contents? true/false
type: docs  # Do not modify.


# Add menu entry to sidebar.
# - name: Declare this menu item as a parent with ID `name`.
# - weight: Position of link in menu.
menu:
  at:
    name: AT Forests
    weight: 1
---
<style>

p    {font-size: 19px;}

</style>

<img src="/img/ATC_Humpbackrocks.jpg" hspace = 50 vspace = 40>

## _**Overview**_
___


**The Appalachian National Scenic Trail** (APPA) traverses more than 2,170 miles across the highest ridgelines of the Appalachian Mountains, from Georgia to Maine. Along the way it crosses through 14 states, eight National Forests, six National Parks, six Inventory and Monitoring networks, a National Wildlife Refuge, three Tennessee Valley Authority properties, one Smithsonian Institute property, and over 280 local jurisdictions. The Trail is managed in partnership with the <a href="http://www.appalachiantrail.org/" target="_blank">Appalachian Trail Conservancy (ATC)</a> and its 30 affiliated Trail-maintaining clubs under an extraordinary cooperative management system that provides for an annual contribution of nearly 200,000 hours by more than 5,000 volunteers.

The trail's length, north-south alignment, changes in elevation, and numerous peaks and ridges it crosses along this ancient mountain chain creates *one of the most biodiverse units of the National Park System*.

The Appalachian Trail is uniquely situated to serve as a barometer for the air, water, and biological diversity of the Appalachian Mountains and much of the eastern United States. That is what makes the A.T. an attractive place to explore scientific questions, and which lead to the creation of the <a href="https://www.nps.gov/im/netn/appa.htm" style="color:##003399" target="_blank">A.T. MEGA-Transect</a>. To this end, the National Park Service and ATC, in cooperation with the USDA Forest Service, the U.S. Geological Survey, and a host of other agencies and organizations, are focusing their energies on assessing, understanding, and monitoring the vast wealth of natural resources present on the Appalachian Trail’s 270,000-acre land base.



**The Appalachian Trail is monitored through the <a href="https://www.nps.gov/im/netn/index.htm" target="_blank">North East Temperate Inventory and Monitoring Network's</a> <a href="https://irma.nps.gov/DataStore/Reference/Profile/2170918" target="_blank">Vital Sign Monitoring Program</a>. The goals of monitoring along the trail include:**



* Determine the status and trends in selected indicators of the condition of park ecosystems to allow managers to make better-informed decisions and to work more effectively with other agencies and individuals for the benefit of park resources
* Provide early warning of abnormal conditions of selected resources to help develop effective mitigation measures and reduce costs of management
* Provide data to better understand the dynamic nature and condition of park ecosystems and to provide reference points for comparisons with other, altered environments
* Provide data to meet certain legal and Congressional mandates related to natural resource protection and visitor enjoyment
* Provide a means of measuring progress towards performance goals.


<br>

## _**The Challenge**_
___
**The large, but narrow configuration of the APPA makes a ground-based plot monitoring program logistically and financially infeasible for the National Park Service to implement.** In light of that challenge, the <a href="https://www.nps.gov/im/netn/index.htm" target="_blank">North East Temperate Inventory and Monitoring Network</a> developed a <a href="https://irma.nps.gov/DataStore/Reference/Profile/2257434" target="_blank">data acquisition protocol</a> to track the overall condition of forest resources along the Appalachian Trail using plot-based data collected by the Forest Inventory and Analysis (FIA) Program. 

Beginning to implement this monitoring program, we found a lack of publicly available tools to compute complex, space-time indexed summaries from FIA data. We created `rFIA` to address this challenge. We thank the <a href="https://www.nps.gov/im/netn/index.htm" target="_blank">North East Temperate Inventory and Monitoring Network</a> and the <a href="https://www.nps.gov/im/index.htm" target="_blank">National Park Service Inventory and Monitoring Division</a> for their contribution to the development of `rFIA`, and for providing technical and financial support to implement the 	
Appalachian National Scenic Trail <a href="https://irma.nps.gov/DataStore/Reference/Profile/2257434" target="_blank">forest health monitoring protocol</a>.

**Using `rFIA` We leverage the Forest Inventory and Analysis database to assess the status and trends in forest condition along the Appalachian Trail and neighboring lands**. Specifically, we estimate the following attributes within ecoregion subsections which intersect the Appalachian Trail: 

1. [**Live tree abundance and biomass**] ( {{< ref "/at/tpa.md" >}} )
  + TPA, BAA, biomass, and carbon by species
2. [**Species diversity of live trees**] ( {{< ref "/at/div.md" >}} )
  + Shannon's diversity, evenness, and richness
3. [**Tree vital rates**] ( {{< ref "/at/vr.md" >}} )
  + Annual diameter, basal area, and biomass growth by species
4. [**Forest demographic rates**] ( {{< ref "/at/gm.md" >}} )
  + Annual recruitment, mortality, and harvest totals and rates by species
5. [**Regeneration abundance**] ( {{< ref "/at/regen.md" >}} )
  + TPA of regenerating stems (<5" DBH) by species and size-class
6. [**Snag abundance**] ( {{< ref "/at/snag.md" >}} )
  + TPA, BAA, biomass, carbon, relative fraction
7. [**Down woody debris abundance**] ( {{< ref "/at/dwm.md" >}} ) 
  + Volume, biomass, and carbon by fuel class
8. [**Invasive Plant abundance**] ( {{< ref "/at/inv.md" >}} )
  + % cover by species
9. [**Stand structural stage distributions**] ( {{< ref "/at/ss.md" >}} )
  + % area in pole, mature, and late stage forest

<br>



## _**Anticipated use of results**_
___
* **Adaptive Management and Science**
  + Provide sound scientific baseline and trend information about environmental conditions on the Appalachian Trail to help inform practice and science
* **Public Policy and Action**
  + Utilize large-scale data sets to inform the public and influence decisions
* **Public Engagement and Education** 
  + Involve citizens and use the Appalachian Trail's iconic status to convey key findings to the public.


<br>

## _**Get the Data!**_  

{{% alert note %}}
**Download all data, code, and results** from this project <a href="/files/AT_Summary.zip" target="_blank">HERE</a>!
{{% /alert %}}

