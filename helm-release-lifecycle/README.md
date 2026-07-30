# Helm Release Lifecycle

## What This Does

This implementation provides a reusable Helm chart for deploying and managing an Nginx-based web application on Kubernetes.

The chart generates a Deployment, Service, ServiceAccount, and ConfigMap. Application content and deployment behavior are controlled through Helm values, allowing the same chart to support different environments without modifying the Kubernetes templates.

The implementation demonstrates chart authoring, template rendering, JSON schema validation, release installation, runtime configuration overrides, scaling, upgrades, rollback operations, and chart packaging.

## Architecture

    Helm Chart
        |
        | renders Kubernetes resources
        v
    Helm Release
        |
        +-----------------------+
        |                       |
        v                       v
    ConfigMap              ServiceAccount
        |
        v
    Deployment
        |
        +-----------------------+
        |          |            |
        v          v            v
      Pod 1      Pod 2        Pod 3
        |
        v
    ClusterIP Service
        |
        v
    Port Forward / Internal Client

## Release Lifecycle

    Revision 1
        Initial deployment failed because the Nginx image could not
        initialize its writable cache directories under an incompatible
        container capability restriction.

    Revision 2
        Security settings were corrected and the release successfully
        deployed with three replicas.

    Revision 3
        The release was upgraded to four replicas with a runtime message
        override.

    Revision 4
        The release was rolled back to revision 2, restoring three replicas.

## Capabilities

- Reusable Kubernetes application packaging
- Configurable replica counts
- Configurable container images
- ConfigMap-generated web content
- Environment-specific values
- Runtime value overrides
- JSON schema validation
- Health probes
- Resource requests and limits
- Rolling updates
- Release history
- Upgrade and rollback operations
- Packaged chart distribution

## Repository Structure

    helm-release-lifecycle/
    ├── chart/
    │   ├── Chart.yaml
    │   ├── values.yaml
    │   ├── values.schema.json
    │   ├── custom-values.yaml
    │   └── templates/
    │       ├── _helpers.tpl
    │       ├── configmap.yaml
    │       ├── deployment.yaml
    │       ├── service.yaml
    │       └── serviceaccount.yaml
    ├── packages/
    │   └── web-delivery-0.1.0.tgz
    └── README.md

## Prerequisites

The following tools are required:

    Docker Engine
    Kubernetes cluster
    kubectl
    Helm
    curl

Verify the tools:

    docker --version
    kubectl version --client
    helm version

Verify cluster connectivity:

    kubectl cluster-info
    kubectl get nodes

## Chart Metadata

The chart is defined as a Helm application chart:

    apiVersion: v2
    name: web-delivery
    type: application
    version: 0.1.0
    appVersion: "1.29"

The chart also declares compatibility with Kubernetes version 1.30 or later.

## Validate the Chart

Move into the chart directory:

    cd helm-release-lifecycle/chart

Run Helm linting:

    helm lint .

Render the Kubernetes resources:

    helm template web-delivery . \
      --namespace web-platform \
      --values custom-values.yaml

Render the output into a file:

    helm template web-delivery . \
      --namespace web-platform \
      --values custom-values.yaml \
      > /tmp/web-delivery-rendered.yaml

Validate the generated Kubernetes resources:

    kubectl apply \
      --dry-run=client \
      --validate=false \
      -f /tmp/web-delivery-rendered.yaml

## Values Schema Validation

The `values.schema.json` file validates important configuration before Helm renders or deploys the chart.

The schema validates:

- Replica count boundaries
- Image repository and tag values
- Image pull policy
- Service type
- Service ports
- Application environment
- Required application content
- Revision history limits

An invalid value can be tested with:

    helm template invalid-release . \
      --set replicaCount=0

The chart should reject a replica count below the allowed minimum.

## Create the Namespace

    kubectl create namespace web-platform \
      --dry-run=client \
      -o yaml |
      kubectl apply -f -

## Install the Release

From the repository root:

    helm upgrade --install web-delivery-release \
      ./helm-release-lifecycle/chart \
      --namespace web-platform \
      --values ./helm-release-lifecycle/chart/custom-values.yaml \
      --wait \
      --timeout 5m

Verify the release:

    helm status web-delivery-release \
      --namespace web-platform

List releases:

    helm list \
      --namespace web-platform

## Verify Kubernetes Resources

Check the Deployment:

    kubectl get deployment \
      --namespace web-platform

Check the Pods:

    kubectl get pods \
      --namespace web-platform \
      -l app.kubernetes.io/name=web-delivery \
      -o wide

Check the Service:

    kubectl get service \
      --namespace web-platform \
      -l app.kubernetes.io/name=web-delivery

Check the ConfigMap:

    kubectl get configmap \
      --namespace web-platform \
      -l app.kubernetes.io/name=web-delivery

Expected state:

    Deployment: 3/3 ready
    Pods: 3 running
    Service: ClusterIP
    Release status: deployed

## Access the Application

Start a port forward:

    kubectl port-forward \
      --namespace web-platform \
      service/web-delivery-release \
      8080:80

Test from another terminal:

    curl http://127.0.0.1:8080

The response contains:

- Application heading
- Environment name
- Chart version
- Application version
- Helm release name

## Inspect Release Values

View user-supplied values:

    helm get values web-delivery-release \
      --namespace web-platform

View all computed values:

    helm get values web-delivery-release \
      --namespace web-platform \
      --all

View rendered manifests:

    helm get manifest web-delivery-release \
      --namespace web-platform

View all release information:

    helm get all web-delivery-release \
      --namespace web-platform

## Upgrade the Release

Upgrade the release to four replicas:

    helm upgrade web-delivery-release \
      ./helm-release-lifecycle/chart \
      --namespace web-platform \
      --values ./helm-release-lifecycle/chart/custom-values.yaml \
      --set replicaCount=4 \
      --set application.message="This release was upgraded using Helm runtime overrides." \
      --wait \
      --timeout 5m

Verify the upgrade:

    kubectl get deployment,pods \
      --namespace web-platform

Expected state:

    Deployment: 4/4 ready

## View Release History

    helm history web-delivery-release \
      --namespace web-platform

The history should include the installation, upgrade, and rollback revisions.

## Roll Back the Release

Roll back to revision 2:

    helm rollback web-delivery-release 2 \
      --namespace web-platform \
      --wait \
      --timeout 5m

Verify the rollback:

    kubectl get deployment,pods \
      --namespace web-platform

Expected state:

    Deployment: 3/3 ready

View the updated history:

    helm history web-delivery-release \
      --namespace web-platform

The rollback creates a new release revision rather than deleting existing history.

## Environment-Specific Configuration

The included `custom-values.yaml` demonstrates an environment-specific configuration.

It changes:

- Replica count
- Application title
- Application heading
- Application message
- Environment label
- Pod labels
- Service configuration

Deploy using the custom values:

    helm upgrade --install web-delivery-release \
      ./helm-release-lifecycle/chart \
      --namespace web-platform \
      --values ./helm-release-lifecycle/chart/custom-values.yaml

## Runtime Overrides

Helm values can also be changed directly from the command line:

    helm upgrade web-delivery-release \
      ./helm-release-lifecycle/chart \
      --namespace web-platform \
      --reuse-values \
      --set replicaCount=4

Multiple values can be overridden:

    helm upgrade web-delivery-release \
      ./helm-release-lifecycle/chart \
      --namespace web-platform \
      --reuse-values \
      --set replicaCount=4 \
      --set application.environment=staging \
      --set application.message="Staging release"

## ConfigMap Rollout Automation

The Deployment template includes a checksum annotation generated from the ConfigMap template.

When ConfigMap content changes, Helm produces a different checksum. Kubernetes detects the changed Pod template and performs a rolling update automatically.

This prevents Pods from continuing to serve outdated mounted content after a configuration change.

## Package the Chart

Create a distributable chart archive:

    mkdir -p helm-release-lifecycle/packages

    helm package \
      ./helm-release-lifecycle/chart \
      --destination ./helm-release-lifecycle/packages

Expected package:

    web-delivery-0.1.0.tgz

Inspect the packaged chart:

    helm show chart \
      ./helm-release-lifecycle/packages/web-delivery-0.1.0.tgz

Inspect packaged default values:

    helm show values \
      ./helm-release-lifecycle/packages/web-delivery-0.1.0.tgz

## Install from the Packaged Chart

Install the packaged chart under a separate release name:

    helm upgrade --install packaged-web-release \
      ./helm-release-lifecycle/packages/web-delivery-0.1.0.tgz \
      --namespace web-platform \
      --set replicaCount=1 \
      --wait \
      --timeout 5m

Verify it:

    helm status packaged-web-release \
      --namespace web-platform

Remove the additional release:

    helm uninstall packaged-web-release \
      --namespace web-platform

## Troubleshooting

### Release Remains Pending

Check Helm status:

    helm status web-delivery-release \
      --namespace web-platform

Check Kubernetes resources:

    kubectl get deployment,pods \
      --namespace web-platform

Inspect events:

    kubectl get events \
      --namespace web-platform \
      --sort-by='.lastTimestamp'

### Pods Enter CrashLoopBackOff

Inspect current logs:

    kubectl logs \
      --namespace web-platform \
      -l app.kubernetes.io/name=web-delivery \
      --all-containers=true \
      --prefix=true \
      --tail=100

Inspect previous container logs:

    POD_NAME="$(
      kubectl get pods \
        --namespace web-platform \
        -l app.kubernetes.io/name=web-delivery \
        -o jsonpath='{.items[0].metadata.name}'
    )"

    kubectl logs \
      "$POD_NAME" \
      --namespace web-platform \
      --previous

### Nginx Cache Permission Failure

The official Nginx image initializes writable cache directories during startup.

An overly restrictive container capability configuration can produce:

    chown("/var/cache/nginx/client_temp", 101) failed
    Operation not permitted

The working chart keeps privilege escalation disabled without removing the capabilities required during Nginx initialization.

### Template Rendering Failure

Run detailed linting:

    helm lint \
      ./helm-release-lifecycle/chart \
      --debug

Render the templates:

    helm template web-delivery \
      ./helm-release-lifecycle/chart \
      --namespace web-platform \
      --values ./helm-release-lifecycle/chart/custom-values.yaml \
      --debug

### Upgrade Failure

Use rollback protection during an upgrade:

    helm upgrade web-delivery-release \
      ./helm-release-lifecycle/chart \
      --namespace web-platform \
      --values ./helm-release-lifecycle/chart/custom-values.yaml \
      --rollback-on-failure \
      --wait \
      --timeout 5m

Inspect release history:

    helm history web-delivery-release \
      --namespace web-platform

### Service Is Not Accessible

Verify the Service:

    kubectl get service web-delivery-release \
      --namespace web-platform

Verify Service endpoints:

    kubectl get endpointslices \
      --namespace web-platform \
      -l kubernetes.io/service-name=web-delivery-release

Restart the port forward:

    kubectl port-forward \
      --namespace web-platform \
      service/web-delivery-release \
      8080:80

## Security and Reliability Features

This chart includes:

- Service-account token automount disabled
- Runtime default seccomp profile
- Privilege escalation disabled
- CPU requests and limits
- Memory requests and limits
- Liveness probes
- Readiness probes
- Rolling deployment strategy
- Limited revision history
- ConfigMap checksum rollouts
- Pinned container image tag
- Values schema validation

## Skills Demonstrated

- Helm chart architecture
- Go template syntax
- Helper template creation
- Helm values management
- JSON schema validation
- Kubernetes resource generation
- ConfigMap volume mounting
- Health probe configuration
- Resource governance
- Release installation
- Release upgrades
- Runtime value overrides
- Rollback operations
- Release history inspection
- Chart packaging
- Failed-release troubleshooting

## Real-World Use Case

Helm charts provide reusable application delivery definitions across development, staging, and production environments.

Platform teams can maintain one chart while environment-specific values control replica counts, resources, application configuration, service exposure, and deployment behavior.

The release history provides operational traceability and allows teams to restore a previously working configuration without manually recreating Kubernetes resources.

## Lessons Learned

- Helm separates reusable templates from environment-specific configuration.
- Chart schemas catch invalid configuration before deployment.
- ConfigMap checksums trigger workload rollouts when mounted content changes.
- Release upgrades create auditable revisions.
- Rollbacks create a new revision while restoring an earlier configuration.
- Runtime overrides provide flexibility without modifying chart files.
- Health probes allow Helm and Kubernetes to determine workload readiness.
- Packaged charts can be distributed and installed consistently.
- Container security controls must remain compatible with image startup behavior.
- Failed releases should be diagnosed through both Helm status and Kubernetes events.

## Cleanup

Remove the release:

    helm uninstall web-delivery-release \
      --namespace web-platform

Delete the namespace:

    kubectl delete namespace web-platform

Verify cleanup:

    helm list --all-namespaces
    kubectl get namespace web-platform
