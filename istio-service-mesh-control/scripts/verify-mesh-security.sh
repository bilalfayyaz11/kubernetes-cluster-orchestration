#!/usr/bin/env bash

set -euo pipefail

echo "========================================"
echo " Istio Mesh Security Verification"
echo "========================================"
echo
echo "Generated: $(date --iso-8601=seconds)"
echo

echo "Peer Authentication"
echo "-------------------"
kubectl get peerauthentication \
  -A
echo

echo "Authorization Policies"
echo "----------------------"
kubectl get authorizationpolicy \
  -A
echo

echo "Proxy Synchronization"
echo "---------------------"
istioctl proxy-status
echo

echo "Configuration Analysis"
echo "----------------------"
istioctl analyze
echo

echo "Ingress Productpage Request"
echo "---------------------------"
curl -sS \
  -o /dev/null \
  -w 'HTTP %{http_code}\n' \
  http://127.0.0.1/productpage
echo

echo "Ratings Resilience Policy"
echo "-------------------------"
kubectl get destinationrule ratings \
  -o json \
  | jq '{
      host: .spec.host,
      connectionPool: .spec.trafficPolicy.connectionPool,
      outlierDetection: .spec.trafficPolicy.outlierDetection
    }'
