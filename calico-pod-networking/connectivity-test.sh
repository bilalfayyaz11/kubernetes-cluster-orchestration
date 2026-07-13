#!/usr/bin/env bash
set -euo pipefail

POD1_IP=$(kubectl get pod test-pod-1 -o jsonpath='{.status.podIP}')
POD2_IP=$(kubectl get pod test-pod-2 -o jsonpath='{.status.podIP}')
POD3_IP=$(kubectl get pod test-pod-3 -o jsonpath='{.status.podIP}')

echo "=== Pod Addresses ==="
echo "Pod 1: $POD1_IP"
echo "Pod 2: $POD2_IP"
echo "Pod 3: $POD3_IP"

echo
echo "=== Pod-to-Pod Ping ==="
kubectl exec test-pod-2 -- ping -c 2 "$POD1_IP"

echo
echo "=== Allowed HTTP Test ==="
kubectl exec test-pod-2 -- wget -qO- --timeout=5 "http://$POD1_IP" >/dev/null
echo "Pod 2 to Pod 1: allowed"

echo
echo "=== Service DNS Test ==="
kubectl exec test-pod-2 -- nslookup test-service-1.default.svc.cluster.local

echo
echo "=== Network Policy Block Test ==="
if kubectl exec test-pod-3 -- curl \
  --fail \
  --silent \
  --connect-timeout 5 \
  "http://$POD1_IP" >/dev/null; then
  echo "FAILED: Pod 3 was not blocked"
  exit 1
else
  echo "Pod 3 to Pod 1: blocked as expected"
fi

echo
echo "=== Connectivity Verification Passed ==="
