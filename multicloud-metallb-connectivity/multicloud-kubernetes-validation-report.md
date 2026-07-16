# Multi-Cluster Kubernetes Validation Report

## Environment

- Host operating system: Ubuntu 24.04
- Container runtime: Docker
- Kubernetes implementation: kind
- Cluster count: 2
- Nodes per cluster: 3
- LoadBalancer implementation: MetalLB
- Networking mode: Layer 2
- AWS-simulated endpoint: 172.18.255.205
- GCP-simulated endpoint: 172.18.255.225

## Architecture

    +-----------------------------------------------------------+
    |                    Ubuntu Docker Host                     |
    |                                                           |
    |  +-------------------------+  +-------------------------+ |
    |  | AWS-Simulated Cluster   |  | GCP-Simulated Cluster   | |
    |  |                         |  |                         | |
    |  | Control Plane           |  | Control Plane           | |
    |  | Worker 1                |  | Worker 1                | |
    |  | Worker 2                |  | Worker 2                | |
    |  |                         |  |                         | |
    |  | MetalLB                 |  | MetalLB                 | |
    |  | aws-pool                |  | gcp-pool                | |
    |  |                         |  |                         | |
    |  | aws-web                 |  | gcp-web                 | |
    |  +------------+------------+  +------------+------------+ |
    |               |                            |              |
    |               +------ Shared Docker -------+              |
    |                        Network                             |
    +-----------------------------------------------------------+

## Cluster State

### AWS-Simulated Cluster

```text
NAME                        STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                       KERNEL-VERSION            CONTAINER-RUNTIME    CLOUD   REGION
aws-cluster-control-plane   Ready    control-plane   34m   v1.36.1   172.18.0.3    <none>        Debian GNU/Linux 13 (trixie)   6.14.0-1018-aws (amd64)   containerd://2.3.1   aws     us-east-1
aws-cluster-worker          Ready    <none>          34m   v1.36.1   172.18.0.4    <none>        Debian GNU/Linux 13 (trixie)   6.14.0-1018-aws (amd64)   containerd://2.3.1   aws     us-east-1
aws-cluster-worker2         Ready    <none>          34m   v1.36.1   172.18.0.2    <none>        Debian GNU/Linux 13 (trixie)   6.14.0-1018-aws (amd64)   containerd://2.3.1   aws     us-east-1
```

### GCP-Simulated Cluster

```text
NAME                        STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                       KERNEL-VERSION            CONTAINER-RUNTIME    CLOUD   REGION
gcp-cluster-control-plane   Ready    control-plane   23m   v1.36.1   172.18.0.7    <none>        Debian GNU/Linux 13 (trixie)   6.14.0-1018-aws (amd64)   containerd://2.3.1   gcp     us-central1
gcp-cluster-worker          Ready    <none>          23m   v1.36.1   172.18.0.5    <none>        Debian GNU/Linux 13 (trixie)   6.14.0-1018-aws (amd64)   containerd://2.3.1   gcp     us-central1
gcp-cluster-worker2         Ready    <none>          23m   v1.36.1   172.18.0.6    <none>        Debian GNU/Linux 13 (trixie)   6.14.0-1018-aws (amd64)   containerd://2.3.1   gcp     us-central1
```

## MetalLB State

### AWS-Simulated Cluster

```text
NAME                                AUTO ASSIGN   AVOID BUGGY IPS   ADDRESSES
ipaddresspool.metallb.io/aws-pool   true          false             ["172.18.255.205-172.18.255.224"]

NAME                                              IPADDRESSPOOLS   IPADDRESSPOOL SELECTORS   INTERFACES
l2advertisement.metallb.io/aws-l2-advertisement   ["aws-pool"]                               
```

### GCP-Simulated Cluster

```text
NAME                                AUTO ASSIGN   AVOID BUGGY IPS   ADDRESSES
ipaddresspool.metallb.io/gcp-pool   true          false             ["172.18.255.225-172.18.255.244"]

NAME                                              IPADDRESSPOOLS   IPADDRESSPOOL SELECTORS   INTERFACES
l2advertisement.metallb.io/gcp-l2-advertisement   ["gcp-pool"]                               
```

## Application State

### AWS Application

```text
NAME                          READY   STATUS    RESTARTS   AGE   IP           NODE                  NOMINATED NODE   READINESS GATES
pod/aws-web-846ccd54c-bts5c   1/1     Running   0          21m   10.240.2.2   aws-cluster-worker2   <none>           <none>
pod/aws-web-846ccd54c-zhw5p   1/1     Running   0          21m   10.240.1.2   aws-cluster-worker    <none>           <none>

NAME              TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)        AGE   SELECTOR
service/aws-web   LoadBalancer   10.241.146.100   172.18.255.205   80:30542/TCP   21m   app=aws-web
```

### GCP Application

```text
NAME                           READY   STATUS    RESTARTS   AGE   IP           NODE                  NOMINATED NODE   READINESS GATES
pod/gcp-web-55fb84fdf9-gcjc7   1/1     Running   0          20m   10.244.2.2   gcp-cluster-worker    <none>           <none>
pod/gcp-web-55fb84fdf9-zzwgv   1/1     Running   0          20m   10.244.1.2   gcp-cluster-worker2   <none>           <none>

NAME              TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)        AGE   SELECTOR
service/gcp-web   LoadBalancer   10.96.24.132   172.18.255.225   80:31716/TCP   20m   app=gcp-web
```

## Connectivity Results

### Host to AWS-Simulated Endpoint

```json
{"cluster":"aws","region":"us-east-1"}
```

### Host to GCP-Simulated Endpoint

```json
{"cluster":"gcp","region":"us-central1"}
```

### AWS-Simulated Cluster to GCP-Simulated Cluster

```json
{"cluster":"gcp","region":"us-central1"}{"cluster":"gcp","region":"us-central1"}pod "final-aws-client" deleted from multicloud namespace
```

### GCP-Simulated Cluster to AWS-Simulated Cluster

```json
{"cluster":"aws","region":"us-east-1"}{"cluster":"aws","region":"us-east-1"}pod "final-gcp-client" deleted from multicloud namespace
```

## Address Allocation

- AWS address pool: 172.18.255.205-172.18.255.224
- GCP address pool: 172.18.255.225-172.18.255.244
- Address pools overlap: No
- External service addresses are distinct: Yes

## Operational Findings

The environment successfully ran two independent Kubernetes control planes on one Docker host. Each cluster contained one control-plane node and two workers and used separate Kubernetes contexts for administration. MetalLB provided Layer 2 LoadBalancer addresses from non-overlapping ranges inside the shared kind Docker network. Applications in both clusters were reachable from the host and from pods in the opposite cluster. The main operational issues were host inotify exhaustion when creating the sixth kind node, MetalLB webhook readiness during address-pool creation, missing namespaces after cluster recreation, and commands being applied before prerequisite components were available.

## Final Result

- Both Kubernetes clusters operational: PASS
- Six Kubernetes nodes Ready: PASS
- Both MetalLB controllers operational: PASS
- Both speaker DaemonSets Ready: PASS
- Non-overlapping address pools configured: PASS
- Two AWS application replicas Ready: PASS
- Two GCP application replicas Ready: PASS
- Host-to-service connectivity: PASS
- Bidirectional cross-cluster connectivity: PASS
