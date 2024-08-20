
# Load Packages
require(rsconnect)
require(shiny)
require(readr)
require(dplyr)
require(leaflet)
require(RColorBrewer)
require(rnaturalearth)
require(rnaturalearthdata)
require(shinydashboard)
require(sf)

# Loading in refugee dataset, geometry and cleaning data
ref_data <- read_csv("refugee_data.csv")

# Refugee data is from [UNCHR](https://www.unhcr.org/refugee-statistics/download/?url=1reH5v)
# Data is from 1951 onwards, however does not specify country of origin until later on

world_map_df <- ne_countries(scale = "medium", returnclass = "sf")|>
  filter(name != "Antarctica") # remove Antarctica

world_map_names <- select(world_map_df, name_long, iso_a3)|>
  rename(coo_iso = iso_a3)

years = unique(ref_data$year) # For some reason would not work if used in ui

ref_data <- merge(ref_data, world_map_names, by = "coo_iso", all = TRUE)

# Define UI for the map making application using shinydashboard package
ui <- dashboardPage(
  # Title of Application
  dashboardHeader(title = "Refugee Map"),
  # Sidebar containing inputs for country of origin and year
  dashboardSidebar(
    # selectInput("mode", "Select a refugee viewing mode", choices = c("Country of origin", "Country of asylum")),
    selectInput("country", "Select a country of origin:", choices = unique(ref_data$name_long)),
    selectInput("year", "Select a year:", choices = years)
  ),
  # Body of dashboard featuring the map
  dashboardBody(
    tags$style(type = "text/css", "#map {height: calc(100vh - 80px) !important;}"),
    leafletOutput("map", height="100%", width="100%"),
    
  )
)
# Define server logic required to draw a histogram
server <- function(input, output, session) {
  
  # # Reactive function to change refugee viewing mode
  # selected_mode <- reactive({
  #   if(input$mode == "Country of origin") {
  #     "coo"
  #   } else {
  #     "coa"
  # }
  # })
  
  # Reactive function to change country of origin of refugees and year
  selected_country <- reactive({
    filter(ref_data, name_long == input$country, year == input$year)|>
      select(coo_iso, coa_iso, refugees)
  })
  
  
  output$map <- renderLeaflet({
    
    # # Merge map dataframe with selected_country() to connect map with refugee data
    # if(selected_mode() == "coo"){
    # world_map_df <- rename(world_map_df, coa_iso = iso_a3)
    # world_map_df <- merge(selected_country(), world_map_df, by = "coa_iso", all = TRUE)
    # } else{
    #   world_map_df <- rename(world_map_df, coo_iso = iso_a3)
    #   world_map_df <- merge(selected_country(), world_map_df, by = "coo_iso", all = TRUE)
    #   print(world_map_df)
    # }
    
    world_map_df <- rename(world_map_df, coa_iso = iso_a3)
    world_map_df <- merge(selected_country(), world_map_df, by = "coa_iso", all = TRUE)
    
    # Convert to SpatialPolygonsDataFrame
    world_map_sp <- st_as_sf(world_map_df)
    
    # Create bins for color heatmap using colorBin
    bins <- c(0, 1000, 10000, 25000, 50000, 100000, 250000, 500000, 1000000, Inf)
    pal <- colorBin("YlOrRd", domain = world_map_sp$refugees, bins = bins)
    
    # Make leaflet map using combined data
    map <- leaflet(world_map_sp)|>
      addProviderTiles(providers$Stadia.StamenTonerLite,
                       options = providerTileOptions(noWrap = TRUE))|>
      setView(0, 0, 2)|>
      addPolygons(
        fillColor = pal(world_map_sp$refugees),
        weight = 2,
        opacity = 1,
        color = "white",
        dashArray = "3",
        fillOpacity = 0.7,
        highlightOptions = highlightOptions(color = "#666", weight = 3, bringToFront = TRUE, dashArray = "", fillOpacity = 0.7),
        layerId = ~name_long,
        label = ~paste(name_long, ": ", refugees, " refugees")
      )|>
      # Using second addPolygons function in order to add blue selected country on top of map
      addPolygons(
        data = filter(world_map_sp, name_long == input$country),
        fillColor = "blue",
        weight = 2,
        opacity = 1,
        color = "white",
        dashArray = "3",
        fillOpacity = 0.7,
        highlightOptions = highlightOptions(color = "#666", weight = 3, bringToFront = TRUE, dashArray = "", fillOpacity = 0.7),
        layerId = ~name_long,
        label = ~paste(name_long, ": selected country")
      )|>
      # Legend containing information what the colors mean in terms of refugees
      addLegend(
        "bottomright",
        pal = pal,
        values = ~refugees,
        title = "Number of Refugees",
        opacity = 1
      )
    
    
  })
  # observe used to update selectInput and therefore the entire map with country clicked
  observe({
    updateSelectInput(session, "country", selected = input$map_shape_click$id)
  })
  
}

# Run the application 
shinyApp(ui = ui, server = server)
