# Mise en place et configuration d'un datalake Hadoop

## Contexte du projet
En tant que data Engineer, votre entreprise utilise un Data Lake basé sur l’écosystème Hadoop (HDFS, Hive, Spark).

L’objectif global est de reproduire cet environnement dans un cluster de développement pour tester de nouvelles fonctionnalités ou valider des traitements de données avant leur déploiement en production.


Les objectifs de ce brief :


* Introduction et mise en place du framework hadoop

* Se familiariser avec le Pattern MapReduce,

* écrire un algorithme Mapr/reduce de WordCount

* Code cet algorithme wordount en python

* Tester l’exemple en local

*Tester l’exemple sur HDFS (sur le cluster Hadoop installé)



## 1. Installation de l’environnement Hadoop
Installer un cluster Hadoop en environnement de développement/test.

### 1.1 Déploiement d’un cluster Hadoop Local

### 1.2 Bonus: Cluster multi-nœuds

Pour démarrer les containers Docker, l'instructure contient cluster d'un namenode et deux datanodes

```bash
docker-compose -up -d
```


## 2. Reproduction de l’arborescence HDFS
 Recréer une structure des données en production sur HDFS.

### 2.1 Créer les répertoires HDFS nécessaires (/data/raw, /data/processed, /data/analytics).

Pour créer les répertoire HDFS:

 1. Lancher le shell de container namenode
```bash
docker exec -it namenode bash
```

2. Créer les répertoire

```bash 
hdfs dfs -mkdir -p /input_data/raw

hdfs dfs -mkdir -p /input_data/processed

hdfs dfs -mkdir -p /input_data/analytics
```

### 2.2 Charger un ensemble de données de test dans ces répertoires (fichiers CSV, JSON ou Parquet).
Pour charger les données dans HDFS, il faut faire en 2 étapes:
    
1. Copier les données dans le container Docker

```bash
docker cp input_data/wordcount.txt namenode: /tmp/
```

2. Charger ces données dans le HDFS

```bash
hdfs dfs -put /tmp/* /input_data/raw
```

## 3. Comparer MapReduce avec Spark
 Recréer une structure des données en production sur HDFS.

3.1- Compter le nbre d’occurence de mots/ventes dans un fichier stocké sur HDFS avec MapReduce .

3.2- Reproduire le même traitement avec Spark, montrer les gains en simplicité et performances.



## Arborescence du projt
```          
├── Dockerfile             Image Docker pour tourner le clustervHadoop et Spark
├── README.md
├── apps_output            Volume pour la sortie des données processed
├── docker-compose.yml     docker-compose pour l'ensemble de l'architecture
├── hadoop_config          Configuration pour l'architecture Hadoop
│   ├── capacity-scheduler.xml
│   ├── core-site.xml
│   ├── hdfs-site.xml
│   ├── log4j.properties
│   ├── mapred-site.xml
│   └── yarn-site.xml
├── input_data             Données d'entrée
│   └── wordcount.txt      Fichier à compter l'occurence des mots
├── python_scripts         Répertoire pour les scripts Python
│   ├── mapper.py          Script python pour la partie Map du Mapreduce
│   ├── reducer.py         Script python pour la partie Reduce du Mapreduce
│   └── run_spark.py       Script python pour exécuter pyspark
├── start-namenode.sh      Script pour démarrer le namenode
└── wordcount-job.sh       Script pour initialiser l'arborescence dans HDFS, copie des fichiers jars dans HDFS et exécuter les scripts Python
```