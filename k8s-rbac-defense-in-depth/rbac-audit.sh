#!/bin/bash

echo "=== RBAC Audit Report ==="
echo "Date: $(date)"
echo

echo "=== Cluster Roles ==="
kubectl get clusterroles --no-headers | wc -l
echo "Total ClusterRoles found"
echo

echo "=== Roles by Namespace ==="
for ns in $(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}'); do
    role_count=$(kubectl get roles -n $ns --no-headers 2>/dev/null | wc -l)
    if [ $role_count -gt 0 ]; then
        echo "Namespace: $ns - Roles: $role_count"
    fi
done
echo

echo "=== Service Accounts with Bindings ==="
kubectl get rolebindings,clusterrolebindings -A -o json | jq -r '.items[] | select(.subjects[]?.kind == "ServiceAccount") | "\(.metadata.namespace // "cluster-wide") - \(.metadata.name) - \(.subjects[].name)"' | sort | uniq
echo

echo "=== Custom Roles in rbac-test namespace ==="
kubectl get roles -n rbac-test -o custom-columns=NAME:.metadata.name,CREATED:.metadata.creationTimestamp
echo

echo "=== Role Bindings in rbac-test namespace ==="
kubectl get rolebindings -n rbac-test -o custom-columns=NAME:.metadata.name,ROLE:.roleRef.name,SUBJECT:.subjects[0].name
