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
hdfs dfs -put /tmp/ /input_data/raw
```

## 3. Comparer MapReduce avec Spark
 Recréer une structure des données en production sur HDFS.

3.1- Compter le nbre d’occurence de mots/ventes dans un fichier stocké sur HDFS avec MapReduce .

3.2- Reproduire le même traitement avec Spark, montrer les gains en simplicité et performances.



## Arborescence du projt
```          
├── data
│   └── wordcount.txt                      Données pour qu'on puisse compter les mots
├── docker-compose.yml                     Fichier docker-compose
├── hadoop_config                          Répertoire contient des configurations des nodes
│   ├── core-site.xml                      Configurations fondamentales d'Hadoop, notamment le système de fichiers par défaut
│   ├── hdfs-site.xml                      Configurations spécifiques à HDFS
│   ├── log4j.properties                   Configurations de logs
│   ├── mapred-site.xml                    Configurations de MapReduce
│   └── yarn-site.xml                      Configurations de YARN, le gestionnaire de ressources d'Hadoop
├── README.md
├── hadoop_datanode1                       Volume de datanode1
├── hadoop_datanode2                       Volume de datanode1
├── hadoop_namenode                        Volume de namenode
├── init-datanode.sh                       Script pour l'initialisation des datanodes
└── start-hdfs.sh                          Script pour l'initialisation de namenode
```