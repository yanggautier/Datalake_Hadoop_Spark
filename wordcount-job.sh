#!/bin/bash

# Configuration
HADOOP_HOME=/opt/hadoop
HDFS_INPUT_DIR=/data/raw
HDFS_OUTPUT_DIR=/data/processed
LOCAL_INPUT_FILE=/tmp/wordcount.txt

# Attendre que HDFS sorte du mode sans échec
echo "Attente de la disponibilité de HDFS..."
until $HADOOP_HOME/bin/hdfs dfsadmin -safemode get | grep "Safe mode is OFF"; do
  echo "HDFS est en mode sans échec, attente..."
  sleep 5
done
echo "HDFS est prêt."

echo "Démarrage du job WordCount Python..."

# Créer le répertoire d'entrée HDFS s'il n'existe pas
$HADOOP_HOME/bin/hdfs dfs -mkdir -p $HDFS_INPUT_DIR

# Nettoyer le répertoire de sortie s'il existe
echo "Nettoyage du répertoire de sortie..."
$HADOOP_HOME/bin/hdfs dfs -rm -r -f $HDFS_OUTPUT_DIR

# Copier le fichier d'entrée vers HDFS
echo "Copie du fichier d'entrée vers HDFS..."
$HADOOP_HOME/bin/hdfs dfs -put -f $LOCAL_INPUT_FILE $HDFS_INPUT_DIR/

# Rendre les scripts Python exécutables
chmod +x /python_scripts/mapper.py
chmod +x /python_scripts/reducer.py

# Exécuter le job WordCount avec Hadoop Streaming
echo "Exécution du job WordCount Python avec Hadoop Streaming..."
$HADOOP_HOME/bin/hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-*.jar \
    -files /python_scripts/mapper.py,/python_scripts/reducer.py \
    -mapper mapper.py \
    -reducer reducer.py \
    -input $HDFS_INPUT_DIR/wordcount.txt \
    -output $HDFS_OUTPUT_DIR


# Vérifier les résultats
echo "Résultats du WordCount Python :"
$HADOOP_HOME/bin/hdfs dfs -cat $HDFS_OUTPUT_DIR/part-00000 

echo "Job WordCount Python terminé avec succès !"

echo "Exécution du job WordCount avec Spark"
$HADOOP_HOME/bin/hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-*.jar \
    -files /python_scripts/mapper.py,/python_scripts/reducer.py \
    -mapper mapper.py \
    -reducer reducer.py \
    -input $HDFS_INPUT_DIR/wordcount.txt \
    -output $HDFS_OUTPUT_DIR

# Garder le container en vie pour inspection
tail -f /dev/null