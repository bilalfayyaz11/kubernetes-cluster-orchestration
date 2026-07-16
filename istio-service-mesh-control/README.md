# Istio Service Mesh Traffic, Observability, and Zero-Trust Security

## What This Does

This implementation deploys Istio on a multi-node Kubernetes cluster and demonstrates how a service mesh controls communication between microservices without requiring networking logic inside application code.

The environment runs the Bookinfo microservices with automatic Envoy sidecar injection, ingress routing, version-aware traffic distribution, canary releases, circuit breaking, metrics, distributed tracing, strict mutual TLS, and identity-based authorization.

Prometheus, Grafana, Jaeger, and Kiali provide visibility into request volume, response codes, service dependencies, proxy synchronization, and distributed request paths. Reusable validation scripts verify observability health, mesh configuration, security policies, and ingress availability.

## Architecture

    +-----------------------------------------------------------------------+
    |                             Client Traffic                            |
    |                                                                       |
    |                     HTTP :80          HTTPS :443                       |
    +------------------------------+----------------------------------------+
                                   |
                                   v
    +-----------------------------------------------------------------------+
    |                       Istio Ingress Gateway                           |
    |                                                                       |
    |  Gateway                                                             |
    |  Bookinfo VirtualService                                             |
    |  Productpage AuthorizationPolicy                                     |
    +------------------------------+----------------------------------------+
                                   |
                                   v
    +-----------------------------------------------------------------------+
    |                    Kubernetes Service Mesh                            |
    |                                                                       |
    |  +------------------+        +-------------------------------+        |
    |  | Productpage v1   |------->| Reviews VirtualService        |        |
    |  |                  |        |                               |        |
    |  | Application      |        | Header routing               |        |
    |  | Envoy sidecar    |        | Weighted canary routing       |        |
    |  +--------+---------+        +---------------+---------------+        |
    |           |                                  |                        |
    |           |                 +----------------+----------------+       |
    |           |                 |                                 |       |
    |           v                 v                                 v       |
    |  +------------------+  +------------------+          +----------------+|
    |  | Details v1       |  | Reviews v1       |          | Reviews v3     ||
    |  | Application      |  | Application      |          | Application    ||
    |  | Envoy sidecar    |  | Envoy sidecar    |          | Envoy sidecar  ||
    |  +------------------+  +------------------+          +--------+-------+|
    |                                                                 |     |
    |                                                                 v     |
    |                                                        +----------------+
    |                                                        | Ratings v1     |
    |                                                        | Circuit breaker|
    |                                                        | Envoy sidecar  |
    |                                                        +----------------+
    |                                                                       |
    |  Security                                                             |
    |  - Strict mutual TLS                                                  |
    |  - Workload identity                                                  |
    |  - Ingress-only productpage access                                    |
    |  - Envoy-enforced authorization                                       |
    +------------------------------+----------------------------------------+
                                   |
                                   v
    +-----------------------------------------------------------------------+
    |                       Observability Platform                          |
    |                                                                       |
    |  +----------------+  +----------------+  +------------------------+   |
    |  | Prometheus     |  | Grafana        |  | Jaeger                 |   |
    |  | Metrics        |  | Dashboards     |  | Distributed Tracing    |   |
    |  +----------------+  +----------------+  +------------------------+   |
    |                                                                       |
    |                         +----------------+                            |
    |                         | Kiali          |                            |
    |                         | Mesh Topology  |                            |
    |                         +----------------+                            |
    +-----------------------------------------------------------------------+

## Prerequisites

- Ubuntu 24.04 LTS
- At least 4 CPU cores
- At least 8 GiB of memory
- At least 20 GiB of available disk space
- A user with sudo privileges
- Docker Engine
- kubectl
- Kind
- Istio CLI
- Helm
- Git
- curl
- jq
- tree
- Internet access for release downloads and container images

## Setup & Installation

Update package metadata and install required utilities:

sudo apt-get update

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ca-certificates \
  curl \
  git \
  jq \
  tree

Grant the current user access to Docker:

sudo usermod -aG docker "$USER"

newgrp docker

Install the current stable Kind release:

KIND_VERSION="$(
  curl -fsSL \
    https://api.github.com/repos/kubernetes-sigs/kind/releases/latest \
  | jq -r '.tag_name'
)"

curl -fLo /tmp/kind \
  "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64"

sudo install \
  -o root \
  -g root \
  -m 0755 \
  /tmp/kind \
  /usr/local/bin/kind

rm -f /tmp/kind

Install the current stable Istio release:

ISTIO_VERSION="$(
  curl -fsSL \
    https://api.github.com/repos/istio/istio/releases/latest \
  | jq -r '.tag_name' \
  | sed 's/^v//'
)"

curl -fsSL https://istio.io/downloadIstio \
  | ISTIO_VERSION="$ISTIO_VERSION" TARGET_ARCH=x86_64 sh -

sudo install \
  -o root \
  -g root \
  -m 0755 \
  "istio-${ISTIO_VERSION}/bin/istioctl" \
  /usr/local/bin/istioctl

ln -sfn \
  "istio-${ISTIO_VERSION}" \
  istio-current

Verify the required tools:

docker --version

kubectl version --client

kind version

istioctl version --remote=false

helm version --short

## How to Reproduce

Clone the repository:

git clone https://github.com/bilalfayyaz11/kubernetes-cluster-orchestration.git

Enter the implementation directory:

cd kubernetes-cluster-orchestration/istio-service-mesh-control

Create the multi-node Kubernetes cluster:

kind create cluster \
  --name istio \
  --config kind-config.yaml \
  --wait 300s

Verify the cluster:

kubectl cluster-info

kubectl get nodes -o wide

Install Istio using the demonstration profile:

istioctl install \
  --set profile=demo \
  -y

Wait for the control plane:

kubectl rollout status \
  deployment/istiod \
  --namespace istio-system \
  --timeout=300s

Enable automatic sidecar injection:

kubectl label namespace default \
  istio-injection=enabled \
  --overwrite

Deploy Bookinfo:

kubectl apply \
  -f istio-current/samples/bookinfo/platform/kube/bookinfo.yaml

Wait for all Bookinfo deployments:

kubectl rollout status deployment/details

kubectl rollout status deployment/productpage

kubectl rollout status deployment/ratings

kubectl rollout status deployment/reviews-v1

kubectl rollout status deployment/reviews-v2

kubectl rollout status deployment/reviews-v3

Verify that each workload includes its application container and Envoy sidecar:

kubectl get pods

istioctl proxy-status

Apply the Bookinfo ingress configuration:

kubectl apply \
  -f manifests/bookinfo-gateway.yaml

kubectl apply \
  -f manifests/bookinfo-virtualservice.yaml

Patch the ingress gateway service for the Kind port mappings:

kubectl patch service istio-ingressgateway \
  --namespace istio-system \
  --type merge \
  -p '{
    "spec": {
      "type": "NodePort",
      "ports": [
        {
          "name": "status-port",
          "port": 15021,
          "protocol": "TCP",
          "targetPort": 15021,
          "nodePort": 30021
        },
        {
          "name": "http2",
          "port": 80,
          "protocol": "TCP",
          "targetPort": 8080,
          "nodePort": 30080
        },
        {
          "name": "https",
          "port": 443,
          "protocol": "TCP",
          "targetPort": 8443,
          "nodePort": 30443
        }
      ]
    }
  }'

Validate ingress access:

curl -fsS \
  http://127.0.0.1/productpage \
  | grep -o '<title>[^<]*</title>'

Apply service subsets and load-balancing configuration:

kubectl apply \
  -f manifests/bookinfo-destination-rules.yaml

Apply identity-aware routing:

kubectl apply \
  -f manifests/reviews-user-routing.yaml

Replace identity-aware routing with a weighted canary split:

kubectl apply \
  -f manifests/reviews-canary-routing.yaml

Generate ingress traffic:

for request in $(seq 1 100); do
  curl -fsS \
    http://127.0.0.1/productpage \
    > /dev/null

  sleep 0.1
done

Install the observability components:

kubectl apply \
  -f istio-current/samples/addons/prometheus.yaml

kubectl apply \
  -f istio-current/samples/addons/grafana.yaml

kubectl apply \
  -f istio-current/samples/addons/jaeger.yaml

kubectl apply \
  -f istio-current/samples/addons/kiali.yaml

Wait for the observability deployments:

kubectl rollout status \
  deployment/prometheus \
  --namespace istio-system \
  --timeout=300s

kubectl rollout status \
  deployment/grafana \
  --namespace istio-system \
  --timeout=300s

kubectl rollout status \
  deployment/jaeger \
  --namespace istio-system \
  --timeout=300s

kubectl rollout status \
  deployment/kiali \
  --namespace istio-system \
  --timeout=300s

Apply the ratings resilience policy:

kubectl apply \
  -f manifests/ratings-resilience.yaml

Apply strict mutual TLS:

kubectl apply \
  -f manifests/bookinfo-mtls.yaml

Apply the ingress-only authorization policy:

kubectl apply \
  -f manifests/productpage-authorization.yaml

Analyze the complete Istio configuration:

istioctl analyze

Verify proxy synchronization:

istioctl proxy-status

Run the observability verification:

chmod +x scripts/verify-observability.sh

./scripts/verify-observability.sh

Run the security verification:

chmod +x scripts/verify-mesh-security.sh

./scripts/verify-mesh-security.sh

## Traffic Management

- Istio Gateway for north-south ingress traffic
- VirtualService-based HTTP routing
- DestinationRule service subsets
- Fully qualified Kubernetes service hosts
- Header-based routing for selected users
- Weighted 50/50 canary distribution
- Round-robin load balancing
- Envoy route and cluster inspection
- Version-specific service telemetry

## Resilience Controls

- TCP connection-pool limits
- HTTP request queue limits
- Maximum requests per connection
- Retry limits
- Consecutive HTTP 5xx detection
- Unhealthy endpoint ejection
- Configurable ejection intervals
- Configurable recovery periods
- Controlled failure blast radius

## Security Controls

- Automatic Envoy sidecar injection
- Strict namespace-scoped mutual TLS
- SPIFFE-compatible workload identities
- Identity-based authorization
- Ingress-only productpage access
- Denied direct workload access
- Stable Istio security API resources
- Proxy synchronization validation
- Configuration analysis with istioctl

## Observability

- Prometheus request metrics
- Grafana dashboards
- Jaeger distributed tracing
- Kiali service topology
- Response-code aggregation
- Requests grouped by service version
- Envoy proxy synchronization
- Dashboard health validation
- Reusable terminal-based verification scripts

## Tools Used

- Kubernetes
- Kind
- Docker
- kubectl
- Istio
- istioctl
- Envoy
- Helm
- Prometheus
- Grafana
- Jaeger
- Kiali
- Bash
- curl
- jq
- YAML
- Git
- Linux

## Key Skills Demonstrated

- Kubernetes service-mesh installation
- Multi-node Kind cluster configuration
- Istio control-plane administration
- Automatic Envoy sidecar injection
- Ingress gateway configuration
- Service-to-service traffic management
- Header-based request routing
- Weighted canary delivery
- DestinationRule subset design
- Envoy configuration inspection
- Circuit-breaker implementation
- Outlier detection
- Mutual TLS enforcement
- Workload identity authorization
- Zero-trust service communication
- Metrics collection and querying
- Distributed tracing
- Service topology visualization
- Istio configuration validation
- Cloud-native troubleshooting
- Platform engineering automation

## Real-World Use Case

A platform engineering team can use this architecture to provide shared traffic management, security, and observability capabilities for microservices running on Kubernetes. Application teams can release new service versions gradually, route selected users to canary versions, enforce encrypted service communication, restrict access using workload identity, and diagnose failures through centralized metrics and traces. This reduces application-level networking complexity while giving operators consistent control over reliability and security.

## Lessons Learned

- Sidecar injection must be enabled before workload creation or the pods must be restarted.
- Minimal application images often exclude troubleshooting utilities such as curl.
- A temporary injected diagnostic pod is safer than modifying production-style application containers.
- Kind host port mappings must match the ingress gateway NodePorts exactly.
- DestinationRule subsets must match workload version labels.
- VirtualService rules are evaluated in order, so specific matches must appear before catch-all routes.
- Weighted routing is probabilistic and should be evaluated across a meaningful request sample.
- Strict mutual TLS should be scoped carefully to avoid unexpectedly affecting unrelated namespaces.
- Authorization identities should be discovered from live service accounts rather than hard-coded.
- Istio demonstration observability components are suitable for evaluation but require production hardening before organizational use.

## Troubleshooting Log

Issue:
The supplied Kind installation used an obsolete release.

Resolution:
Installed the current stable release dynamically and recorded the exact version.

Issue:
The original Istio PATH command stored a directory based on the shell's current working directory.

Resolution:
Installed istioctl into /usr/local/bin and used a stable symbolic link for release content.

Issue:
The Bookinfo application container did not include curl.

Resolution:
Created a temporary curlimages/curl pod with an injected Envoy sidecar to validate service-to-service communication.

Issue:
Sidecar injection could be missed when workloads were deployed before namespace labeling.

Resolution:
Enabled automatic injection before deploying Bookinfo and verified that each pod contained two ready containers.

Issue:
The ingress gateway service did not use the NodePorts mapped by Kind.

Resolution:
Patched the service to expose HTTP through NodePort 30080 and HTTPS through NodePort 30443.

Issue:
The original routing configuration omitted the required VirtualService hosts field.

Resolution:
Added explicit fully qualified service hosts to every routing resource.

Issue:
The original manifests used older beta API versions.

Resolution:
Used stable networking.istio.io/v1 and security.istio.io/v1 resources.

Issue:
The original circuit-breaker policy placed outlier-detection fields inside the HTTP connection pool.

Resolution:
Moved failure detection, ejection interval, and recovery settings into trafficPolicy.outlierDetection.

Issue:
The original mutual TLS policy applied to the complete mesh.

Resolution:
Scoped strict mutual TLS to the namespace containing the Bookinfo workloads.

Issue:
The original authorization policy hard-coded an ingress service-account identity.

Resolution:
Discovered the active ingress gateway service account and generated the matching workload principal.

Issue:
The original mTLS verification command was removed from current Istio releases.

Resolution:
Inspected Envoy transport-socket configuration using istioctl proxy-config clusters.

Issue:
The original Prometheus verification command omitted the required server address.

Resolution:
Queried the Prometheus HTTP API directly and validated the JSON response with jq.

Issue:
The original Jaeger port-forward command assumed an incorrect service name and service port.

Resolution:
Forwarded the tracing service port exposed by the installed Istio observability manifest.

Issue:
Unmanaged background port-forward processes could remain active.

Resolution:
Recorded process IDs and logs inside a temporary runtime directory for controlled cleanup.
