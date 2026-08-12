# 🛠️ Post-Mortem: Legacy Multi-Node Homelab Cluster

## 📌 Project Overview

This document captures my early attempts to build a low-cost, heterogeneous mini-homelab cluster using leftover low-power Single Board Computers (SBCs), legacy x86 hardware, custom enclosures, and tailored Linux deployment scripts.

While theoretically capable of handling lightweight containerized workloads and distributed processing tasks, the build went through multiple iterations before ultimately being decommissioned due to thermal challenges, power instability, media degradation, and time constraints.

---

## 🏗️ Hardware Architecture & Hardware Iterations

The core nodes were reused across several physical builds and enclosure designs over time:

### Iteration 1: The "G5 Box"

* **Hardware:** 5× Raspberry Pi 3 Model B nodes and an integrated Wi-Fi access point.
* **Software:** Attempted to build a Kali Linux-based cluster by heavily modifying upstream ARM deployment scripts.
* **Outcome:** Scrapped. Modding the physical case damaged several tools, and the exposed hardware was unsuitable to keep at home around a newborn.

### Iteration 2: MasterCraft Case Cluster

* **Hardware:** Re-housed the 5× Raspberry Pi 3 Model B nodes into a portable MasterCraft toolbox enclosure.
* **Outcome:** Dismantled. Severe time constraints forced the project onto hiatus before the deployment was completed.

### Iteration 3: Dollarama Case Cluster

* **Hardware:** Raspberry Pi 3 Model B nodes housed in a cheap acrylic storage box, featuring custom cooling powered by salvaged PowerMac G5 fans.
* **Power Supply:** Powered by a 20V laptop power supply feeding multiple buck converters to meet the varying voltage requirements of the BitScope setup.
* **Software:** Ran a custom Manjaro Linux build configured for NFS root booting. Built during the COVID-19 pandemic.
* **Outcome:** Scrapped. The G5 fans were excessively loud, and the setup frequently suffered from thermal throttling and power distribution issues.

### Iteration 4: PowerMac G4 "Silver" Rebuild

* **Hardware:** 5× Raspberry Pi 3 Model B nodes paired with an Atomic Pi, mounted inside a PowerMac G4 chassis using custom 3D-printed brackets to retain the original fold-out side door mechanism.
* **Software:** Ran Manjaro Linux using iPXE network booting (netboot). Served as my first distributed Hadoop + Spark cluster.
* **Outcome:** Decommissioned. Experienced recurring power distribution failures and persistent MicroSD card corruption.

---

## ⚡ Root Causes of Failure

### 1. Power Supply Instability & Undervoltage

* **Inadequate Power Distribution:** Attempted to power multiple Raspberry Pi units and the Atomic Pi using off-the-shelf power strips, low-cost USB power hubs, and improvised wiring.
* **Under-Voltage Throttling:** Raspberry Pi nodes experienced frequent CPU throttling (`under-voltage detected`), causing sudden reboots and corrupted state transitions.
* **Atomic Pi Power Draw:** The Atomic Pi required a dedicated 5V/4A feed via header pins; sub-optimal buck converters and wiring caused severe voltage drops under load.

### 2. Storage Degradation & Bus Bottlenecks

* **MicroSD Card Failure:** High write-amplification from Linux system logs, Docker container layers, and system updates rapidly degraded consumer-grade MicroSD cards.
* **Filesystem Corruption:** Abrupt power losses directly corrupted the root (`/`) partitions on ungracefully unmounted storage.
* **I/O Bottlenecks:** The shared USB 2.0 / SD card controller on the Raspberry Pi 3 heavily throttled network boot performance and local script execution.

### 3. Thermal & Structural Issues

* **Acoustics & Heat:** Reusing industrial and high-CFM PC fans (like the G5 fans) introduced extreme noise without providing targeted airflow over power conversion components.
* **Child Safety & Space Constraints:** Loose wiring, exposed power rails, and fragile custom modifications made the cluster impractical and unsafe for a residential family environment.

### 4. Hardware Misalignment

* **Mixed Architectures:** Combining 64-bit ARM nodes with x86_64 hardware significantly increased maintenance overhead without offering meaningful redundancy.

---

## 💻 Software & Scripting Stack

* **Operating Systems:**
* **Custom Manjaro Linux Builds:** Utilized on the Dollarama Case and PowerMac G4 builds to support NFS/iPXE boot setups.
* **Custom Kali Linux ARM Builds:** Deployed on the Raspberry Pi nodes with custom bootstrap scripts.


* **Provisioning & Deployment:**
* Custom Bash automation scripts to manage network interfaces, assign static IPs, and install lightweight runtime packages.
* High manual configuration overhead required to build and maintain multi-architecture image compatibility (ARM64 vs. x86_64).



---

## 📝 Key Lessons Learned

1. **Power Quality > Node Count:** A single reliable node with a clean, dedicated power supply far outperforms a multi-node cluster plagued by voltage drops.
2. **Avoid SD Cards for OS Storage:** Always opt for network boot (PXE) over reliable infrastructure, or use dedicated SSDs (via USB-to-SATA adapters or NVMe) for root filesystems.
3. **Homogeneous Architecture Saves Time:** Mixing different instruction sets (x86 vs. ARM) introduces unnecessary cross-compilation and script maintenance burdens.
4. **Enclosures Require Safety Planning:** DIY custom cases must account for noise levels, safe voltage step-downs, and child-proofing before being deployed long-term.