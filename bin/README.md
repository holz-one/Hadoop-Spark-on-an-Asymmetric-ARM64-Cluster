# Cluster Management Scripts

A collection of Bash automation scripts and Python auto-tuning utilities for managing, synchronizing, and controlling a multi-node Hadoop and Spark cluster.

---

## Script Index

### `clustercmd`
* **Description:** Executes a given bash command across all worker nodes in the cluster sequentially via SSH, before executing it on the local node.

---

### `cluster-mode.sh`
* **Description:** Manages the active operational mode of the cluster[cite: 4]. It stops running services, sets the mode (`hadoop` or `spark`), brings up HDFS/YARN or Spark standalone daemons, and checks cluster status across nodes using `jps`[cite: 4]. Also supports `status` and `stop` actions.

---

### `cluster-reboot.sh`
* **Description:** Safely stops all active Spark and Hadoop/YARN services across the cluster, waits for process termination, and triggers a system reboot on all cluster nodes.

---

### `cluster-shutdown.sh`
* **Description:** Safely stops all active Spark and Hadoop/YARN services across the cluster, waits for process termination, and initiates an immediate shutdown on all nodes.

---

### `cluster-cp`
* **Description:** Copies a specified file from the local node to the identical absolute file path on all worker nodes using SSH and `sudo tee`.

---

### `cluster-sync`
* **Description:** Recursively synchronizes a specified local directory to the corresponding parent directory path across all worker nodes using `rsync`.

---

### `get-mac`
* **Description:** Takes a network interface name as an argument (e.g., `eth0`) and outputs its corresponding MAC (ethernet) address.

---

### `get-iface`
* **Description:** Accepts a partial or full network interface name and returns matching interface identifiers assigned on the system.

---

### `otherpis`
* **Description:** Parses `/etc/hosts` for IP addresses matching the `10.0.1.x` subnet and returns the hostnames of all cluster nodes excluding the local machine.

---

### `set_cluster_mode`
* **Description:** Sets and persists the current cluster operational mode (`spark` or `hadoop`) by writing the value to `/mnt/cluster/.cluster_mode`.

---

### `generate_spark_config.py`
* **Description:** A Python auto-tuning utility that calculates and outputs optimal Spark configuration parameters (`--conf` flags) based on worker node hardware specifications (RAM, CPU cores, node count) and workload profiles (`conservative`, `balanced`, or `aggressive`).

---

### `start-hadoop`
* **Description:** Shortcut script that executes `cluster-mode` to switch the cluster into Hadoop/YARN mode.

---

### `start-spark`
* **Description:** Shortcut script that executes `cluster-mode` to switch the cluster into Spark standalone mode.
