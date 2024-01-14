# Projet de Data Visualization sur les Séismes

👾 Les membres du projet : Juliette, Maxence et Pierre

![Image](lien_vers_une_image.png) <!-- Ajoutez une image représentative de votre projet -->
![Capture d'écran de l'application](/Users/boutonnet/Desktop/Capture d’écran 2024-01-14 à 01.45.18.png)

## Aperçu

L'application Earthquake🅁 est une application R Shiny qui a pour objectif de visualiser et d'analyser les données sur les séismes collectées par le Service géologique des États-Unis en juin 2016.

🚀 L'application *Earthquake🅁* est disponible [ici](https://pierreboutonnet.shinyapps.io/Data_Visualization_2/)

## Fonctionnalités

Earthquake🅁 est divisé en trois sections principales:

### Visualisation

#### Carte Interactive

- La carte du monde est entièrement interactive, permettant aux utilisateurs de zoomer et de cliquer sur les séismes représentés par des cercles colorés.
- En cliquant sur un séisme, plusieurs informations s'affichent, telles que l'ID du séisme, sa magnitude et les dégâts causés.
- Deux curseurs permettent de filtrer la base de données en fonction de la période et de la magnitude des séismes à observer.
- Une palette de couleurs personnalisable permet de modifier le gradient de couleur utilisé pour représenter les dégâts causés par les séismes.
- L'option "Afficher la légende" permet de masquer ou d'afficher la légende de la carte.

### Statistiques

- (Ajoutez ici une description des fonctionnalités de la section Statistiques)

### Modélisation et Prédiction

- (Ajoutez ici une description des fonctionnalités de la section Modélisation et Prédiction)

## Description de la Base de Données

La base de données initiale, nommée 'earthquake.csv', contient des informations sur 8394 séismes enregistrés en juin 2016 par le Service géologique des États-Unis. Chaque séisme est caractérisé par 18 variables.

La base de données utilisée pour ce projet est accessible [ici](lien_vers_la_base_de_données).

Dans le cadre de ce projet, nous avons choisi de conserver uniquement 9 variables pour l'analyse:

1. `Id` (chaîne de caractères): Un identifiant unique pour chaque séisme.
2. `Impact` (ajoutez une description de cette variable).
3. `gap` (nombre décimal): Le plus grand écart azimutal entre des stations azimutalement adjacentes, en degrés.
4. `magnitude` (nombre décimal): Une mesure de la taille du séisme à sa source.
5. `significance` (entier): Un nombre qui décrit l'ampleur du séisme, déterminé par plusieurs facteurs tels que la magnitude, le maximum MMI, les dégâts matériels et humains, etc.
6. `Location` (ajoutez une description de cette variable).
7. `depth` (nombre décimal): La profondeur de l'épicentre du séisme, en kilomètres.
8. `longitude` (nombre décimal): La longitude du séisme.
9. `latitude` (nombre décimal): La latitude du séisme.
10. `distance` (nombre décimal): La distance approximative à laquelle le séisme s'est produit par rapport à la station de signalement.
11. `day` (entier): Le jour du mois où le séisme s'est produit.

Les variables `impact.gap` et `location.distance` sont utilisées pour filtrer la base de données et exclure les séismes dont les données sont moins fiables (avec un écart azimutal supérieur à 180° ou une distance supérieure à 7.1°).

De plus, en utilisant le package `Rworldmap`, nous avons converti les données de `location.longitude` et `location.latitude` en `location.country` (pays où le séisme a eu lieu), ce qui améliore la compréhension et la visualisation des données géographiques.




