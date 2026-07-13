# Kubernetes Pod Networking with Calico CNI

## What This Does

This implementation provisions networking for a single-node Kubernetes cluster using the Calico Container Network Interface plugin.

It configures pod IP allocation, inter-pod routing, Kubernetes service discovery, ClusterIP communication, and ingress traffic controls through Kubernetes NetworkPolicy resources. Dedicated diagnostic containers validate ICMP, DNS, HTTP, TCP port connectivity, service routing, and policy enforcement.

The implementation also includes reusable verification scripts that collect cluster networking information and confirm that permitted traffic succeeds while unauthorized traffic is blocked.

This type of configuration is used by Platform Engineering, DevOps, SRE, Cloud Infrastructure, and Kubernetes Operations teams to provide reliable and controlled communication between containerized workloads.

## Architecture

    +----------------------------------------------------------+
    |                    Kubernetes Node                       |
    |                 Ubuntu 24.04 on AWS                      |
    |                                                          |
    |   +--------------------------------------------------+   |
    |   |              Kubernetes Control Plane            |   |
    |   |                                                  |   |
    |   |  kube-apiserver   scheduler   controller-manager |   |
    |   |  etcd             CoreDNS      kube-proxy        |   |
    |   +-------------------------+------------------------+   |
    |                             |                            |
    |                             v                            |
    |   +--------------------------------------------------+   |
    |   |                  Calico CNI                      |   |
    |   |                                                  |   |
    |   |  IP Address Management                           |   |
    |   |  Pod Routing                                     |   |
    |   |  Workload Endpoints                              |   |
    |   |  NetworkPolicy Enforcement                       |   |
    |   +-------------------------+------------------------+   |
    |                             |                            |
    |           +-----------------+-----------------+          |
    |           |                 |                 |          |
    |           v                 v                 v          |
    |   +---------------+ +---------------+ +---------------+ |
    |   | test-pod-1    | | test-pod-2    | | test-pod-3    | |
    |   |               | |               | |               | |
    |   | Nginx         | | BusyBox       | | Netshoot      | |
    |   | Network Tools | | DNS / HTTP    | | TCP / HTTP    | |
    |   +-------+-------+ +-------+-------+ +-------+-------+ |
    |           |                 |                 |          |
    |           +-----------------+-----------------+          |
    |                             |                            |
    |                             v                            |
    |                 +----------------------+                 |
    |                 | ClusterIP Service    |                 |
    |                 | test-service-1       |                 |
    |                 | TCP Port 80          |                 |
    |                 +----------------------+                 |
    |                                                          |
    |   NetworkPolicy:                                         |
    |   test-pod-2 -> test-pod-1:80  ALLOWED                   |
    |   test-pod-3 -> test-pod-1:80  BLOCKED                   |
    +----------------------------------------------------------+

## Prerequisites

- Ubuntu 24.04
- Root or sudo access
- Docker
- containerd
- Kubernetes kubeadm
- Kubernetes kubelet
- Kubernetes kubectl
- curl
- Git
- iproute2
- iptables
- conntrack
- socat
- Internet access for container images and package repositories
- At least 2 CPU cores
- At least 2 GB of memory

## Setup & Installation

Install the required operating-system packages:

sudo apt-get update

sudo apt-get install -y ca-certificates curl gpg iproute2 iptables conntrack socat

Configure the Kubernetes package repository:

sudo mkdir -p -m 755 /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.36/deb/Release.key \
  | sudo gpg --dearmor --yes \
  -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.36/deb/ /' \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update

sudo apt-get install -y kubeadm kubelet kubectl

sudo apt-mark hold kubeadm kubelet kubectl

Disable swap:

sudo swapoff -a

sudo sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab

Load the required kernel modules:

cat <<'MODULES' | sudo tee /etc/modules-load.d/kubernetes.conf
overlay
br_netfilter
MODULES

sudo modprobe overlay

sudo modprobe br_netfilter

Configure kernel networking:

cat <<'SYSCTL' | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
SYSCTL

sudo sysctl --system

Configure containerd with systemd cgroups:

sudo mkdir -p /etc/containerd

containerd config default | sudo tee /etc/containerd/config.toml

sudo sed -i '/disabled_plugins.*cri/d' /etc/containerd/config.toml

sudo sed -i \
  "/\[plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.runc.options\]/,/^\[/ s/SystemdCgroup = false/SystemdCgroup = true/" \
  /etc/containerd/config.toml

sudo systemctl restart containerd

sudo systemctl enable --now containerd

sudo systemctl enable --now kubelet

## How to Reproduce

Initialize the Kubernetes control plane:

NODE_IP=$(hostname -I | awk '{print $1}')

sudo kubeadm init \
  --apiserver-advertise-address="$NODE_IP" \
  --pod-network-cidr=192.168.0.0/16 \
  --node-name="$(hostname)"

Configure kubectl:

mkdir -p "$HOME/.kube"

sudo cp /etc/kubernetes/admin.conf "$HOME/.kube/config"

sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"

chmod 600 "$HOME/.kube/config"

Allow workloads on the single control-plane node:

kubectl taint nodes --all node-role.kubernetes.io/control-plane-

Install Calico:

kubectl apply -f calico.yaml

Wait for the node to become ready:

kubectl wait \
  --for=condition=Ready \
  node/"$(hostname)" \
  --timeout=300s

Create the networking workloads:

kubectl apply -f pod1.yaml

kubectl apply -f pod2.yaml

kubectl apply -f pod3.yaml

kubectl apply -f service1.yaml

Wait for the pods:

kubectl wait --for=condition=Ready pod/test-pod-1 --timeout=180s

kubectl wait --for=condition=Ready pod/test-pod-2 --timeout=180s

kubectl wait --for=condition=Ready pod/test-pod-3 --timeout=180s

Run the connectivity validation:

chmod +x connectivity-test.sh network-report.sh

./connectivity-test.sh

Generate the network report:

./network-report.sh | tee network-report.txt

Apply the ingress policy:

kubectl apply -f network-policy.yaml

Verify the policy:

kubectl get networkpolicy

kubectl describe networkpolicy allow-test-pod-2-to-test-pod-1

## Network Validation

The implementation validates the following traffic paths:

- Pod-to-pod ICMP connectivity
- Direct HTTP access to a pod IP
- Kubernetes ClusterIP service routing
- CoreDNS service-name resolution
- TCP port 80 connectivity
- Calico workload endpoint creation
- Calico IP pool allocation
- Allowed NetworkPolicy traffic
- Blocked NetworkPolicy traffic

## Tools Used

- Kubernetes
- Calico CNI
- kubeadm
- kubelet
- kubectl
- containerd
- Docker
- CoreDNS
- kube-proxy
- Kubernetes NetworkPolicy
- Kubernetes EndpointSlice
- Nginx
- BusyBox
- Netshoot
- Bash
- Linux
- curl
- wget
- ping
- netcat
- ss
- Git
- AWS EC2

## Key Skills Demonstrated

- Kubernetes control-plane initialization
- Container runtime configuration
- Container Network Interface deployment
- Pod IP address management
- Kubernetes pod routing
- Service discovery with CoreDNS
- ClusterIP service validation
- EndpointSlice inspection
- NetworkPolicy implementation
- Zero-trust workload communication controls
- Linux kernel networking configuration
- systemd cgroup integration
- Kubernetes workload troubleshooting
- Container-based network diagnostics
- Infrastructure verification automation
- Security-aware cluster configuration

## Real-World Use Case

Production Kubernetes platforms require reliable communication between microservices while preventing unnecessary access between workloads. Calico provides pod networking and policy enforcement that allows platform teams to define which applications may communicate, on which ports, and in which direction. This approach can isolate frontend, backend, database, monitoring, and administrative workloads while preserving required service-to-service communication. The same model is commonly used to reduce lateral movement risk, enforce application boundaries, support compliance controls, and troubleshoot connectivity failures in multi-service environments.

## Lessons Learned

- Kubernetes nodes remain NotReady until a compatible CNI implementation is installed.
- kube-proxy should not be skipped unless an explicitly configured replacement handles Kubernetes service routing.
- containerd 2.x uses a different CRI configuration structure than older containerd releases.
- Diagnostic tools should be included in purpose-built containers instead of installed manually after a pod starts.
- Floating image tags reduce reproducibility and should be replaced with pinned versions.
- Kubernetes NetworkPolicy resources only take effect when the installed CNI supports policy enforcement.
- Service connectivity requires several working layers: pod networking, CoreDNS, EndpointSlices, and kube-proxy.
- Bootstrap logs should not be committed because they may contain temporary authentication material.

## Troubleshooting Log

Issue:
The original Kubernetes installation method used apt-key and the retired apt.kubernetes.io repository.

Resolution:
Configured the versioned pkgs.k8s.io repository with a dedicated signed keyring.

Issue:
Ubuntu suggested installing kubeadm and kubelet through Snap.

Resolution:
Installed matching Kubernetes components through the official APT repository to keep package versions, service management, and upgrade behavior consistent.

Issue:
The original initialization command skipped kube-proxy.

Resolution:
Initialized the cluster without skipping kube-proxy because the implementation uses standard Kubernetes ClusterIP routing rather than Calico eBPF kube-proxy replacement mode.

Issue:
The Kubernetes node remained NotReady immediately after initialization.

Resolution:
Installed Calico CNI and waited for the Calico node daemon, Calico controllers, CoreDNS, and Kubernetes node readiness conditions.

Issue:
The original configuration used an outdated Calico manifest version.

Resolution:
Downloaded a modern Calico manifest compatible with the active Kubernetes release.

Issue:
The original workload definitions used floating latest image tags.

Resolution:
Pinned container image versions to improve reproducibility and reduce unexpected behavior.

Issue:
The original workflow attempted to run ping from a standard Nginx container.

Resolution:
Added a dedicated BusyBox networking sidecar that shares the pod network namespace with Nginx.

Issue:
The original workflow installed curl and netcat interactively inside a running Alpine container.

Resolution:
Used a purpose-built Netshoot image containing the required networking utilities.

Issue:
The original Calico inspection commands assumed calicoctl was installed inside the Calico node container.

Resolution:
Queried Calico custom resources directly through kubectl, including IP pools, workload endpoints, and Calico node resources.

Issue:
The original service verification relied on the legacy Endpoints view.

Resolution:
Validated Kubernetes EndpointSlice resources, which are the modern scalable representation of service backends.

Issue:
The network policy needed to allow one client while denying another.

Resolution:
Applied an ingress policy selecting the Nginx pod and allowing TCP port 80 only from pods labeled app=test-pod-2.

Issue:
The Kubernetes bootstrap output contained temporary authentication information.

Resolution:
Excluded kubeadm-init.log from the Git repository.
