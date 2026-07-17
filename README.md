# Kubernetes Cluster Orchestration

A hands-on Kubernetes engineering portfolio covering cluster architecture, workload orchestration, networking, storage, observability, security, autoscaling, GitOps, multi-cluster connectivity, disaster recovery, service mesh operations, and advanced troubleshooting.

This repository serves as the central index for a collection of independently implemented Kubernetes environments. Each directory focuses on a specific operational capability and includes declarative manifests, automation scripts, validation procedures, architecture documentation, and evidence of successful execution.

---

## Portfolio Overview

The work in this repository progresses from core Kubernetes concepts to production-oriented platform engineering.

Key areas include:

* Kubernetes architecture and control-plane fundamentals
* Pods, Services, Deployments, StatefulSets, and DaemonSets
* ConfigMaps and runtime configuration management
* CNI networking with Calico
* Ingress routing and API gateway patterns
* Horizontal Pod Autoscaling
* persistent storage and topology-aware scheduling
* Prometheus and Grafana observability
* centralized Kubernetes logging
* RBAC and defense-in-depth security
* NetworkPolicy-based microsegmentation
* CI/CD and GitOps deployment workflows
* scheduling pressure and autoscaling guardrails
* multi-cluster and multi-environment connectivity
* Kubernetes security hardening
* disaster recovery with Velero and MinIO
* Istio service mesh traffic control and security
* advanced Kubernetes incident diagnosis and recovery

---

## Repository Architecture

```text
kubernetes-cluster-orchestration/
│
├── calico-pod-networking/
├── configuration-state-management/
├── high-availability-workloads/
├── istio-service-mesh-control/
├── k8s-observability-stack/
├── k8s-rbac-defense-in-depth/
├── kubernetes-autoscaling/
├── kubernetes-disaster-recovery/
├── kubernetes-network-microsegmentation/
├── kubernetes-security-hardening/
├── multicloud-metallb-connectivity/
├── nginx-ingress-routing/
├── persistent-volume-storage/
├── scheduling-pressure-autoscaling-guardrails/
├── storage-topology-orchestration/
└── README.md
```

---

## Capability Map

| Area                              | Implementation                                                                                                                | Repository                                   |
| --------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------- |
| Kubernetes fundamentals           | Core architecture, control-plane responsibilities, worker-node components, and workload primitives                            | Portfolio foundation                         |
| Workload orchestration            | Pods, Services, Deployments, rolling updates, replica management, and service discovery                                       | `high-availability-workloads`                |
| Stateful and node-level workloads | StatefulSets, DaemonSets, node placement, distributed agents, and topology-aware scheduling                                   | `storage-topology-orchestration`             |
| Configuration management          | ConfigMaps, environment injection, mounted configuration, update behavior, and configuration decoupling                       | `configuration-state-management`             |
| Pod networking                    | Calico CNI installation, pod communication, IP allocation, and traffic validation                                             | `calico-pod-networking`                      |
| Ingress routing                   | NGINX Ingress Controller, host-based routing, path-based routing, and centralized entry points                                | `nginx-ingress-routing`                      |
| Horizontal scaling                | Metrics Server, CPU-based scaling, load generation, and replica validation                                                    | `kubernetes-autoscaling`                     |
| Persistent storage                | PersistentVolumes, PersistentVolumeClaims, StorageClasses, and multi-pod data validation                                      | `persistent-volume-storage`                  |
| Monitoring                        | Prometheus metrics collection, Grafana dashboards, target validation, and application observability                           | `k8s-observability-stack`                    |
| Centralized logging               | Cluster-level log collection and aggregation patterns for Kubernetes workloads                                                | Observability coverage                       |
| Access control                    | Kubernetes RBAC, least privilege, service accounts, namespace isolation, and authorization testing                            | `k8s-rbac-defense-in-depth`                  |
| Network security                  | Calico NetworkPolicies, default-deny controls, namespace isolation, and microsegmentation                                     | `kubernetes-network-microsegmentation`       |
| Delivery automation               | Declarative deployment workflows, version-controlled configuration, and GitOps operating principles                           | Integrated across repositories               |
| Scheduling resilience             | scheduling pressure, resource requests, capacity constraints, and autoscaling guardrails                                      | `scheduling-pressure-autoscaling-guardrails` |
| Multi-environment connectivity    | Multi-cluster networking concepts, MetalLB service exposure, and connectivity validation                                      | `multicloud-metallb-connectivity`            |
| Platform hardening                | Pod Security Standards, admission controls, RBAC review, compliance checks, and security validation                           | `kubernetes-security-hardening`              |
| Disaster recovery                 | Velero backup and restore workflows with MinIO-compatible object storage                                                      | `kubernetes-disaster-recovery`               |
| Service mesh                      | Istio traffic management, observability, mTLS, authorization, and mesh security                                               | `istio-service-mesh-control`                 |
| Incident response                 | Image failures, missing configuration, scheduling failures, Service selector issues, DNS checks, and EndpointSlice validation | Advanced troubleshooting implementation      |

---

## Architecture

```text
                            External Clients
                                   |
                                   v
                    +-----------------------------+
                    |  Load Balancer / Ingress    |
                    |  NGINX / MetalLB / Istio    |
                    +--------------+--------------+
                                   |
                                   v
                    +-----------------------------+
                    |      Kubernetes Services    |
                    |  ClusterIP / LoadBalancer   |
                    +--------------+--------------+
                                   |
                     +-------------+-------------+
                     |                           |
                     v                           v
          +----------------------+    +----------------------+
          | Stateless Workloads  |    | Stateful Workloads   |
          | Deployments          |    | StatefulSets         |
          | ReplicaSets          |    | Persistent Storage   |
          +----------+-----------+    +----------+-----------+
                     |                           |
                     +-------------+-------------+
                                   |
                                   v
                    +-----------------------------+
                    | Kubernetes Networking       |
                    | Calico CNI                   |
                    | NetworkPolicies              |
                    | Service Discovery            |
                    | EndpointSlices               |
                    +--------------+--------------+
                                   |
                 +-----------------+------------------+
                 |                                    |
                 v                                    v
      +-------------------------+       +-------------------------+
      | Observability           |       | Security                |
      | Prometheus              |       | RBAC                    |
      | Grafana                 |       | Pod Security Standards  |
      | Centralized Logging     |       | mTLS and Authorization  |
      +-------------------------+       +-------------------------+
                 |                                    |
                 +-----------------+------------------+
                                   |
                                   v
                    +-----------------------------+
                    | Platform Operations         |
                    | Autoscaling                 |
                    | GitOps                      |
                    | Backup and Restore          |
                    | Incident Response           |
                    +-----------------------------+
```

---

## Implemented Environments

### Calico Pod Networking

**Directory:** `calico-pod-networking`

Implements Kubernetes pod networking with Calico and validates communication between workloads.

Key capabilities:

* Calico CNI installation
* pod IP allocation
* cross-pod connectivity
* namespace-level traffic testing
* workload traffic controls
* network diagnostics
* CNI health verification

---

### Configuration State Management

**Directory:** `configuration-state-management`

Demonstrates how application configuration can be separated from container images and managed declaratively.

Key capabilities:

* ConfigMap creation
* environment variable injection
* mounted configuration files
* configuration decoupling
* workload update behavior
* validation from inside running containers
* declarative configuration management

---

### High-Availability Workloads

**Directory:** `high-availability-workloads`

Implements replicated Kubernetes workloads designed for resilience and controlled updates.

Key capabilities:

* Deployments
* ReplicaSets
* Services
* rolling updates
* rollout status checks
* self-healing behavior
* readiness validation
* declarative workload management

---

### Storage Topology Orchestration

**Directory:** `storage-topology-orchestration`

Implements stateful and node-level workload patterns.

Key capabilities:

* StatefulSets
* DaemonSets
* stable pod identities
* ordered workload behavior
* node-level agents
* storage-aware scheduling
* node topology routing
* distributed workload placement

---

### NGINX Ingress Routing

**Directory:** `nginx-ingress-routing`

Implements centralized HTTP routing through the NGINX Ingress Controller.

Key capabilities:

* ingress controller deployment
* host-based routing
* path-based routing
* backend Service integration
* centralized application entry points
* request routing validation
* ingress troubleshooting

---

### Kubernetes Autoscaling

**Directory:** `kubernetes-autoscaling`

Implements CPU-driven horizontal workload scaling.

Key capabilities:

* Metrics Server
* resource requests
* HorizontalPodAutoscaler
* CPU utilization targets
* load generation
* scale-out validation
* scale-in validation
* autoscaling observability

---

### Persistent Volume Storage

**Directory:** `persistent-volume-storage`

Implements persistent data management for Kubernetes workloads.

Key capabilities:

* PersistentVolumes
* PersistentVolumeClaims
* StorageClasses
* volume mounting
* data persistence
* multi-pod access validation
* storage lifecycle testing

---

### Kubernetes Observability Stack

**Directory:** `k8s-observability-stack`

Deploys an observability platform with Prometheus and Grafana.

Key capabilities:

* Prometheus deployment
* Kubernetes metrics collection
* scrape target validation
* Grafana deployment
* dashboard access
* application monitoring
* cluster health visibility
* observability validation

---

### RBAC Defense in Depth

**Directory:** `k8s-rbac-defense-in-depth`

Implements identity-based access controls using Kubernetes RBAC.

Key capabilities:

* Roles
* ClusterRoles
* RoleBindings
* ClusterRoleBindings
* service accounts
* least-privilege permissions
* authorization testing
* namespace isolation
* access-denial validation

---

### Kubernetes Network Microsegmentation

**Directory:** `kubernetes-network-microsegmentation`

Implements zero-trust workload communication with Calico NetworkPolicies.

Key capabilities:

* default-deny ingress
* default-deny egress
* namespace isolation
* label-based traffic authorization
* DNS egress allowances
* application-specific policies
* allowed-path testing
* denied-path testing

---

### Scheduling Pressure and Autoscaling Guardrails

**Directory:** `scheduling-pressure-autoscaling-guardrails`

Examines scheduler behavior under constrained resources and validates scaling safety controls.

Key capabilities:

* resource requests and limits
* scheduler event analysis
* Pending pod diagnosis
* node allocatable capacity
* scheduling pressure simulation
* autoscaling constraints
* capacity guardrails
* recovery validation

---

### Multi-Cluster MetalLB Connectivity

**Directory:** `multicloud-metallb-connectivity`

Implements external service exposure and connectivity patterns applicable to multi-cluster and multi-environment Kubernetes deployments.

Key capabilities:

* MetalLB deployment
* IP address pools
* Layer 2 advertisement
* LoadBalancer Services
* external connectivity
* service reachability validation
* multi-environment networking concepts

---

### Kubernetes Security Hardening

**Directory:** `kubernetes-security-hardening`

Implements platform security controls and compliance-oriented validation.

Key capabilities:

* Pod Security Standards
* restricted workload policies
* security contexts
* non-root containers
* capability removal
* seccomp profiles
* RBAC review
* NetworkPolicy enforcement
* compliance assessment
* security posture validation

---

### Kubernetes Disaster Recovery

**Directory:** `kubernetes-disaster-recovery`

Implements backup and restore workflows with Velero and MinIO-compatible object storage.

Key capabilities:

* Velero installation
* MinIO object storage
* backup location configuration
* namespace backups
* persistent data protection
* workload deletion simulation
* application restoration
* backup status inspection
* recovery validation

---

### Istio Service Mesh Control

**Directory:** `istio-service-mesh-control`

Implements service mesh traffic control, observability, encryption, and authorization.

Key capabilities:

* Istio installation
* sidecar injection
* Gateway configuration
* VirtualServices
* destination-based routing
* traffic splitting
* request retries
* timeouts
* circuit-breaking concepts
* mutual TLS
* AuthorizationPolicies
* mesh observability
* secure service-to-service communication

---

## Advanced Kubernetes Incident Response

The portfolio also includes a complete troubleshooting workflow for common Kubernetes failures.

The environment uses:

* kubeadm
* containerd
* Flannel
* CoreDNS
* Kubernetes Deployments
* ConfigMaps
* Services
* EndpointSlices
* Bash automation
* evidence-based validation

### Image Pull Failure

Observed conditions:

```text
ErrImagePull
ImagePullBackOff
```

Root cause:

* invalid registry
* nonexistent image reference

Recovery:

* replaced the invalid image with a valid pinned NGINX image
* monitored Deployment rollout
* verified all replicas became Ready
* tested the application from inside the recovered Pod

---

### Missing Configuration

Observed condition:

```text
CreateContainerConfigError
```

Root cause:

* the workload referenced a ConfigMap that did not exist

Recovery:

* created the required ConfigMap
* injected environment variables
* waited for the Pod to recover
* verified the values inside the running container

---

### Scheduling Failure

Observed condition:

```text
Pending
```

Root cause:

* the workload requested more CPU and memory than the node could provide

Recovery:

* inspected scheduler events
* compared requests with node allocatable resources
* reduced CPU and memory requirements
* verified successful node assignment
* confirmed the application became Ready

---

### Service Routing Failure

Observed condition:

* Service existed
* backend Pods were healthy
* EndpointSlice contained no ready endpoints

Root cause:

* the Service selector did not match the labels assigned to backend Pods

Recovery:

* corrected the Service selector
* waited for EndpointSlice reconciliation
* verified two ready backend endpoints
* tested DNS resolution
* sent repeated HTTP requests through the Service

---

## Troubleshooting Methodology

The incident-response workflows follow an evidence-first process:

1. Inspect the current resource state.
2. Identify the affected Kubernetes object.
3. Describe the object and review its conditions.
4. Inspect container waiting states.
5. Review Kubernetes events.
6. Compare desired configuration with observed state.
7. Confirm the root cause with evidence.
8. Apply the smallest corrective change.
9. Wait for Kubernetes reconciliation.
10. Validate readiness, networking, DNS, and application behavior.
11. Capture before-and-after evidence.
12. Generate a final health report.

This process avoids speculative changes and creates an auditable recovery record.

---

## Representative Commands

### Cluster Health

```bash
kubectl cluster-info

kubectl get nodes -o wide

kubectl get pods --all-namespaces -o wide
```

### Workload Inspection

```bash
kubectl get deployments --all-namespaces

kubectl get pods -n NAMESPACE -o wide

kubectl describe pod POD_NAME -n NAMESPACE

kubectl logs POD_NAME -n NAMESPACE
```

### Rollout Validation

```bash
kubectl rollout status deployment/DEPLOYMENT_NAME \
  -n NAMESPACE

kubectl rollout history deployment/DEPLOYMENT_NAME \
  -n NAMESPACE
```

### Kubernetes Events

```bash
kubectl get events \
  --all-namespaces \
  --sort-by=.metadata.creationTimestamp

kubectl get events \
  --all-namespaces \
  --field-selector type=Warning \
  --sort-by=.metadata.creationTimestamp
```

### Services and EndpointSlices

```bash
kubectl get services --all-namespaces

kubectl get endpointslice --all-namespaces

kubectl describe service SERVICE_NAME \
  -n NAMESPACE

kubectl get pods \
  -n NAMESPACE \
  --show-labels
```

### Resource Inspection

```bash
kubectl describe node

kubectl top nodes

kubectl top pods \
  --all-namespaces
```

### RBAC Validation

```bash
kubectl auth can-i get pods \
  --as=system:serviceaccount:NAMESPACE:SERVICE_ACCOUNT \
  -n NAMESPACE

kubectl auth can-i delete deployments \
  --as=system:serviceaccount:NAMESPACE:SERVICE_ACCOUNT \
  -n NAMESPACE
```

### NetworkPolicy Validation

```bash
kubectl get networkpolicy \
  --all-namespaces

kubectl describe networkpolicy POLICY_NAME \
  -n NAMESPACE
```

### Persistent Storage

```bash
kubectl get storageclass

kubectl get persistentvolume

kubectl get persistentvolumeclaim \
  --all-namespaces
```

### Autoscaling

```bash
kubectl get horizontalpodautoscaler \
  --all-namespaces

kubectl describe horizontalpodautoscaler HPA_NAME \
  -n NAMESPACE
```

---

## Operational Validation

Each implementation includes one or more of the following validation techniques:

* rollout status checks
* readiness checks
* Pod condition inspection
* Kubernetes event analysis
* container log inspection
* in-cluster DNS queries
* HTTP connectivity tests
* Service endpoint validation
* EndpointSlice inspection
* environment variable verification
* data persistence checks
* RBAC authorization checks
* NetworkPolicy allow-and-deny tests
* autoscaling behavior verification
* backup and restore validation
* service mesh traffic testing
* mutual TLS validation
* final state reports
* SHA-256 evidence checksums

---

## Skills Demonstrated

### Kubernetes Administration

* kubeadm cluster initialization
* kubelet management
* kubectl administration
* containerd integration
* control-plane architecture
* cluster component validation
* namespace administration

### Workload Engineering

* Pods
* ReplicaSets
* Deployments
* StatefulSets
* DaemonSets
* Jobs
* Services
* rolling updates
* self-healing workloads
* application readiness

### Networking

* Calico CNI
* pod networking
* Service discovery
* ClusterIP Services
* LoadBalancer Services
* MetalLB
* NGINX Ingress
* CoreDNS
* NetworkPolicies
* EndpointSlices
* multi-cluster connectivity concepts

### Storage

* PersistentVolumes
* PersistentVolumeClaims
* StorageClasses
* persistent application data
* topology-aware storage
* stateful workload recovery

### Observability

* Prometheus
* Grafana
* Kubernetes metrics
* cluster monitoring
* workload monitoring
* centralized logging
* health dashboards
* operational evidence collection

### Security

* RBAC
* service accounts
* least privilege
* NetworkPolicy microsegmentation
* Pod Security Standards
* security contexts
* non-root containers
* Linux capability restrictions
* seccomp
* mutual TLS
* authorization policies
* compliance validation

### Reliability

* Horizontal Pod Autoscaling
* scheduling diagnostics
* capacity constraints
* resource requests and limits
* high-availability workload patterns
* backup and restore
* disaster recovery
* incident response
* root-cause analysis

### Automation

* Bash scripting
* declarative Kubernetes manifests
* repeatable validation
* Git-based configuration management
* CI/CD concepts
* GitOps operating patterns
* automated evidence generation

---

## Production Relevance

The implementations in this portfolio map directly to real platform engineering and Site Reliability Engineering responsibilities.

They address operational scenarios such as:

* failed container image pulls
* missing application configuration
* unschedulable workloads
* incorrect resource sizing
* broken Service routing
* unavailable backend endpoints
* ingress misconfiguration
* DNS resolution failures
* CNI initialization problems
* overly permissive access
* unauthorized workload communication
* application scaling under load
* persistent storage requirements
* monitoring and alerting gaps
* cluster backup and restoration
* service-to-service encryption
* traffic shifting and resilience
* multi-environment service exposure
* Kubernetes security hardening

---

## Engineering Principles

The work in this repository follows several consistent principles:

### Declarative Configuration

Infrastructure and workloads are represented through version-controlled Kubernetes manifests.

### Evidence Before Changes

Failures are diagnosed using resource state, descriptions, events, logs, conditions, and networking evidence before corrections are applied.

### Smallest Safe Correction

Each failure is addressed with the smallest change that resolves the confirmed root cause.

### End-to-End Validation

A resource is not considered healthy only because it exists. Validation includes readiness, DNS, routing, connectivity, metrics, security controls, and application behavior.

### Reproducibility

Commands, manifests, scripts, reports, and validation steps are preserved so the environments can be recreated and reviewed.

### Security by Default

Workloads use least privilege, restricted communication, secure runtime settings, and explicit access controls wherever applicable.

---

## Completed Kubernetes Coverage

The portfolio covers the following progression:

1. Kubernetes fundamentals
2. Kubernetes cluster architecture
3. Pods, Services, and Deployments
4. StatefulSets and DaemonSets
5. ConfigMaps and runtime configuration
6. CNI networking
7. Ingress and centralized traffic routing
8. Horizontal Pod Autoscaling
9. PersistentVolumes and PersistentVolumeClaims
10. Prometheus and Grafana monitoring
11. centralized Kubernetes logging
12. Kubernetes RBAC
13. NetworkPolicy security
14. CI/CD and GitOps
15. cluster and scheduling autoscaling concepts
16. multi-environment Kubernetes connectivity
17. advanced Kubernetes security
18. disaster recovery and backup
19. Istio service mesh
20. advanced Kubernetes troubleshooting

---

## Portfolio Outcome

This repository demonstrates the ability to design, deploy, secure, monitor, scale, troubleshoot, and recover Kubernetes environments across the complete platform lifecycle.

The work goes beyond isolated manifests by including:

* architecture decisions
* repeatable automation
* operational verification
* failure simulation
* root-cause diagnosis
* corrective actions
* security enforcement
* recovery procedures
* production-oriented documentation

---

## Author

**Bilal Fayyaz**

Focused on:

* Kubernetes
* DevOps
* Site Reliability Engineering
* cloud-native infrastructure
* platform engineering
* infrastructure automation
* observability
* security
* disaster recovery

---

## License

This repository is available for educational, demonstration, and portfolio purposes. Individual directories may contain additional implementation-specific documentation.
