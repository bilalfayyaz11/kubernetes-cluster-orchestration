# Minikube Workload Orchestration

## What This Does

This implementation provisions and validates application workloads on a local Kubernetes cluster using Minikube.

It deploys an Nginx workload and a lightweight HTTP service using Kubernetes Deployments and NodePort Services. The configuration includes replica management, rolling updates, resource requests and limits, readiness probes, liveness probes, service discovery, and external access.

The Nginx workload is scaled from three to five replicas, while the HTTP workload runs with two replicas. Kubernetes Services distribute traffic across the healthy Pods.

## Architecture

    External Client
          |
          +----------------------------+
          |                            |
          v                            v
    nginx-service                webapp-service
    NodePort 30080               NodePort 30081
          |                            |
          v                            v
    Nginx Deployment             Webapp Deployment
      5 replicas                    2 replicas
          |                            |
          +------------+---------------+
                       |
                       v
              Minikube Kubernetes Node

## Components

### Nginx Deployment

The Nginx Deployment provides:

- Five application replicas after scaling
- Rolling update behavior
- CPU and memory requests
- CPU and memory limits
- HTTP readiness probes
- HTTP liveness probes
- Restricted privilege escalation
- Automatic Pod replacement

### Nginx Service

The Nginx Service exposes the workload through:

    Service type: NodePort
    Service port: 80
    Container port: 80
    NodePort: 30080

### Webapp Deployment

The webapp Deployment provides:

- Two replicas
- A lightweight HTTP response service
- Resource requests and limits
- HTTP readiness and liveness probes
- Non-root execution
- Restricted Linux capabilities

### Webapp Service

The webapp Service exposes the workload through:

    Service type: NodePort
    Service port: 8080
    Container port: 8080
    NodePort: 30081

## Repository Structure

    minikube-workload-orchestration/
    ├── manifests/
    │   ├── nginx-deployment.yaml
    │   └── webapp-deployment.yaml
    └── README.md

## Prerequisites

The following tools are required:

    Docker Engine
    kubectl
    Minikube
    curl
    Git

Verify the tools:

    docker --version
    kubectl version --client
    minikube version

Verify Docker access:

    docker info

## Start the Kubernetes Cluster

Start Minikube with the Docker driver:

    minikube start \
      --driver=docker \
      --cpus=3 \
      --memory=6144mb

Verify the cluster:

    minikube status
    kubectl cluster-info
    kubectl get nodes -o wide
    kubectl get pods -n kube-system

The Minikube node should report:

    Ready

## Validate the Manifests

Move into this directory:

    cd minikube-workload-orchestration

Run client-side validation:

    kubectl apply --dry-run=client \
      -f manifests/nginx-deployment.yaml

    kubectl apply --dry-run=client \
      -f manifests/webapp-deployment.yaml

## Deploy the Workloads

Apply both manifests:

    kubectl apply \
      -f manifests/nginx-deployment.yaml

    kubectl apply \
      -f manifests/webapp-deployment.yaml

Wait for both rollouts:

    kubectl rollout status deployment/nginx \
      --timeout=180s

    kubectl rollout status deployment/webapp \
      --timeout=180s

## Verify Pod Readiness

Wait for Nginx Pods:

    kubectl wait \
      --for=condition=Ready \
      pod \
      -l app=nginx \
      --timeout=180s

Wait for webapp Pods:

    kubectl wait \
      --for=condition=Ready \
      pod \
      -l app=webapp \
      --timeout=180s

Inspect the running workloads:

    kubectl get deployments
    kubectl get pods -o wide
    kubectl get services

## Scale the Nginx Workload

Scale Nginx from three to five replicas:

    kubectl scale deployment nginx --replicas=5

Wait for the scaling operation:

    kubectl rollout status deployment/nginx \
      --timeout=180s

Verify the final replica count:

    kubectl get deployment nginx

Expected state:

    READY   UP-TO-DATE   AVAILABLE
    5/5     5            5

## Test the Nginx Service

Retrieve the Minikube service address:

    NGINX_URL="$(minikube service nginx-service --url)"

Display the address:

    echo "$NGINX_URL"

Test the service:

    curl -fsS "$NGINX_URL"

The response should contain the default Nginx HTML page.

## Test the Webapp Service

Retrieve the service address:

    WEBAPP_URL="$(minikube service webapp-service --url)"

Display the address:

    echo "$WEBAPP_URL"

Test the service:

    curl -fsS "$WEBAPP_URL"

Expected response:

    Hello from Kubernetes

## Verify Service Discovery

Inspect the EndpointSlices:

    kubectl get endpointslices

Inspect the Nginx endpoints:

    kubectl get endpointslices \
      -l kubernetes.io/service-name=nginx-service \
      -o wide

Inspect the webapp endpoints:

    kubectl get endpointslices \
      -l kubernetes.io/service-name=webapp-service \
      -o wide

Each ready Pod should appear as a backend endpoint.

## Verify Cluster Health

Check the node:

    kubectl get nodes -o wide

Check system workloads:

    kubectl get pods -n kube-system

Check application workloads:

    kubectl get pods

Check all resources in the default namespace:

    kubectl get all

The expected application state is:

    nginx     5/5 replicas ready
    webapp    2/2 replicas ready

The expected running Pod count is seven.

## Enable Resource Metrics

Enable the metrics server:

    minikube addons enable metrics-server

Wait for the metrics components to initialize:

    sleep 30

View node resource usage:

    kubectl top nodes

View Pod resource usage:

    kubectl top pods

## View Application Logs

View Nginx logs:

    kubectl logs \
      -l app=nginx \
      --tail=20 \
      --prefix=true

View webapp logs:

    kubectl logs \
      -l app=webapp \
      --tail=20 \
      --prefix=true

## Inspect Deployment History

View the Nginx rollout history:

    kubectl rollout history deployment/nginx

View the webapp rollout history:

    kubectl rollout history deployment/webapp

## Troubleshooting

### Pods Remain Pending

Inspect Pod events:

    kubectl describe pods

Inspect node capacity:

    kubectl describe node minikube

Check resource requests:

    kubectl get pods \
      -o custom-columns=NAME:.metadata.name,CPU:.spec.containers[*].resources.requests.cpu,MEMORY:.spec.containers[*].resources.requests.memory

### Pods Enter CrashLoopBackOff

Check current logs:

    kubectl logs <POD_NAME>

Check logs from the previous container instance:

    kubectl logs <POD_NAME> --previous

Inspect Pod events:

    kubectl describe pod <POD_NAME>

### Nginx Permission Failure

The official Nginx image performs startup initialization under its default container user.

Overly restrictive capability removal can prevent Nginx from preparing writable cache directories and produce errors such as:

    chown("/var/cache/nginx/client_temp", 101) failed

The working configuration keeps privilege escalation disabled without dropping the capabilities required by the image during startup.

### Service Has No Ready Endpoints

Inspect EndpointSlices:

    kubectl get endpointslices \
      -l kubernetes.io/service-name=nginx-service \
      -o yaml

Check the Service selector:

    kubectl describe service nginx-service

Check Pod labels:

    kubectl get pods --show-labels

The Service selector must match the Pod labels.

### Service Is Not Accessible

List Minikube services:

    minikube service list

Retrieve the service address:

    minikube service nginx-service --url

Check NodePort allocation:

    kubectl get service nginx-service

### Docker Permission Denied

Add the current user to the Docker group:

    sudo usermod -aG docker "$USER"

Start a shell with Docker group access:

    newgrp docker

Verify access:

    docker info

## Cleanup

Delete both application configurations:

    kubectl delete \
      -f manifests/nginx-deployment.yaml

    kubectl delete \
      -f manifests/webapp-deployment.yaml

Stop Minikube:

    minikube stop

Delete the cluster:

    minikube delete

## Reliability Features

This implementation includes:

- Declarative Kubernetes Deployments
- Multiple application replicas
- Rolling update configuration
- HTTP readiness probes
- HTTP liveness probes
- CPU requests and limits
- Memory requests and limits
- NodePort Services
- EndpointSlice-based service verification
- Automatic Pod recreation
- Controlled privilege escalation
- Non-root execution where supported

## Skills Demonstrated

- Local Kubernetes provisioning
- Minikube cluster management
- Kubernetes manifest creation
- Deployment lifecycle management
- Pod replication and scaling
- Kubernetes Service configuration
- NodePort exposure
- Readiness and liveness probes
- Resource governance
- Service discovery
- EndpointSlice inspection
- Rollout monitoring
- Container troubleshooting
- Cluster health verification

## Real-World Use Case

This architecture provides a development and validation environment for containerized services before deployment to managed Kubernetes platforms.

The same workload concepts apply to Amazon EKS, Azure Kubernetes Service, Google Kubernetes Engine, and private Kubernetes clusters.

Deployments maintain the desired number of replicas, Services provide stable network access, probes remove unhealthy Pods from traffic, and resource controls protect the cluster from unbounded workload consumption.

## Lessons Learned

- Kubernetes Deployments maintain the desired application state.
- Services provide stable access even when Pod IP addresses change.
- Labels and selectors connect Services to workloads.
- Readiness probes control whether a Pod receives traffic.
- Liveness probes allow Kubernetes to restart unhealthy containers.
- Resource requests influence scheduling decisions.
- Resource limits prevent excessive workload consumption.
- EndpointSlices are the modern mechanism for inspecting Service backends.
- Rollout commands provide safer verification than indefinite watch commands.
- Container security settings must remain compatible with image startup behavior.
- Scaling changes application capacity without modifying individual Pods.
