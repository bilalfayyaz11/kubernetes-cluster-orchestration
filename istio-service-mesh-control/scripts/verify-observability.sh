#!/usr/bin/env bash

set -euo pipefail

echo "========================================"
echo " Istio Observability Verification"
echo "========================================"
echo
echo "Generated: $(date --iso-8601=seconds)"
echo

echo "Add-on Deployments"
echo "------------------"
kubectl get deployments \
  -n istio-system \
  prometheus \
  grafana \
  jaeger \
  kiali
echo

echo "Istio Proxy Synchronization"
echo "---------------------------"
istioctl proxy-status
echo

echo "Prometheus Productpage Requests"
echo "-------------------------------"
curl -fsSG \
  http://127.0.0.1:9090/api/v1/query \
  --data-urlencode \
  'query=sum(istio_requests_total{destination_service_name="productpage"})' \
  | jq -r '
      if .data.result | length == 0 then
        "No productpage request metric found."
      else
        .data.result[]
        | "Requests: \(.value[1])"
      end
    '
echo

echo "Reviews Requests by Version"
echo "---------------------------"
curl -fsSG \
  http://127.0.0.1:9090/api/v1/query \
  --data-urlencode \
  'query=sum by (destination_version) (istio_requests_total{destination_service_name="reviews"})' \
  | jq -r '
      .data.result[]
      | "\(.metric.destination_version // "unknown"): \(.value[1])"
    '
echo

echo "Grafana Health"
echo "--------------"
curl -fsS http://127.0.0.1:3000/api/health | jq .
echo

echo "Jaeger Services"
echo "---------------"
curl -fsS http://127.0.0.1:16686/api/services | jq .
echo

echo "Kiali Health"
echo "------------"
curl -fsS http://127.0.0.1:20001/kiali/healthz
echo
