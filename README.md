# Custom Kubernetes Setup Script

This script is designed to automate the setup of a Kubernetes cluster with customizable settings for version, CIDR block, and role (worker or master).
It is intended to simplify the deployment and configuration process for Kubernetes clusters.
To raise a Kubernetes cluster you need at least 2 VMs: master and worker.

## Prerequisites

- A system with Ubuntu or a compatible Linux distribution.
- `curl`, and `wget` installed to download the scripts.
- Root (or sudo) access to install dependencies.

## Usage

The script accepts three parameters:
- `-v`: Kubernetes version (e.g., `v1.31`)
- `-c`: CIDR block for the Pod network (required for master node)
- `-r`: Role (`master` or `worker`)

## Examples

### 1. Install script

Download the script from GitHub

```bash
wget https://raw.githubusercontent.com/DanyloMaryskevych/k8s/main/k8s_setup.sh
```

### 2. Setting up a **Master** Node

To set up a master node, you need to provide both the Kubernetes version and the CIDR block for the pod network:

```bash
bash k8s_setup.sh -v v1.31 -c 10.15.0.0/16 -r master
```

### 3. Setting up a **Worker** Node

To set up a worker node, you need to provide only the Kubernetes version:

```bash
bash k8s_setup.sh -v v1.31 -r worker
```
After this, you will get a message to run on the master node this command to get the join command:
```bash
kubeadm token create --print-join-command
```
