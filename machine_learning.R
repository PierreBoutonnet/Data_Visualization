#install.packages("caret")
#install.packages("randomForest")

library(randomForest)
library(caret)
library(dplyr)
library(plotly)

summary(dat$impact.significance)
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

ggplotly(gg)
