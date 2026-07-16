# Kubernetes Scheduling Pressure and Autoscaling Guardrail Validation

## What This Does

This implementation builds a three-node Kubernetes cluster with kind, installs a working resource-metrics pipeline, generates reproducible scheduling pressure, and validates workload-protection controls used during node-removal decisions.

The environment includes one control-plane node, two worker nodes, Metrics Server, resource-constrained deployments, stable RBAC definitions, a PodDisruptionBudget, timestamped cluster snapshots, and durable troubleshooting evidence.

The validation demonstrates how resource requests cause pods to become unschedulable, how capacity reduction restores scheduling, and how a PodDisruptionBudget prevents voluntary eviction of a critical single-replica workload.

It also documents an important infrastructure boundary: standard kind worker containers are not members of a cloud-provider node group, so upstream Cluster Autoscaler cannot directly create or delete them without an infrastructure integration such as an AWS Auto Scaling Group or Cluster API MachineDeployment.

## Architecture

    +-------------------------------------------------------------+
    |                    Ubuntu 24.04 Host                        |
    |                                                             |
    |  +-------------------------------------------------------+  |
    |  |                  Docker Engine                        |  |
    |  |                                                       |  |
    |  |  +----------------------+                             |  |
    |  |  | kind Control Plane   |                             |  |
    |  |  | Kubernetes API       |                             |  |
    |  |  | Scheduler            |                             |  |
    |  |  | Controller Manager   |                             |  |
    |  |  +----------+-----------+                             |  |
    |  |             |                                         |  |
    |  |             v                                         |  |
    |  |  +----------------------+  +----------------------+   |  |
    |  |  | kind Worker          |  | kind Worker          |   |  |
    |  |  | Scalable Workloads   |  | Scalable Workloads   |   |  |
    |  |  | Kubelet              |  | Kubelet              |   |  |
    |  |  +----------+-----------+  +----------+-----------+   |  |
    |  +-------------|-------------------------|---------------+  |
    |                |                         |                  |
    |                +------------+------------+                  |
    |                             |                               |
    |                             v                               |
    |                 +-------------------------+                 |
    |                 | Metrics Server          |                 |
    |                 | CPU and Memory Metrics  |                 |
    |                 +------------+------------+                 |
    |                              |                              |
    |                              v                              |
    |       +-----------------------------------------------+     |
    |       | Scheduling Pressure Deployment                |     |
    |       | CPU and Memory Resource Requests              |     |
    |       | Pending Pod and FailedScheduling Evidence     |     |
    |       +----------------------+------------------------+     |
    |                              |                              |
    |                              v                              |
    |       +-----------------------------------------------+     |
    |       | Protected Service                             |     |
    |       | PodDisruptionBudget: minAvailable = 1         |     |
    |       | Drain and Eviction Protection Validation      |     |
    |       +----------------------+------------------------+     |
    |                              |                              |
    |                              v                              |
    |       +-----------------------------------------------+     |
    |       | Validation Evidence                           |     |
    |       | Node Snapshots                                |     |
    |       | Metrics Snapshots                             |     |
    |       | Scheduler Events                              |     |
    |       | PDB Drain Output                              |     |
    |       | Markdown Validation Report                    |     |
    |       +-----------------------------------------------+     |
    +-------------------------------------------------------------+

    Provider Integration Boundary

    +----------------------------+
    | Cluster Autoscaler         |
    | Scheduling Evaluation      |
    +-------------+--------------+
                  |
                  v
    +----------------------------+
    | Resizable Node Group       |
    | Required for Node Changes  |
    +-------------+--------------+
                  |
          +-------+--------+
          |                |
          v                v
    +-----------+   +----------------------+
    | AWS ASG   |   | Cluster API Machines |
    +-----------+   +----------------------+

    Standard kind workers are Docker containers and are not connected to
    either provider-backed node-group implementation.

## Prerequisites

- Ubuntu 24.04
- At least 4 CPU cores
- At least 12 GiB available memory
- At least 20 GiB available disk space
- Docker Engine
- Docker access for the current non-root user
- kubectl
- kind
- Git
- curl
- jq
- tree
- Internet access for container images and Kubernetes manifests
- Sudo privileges for dependency installation

## Setup & Installation

Install supporting packages:

    sudo apt update

    sudo apt install -y curl git jq tree

Install kind:

    curl -Lo /tmp/kind \
      https://kind.sigs.k8s.io/dl/v0.32.0/kind-linux-amd64

    sudo install -m 0755 /tmp/kind /usr/local/bin/kind

    rm -f /tmp/kind

Grant Docker access to the current user:

    sudo usermod -aG docker "$USER"

    newgrp docker

Verify the toolchain:

    docker version

    kubectl version --client

    kind version

    git --version

    jq --version

    tree --version

## How to Reproduce

Create the working directory:

    mkdir -p ~/kubernetes-autoscaling

    cd ~/kubernetes-autoscaling

Create the kind cluster:

    kind create cluster \
      --name autoscaling \
      --config kind-config.yaml \
      --wait 5m

Select the cluster context:

    kubectl config use-context kind-autoscaling

Verify all nodes:

    kubectl get nodes -o wide

    kubectl cluster-info

Install Metrics Server:

    kubectl apply -f metrics-server-components.yaml

Apply the kind-specific kubelet connection arguments:

    kubectl patch deployment metrics-server \
      -n kube-system \
      --type='json' \
      -p='[
        {
          "op": "add",
          "path": "/spec/template/spec/containers/0/args/-",
          "value": "--kubelet-insecure-tls"
        },
        {
          "op": "add",
          "path": "/spec/template/spec/containers/0/args/-",
          "value": "--kubelet-preferred-address-types=InternalIP,Hostname"
        }
      ]'

Wait for Metrics Server:

    kubectl rollout status deployment/metrics-server \
      -n kube-system \
      --timeout=180s

Verify node metrics:

    kubectl top nodes

Deploy the scheduling-pressure workload:

    kubectl apply -f manifests/scheduling-pressure.yaml

Increase aggregate resource requests:

    kubectl scale deployment/scheduling-pressure --replicas=12

Inspect pod scheduling:

    kubectl get pods \
      -l app=scheduling-pressure \
      -o wide

Inspect scheduling failures:

    kubectl get events \
      --sort-by=.metadata.creationTimestamp |
      grep -Ei 'FailedScheduling|Insufficient'

Review the captured scheduling evidence:

    cat evidence/scale-up-pressure.txt

Reduce resource pressure:

    kubectl scale deployment/scheduling-pressure --replicas=2

    kubectl rollout status deployment/scheduling-pressure \
      --timeout=180s

Deploy the protected service and its disruption policy:

    kubectl apply -f manifests/protected-workload.yaml

Verify the policy:

    kubectl get pdb protected-service-pdb

Identify the worker hosting the protected pod:

    PROTECTED_POD="$(
      kubectl get pods \
        -l app=protected-service \
        -o jsonpath='{.items[0].metadata.name}'
    )"

    PROTECTED_NODE="$(
      kubectl get pod "$PROTECTED_POD" \
        -o jsonpath='{.spec.nodeName}'
    )"

Attempt a voluntary drain:

    kubectl drain "$PROTECTED_NODE" \
      --ignore-daemonsets \
      --delete-emptydir-data \
      --force \
      --timeout=90s

The drain should be rejected because evicting the only protected replica would violate the PodDisruptionBudget.

Return the worker to a schedulable state:

    kubectl uncordon "$PROTECTED_NODE"

Verify that the protected workload remained available:

    kubectl get pod "$PROTECTED_POD" -o wide

Review the complete validation report:

    cat autoscaler-validation-report.md

Verify the report explanation length:

    awk '
      /^## Scaling Explanation$/ {
        capture=1
        next
      }
      /^## / && capture {
        capture=0
      }
      capture {
        print
      }
    ' autoscaler-validation-report.md |
    wc -w

## Autoscaling Configuration Evaluated

The following production-oriented settings were documented and validated where supported by the local environment:

- Least-waste expansion strategy
- Scale-down utilization threshold of 0.5
- Scale-down unneeded duration of two minutes
- Scale-down delay after node addition of two minutes
- Minimum worker count of two
- Maximum worker count of five
- System-pod scale-down evaluation
- Local-storage scale-down evaluation
- Verbosity level four for detailed decisions
- Stable Kubernetes RBAC APIs
- PodDisruptionBudget protection

Actual node creation and deletion require a provider-managed node group. The local kind workers are not managed by an AWS Auto Scaling Group, Cluster API MachineDeployment, MachineSet, or MachinePool.

## Tools Used

- Kubernetes
- kind
- kubectl
- Docker
- Metrics Server
- Kubernetes Scheduler
- Kubernetes RBAC
- PodDisruptionBudget
- Deployments
- ConfigMaps
- YAML
- Bash
- Linux
- Git
- curl
- jq
- tree

## Key Skills Demonstrated

- Multi-node Kubernetes cluster provisioning
- Kubernetes control-plane and worker validation
- Container-based cluster operations
- Resource-request capacity planning
- Unschedulable pod investigation
- FailedScheduling event analysis
- Kubernetes Metrics API configuration
- Metrics Server troubleshooting
- Node CPU and memory observability
- Cluster Autoscaler architecture analysis
- Cloud-provider dependency identification
- Autoscaling boundary design
- Kubernetes RBAC modernization
- Pod disruption protection
- Voluntary eviction testing
- Worker drain and uncordon operations
- Production guardrail validation
- Timestamped evidence collection
- Technical validation reporting
- Honest infrastructure limitation analysis

## Real-World Use Case

A platform engineering team preparing a Kubernetes environment for autoscaling must verify more than controller installation. Engineers need to confirm that resource requests accurately represent workload demand, node metrics are available, unschedulable pods produce observable signals, node groups have safe minimum and maximum limits, and critical services cannot be removed during consolidation. This implementation models that readiness process and produces the evidence needed for an architecture review before connecting Cluster Autoscaler to an AWS Auto Scaling Group, Cluster API MachineDeployment, or another supported infrastructure provider.

## Lessons Learned

- Cluster Autoscaler depends on a provider-managed node group and cannot independently create or delete arbitrary Kubernetes nodes.
- Standard kind workers are Docker containers and do not become resizable infrastructure merely by enabling the Cluster API cloud-provider flag.
- Kubernetes scheduling decisions are based on declared resource requests rather than the workload's instantaneous CPU consumption.
- Metrics Server may require kubelet TLS and address-selection adjustments in local container-based clusters.
- Stable RBAC resources must use `rbac.authorization.k8s.io/v1`; obsolete beta API versions are no longer valid.
- A PodDisruptionBudget can block a node drain when voluntary eviction would reduce application availability below the configured minimum.
- Node drains should always be followed by verification and uncordon recovery when a validation attempt is rejected.
- Validation evidence must clearly distinguish real node scaling from scheduling-pressure simulation.

## Troubleshooting Log

Issue:
The Docker client was installed and the Docker service was active, but the non-root user could not connect to the Docker daemon socket.

Resolution:
Added the current user to the Docker group and activated the new group membership with `newgrp docker`.

Issue:
kind and tree were missing from the fresh Ubuntu environment.

Resolution:
Installed tree through apt and installed the official kind Linux binary under `/usr/local/bin`.

Issue:
Metrics Server initially could not reliably communicate with kind kubelets using its default production certificate validation.

Resolution:
Added `--kubelet-insecure-tls` and `--kubelet-preferred-address-types=InternalIP,Hostname` to the Metrics Server deployment.

Issue:
The Metrics API returned temporary availability errors immediately after installation.

Resolution:
Waited for the deployment rollout and used repeated `kubectl top nodes` checks until numeric metrics were returned for every node.

Issue:
Older Cluster Autoscaler examples referenced `rbac.authorization.k8s.io/v1beta1`.

Resolution:
Used the stable `rbac.authorization.k8s.io/v1` API for ClusterRole and ClusterRoleBinding resources.

Issue:
The original architecture assumed that Cluster Autoscaler could create and delete ordinary kind worker containers.

Resolution:
Verified that the workers were not managed by an AWS Auto Scaling Group, Cluster API MachineDeployment, MachineSet, or MachinePool. The implementation records this limitation rather than reporting fabricated node-count changes.

Issue:
Starting Cluster Autoscaler with the Cluster API provider alone would not make ordinary kind workers resizable.

Resolution:
Documented the provider requirement and retained the controller configuration as a server-validated reference rather than deploying a nonfunctional controller.

Issue:
The suggestion to add `--v=4` with `kubectl set env` would modify environment variables instead of container arguments.

Resolution:
Documented that command-line flags must be added through a manifest update, Helm values, `kubectl edit`, or a structured deployment patch.

Issue:
The high-resource deployment exceeded available worker CPU and left pods in Pending state.

Resolution:
Captured FailedScheduling and insufficient-capacity evidence, then reduced the replica count to restore schedulability.

Issue:
The node drain could have made the only protected service replica unavailable.

Resolution:
Created a PodDisruptionBudget with `minAvailable: 1`. Kubernetes rejected the voluntary eviction, and the protected pod remained Running.

Issue:
The drain command cordoned the worker before the PodDisruptionBudget rejection stopped the operation.

Resolution:
Explicitly uncordoned the worker and verified that all nodes returned to Ready and schedulable status.

Issue:
A broad search for timestamps in the pod-watch output could incorrectly treat monitoring timestamps as deletion timestamps.

Resolution:
Validated the specific deletion-timestamp column and excluded the header and `<none>` values.
