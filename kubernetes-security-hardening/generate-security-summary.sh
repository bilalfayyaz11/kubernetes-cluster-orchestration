#!/bin/bash

echo "========================================="
echo " Kubernetes Security Summary"
echo "========================================="
echo

echo "Date:"
date
echo

echo "High/Critical Image Vulnerabilities"
echo "-----------------------------------"

trivy image \
    --severity HIGH,CRITICAL \
    --format table \
    nginx:1.27-alpine

echo
echo "Generated Reports"

ls -lh reports

echo
echo "Completed."
