#!/usr/bin/env bash

set -euo pipefail

echo "Deleting the Kind cluster..."
kind delete cluster --name network-security

echo "Cluster cleanup completed."
