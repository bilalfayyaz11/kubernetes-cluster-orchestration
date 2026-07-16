#!/usr/bin/env bash

set -uo pipefail

INTERVAL="${INTERVAL:-30}"

while true; do
    clear

    echo "================================================="
    echo " Kubernetes Security Monitoring Dashboard"
    echo "================================================="
    echo "Updated: $(date --iso-8601=seconds)"
    echo "Refresh interval: ${INTERVAL}s"
    echo

    NODE_COUNT="$(
      kubectl get nodes --no-headers 2>/dev/null \
        | awk 'END { print NR + 0 }'
    )"

    NOT_READY_NODES="$(
      kubectl get nodes --no-headers 2>/dev/null \
        | awk '$2 !~ /^Ready/ { count++ } END { print count + 0 }'
    )"

    NON_RUNNING_PODS="$(
      kubectl get pods -A --no-headers 2>/dev/null \
        | awk '$4 != "Running" && $4 != "Completed" { count++ } END { print count + 0 }'
    )"

    PRIVILEGED_CONTAINERS="$(
      kubectl get pods -A -o json 2>/dev/null \
        | jq '
            [
              .items[]
              | (
                  (.spec.initContainers // [])
                  + (.spec.containers // [])
                  + (.spec.ephemeralContainers // [])
                )[]
              | select(.securityContext.privileged == true)
            ]
            | length
          '
    )"

    EXPLICIT_ROOT_CONTAINERS="$(
      kubectl get pods -A -o json 2>/dev/null \
        | jq '
            [
              .items[]
              | . as $pod
              | (
                  (.spec.initContainers // [])
                  + (.spec.containers // [])
                  + (.spec.ephemeralContainers // [])
                )[]
              | select(
                  (.securityContext.runAsUser == 0)
                  or (
                    (.securityContext.runAsUser == null)
                    and ($pod.spec.securityContext.runAsUser == 0)
                  )
                )
            ]
            | length
          '
    )"

    POLICY_COUNT="$(
      kubectl get networkpolicies -A --no-headers 2>/dev/null \
        | awk 'END { print NR + 0 }'
    )"

    QUOTA_COUNT="$(
      kubectl get resourcequotas -A --no-headers 2>/dev/null \
        | awk 'END { print NR + 0 }'
    )"

    echo "Cluster Health"
    echo "--------------"
    printf "%-30s %s\n" "Nodes:" "$NODE_COUNT"
    printf "%-30s %s\n" "Not-ready nodes:" "$NOT_READY_NODES"
    printf "%-30s %s\n" "Non-running pods:" "$NON_RUNNING_PODS"
    echo

    echo "Security Indicators"
    echo "-------------------"
    printf "%-30s %s\n" "Privileged containers:" "$PRIVILEGED_CONTAINERS"
    printf "%-30s %s\n" "Explicit UID 0 containers:" "$EXPLICIT_ROOT_CONTAINERS"
    printf "%-30s %s\n" "NetworkPolicies:" "$POLICY_COUNT"
    printf "%-30s %s\n" "ResourceQuotas:" "$QUOTA_COUNT"
    echo

    echo "Recent Warning Events"
    echo "---------------------"
    kubectl get events -A \
      --field-selector type=Warning \
      --sort-by='.metadata.creationTimestamp' \
      2>/dev/null \
      | tail -8
    echo

    echo "Non-Running Workloads"
    echo "---------------------"
    kubectl get pods -A --no-headers 2>/dev/null \
      | awk '$4 != "Running" && $4 != "Completed" {
          printf "%-22s %-42s %-15s\n", $1, $2, $4
        }'

    echo
    echo "Press Ctrl+C to exit."
    sleep "$INTERVAL"
done
