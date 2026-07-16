#!/usr/bin/env bash

echo "====================================="
echo " Velero Backup Validation"
echo "====================================="

echo
echo "Existing Backups"

velero backup get

echo
echo "Backup Storage"

velero backup-location get

echo
echo "Schedules"

velero schedule get

echo
echo "Recent Restore Operations"

velero restore get
