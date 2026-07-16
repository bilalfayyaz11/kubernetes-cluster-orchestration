#!/usr/bin/env bash

set -euo pipefail

velero schedule create daily-recovery \
    --schedule="0 2 * * *" \
    --include-namespaces recovery-demo \
    --ttl 720h \
    --default-volumes-to-fs-backup

echo
echo "Current schedules"

velero schedule get
