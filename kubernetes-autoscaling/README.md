# Kubernetes Horizontal Pod Autoscaling

## What This Does

This implementation demonstrates automatic workload scaling in Kubernetes using the Horizontal Pod Autoscaler (HPA) driven by live CPU and memory utilization metrics.

The environment provisions a Kubernetes cluster with Metrics Server, deploys a PHP-Apache web application, configures autoscaling policies, generates controlled application traffic, and validates both scale-up and scale-down behavior under changing workloads.

The implementation also demonstrates advanced HPA behavior configuration, stabilization windows, scaling policies, resource monitoring, and automated validation scripts that capture scaling events and cluster state.

This type of autoscaling architecture is widely used by Platform Engineering, DevOps, Cloud Infrastructure, SRE, and Kubernetes Operations teams to automatically adjust application capacity while balancing performance and infrastructure cost.

## Architecture

                    +--------------------------------------+
                    |      Client Load Generator           |
                    |   BusyBox HTTP Request Workers       |
                    +------------------+-------------------+
                                       |
                                       |
                                       v
                  +------------------------------------------+
                  |         Kubernetes Service               |
                  |           php-apache (ClusterIP)         |
                  +------------------+-----------------------+
                                     |
                                     |
                                     v
          +-------------------------------------------------------+
          |          Horizontal Pod Autoscaler (HPA)              |
          |                                                       |
          | CPU Target: 50%                                       |
          | Memory Target: 70%                                    |
          | Advanced Scaling Policies                             |
          | Stabilization Windows                                 |
          +------------------+------------------------------------+
                             |
                             |
                             v
          +-------------------------------------------------------+
          |              php-apache Deployment                    |
          |                                                       |
          | Replica Count Automatically Changes                   |
          | According to CPU & Memory Utilization                 |
          +------------------+------------------------------------+
                             |
                             |
                             v
          +-------------------------------------------------------+
          |                 Metrics Server                        |
          |                                                       |
          | Collects CPU & Memory Usage                           |
          | Exposes Kubernetes Metrics API                        |
          +------------------+------------------------------------+
                             |
                             |
                             v
          +-------------------------------------------------------+
          |                  Minikube Cluster                     |
          | Docker Driver                                          |
          | Kubernetes Control Plane                              |
          +-------------------------------------------------------+

## Prerequisites

- Ubuntu 24.04
- Docker
- Minikube
- kubectl
- conntrack
- socat
- curl
- Git
- 2 CPU cores minimum
- 4 GB RAM minimum
- Internet connectivity

## Setup & Installation

Install dependencies:

sudo apt-get update

sudo apt-get install -y conntrack socat

Install Minikube:

curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

sudo install minikube-linux-amd64 /usr/local/bin/minikube

Start Kubernetes:

minikube start \
  --driver=docker \
  --cpus=2 \
  --memory=4096 \
  --kubernetes-version=v1.35.1

Enable Metrics Server:

minikube addons enable metrics-server

Verify Metrics:

kubectl top nodes

## How to Reproduce

Deploy the application:

kubectl apply -f php-apache-deployment.yaml

Deploy the Horizontal Pod Autoscaler:

kubectl apply -f php-apache-hpa.yaml

Generate application load:

kubectl apply -f load-generator.yaml

Observe scaling:

kubectl get hpa -w

kubectl get deployment php-apache -w

Capture scaling reports:

chmod +x monitor-hpa.sh

./monitor-hpa.sh

Stop traffic:

kubectl delete deployment load-generator

Deploy advanced autoscaling policy:

kubectl delete hpa php-apache-hpa

kubectl apply -f advanced-hpa.yaml

## Autoscaling Workflow

Application Deployment

↓

Metrics Server collects CPU and Memory

↓

HPA evaluates target utilization

↓

Replica count increases

↓

Traffic decreases

↓

HPA stabilization window

↓

Replica count decreases

## Tools Used

- Kubernetes
- Horizontal Pod Autoscaler
- Metrics Server
- Minikube
- Docker
- kubectl
- BusyBox
- PHP-Apache
- Linux
- Bash
- Git

## Key Skills Demonstrated

- Kubernetes cluster administration
- Horizontal Pod Autoscaler
- Metrics Server configuration
- CPU autoscaling
- Memory autoscaling
- Resource requests and limits
- Autoscaling policy tuning
- Scaling stabilization windows
- Kubernetes monitoring
- Workload validation
- Production autoscaling strategies
- Kubernetes troubleshooting

## Real-World Use Case

Cloud-native applications often experience highly variable traffic throughout the day. Rather than permanently allocating enough infrastructure for peak demand, Kubernetes Horizontal Pod Autoscaling continuously monitors application resource utilization and adjusts the number of running replicas automatically. This improves application availability during traffic spikes while reducing infrastructure costs during periods of low demand. Similar autoscaling configurations are commonly deployed in production Kubernetes clusters supporting web applications, APIs, microservices, and internal enterprise platforms.

## Lessons Learned

- HPA depends entirely on Metrics Server.
- CPU requests directly influence utilization calculations.
- Stabilization windows prevent rapid oscillation.
- Controlled load generation produces predictable scaling behavior.
- Docker permissions must be configured before Minikube can create a cluster.
- Monitoring HPA conditions provides better insight than observing replica counts alone.

## Troubleshooting Log

Issue:
Minikube failed to start because Docker socket permissions were denied.

Resolution:
Added the user to the docker group and executed Minikube commands with the correct group permissions.

Issue:
Metrics Server was unavailable immediately after enabling the addon.

Resolution:
Waited until the Metrics API produced valid resource samples before creating the HPA.

Issue:
The original image referenced the retired k8s.gcr.io registry.

Resolution:
Updated the workload to use registry.k8s.io.

Issue:
Background traffic generators launched from kubectl exec could continue running after terminal disconnects.

Resolution:
Implemented a dedicated Kubernetes Deployment for load generation.

Issue:
Host-side pkill commands do not reliably terminate processes running inside Kubernetes pods.

Resolution:
Stopped traffic by deleting the load-generator Deployment.

Issue:
The original monitoring loop could run for several minutes without additional value once scale-down had already begun.

Resolution:
Replaced the long-running observation with bounded validation snapshots.
