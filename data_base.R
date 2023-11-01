#############
# Data base #
#############

# package
library(dplyr)

#### import de la base de données brut ###

dat<-read.csv("earthquakes.csv")
colnames(dat) <- c("id", "location.gap", "impact.magnitude", "impact.significance", "location.depth", "location.distance", "name", "lat", "long","state", "time.day", "epoch", "time", "hour", "minute", "month","second", "year")

#### traitement de la base de données ###

# on crée des classes pour dep et mag (profondeur et magnitude)
# dat <- transform(dat, 
#   impact.depth = ifelse(Depth <= 30, "faible", ifelse(impact.depth <= 70, "moyenne", "élevée")),
#   impact.magnitude = cut(impact.magnitude, breaks = c(0, 1, 2, 3, 4, 5, 6, Inf), labels = c("0", "0-1", "1-2", # "2-3", "3-4", "4-5", "5-6"))
# )

# on convertit location.latitude/long en pays et continent
coords2region <- function(points, get_country = TRUE) {
  countriesSP <- getMap(resolution = 'low')
  pointsSP = SpatialPoints(points, proj4string = CRS(proj4string(countriesSP)))
  indices = over(pointsSP, countriesSP)
  if (get_country) {
    return(indices$ADMIN)
  } else {
    return(indices$REGION)
  }
}

points <- data.frame(long = dat$long, lat = dat$lat)

dat$location.country <- coords2region(points, get_country = TRUE)
dat$location.continent <- coords2region(points, get_country = FALSE)

# cas : significance >1000
dat <- dat %>% 
  mutate(impact.significance = ifelse(impact.significance > 1000, 1000, impact.significance)) %>%
  mutate (location.continent = coalesce(location.continent, "Water")) %>%
  mutate (location.country = coalesce(location.country, "Water"))

location.continent.unique <- unique(dat$location.continent)

# conversion du jour 
dat$time.day <- (dat$time.day + 5) %% 31


# choix des colonnes interessantes
dat <- dat[,c(1,2,3,4,5,6,8,9,11,19,20)]

# on ne garde que certianes valeurs si les données ne sont pas safe
dat <- dat[!(dat$location.depth > quantile(dat$location.depth, probs = 0.75) | dat$location.gap > 180), ]

# on enlève les NAs
dat <- na.omit(dat)

View(dat)

