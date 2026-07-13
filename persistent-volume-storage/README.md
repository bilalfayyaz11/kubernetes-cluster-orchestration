# Kubernetes Persistent Volume Storage

## What This Does

This implementation provides persistent storage for Kubernetes workloads using a statically provisioned PersistentVolume and PersistentVolumeClaim.

An NGINX workload mounts the claim as its document directory and writes application content directly to persistent storage. The implementation verifies that data remains available after pod deletion and recreation, can be accessed from multiple pods on the same node, and can be monitored through dedicated validation workloads.

The environment also demonstrates container runtime preparation, Kubernetes control-plane initialization, Flannel networking, storage binding, host-to-container data access, capacity testing, and structured troubleshooting.

## Architecture

    +------------------------------------------------------+
    |                Ubuntu 24.04 Host                     |
    |                                                      |
    |  +------------------------------------------------+  |
    |  | Kubernetes v1.36 Control Plane                 |  |
    |  | kube-apiserver | scheduler | controller | etcd |  |
    |  +------------------------+-----------------------+  |
    |                           |                          |
    |                           v                          |
    |  +------------------------------------------------+  |
    |  | Flannel Container Network Interface           |  |
    |  | Pod Network: 10.244.0.0/16                    |  |
    |  +------------------------+-----------------------+  |
    |                           |                          |
    |                           v                          |
    |  +------------------------------------------------+  |
    |  | PersistentVolumeClaim                         |  |
    |  | Name: local-pvc                               |  |
    |  | Request: 500Mi                                |  |
    |  | Access Mode: ReadWriteOnce                    |  |
    |  +------------------------+-----------------------+  |
    |                           | Bound                    |
    |                           v                          |
    |  +------------------------------------------------+  |
    |  | PersistentVolume                              |  |
    |  | Name: local-pv                                |  |
    |  | Capacity: 1Gi                                 |  |
    |  | Reclaim Policy: Retain                        |  |
    |  | Storage Class: manual                         |  |
    |  +------------------------+-----------------------+  |
    |                           |                          |
    |                           v                          |
    |  +------------------------------------------------+  |
    |  | Host Storage                                  |  |
    |  | /mnt/data                                     |  |
    |  +------------------------+-----------------------+  |
    |                           ^                          |
    |             +-------------+-------------+            |
    |             |             |             |            |
    |             |             |             |            |
    |  +----------+---+ +-------+------+ +----+----------+ |
    |  | NGINX Pod    | | BusyBox Pod | | Monitor Pod   | |
    |  | Web Content  | | Shared Data | | Usage Checks  | |
    |  +--------------+ +--------------+ +---------------+ |
    +------------------------------------------------------+

## Prerequisites

- Ubuntu 24.04
- At least 2 CPU cores
- At least 2 GB of available memory
- Root or sudo access
- Internet connectivity
- Git
- curl
- GnuPG
- containerd
- runc
- kubeadm
- kubelet
- kubectl
- Flannel-compatible Pod network range
- Permission to modify kernel modules and sysctl settings

## Setup & Installation

Install the required operating-system packages:

sudo apt update

sudo apt install -y curl wget ca-certificates gnupg containerd.io

Configure the required kernel modules:

cat <<'MODULES' | sudo tee /etc/modules-load.d/kubernetes.conf
overlay
br_netfilter
MODULES

sudo modprobe overlay

sudo modprobe br_netfilter

Configure Kubernetes networking requirements:

cat <<'SYSCTL' | sudo tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
SYSCTL

sudo sysctl --system

Configure containerd:

sudo mkdir -p /etc/containerd

containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

sudo sed -i '/SystemdCgroup = false/s/false/true/' /etc/containerd/config.toml

sudo systemctl restart containerd

sudo systemctl enable containerd

Add the Kubernetes v1.36 package repository:

sudo mkdir -p -m 755 /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.36/deb/Release.key |
sudo gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.36/deb/ /' |
sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

sudo apt update

sudo apt install -y kubelet kubeadm kubectl

sudo apt-mark hold kubelet kubeadm kubectl

Initialize the single-node cluster:

NODE_IP=$(hostname -I | awk '{print $1}')

sudo kubeadm init \
  --apiserver-advertise-address="$NODE_IP" \
  --pod-network-cidr=10.244.0.0/16 \
  --cri-socket unix:///run/containerd/containerd.sock

Configure kubectl:

mkdir -p "$HOME/.kube"

sudo cp -f /etc/kubernetes/admin.conf "$HOME/.kube/config"

sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"

chmod 600 "$HOME/.kube/config"

Install Flannel:

kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

Allow workload scheduling on the single control-plane node:

kubectl taint nodes --all node-role.kubernetes.io/control-plane-

## How to Reproduce

Clone the repository:

git clone https://github.com/bilalfayyaz11/kubernetes-cluster-orchestration.git

cd kubernetes-cluster-orchestration/persistent-volume-storage

Create the host-backed storage directory:

sudo mkdir -p /mnt/data

sudo chmod 0777 /mnt/data

echo "Initial data from host" | sudo tee /mnt/data/host-file.txt

Create the PersistentVolume and PersistentVolumeClaim:

kubectl apply -f pv-storage.yaml

kubectl apply -f pvc-storage.yaml

Verify that the claim is bound:

kubectl get pv

kubectl get pvc

Deploy the NGINX workload:

kubectl apply -f pod-with-pvc.yaml

kubectl wait \
  --for=condition=Ready \
  pod/storage-pod \
  --timeout=180s

Verify that the host-created file is accessible:

kubectl exec storage-pod -- \
  cat /usr/share/nginx/html/host-file.txt

Create persistent content from inside the pod:

kubectl exec storage-pod -- sh -c \
  'echo "<h1>Persistent Storage Is Working</h1>" > /usr/share/nginx/html/index.html'

Verify that the file exists on the host:

sudo cat /mnt/data/index.html

Delete and recreate the pod:

kubectl delete pod storage-pod

kubectl apply -f pod-with-pvc.yaml

kubectl wait \
  --for=condition=Ready \
  pod/storage-pod \
  --timeout=180s

Verify that the data survived pod replacement:

kubectl exec storage-pod -- \
  cat /usr/share/nginx/html/index.html

Deploy a second workload using the same claim:

kubectl apply -f second-pod.yaml

kubectl wait \
  --for=condition=Ready \
  pod/second-storage-pod \
  --timeout=180s

Write data from the second pod:

kubectl exec second-storage-pod -- sh -c \
  'echo "Data from second pod" > /data/second-pod-data.txt'

Read the shared data from the NGINX pod:

kubectl exec storage-pod -- \
  cat /usr/share/nginx/html/second-pod-data.txt

Deploy the storage monitoring and validation workloads:

kubectl apply -f storage-monitor.yaml

kubectl apply -f storage-test.yaml

kubectl wait \
  --for=condition=Ready \
  pod/storage-monitor \
  --timeout=180s

kubectl wait \
  --for=condition=Ready \
  pod/storage-test \
  --timeout=180s

Review storage monitoring output:

kubectl logs storage-monitor --tail=30

Write and verify a larger data file:

kubectl exec storage-test -- sh -c '
for i in $(seq 1 100)
do
  echo "Line $i: $(date)"
done > /test-data/large-file.txt
'

kubectl exec storage-test -- \
  ls -lh /test-data/large-file.txt

kubectl exec storage-pod -- \
  tail -5 /usr/share/nginx/html/large-file.txt

Review the final state:

kubectl get nodes

kubectl get pods

kubectl get pv

kubectl get pvc

sudo ls -lah /mnt/data

## Configuration Files

- `pv-storage.yaml` defines the 1 GiB host-backed PersistentVolume.
- `pvc-storage.yaml` requests 500 MiB from the manual storage class.
- `pod-with-pvc.yaml` mounts persistent storage into an NGINX container.
- `second-pod.yaml` verifies storage access from another workload.
- `storage-monitor.yaml` reports disk usage, file count, and recent files.
- `storage-test.yaml` performs repeatable write and integrity validation.

## Tools Used

- Kubernetes v1.36
- kubeadm
- kubelet
- kubectl
- containerd
- runc
- Flannel
- NGINX
- BusyBox
- YAML
- Bash
- Linux
- Git

## Key Skills Demonstrated

- Kubernetes control-plane initialization with kubeadm
- Container Runtime Interface configuration
- containerd systemd cgroup configuration
- Kubernetes networking with Flannel
- Static PersistentVolume provisioning
- PersistentVolumeClaim creation and binding
- Persistent storage mounting
- Stateful workload validation
- Pod replacement and recovery testing
- Multi-pod storage access
- Host-to-container storage verification
- Storage usage monitoring
- Data integrity validation
- Kubernetes event and workload troubleshooting
- Reproducible image version pinning
- Linux kernel and networking preparation

## Real-World Use Case

Persistent storage is required for workloads whose data must survive container restarts, rescheduling, upgrades, and application failures. A platform engineering team could apply the same Kubernetes storage concepts to databases, content management systems, artifact repositories, monitoring platforms, CI/CD controllers, and internal developer services. In a production cluster, the host-backed volume used here would normally be replaced with a CSI-provisioned service such as cloud block storage, distributed storage, or an enterprise network filesystem.

## Lessons Learned

- Kubernetes nodes require correct kernel modules, forwarding rules, swap configuration, and runtime settings before cluster initialization.
- Docker Engine alone is not a Kubernetes CRI runtime, so kubeadm was explicitly configured to use containerd.
- The kubelet and container runtime must use compatible cgroup drivers to avoid node instability.
- PersistentVolume and PersistentVolumeClaim storage classes, access modes, and capacity requirements must match before binding can occur.
- Data stored through a claim remains independent of the lifecycle of an individual pod.
- A hostPath volume is useful for single-node validation but is not portable across nodes.
- Pinned container image versions make the environment more deterministic than floating image tags.
- Operational validation should include pod replacement, cross-pod access, host verification, and data integrity checks.

## Troubleshooting Log

Issue:
The supplied Kubernetes installation referenced the retired v1.28 package channel.

Resolution:
Installed kubeadm, kubelet, and kubectl from the Kubernetes v1.36 package repository and aligned all component versions.

Issue:
Docker Engine was installed, but Kubernetes requires a Container Runtime Interface-compatible runtime.

Resolution:
Configured kubeadm and kubelet to use containerd through `/run/containerd/containerd.sock`.

Issue:
The initial setup did not configure the Linux kernel modules and forwarding settings required for Kubernetes networking.

Resolution:
Loaded `overlay` and `br_netfilter`, enabled bridge packet processing, and enabled IPv4 forwarding.

Issue:
The default containerd configuration did not guarantee alignment with the kubelet cgroup driver.

Resolution:
Generated a clean containerd configuration and enabled `SystemdCgroup = true`.

Issue:
The machine contained multiple runtime-related components, which could make automatic runtime detection ambiguous.

Resolution:
Passed the containerd CRI socket explicitly during image pulling and control-plane initialization.

Issue:
Control-plane pods initially appeared as Pending immediately after initialization.

Resolution:
Allowed the kubelet and container runtime to complete static pod startup before applying further changes.

Issue:
The Kubernetes node remained NotReady before a Container Network Interface implementation was installed.

Resolution:
Installed Flannel with a Pod network range matching the range supplied to kubeadm.

Issue:
The control-plane node rejected normal workloads because of its default scheduling taint.

Resolution:
Removed the control-plane NoSchedule taint for the single-node environment.

Issue:
The original PersistentVolume definition did not validate that the host storage path already existed.

Resolution:
Added `hostPath.type: Directory` to fail clearly when `/mnt/data` is missing.

Issue:
The original workload definitions used floating `latest` image tags.

Resolution:
Pinned NGINX and BusyBox image versions for predictable reproduction.

Issue:
Interactive temporary test containers can hang in browser-based terminal environments.

Resolution:
Used controlled port forwarding and host-based curl requests for deterministic HTTP validation.

Issue:
Continuous background log following could leave an orphaned kubectl process.

Resolution:
Used bounded `kubectl logs --tail` and `kubectl logs --since` snapshots.

Issue:
Deleting the claim during the main validation could leave the retained PersistentVolume in a Released state.

Resolution:
Kept the claim intact during functional verification and reserved destructive cleanup for an optional final step.

Issue:
World-writable host permissions are not suitable for production systems.

Resolution:
Used permissive permissions only for isolated multi-container validation and documented the requirement for controlled ownership or security contexts in production.
