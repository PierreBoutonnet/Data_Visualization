# Installer les packages nécessaires si vous ne les avez pas déjà
install.packages("caret")
install.packages("randomForest")

# Charger les bibliothèques
library(caret)
library(randomForest)

# Charger vos données de séismes (supposons que les données sont dans un data frame appelé "seismes")
# Assurez-vous que votre jeu de données contient une colonne "gravite" indiquant la gravité (par exemple, 0 pour faible, 1 pour élevée)

# Diviser les données en ensembles d'entraînement et de test
set.seed(123)  # Pour rendre les résultats reproductibles
trainIndex <- createDataPartition(seismes$gravite, p = 0.8, 
                                  list = FALSE,
                                  times = 1)
data_train <- seismes[trainIndex, ]
data_test <- seismes[-trainIndex, ]

# Créer le modèle de forêt aléatoire
model <- randomForest(gravite ~ magnitude + longitude + latitude + profondeur, data = data_train)

# Faire des prédictions sur l'ensemble de test
predictions <- predict(model, data_test)

# Évaluer la performance du modèle
confusionMatrix(predictions, data_test$gravite)

# Vous pouvez maintenant utiliser ce modèle pour prédire la gravité des séismes
# par exemple, si vous avez de nouvelles données de séismes dans un data frame "nouveaux_seismes"
new_predictions <- predict(model, nouvelles_seismes)

# Afficher la matrice de confusion
confusionMatrix(new_predictions, nouvelles_seismes$gravite)
