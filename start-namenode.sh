#!/bin/bash

HADOOP_HOME=/opt/hadoop
HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop

# Formater le NameNode seulement s'il n'a pas déjà été formaté
# Utilise un fichier marqueur pour éviter de reformater à chaque démarrage

# Formater le NameNode seulement si le répertoire est vide
if [ ! "$(ls -A /opt/hadoop/data/nameNode)" ]; then
  echo "Formatage du NameNode..."
  $HADOOP_HOME/bin/hdfs namenode -format -force
fi

echo "Démarrage du NameNode en arrière-plan..."
$HADOOP_HOME/bin/hdfs --daemon start namenode

echo "Le NameNode est en cours de démarrage. Le conteneur va rester actif."
echo "Pour voir les logs, utilisez la commande : docker logs -f namenode"

# Garder le conteneur en vie de manière fiable
tail -f /dev/null

echo "Tous les services du NameNode (HDFS, YARN ResourceManager, JobHistory) sont démarrés."
echo "Interface Web UI du NameNode disponible sur http://localhost:9870"
echo "Interface Web UI du ResourceManager disponible sur http://localhost:8088"
echo "Interface Web UI du JobHistory Server disponible sur http://localhost:19888"
