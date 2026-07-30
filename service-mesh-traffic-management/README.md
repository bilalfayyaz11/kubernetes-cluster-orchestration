# Istio Service Mesh Traffic Management

## What This Does

This implementation configures an Istio service mesh on Kubernetes and demonstrates controlled traffic delivery across multiple versions of a backend service.

The architecture includes an externally accessible frontend, two backend versions, automatic Istio sidecar injection, an ingress gateway, service subsets, weighted canary routing, header-based routing, URI-based routing, and mesh configuration validation.

Normal backend traffic is distributed using a 90/10 split between versions one and two. Premium users and designated test users are routed directly to version two. Requests using version-specific URI prefixes are routed deterministically to the corresponding backend version.

## Architecture

    External Client
           |
           | HTTP
           v
    Istio Ingress Gateway
           |
           v
      Frontend Service
           |
           | Internal mesh traffic
           v
       Backend Service
           |
           +-----------------------------+
           |                             |
           v                             v
      Backend v1                    Backend v2
      Primary version               Canary version
           ^                             ^
           |                             |
           +---------- Istio ------------+
                 VirtualService
                 DestinationRule

## Traffic Policies

    Standard requests
        90% -> backend v1
        10% -> backend v2

    Header: user-type: premium
        100% -> backend v2

    Header: test-user: true
        100% -> backend v2

    URI prefix: /api/v1
        100% -> backend v1

    URI prefix: /api/v2
        100% -> backend v2

## Components

### Frontend

The frontend is a lightweight HTTP service exposed through the Istio ingress gateway.

Its Kubernetes Service provides a stable internal endpoint, while the Gateway and VirtualService make it accessible from outside the mesh.

### Backend Version One

Backend version one represents the stable production release.

It is identified by these workload labels:

    app: backend
    version: v1

### Backend Version Two

Backend version two represents a newer canary release.

It is identified by these workload labels:

    app: backend
    version: v2

### Istio Sidecars

Automatic sidecar injection adds an `istio-proxy` container to each application Pod.

The sidecars intercept network traffic and enforce routing policies without requiring changes to the application source code.

### Gateway

The Istio Gateway accepts external HTTP traffic and forwards matching requests into the service mesh.

### DestinationRule

The DestinationRule defines the backend service subsets:

    v1
    v2

Each subset maps to the corresponding Kubernetes workload version label.

### VirtualServices

The frontend VirtualService connects the ingress gateway to the frontend service.

The backend VirtualService implements:

- Weighted canary routing
- Header-based routing
- URI-based routing
- Default fallback routing

## Repository Structure

    service-mesh-traffic-management/
    ├── manifests/
    │   ├── applications.yaml
    │   └── traffic-management.yaml
    └── README.md

## Prerequisites

The following tools are required:

    Docker Engine
    kubectl
    Minikube
    istioctl
    curl
    Git

Verify the tools:

    docker --version
    kubectl version --client
    minikube version
    istioctl version --remote=false

Verify Docker access:

    docker info

## Start the Kubernetes Cluster

Start Minikube with sufficient resources:

    minikube start \
      --driver=docker \
      --cpus=3 \
      --memory=7168mb

Verify the cluster:

    minikube status
    kubectl get nodes -o wide
    kubectl get pods -n kube-system

## Install Istio

Install Istio using the demonstration profile:

    istioctl install \
      --set profile=demo \
      -y

Wait for the control plane:

    kubectl rollout status deployment/istiod \
      -n istio-system \
      --timeout=240s

Wait for the ingress gateway:

    kubectl rollout status deployment/istio-ingressgateway \
      -n istio-system \
      --timeout=240s

Verify Istio:

    kubectl get pods -n istio-system
    istioctl version

## Create the Mesh Namespace

Create the namespace:

    kubectl create namespace microservices

Enable automatic sidecar injection:

    kubectl label namespace microservices \
      istio-injection=enabled \
      --overwrite

Verify the label:

    kubectl get namespace microservices --show-labels

## Validate the Manifests

Move into this directory:

    cd service-mesh-traffic-management

Validate the application definitions:

    kubectl apply --dry-run=client \
      -f manifests/applications.yaml

Validate the traffic configuration:

    kubectl apply --dry-run=client \
      -f manifests/traffic-management.yaml

## Deploy the Applications

Apply the application definitions:

    kubectl apply \
      -f manifests/applications.yaml

Wait for each rollout:

    kubectl rollout status deployment/frontend-v1 \
      -n microservices \
      --timeout=180s

    kubectl rollout status deployment/backend-v1 \
      -n microservices \
      --timeout=180s

    kubectl rollout status deployment/backend-v2 \
      -n microservices \
      --timeout=180s

## Verify Sidecar Injection

List the application Pods:

    kubectl get pods -n microservices

Display the containers inside every Pod:

    kubectl get pods \
      -n microservices \
      -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].name}{"\n"}{end}'

Each application Pod should contain:

    application-container
    istio-proxy

## Apply Traffic Management

Apply the Gateway, DestinationRule, and VirtualServices:

    kubectl apply \
      -f manifests/traffic-management.yaml

Inspect the resources:

    kubectl get gateway \
      -n microservices

    kubectl get virtualservice \
      -n microservices

    kubectl get destinationrule \
      -n microservices

## Validate the Mesh Configuration

Analyze the namespace:

    istioctl analyze -n microservices

Expected result:

    No validation issues found

## Access the Ingress Gateway

Get the Minikube IP:

    INGRESS_HOST="$(minikube ip)"

Get the ingress NodePort:

    INGRESS_PORT="$(
      kubectl -n istio-system get service istio-ingressgateway \
        -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}'
    )"

Create the gateway URL:

    GATEWAY_URL="http://${INGRESS_HOST}:${INGRESS_PORT}"

Display it:

    echo "$GATEWAY_URL"

Test the frontend:

    curl -fsS "$GATEWAY_URL"

Expected response:

    Frontend v1

## Create an Internal Traffic Client

Create a temporary client inside the mesh:

    kubectl apply -n microservices -f - << 'CLIENT'
    apiVersion: v1
    kind: Pod
    metadata:
      name: traffic-client
      labels:
        app: traffic-client
    spec:
      containers:
        - name: curl
          image: curlimages/curl:8.16.0
          command:
            - sleep
            - "3600"
    CLIENT

Wait for readiness:

    kubectl wait \
      --for=condition=Ready \
      pod/traffic-client \
      -n microservices \
      --timeout=180s

## Test Weighted Canary Routing

Send multiple default requests:

    for i in $(seq 1 50); do
      kubectl exec \
        -n microservices \
        traffic-client \
        -c curl -- \
        curl -fsS http://backend
    done | sort | uniq -c

Version one should receive most requests, while version two should receive a smaller portion.

Weighted routing is probabilistic, so a small sample may not produce an exact 90/10 count.

## Test Premium-User Routing

    kubectl exec \
      -n microservices \
      traffic-client \
      -c curl -- \
      curl -fsS \
      -H "user-type: premium" \
      http://backend

Expected response:

    Backend v2 - New Features!

## Test Designated Test-User Routing

    kubectl exec \
      -n microservices \
      traffic-client \
      -c curl -- \
      curl -fsS \
      -H "test-user: true" \
      http://backend

Expected response:

    Backend v2 - New Features!

## Test URI-Based Routing

Route to backend version one:

    kubectl exec \
      -n microservices \
      traffic-client \
      -c curl -- \
      curl -fsS http://backend/api/v1

Expected response:

    Backend v1

Route to backend version two:

    kubectl exec \
      -n microservices \
      traffic-client \
      -c curl -- \
      curl -fsS http://backend/api/v2

Expected response:

    Backend v2 - New Features!

## Inspect Proxy Configuration

Inspect routes configured on a backend proxy:

    BACKEND_POD="$(
      kubectl get pod \
        -n microservices \
        -l app=backend,version=v1 \
        -o jsonpath='{.items[0].metadata.name}'
    )"

    istioctl proxy-config routes \
      "$BACKEND_POD" \
      -n microservices

Inspect clusters:

    istioctl proxy-config clusters \
      "$BACKEND_POD" \
      -n microservices

Inspect endpoints:

    istioctl proxy-config endpoints \
      "$BACKEND_POD" \
      -n microservices

## Troubleshooting

### Sidecar Is Not Injected

Verify the namespace label:

    kubectl get namespace microservices --show-labels

Restart the deployments after enabling injection:

    kubectl rollout restart deployment \
      -n microservices

Verify containers again:

    kubectl get pods \
      -n microservices \
      -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].name}{"\n"}{end}'

### Gateway Is Not Accessible

Verify the ingress gateway:

    kubectl get pods \
      -n istio-system \
      -l istio=ingressgateway

Inspect the service:

    kubectl get service \
      istio-ingressgateway \
      -n istio-system

Verify Docker access when using Minikube's Docker driver:

    docker info
    minikube ip

### Routing Rules Do Not Work

Run configuration analysis:

    istioctl analyze -n microservices

Inspect the routing resources:

    kubectl describe virtualservice backend-route \
      -n microservices

    kubectl describe destinationrule backend-destination \
      -n microservices

Verify Pod labels:

    kubectl get pods \
      -n microservices \
      --show-labels

### Requests Do Not Reach a Backend Version

Inspect service discovery:

    kubectl get endpointslices \
      -n microservices \
      -l kubernetes.io/service-name=backend

Check the application logs:

    kubectl logs \
      -n microservices \
      -l app=backend \
      -c backend \
      --tail=50

Check the sidecar logs:

    kubectl logs \
      -n microservices \
      -l app=backend \
      -c istio-proxy \
      --tail=50

## Reliability and Delivery Patterns

This implementation demonstrates:

- Canary release delivery
- Header-based A/B routing
- User-segment routing
- URI-based version routing
- Gradual traffic migration
- Application-independent traffic control
- Kubernetes service discovery
- Proxy-managed request routing
- Declarative mesh configuration
- Configuration validation

## Skills Demonstrated

- Istio installation and operation
- Kubernetes namespace management
- Automatic sidecar injection
- Envoy proxy integration
- Istio Gateway configuration
- DestinationRule subset creation
- VirtualService routing
- Weighted traffic splitting
- Header-based routing
- URI-based routing
- Canary deployment patterns
- A/B delivery strategies
- In-mesh traffic testing
- Proxy configuration inspection
- Service-mesh troubleshooting

## Real-World Use Case

This architecture supports controlled delivery of new application versions without changing application code.

Platform and reliability teams can gradually introduce a new release, direct internal testers to it, route premium customers to specialized functionality, and immediately change traffic distribution through declarative configuration.

The same patterns are used for canary releases, A/B testing, progressive delivery, production validation, and controlled rollback strategies.

## Lessons Learned

- Istio manages service traffic independently of application code.
- Sidecar proxies enforce routing policies at runtime.
- DestinationRule subsets connect logical versions to Kubernetes labels.
- VirtualServices control how requests are matched and distributed.
- Header routing supports targeted user experiences and controlled testing.
- Weighted routing enables gradual release adoption.
- URI routing provides deterministic access to specific service versions.
- Traffic percentages are probabilistic rather than exact for small samples.
- Configuration analysis should be completed before production traffic testing.
- Docker permissions affect Minikube commands when using the Docker driver.
