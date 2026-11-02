# tck8s-iam

A production-ready Kubernetes application for IAM (Identity and Access Management) running on a Tomcat stack with a PostgreSQL backend.

This project is designed as a **Hot-Loop Development Environment**, where code changes in the `ssb` directory are instantly reflected in the running Kubernetes containers via bind mounts and automatic hot-reloading.

## Project Structure
- `templates/`: Kubernetes manifests.
- `scripts/`: Utility scripts for secret management and build automation.
- `ssb/`: The Standard Services Build (core engine).
- `docs/`: Documentation and installation guides.

## Prerequisites
- `kubectl` installed and configured.
- `helm` installed.
- Python 3.8+ (for secret generation).
- `values-local.yaml`: A local configuration file containing your specific environment paths.

## Quick Start

### 0. Local Configuration (Prerequisite)
Before deploying, you must create a `values-local.yaml` file to configure your local project path. Run the following command to generate it:

```bash
cat <<EOF > values-local.yaml
app:
  ssb_host_path: </path/to>/iam-learning-lab/src/ssb
# Update this to your local absolute project path.
# The project uses this to calculate all hostPath volumes.
project_root: /home/mkonrad/Development/source/iam-learning-lab/src/tck8s-iam
EOF
```

Run the following command to create the project's kubernetes namespace:
```bash
kubectl create namespace tck8s-iam
```

### 1. Storage & Persistence (Local Development)
For local development using **microK8s** or **Minikube**, you must ensure your cluster has a `StorageClass` and the required `PersistentVolume` (PV) objects are manually defined because they do not automatically provision on your local machine.

**A. Create the StorageClass:**
Apply the following configuration to create a `standard` StorageClass using the hostpath provisioner:
```bash
kubectl apply -f storageclass.yaml
```
*(Note: If you don't have a `storageclass.yaml` file, you can create one with `provisioner: kubernetes.io/no-provisioner` and `volumeBindingMode: WaitForFirstConsumer`.)*

**B. Create the PersistentVolumes:**
Because the cluster uses static provisioning, you must manually create the PVs. The project requires the following PVs to be created (see `pvs.yaml` for the full definitions):
- `tck8s-iam-db-data` (20Gi)
- `tck8s-iam-tc-iam-backup` (5Gi)
- `tck8s-iam-tc-iam-logs` (2Gi)
- `tck8s-iam-tc-iam-conf` (1Gi)
- `tck8s-iam-tc-iam-secrets` (1Gi)
- `tck8s-iam-tc-iam-webapps` (5Gi)

**To apply these volumes while supporting custom project paths, use `envsubst`:**
```bash
export PROJECT_ROOT=/home/mkonrad/Development/source/iam-learning-lab/src/tck8s-iam
envsubst < pvs.yaml | kubectl apply -f -
```

### 2. Secret Provisioning
The project uses native Kubernetes Secrets and persistent volumes for sensitive data.

**Database Secrets:**
To initialize the database, you must create two secrets: one for the Postgres admin account and one for the application-specific schema credentials.

**Option A: Manual (Provide a specific password)**
Replace `REPLACE_WITH_PASSWORD` with your chosen password:

1. **Admin Secret:**
```bash
python3 scripts/setup_secrets.py --name tck8s-iam-db-secret --keys "postgres_password=$POSTGRES_PASSWORD,database_url=postgresql://postgres:$POSTGRES_PASSWORD@tck8s-iam-db:5432/postgres" --namespace tck8s-iam
```

2. **Schema Secrets:**
Provide the credentials for `identityiq`, `identityiqPlugin`, and `identityiqah` schemas.
```bash1
python3 scripts/setup_secrets.py --name tck8s-iam-schema-secrets --keys "identityiq:pass1,identityiqPlugin:pass2,identityiqah:pass3" --namespace tck8s-iam
```

**Option B: Automatic (Let the script generate a password)**
The script will generate a secure random password and print it to the console. You will then need to use that password in the `database_url` connection string.

1. **Admin Secret:**
```bash1
python3 scripts/setup_secrets.py --name tck8s-iam-db-secret --keys "postgres_password,database_url=postgresql://postgres:REPLACE_WITH_PASSWORD@tck8s-iam-db:5432/postgres" --namespace tck8s-iam
```

2. **Schema Secrets:**
```bash1
python3 scripts/setup_secrets.py --name tck8s-iam-schema-secrets --keys "identityiq,identityiqPlugin,identityiqah" --namespace tck8s-iam
```
*Note: After running these, the script will output the generated passwords. Copy those passwords and update the `database_url` in the command for the Admin Secret, then rerun to ensure the secret is correct.*

**Tomcat Credentials:**
Tomcat Manager credentials are dynamically generated and stored in the `/opt/secrets` volume. Ensure these files exist:
- `/opt/secrets/rpauser`
- `/opt/secrets/rpapass`

### 3. Deployment
Deploy the application using Helm:
```bash1
helm install tck8s-iam ./ -f values.yaml -f values-local.yaml --namespace tck8s-iam --create-namespace
```
*Note: The database schema is automatically initialized by Kubernetes InitContainers upon deployment.*

---

## Hot-Loop Development (The "DevEx" Workflow)

This project is optimized for rapid iteration. You can modify the application logic in the `ssb` folder and see changes in real-time without restarting your pods.

### 1. Configure your Local Path
The project uses `values-local.yaml` to map your local directory to the container. Ensure the `ssb_host_path` in `values-local.yaml` points to your local project root.

### 2. Develop and Build
Modify the files in the `ssb` directory. To compile the changes and trigger a hot-reload of the running container:
```bash1
cd src/ssb
./build.sh
```
*The script will build the WAR and signal Tomcat to reload the application context immediately.*

---

## Connection Details
- **Database URL:** `postgresql://postgres:REPLACE_WITH_PASSWORD@tck8s-iam-db:5432/postgres`
- **Host:** `tck8s-iam-db` (Assumes Helm release name is `tck8s-iam`)

## Volume & Persistence
- `tc-iam-backup`: 5Gi
- `tc-iam-logs`: 2Gi
- `tc-iam-conf`: 1Gi
- `tc-iam-secrets`: 1Gi
- `tc-iam-webapps`: 5Gi
- `tck8s-iam-db-data`: 20Gi
