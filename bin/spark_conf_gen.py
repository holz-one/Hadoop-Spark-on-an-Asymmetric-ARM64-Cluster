from typing import Dict


def generate_spark_config(
    num_nodes: int,
    node_ram_gb: float,
    node_cores: int,
    workload: str = "balanced",
) -> Dict[str, str]:
    """Generate Spark auto-tuned configuration.

    Args:
        num_nodes: Number of worker nodes.
        node_ram_gb: RAM per node (GB).
        node_cores: CPU cores per node.
        workload: One of ["conservative", "balanced", "aggressive"].

    Returns:
        Dict[str, str]: Spark config.
    """
    os_reserved_gb = 0.5
    usable_ram = max(node_ram_gb - os_reserved_gb, 0.5)

    if workload == "aggressive":
        executors_per_node = 1
        core_fraction = 0.75
    elif workload == "conservative":
        executors_per_node = 1
        core_fraction = 0.25
    else:
        executors_per_node = 1
        core_fraction = 0.5

    executor_cores = max(int(node_cores * core_fraction), 1)
    executor_memory_gb = usable_ram / executors_per_node

    num_executors = num_nodes * executors_per_node

    return {
        "spark.executor.instances": str(num_executors),
        "spark.executor.cores": str(executor_cores),
        "spark.executor.memory": f"{int(executor_memory_gb * 1024)}m",
        "spark.executor.memoryOverhead": "256",
        "spark.sql.shuffle.partitions": str(num_executors * executor_cores * 2),
        "spark.default.parallelism": str(num_executors * executor_cores),
    }


if __name__ == "__main__":
    config = generate_spark_config(
        num_nodes=2,
        node_ram_gb=4,
        node_cores=4,
        workload="balanced",
    )

    for k, v in config.items():
        print(f"--conf {k}={v}")
