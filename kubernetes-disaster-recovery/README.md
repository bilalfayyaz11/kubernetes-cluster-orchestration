# Kubernetes Disaster Recovery with Velero and MinIO

## What This Does

This implementation builds a Kubernetes disaster recovery environment using Kind, Velero, MinIO, and filesystem-level volume backup components.

The environment provides S3-compatible backup storage, namespace-level resource protection, persistent-volume backup workflows, scheduled recovery points, retention controls, monitoring scripts, and restore validation. It also demonstrates why Kubernetes resource restoration and application data restoration must be tested separately.

The implementation includes a real troubleshooting scenario in which Kubernetes resources restored successfully while persistent application files were absent. This outcome was investigated through Velero backup metadata, PodVolumeBackup resources, PodVolumeRestore resources, node-agent logs, and restored PVC validation.

## Architecture

    +-------------------------------------------------------------+
    |                     Ubuntu Host                             |
    |                                                             |
    |  +---------------------+    +----------------------------+  |
    |  | Velero CLI          |    | MinIO Client               |  |
    |  | Backup Management   |    | Bucket Validation          |  |
    |  | Restore Management  |    | Storage Inspection         |  |
    |  +----------+----------+    +-------------+--------------+  |
    |             |                             |                 |
    +-------------|-----------------------------|-----------------+
                  |                             |
                  v                             v
    +-------------------------------------------------------------+
    |                   Kind Kubernetes Cluster                   |
    |                                                             |
    |  +----------------------+    +----------------------------+ |
    |  | Control-Plane Node   |    | Worker Nodes               | |
    |  |                      |    |                            | |
    |  | API Server           |    | Application Workloads      | |
    |  | Scheduler            |    | Velero Node Agents         | |
    |  | Controller Manager   |    | Persistent Volumes         | |
    |  | etcd                 |    |                            | |
    |  +----------+-----------+    +-------------+--------------+ |
    |             |                              |                |
    |             +------------------------------+                |
    |                            |                                |
    |                            v                                |
    |  +-------------------------------------------------------+ |
    |  | Velero                                                | |
    |  |                                                       | |
    |  | Kubernetes Resource Backup                            | |
    |  | Namespace Restore                                     | |
    |  | Backup Scheduling                                     | |
    |  | Backup Retention                                      | |
    |  | Node-Agent Filesystem Backup                          | |
    |  +--------------------------+----------------------------+ |
    |                             |                              |
    |                             v                              |
    |  +-------------------------------------------------------+ |
    |  | MinIO S3-Compatible Backup Storage                    | |
    |  |                                                       | |
    |  | Bucket: velero-backups                                | |
    |  | Host-Persisted Storage                                | |
    |  | Bucket Versioning                                     | |
    |  +-------------------------------------------------------+ |
    +-------------------------------------------------------------+

## Prerequisites

- Ubuntu 24.04 LTS
- At least 4 CPU cores
- At least 8 GiB of memory
- At least 20 GiB of available disk space
- A user with sudo privileges
- Docker Engine
- kubectl
- Kind
- Velero CLI
- MinIO Client
- Helm
- Git
- curl
- jq
- tree
- Internet access for container images and release downloads

## Setup & Installation

Update the package index and install the required utilities:

sudo apt-get update

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ca-certificates \
  curl \
  git \
  jq \
  tree

Grant the current user access to Docker:

sudo usermod -aG docker "$USER"

newgrp docker

Install Kind:

KIND_VERSION="$(
  curl -fsSL \
    https://api.github.com/repos/kubernetes-sigs/kind/releases/latest \
  | jq -r '.tag_name'
)"

curl -fLo /tmp/kind \
  "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64"

sudo install \
  -o root \
  -g root \
  -m 0755 \
  /tmp/kind \
  /usr/local/bin/kind

rm -f /tmp/kind

Install Velero:

VELERO_VERSION="$(
  curl -fsSL \
    https://api.github.com/repos/vmware-tanzu/velero/releases/latest \
  | jq -r '.tag_name'
)"

curl -fL \
  "https://github.com/vmware-tanzu/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-linux-amd64.tar.gz" \
  -o /tmp/velero.tar.gz

tar -xzf /tmp/velero.tar.gz -C /tmp

sudo install \
  -o root \
  -g root \
  -m 0755 \
  "/tmp/velero-${VELERO_VERSION}-linux-amd64/velero" \
  /usr/local/bin/velero

rm -rf \
  /tmp/velero.tar.gz \
  "/tmp/velero-${VELERO_VERSION}-linux-amd64"

Install the MinIO client:

curl -fL \
  https://dl.min.io/client/mc/release/linux-amd64/mc \
  -o /tmp/mc

sudo install \
  -o root \
  -g root \
  -m 0755 \
  /tmp/mc \
  /usr/local/bin/mc

rm -f /tmp/mc

Verify the toolchain:

docker --version

kubectl version --client

kind version

velero version --client-only

mc --version

## How to Reproduce

Clone the repository:

git clone https://github.com/bilalfayyaz11/kubernetes-cluster-orchestration.git

Enter the disaster recovery implementation:

cd kubernetes-cluster-orchestration/kubernetes-disaster-recovery

Create the Kind cluster:

kind create cluster \
  --name recovery \
  --config kind-config.yaml \
  --wait 300s

Verify the cluster:

kubectl cluster-info

kubectl get nodes -o wide

Prepare the MinIO storage directory:

mkdir -p storage/minio

chmod 700 storage/minio

Deploy MinIO:

kubectl apply -f manifests/minio.yaml

Wait for MinIO:

kubectl rollout status \
  deployment/minio \
  --namespace backup-storage \
  --timeout=300s

Configure the MinIO client:

mc alias set \
  recovery-storage \
  http://127.0.0.1:30000 \
  velero-admin \
  'VeleroBackup-2026-Secure'

Create the Velero bucket:

mc mb \
  --ignore-existing \
  recovery-storage/velero-backups

Enable bucket versioning:

mc version enable \
  recovery-storage/velero-backups

Create the local Velero credentials file:

mkdir -p credentials

cat > credentials/minio-credentials << 'CREDENTIALS'
[default]
aws_access_key_id=velero-admin
aws_secret_access_key=VeleroBackup-2026-Secure
CREDENTIALS

Install Velero with MinIO storage and the node agent:

velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:latest \
  --bucket velero-backups \
  --secret-file credentials/minio-credentials \
  --backup-location-config \
region=minio,s3ForcePathStyle=true,s3Url=http://minio.backup-storage.svc.cluster.local:9000,publicUrl=http://127.0.0.1:30000 \
  --use-node-agent \
  --use-volume-snapshots=false

Wait for Velero:

kubectl rollout status \
  deployment/velero \
  --namespace velero \
  --timeout=300s

kubectl rollout status \
  daemonset/node-agent \
  --namespace velero \
  --timeout=300s

Verify the backup location:

velero backup-location get

Deploy the stateful application:

kubectl apply -f manifests/sample-app.yaml

kubectl rollout status \
  deployment/nginx-demo \
  --namespace recovery-demo \
  --timeout=300s

Create persistent application data:

POD_NAME="$(
  kubectl get pods \
    --namespace recovery-demo \
    --selector app=nginx-demo \
    -o jsonpath='{.items[0].metadata.name}'
)"

kubectl exec \
  --namespace recovery-demo \
  "$POD_NAME" \
  -- sh -c '
    echo "<h1>Velero Recovery Validation</h1>" \
      > /usr/share/nginx/html/index.html

    echo "Persistent recovery payload" \
      > /usr/share/nginx/html/testdata.txt
  '

Create a filesystem-enabled backup:

BACKUP_NAME="filesystem-backup-$(date +%Y%m%d-%H%M%S)"

velero backup create "$BACKUP_NAME" \
  --include-namespaces recovery-demo \
  --default-volumes-to-fs-backup \
  --wait

Verify that a filesystem backup was created:

kubectl get podvolumebackups \
  --namespace velero \
  --selector "velero.io/backup-name=${BACKUP_NAME}"

Review backup details:

velero backup describe "$BACKUP_NAME" --details

velero backup logs "$BACKUP_NAME"

Simulate namespace loss:

kubectl delete namespace recovery-demo

kubectl wait \
  --for=delete \
  namespace/recovery-demo \
  --timeout=300s

Restore the namespace:

RESTORE_NAME="filesystem-restore-$(date +%Y%m%d-%H%M%S)"

velero restore create "$RESTORE_NAME" \
  --from-backup "$BACKUP_NAME" \
  --wait

Verify filesystem restoration:

kubectl get podvolumerestores \
  --namespace velero \
  --selector "velero.io/restore-name=${RESTORE_NAME}"

Wait for the application:

kubectl rollout status \
  deployment/nginx-demo \
  --namespace recovery-demo \
  --timeout=300s

Verify restored files:

RESTORED_POD="$(
  kubectl get pods \
    --namespace recovery-demo \
    --selector app=nginx-demo \
    -o jsonpath='{.items[0].metadata.name}'
)"

kubectl exec \
  --namespace recovery-demo \
  "$RESTORED_POD" \
  -- cat /usr/share/nginx/html/index.html

kubectl exec \
  --namespace recovery-demo \
  "$RESTORED_POD" \
  -- cat /usr/share/nginx/html/testdata.txt

Create the recurring backup schedule:

chmod +x scripts/create-scheduled-backup.sh

./scripts/create-scheduled-backup.sh

Generate the backup validation report:

chmod +x scripts/validate-backups.sh

./scripts/validate-backups.sh \
  | tee reports/backup-validation.txt

Generate the disaster recovery summary:

chmod +x scripts/disaster-recovery-summary.sh

./scripts/disaster-recovery-summary.sh \
  | tee reports/disaster-recovery-summary.txt

## Backup Strategy

- S3-compatible backup storage through MinIO
- Kubernetes resource backup through Velero
- Filesystem-level PersistentVolume backup through the Velero node agent
- Namespace-specific recovery points
- Timestamped manual backups
- Daily scheduled backups
- Thirty-day backup retention
- Bucket versioning
- Backup storage monitoring
- Backup and restore status validation
- Data integrity verification using checksums

## Tools Used

- Kubernetes
- Kind
- Docker
- kubectl
- Velero
- Velero Node Agent
- Velero AWS Plugin
- MinIO
- MinIO Client
- Kubernetes PersistentVolumes
- Kubernetes PersistentVolumeClaims
- Bash
- jq
- YAML
- Git
- Linux

## Key Skills Demonstrated

- Kubernetes disaster recovery architecture
- Velero installation and configuration
- S3-compatible backup storage integration
- MinIO deployment and bucket management
- PersistentVolume backup planning
- Filesystem backup with Velero node agents
- Kubernetes namespace recovery
- Backup and restore validation
- Recovery-point retention management
- Scheduled backup automation
- Backup integrity testing
- Persistent data checksum comparison
- Kubernetes storage troubleshooting
- Backup failure investigation
- Operational monitoring automation
- Platform engineering documentation
- Business continuity planning

## Real-World Use Case

A platform engineering or site reliability team can use this architecture to protect Kubernetes workloads against accidental namespace deletion, failed deployments, configuration loss, storage corruption, and cluster migration risks. Velero stores Kubernetes resources and persistent application data in an external S3-compatible repository, allowing workloads to be rebuilt after an operational incident. Scheduled backups and retention controls provide defined recovery points, while restore validation proves whether the organization can meet its recovery objectives.

## Lessons Learned

- A Velero backup marked as Completed does not automatically prove that PersistentVolume data was captured.
- Installing the Velero node agent enables filesystem backup capability but does not automatically select every pod volume for backup.
- Filesystem backups should be confirmed through completed PodVolumeBackup resources before destructive recovery testing.
- Successful Kubernetes object restoration and successful application data restoration are separate validation requirements.
- Restored PVC objects may bind successfully while still containing no application data.
- Host-side Velero commands cannot directly resolve Kubernetes internal service names without an externally reachable public URL.
- Recovery procedures should compare pre-backup and post-restore checksums rather than relying only on pod readiness.
- Backup deletion utilities should use preview behavior by default and require explicit confirmation before removing recovery points.

## Troubleshooting Log

Issue:
The original Kind version was pinned to an obsolete release.

Resolution:
Installed the current stable Kind release dynamically from the official release API.

Issue:
The original Velero CLI and AWS plugin versions were outdated.

Resolution:
Installed the current Velero CLI and used a compatible AWS object-storage plugin.

Issue:
Docker was installed, but the current user could not access the Docker socket.

Resolution:
Added the user to the Docker group and activated the updated group membership.

Issue:
The MinIO client command conflicted with Ubuntu's Midnight Commander package.

Resolution:
Installed the official MinIO Client binary directly from MinIO.

Issue:
The original Kind configuration exposed only the MinIO API port.

Resolution:
Mapped both the MinIO API and console NodePorts to the Ubuntu host.

Issue:
MinIO was initially deployed with ephemeral emptyDir storage.

Resolution:
Used host-persisted storage mounted into the Kind control-plane node and a retained PersistentVolume.

Issue:
The MinIO pod could not schedule on the selected control-plane node.

Resolution:
Added a toleration for the control-plane NoSchedule taint.

Issue:
The MinIO container could not initially access the mounted storage directory.

Resolution:
Corrected host and node-side directory ownership and permissions.

Issue:
Velero CLI report downloads failed because the Ubuntu host could not resolve the Kubernetes service hostname.

Resolution:
Configured the BackupStorageLocation public URL as http://127.0.0.1:30000 while retaining the internal service URL for in-cluster operations.

Issue:
The first Velero backup restored Kubernetes resources but not persistent application files.

Resolution:
The backup metadata showed File System Backup was disabled. The node agent was running, but no filesystem volume backup had been selected.

Issue:
No PodVolumeBackup resource was created for the first backup.

Resolution:
Updated the backup workflow to use --default-volumes-to-fs-backup and added explicit validation for completed PodVolumeBackup resources.

Issue:
The restore completed and recreated the namespace, Deployment, Service, PVC, and Pod, but the application files were absent.

Resolution:
Confirmed that no PodVolumeRestore resource existed. This demonstrated that Kubernetes object recovery alone does not constitute complete disaster recovery.

Issue:
A failed restored-file check terminated the shell workflow.

Resolution:
Separated restore validation from destructive operations and added explicit phase and resource checks before reading restored files.

Issue:
The original cleanup workflow was described as a dry run but permanently deleted backups.

Resolution:
Created an interactive cleanup utility that requires explicit confirmation before deleting recovery points.
