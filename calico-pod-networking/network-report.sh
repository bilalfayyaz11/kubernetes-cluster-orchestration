#!/usr/bin/env bash
set -euo pipefail

echo "=== Kubernetes Network Report ==="
echo "Generated: $(date -Is)"

echo
echo "=== Nodes ==="
kubectl get nodes -o wide

echo
echo "=== Pods ==="
kubectl get pods -o wide

echo
echo "=== Services ==="
kubectl get services -o wide

echo
echo "=== EndpointSlices ==="
kubectl get endpointslices

echo
echo "=== Network Policies ==="
kubectl get networkpolicies

echo
echo "=== Calico Components ==="
kubectl get pods -n kube-system -l k8s-app=calico-node -o wide
kubectl get deployment -n kube-system calico-kube-controllers

echo
echo "=== Calico IP Pools ==="
kubectl get ippools.crd.projectcalico.org -o wide

echo
echo "=== Workload Endpoints ==="
kubectl get workloadendpoints.crd.projectcalico.org -A -o wide
