# MOSIP K8S Cluster Setup using RKE

## Overview
This is a guide to set up Kubernetes cluster on Virtual Machines using [RKE](https://rancher.com/products/rke). This cluster would host all MOSIP modules.

![Architecture](../../docs/_images/architecture.png)

## Prerequisites
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html).
  - For ubuntu:
    ```
    sudo apt update                                                                                                                             
    sudo apt install software-properties-common -y                                                                                             
    sudo add-apt-repository --yes --update ppa:ansible/ansible                                                                                                                                                                                                      
    sudo apt install ansible -y
    ```
- [Hardware, network, certificate requirements](./requirements.md).
- [Rancher](../../rancher).
- Command line utilities:
  - kubectl
    ```
    sudo apt install curl -y
    curl -LO "https://dl.k8s.io/release/v1.22.9/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /bin/
    ```
  - helm
    ```
    wget https://get.helm.sh/helm-v3.16.2-linux-amd64.tar.gz
    tar -zxvf helm-v3.16.2-linux-amd64.tar.gz
    sudo mv linux-amd64/helm /bin/helm
    ```
  - rke (rke version: v1.3.10)
    ```
    wget https://github.com/rancher/rke/releases/download/v1.3.10/rke_linux-amd64
    chmod +x rke_linux-amd64
    sudo mv rke_linux-amd64 /bin/rke
    ```
  - istioctl (istioctl version: v1.15.0)
    ```
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.15.0 TARGET_ARCH=x86_64 sh -
    sudo mv istio-1.15.0/bin/istioctl /bin/
    ```
- Helm repos:
  ```sh
  helm repo add bitnami https://charts.bitnami.com/bitnami
  helm repo add mosip https://mosip.github.io/mosip-helm
  ```
## Virtual machines
* Set up VMs.
* Set up [passwordless SSH](../../docs/ssh.md).
* Create copy of `hosts.ini.sample` as `hosts.ini`. Update the IP addresses.

## Wireguard bastion node
_If you already have a Wireguard bastion host then you may skip this step._

* Open required Wireguard ports.
  ```
  ansible-playbook -i hosts.ini wireguard.yaml
  ```
* Install [Wireguard bastion host](https://docs.mosip.io/1.2.0/deployment/wireguard/wireguard-bastion) with enough number of peers.
- Assign peer1 to yourself and set your Wireguard client before working on the cluster.

## Ports
_If the ports are already managed by a firewall, this step can be skipped._

* Open ports on each of the nodes.
  ```
  ansible-playbook -i hosts.ini ports.yaml
  ```
* Disable swap _(perhaps not needed as swap is already disabled)_.
  ```
  ansible-playbook -i hosts.ini swap.yaml
  ```
## Environment Check
To Perform Environment check on all the cluster nodes
```
ansible-playbook -i hosts.ini env-check.yaml
```
## Docker
* Update the registry mirrors server host and port `"registry-mirrors": ["http://<IP>:5000"]` in `daemon.json` file.
* If the `registry-mirrors` entry in the `daemon.json` file is not required, remove it.
  Be sure to delete the preceding comma if it was placed before `registry-mirrors`.
* Install docker on all nodes.
  ```
  ansible-playbook -i hosts.ini docker.yaml
  ```

## RKE cluster setup
* Create a cluster config file. 
    ```
    rke config
    ```
    *  _controlplane, etcd, worker_: Specify _controlplane_, _etc_ on at least **three** nodes. All nodes may be _worker_.
    * Use default _canal_ networking model
    * Keep the _Pod Security Policies_ disabled.
    * Sample configuration options:
    ```
    [+] Cluster Level SSH Private Key Path [~/.ssh/id_rsa]:
    [+] Number of Hosts [1]:
    [+] SSH Address of host (1) [none]: <node1-ip>
    [+] SSH Port of host (1) [22]:
    [+] SSH Private Key Path of host (<node1-ip>) [none]:
    [-] You have entered empty SSH key path, trying fetch from SSH key parameter
    [+] SSH Private Key of host (<node1-ip>) [none]:
    [-] You have entered empty SSH key, defaulting to cluster level SSH key: ~/.ssh/id_rsa
    [+] SSH User of host (<node1-ip>) [ubuntu]:
    [+] Is host (<node1-ip>) a Control Plane host (y/n)? [y]: y
    [+] Is host (<node1-ip>) a Worker host (y/n)? [n]: y
    [+] Is host (<node1-ip>) an etcd host (y/n)? [n]: y
    [+] Override Hostname of host (<node1-ip>) [none]: node2
    [+] Internal IP of host (<node1-ip>) [none]:
    [+] Docker socket path on host (<node1-ip>) [/var/run/docker.sock]:
    [+] Network Plugin Type (flannel, calico, weave, canal) [canal]:
    [+] Authentication Strategy [x509]:
    [+] Authorization Mode (rbac, none) [rbac]:
    [+] Kubernetes Docker image [rancher/hyperkube:v1.17.17-rancher1]:
    [+] Cluster domain [cluster.local]:
    [+] Service Cluster IP Range [10.43.0.0/16]:
    [+] Enable PodSecurityPolicy [n]:
    [+] Cluster Network CIDR [10.42.0.0/16]:
    [+] Cluster DNS Service IP [10.43.0.10]:
    [+] Add addon manifest URLs or YAML files [no]:
    ```
* While opting for roles for different nodes follow below points:
  * In case of odd no of total nodes of cluster opt for (n+1/2) nodes with Control plane, etcd host and worker host role and rest of the nodes with Worker host and etcd host role.
  * In case of even no of total nodes of cluster opt for (n/2) nodes with Control Plane, etcd host and worker host role and rest of the node with Worker host and etcd host role.

* Remove the default Ingress install by editing `cluster.yml`:
  ```
  ingress:
    provider: none
  ```
* Add the name of the kubernetes cluster in `cluster.yml`:
  ```
  cluster_name: sandbox-name
  ```
* Add this ETCD backup_config section under services in cluster.yml to enable recurring snapshots for ETCD:
  ```
  backup_config:
    interval_hours: 12
    retention: 6
  ```
* Update node labels to `vlan: 200`, `vlan: 100`, `vlan: 101`, or `vlan: 202` in `cluster.yml` for all the cluster nodes.
  ```
  nodes:
  - address: xxxx
    labels:
      vlan: '200'
  ```

* [Sample config file](sample.cluster.yml) is provider in this folder.

* For production deployments edit the `cluster.yml`, according to this [RKE Cluster Hardening Guide](../../docs/rke-cluster-hardening.md).

* Bring up the cluster:
  ```
  rke up
  ```
* After successful creation of cluster a `kube_config_cluster.yaml` will get created. Copy the file to `$HOME/.kube` folder.
  ```
  cp kube_config_cluster.yml $HOME/.kube/<cluster_name>_config
  chmod 400 $HOME/.kube/<cluster_name>_config
  ```
* To set this file as global default for `kubectl`, make sure you have a copy of existing `$HOME/.kube/config`. 
  ```
  cp  $HOME/.kube/<cluster_name>_config  $HOME/.kube/config
  ```
* Alternatively, set `KUBECOFIG` env variable:
  ```
  export KUBECONFIG=$HOME/.kube/<cluster_name>_config
  ```
* Test
  ```
  kubectl get nodes
  ```

## Global configmap
* `cd ../`
* Copy `global_configmap.yaml.sample` to `global_configmap.yaml`  
* Update the domain names in `global_configmap.yaml` and run
  ```sh
  kubectl apply -f global_configmap.yaml
  ```

## Register the cluster with Rancher
* Login as `admin` in Rancher console
* Select `Import Existing` for cluster addition.
* Select the `Generic` as cluster type to add.
* Fill the `Cluster Name` field with unique cluster name and select `Create`.
* You will get the kubecl commands to be executed in the kubernetes cluster
  ```
  eg.
  kubectl apply -f https://rancher.e2e.mosip.net/v3/import/pdmkx6b4xxtpcd699gzwdtt5bckwf4ctdgr7xkmmtwg8dfjk4hmbpk_c-m-db8kcj4r.yaml
  ```
* Wait for few seconds after executing the command for the cluster to get verified.
* Your cluster is now added to the rancher management server.

## Setup storage class
* Install [NFS server & client provisioner](../nfs/README.md)

## Monitoring
* Install [monitoring](../../monitoring/README.md)

## Istio for service discovery and Ingress
* `cd /istio/`
* Edit `iop.yaml` if required.
  ```
  export KUBECONFIG="$HOME/.kube/<cluster_name>_config
  ./install.sh
  ```
* This will bring up all Istio components and the Ingress Gateways.
* Check Ingress Gateway services:
  ```
  kubectl get svc -n istio-system
  ```

## Logging
* Install [Logging](../../logging/README.md)

## Nginx
* Install [Nginx Reverse Proxy](./nginx/) on a separate machine/VM, that proxies traffic to the above Ingress Gateways.

## DNS mapping
* Point your domain names to respective public IP or internal IP of the Nginx node. Refer to the [DNS Requirements](./requirements.md#DNS_requirements) document and your `global_configmap.yaml` to correlate the mappings.

## Httpbin
* Install [`httpbin`](../../utils/httpbin/README.md) for testing the wiring.

## RKE Cluster tools:
Below contains some of the RKE cluster related operations in brief:

Note: Before adding/removing nodes make sure that ```rke version``` should be same as you have installed during initial cluster creation as mentioned in the Pre-requisites. 

* Adding/Removing nodes to cluster
  _This step is only required if you have to add/delete nodes to an existing cluster._
  * Copy the ssh keys, setup Docker and open ports as given above.
  * Edit the `cluster.yml` file and add extra nodes with their IPs and roles.
  * Run `rke up --update-only` to bring up the changes to the cluster.
* Removing the whole RKE cluster:
  _This step is only required if you knowingly want to delete existing complete cluster and its dependent binaries._
  * From the folder containing `cluster.yml`, `cluster-rke.state`, `kube-config-cluster.yml` files created while cluster creation, run the below>
    ```
    rke remove
    ```
  * Remove the cluster components and  binaries from all the nodes using `rke-recovery.sh`
    ```
    cd utils
    ansible-playbook -i hosts.ini ../../utils/rke-components-delete.yaml
    ```
* Recovering the original `cluster.rkestate` file and `cluster.yml` file created during cluster intialisation.
  _This step is only required if you have lost the `cluster.rkestate` and cluster.yaml file for a RKE cluster._
  * Set the kubeconfig file pointing to respective RKE cluster using any of the way mentioneed in cluster creation section above.
  * run the below script to recover the `cluster.yml` and rkestate.yml
  ```
  ./../../utils/rke-recovery.sh [kubeconfig]
  ```
  * ``cluster.yml`` and `cluster.rkestate` will be created in the same directory, do preserve the same for further use.
* RKE cluster certificate rotation:
  _This step is only required if your cluster certificates are expired and the same needs to be rotated._
  Note: Whenever you’re trying to rotate certificates, the `cluster.yml` that was used to deploy the Kubernetes cluster is required. You can reference a different location for this file by using the --config option. In case you dont have the `cluster.yml` follow above steps to recover it.
  * Follow the [instruction](https://rancher.com/docs/rke/latest/en/cert-mgmt/#certificate-rotation) to rotate the certificate on need basis.
  __Note:__ Please do check the persion in the Rancher docs.

## Troubleshooting
* **Environment check issue**: If an issue arises as localhost mapping is not present in the hosts file of the system then it could be due to `localhost not being       mapped to 127.0.0.1` within `/etc/hosts` file of the system.

  Resolution: An ansible script has been written and the task is automated to reduce the effort of checking all the nodes of the cluster. This was extremely tedious     and time consuming manually and if an error arises as `localhost mapping not present` after running the script then we need to map the localhost to 127.0.0.1 within   `/etc/hosts` file of one or all the nodes of the cluster.

  To view the ansible script or make any changes 
  File_name: "env-check.yaml"

* **Node Addition Issue**: while adding or removing nodes if you are observing the below-mentioned issues it's better to recreate the nodes to proceed further.
``cannot proceed with upgrade of controlplane since 3 host(s) cannot be reached prior to upgrade
retrying of unary invoker failed
rpc error: code = Unavailable desc = etcdserver: unhealthy cluster``
