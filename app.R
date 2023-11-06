library(shiny)
library(leaflet)
library(RColorBrewer)
library(sp)
library(rworldmap)
library(shinythemes)
library(ggplot2)
library(DT)
library(plotly)
library(randomForest)
library(caret)
library(dplyr)
library(plotly)

################################################################################
######################
###Machine learning###
######################

# Définir le taux de division (par exemple, 70% pour l'entraînement, 30% pour les tests)
train_proportion <- 0.7

# Créer l'ensemble de données d'entraînement et de test
set.seed(123)  # Pour la reproductibilité
splitIndex <- createDataPartition(dat$impact.significance, p = train_proportion, list = FALSE)
train_data <- dat[splitIndex, ]
test_data <- dat[-splitIndex, ]


# Création du modèle d'encodage one-hot
dummy_model_train <- dummyVars(~ location.country, data = train_data)
dummy_model_test <- dummyVars(~ location.country, data = test_data)


# Transformation des données d'entraînement
train_data_encoded <- predict(dummy_model_train, newdata = train_data)
test_data_encoded <- predict(dummy_model_test, newdata = test_data)


# Supposons que vous ayez un ensemble de données train_data avec les variables "profondeur" et "magnitude"

# Calcul des moyennes et écarts-types des variables
mean_depth <- mean(train_data$location.depth)
sd_depth <- sd(train_data$location.depth)

mean_magnitude <- mean(train_data$impact.magnitude)
sd_magnitude <- sd(train_data$impact.magnitude)

# Standardisation (z-score) des variables
train_data$impact.depth_standardisee <- (train_data$location.depth - mean_depth) / sd_depth
train_data$impact.magnitude_standardisee <- (train_data$impact.magnitude - mean_magnitude) / sd_magnitude
test_data$impact.depth_standardisee <- (test_data$location.depth - mean_depth) / sd_depth
test_data$impact.magnitude_standardisee <- (test_data$impact.magnitude - mean_magnitude) / sd_magnitude
# Extraire les noms de colonnes de la première ligne de la matrice
colnames <- as.character(train_data_encoded[1, ])
colnames <- as.character(test_data_encoded[1, ])

# Créer un data frame avec les noms de colonnes et les données de la matrice
train_data_encoded <- as.data.frame(train_data_encoded, col.names = colnames)
test_data_encoded <- as.data.frame(test_data_encoded, col.names = colnames)

train_data_encoded$impact.significance <- train_data$impact.significance
train_data_encoded$impact.depth_standardisee <- train_data$impact.depth_standardisee
train_data_encoded$impact.magnitude_standardisee <- train_data$impact.magnitude_standardisee

test_data_encoded$impact.significance <- test_data$impact.significance
test_data_encoded$impact.depth_standardisee <- test_data$impact.depth_standardisee
test_data_encoded$impact.magnitude_standardisee <- test_data$impact.magnitude_standardisee


# Enlevez les espaces dans les noms des colonnes
colnames(train_data_encoded) <- gsub(" ", "", colnames(train_data_encoded))
colnames(test_data_encoded) <- gsub(" ", "", colnames(test_data_encoded))

# Obtenez la liste des noms de colonnes communes
common_columns <- intersect(colnames(test_data_encoded), colnames(train_data_encoded))

# Extrait uniquement les colonnes communes de df1 et df2
test_data_encoded_common <- test_data_encoded[, common_columns]
train_data_encoded_common <- train_data_encoded[, common_columns]

# Les variables "profondeur_standardisee" et "magnitude_standardisee" sont maintenant standardisées

rf_model <- randomForest(impact.significance ~ impact.depth_standardisee + impact.magnitude_standardisee + ., data = train_data_encoded_common)

predictions <- predict(rf_model, newdata = test_data_encoded_common)

rmse <- sqrt(mean((predictions - test_data_encoded$impact.significance)^2))
print(paste("erreur quadratique moyenne : ", rmse))

### Graphique fitted vs true ###
# Créez un data frame avec les valeurs réelles et prédites
results <- data.frame(True = test_data_encoded_common$impact.significance, Fitted = predictions)

# Créez un graphique fitted vs. true avec ggplot2
gg<-ggplot(results, aes(x = True, y = Fitted)) +
  geom_point() +                  # Affichez les points
  geom_abline(intercept = 0, slope = 1, color = "red") +  # Ajoutez une ligne de référence (y=x)
  labs(x = "Valeurs Réelles (True)", y = "Valeurs Prédites (Fitted)") +
  ggtitle("Fitted vs. True Plot")


################################################################################
### Outil de prédiction ###

# Objets utiles (disponible dans "machine_learing.R")
# train_data_encoded (data.frame)
# mean_depth/magnitude (float) (utile pour standardisee depth et magnitude)
# sd_float/magniutde (float) (idem)
# rf_model (modèle ML RandomForest)

# liste des noms
liste_noms_colonnes <- c(colnames(train_data_encoded))

# Fonction qui calcul les "dégats" en fonction des inputs : country, depth, magnitude
make_predictions <- function(country, depth, magnitude) {
  nouveau_data_frame <- data.frame(matrix(0, nrow = 1, ncol = length(liste_noms_colonnes)))
  colnames(nouveau_data_frame) <- liste_noms_colonnes
  nom_complet_country <- gsub(" ", "", country)
  nom_complet_country <- paste("location.country", nom_complet_country, sep = "")
  if (nom_complet_country %in% colnames(nouveau_data_frame)) {
    # Si le nom du pays correspond à une colonne, attribuez 1 à cette colonne
    nouveau_data_frame[[nom_complet_country]] <- ifelse(nouveau_data_frame[[nom_complet_country]] == 0, 1, nouveau_data_frame[[nom_complet_country]])
  }
  nouveau_data_frame$impact.depth_standardisee = (depth -  mean_depth) / sd_depth
  nouveau_data_frame$impact.magnitude_standardisee = (magnitude - mean_magnitude) / sd_magnitude
  prediction <- predict(rf_model, newdata = nouveau_data_frame)
  return(prediction)
}


################################################################################

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


################################################################################

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
             tabPanel("Algorithme ML",includeHTML("machine_learning.html")
             ),
             tabPanel("Outils de prédiction",
                      sidebarLayout(
                        sidebarPanel(
                          selectInput("country_input", "Pays", choices = unique(train_data$location.country)),
                          numericInput("depth_input", "Profondeur de l'épicentre", min = 0, value = 0),
                          numericInput("magnitude_input", "Magnitude", min = 0, value = 0),
                          actionButton("predict_button", "Effectuer la Prédiction")
                        ),
                        mainPanel(
                          textOutput("text_output"),
                          verbatimTextOutput("prediction_output")
                        )
                      )),
             tabPanel("Data", DT::dataTableOutput("data")
             )
  ))


################################################################################

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
      ggplot(aes(x = input$ctn, y = impact.magnitude ))+
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
  observe({
    
  })
  observeEvent(input$predict_button, {
    # Récupérer les valeurs d'entrée
    input_country <- input$country_input
    input_depth <- input$depth_input
    input_magnitude <- input$magnitude_input
    
    # Faites des prédictions avec votre modèle (à adapter)
    prediction <- make_predictions(input_country, input_depth, input_magnitude)
    output$prediction_output <- renderText({
      paste("Prédiction :", prediction)  # Personnalisez le texte de sortie selon vos besoins
      })
  })
  output$text_output <- renderText({
    "L'outils de prédiction est basé sur l'algorithme Random Forest (présenté dans l'onglet algoritme ML)"
  })
}

shinyApp(ui, server)

