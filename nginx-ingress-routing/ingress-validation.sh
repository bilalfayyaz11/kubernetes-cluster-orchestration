#!/usr/bin/env bash
set -euo pipefail

MACHINE_IP=$(hostname -I | awk '{print $1}')

HTTP_PORT=$(kubectl get svc ingress-nginx-controller \
  -n ingress-nginx \
  -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')

request_code() {
  local host_header="$1"
  local path="$2"

  if [ -n "$host_header" ]; then
    curl -sS \
      -H "Host: $host_header" \
      -o /dev/null \
      -w '%{http_code}' \
      "http://$MACHINE_IP:$HTTP_PORT$path"
  else
    curl -sS \
      -o /dev/null \
      -w '%{http_code}' \
      "http://$MACHINE_IP:$HTTP_PORT$path"
  fi
}

echo "=== Ingress Validation Report ==="
echo "Generated: $(date -Is)"
echo "Machine IP: $MACHINE_IP"
echo "HTTP NodePort: $HTTP_PORT"

echo
echo "=== Path-Based Routing ==="
echo "/ -> HTTP $(request_code "" "/")"
echo "/app1 -> HTTP $(request_code "" "/app1")"
echo "/app2 -> HTTP $(request_code "" "/app2")"
echo "/app3 -> HTTP $(request_code "" "/app3")"

echo
echo "=== Host-Based Routing ==="
echo "app1.local -> HTTP $(request_code "app1.local" "/")"
echo "app2.local -> HTTP $(request_code "app2.local" "/")"

echo
echo "=== Advanced Routing ==="
echo "/advanced/app1 -> HTTP $(request_code "" "/advanced/app1")"
echo "/advanced/app2 -> HTTP $(request_code "" "/advanced/app2")"

echo
echo "=== Custom Response Headers ==="
curl -sSI "http://$MACHINE_IP:$HTTP_PORT/advanced/app1" \
  | grep -iE 'HTTP/|X-Ingress-Controller|X-Route-Type'

echo
echo "=== Ingress Resources ==="
kubectl get ingress -o wide

echo
echo "=== Backend Services ==="
kubectl get services app1-service app2-service default-backend-service

echo
echo "=== EndpointSlices ==="
kubectl get endpointslices

echo
echo "=== Controller Status ==="
kubectl get pods -n ingress-nginx -o wide
kubectl get svc ingress-nginx-controller -n ingress-nginx

echo
echo "=== Recent Controller Logs ==="
kubectl logs \
  -n ingress-nginx \
  deployment/ingress-nginx-controller \
  --tail=30

echo
echo "=== Validation Complete ==="
