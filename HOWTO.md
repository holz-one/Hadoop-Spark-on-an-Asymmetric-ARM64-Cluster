# HOWTO: Hadoop + Spark on an Asymmetric ARM64 Cluster

## 1. Overview

This guide documents a working Hadoop/YARN + Apache Spark cluster built from inexpensive ARM64 SBCs with different amounts of RAM and CPU resources.

The important characteristic of this cluster is that it is **asymmetric**: the nodes do not have identical hardware.

The working architecture is:

```text
                         ┌──────────────────────┐
                         │       hppsrv         │
                         │   Orange Pi 5 Plus   │
                         │       32 GB RAM      │
                         │     YARN RM / HDFS   │
                         │       10.0.1.1       │
                         └──────────┬───────────┘
                                    │
                     ┌──────────────┴──────────────┐
                     │                             │
             ┌───────▼────────┐           ┌────────▼───────┐
             │     zero2w     │           │      zero3     │
             │ Orange Zero 2W │           │ Orange Pi Zero3 │
             │     4 GB RAM   │           │     4 GB RAM    │
             │   10.0.1.2     │           │    10.0.1.3     │
             │ YARN NodeMgr   │           │ YARN NodeMgr    │
             │ DataNode       │           │ DataNode        │
             └────────────────┘           └─────────────────┘
```

The Orange Pi 5 Plus is the master and client machine. The two smaller boards provide YARN executor capacity.

Spark runs **on YARN**, rather than using Spark Standalone.

---

# 2. Hardware

| Host | Hardware | RAM | Role |
|---|---|---:|---|
| `hppsrv` | Orange Pi 5 Plus | 32 GB | HDFS NameNode, YARN ResourceManager, Spark client |
| `zero2w` | Orange Zero 2 W | 4 GB | HDFS DataNode, YARN NodeManager |
| `zero3` | Orange Pi Zero 3 | 4 GB | HDFS DataNode, YARN NodeManager |

The cluster is intentionally asymmetric.

The master has substantially more RAM than the workers, so it is useful for:

- HDFS NameNode
- YARN ResourceManager
- Spark client/driver in client mode
- development
- monitoring
- experimentation

The smaller nodes are primarily compute workers.

---

# 3. Software Versions

The working environment used:

```text
Operating system: DietPi
Architecture:     ARM64 / aarch64
Java:             OpenJDK 17.0.9
Hadoop:           Apache Hadoop 3.4.3
Spark:            Apache Spark 3.5.8
Scala:            2.12
```

Apache binaries were used directly rather than building Hadoop from source.

The installation layout was:

```text
/mnt/cluster/
├── jdk/
├── hadoop/
│   └── current -> hadoop-3.4.3/
├── spark/
│   └── spark-3.5.8-bin-hadoop3/
└── hdfs/
```

Keeping software underneath `/mnt/cluster` makes it possible to switch versions using symlinks.

For example:

```bash
/mnt/cluster/hadoop/current
/mnt/cluster/jdk
```

This makes future upgrades considerably easier.

---

# 4. Java Environment

Set the Java environment consistently on all nodes.

Example:

```bash
export JAVA_HOME=/mnt/cluster/jdk
export PATH="$JAVA_HOME/bin:$PATH"
```

Verify:

```bash
java -version
```

The working cluster used:

```text
Java 17.0.9
```

All Hadoop and Spark nodes must be able to locate the same Java installation/version.

---

# 5. Hadoop Environment

Set:

```bash
export HADOOP_HOME=/mnt/cluster/hadoop/current
export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
export YARN_CONF_DIR="$HADOOP_CONF_DIR"

export PATH="$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH"
```

Spark needs access to the Hadoop client configuration.

In particular:

```bash
export HADOOP_CONF_DIR=/mnt/cluster/hadoop/current/etc/hadoop
```

Spark's YARN integration uses this configuration to locate HDFS and the YARN ResourceManager.

---

# 6. Network Configuration

Use stable hostnames and addresses.

The working configuration used:

```text
hppsrv   10.0.1.1
zero2w   10.0.1.2
zero3    10.0.1.3
```

The important lesson from the failed Spark run was that **the Spark driver must advertise an address reachable from the worker nodes**.

Initially Spark advertised:

```text
192.168.2.200:40461
```

The YARN ApplicationMaster could not connect to it:

```text
Failed to connect to /192.168.2.200:40461
Connection timed out
```

The successful configuration explicitly bound Spark to the cluster network:

```bash
--conf spark.driver.host=10.0.1.1
--conf spark.driver.bindAddress=0.0.0.0
```

This changed the driver endpoint to:

```text
10.0.1.1
```

That was the critical networking fix.

---

# 7. Hadoop Cluster

The Hadoop installation uses:

```text
hppsrv
  ├── NameNode
  └── ResourceManager

zero2w
  ├── DataNode
  └── NodeManager

zero3
  ├── DataNode
  └── NodeManager
```

The HDFS storage path used during development was:

```text
/mnt/cluster/hdfs
```

After configuring HDFS, verify the filesystem:

```bash
hdfs dfs -ls /
```

And verify YARN:

```bash
yarn node -list
```

Both worker nodes should appear.

---

# 8. YARN Resource Configuration

The cluster's YARN maximum container memory was:

```text
3072 MB
```

This appeared directly in the Spark submission output:

```text
maximum memory capability of the cluster (3072 MB per container)
```

This value is important when tuning Spark.

Spark cannot request an executor container larger than the YARN limit.

The initial successful experiment deliberately used small executors:

```text
executor memory: 512 MB
executor cores:  1
executors:        2
```

with:

```bash
--executor-memory 512m
--executor-cores 1
--num-executors 2
```

This successfully placed executors on both worker nodes.

---

# 9. Install Spark

The working Spark installation was:

```text
Apache Spark 3.5.8
spark-3.5.8-bin-hadoop3
```

Set:

```bash
export SPARK_HOME=/mnt/cluster/spark/current
export PATH="$SPARK_HOME/bin:$PATH"
```

Verify:

```bash
spark-submit --version
```

The resulting environment reported:

```text
Spark 3.5.8
Java 17.0.9
aarch64
```

Spark 3.5.8 supports YARN submission in both client and cluster deployment modes.

---

# 10. First Spark Test

The first test was Spark's built-in `SparkPi` example.

The initial command was:

```bash
spark-submit \
  --master yarn \
  --deploy-mode client \
  --executor-memory 512m \
  --executor-cores 1 \
  --num-executors 2 \
  --class org.apache.spark.examples.SparkPi \
  "$SPARK_HOME/examples/jars/spark-examples_2.12-3.5.8.jar" \
  10
```

This initially failed.

The important error was:

```text
Failed to connect to /192.168.2.200:40461
Connection timed out
```

The YARN application itself was running, but the workers could not establish a connection back to the Spark driver.

---

# 11. Working Spark Submission

The working command explicitly configured the driver network interface:

```bash
spark-submit \
  --master yarn \
  --deploy-mode client \
  --executor-memory 512m \
  --executor-cores 1 \
  --num-executors 2 \
  --class org.apache.spark.examples.SparkPi \
  --conf spark.driver.host=10.0.1.1 \
  --conf spark.driver.bindAddress=0.0.0.0 \
  --conf spark.driver.port=7077 \
  --conf spark.blockManager.port=7078 \
  "$SPARK_HOME/examples/jars/spark-examples_2.12-3.5.8.jar" \
  10
```

The important settings are:

```text
spark.driver.host=10.0.1.1
spark.driver.bindAddress=0.0.0.0
spark.driver.port=7077
spark.blockManager.port=7078
```

The driver successfully started:

```text
SparkUI                  10.0.1.1:4040
sparkDriver              10.0.1.1:7077
NettyBlockTransferService 10.0.1.1:7078
```

The ApplicationMaster subsequently registered:

```text
ApplicationMaster registered as NettyRpcEndpointRef
```

and both workers registered:

```text
zero3
zero2w
```

---

# 12. Successful Executor Allocation

The test used:

```text
2 executors
1 core/executor
512 MB executor memory
```

The executors were allocated as:

```text
Executor 1 → zero3
Executor 2 → zero2w
```

This demonstrates that the YARN cluster was correctly distributing Spark executors across the two ARM64 worker nodes.

The Spark application completed successfully:

```text
Pi is roughly 3.1415351415351416
```

The complete job took approximately:

```text
38 seconds
```

for:

```text
10 partitions
```

This is a useful baseline for future tuning.

---

# 13. Important Observation About Memory

Although each executor requested:

```text
512 MB
```

Spark reported approximately:

```text
127.2 MiB
```

available to the executor's BlockManager.

This is expected.

The executor container contains more than Spark's storage memory. The YARN container also needs room for:

- JVM heap
- Spark execution memory
- Spark storage memory
- JVM/native overhead
- Python/native processes when applicable
- other runtime allocations

Therefore, do not interpret the BlockManager value as total executor memory.

---

# 14. Spark Library Distribution

The first successful run produced this warning:

```text
Neither spark.yarn.jars nor spark.yarn.archive is set,
falling back to uploading libraries under SPARK_HOME.
```

The application still worked.

For experimentation this is acceptable.

For repeated workloads, Spark's documentation supports placing Spark libraries in HDFS using:

```text
spark.yarn.jars
```

or:

```text
spark.yarn.archive
```

This avoids repeatedly uploading Spark's libraries for every application.

For this small learning cluster, library caching should be considered an optimization rather than a prerequisite.

---

# 15. Spark Event Logging

The next stage of the project is feedback-driven tuning.

Enable event logging:

```bash
--conf spark.eventLog.enabled=true \
--conf spark.eventLog.dir=hdfs:///spark-logs
```

For example:

```bash
spark-submit \
  --master yarn \
  --deploy-mode client \
  --executor-memory 512m \
  --executor-cores 1 \
  --num-executors 2 \
  --conf spark.driver.host=10.0.1.1 \
  --conf spark.driver.bindAddress=0.0.0.0 \
  --conf spark.driver.port=7077 \
  --conf spark.blockManager.port=7078 \
  --conf spark.eventLog.enabled=true \
  --conf spark.eventLog.dir=hdfs:///spark-logs \
  "$SPARK_HOME/examples/jars/spark-examples_2.12-3.5.8.jar" \
  10
```

The event log becomes the input to the auto-tuner.

---

# 16. Auto-Tuning Architecture

The planned tuning system is:

```text
                 ┌───────────────────┐
                 │   Spark Job       │
                 └─────────┬─────────┘
                           │
                           ▼
                 ┌───────────────────┐
                 │ Spark Event Log   │
                 │      HDFS         │
                 └─────────┬─────────┘
                           │
                           ▼
                 ┌───────────────────┐
                 │ Log Analyzer      │
                 └─────────┬─────────┘
                           │
                           ▼
                 ┌───────────────────┐
                 │ Performance       │
                 │ Metrics            │
                 └─────────┬─────────┘
                           │
                           ▼
                 ┌───────────────────┐
                 │ Tuning Engine     │
                 └─────────┬─────────┘
                           │
                           ▼
                 ┌───────────────────┐
                 │ New Spark Config  │
                 └───────────────────┘
```

The tuner should eventually consider:

- executor count
- executor cores
- executor memory
- memory overhead
- shuffle partitions
- default parallelism
- Adaptive Query Execution
- task duration
- task skew
- shuffle volume
- executor utilization
- GC pressure
- failed tasks
- spilled data
- network transfer

---

# 17. Initial Auto-Tuning Rules

A useful first version can use rules rather than machine learning.

### High task skew

Enable AQE/skew handling:

```text
spark.sql.adaptive.enabled=true
spark.sql.adaptive.skewJoin.enabled=true
```

### Excessive shuffle

Increase:

```text
spark.sql.shuffle.partitions
```

### Too few tasks

Increase:

```text
spark.default.parallelism
```

### Very small tasks

Consider increasing:

```text
spark.executor.cores
```

### Very long tasks

Investigate:

- insufficient parallelism
- data skew
- insufficient executor memory
- disk spilling
- network throughput

The tuner should **recommend changes first**, rather than blindly changing the cluster.

---

# 18. Why Auto-Tuning Is Especially Useful Here

This cluster is asymmetric.

A conventional Spark configuration assumes reasonably homogeneous machines.

This cluster is different:

```text
             RAM         CPU
hppsrv       32 GB       high
zero2w        4 GB       low
zero3         4 GB       low
```

Therefore the tuner should be **YARN-aware**, rather than simply calculating:

```text
total_cluster_memory / number_of_nodes
```

YARN should determine what resources are actually available to containers.

The Spark application should then request resources that fit within those constraints.

---

# 19. Recommended Initial Baseline

Use this as the baseline for experiments:

```text
Executors:              2
Executor cores:         1
Executor memory:        512 MB
YARN max container:     3072 MB
Workers:                zero2w, zero3
Driver:                 hppsrv
Driver IP:              10.0.1.1
Driver port:            7077
BlockManager port:      7078
```

Do not immediately increase executor memory or cores.

First establish a performance baseline.

Then change one variable at a time.

---

# 20. Benchmarking Method

For each configuration:

```text
configuration
     ↓
Spark job
     ↓
event log
     ↓
metrics
     ↓
runtime
     ↓
tuner recommendation
     ↓
next configuration
```

Store the results:

```text
run_id
executor_memory
executor_cores
num_executors
shuffle_partitions
runtime
task_count
average_task_time
maximum_task_time
shuffle_read
shuffle_write
spill_memory
spill_disk
failed_tasks
```

This eventually provides a dataset for an ML/Bayesian optimizer.

---

# 21. Future ML-Based Tuner

Once enough benchmark runs have been collected, the rule-based tuner can evolve into:

```text
Spark configuration
        │
        ▼
     Run job
        │
        ▼
   Collect metrics
        │
        ▼
   Store benchmark
        │
        ▼
 Optimization model
        │
        ▼
 Predict next configuration
        │
        ▼
     Run again
```

The objective can initially be:

```text
minimize job runtime
```

subject to:

```text
memory <= available memory
CPU <= available CPU
YARN container <= 3072 MB
```

This is a much better approach for an unusual ARM cluster than blindly copying Spark configurations designed for large x86 servers.

---

# 22. Troubleshooting Lessons

## Spark cannot connect to the driver

Look for:

```text
Failed to connect to <IP>:<port>
Connection timed out
```

Check:

```bash
--conf spark.driver.host=<reachable-IP>
--conf spark.driver.bindAddress=0.0.0.0
```

Then test connectivity from a worker:

```bash
nc -vz 10.0.1.1 7077
```

and:

```bash
nc -vz 10.0.1.1 7078
```

Ensure the firewall permits the required ports.

## Application stays ACCEPTED

If Spark repeatedly reports:

```text
Initial job has not accepted any resources
```

check:

```bash
yarn node -list
```

and:

```bash
yarn application -status <application-id>
```

Also verify that the requested executor resources fit within YARN's available container resources.

## Executors never register

Check:

```text
ApplicationMaster
NodeManager
Spark driver
```

in that order.

The Spark driver must be reachable from the worker network.

---

# 23. Final Working Stack

The resulting stack is:

```text
DietPi
  │
  ├── OpenJDK 17.0.9
  │
  ├── Apache Hadoop 3.4.3
  │     ├── HDFS
  │     └── YARN
  │
  └── Apache Spark 3.5.8
        │
        └── Spark on YARN
              │
              ├── zero2w
              └── zero3
```

The most important successful configuration was not an aggressive executor configuration.

It was establishing reliable networking between the Spark client/driver and the YARN workers:

```text
spark.driver.host=10.0.1.1
spark.driver.bindAddress=0.0.0.0
```

Once that was corrected, the two asymmetric ARM64 worker nodes successfully registered Spark executors and completed the SparkPi workload.

---

# 24. Minimal Reproduction

For someone rebuilding this cluster, the essential sequence is:

```bash
# 1. Verify Java
java -version

# 2. Verify Hadoop
hdfs dfs -ls /
yarn node -list

# 3. Verify Spark
spark-submit --version

# 4. Submit SparkPi
spark-submit \
  --master yarn \
  --deploy-mode client \
  --executor-memory 512m \
  --executor-cores 1 \
  --num-executors 2 \
  --class org.apache.spark.examples.SparkPi \
  --conf spark.driver.host=10.0.1.1 \
  --conf spark.driver.bindAddress=0.0.0.0 \
  --conf spark.driver.port=7077 \
  --conf spark.blockManager.port=7078 \
  "$SPARK_HOME/examples/jars/spark-examples_2.12-3.5.8.jar" \
  10
```

Expected result:

```text
Pi is roughly 3.1415...
```

with executors appearing on:

```text
zero2w
zero3
```

That establishes the baseline from which the auto-tuner can begin optimizing.
