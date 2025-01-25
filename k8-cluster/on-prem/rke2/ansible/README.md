# RKE2 Kubernetes Cluster Setup using Ansible

## Overview
An Ansible playbook and associated configurations to set up an RKE2 Kubernetes cluster. This setup includes:

* **Primary Control Plane Node:** Manages the cluster's control plane operations.
* **Subsequent Control Plane Nodes:** Provides high availability for the control plane.
* **Agent Nodes:** Runs workloads and application pods.
* **etcd Cluster:** Offers a distributed key-value store for Kubernetes.

The playbooks are designed to install RKE2, configure the nodes, and ensure the cluster is fully operational and ready for use.
## Prerequisites

Below are the pre-requisites for ansible playbook execution:

* Install Ansible on your local machine. For installation instructions, refer to the [Ansible Installation Guide](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html). version > 2.12.4
* Ensure that nodes are accessible from your local machine for SSH authentication.
* Verify that the SSH private key for the nodes is available on your local machine [password less ssh](../../../../docs/ssh.md).
* Supported operating systems include Ubuntu 24.04 and other Debian-based distributions.

* Ensure to set `8.8.8.8` in `/etc/resolv.conf`.
* Git & tmux
  ```
  sudo apt update && sudo apt install git tmux -y
  ```
* [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html).
  * For ubuntu:
    ```
    sudo apt update && sudo apt install software-properties-common -y  && sudo add-apt-repository --yes --update ppa:ansible/ansible && sudo apt install ansible -y
    ```

* The following tools are installed on all the VM's/machines and the client machine.
  ```ufw , wget , curl , kubectl , istioctl , helm , jq```
* Command line utilities:
  - kubectl
    ```
    sudo apt install curl -y && \
    curl -LO "https://dl.k8s.io/release/v1.22.9/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    sudo mv kubectl /bin/ 
    ```
  - helm
    ```
    wget https://get.helm.sh/helm-v3.16.2-linux-amd64.tar.gz && \
    tar -zxvf helm-v3.16.2-linux-amd64.tar.gz && \
    sudo mv linux-amd64/helm /bin/helm
    ```
  - istioctl (istioctl version: v1.15.0)
    ```
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.15.0 TARGET_ARCH=x86_64 sh - && \
    sudo mv istio-1.15.0/bin/istioctl /bin/
    ```
* Helm repos:
  ```sh
  helm repo add bitnami https://charts.bitnami.com/bitnami && \ 
  helm repo add mosip https://mosip.github.io/mosip-helm && \
  helm repo update
  ```
* Verify toots are deployed.
  ``` 
  kubectl version
  istioctl version
  helm version
  ```


## Kubernetes setup via Ansible playbook

To run the playbooks and set up your RKE2 Kubernetes cluster, follow these steps:

* Set up VMs.
* Set up [passwordless SSH](../../../../docs/ssh.md).
* Clone repository
  ```
  cd ~/
  ```
  ```
  git clone https://github.com/tf-nira/k8s-infra.git -b NIRA-K8s
  ```
  ```
  cd ~/k8s-infra/k8-cluster/on-prem/rke2/ansible
  ```

### 1. Prepare Inventory File:

#### For Sandbox and Development Environments:

* Create a copy of `hosts.ini.sample` as `hosts.ini`:
    ```bash
    cp hosts.ini.sample hosts.ini
    ```
* Comment out the `[etcd]` section in the `hosts.ini` file.
* Update other sections with VM details.

#### For Production Environment:

* Create a copy of `hosts.ini.sample` as `hosts.ini`:
    ```bash
    cp hosts.ini.sample hosts.ini
    ```
* Ensure that all required fields, including the `[etcd]` section, are updated with the correct details.

### 2. Enable Required Ports:

* **Execute `ports.yml` to enable ports:**
  ```bash
  ansible-playbook -i hosts.ini ports.yaml
  ```

### 3. Disable swap :

* Disable swap in cluster nodes.(Ignore if swap is already disabled)
  ```bash
  ansible-playbook -i hosts.ini swap.yaml
  ```

### 4. Run the Playbooks:

* **Run the playbook to provision RKE2 Cluster:**
  ```bash
  ansible-playbook -i hosts.ini main.yaml
  ```
  This command will start the installation and configuration process across all nodes.


### 5. Securely Store Kubeconfig File

After the successful creation of the RKE2 cluster, the kubeconfig file will be saved in the [k8s-infra/k8-cluster/on-prem/rke2/ansible/playbook/](k8s-infra/k8-cluster/on-prem/rke2/ansible/playbook/) directory as `{{ cluster_domain }}-{{ inventory_hostname }}.yaml`. Store it securely:

```bash
cp {{ cluster_domain }}-{{ inventory_hostname }}.yaml $HOME/.kube/<cluster_name>_config
chmod 400 $HOME/.kube/<cluster_name>_config
```
### 6. Access the Cluster

To access the cluster using the kubeconfig file, use one of the following methods:

* **Copy kubeconfig to default location:**
    ```bash
    cp $HOME/.kube/<cluster_name>_config $HOME/.kube/config
    ```

* **Or set the `KUBECONFIG` environment variable:**
    ```bash
    export KUBECONFIG="$HOME/.kube/<cluster_name>_config"
    ```

### 7. Test Cluster Access

Verify that you can access the cluster:

```bash
kubectl get nodes
```

