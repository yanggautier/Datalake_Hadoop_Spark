#!/bin/bash

# Configuration
HADOOP_HOME=/opt/hadoop
HDFS_INPUT_DIR=/data/raw
HDFS_OUTPUT_DIR=/data/processed
LOCAL_INPUT_FILE=/tmp/wordcount.txt
CONTAINER_OUTPUT_DIR=/apps_output

# --- Initial Setup (unchanged) ---
echo "Attente de la disponibilité de HDFS..."
until $HADOOP_HOME/bin/hdfs dfsadmin -safemode get | grep "Safe mode is OFF"; do
  echo "HDFS est en mode sans écTchec, attente..."
  sleep 5
done
echo "HDFS est prêt."

echo "Démarrage du job WordCount Python..."

# Créer le répertoire d'entrée HDFS s'il n'existe pas
$HADOOP_HOME/bin/hdfs dfs -mkdir -p $HDFS_INPUT_DIR

# Nettoyer les répertoires de sortie HDFS
echo "Nettoyage des répertoires de sortie HDFS..."
$HADOOP_HOME/bin/hdfs dfs -rm -r -f $HDFS_OUTPUT_DIR/mapreduce_output
$HADOOP_HOME/bin/hdfs dfs -rm -r -f $HDFS_OUTPUT_DIR/spark_output # Ensure this matches run_spark.py output

# Copier le fichier d'entrée vers HDFS
echo "Copie du fichier d'entrée vers HDFS..."
$HADOOP_HOME/bin/hdfs dfs -put -f $LOCAL_INPUT_FILE $HDFS_INPUT_DIR/


# Ensure Spark JARs are in HDFS for spark.yarn.jars optimization
echo "Vérification et copie des JARs Spark vers HDFS..."
SPARK_JARS_HDFS_DIR="/spark-jars" # Make sure this variable is consistent

# --- IMPORTANT: Ensure the directory is created before attempting to list it ---
echo "Création du répertoire HDFS $SPARK_JARS_HDFS_DIR si nécessaire..."
$HADOOP_HOME/bin/hdfs dfs -mkdir -p "$SPARK_JARS_HDFS_DIR"
# Check if mkdir succeeded
if [ $? -ne 0 ]; then
  echo "Erreur: Impossible de créer le répertoire HDFS $SPARK_JARS_HDFS_DIR. Vérifiez les permissions ou l'état de HDFS."
  exit 1
fi
echo "Répertoire HDFS $SPARK_JARS_HDFS_DIR créé ou existant."


# Now that the directory is guaranteed to exist, we can check its contents
NUM_HDFS_JARS=$($HADOOP_HOME/bin/hdfs dfs -ls "$SPARK_JARS_HDFS_DIR" 2>/dev/null | grep -c "\.jar$")
NUM_LOCAL_JARS=$($SPARK_HOME/jars/ls -l 2>/dev/null | grep -c "\.jar$") # Added 2>/dev/null to suppress errors if jars dir is initially empty

echo "Nombre de JARs dans HDFS ($SPARK_JARS_HDFS_DIR): $NUM_HDFS_JARS"
echo "Nombre de JARs locaux ($SPARK_HOME/jars/): $NUM_LOCAL_JARS"


# If the HDFS directory is empty or has significantly fewer JARs than locally
if [ "$NUM_HDFS_JARS" -eq 0 ] || [ "$NUM_HDFS_JARS" -lt "$(($NUM_LOCAL_JARS - 10))" ]; then # Allow for slight differences
  echo "Les JARs Spark ne sont pas présents ou incomplets dans HDFS. Suppression et copie en cours..."
  # Clean up existing directory before re-uploading
  $HADOOP_HOME/bin/hdfs dfs -rm -r -f "$SPARK_JARS_HDFS_DIR"
  $HADOOP_HOME/bin/hdfs dfs -mkdir -p "$SPARK_JARS_HDFS_DIR" # Recreate empty directory

  # Copy all JARs from the container's SPARK_HOME/jars to HDFS
  # Use a loop for more robust copying
  for jar_file in $SPARK_HOME/jars/*.jar; do
    echo "Copie de $(basename $jar_file) vers HDFS..."
    $HADOOP_HOME/bin/hdfs dfs -put -f "$jar_file" "$SPARK_JARS_HDFS_DIR/" || { echo "Erreur: Échec de la copie de $(basename $jar_file)."; exit 1; }
  done
  echo "Tous les JARs Spark copiés dans HDFS."
else
  echo "Les JARs Spark sont déjà présents dans HDFS. Nombre: $NUM_HDFS_JARS"
fi


# Rendre les scripts Python exécutables
chmod +x /python_scripts/mapper.py
chmod +x /python_scripts/reducer.py

# --- MapReduce Job (unchanged timing) ---
echo "Exécution du job WordCount Python avec Hadoop Streaming..."
TIMEFORMAT="%R"
start_time_mr=$(date +%s.%N)
($HADOOP_HOME/bin/hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-*.jar \
    -files /python_scripts/mapper.py,/python_scripts/reducer.py \
    -mapper mapper.py \
    -reducer reducer.py \
    -input $HDFS_INPUT_DIR/wordcount.txt \
    -output $HDFS_OUTPUT_DIR/mapreduce_output \
) || { echo "Erreur: Job Hadoop Streaming échoué."; exit 1; }
end_time_mr=$(date +%s.%N)
duration_mr=$(echo "$end_time_mr - $start_time_mr")
echo "Résultats du WordCount Python (HDFS):"
# $HADOOP_HOME/bin/hdfs dfs -cat $HDFS_OUTPUT_DIR/mapreduce_output/part-00000 # Optional to display here

echo "Job WordCount MapReduce terminé avec succès !"
echo "Temps d'exécution MapReduce: ${duration_mr} secondes"

# --- Spark Job (unchanged timing) ---
echo "Exécution du job WordCount avec Spark"
start_time_spark=$(date +%s.%N)
python3 /python_scripts/run_spark.py || { echo "Erreur: Job Spark échoué."; exit 1; }
end_time_spark=$(date +%s.%N)
duration_spark=$end_time_spark - $start_time_spark | bc


echo "Job WordCount Spark terminé avec succès !"
echo "Temps d'exécution Spark: ${duration_spark} secondes"

echo "Comparaison des temps:"
echo "MapReduce: ${duration_mr} s"
echo "Spark:     ${duration_spark} s"

# --- New: Get Output Files from HDFS to Container's Local Filesystem ---
echo "Copie des fichiers de sortie HDFS vers le répertoire local du conteneur..."
mkdir -p $CONTAINER_OUTPUT_DIR/mapreduce_output
mkdir -p $CONTAINER_OUTPUT_DIR/spark_output

# Get MapReduce output
# Note: Hadoop streaming creates a directory, so we get the content of the directory
$HADOOP_HOME/bin/hdfs dfs -get $HDFS_OUTPUT_DIR/mapreduce_output/* $CONTAINER_OUTPUT_DIR/mapreduce_output/ || { echo "Erreur: Impossible de récupérer la sortie MapReduce."; }

# Get Spark output
# Spark also creates a directory, get its content
$HADOOP_HOME/bin/hdfs dfs -get $HDFS_OUTPUT_DIR/spark_output/* $CONTAINER_OUTPUT_DIR/spark_output/ || { echo "Erreur: Impossible de récupérer la sortie Spark."; }

echo "Fichiers de sortie copiés vers le conteneur: ${CONTAINER_OUTPUT_DIR}"
ls -lR ${CONTAINER_OUTPUT_DIR} # Verify files are there

# Garder le container en vie pour inspection
tail -f /dev/null