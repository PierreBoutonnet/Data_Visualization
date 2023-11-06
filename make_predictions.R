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

