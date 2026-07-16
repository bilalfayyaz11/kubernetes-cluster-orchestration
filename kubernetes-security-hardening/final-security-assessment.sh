#!/usr/bin/env bash

set -uo pipefail

REPORT_DIR="${REPORT_DIR:-reports}"
mkdir -p "$REPORT_DIR"

echo "================================================="
echo " Final Kubernetes Security Assessment"
echo "================================================="
echo
echo "Assessment date: $(date --iso-8601=seconds)"
echo "Cluster context: $(kubectl config current-context 2>/dev/null || echo unavailable)"
echo

echo "Pod Security Standards"
echo "----------------------"
kubectl get namespaces \
  -o custom-columns='NAME:.metadata.name,ENFORCE:.metadata.labels.pod-security\.kubernetes\.io/enforce,AUDIT:.metadata.labels.pod-security\.kubernetes\.io/audit,WARN:.metadata.labels.pod-security\.kubernetes\.io/warn'
echo

echo "Node Status"
echo "-----------"
kubectl get nodes -o wide
echo

echo "Workload Status"
echo "---------------"
kubectl get pods -A -o wide
echo

echo "Privileged Containers"
echo "---------------------"
PRIVILEGED_OUTPUT="$(
  kubectl get pods -A -o json \
    | jq -r '
        .items[]
        | . as $pod
        | (
            (.spec.initContainers // [])
            + (.spec.containers // [])
            + (.spec.ephemeralContainers // [])
          )[]
        | select(.securityContext.privileged == true)
        | "\($pod.metadata.namespace)/\($pod.metadata.name)\t\(.name)"
      '
)"

if [[ -n "$PRIVILEGED_OUTPUT" ]]; then
    printf '%s\n' "$PRIVILEGED_OUTPUT"
else
    echo "No privileged containers detected."
fi
echo

echo "Explicit Root Containers"
echo "------------------------"
ROOT_OUTPUT="$(
  kubectl get pods -A -o json \
    | jq -r '
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
        | "\($pod.metadata.namespace)/\($pod.metadata.name)\t\(.name)"
      '
)"

if [[ -n "$ROOT_OUTPUT" ]]; then
    printf '%s\n' "$ROOT_OUTPUT"
else
    echo "No containers explicitly configured with UID 0."
fi
echo

echo "Containers Allowing Privilege Escalation"
echo "----------------------------------------"
ESCALATION_OUTPUT="$(
  kubectl get pods -A -o json \
    | jq -r '
        .items[]
        | . as $pod
        | (
            (.spec.initContainers // [])
            + (.spec.containers // [])
            + (.spec.ephemeralContainers // [])
          )[]
        | select(.securityContext.allowPrivilegeEscalation != false)
        | "\($pod.metadata.namespace)/\($pod.metadata.name)\t\(.name)"
      '
)"

if [[ -n "$ESCALATION_OUTPUT" ]]; then
    printf '%s\n' "$ESCALATION_OUTPUT"
else
    echo "All inspected containers explicitly disable privilege escalation."
fi
echo

echo "Seccomp Configuration"
echo "---------------------"
kubectl get pods -A -o json \
  | jq -r '
      .items[]
      | [
          .metadata.namespace,
          .metadata.name,
          (.spec.securityContext.seccompProfile.type // "not-set")
        ]
      | @tsv
    ' \
  | column -t
echo

echo "Network Policies"
echo "----------------"
kubectl get networkpolicies -A
echo

echo "Resource Quotas"
echo "---------------"
kubectl get resourcequotas -A
echo

echo "Limit Ranges"
echo "------------"
kubectl get limitranges -A
echo

echo "RBAC Object Counts"
echo "------------------"
printf "ClusterRoles: "
kubectl get clusterroles --no-headers 2>/dev/null | wc -l

printf "ClusterRoleBindings: "
kubectl get clusterrolebindings --no-headers 2>/dev/null | wc -l

printf "Namespaced Roles: "
kubectl get roles -A --no-headers 2>/dev/null | wc -l

printf "Namespaced RoleBindings: "
kubectl get rolebindings -A --no-headers 2>/dev/null | wc -l
echo

echo "Recent Warning Events"
echo "---------------------"
kubectl get events -A \
  --field-selector type=Warning \
  --sort-by='.metadata.creationTimestamp' \
  | tail -20
echo

echo "Security Report Artifacts"
echo "-------------------------"
find "$REPORT_DIR" \
  -maxdepth 1 \
  -type f \
  -printf '%f\t%k KB\n' \
  | sort
echo

echo "Recommended Actions"
echo "-------------------"
echo "1. Remove privileged workloads that are not explicitly required."
echo "2. Ensure application containers run as non-root users."
echo "3. Require RuntimeDefault or approved Localhost seccomp profiles."
echo "4. Apply default-deny NetworkPolicies to application namespaces."
echo "5. Review HIGH and CRITICAL image vulnerabilities before deployment."
echo "6. Investigate failed CIS controls and document accepted risks."
echo "7. Apply resource requests, limits, quotas, and LimitRanges consistently."
echo "8. Minimize RBAC permissions and periodically review bindings."
