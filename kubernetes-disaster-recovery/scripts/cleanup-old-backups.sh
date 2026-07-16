#!/usr/bin/env bash

set -euo pipefail

echo "Existing backups"

velero backup get

echo
read -rp "Delete completed backups? (yes/no): " ANSWER

if [[ "$ANSWER" != "yes" ]]; then
    echo
    echo "Cleanup cancelled."
    exit 0
fi

for backup in $(velero backup get -o json | jq -r '.items[].metadata.name')
do
    echo "Deleting $backup"
    velero backup delete "$backup" --confirm
done

echo
echo "Cleanup completed."
