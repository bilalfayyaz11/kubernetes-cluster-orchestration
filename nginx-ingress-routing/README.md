# Kubernetes Ingress Routing with NGINX

## What This Does

This implementation provides centralized HTTP traffic routing for Kubernetes applications through the NGINX Ingress Controller.

It exposes multiple internal ClusterIP services through a single NodePort entry point and routes requests using URL paths and HTTP hostnames. Requests to `/app1` and `/app2` are sent to separate replicated workloads, while `app1.local` and `app2.local` demonstrate hostname-based routing.

The configuration also includes a custom fallback backend, URL rewriting, response headers, endpoint validation, controller log inspection, and automated routing verification.

This architecture is commonly used by Platform Engineering, DevOps, SRE, and Cloud Infrastructure teams to expose web applications and APIs without creating a separate external load balancer for every service.

## Architecture

    +--------------------------------------------------------------+
    |                       External Client                        |
    |                                                              |
    |  Requests:                                                   |
    |  /app1              /app2                                    |
    |  Host: app1.local   Host: app2.local                         |
    +-----------------------------+--------------------------------+
                                  |
                                  v
    +--------------------------------------------------------------+
    |                    Kubernetes NodePort                        |
    |               ingress-nginx-controller                       |
    |                       HTTP Gateway                            |
    +-----------------------------+--------------------------------+
                                  |
                                  v
    +--------------------------------------------------------------+
    |                  NGINX Ingress Controller                     |
    |                                                              |
    |  Path Routing              Host Routing                       |
    |  /app1 -> app1-service     app1.local -> app1-service        |
    |  /app2 -> app2-service     app2.local -> app2-service        |
    |                                                              |
    |  Advanced Routes                                             |
    |  /advanced/app1 -> app1-service                              |
    |  /advanced/app2 -> app2-service                              |
    |                                                              |
    |  Unmatched traffic -> default-backend-service                |
    +------------+----------------+----------------+----------------+
                 |                |                |
                 v                v                v
    +-------------------+ +-------------------+ +-------------------+
    | app1-service      | | app2-service      | | default-backend   |
    | ClusterIP :80     | | ClusterIP :80     | | ClusterIP :80     |
    +---------+---------+ +---------+---------+ +---------+---------+
              |                     |                     |
              v                     v                     v
    +-------------------+ +-------------------+ +-------------------+
    | App 1 Deployment  | | App 2 Deployment  | | Default Backend   |
    | 2 NGINX replicas  | | 2 NGINX replicas  | | 1 NGINX replica   |
    +-------------------+ +-------------------+ +-------------------+

    Cluster Networking:
    Kubernetes -> Flannel CNI -> Pod IP allocation and routing

## Prerequisites

- Ubuntu 24.04
- Root or sudo access
- At least 2 CPU cores
- At least 4 GB of memory
- Internet access
- Git
- curl
- containerd
- kubeadm
- kubelet
- kubectl
- conntrack
- socat
- iproute2
- iptables

## Setup & Installation

Install the required operating-system packages:

sudo apt-get update

sudo apt-get install -y \
  ca-certificates \
  curl \
  gpg \
  conntrack \
  socat \
  iproute2 \
  iptables

Configure the Kubernetes v1.36 package repository:

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

Configure Kubernetes networking parameters:

cat <<'SYSCTL' | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
SYSCTL

sudo sysctl --system

Configure containerd with systemd cgroups:

sudo mkdir -p /etc/containerd

containerd config default \
  | sudo tee /etc/containerd/config.toml >/dev/null

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
  --pod-network-cidr=10.244.0.0/16 \
  --node-name="$(hostname)"

Configure kubectl:

mkdir -p "$HOME/.kube"

sudo cp /etc/kubernetes/admin.conf "$HOME/.kube/config"

sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"

chmod 600 "$HOME/.kube/config"

Allow workloads on the single-node control plane:

kubectl taint nodes --all node-role.kubernetes.io/control-plane-

Install Flannel:

kubectl apply -f kube-flannel.yml

Wait for the node:

kubectl wait \
  --for=condition=Ready \
  node/"$(hostname)" \
  --timeout=300s

Install the NGINX Ingress Controller:

kubectl apply -f ingress-nginx-baremetal.yaml

Wait for the controller:

kubectl rollout status \
  deployment/ingress-nginx-controller \
  -n ingress-nginx \
  --timeout=300s

Deploy the backend applications:

kubectl apply -f applications.yaml

kubectl rollout status deployment/app1 --timeout=180s

kubectl rollout status deployment/app2 --timeout=180s

kubectl rollout status deployment/default-backend --timeout=180s

Apply path-based and host-based routing:

kubectl apply -f ingress-rules.yaml

Apply the advanced routes and custom headers:

kubectl apply -f advanced-ingress.yaml

Verify all Ingress resources:

kubectl get ingress -o wide

Run the automated routing validation:

chmod +x ingress-validation.sh ingress-report.sh

./ingress-validation.sh

Generate the configuration report:

./ingress-report.sh | tee ingress-report.txt

## Routing Behavior

Path-based routes:

- `/app1` routes to `app1-service`
- `/app2` routes to `app2-service`
- `/advanced/app1` routes to `app1-service`
- `/advanced/app2` routes to `app2-service`
- Unknown paths route to `default-backend-service`

Host-based routes:

- `app1.local` routes to `app1-service`
- `app2.local` routes to `app2-service`

Host routing can be tested without changing local DNS:

MACHINE_IP=$(hostname -I | awk '{print $1}')

HTTP_PORT=$(kubectl get service ingress-nginx-controller \
  -n ingress-nginx \
  -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')

curl -H "Host: app1.local" \
  "http://$MACHINE_IP:$HTTP_PORT/"

curl -H "Host: app2.local" \
  "http://$MACHINE_IP:$HTTP_PORT/"

## Tools Used

- Kubernetes
- NGINX Ingress Controller
- Flannel CNI
- kubeadm
- kubelet
- kubectl
- containerd
- Kubernetes Ingress
- Kubernetes Services
- Kubernetes Deployments
- Kubernetes ConfigMaps
- Kubernetes EndpointSlices
- NGINX
- Bash
- curl
- Linux
- Git
- AWS EC2

## Key Skills Demonstrated

- Kubernetes control-plane initialization
- Container runtime configuration
- CNI deployment and pod networking
- NGINX Ingress Controller deployment
- Kubernetes external traffic management
- Path-based HTTP routing
- Host-based HTTP routing
- Default backend configuration
- URL rewriting
- Custom response headers
- ClusterIP service exposure
- IngressClass usage
- EndpointSlice validation
- Controller log analysis
- Reverse proxy troubleshooting
- Automated HTTP route verification
- Reproducible Kubernetes manifest design

## Real-World Use Case

Organizations commonly run many web applications and internal APIs inside Kubernetes while exposing them through a limited number of external entry points. An Ingress Controller acts as a reverse proxy and routing gateway, directing traffic according to hostnames and URL paths. This reduces load-balancer sprawl, centralizes routing behavior, and supports microservice architectures, multi-tenant platforms, internal developer portals, API endpoints, and customer-facing applications. In production, the same design can be extended with TLS certificates, external DNS, rate limiting, web application firewalls, authentication, observability, and highly available controller replicas.

## Lessons Learned

- An Ingress resource does not process traffic by itself; an Ingress Controller must be installed and running.
- NodePort provides a practical external entry point for bare-metal and single-node Kubernetes environments.
- Path-based routing allows several applications to share one IP address and port.
- Host-based routing depends on the HTTP Host header and can be tested without modifying DNS.
- A custom default backend provides controlled responses for unmatched routes.
- Backend services must have healthy EndpointSlices before Ingress routing can succeed.
- Configuration snippet annotations may be disabled because they can inject arbitrary NGINX directives.
- Purpose-built response-header ConfigMaps are safer than unrestricted NGINX configuration snippets.
- Controller logs provide immediate evidence of route synchronization, configuration reloads, and upstream failures.

## Troubleshooting Log

Issue:
The original Kubernetes installation used the Kubernetes v1.28 package repository.

Resolution:
Configured the versioned Kubernetes v1.36 repository to match the installed kubectl client and current package layout.

Issue:
Ubuntu suggested installing kubeadm and kubelet through Snap.

Resolution:
Installed matching components from the official Kubernetes APT repository to maintain consistent versions and systemd service behavior.

Issue:
The source described Docker as the Kubernetes runtime.

Resolution:
Used containerd through the Kubernetes Container Runtime Interface and configured the systemd cgroup driver.

Issue:
The Kubernetes node remained NotReady immediately after initialization.

Resolution:
Installed Flannel CNI and waited for Flannel, CoreDNS, and node readiness.

Issue:
The source used a floating Flannel download URL.

Resolution:
Resolved a specific published Flannel release and saved the manifest locally for reproducibility.

Issue:
The original NGINX Ingress Controller manifest pinned controller v1.8.2.

Resolution:
Downloaded a current official bare-metal manifest and stored it inside the repository.

Issue:
Application Deployments were defined before their ConfigMaps.

Resolution:
Created each ConfigMap before the dependent Deployment to prevent missing-volume startup delays.

Issue:
Application containers used the outdated nginx:1.21 image.

Resolution:
Used a pinned Alpine-based NGINX image to improve reproducibility and reduce image size.

Issue:
Repeated test runs could append duplicate app1.local and app2.local entries to /etc/hosts.

Resolution:
Tested host-based routing with explicit HTTP Host headers instead of modifying system DNS configuration.

Issue:
The advanced route used configuration-snippet annotations.

Resolution:
Used a dedicated ConfigMap with the custom-headers annotation because unrestricted snippet directives are frequently disabled for security reasons.

Issue:
The original monitoring approach started kubectl logs in the background.

Resolution:
Used a bounded controller log tail to avoid orphaned processes in browser-based terminal sessions.

Issue:
Legacy endpoint commands were used for backend verification.

Resolution:
Validated EndpointSlice resources, which are the current scalable service-backend representation.

Issue:
Kubernetes initialization logs can contain temporary bootstrap credentials.

Resolution:
Excluded kubeadm-init.log from all Git commits.
