# Enterprise Configuration Decoupling: Immutable State Injection and Secret Envelope Controls

## What This Does

This architecture implements cloud-native operational decoupling by isolating infrastructure configuration from application code using Kubernetes ConfigMaps and Secrets. It enables secure runtime environment variable injection, mounts configuration templates through read-only volumes, and protects sensitive credentials with Opaque Secrets. The result is a fully stateless deployment model that supports consistent promotion across development, testing, and production environments.

---

## Architecture

```text
                     +-----------------------------------+
                     |       Kubernetes API Engine       |
                     +-----------------------------------+
                               |                 |
     [ Injects Plaintext ]     |                 |     [ Injects Base64 Secrets ]
                               v                 v
                     +------------------+  +------------------+
                     |    ConfigMap     |  |      Secret      |
                     | (app-config-comp)|  | (app-secret-comp)|
                     +------------------+  +------------------+
                               |                 |
                               +--------+--------+
                                        |
                                        v
                     +-----------------------------------+
                     |        Target Pod Sandbox         |
                     |  - Mounted Volume: /etc/config    |
                     |  - Mounted Volume: /etc/secrets   |
                     |  - Env Variable: DB_PASSWORD      |
                     +-----------------------------------+
```

---

## Prerequisites

- Ubuntu 24.04 LTS or equivalent Linux distribution
- Docker Engine
- Kubernetes Cluster (Minikube recommended)
- kubectl CLI
- Basic understanding of ConfigMaps and Secrets

---

## Setup & Execution

```bash
# Deploy the ConfigMap
kubectl apply -f configmap-web.yaml

# Deploy the Secret
kubectl apply -f secret-manifest.yaml

# Deploy the application
kubectl apply -f complete-app.yaml

# Verify resources
kubectl get configmaps
kubectl get secrets
kubectl get pods
kubectl describe pod <pod-name>
```

---

## Project Structure

```text
configuration-state-management/
├── app.properties
├── configmap-web.yaml
├── secret-manifest.yaml
├── complete-app.yaml
└── README.md
```

---

## Tools Used

| Component | Technology |
|-----------|------------|
| Container Orchestration | Kubernetes |
| Configuration Management | ConfigMaps |
| Secret Management | Kubernetes Secrets |
| Web Server | Nginx 1.21 |
| Deployment Model | Kubernetes Deployment |
| Runtime Configuration | Environment Variables & Mounted Volumes |

---

## Key Skills Demonstrated

- Stateless application deployment using external configuration.
- Secure secret management through Kubernetes Opaque Secrets.
- Runtime environment variable injection.
- Read-only volume mounting for configuration and credentials.
- Infrastructure-as-Code using declarative YAML manifests.
- Separation of configuration from container images.
- Enterprise-grade Kubernetes configuration management.

---

## Real-World Use Case

Modern cloud-native applications should never hardcode credentials or configuration inside container images. Instead, configuration is externalized through ConfigMaps while sensitive information such as database passwords, API keys, and authentication tokens is securely injected using Kubernetes Secrets. This architecture allows the same application image to be promoted across Development, QA, Staging, and Production by simply replacing external configuration without rebuilding containers.

---

## Lessons Learned

- Configuration should always remain independent from application binaries.
- Secrets must never be committed to source control.
- Environment-specific values should be injected during deployment.
- Mounted configuration volumes simplify operational updates.
- Kubernetes ConfigMaps and Secrets significantly improve portability and maintainability.

---

## Troubleshooting

### ConfigMap Not Updating

Pods do not automatically reload mounted ConfigMaps after modification.

**Solution**

```bash
kubectl rollout restart deployment complete-app
```

---

### Secret Not Available

If environment variables appear empty, verify the Secret exists before deployment.

**Solution**

```bash
kubectl get secrets
kubectl describe secret app-secrets-complete
```

---

### Pod Startup Failure

If Pods fail to start, verify that both the ConfigMap and Secret were successfully created before applying the Deployment.

**Solution**

```bash
kubectl get configmaps
kubectl get secrets
kubectl describe pod <pod-name>
```

---

## Outcome

This project demonstrates enterprise-grade Kubernetes configuration management by separating application configuration from source code, securely injecting sensitive runtime secrets, and deploying stateless workloads using declarative Infrastructure-as-Code practices. It reflects production-ready design patterns commonly used in modern cloud platforms and DevOps environments.
