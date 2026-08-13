# Asymmetric Big Data Cluster: Hadoop & Spark on ARM64

## Overview

This repository contains the configuration files, topology details, and deployment notes for a custom multi-node Hadoop/YARN and Apache Spark cluster built on inexpensive ARM64 Single Board Computers (SBCs) using Dietpi. Armbian didn't support all my hardware at the same level, one standard and two community builds.  Dietpi seemed the best option because it has may official orange pi images.

The cluster is intentionally **asymmetric**, utilizing a high-resource SBC as the master/control node and smaller low-cost boards to provide YARN executor capacity:

* **Master (`hppsrv`):** Orange Pi 5 Plus | 32 GB RAM *(HDFS NameNode, YARN ResourceManager, Spark Driver)*
* **Worker 1 (`zero2w`):** Orange Pi Zero 2W | 4 GB RAM *(HDFS DataNode, YARN Node)*
* **Worker 2 (`zero3`):** Orange Pi Zero 3 | 4 GB RAM *(HDFS DataNode, YARN Node)*

Running Spark on YARN allows this heterogeneous hardware to effectively distribute workload tasks within YARN's memory boundaries (configured at 3072 MB max container size).

---

## Hardware Limitations & Power Constraints

While this setup serves as a functional proof-of-concept for edge computing and local development, it revealed critical power supply limitations under heavy storage workloads:

* **Power Delivery Issue:** An adapted HP Pavilion desktop PSU was used to power the system, stepping down voltage using an adapter from the 12 volt P4 connector to a buck converter with a **5A maximum output**.
* **Storage Bottleneck:** When attempting to run multiple external drives continuously on the Orange Pi 5 Plus, the 5A buck converter could not handle the sustained power draw, leading to under-voltage instability. 
* **Drives** didn't mount on boot, they required an amp of current each. 
* **The usb hub** on the front isn't working well on usb3 drives, but great for peripherals on usb2 it's also powered using a sata power to barrel connector. 
* **2 usb c charging ports** are also connected to buck converters from 12 volts line to 5 volts with 2-3 amps max.
* **LCD Display:** takes 12 volt at 3 amps, it's originally from a pinebook pro that broke at the hinges. 2 fans have also been mounted inside and powered with a sata power connector.

---

## Hardware Recommendations for Rebuilding

If you are looking to replicate or build a similar home lab cluster, **SBCs are not recommended** due to power delivery quirks, accessory costs, and strict RAM limits per dollar.

### Recommended Alternative: Refurbished Mini PCs
Instead of single-board computers, it is significantly more practical and cost-effective to build a cluster using 3–4 used x86 Mini PCs (e.g., **Lenovo ThinkCentre M700 / M710q**, **Dell OptiPlex 3040/5040 Micro**, or **HP ProDesk 600 G2**). Even 3 used iMacs would make a nice setup with synergy for a cluster lab, some take a lot of ram.

**Why Mini PCs are superior for this setup:**
1. **Cost-to-Performance:** A fleet of 3–4 refurbished Mini PCs equipped with **16 GB RAM** and Intel Core i5 processors can often be sourced for less than the combined cost of high-tier SBCs, fast microSD cards/NVMe expansions, power splitters, and custom cooling.
2. **Dedicated Power & Stability:** Each node uses its own standard power brick, completely avoiding buck converter amperage bottlenecks when running external storage or high CPU workloads.
3. **Upgradability:** Standard x86 architecture, socketed RAM, and native SATA/NVMe interfaces make software setup and hardware expansion seamless.


### References

These are some of the guides I got inspration from for this cluster build and my old Raspberry Pi builds that failed to last.

- [RPi bramble Cluster for Docker Swarm](https://glasstty.com/a-raspberry-pi-based-bramble-cluster-for-docker-swarm/)
- [RPi Cluster for ipyparallel and MPI](https://glasstty.com/a-raspberry-pi-based-cluster-for-use-with-ipyparallel-and-mpi/)
- [Building a Raspberry Pi Hadoop / Spark Cluster](https://dev.to/awwsmm/building-a-raspberry-pi-hadoop-spark-cluster-8b2)


