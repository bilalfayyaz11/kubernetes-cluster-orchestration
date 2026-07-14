# Kubernetes Network Security Configuration

## Overview

This implementation secures a three-tier Kubernetes workload using Calico and Kubernetes NetworkPolicy resources.

The frontend, backend, and database workloads run in separate namespaces. Communication is restricted to the minimum required service path:

    Frontend -> Backend -> Database

Traffic that does not match an explicitly approved source, destination, protocol, and port is denied.

## Architecture

    +-----------------------------+
    | Frontend Namespace          |
    |                             |
    | frontend-app                |
    | app=frontend                |
    | tier=web                    |
    +-------------+---------------+
                  |
                  | TCP 80
                  | Allowed
                  v
    +-----------------------------+
    | Backend Namespace           |
    |                             |
    | backend-app                 |
    | app=backend                 |
    | tier=api                    |
    +-------------+---------------+
                  |
                  | TCP 80
                  | Allowed
                  v
    +-----------------------------+
    | Database Namespace          |
    |                             |
    | database-app               |
    | app=database                |
    | tier=data                   |
    +-----------------------------+

    Blocked paths:

    Frontend  -X-> Database
    Database  -X-> Backend
    Database  -X-> Frontend
    Untrusted -X-> Database

## Namespace Design

### Frontend

The frontend namespace contains the web-facing application tier.

Active controls:

- Namespace-wide default-deny ingress and egress
- Egress permission to backend pods on TCP port 80
- Egress permission to Kubernetes DNS on TCP and UDP port 53
- Controlled ingress from matching frontend workloads on TCP port 80

### Backend

The backend namespace contains the application API tier.

Active controls:

- Ingress permission from matching frontend pods on TCP port 80
- Egress permission to matching database pods on TCP port 80
- Egress permission to Kubernetes DNS on TCP and UDP port 53
- Temporary controlled ingress from the diagnostics namespace on TCP port 80

### Database

The database namespace represents the protected data tier.

Active controls:

- Ingress permission only from matching backend pods on TCP port 80
- Egress permission only to Kubernetes DNS
- Port-specific ingress control for the active application port

### Diagnostics

The diagnostics namespace contains a restricted network troubleshooting pod.

Active controls:

- Namespace-wide default deny
- DNS egress permission
- TCP port 80 egress permission to backend pods
- No access to the database tier

## NetworkPolicy Selection Model

Namespace identities are selected using the Kubernetes-managed label:

    kubernetes.io/metadata.name

Workload identities are selected using application labels such as:

    app=frontend
    tier=web

    app=backend
    tier=api

    app=database
    tier=data

Namespace and pod selectors are placed in the same NetworkPolicy peer entry. This requires both identity conditions to match.

## Approved Communication Matrix

| Source | Destination | Protocol | Port | Result |
|---|---|---:|---:|---|
| Frontend | Backend | TCP | 80 | Allowed |
| Backend | Database | TCP | 80 | Allowed |
| Frontend | Database | TCP | 80 | Blocked |
| Database | Backend | TCP | 80 | Blocked |
| Database | Frontend | TCP | 80 | Blocked |
| Diagnostics | Backend | TCP | 80 | Allowed |
| Diagnostics | Database | TCP | 80 | Blocked |
| Untrusted default namespace pod | Database | TCP | 80 | Blocked |
| Selected workloads | Kubernetes DNS | TCP/UDP | 53 | Allowed |

## Security Benefits

1. Least-privilege communication between application tiers
2. Reduced lateral movement opportunities after workload compromise
3. Namespace and workload identity-based segmentation
4. Explicit DNS access instead of unrestricted egress
5. Repeatable validation of allowed and denied traffic
6. Controlled troubleshooting access through a dedicated namespace
7. Reduced blast radius for unauthorized workloads

## Validation Strategy

Connectivity is tested using dedicated network-client containers and a restricted diagnostics pod.

Allowed paths must return the expected application response.

Blocked paths must time out or fail within a bounded maximum duration.

The automated validation scripts report pass and failure totals and return a nonzero exit code when an unexpected result occurs.

## Operational Notes

Kubernetes NetworkPolicies are additive. A later policy does not replace an earlier policy.

Traffic is allowed when an applicable policy permits it and the opposite traffic direction is also permitted where required.

A failed ICMP ping to a ClusterIP is not a reliable NetworkPolicy test. HTTP and TCP checks are used instead.

DNS resolution and application connectivity are tested independently because successful DNS lookup does not prove that destination traffic is allowed.
