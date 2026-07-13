# Kubernetes Observability Stack with Prometheus and Grafana

## What This Does

This implementation delivers a complete Kubernetes monitoring and alerting pipeline on a single-node k3s cluster — from bare-metal Linux to validated, firing alerts.

The stack uses the kube-prometheus-stack Helm chart to deploy Prometheus for metrics collection, Grafana for visualization, Alertmanager for routing, node-exporter for host-level metrics, and kube-state-metrics for Kubernetes object state. A custom ServiceMonitor wires Prometheus to scrape a sample application, a hand-built Grafana dashboard surfaces cluster CPU, memory, and pod-count metrics, and PrometheusRule CRDs define alerting rules that are validated end-to-end by deploying a deliberately failing pod and confirming the KubernetesPodCrashLooping alert transitions to pending or firing.

This directly mirrors what Platform Engineering and SRE teams build to achieve full observability across production Kubernetes clusters.

## Architecture

    +----------------------------------+
    |        Bare Metal Ubuntu         |
    |                                  |
    |  +----------------------------+  |
    |  |     k3s Single Node        |  |
    |  |                            |  |
    |  |  +----------------------+  |  |
    |  |  | sample-metrics-app   |  |  |
    |  |  | (node-exporter x2)   |  |  |
    |  |  +----------+-----------+  |  |
    |  |             |              |  |
    |  |  +----------v-----------+  |  |
    |  |  | ServiceMonitor       |  |  |
    |  |  | (auto-discovery)     |  |  |
    |  |  +----------+-----------+  |  |
    |  |             |              |  |
    |  |  +----------v-----------+  |  |
    |  |  | Prometheus           |  |  |
    |  |  | - cluster metrics    |  |  |
    |  |  | - custom scrape      |  |  |
    |  |  | - alert evaluation   |  |  |
    |  |  +-----+----------+----+  |  |
    |  |        |          |       |  |
    |  |  +-----v----+ +--v------+  |  |
    |  |  | Grafana  | | Alert-  |  |  |
    |  |  | Dash-    | | manager |  |  |
    |  |  | boards   | |         |  |  |
    |  |  +----------+ +---------+  |  |
    |  |                            |  |
    |  |  +----------------------+  |  |
    |  |  | node-exporter        |  |  |
    |  |  | kube-state-metrics   |  |  |
    |  |  +----------------------+  |  |
    |  +----------------------------+  |
    +----------------------------------+

## Prerequisites

- Ubuntu 24.04 (Noble Numbat) x86_64
- k3s lightweight Kubernetes distribution
- kubectl CLI
- Helm v4+
- curl and jq
- Minimum 4GB RAM, 2 CPU cores

## Setup & Installation

sudo apt update && sudo apt install -y curl wget apt-transport-https ca-certificates gnupg lsb-release jq

curl -sfL https://get.k3s.io | sh -

mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

kubectl create namespace monitoring

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values prometheus-values.yaml \
  --wait --timeout 10m

## How to Reproduce

Deploy the monitoring stack:

kubectl apply -f prometheus-values.yaml  # reference only — values consumed by helm install above

Deploy the sample metrics application with ServiceMonitor:

kubectl apply -f sample-app.yaml
kubectl rollout status deployment/sample-metrics-app -n default --timeout=120s

Import the custom dashboard into Grafana:

GRAFANA_PASS=$(kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
curl -s -X POST \
  -H "Content-Type: application/json" \
  -u "admin:$GRAFANA_PASS" \
  "http://localhost:3000/api/dashboards/db" \
  -d @kubernetes-dashboard.json | jq '{status: .status, url: .url}'

Deploy alerting rules:

kubectl apply -f kubernetes-alerts.yaml

Validate alerting with a failing pod:

kubectl apply -f failing-pod.yaml
sleep 180
curl -s http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | {alertname: .labels.alertname, state: .state, pod: .labels.pod}'

Access dashboards:

kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 &
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &

## Tools Used

- k3s — lightweight single-node Kubernetes
- Helm v4 — package manager for Kubernetes charts
- kube-prometheus-stack — Prometheus, Grafana, Alertmanager, node-exporter, kube-state-metrics
- Prometheus Operator — CRDs for ServiceMonitor, PrometheusRule
- Grafana — metrics visualization and dashboarding
- node-exporter — host-level hardware and OS metrics
- kube-state-metrics — Kubernetes object state metrics
- Python — not used; pure Kubernetes-native stack
- jq — JSON parsing for API validation

## Key Skills Demonstrated

- Kubernetes cluster provisioning from bare metal using k3s
- Helm chart deployment with custom values overrides
- Prometheus scrape configuration via additionalScrapeConfigs
- ServiceMonitor CRD for dynamic service discovery and metric collection
- Custom Grafana dashboard creation and programmatic import via API
- PrometheusRule CRD for declarative alerting rule management
- End-to-end alert validation with engineered failure conditions
- Port-forward based local access to cluster services
- kubectl rollout status for deployment readiness verification

## Real-World Use Case

In any organization running Kubernetes in production — whether on EKS, GKE, AKS, or self-managed — the first operational requirement after cluster deployment is observability. Without metrics collection, dashboards, and alerting, teams have zero visibility into node resource saturation, pod crash loops, or degraded workloads. This stack is the exact pattern used by Platform Engineering teams to bootstrap monitoring on new clusters, and by SRE teams to define SLI/SLO-based alerting that routes to PagerDuty, Opsgenie, or Slack via Alertmanager integrations.

## Lessons Learned

- Helm install of kube-prometheus-stack can take 3–8 minutes on constrained single-node clusters — the --wait --timeout 10m flags are essential to prevent silent partial installs.
- The Grafana dashboard import API requires "overwrite": true at the top level of the JSON payload — without it, re-importing fails with a conflict error.
- The newgrp docker command breaks scripted execution by spawning a subshell — it must be avoided in non-interactive contexts.
- Alert evaluation depends on two time windows: the PrometheusRule "for" duration (2m in this case) plus the scrape interval cycles needed to accumulate enough data points for the rate() function to produce a non-zero value.
- A deliberately failing pod with "exit 1" and restartPolicy: Always reliably triggers CrashLoopBackOff within 60 seconds, making it a clean validation target for alerting pipelines.

## Troubleshooting Log

Issue:
Lab instructed to run newgrp docker mid-script.
Resolution:
Skipped entirely — k3s uses containerd, not Docker. newgrp spawns a subshell that breaks all subsequent commands in the same execution block.

Issue:
kubectl download URL hardcoded to amd64 architecture.
Resolution:
Skipped — kubectl v1.36.2 was pre-installed. For portability, the URL should use $(uname -m) with a mapping to either amd64 or arm64.

Issue:
Docker GPG keyring path docker-archive-keyring.gpg used in lab.
Resolution:
Skipped — Docker was pre-installed. The modern path is docker.gpg per current Docker documentation.

Issue:
Grafana dashboard JSON missing "overwrite": true field.
Resolution:
Added "overwrite": true at the top level of the JSON payload to prevent API conflict errors on re-import.

Issue:
Lab used kubectl version --client --short which is removed in kubectl v1.27+.
Resolution:
Used kubectl version --client as fallback in the dependency check block.
