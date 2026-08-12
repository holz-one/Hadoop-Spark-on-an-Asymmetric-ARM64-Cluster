# Troubleshooting: Asymmetric ARM64 Hadoop + Spark Cluster

This guide covers common diagnostic steps for the hppsrv (Master) / zero2w & zero3 (Workers) cluster.

## 1. Quick Verification Checklist

Before investigating logs, verify core services are running:

### Check Daemons (run on respective hosts)
- Master (hppsrv): Should see NameNode, SecondaryNameNode, ResourceManager, Master.
  Command: jps
- Workers (zero2w, zero3): Should see DataNode, NodeManager, Worker.
  Command: jps

### Check UI Accessibility
- HDFS: http://10.0.1.1:9870
- YARN: http://10.0.1.1:8088
- Spark: http://10.0.1.1:8080

---

## 2. Networking & Connectivity

### Issue: Spark Driver Connection Timeout
Symptoms: Jobs fail with "Failed to connect to <IP>:<port>" or "Connection timed out" in the application master logs.

Diagnostic:
Test reachability from a worker node to the Master driver port:
  nc -vz 10.0.1.1 7077

Fix:
Ensure your spark-submit command explicitly binds the driver to the cluster interface:
  --conf spark.driver.host=10.0.1.1
  --conf spark.driver.bindAddress=0.0.0.0

---

## 3. YARN Resource & Scheduling Issues

### Issue: Application Stuck in ACCEPTED
Symptoms: Job is submitted but never starts executing tasks.

Diagnostic:
1. Check if YARN sees the workers:
   yarn node -list
2. Check logs for rejection reason:
   yarn application -status <application_id>

Common Causes:
- Memory Constraints: Requested executor-memory + overhead exceeds the yarn.nodemanager.resource.memory-mb (3072 MB per container limit on your cluster).
- Cores: Trying to request more cores than the worker node has available.

Fix:
Lower your Spark request parameters:
  --executor-memory 512m --executor-cores 1

---

## 4. HDFS Data Integrity

### Issue: DataNode Fails to Join
Symptoms: DataNode doesn't appear in the `hdfs dfsadmin -report` output or the Web UI.

Diagnostic:
Check the DataNode logs on the worker node:
  tail -f $HADOOP_HOME/logs/hadoop-*-datanode-*.log

Common Cause:
Formatting the NameNode without clearing old DataNode storage data can cause cluster ID mismatches.

Fix:
If you reformat the NameNode, you MUST clear the dfs.datanode.data.dir on ALL worker nodes.

---

## 5. Environment & Configuration

### Issue: "Command not found" or "Version Mismatch"
Diagnostic:
Verify paths are exported correctly in ~/.bashrc:
  echo $JAVA_HOME
  echo $HADOOP_HOME
  echo $SPARK_HOME

---

## 6. Resetting the Cluster (The "Panic Button")

If the cluster state becomes corrupted, follow this sequence to perform a clean re-initialization:

1. Stop all services:
   stop-all.sh

2. Clear logs and temp data:
   rm -rf /mnt/cluster/hdfs/data/*
   rm -rf /mnt/cluster/hadoop/logs/*

3. Re-format NameNode:
   hdfs namenode -format

4. Restart:
   start-dfs.sh
   start-yarn.sh
