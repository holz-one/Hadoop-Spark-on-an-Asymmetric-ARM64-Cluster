#!/usr/bin/env bash

#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

export SPARK_MASTER_HOST=hppsrv

# =========================
# Cluster Base Paths
# =========================

export CLUSTER_ROOT=/mnt/cluster

export SPARK_HOME=$CLUSTER_ROOT/spark/current

export JAVA_HOME=$CLUSTER_ROOT/jdk

# =========================
# Node Role Detection
# =========================

HOSTNAME_SHORT=$(hostname -s)

if [[ "$HOSTNAME_SHORT" == "hppsrv" ]]; then
    export NODE_ROLE="master"
else
    export NODE_ROLE="worker"
fi

# =========================
# Memory Profiles
# =========================

if [[ "$NODE_ROLE" == "master" ]]; then

#    export SPARK_WORKER_MEMORY=20g
    export SPARK_WORKER_CORES=4
#    export SPARK_DRIVER_MEMORY=4g
else

#    export SPARK_WORKER_MEMORY=1024m
    export SPARK_WORKER_CORES=2
#    export SPARK_DRIVER_MEMORY=1024m
fi

export SPARK_DRIVER_MEMORY=1024m
export SPARK_WORKER_MEMORY=768m

# =========================
# JVM Tuning
# =========================

export SPARK_DAEMON_JAVA_OPTS="-XX:+UseG1GC"

# =========================
# Networking Stability
# =========================

#export SPARK_LOCAL_IP=$(ip a|grep 192.168.2 | tr -s ' ' | cut -d ' ' -f3| cut -d '/' -f1)
#export SPARK_LOCAL_IP=$(hostname -I | awk '{ print $2; }')
export SPARK_LOCAL_IP=$(cat /etc/hosts | grep -i $(hostname) | awk '{ print $1; }')

# ========================
# Auto-switch configs
# ========================

if [[ "$(cat /mnt/cluster/.cluster_mode)" == "spark" ]]; then
  export SPARK_MASTER_URL="spark://hppsrv:7077"
else
  export SPARK_MASTER_URL="yarn"
fi

cat << conf > ${SPARK_HOME}/conf/spark-defaults.conf

spark.master ${SPARK_MASTER_URL}
spark.submit.deployMode client



spark.driver.host ${SPARK_LOCAL_IP}
spark.driver.bindAddress 0.0.0.0
spark.driver.port=7077

spark.blockManager:7078

# Core executor model
spark.driver.memory ${SPARK_DRIVER_MEMORY}
spark.executor.memory ${SPARK_WORKER_MEMORY}
spark.executor.cores ${SPARK_WORKER_CORES} 
spark.executor.instances 3

# SQL tuning (CRITICAL)
spark.default.parallelism 6
spark.sql.shuffle.partitions 8

# Adaptive Query Execution (BIG WIN)
spark.sql.adaptive.enabled true
spark.sql.adaptive.coalescePartitions.enabled true
spark.sql.adaptive.skewJoin.enabled true

# Reduce shuffle pressure
spark.sql.adaptive.advisoryPartitionSizeInBytes 64MB

# Broadcast joins (fits your cluster well)
spark.sql.autoBroadcastJoinThreshold 50MB


spark.network.timeout 300s
spark.executor.heartbeatInterval 60s

spark.speculation false


# Reduce overhead (important for small nodes)
spark.executor.memoryOverhead 256

# Improve scheduling
spark.scheduler.mode FAIR

# Serialization boost
spark.serializer org.apache.spark.serializer.KryoSerializer

spark.memory.fraction 0.6
spark.memory.storageFraction 0.3

conf
