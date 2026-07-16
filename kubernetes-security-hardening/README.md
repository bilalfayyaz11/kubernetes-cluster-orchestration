# Kubernetes Security Hardening and Compliance Assessment

## What This Does

This implementation builds and secures a single-node Kubernetes cluster using preventive, detective, and operational security controls.

The environment enforces Kubernetes Pod Security Standards, deploys workloads with hardened security contexts, restricts pod communication through NetworkPolicies, and protects cluster capacity with ResourceQuotas and LimitRanges. Trivy scans container images and Kubernetes resources for vulnerabilities and configuration risks, while Kube-bench evaluates the control plane and worker configuration against the CIS Kubernetes Benchmark.

Reusable shell automation generates security summaries, benchmark analysis, cluster posture reports, and a terminal-based monitoring dashboard. Together, these components demonstrate how platform and security engineering teams can continuously evaluate and improve Kubernetes security.

## Architecture

    +------------------------------------------------------------------+
    |                     Kubernetes Control Plane                      |
    |                                                                  |
    |  +----------------+  +----------------+  +--------------------+  |
    |  | API Server     |  | Scheduler      |  | Controller Manager |  |
    |  +--------+-------+  +--------+-------+  +----------+---------+  |
    |           |                   |                     |            |
    |           +-------------------+---------------------+            |
    |                               |                                  |
    |                         +-----v------+                           |
    |                         |    etcd    |                           |
    |                         +-----+------+                           |
    +-------------------------------|----------------------------------+
                                    |
                                    v
    +------------------------------------------------------------------+
    |                    Kubernetes Security Controls                   |
    |                                                                  |
    |  +----------------------+  +-------------------------------+     |
    |  | Pod Security         |  | Hardened Workload Context     |     |
    |  | Standards            |  |                               |     |
    |  |                      |  | Non-root execution            |     |
    |  | Privileged           |  | RuntimeDefault seccomp        |     |
    |  | Baseline             |  | Read-only root filesystem     |     |
    |  | Restricted           |  | Dropped Linux capabilities    |     |
    |  +----------+-----------+  +---------------+---------------+     |
    |             |                              |                     |
    |  +----------v-----------+  +---------------v---------------+     |
    |  | Calico NetworkPolicy |  | Resource Governance           |     |
    |  | Enforcement          |  |                               |     |
    |  |                      |  | ResourceQuota                 |     |
    |  | Ingress controls     |  | LimitRange                    |     |
    |  | Egress controls      |  | CPU and memory constraints    |     |
    |  +----------+-----------+  +---------------+---------------+     |
    +-------------|------------------------------|---------------------+
                  |                              |
                  v                              v
    +------------------------------------------------------------------+
    |                   Security Assessment Tooling                     |
    |                                                                  |
    |  +----------------------+  +-------------------------------+     |
    |  | Trivy                |  | Kube-bench                    |     |
    |  |                      |  |                               |     |
    |  | Image CVE scanning   |  | CIS benchmark assessment      |     |
    |  | Cluster scanning     |  | Control-plane checks          |     |
    |  | Misconfiguration     |  | Node and etcd checks          |     |
    |  | analysis             |  | Remediation guidance          |     |
    |  +----------+-----------+  +---------------+---------------+     |
    +-------------|------------------------------|---------------------+
                  |                              |
                  +---------------+--------------+
                                  |
                                  v
    +------------------------------------------------------------------+
    |                    Reporting and Monitoring                       |
    |                                                                  |
    |  reports/*.json                                                  |
    |  reports/*.txt                                                   |
    |  analyze-kube-bench.sh                                           |
    |  generate-security-summary.sh                                    |
    |  final-security-assessment.sh                                    |
    |  security-monitor.sh                                             |
    +------------------------------------------------------------------+

## Prerequisites

- Ubuntu 24.04 LTS
- At least 2 CPU cores
- At least 4 GiB of memory
- At least 20 GiB of available disk space
- A user with sudo privileges
- Internet access for package repositories and container images
- Git
- curl
- GnuPG
- jq
- tree
- containerd
- runc
- kubeadm
- kubelet
- kubectl
- Trivy
- Kube-bench
- Calico networking

## Setup & Installation

Update the operating system and install the required base utilities:

sudo apt-get update

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gpg \
  jq \
  tree

Configure the kernel modules required by Kubernetes networking:

cat <<'KERNEL_MODULES' | sudo tee /etc/modules-load.d/kubernetes.conf
overlay
br_netfilter
KERNEL_MODULES

sudo modprobe overlay

sudo modprobe br_netfilter

Configure bridge networking and IPv4 forwarding:

cat <<'KERNEL_SYSCTL' | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
KERNEL_SYSCTL

sudo sysctl --system

Install and configure containerd:

sudo apt-get install -y containerd

sudo mkdir -p /etc/containerd

containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

sudo sed -i \
  's/SystemdCgroup = false/SystemdCgroup = true/' \
  /etc/containerd/config.toml

sudo systemctl restart containerd

sudo systemctl enable containerd

Add the Kubernetes package repository:

sudo mkdir -p -m 755 /etc/apt/keyrings

curl -fsSL \
  https://pkgs.k8s.io/core:/stable:/v1.36/deb/Release.key \
  | sudo gpg --dearmor --yes \
      -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.36/deb/ /' \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

Install Kubernetes components:

sudo apt-get update

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  kubeadm \
  kubelet \
  kubectl

sudo apt-mark hold kubeadm kubelet kubectl

sudo systemctl enable kubelet

Add the Trivy package repository:

curl -fsSL \
  https://aquasecurity.github.io/trivy-repo/deb/public.key \
  | sudo gpg --dearmor --yes \
      -o /usr/share/keyrings/trivy.gpg

echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" \
  | sudo tee /etc/apt/sources.list.d/trivy.list > /dev/null

Install Trivy:

sudo apt-get update

sudo apt-get install -y trivy

Install Kube-bench from its current GitHub release:

KUBE_BENCH_DEB_URL="$(
  curl -fsSL \
    https://api.github.com/repos/aquasecurity/kube-bench/releases/latest \
  | jq -r '
      .assets[]
      | select(.name | test("linux_amd64\\.deb$"))
      | .browser_download_url
    ' \
  | head -1
)"

curl -fL \
  "$KUBE_BENCH_DEB_URL" \
  -o /tmp/kube-bench-linux-amd64.deb

sudo apt-get install -y /tmp/kube-bench-linux-amd64.deb

rm -f /tmp/kube-bench-linux-amd64.deb

## How to Reproduce

Clone the repository and enter the implementation directory:

git clone https://github.com/bilalfayyaz11/kubernetes-cluster-orchestration.git

cd kubernetes-cluster-orchestration/kubernetes-security-hardening

Initialize the Kubernetes control plane:

sudo kubeadm init \
  --pod-network-cidr=192.168.0.0/16

Configure kubectl for the current user:

mkdir -p "$HOME/.kube"

sudo cp /etc/kubernetes/admin.conf "$HOME/.kube/config"

sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"

Allow workloads to run on the single control-plane node:

kubectl taint nodes \
  --all \
  node-role.kubernetes.io/control-plane- || true

Install Calico networking:

kubectl apply \
  -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.2/manifests/calico.yaml

Wait for the Kubernetes system components:

kubectl wait \
  --for=condition=Ready \
  pods \
  --all \
  --namespace kube-system \
  --timeout=600s

Verify node readiness:

kubectl get nodes -o wide

Apply the Pod Security namespaces:

kubectl apply \
  -f manifests/security-namespaces.yaml

Test privileged workload enforcement:

kubectl apply \
  -f manifests/privileged-pod.yaml \
  -n privileged-ns

kubectl apply \
  -f manifests/privileged-pod.yaml \
  -n baseline-ns || true

kubectl apply \
  -f manifests/privileged-pod.yaml \
  -n restricted-ns || true

Deploy the restricted-compliant pod:

kubectl apply \
  -f manifests/restricted-pod.yaml \
  -n restricted-ns

Deploy the hardened nginx workload:

kubectl apply \
  -f manifests/secure-deployment.yaml

kubectl rollout status \
  deployment/secure-nginx \
  --namespace restricted-ns \
  --timeout=180s

Apply network isolation:

kubectl apply \
  -f manifests/network-policy.yaml

Apply namespace resource controls:

kubectl apply \
  -f manifests/resource-quota.yaml

Verify the active controls:

kubectl get namespaces \
  --show-labels

kubectl get pods,deployments \
  --namespace restricted-ns

kubectl get networkpolicies,resourcequotas,limitranges \
  --namespace restricted-ns

Run a Trivy image scan:

trivy image \
  --severity HIGH,CRITICAL \
  nginx:1.27-alpine

Generate the JSON image report:

mkdir -p reports

trivy image \
  --format json \
  --output reports/nginx-image-report.json \
  nginx:1.27-alpine

Run a Kubernetes cluster scan:

trivy k8s \
  --report summary \
  cluster

Generate the cluster security report:

trivy k8s \
  --format table \
  --output reports/cluster-security-report.txt \
  cluster

Generate the restricted namespace report:

trivy k8s \
  --format json \
  --output reports/restricted-namespace.json \
  namespace/restricted-ns

Run the CIS Kubernetes Benchmark assessment:

sudo kube-bench run \
  | tee reports/kube-bench-results.txt

Generate the Kube-bench findings analysis:

chmod +x analyze-kube-bench.sh

./analyze-kube-bench.sh \
  reports/kube-bench-results.txt \
  | tee reports/kube-bench-analysis.txt

Generate the vulnerability summary:

chmod +x generate-security-summary.sh

./generate-security-summary.sh \
  | tee reports/security-summary.txt

Generate the final cluster security assessment:

chmod +x final-security-assessment.sh

./final-security-assessment.sh \
  | tee reports/final-security-report.txt

Run the terminal monitoring dashboard:

chmod +x security-monitor.sh

INTERVAL=30 ./security-monitor.sh

## Security Controls Implemented

- Pod Security Standards with privileged, baseline, and restricted enforcement
- Non-root workload execution
- RuntimeDefault seccomp profiles
- Disabled privilege escalation
- Read-only container root filesystems
- Removal of unnecessary Linux capabilities
- Calico-backed ingress and egress NetworkPolicies
- Namespace ResourceQuotas
- Container LimitRanges
- CPU and memory requests and limits
- Trivy container image scanning
- Trivy Kubernetes configuration scanning
- CIS Kubernetes Benchmark assessment
- Automated security posture reporting
- Terminal-based security monitoring

## Tools Used

- Kubernetes
- kubeadm
- kubelet
- kubectl
- containerd
- runc
- Calico
- Trivy
- Kube-bench
- CIS Kubernetes Benchmark
- Pod Security Admission
- Kubernetes NetworkPolicy
- ResourceQuota
- LimitRange
- Bash
- jq
- YAML
- Linux
- Git

## Key Skills Demonstrated

- Secure Kubernetes cluster bootstrap with kubeadm
- Container runtime configuration using systemd cgroups
- Kubernetes Pod Security Standards implementation
- Privileged workload restriction and policy validation
- Non-root container hardening
- Linux capability reduction
- Seccomp profile enforcement
- Read-only filesystem design
- Kubernetes NetworkPolicy implementation
- Namespace resource governance
- Container vulnerability scanning
- Kubernetes misconfiguration scanning
- CIS benchmark assessment and interpretation
- Security findings aggregation
- Automated security posture reporting
- Cluster event and workload monitoring
- Kubernetes troubleshooting
- DevSecOps control implementation
- Platform security engineering
- Cloud-native compliance assessment

## Real-World Use Case

A platform engineering or cloud security team can use this implementation as a baseline for validating newly provisioned Kubernetes environments before application onboarding. Pod Security Standards prevent high-risk workloads from entering protected namespaces, Calico policies restrict unnecessary network paths, and resource controls reduce denial-of-service risk from uncontrolled workloads. Trivy provides continuous vulnerability and configuration assessment, while Kube-bench identifies deviations from CIS recommendations. The reports can be archived as security evidence, reviewed during release approvals, or integrated into CI/CD and cluster governance workflows.

## Lessons Learned

- Installing Docker Engine alone does not provide the Kubernetes Container Runtime Interface required by modern kubelet versions; containerd is the more direct runtime choice.
- Kubernetes component versions must remain aligned to avoid unsupported version skew and unpredictable control-plane behavior.
- A NetworkPolicy resource provides no actual traffic enforcement unless the installed CNI supports Kubernetes NetworkPolicy.
- Restricted Pod Security enforcement requires explicit settings such as non-root execution, dropped capabilities, disabled privilege escalation, and an approved seccomp profile.
- Read-only container filesystems require writable temporary volumes for runtime files, caches, and process identifiers.
- Security scanner findings require contextual analysis because some warnings represent manual controls or topology-specific exceptions.
- Pinning container image versions improves reproducibility, but image digests would provide stronger supply-chain guarantees at scale.
- Security remediation should be applied incrementally because incorrect API server, etcd, or kubelet changes can make the control plane unavailable.

## Troubleshooting Log

Issue:
The original Kubernetes installation path installed Docker Engine without providing a compatible CRI adapter.

Resolution:
Used containerd directly and configured its systemd cgroup driver to match kubelet.

Issue:
The Kubernetes package source was pinned to an obsolete minor version that did not match the existing kubectl client.

Resolution:
Used the Kubernetes v1.36 package repository and aligned kubeadm, kubelet, and kubectl versions.

Issue:
The bridge networking module and required sysctl values were missing.

Resolution:
Loaded overlay and br_netfilter persistently and enabled bridge packet processing and IPv4 forwarding.

Issue:
The original Trivy installation used the deprecated apt-key command.

Resolution:
Stored the Trivy repository key in a dedicated GPG keyring and referenced it with signed-by.

Issue:
The original networking design used Flannel while expecting NetworkPolicy enforcement.

Resolution:
Replaced Flannel with Calico so ingress and egress policies are actively enforced.

Issue:
The original Trivy Operator manifest contained incomplete RBAC and controller resources.

Resolution:
Used supported Trivy CLI cluster scanning instead of deploying an incomplete custom operator.

Issue:
Security manifests referenced floating latest image tags.

Resolution:
Pinned nginx and security tool container versions to improve reproducibility.

Issue:
The initial hardened nginx deployment omitted the seccomp profile required by Restricted Pod Security enforcement.

Resolution:
Added RuntimeDefault seccomp profiles at both pod and container levels.

Issue:
The hardened deployment exposed port 8080 without configuring nginx to listen on that port.

Resolution:
Mounted a custom nginx configuration that listens on port 8080 and writes temporary runtime data to writable volumes.

Issue:
A read-only root filesystem prevented nginx from writing cache, PID, and temporary files.

Resolution:
Mounted emptyDir volumes for /tmp, /var/cache/nginx, and /var/run.

Issue:
The namespace selector depended on a manually maintained name label.

Resolution:
Used the automatically generated kubernetes.io/metadata.name namespace label.

Issue:
The original Kube-bench invocation forced obsolete target names and Kubernetes version 1.28.

Resolution:
Allowed Kube-bench to select the compatible CIS benchmark and used supported component targets.

Issue:
The original monitoring script checked only pod-level user configuration and could miss container-level root execution.

Resolution:
Inspected pod, init-container, application-container, and ephemeral-container security contexts with jq.

Issue:
The original grep-based security counters could return duplicate zero values.

Resolution:
Used deterministic jq and awk counters that always produce a single numeric result.
