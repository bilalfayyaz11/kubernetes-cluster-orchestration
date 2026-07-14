#!/usr/bin/env bash

set -euo pipefail

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

test_http() {
  local source_namespace="$1"
  local source_pod="$2"
  local destination="$3"
  local expected_text="$4"
  local description="$5"

  echo "Testing: $description"

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
      "http://$destination")"

  if [ "$response" = "$expected_text" ]; then
    echo "PASS: $response"
  else
    echo "FAIL: Unexpected response: $response"
    exit 1
  fi

  echo
}

test_http \
  "frontend" \
  "$FRONTEND_POD" \
  "backend-service.backend.svc.cluster.local" \
  "Backend API Service" \
  "Frontend to Backend"

test_http \
  "frontend" \
  "$FRONTEND_POD" \
  "database-service.database.svc.cluster.local" \
  "Database Service" \
  "Frontend to Database"

test_http \
  "backend" \
  "$BACKEND_POD" \
  "database-service.database.svc.cluster.local" \
  "Database Service" \
  "Backend to Database"

test_http \
  "database" \
  "$DATABASE_POD" \
  "frontend-service.frontend.svc.cluster.local" \
  "Frontend Application" \
  "Database to Frontend"

echo "Baseline connectivity validation completed successfully."
