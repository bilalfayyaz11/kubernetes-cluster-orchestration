#!/usr/bin/env bash

set -u

PASS_COUNT=0
FAIL_COUNT=0

FRONTEND_POD="$(kubectl get pods \
  -n frontend \
  -l app=frontend \
  -o jsonpath='{.items[0].metadata.name}')"

BACKEND_POD="$(kubectl get pods \
  -n backend \
  -l app=backend \
  -o jsonpath='{.items[0].metadata.name}')"

DATABASE_POD="$(kubectl get pods \
  -n database \
  -l app=database \
  -o jsonpath='{.items[0].metadata.name}')"

pass() {
  echo "PASS: $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo "FAIL: $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

test_http_allowed() {
  local namespace="$1"
  local pod="$2"
  local container="$3"
  local destination="$4"
  local expected_response="$5"
  local description="$6"

  echo
  echo "Testing allowed path: $description"

  response="$(kubectl exec \
    -n "$namespace" \
    "$pod" \
    -c "$container" \
    -- curl \
      --fail \
      --silent \
      --show-error \
      --connect-timeout 5 \
      --max-time 10 \
      "http://$destination" 2>/dev/null)"

  result=$?

  if [ "$result" -eq 0 ] && [ "$response" = "$expected_response" ]; then
    pass "$description"
  else
    fail "$description"
    echo "Observed response: ${response:-no response}"
  fi
}

test_http_blocked() {
  local namespace="$1"
  local pod="$2"
  local container="$3"
  local destination="$4"
  local description="$5"

  echo
  echo "Testing blocked path: $description"

  if kubectl exec \
    -n "$namespace" \
    "$pod" \
    -c "$container" \
    -- curl \
      --fail \
      --silent \
      --show-error \
      --connect-timeout 3 \
      --max-time 7 \
      "http://$destination" >/dev/null 2>&1; then

    fail "$description unexpectedly succeeded"
  else
    pass "$description correctly blocked"
  fi
}

echo "===== NETWORK POLICY VALIDATION ====="

test_http_allowed \
  "frontend" \
  "$FRONTEND_POD" \
  "network-client" \
  "backend-service.backend.svc.cluster.local" \
  "Backend API Service" \
  "Frontend to Backend"

test_http_allowed \
  "backend" \
  "$BACKEND_POD" \
  "network-client" \
  "database-service.database.svc.cluster.local" \
  "Database Service" \
  "Backend to Database"

test_http_allowed \
  "diagnostics" \
  "network-debug" \
  "network-tools" \
  "backend-service.backend.svc.cluster.local" \
  "Backend API Service" \
  "Diagnostics to Backend"

test_http_blocked \
  "frontend" \
  "$FRONTEND_POD" \
  "network-client" \
  "database-service.database.svc.cluster.local" \
  "Frontend to Database"

test_http_blocked \
  "database" \
  "$DATABASE_POD" \
  "network-client" \
  "backend-service.backend.svc.cluster.local" \
  "Database to Backend"

test_http_blocked \
  "database" \
  "$DATABASE_POD" \
  "network-client" \
  "frontend-service.frontend.svc.cluster.local" \
  "Database to Frontend"

test_http_blocked \
  "diagnostics" \
  "network-debug" \
  "network-tools" \
  "database-service.database.svc.cluster.local" \
  "Diagnostics to Database"

echo
echo "===== VALIDATION SUMMARY ====="
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "RESULT: NETWORK POLICY VALIDATION FAILED"
  exit 1
fi

echo "RESULT: ALL NETWORK POLICY TESTS PASSED"
