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

record_pass() {
  echo "PASS: $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

record_fail() {
  echo "FAIL: $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

test_allowed() {
  local source_namespace="$1"
  local source_pod="$2"
  local destination="$3"
  local expected_response="$4"
  local description="$5"

  echo
  echo "Testing allowed path: $description"

  response="$(kubectl exec \
    -n "$source_namespace" \
    "$source_pod" \
    -c network-client \
    -- curl \
      --fail \
      --silent \
      --show-error \
      --connect-timeout 5 \
      --max-time 10 \
      "http://$destination" 2>/dev/null)"

  result=$?

  if [ "$result" -eq 0 ] && [ "$response" = "$expected_response" ]; then
    record_pass "$description"
  else
    record_fail "$description"
    echo "Observed response: ${response:-no response}"
  fi
}

test_blocked() {
  local source_namespace="$1"
  local source_pod="$2"
  local destination="$3"
  local description="$4"

  echo
  echo "Testing blocked path: $description"

  if kubectl exec \
    -n "$source_namespace" \
    "$source_pod" \
    -c network-client \
    -- curl \
      --fail \
      --silent \
      --show-error \
      --connect-timeout 3 \
      --max-time 7 \
      "http://$destination" >/dev/null 2>&1; then

    record_fail "$description unexpectedly succeeded"
  else
    record_pass "$description correctly blocked"
  fi
}

echo "===== KUBERNETES NETWORK POLICY VALIDATION ====="

test_allowed \
  "frontend" \
  "$FRONTEND_POD" \
  "backend-service.backend.svc.cluster.local" \
  "Backend API Service" \
  "Frontend to Backend"

test_allowed \
  "backend" \
  "$BACKEND_POD" \
  "database-service.database.svc.cluster.local" \
  "Database Service" \
  "Backend to Database"

test_blocked \
  "frontend" \
  "$FRONTEND_POD" \
  "database-service.database.svc.cluster.local" \
  "Frontend to Database"

test_blocked \
  "database" \
  "$DATABASE_POD" \
  "backend-service.backend.svc.cluster.local" \
  "Database to Backend"

test_blocked \
  "database" \
  "$DATABASE_POD" \
  "frontend-service.frontend.svc.cluster.local" \
  "Database to Frontend"

echo
echo "===== VALIDATION SUMMARY ====="
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "RESULT: NETWORK POLICY VALIDATION FAILED"
  exit 1
fi

echo "RESULT: ALL NETWORK POLICY TESTS PASSED"
