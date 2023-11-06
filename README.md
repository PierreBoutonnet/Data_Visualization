# Data visualization
👀 Projet data visualization ISUP

🚀 L'application *Earthquake🅁* est disponible [ici](https://pierreboutonnet.shinyapps.io/Data_Visualization_2/)

👾 Les membres du projet : Juliette, Maxence et Pierre

## Introduction
L'application *Earthquake🅁* est une app Rshiny, son objectif est de visualiser et d'étudier les séismes recueillis par le Service géologique des États-Unis en juin 2016. *Earthquake🅁* est composé de trois sections principales : 

1) Visualisation
* 🌍 Map, la carte du monde interactive pour visualiser la localisation et l'impact des séismes.
* 📊 Statistiques, ...

2) Modélisation et prédiction
* 🤖 Algorithme ML, ...
* 🛠️ Outils de prédiction,...

3) Data base
* 🔢 Data, ...

## Fonctionnement de Earthquake🅁

#### Map 
La carte du monde est entièrement interactive. Il est possible de zoommer et/ou de cliquer sur les séismes symbolisés par des cerlces de couleurs. En cliquant sur les séismes plusieurs informations s'affichent comme l'ID du séismes, sa magnitude et les dégats causés par celui-ci. 
Les deux sliders permettent de filtrer la base de données  par rapport à la période et la magnitude des séismes que l'utilisateur souhaite observer.
La palette de couleurs permet de modifier le gradient de couleur qui sert d'échelle pour les dégâts causé par les séismes (plus de 25 gradients de couleurs sont disponible). Le bouton "Afficher la légende" peut être coché ou décoché pour afficher ou non la légende.

#### Statistiques
...

#### Algorithme ML
...

#### Outils de prédiction

...

## Data base

La base de données utilisée pour réaliser ce projet est disponible [ici](https://corgis-edu.github.io/corgis/csv/earthquakes/). 
#### Descrition 
Dans cette partie nous décrirons succinctement la base de données (une descrition plus complète est disponible [ici](https://corgis-edu.github.io/corgis/csv/earthquakes/)).

La base de données initiale 'earthquake.csv' recense 8394 séismes enregistrés par le Service géologique des États-Unis en juin 2016. Pour chaque séismes nous possèdons des informations sur la localisation, l'impacte et  la date pour un total de 18 variables. 

Pour le projet, nous avons fait le choix de garder suelement 9 variables.
* Id (string) : Un nom unique pour chaque séisme.
* Impact
  - gap (float) : Le plus grand écart azimutal entre des stations azimutalement adjacentes. (en degrés)
  - magnitude (float) : Une mesure sur la taille du séisme à sa source.
  - significance (integer) : Un nombre qui décrit l'ampleur du séisme. Cette valeur est déterminée par plusieurs facteurs comme la magnitude, le maximum MMI, le ressenti de la population, les dégâts matériels et humains.
* Location
  - depth (float) : profondeur de l'épicentre du séismes (en km).
  - longitude (float) : longitude du séisme
  - latitude (float) : latitude du séisme
  - distance (float) : The rough distance that this earthquake occurred away from the reporting station.
* Time
  - day (int)
 
Les variables impact.gap et location.distance sont conservées pour filtrer notre base de données et garder uniquement les sésimes "fiables". En effet, on retire de la base de données les séismes qui ont un gap > 180° ou distance > 7.1° car au dela de ces valeurs les données enregistrées sont moins fiables.

En utlisant le package Rworlmap, nous avons converti les données location.longitude et location.latitude en location.country (pays où a eu lieu le sésisme). Cela permet une meilleure comprehension et visualisation de nos données.







  


.
.






