#!/usr/bin/env bash

echo "========================================"
echo " Kubernetes Disaster Recovery Summary"
echo "========================================"

echo
echo "Date:"
date

echo
echo "Cluster"

kubectl get nodes

echo
echo "Namespaces"

kubectl get ns

echo
echo "Velero"

velero backup get

echo
velero restore get

echo
velero schedule get

echo
echo "Backup Storage"

velero backup-location get

echo
echo "Persistent Volumes"

kubectl get pv,pvc -A

echo
echo "Finished."
