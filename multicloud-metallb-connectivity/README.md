# Multi-Cluster Kubernetes Networking with MetalLB

## What This Does

This implementation creates two independent three-node Kubernetes clusters on a single Docker host to simulate separately managed AWS and GCP environments.

Each cluster includes one control-plane node, two worker nodes, its own Kubernetes context, cloud-specific node labels, a dedicated MetalLB address pool, and a replicated web application exposed through a LoadBalancer service.

The system validates host-to-cluster connectivity and genuine bidirectional pod-to-service communication across cluster boundaries using distinct MetalLB-assigned external IP addresses.

The implementation also includes repeatable health checks, dynamically calculated non-overlapping address ranges, durable validation evidence, and operational fixes for kernel resource exhaustion, admission webhook readiness, missing namespaces, and deployment-order dependencies.

## Architecture

    +---------------------------------------------------------------------+
    |                         Ubuntu 24.04 Host                           |
    |                                                                     |
    |  +---------------------------------------------------------------+  |
    |  |                       Docker Engine                           |  |
    |  |                                                               |  |
    |  |  +----------------------------+  +--------------------------+ |  |
    |  |  | AWS-Simulated Kubernetes   |  | GCP-Simulated Kubernetes| |  |
    |  |  |                            |  |                          | |  |
    |  |  | +------------------------+ |  | +----------------------+ | |  |
    |  |  | | Control Plane          | |  | | Control Plane        | | |  |
    |  |  | +------------------------+ |  | +----------------------+ | |  |
    |  |  |                            |  |                          | |  |
    |  |  | +-----------+ +----------+ |  | +----------+ +---------+ | |  |
    |  |  | | Worker 1  | | Worker 2 | |  | | Worker 1 | | Worker 2| | |  |
    |  |  | +-----------+ +----------+ |  | +----------+ +---------+ | |  |
    |  |  |                            |  |                          | |  |
    |  |  | MetalLB Controller         |  | MetalLB Controller       | |  |
    |  |  | MetalLB Speaker DaemonSet  |  | MetalLB Speaker DaemonSet| |  |
    |  |  | AWS Address Pool           |  | GCP Address Pool         | |  |
    |  |  |                            |  |                          | |  |
    |  |  | aws-web Deployment         |  | gcp-web Deployment       | |  |
    |  |  | 2 Replicas                 |  | 2 Replicas               | |  |
    |  |  | LoadBalancer Service       |  | LoadBalancer Service     | |  |
    |  |  +-------------+--------------+  +-------------+------------+ |  |
    |  |                |                               |              |  |
    |  |                +-----------+-------------------+              |  |
    |  |                            |                                  |  |
    |  |                            v                                  |  |
    |  |                  Shared kind Network                          |  |
    |  |                  Non-Overlapping IP Pools                     |  |
    |  +----------------------------+----------------------------------+  |
    |                               |                                     |
    |                +--------------+---------------+                     |
    |                |                              |                     |
    |                v                              v                     |
    |       Host-to-AWS Validation         Host-to-GCP Validation         |
    |                                                                     |
    |       AWS Pod -> GCP Service         GCP Pod -> AWS Service         |
    +---------------------------------------------------------------------+

## Prerequisites

- Ubuntu 24.04
- At least 4 CPU cores
- At least 12 GiB available memory
- At least 20 GiB available storage
- Docker Engine
- Docker access for the current non-root user
- kubectl
- kind
- Helm
- Git
- curl
- jq
- Python 3
- tree
- Internet access for container images and Kubernetes manifests
- Sudo privileges for kernel and package configuration

## Setup & Installation

Install supporting packages:

    sudo apt update

    sudo apt install -y curl git jq python3 tree

Install kind:

    curl -Lo /tmp/kind \
      https://kind.sigs.k8s.io/dl/v0.32.0/kind-linux-amd64

    sudo install -m 0755 /tmp/kind /usr/local/bin/kind

    rm -f /tmp/kind

Grant Docker access to the current user:

    sudo usermod -aG docker "$USER"

Log out once and reconnect through a fresh SSH session so the Docker group membership is active.

Verify the toolchain:

    docker version

    kubectl version --client

    kind version

    helm version

    jq --version

    tree --version

Increase host inotify limits for six Kubernetes node containers:

    sudo tee /etc/sysctl.d/99-kind-inotify.conf >/dev/null << 'SYSCTL'
    fs.inotify.max_user_instances = 8192
    fs.inotify.max_user_watches = 1048576
    fs.inotify.max_queued_events = 65536
    fs.file-max = 2097152
    SYSCTL

    sudo sysctl --system

## How to Reproduce

Create the working structure:

    mkdir -p ~/multicloud-kubernetes/{aws-cluster,gcp-cluster,networking,applications,monitoring,configs,evidence}

    cd ~/multicloud-kubernetes

Create the AWS-simulated cluster:

    kind create cluster \
      --name aws-cluster \
      --config configs/aws-cluster-config.yaml \
      --wait 5m

Create the GCP-simulated cluster:

    kind create cluster \
      --name gcp-cluster \
      --config configs/gcp-cluster-config.yaml \
      --wait 5m

Verify both contexts:

    kubectl config get-contexts

Verify both node groups:

    kubectl --context kind-aws-cluster get nodes -L cloud,region

    kubectl --context kind-gcp-cluster get nodes -L cloud,region

Install MetalLB on the AWS-simulated cluster:

    kubectl --context kind-aws-cluster apply \
      -f networking/metallb-native-v0.16.1.yaml

Install MetalLB on the GCP-simulated cluster:

    kubectl --context kind-gcp-cluster apply \
      -f networking/metallb-native-v0.16.1.yaml

Wait for the MetalLB controllers:

    kubectl --context kind-aws-cluster \
      rollout status deployment/controller \
      -n metallb-system \
      --timeout=300s

    kubectl --context kind-gcp-cluster \
      rollout status deployment/controller \
      -n metallb-system \
      --timeout=300s

Wait for the speaker DaemonSets:

    kubectl --context kind-aws-cluster \
      rollout status daemonset/speaker \
      -n metallb-system \
      --timeout=300s

    kubectl --context kind-gcp-cluster \
      rollout status daemonset/speaker \
      -n metallb-system \
      --timeout=300s

Verify the MetalLB admission webhook endpoint before applying custom resources:

    kubectl --context kind-gcp-cluster \
      get endpoints metallb-webhook-service \
      -n metallb-system

Apply the non-overlapping address pools:

    kubectl --context kind-aws-cluster apply \
      -f networking/metallb-aws-config.yaml

    kubectl --context kind-gcp-cluster apply \
      -f networking/metallb-gcp-config.yaml

Verify both address pools:

    kubectl --context kind-aws-cluster \
      get ipaddresspool,l2advertisement \
      -n metallb-system

    kubectl --context kind-gcp-cluster \
      get ipaddresspool,l2advertisement \
      -n metallb-system

Create the application namespace in both clusters:

    kubectl --context kind-aws-cluster create namespace multicloud \
      --dry-run=client -o yaml |
    kubectl --context kind-aws-cluster apply -f -

    kubectl --context kind-gcp-cluster create namespace multicloud \
      --dry-run=client -o yaml |
    kubectl --context kind-gcp-cluster apply -f -

Deploy the AWS-simulated application:

    kubectl --context kind-aws-cluster apply \
      -f applications/aws-web.yaml

    kubectl --context kind-aws-cluster \
      rollout status deployment/aws-web \
      -n multicloud \
      --timeout=300s

Deploy the GCP-simulated application:

    kubectl --context kind-gcp-cluster apply \
      -f applications/gcp-web.yaml

    kubectl --context kind-gcp-cluster \
      rollout status deployment/gcp-web \
      -n multicloud \
      --timeout=300s

Retrieve the external addresses:

    AWS_IP="$(
      kubectl --context kind-aws-cluster \
        get service aws-web \
        -n multicloud \
        -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
    )"

    GCP_IP="$(
      kubectl --context kind-gcp-cluster \
        get service gcp-web \
        -n multicloud \
        -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
    )"

    echo "AWS endpoint: $AWS_IP"

    echo "GCP endpoint: $GCP_IP"

Test both services from the host:

    curl --fail --silent --show-error \
      "http://${AWS_IP}/info"

    curl --fail --silent --show-error \
      "http://${GCP_IP}/info"

Test AWS-to-GCP communication:

    kubectl --context kind-aws-cluster \
      run aws-cross-cluster-client \
      -n multicloud \
      --image=curlimages/curl:8.15.0 \
      --restart=Never \
      --rm \
      -i \
      --command -- \
      curl --fail --silent --show-error \
      "http://${GCP_IP}/info"

Test GCP-to-AWS communication:

    kubectl --context kind-gcp-cluster \
      run gcp-cross-cluster-client \
      -n multicloud \
      --image=curlimages/curl:8.15.0 \
      --restart=Never \
      --rm \
      -i \
      --command -- \
      curl --fail --silent --show-error \
      "http://${AWS_IP}/info"

Review the final validation report:

    cat multicloud-kubernetes-validation-report.md

Review the collected evidence:

    tree evidence

## Networking Design

The two Kubernetes clusters share the same Docker network but maintain independent control planes, resources, namespaces, deployments, and service objects.

MetalLB assigns external addresses from separate ranges inside the detected kind Docker subnet:

- AWS-simulated services use the `aws-pool` range.
- GCP-simulated services use the `gcp-pool` range.
- The ranges are generated dynamically to avoid reliance on a hardcoded Docker subnet.
- The ranges do not overlap.
- Addresses already assigned to Docker containers are excluded from selection.
- Layer 2 advertisements make the LoadBalancer addresses reachable from the host and from pods in the opposite cluster.

## Tools Used

- Kubernetes
- kind
- kubectl
- Docker
- MetalLB
- Helm
- NGINX
- Kubernetes Deployments
- Kubernetes Services
- Kubernetes ConfigMaps
- Kubernetes Namespaces
- IPAddressPool
- L2Advertisement
- Admission Webhooks
- Bash
- Python 3
- YAML
- Linux
- Git
- curl
- jq
- tree

## Key Skills Demonstrated

- Multi-cluster Kubernetes provisioning
- Independent Kubernetes context administration
- Cloud-specific node labeling
- Multi-node kind cluster operations
- Docker network inspection
- Dynamic IP address planning
- Non-overlapping LoadBalancer pool design
- MetalLB native-mode deployment
- Layer 2 service advertisement
- Kubernetes admission webhook troubleshooting
- Cross-cluster application communication
- LoadBalancer service validation
- Pod-to-service connectivity testing
- Host-to-cluster connectivity testing
- Kubernetes readiness and rollout validation
- Kernel inotify capacity tuning
- Deployment dependency ordering
- Durable evidence collection
- Repeatable infrastructure verification
- Distributed platform troubleshooting

## Real-World Use Case

A platform engineering team may operate Kubernetes clusters across multiple cloud providers to improve resilience, satisfy data-location requirements, reduce provider dependency, or place services close to regional users. Each cluster remains independently managed, but applications still need reliable connectivity, consistent service exposure, and clear operational boundaries. This implementation models those requirements by creating two separate Kubernetes environments, assigning non-overlapping external service ranges, and proving bidirectional application communication through repeatable tests. The same operating patterns apply to production environments using AWS, Google Cloud, Azure, private data centers, VPN connectivity, service meshes, global DNS, or dedicated interconnects.

## Lessons Learned

- Running six kind nodes on one host can exhaust default inotify limits even when CPU and memory remain available.
- Kubernetes contexts must be validated after every cluster recreation because failed initialization does not produce a usable context.
- MetalLB custom resources cannot be created until its admission webhook has a ready endpoint.
- A running MetalLB controller alone is not enough; valid address pools and Layer 2 advertisements must also exist.
- LoadBalancer services remain pending when no working load-balancer controller is available.
- Namespaces must exist before namespaced application resources can be created.
- Dynamic address-pool generation is safer than assuming Docker always uses `172.18.0.0/16`.
- Interactive aliases are useful for operators but should not be required by automation.
- Explicit rollout, endpoint, and connectivity checks prevent later stages from starting against incomplete prerequisites.
- Large shell blocks must be allowed to finish before additional commands are pasted into the terminal.

## Troubleshooting Log

Issue:
The current user could not access the Docker daemon even though Docker was installed and active.

Resolution:
Added the user to the Docker group and activated the membership through a fresh SSH login rather than using nested `newgrp` shells.

Issue:
The second Kubernetes cluster failed during control-plane initialization with connection-refused errors.

Resolution:
Removed the failed cluster state, simplified the kind configuration, and allowed kind to use its tested network and API-port defaults.

Issue:
The GCP-simulated control-plane kubelet failed with `inotify_init: too many open files`.

Resolution:
Increased `fs.inotify.max_user_instances`, `fs.inotify.max_user_watches`, `fs.inotify.max_queued_events`, and `fs.file-max` through a persistent sysctl configuration.

Issue:
The Kubernetes contexts were missing even though configuration and evidence files existed.

Resolution:
Verified actual kind clusters and Docker containers before treating generated evidence as proof of successful infrastructure creation.

Issue:
MetalLB services remained in the `pending` state.

Resolution:
Confirmed that the `metallb-system` namespace, controller Deployment, speaker DaemonSet, address pools, and Layer 2 advertisements existed before waiting for service addresses.

Issue:
The original address-pool examples assumed a fixed `172.18.0.0/16` Docker subnet.

Resolution:
Detected the actual kind network subnet and generated two non-overlapping address ranges dynamically.

Issue:
The GCP MetalLB address configuration was rejected with a validation-webhook connection-refused error.

Resolution:
Waited for the controller pod and `metallb-webhook-service` endpoint to become ready before retrying the `IPAddressPool` and `L2Advertisement` resources.

Issue:
Application resources failed because the `multicloud` namespace did not exist.

Resolution:
Created the namespace idempotently in both clusters before applying any namespaced application resources.

Issue:
Application deployment commands were pasted with corrupted line endings and concatenated shell content.

Resolution:
Reapplied clean, bounded command blocks and used `set -Eeuo pipefail` to stop immediately on failures.

Issue:
An unbounded shell loop waited indefinitely for MetalLB addresses.

Resolution:
Replaced it with a finite retry loop that reports the state on every attempt and prints controller diagnostics on timeout.

Issue:
The SSH connection repeatedly closed after output containing `logout`.

Resolution:
Stopped using nested Docker group shells and avoided pasting additional commands while foreground loops were still active.

Issue:
The Deployment manifests could be processed before their required ConfigMaps.

Resolution:
Ordered each manifest so ConfigMaps are created before Deployments that mount them.

Issue:
Using floating container tags could introduce non-repeatable behavior.

Resolution:
Pinned NGINX and diagnostic client images to explicit versions.
