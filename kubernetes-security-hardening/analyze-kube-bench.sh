#!/usr/bin/env bash

set -uo pipefail

INPUT_FILE="${1:-reports/kube-bench-results.txt}"

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "ERROR: Kube-bench results file not found: $INPUT_FILE" >&2
    exit 1
fi

count_results() {
    local status="$1"
    grep -c "^\[$status\]" "$INPUT_FILE" 2>/dev/null || true
}

echo "================================================="
echo " Kubernetes CIS Benchmark Analysis"
echo "================================================="
echo
echo "Generated: $(date --iso-8601=seconds)"
echo "Source: $INPUT_FILE"
echo
echo "Result Summary"
echo "--------------"
echo "PASS: $(count_results PASS)"
echo "FAIL: $(count_results FAIL)"
echo "WARN: $(count_results WARN)"
echo "INFO: $(count_results INFO)"
echo

echo "Failed Controls"
echo "---------------"
grep '^\[FAIL\]' "$INPUT_FILE" || echo "No failed controls detected."
echo

echo "Warnings"
echo "--------"
grep '^\[WARN\]' "$INPUT_FILE" || echo "No warnings detected."
echo

echo "Recommended Response"
echo "--------------------"
echo "1. Review each failed control against the active CIS benchmark."
echo "2. Prioritize API server, etcd, kubelet, and certificate findings."
echo "3. Confirm whether each result is applicable to this kubeadm topology."
echo "4. Apply one remediation at a time and rerun the affected benchmark section."
echo "5. Document accepted risks and controls that require manual verification."
