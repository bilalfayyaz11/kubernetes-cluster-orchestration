#!/usr/bin/env bash
set -euo pipefail

echo "=== HPA Monitoring Snapshot ==="
echo "Generated: $(date -Is)"

echo
echo "=== HPA Status ==="
kubectl get hpa php-apache-hpa

echo
echo "=== HPA Details ==="
kubectl describe hpa php-apache-hpa

echo
echo "=== Deployment Status ==="
kubectl get deployment php-apache

echo
echo "=== Application Pods ==="
kubectl get pods -l app=php-apache -o wide

echo
echo "=== Resource Usage ==="
kubectl top pods -l app=php-apache

echo
echo "=== Scaling Events ==="
kubectl get events \
  --sort-by=.metadata.creationTimestamp \
  | grep -Ei 'horizontal|scaled|rescale' \
  | tail -n 30 || true

echo
echo "=== Current HPA Configuration ==="
kubectl get hpa php-apache-hpa -o yaml
