# Kubernetes Network Microsegmentation with Calico Network Policies

## What This Does

This implementation secures a Kubernetes cluster by enforcing microsegmentation using Kubernetes Network Policies with the Calico Container Network Interface (CNI). A three-tier application is deployed across isolated namespaces, and communication is restricted according to the principle of least privilege, allowing only approved service-to-service traffic while blocking unauthorized lateral movement.

The solution demonstrates production-style workload isolation, namespace segmentation, ingress and egress filtering, DNS-aware policy design, policy validation, troubleshooting workflows, and configuration backup. It also includes automated validation scripts that verify both permitted and denied communication paths, making the implementation repeatable and suitable for enterprise platform engineering environments.

## Architecture

```
                               Kubernetes Cluster
┌────────────────────────────────────────────────────────────────────────────┐
│                                                                            │
│  ┌────────────────────┐        TCP/80        ┌────────────────────┐         │
│  │ Frontend Namespace │ ───────────────────► │ Backend Namespace  │         │
│  │                    │                      │                    │         │
│  │ frontend-app       │                      │ backend-app        │         │
│  │ frontend-service   │                      │ backend-service    │         │
│  └─────────┬──────────┘                      └─────────┬──────────┘         │
│            │                                           │                    │
│            │                                           │ TCP/80             │
│            │                                           ▼                    │
│            │                              ┌────────────────────────┐        │
│            │                              │ Database Namespace     │        │
│            │                              │                        │        │
│            │                              │ database-app           │        │
│            │                              │ database-service       │        │
│            │                              └────────────────────────┘        │
│            │                                                               │
│            │                                                               │
│            │              Blocked Communication                            │
│            ├──────────────X──────────────► Database                        │
│            │                                                               │
│            │                                                               │
│            ▼                                                               │
│  ┌────────────────────┐                                                    │
│  │ Diagnostics        │                                                    │
│  │ Namespace          │                                                    │
│  │                    │                                                    │
│  │ network-debug      │                                                    │
│  └────────────────────┘                                                    │
│                                                                            │
│      Calico CNI Enforces Kubernetes Network Policies                       │
└────────────────────────────────────────────────────────────────────────────┘
```

## Prerequisites

- Ubuntu 24.04
- Docker
- Kind
- kubectl
- Git
- curl
- Calico CNI
- Internet connectivity for container image downloads

## Setup & Installation

```bash
sudo systemctl enable --now docker

curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.32.0/kind-linux-amd64
chmod +x kind
sudo mv kind /usr/local/bin/

kubectl version --client
kind version
docker --version

mkdir -p ~/kubernetes-network-security
cd ~/kubernetes-network-security
```

## How to Reproduce

Create the Kubernetes cluster:

```bash
kind create cluster --config kind-config.yaml --name network-security
```

Install Calico:

```bash
kubectl apply -f calico.yaml
```

Deploy the workloads:

```bash
kubectl apply -f frontend-deployment.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f database-deployment.yaml
```

Apply security policies:

```bash
kubectl apply -f frontend-netpol.yaml
kubectl apply -f backend-netpol.yaml
kubectl apply -f database-netpol.yaml

kubectl apply -f deny-all-frontend.yaml
kubectl apply -f database-port-specific.yaml
```

Validate the implementation:

```bash
chmod +x test-network-policies.sh
./test-network-policies.sh

chmod +x validate-network-policies.sh
./validate-network-policies.sh
```

## Security Controls Implemented

- Namespace isolation
- Kubernetes Network Policies
- Default deny networking
- Least privilege communication
- Controlled ingress rules
- Controlled egress rules
- DNS-aware policy exceptions
- Port-specific access control
- Namespace selectors
- Pod selectors
- Diagnostics namespace
- Policy validation automation

## Tools Used

- Kubernetes
- Kind
- Docker
- Calico CNI
- kubectl
- YAML
- Bash
- Linux
- curl
- Git

## Key Skills Demonstrated

- Kubernetes network security
- Kubernetes Network Policy implementation
- Microsegmentation
- Namespace isolation
- Zero Trust networking
- Calico CNI deployment
- Kubernetes service networking
- Pod-to-pod traffic control
- Ingress and egress filtering
- DNS-aware security policy design
- Automated policy validation
- Network troubleshooting
- Platform Engineering
- DevSecOps
- Cloud Infrastructure Security

## Real-World Use Case

Enterprise Kubernetes platforms frequently host multiple business services inside shared clusters. Without network segmentation, every workload can communicate with every other workload, significantly increasing the blast radius of a compromise. This implementation demonstrates how production engineering teams enforce Zero Trust networking using Kubernetes Network Policies so that only explicitly approved application paths remain available while unauthorized lateral movement is prevented.

## Lessons Learned

- Network Policies are additive rather than sequential.
- Namespace selectors and pod selectors should be combined carefully to avoid unintended access.
- Default deny policies should be implemented before introducing explicit allow rules.
- DNS traffic requires dedicated egress permissions.
- Validation scripts significantly simplify production troubleshooting.
- Kubernetes service reachability should be verified using HTTP and TCP rather than ICMP.

## Troubleshooting Log

Issue:

The supplied manifests referenced an older Calico release.

Resolution:

Updated to a current Calico release compatible with Kubernetes 1.36.

Issue:

The original NetworkPolicy selectors separated namespaceSelector and podSelector into different peer entries.

Resolution:

Combined both selectors into a single peer definition to enforce namespace and workload identity simultaneously.

Issue:

Frontend workloads relied only on an egress policy.

Resolution:

Introduced a namespace-wide default deny policy together with explicit ingress rules.

Issue:

Interactive temporary pods could hang in browser terminals.

Resolution:

Replaced interactive testing with deterministic non-interactive validation scripts.

Issue:

Testing ClusterIP services with ping produced misleading results.

Resolution:

Used HTTP and TCP validation instead of ICMP because Kubernetes services generally do not respond to ping.

Issue:

The standard NGINX image did not reliably include curl for connectivity testing.

Resolution:

Added a dedicated network-client sidecar for repeatable policy validation.
