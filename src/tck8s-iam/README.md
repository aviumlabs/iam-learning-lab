# tck8s-iam

A production-ready Kubernetes application for IAM (Identity and Access Management) running on a Tomcat stack with a PostgreSQL backend.

This project is designed as a **Hot-Loop Development Environment**, where code changes in the `ssb` directory are instantly reflected in the running Kubernetes containers via bind mounts and automatic hot-reloading.

## Prerequisites

- `kubectl` installed and configured.
- `helm` installed.
- Python 3.8+ (for secret generation).
- A Kubernetes cluster with **Traefik Ingress Controller** installed.
- `local-path-provisioner` for dynamic volume provisioning.

## 🚀 Fresh Start Guide

Follow these steps to deploy the service from scratch on a new machine.

### 1. Environment Setup

First, configure your local project paths. This allows the Kubernetes manifests to map your local development files (like the `ssb` source code) into the containers.

**A. Generate `values-local.yaml`**
Create a `values-local.yaml` file in the project root. Replace the placeholder paths with your actual absolute paths.

```bash
cat <<EOF > values-local.yaml
app:
  ssb_host_path: /home/user/Development/source/iam-learning-lab/src/ssb
project_root: /home/user/Development/source/iam-learning-lab/src/tck8s-iam
EOF
```

**B. Create the Namespace**
```bash
kubectl create namespace tck8s-iam
```

### 2. Secret Provisioning

The application requires sensitive credentials for the database and Tomcat manager. We use a script to ensure these are injected correctly.

**A. Database Root Secret**
This secret contains the root password required for schema migrations and administrative tasks. It must be named `tck8s-iam-db-secret`.
```shell
python3 scripts/setup_secrets.py --name tck8s-iam-db-secret --keys ".secret_db=$(cat ./.secret_db)" -n tck8s-iam
```

**B. IdentityIQ Schema Secrets**
These secrets contain the `.pgpass` credentials for the IdentityIQ-specific schemas. It must be named `tck8s-iam-schema-secrets`.

```shell
python3 scripts/setup_secrets.py --name tck8s-iam-schema-secrets --keys ".pgpass=$(cat ./.pgpass)" -n tck8s-iam 
```

```bash
# Replace REPLACE_WITH_PASSWORD with your IdentityIQ credentials (4 lines)
python3 scripts/setup_secrets.py --name tck8s-iam-schema-secrets --keys ".pgpass=pass1:user1:host1:port1\npass2:user2:host2:port2\npass3:user3:host3:port3\npass4:user4:host4:port4" --namespace tck8s-iam
```

### 3. Deployment

Deploy the entire stack using Helm. This will provision the database, the application, the Ingress rules, and the necessary persistent volumes.

```bash
helm install tck8s-iam ./ -f values.yaml -f values-local.yaml --namespace tck8s-iam
```

### 4. Verification

Once deployed, verify that the pods are running:
```bash
kubectl get pods -n tck8s-iam
```

The application is exposed externally via **Traefik Ingress**. You can access it using the hostname configured in your Ingress resources (typically via a local DNS entry or by port-forwarding the Traefik service).

---

## 🔄 Hot-Loop Development

This project is optimized for rapid iteration. You can modify the application logic in the `ssb` folder and see changes in real-time without restarting your pods.

### The Workflow
1. Modify files in the `ssb` directory.
2. Trigger a build and hot-reload:
   ```bash
   cd ssb
   ./build.sh
   ```
*The `build.sh` script compiles the changes and signals Tomcat to reload the application context immediately.*

---

## 🛠 Configuration & Networking

### External Access (Traefik Ingress)
Instead of using `NodePort`, this project uses **Traefik Ingress** for external traffic. This allows for standard HTTP/HTTPS routing and avoids Kubernetes port range restrictions.

### Dynamic Database Configuration
You can dynamically point the application to different PostgreSQL instances by setting the following environment variables in your deployment or Helm values:
- `PG_HOST`: The hostname of the database (e.g., `tck8s-iam-db`).
- `PG_PORT`: The port of the database (e.g., `5432`).

These variables are used to patch the JDBC connection URL during the build process.

---

## 🔗 Connection Details

- **Internal Database Host:** `tck8s-iam-db`
- **Database URL Template:** `postgresql://postgres:PASSWORD@tck8s-iam-db:5432/postgres`

## 💾 Volume & Persistence

| Volume Name | Purpose | Default Size |
| :--- | :--- | :--- |
| `db-data` | PostgreSQL data files | 20Gi |
| `tc-iam-webapps` | Tomcat web applications | 5Gi |
| `tc-iam-backup` | Application backups | 5Gi |
| `tc-iam-logs` | Tomcat and application logs | 2Gi |
| `tc-iam-conf` | Application configuration | 1Gi |
| `tc-iam-secrets` | Sensitive credentials | 1Gi |
