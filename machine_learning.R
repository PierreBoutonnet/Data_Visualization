#install.packages("caret")
#install.packages("randomForest")

library(randomForest)

######################
###Machine learning###
######################
set.seed(123)

train_index <- sample(1:nrow(dat), 0.7 * nrow(dat))

train_data <- dat[train_index,]
test_data <- dat[-train_index,]

rf_model <- randomForest(sig ~ dep + continentbis, data = train_data)
rf_model

predictions <- predict(rf_model, newdata = test_data)

rmse <- sqrt(mean((predictions- test_data$sig)^2))
print(paste("erreur quadratique moyenne : ", rmse))

