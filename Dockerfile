# Use a base image that has Java and a working apt package manager
FROM openjdk:11-jdk-slim-buster

# Set environment variables for Hadoop
ENV HADOOP_VERSION=3.3.5
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

# Install necessary tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    tar \
    bc \
    openjdk-11-jdk-headless \
    python3 \
    python3-pip \
    # Add any other build tools if needed, e.g., build-essential, ca-certificates
    && rm -rf /var/lib/apt/lists/*

# Download and install Hadoop
RUN wget -q "https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz" -O /tmp/hadoop.tar.gz \
    && tar -xzf /tmp/hadoop.tar.gz -C /opt \
    && mv /opt/hadoop-${HADOOP_VERSION} ${HADOOP_HOME} \
    && rm /tmp/hadoop.tar.gz

# Install Spark
ARG SPARK_VERSION=3.5.1
ARG SPARK_HADOOP_VERSION=3 # Match your Hadoop major version
ENV SPARK_HOME=/opt/spark
ENV PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin

RUN wget -q "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION}.tgz" -O /tmp/spark.tgz \
    && tar -xzf /tmp/spark.tgz -C /opt \
    && mv "/opt/spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION}" "${SPARK_HOME}" \
    && rm /tmp/spark.tgz


# Install PySpark
RUN pip3 install setuptools wheel
RUN pip3 install pyspark

# Create directories for Hadoop data (Namenode and Datanode need these)
RUN mkdir -p /opt/hadoop/data/nameNode \
           /opt/hadoop/data/dataNode \
           /opt/hadoop/logs

# Set HDFS configuration directories (adjust if you map volumes differently)
# This is crucial for Spark to find Hadoop configuration
ENV HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop

# Set up SSH for Hadoop (optional, but often needed for multi-node setup)
# This might require more configuration for passwordless SSH if you intend to run
# start-dfs.sh/start-yarn.sh from within the container.
RUN apt-get update && apt-get install -y --no-install-recommends openssh-server \
    && mkdir -p /var/run/sshd

# Clean up APT cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Default command (you might override this in docker-compose)
# This will be the base image for ALL your Hadoop services
CMD ["/bin/bash"]