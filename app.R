library(shiny)
library(leaflet)
library(RColorBrewer)
library(sp)
library(rworldmap)
library(shinythemes)
library(ggplot2)
library(DT)
library(plotly)

##############################################################

# Fontion pour donner la taille des cercles sur le leaflet

size_circle <- function(x){
  if(x <= 1.5){
    return(5000)
  }
  if(x <= 3){
    return(12500)
  }
  return(x^7)
}
size_circle <- Vectorize(size_circle)


#############################################################

ui <- bootstrapPage(
  navbarPage(theme = shinytheme("flatly"),title = "Earthquake🅁",
             tabPanel(title = "Carte",
                      leafletOutput("map", width="100%", height="800px"),
                      absolutePanel(id = "controls", class = "panel panel-default",
                                    top = 75, right = 55, width = 200,
                                    draggable = TRUE, height = "0%",
                                    sliderInput(inputId = "num", 
                                                label = "Choisissez des Jour", min = 1, max = 30, value = range(dat$time.day), step = 1
                                    ),
                                    sliderInput("range", "Magnitudes", min(dat$impact.magnitude), max(dat$impact.magnitude),value = range(dat$impact.magnitude), step = 0.1
                                    ),
                                    selectInput("colors", "Palette de Couleur",
                                                rownames(subset(brewer.pal.info, category %in% c("seq", "div")))
                                    ),
                                    checkboxInput("legend", "Afficher Légende", TRUE)
                                    
                      )),
             tabPanel(title = "Statistiques",
                      headerPanel('Histogramme des magnitudes des séismes'),
                      sidebarLayout(
                        sidebarPanel(
                          sliderInput(inputId = "num1", 
                                      label = "Choisissez des Jours", 
                                      min = 1, max = 30, value = range(dat$time.day), step = 1
                          ),
                          selectInput('ctn', 'Continents', location.continent.unique
                          ),
                          sliderInput(inputId = "brk", 
                                      label = "Nombre de Pas", 
                                      value = 25, min = 1, max = 80
                          )
                        ),
                        mainPanel(plotOutput("hist")
                        )),
                      verbatimTextOutput("stats"
                      ),
                      plotOutput('boxplot2')
             ),
             tabPanel("Modèle prédictif"
             ),
             tabPanel("Data", DT::dataTableOutput("data")
             ),
             tabPanel("Read Me",includeMarkdown("Readme.Rmd")
             )
             ))
#######################################################################################################

server <- function(input, output, session) {
  
  #data
  output$data <-DT::renderDataTable(datatable(data = dat[,-c(7,8)]))
  
  ### histogramme
  
  library(shiny)
  library(plotly)
  
  # ...
  output$hist <- renderPlot({
    if(input$ctn==location.continent.unique[8]){
      ggplot(dat[dat$time.day >=input$num1[1] & dat$time.day <= input$num1[2],], aes(impact.magnitude, fill = location.continent)) + 
        geom_histogram(color="darkblue",bins = input$brk, position = 'identity')+
        scale_color_manual(values=brewer.pal(6, "Set2"))+
        scale_fill_manual("Continent", values=brewer.pal(6, "Set2"))+
        labs(x="Magnitude", y = "Fréquence")
    }
    else if(input$ctn==location.continent.unique[7]){
      ggplot(dat[dat$time.day >=input$num1[1] & dat$time.day <= input$num1[2],],aes(x = impact.magnitude))+
        geom_histogram( color="darkblue",fill="#009999",bins = input$brk)+
        labs(x="Magnitude", y = "Fréquence")
    }
    else{
      ggplot(dat[dat$time.day >=input$num1[1] & dat$time.day <= input$num1[2] & dat$location.continent == input$ctn,],aes(x = impact.magnitude))+
        geom_histogram( color="darkblue",fill="#009999",bins = input$brk)+
        labs(x="Magnitude", y = "Fréquence")
    }
  })
  
  
  ###stat
  
  output$stats <- renderPrint({
    if(input$ctn != location.continent.unique[7] || location.continent.unique[8]){
      K<-subset(dat$impact.magnitude,dat$time.day>=input$num1[1] & dat$time.day<=input$num1[2] & dat$location.continent == input$ctn,"impact.magnitude")
    }
    summary(K)
  })
  
  ###boxplot 2
  
  
  output$boxplot2<-renderPlot({
    if(input$ctn==location.continent.unique[8]){
      ggplot(data = dat[dat$time.day >=input$num1[1] & dat$time.day <= input$num1[2],])+
        geom_boxplot(aes(x = location.continent, y = impact.magnitude ))+
        geom_jitter(aes(x = location.continent, y = impact.magnitude),color = "#009999",alpha = 0.2)+
        labs(x="Continent", y = "Fréquence")
    }
    else if(input$ctn==location.continent.unique[7]){
      ggplot(data = dat[dat$time.day >=input$num1[1] & dat$time.day <= input$num1[2],])+
        geom_boxplot(aes(x = input$ctn, y = impact.magnitude ))+
        geom_jitter( aes(x = input$ctn, y = impact.magnitude),color = "#009999",alpha = 0.2)+
        labs(x="Continent", y = "Fréquence")
    }
    
    else {
      ggplot(data = dat[dat$time.day >=input$num1[1] & dat$time.day <= input$num1[2] & dat$location.continent==input$ctn,])+
        geom_boxplot(aes(x = input$ctn, y = impact.magnitude ))+
        geom_jitter( aes(x = input$ctn, y = impact.magnitude),color = "#009999",alpha = 0.2)+
        labs(x="Continent", y = "Fréquence")
    }
  })
  
  
  # Reactive expression for the data subsetted to what the user selected
  filteredData <- reactive({
    r<-dat[dat$impact.magnitude >= input$range[1] & dat$impact.magnitude<=input$range[2],]
    r<-r[r$time.day >=input$num[1] & r$time.day <= input$num[2],]
  })
  
  # This reactive expression represents the palette function,
  # which changes as the user makes selections in UI.
  colorpal <- reactive({
    colorNumeric(input$colors, dat$impact.significance)
  })
  
  output$map <- renderLeaflet({
    # Use leaflet() here, and only include aspects of the map that
    # won't need to change dynamically (at least, not unless the
    # entire map is being torn down and recreated).
    leaflet(dat) %>% addTiles() %>%
      fitBounds(~min(long), ~min(lat), ~max(long), ~max(lat))
  })
  
  # Incremental changes to the map (in this case, replacing the
  # circles when a new color is chosen) should be performed in
  # an observer. Each independent set of things that can change
  # should be managed in its own observer.
  observe({
    pal <- colorpal()
    
    leafletProxy("map", data = filteredData()) %>%
      clearShapes() %>%
      addCircles(radius = ~size_circle(impact.magnitude), weight = 0.2, color = "#777777",
                 fillColor = ~pal(impact.significance), fillOpacity = 0.7, 
                 popup = ~paste("<b> id : </b>",id, "<br>",
                                "<b> magnitude : </b>",impact.magnitude, "<br>",
                                "<b> dégats : </b>", impact.significance, "<br>",
                                "<b> profondeur : </b>",location.depth,"<br>",
                                "<b> date : </b>",time.day, "/062016", "<br>")
      )
  })
  # Use a separate observer to recreate the legend as needed.
  observe({
    proxy <- leafletProxy("map", data = dat)
    
    # Remove any existing legend, and only if the legend is
    # enabled, create a new one.
    proxy %>% clearControls()
    if (input$legend) {
      pal <- colorpal()
      proxy %>% addLegend(position = "bottomright",
                          pal = pal, values = ~impact.significance,
                          title = "Dégâts"
      ) 
    }
  })
}

shinyApp(ui, server)

