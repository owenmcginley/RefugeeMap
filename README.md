# Refugee Map Visualization using R Shiny

This R Shiny application visualizes global refugee data on an interactive map. The app allows users to explore the number of refugees originating from different countries over time.

## Features
- **Interactive Map**: Visualize refugee data by selecting a country of origin and a specific year.
- **Heatmap**: The map displays a heatmap showing the number of refugees for the selected year.
- **Country Highlight**: The selected country of origin is highlighted on the map for easy identification.
- **Data Source**: The refugee data is sourced from the [UNHCR](https://www.unhcr.org/refugee-statistics/download/?url=1reH5v) database, covering data from 1951 onwards.

## Getting Started

### Prerequisites
Make sure you have the following R packages installed:

```r
install.packages(c("rsconnect", "shiny", "readr", "dplyr", "leaflet", "RColorBrewer", "rnaturalearth", "rnaturalearthdata", "shinydashboard", "sf"))
