#!/usr/bin/env bash
set -euo pipefail

echo "=== Kubernetes Ingress Configuration Report ==="
echo "Generated: $(date -Is)"

echo
echo "=== Nodes ==="
kubectl get nodes -o wide

echo
echo "=== Application Deployments ==="
kubectl get deployments

echo
echo "=== Application Pods ==="
kubectl get pods -o wide

echo
echo "=== Services ==="
kubectl get services -o wide

echo
echo "=== Ingress Classes ==="
kubectl get ingressclass

echo
echo "=== Ingress Resources ==="
kubectl get ingress -o wide

echo
echo "=== Ingress Rules ==="
kubectl describe ingress path-based-ingress
kubectl describe ingress host-based-ingress
kubectl describe ingress advanced-ingress

echo
echo "=== Ingress Controller ==="
kubectl get deployment ingress-nginx-controller -n ingress-nginx
kubectl get pods -n ingress-nginx -o wide
kubectl get svc ingress-nginx-controller -n ingress-nginx -o wide
