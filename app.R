library(shiny)
library(leaflet)
library(RColorBrewer)
library(sp)
library(rworldmap)
library(shinythemes)
library(ggplot2)
library(DT)
library(randomForest)


names<-c("mag","dep","sig")

dat <- read.csv("earthquakes.csv")

colnames(dat) <- c("id", "gap", "mag", "sig", "dep", "dist", "name", "lat", "long",
                   "state", "day", "epoch", "time", "hour", "minute", "month",
                   "second", "year")

dat$nday <- (dat$day + 5) %% 31

dat$mag_catego <- factor(floor(dat$mag))

dat$continentbis<- ifelse(dat$long< -20,"Amérique du Nord & Sud",
                          ifelse(dat$long<60,"Europe & Afrique","Asie & Océanie"))

contbis<-c("Amérique du Nord & Sud","Europe & Afrique","Asie & Océanie","Tous","Comparaison")

### Matrice
nbQuakes <- matrix(rep(0, 90), nrow = 30, ncol = 3)
avMag <- matrix(rep(0, 90), nrow = 30, ncol = 3)
avDeg <- matrix(rep(0, 90), nrow = 30, ncol = 3)
for(i in 1:8394){
  if(dat$continentbis[i] == "Amérique du Nord & Sud"){
    j <- 1
  }
  if(dat$continentbis[i] == "Europe & Afrique"){
    j <- 2
  }
  if(dat$continentbis[i] == "Asie & Océanie"){
    j <- 3
  }
  nbQuakes[dat$nday[i], j] <- nbQuakes[dat$nday[i], j] + 1
  avMag[dat$nday[i], j] <- avMag[dat$nday[i], j] + dat$mag[i]
  avDeg[dat$nday[i], j] <- avDeg[dat$nday[i], j] + dat$sig[i]
}

for(i in 1:30){
  for(j in 1:3){
    if(nbQuakes[i, j] != 0){
      avMag[i, j] <- avMag[i, j] / nbQuakes[i ,j]
      avDeg[i, j] <- avDeg[i, j] / nbQuakes[i, j]
    }
  }
}

col1 <- c()
col2 <- c()
col3 <- c()

for(i in 1:30){
  col1[i] <- nbQuakes[i, 1] + nbQuakes[i, 2] + nbQuakes[i, 3]
  col2[i] <- (avMag[i, 1] + avMag[i, 2] + avMag[i, 3])/3
  col3[i] <- (avDeg[i, 1] + avDeg[i, 2] + avDeg[i, 3])/3
}

nbQuakes <- cbind(nbQuakes, col1)
avMag <- cbind(avMag, col2)
avDeg <- cbind(avDeg, col3)

colnames(nbQuakes) <- c("Amérique du Nord & Sud", "Europe & Afrique",
                        "Asie & Océanie", "Tous")

colnames(avMag) <- c("Amérique du Nord & Sud", "Europe & Afrique",
                     "Asie & Océanie", "Tous")

colnames(avDeg) <- c("Amérique du Nord & Sud", "Europe & Afrique",
                     "Asie & Océanie", "Tous")

# Fontion pour donner la taille des cercles sur le leaflet

size <- function(x){
  if(x <= 1.5){
    return(5000)
  }
  if(x <= 3){
    return(12500)
  }
  return(x^7)
}
size <- Vectorize(size)

cont <- c("Europe", "Oceania", "America", "Asia", "Africa")

mth<-function(x){
  return(paste("0",as.character(x),sep=""))
}

dat$sig[7917]=1000

# Supposons que votre jeu de données est stocké dans un data frame appelé "seismes"

# Spécifiez les limites des intervalles pour les catégories
limites_categories <- c(0, 5, 7, Inf)  # Vous pouvez ajuster ces valeurs selon vos critères de catégorisation

# Utilisez la fonction cut() pour créer la colonne "magnitude_categorie"
dat$magnitude_categorie <- cut(dat$mag, 
                                   breaks = limites_categories,
                                   labels = c("Faible", "Modérée", "Élevée"),
                                   right = FALSE)  # Utilisez right = FALSE pour exclure la limite supérieure


###Machine learning###
set.seed(123)

train_index <- sample(1:nrow(dat), 0.7 * nrow(dat))

train_data <- dat[train_index,]
test_data <- dat[-train_index,]

rf_model <- randomForest(sig ~ dep + continentbis, data = train_data)
rf_model

predictions <- predict(rf_model, newdata = test_data)

rmse <- sqrt(mean((predictions- test_data$sig)^2))
print(paste("erreur quadratique moyenne : ", rmse))

#######################################################################################################



#######################################################################################################

ui <- bootstrapPage(
  navbarPage(theme = shinytheme("flatly"),title = "Etude Spatio-Temporelle de Séismes",
             tabPanel(title = "Carte",
                      leafletOutput("map", width="100%", height="800px"),
                      absolutePanel(id = "controls", class = "panel panel-default",
                                    top = 75, right = 55, width = 200,
                                    draggable = TRUE, height = "0%",
                                    sliderInput(inputId = "num", 
                                                label = "Choisissez des Jour", min = 1, max = 30, value = range(dat$nday), step = 1
                                    ),
                                    sliderInput("range", "Magnitudes", min(dat$mag), max(dat$mag),value = range(dat$mag), step = 0.1
                                    ),
                                    selectInput("colors", "Palette de Couleur",
                                                rownames(subset(brewer.pal.info, category %in% c("seq", "div")))
                                    ),
                                    checkboxInput("legend", "Afficher Légende", TRUE)
                                    
                      )),
             tabPanel(title = "Plot",
                      headerPanel('Evolution du nombre de séismes au cours du temps'),
                      sidebarLayout(
                        sidebarPanel(
                          selectInput('ycol', 'Continents', contbis),
                          checkboxInput("cum","Cumulé",TRUE)),
                        mainPanel(plotOutput('plot1'))),
                      plotOutput('plot100')
                      
             ),
             
             tabPanel(title = "Histogramme",
                      headerPanel('Histogramme des magnitudes des séismes'),
                      sidebarLayout(
                        sidebarPanel(
                          sliderInput(inputId = "num1", 
                                      label = "Choisissez des Jours", 
                                      min = 1, max = 30, value = range(dat$nday), step = 1
                          ),
                          selectInput('ctn', 'Continents', contbis
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
             tabPanel("Machine learning"
             ),
             tabPanel("Data", DT::dataTableOutput("data")
             ),
             tabPanel("Read Me",includeMarkdown("Readme.Rmd")
             )
             ))
#######################################################################################################

server <- function(input, output, session) {
  
  #data
  output$data <-DT::renderDataTable(datatable(dat[,-c(2,6,7,11,12,13,14,15,16,17,18,20,22,24)],filter='top',
    colnames = c("id", "mag", "sig", "dep", "lat", "long","state", "day","continentbis","country"))
  )
  
  ### Plot
  
  output$plot1 <- renderPlot({
    if(input$cum){
     if(input$ycol == contbis[5]){
        ggplot() +
          geom_point(
            aes(x = c(1:30), y = cumsum(nbQuakes[,1]), color = avDeg[,1]), 
            size = avMag[,1])+
          geom_point(
            aes(x = c(1:30), y = cumsum(nbQuakes[,2]),color = avDeg[,2], 
                size = avMag[,2]))+
          geom_point(
            aes(x = c(1:30), y = cumsum(nbQuakes[,3]),color = avDeg[,3], 
                size = avMag[,3])) +
          scale_color_viridis_c("Dégâts Moyens", option = "magma") +
          labs(x = "Jour d'Observation", y = "Nombre de Séismes", size = "Magnitude Moyenne")}
      else{
        ggplot() +
          geom_point(
            aes(x = c(1:30), y = cumsum(nbQuakes[,input$ycol]),color = avDeg[,input$ycol], 
                size = avMag[,input$ycol]))+
          scale_color_viridis_c("Dégâts Moyens", option = "magma") +
          labs(x="Jour d'Observation", y = "Nombre de Séismes", size = "Magnitude Moyenne")
      }
    }
    else{
      if(input$ycol==contbis[5]){
        ggplot() +
          geom_point(
            aes(x = c(1:30), y = nbQuakes[,1],color = avDeg[,1], 
                size = avMag[,1]))+
          geom_point(
            aes(x = c(1:30), y = nbQuakes[,2],color = avDeg[,2], 
                size = avMag[,2]))+
          geom_point(
            aes(x = c(1:30), y = nbQuakes[,3],color = avDeg[,3], 
                size = avMag[,3]))+
          scale_color_viridis_c("Dégâts Moyens", option = "magma") +
          labs(x="Jour d'Observation", y = "Nombre de Séismes", size = "Magnitude Moyenne")
      }
      else{
        ggplot() +
          geom_point(
            aes(x = c(1:30), y = nbQuakes[,input$ycol],color = avDeg[,input$ycol], 
                size = avMag[,input$ycol])
          )+
          scale_color_viridis_c("Dégâts Moyens", option = "magma") +
          labs(x="Jour d'Observation", y = "Nombre de Séismes", size = "Magnitude Moyenne")
      }
    }})
  
  
  ### histogramme
  
  output$hist <- renderPlot({
    if(input$ctn==contbis[5]){
      ggplot(dat[dat$nday >=input$num1[1] & dat$nday <= input$num1[2],], aes(mag, fill = continentbis)) + 
        geom_histogram(color="darkblue",bins = input$brk, position = 'identity')+
        scale_color_manual(values=brewer.pal(3, "Set2"))+
        scale_fill_manual("Continent", values=brewer.pal(3, "Set2"))+
        labs(x="Magnitude", y = "Fréquence")
    }
    else if(input$ctn==contbis[4]){
      ggplot(dat[dat$nday >=input$num1[1] & dat$nday <= input$num1[2],],aes(x = mag))+
        geom_histogram( color="darkblue",fill="#009999",bins = input$brk)+
        labs(x="Magnitude", y = "Fréquence")
    }
    else{
      ggplot(dat[dat$nday >=input$num1[1] & dat$nday <= input$num1[2] & dat$continentbis == input$ctn,],aes(x = mag))+
        geom_histogram( color="darkblue",fill="#009999",bins = input$brk)+
        labs(x="Magnitude", y = "Fréquence")
    }
  }) 
  
  ###stat
  
  output$stats <- renderPrint({
    if(input$ctn==contbis[4]){
      K<-subset(dat$temps,dat$day>=input$num1[1] & dat$day<=input$num1[2],"mag")
    }
    else{
      K<-subset(dat$mag,dat$day>=input$num1[1] & dat$day<=input$num1[2] & dat$continentbis == input$ctn,"mag")
    }
    summary(K)
  })
  
  ###boxplot 2
  
  
  output$boxplot2<-renderPlot({
    if(input$ctn==contbis[5]){
      ggplot(data = dat[dat$nday >=input$num1[1] & dat$nday <= input$num1[2],])+
        geom_boxplot(aes(x = continentbis, y = mag ),color = brewer.pal(3, "Set2"))+
        geom_jitter(aes(x = continentbis, y = mag),color = "#009999",alpha = 0.2)+
        labs(x="Continent", y = "Fréquence")
    }
    else if(input$ctn==contbis[4]){
      ggplot(data = dat[dat$nday >=input$num1[1] & dat$nday <= input$num1[2],])+
        geom_boxplot(aes(x = input$ctn, y = mag ))+
        geom_jitter( aes(x = input$ctn, y = mag),color = "#009999",alpha = 0.2)+
        labs(x="Continent", y = "Fréquence")
    }
    else{
      ggplot(data = dat[dat$nday >=input$num1[1] & dat$nday <= input$num1[2] & dat$continentbis==input$ctn,])+
        geom_boxplot(aes(x = input$ctn, y = mag ))+
        geom_jitter( aes(x = input$ctn, y = mag),color = "#009999",alpha = 0.2)+
        labs(x="Continent", y = "Fréquence")
    }
  })
  
  
  # Reactive expression for the data subsetted to what the user selected
  filteredData <- reactive({
    r<-dat[dat$mag >= input$range[1] & dat$mag<=input$range[2],]
    r<-r[r$nday >=input$num[1] & r$nday <= input$num[2],]
  })
  
  # This reactive expression represents the palette function,
  # which changes as the user makes selections in UI.
  colorpal <- reactive({
    colorNumeric(input$colors, dat$sig)
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
      addCircles(radius = ~size(mag), weight = 0.2, color = "#777777",
                 fillColor = ~pal(sig), fillOpacity = 0.7, 
                 popup = ~paste("<b> id : </b>",id, "<br>",
                                "<b> magnitude : </b>",mag, "<br>",
                                "<b> dégats : </b>", sig, "<br>",
                                "<b> profondeur : </b>",dep,"<br>",
                                "<b> date : </b>",day, "/", mth(month), "<br>")
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
                          pal = pal, values = ~sig,
                          title = "Dégâts"
      ) 
    }
  })
}

shinyApp(ui, server)

