Avium Labs IAM Learning Lab K8s Environment Guide (c) by Michael Konrad

Avium Labs IAM Learning Lab K8s Environment is licensed under a
Creative Commons Attribution 4.0 International License.

You should have received a copy of the license along with this
work. If not, see <http://creativecommons.org/licenses/by/4.0/>


# Avium Labs IAM Learning Lab Kubernetes Guide

This guide covers the deployment of services in an Ubuntu 26.04 MicroK8s environment.

## Prerequisites

### User Permissions 

Add your user account to the microk8s group:

```shell
sudo usermod -aG microk8s <logon_id>
```

### Configure microk8s

**1. Set kubectl alias:**

Add an alias to call kubectl directly without microk8s prefix:

```shell
sudo snap alias microk8s.kubectl kubectl
```

**2. Setup microk8s configuration:**
```shell
mkdir ~/.kube
```

```shell
microk8s config > ~/.kube/config
```

```shell
chmod 600 ~/.kube/config
```

**3. Test the configuration:**
```shell
kubectl cluster-info
```
>  
> Kubernetes control plane is running at https://127.0.0.1:16443  
> CoreDNS is running at https://127.0.0.1:16443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy  
>  
> To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.  
>  

### Install Helm

Download installer:

```shell
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
```

Set execution permissions:

```shell
chmod 700 get_helm.sh
```

Run the install:

```shell
./get_helm.sh
```

## Helm Validation

Open a terminal window and change to directory tck8s-iam directory.

To check for syntax errors: 
```shell
helm lint .
```

To perform a dry-run:
```
helm install --dry-run=client --debug tck8s-iam-release .
```


## Deployment

Create the database secret:

```shell
python3 scripts/setup_secrets.py --name tck8s-iam-db-secret --keys "postgres_password,database_url=postgresql://postgres:REPLACE_WITH_PASSWORD@tck8s-iam-db:5432/postgres" --namespace tck8s-iam
```

```shell
# Read the password from your local file and pass it to the script
DB_PASS=$(cat ./.secret_db)
python3 scripts/setup_secrets.py \
    --name db-password \
    --keys "password=$DB_PASS" \
    --namespace tck8s-iam
```

```shell
helm install tck8s-iam ./ -f values.yaml -f values-local.yaml --namespace tck8s-iam
```

>  
> level=INFO msg="found symbolic link in path. Contents of linked file included and used" path=/path/to/iam-learning-lab/src/tck8s-iam/scripts/iiqdeptools.py resolved=/path/to/iam-learning-lab/src/scripts/iiqdeptools.py
> NAME: tck8s-iam  
> LAST DEPLOYED: Wed Oct  7 00:29:36 2026  
> NAMESPACE: tck8s-iam  
> STATUS: deployed  
> REVISION: 1  
> DESCRIPTION: Install complete  
> TEST SUITE: None  
>  

**Check the pods:**

```
kubectl get pods -n tck8s-iam
```

>  
> NAME                            READY   STATUS    RESTARTS   AGE
> tck8s-iam-57c4b4f78c-r2b7d      0/1     Pending   0          4m45s
> tck8s-iam-db-56f8bf76db-sl5z8   0/1     Pending   0          4m45s  
>  

When the pods have reached the **Running** state, install IdentityIQ:

```bash
# Get the application pod name using the new label
APP_POD=$(kubectl get pods -n tck8s-iam -l component=app -o jsonpath='{.items[0].metadata.name}')

# Run your command
kubectl exec $APP_POD -n tck8s-iam -- iiqdeptools.py -c -H tck8s-iam-app-db -P 5432
```

**View logs**
```
kubectl logs tck8s-iam-57c4b4f78c-r2b7d -n tck8s-iam
```

**Shell access**
```
kubectl exec -it tck8s-iam-57c4b4f78c-r2b7d -n tck8s-iam -- /bin/ash
```

**Describe a pod:**
```shell
kubectl describe pod tck8s-iam-57c4b4f78c-r2b7d -n tck8s-iam
```

**Stop pods:**
```shell
kubectl scale deployment tck8s-iam -n tck8s-iam --replicas=0
```

## IdentityIQ Deployment

**To configure the environment with the new database service:**
```bash
iiqdeptools.py -c -H tck8s-iam-db -P 5432
```

**To deploy the environment with the new database service:**
```bash
iiqdeptools.py -d -H tck8s-iam-db -P 5432
```


Reload changed values.yaml:
```shell
helm upgrade tck8s-iam ./ -f values.yaml -f values-local.yaml --namespace tck8s-iam
```

## Starting Over

Uninstall the deployment:
```shell
helm uninstall tck8s-iam -n tck8s-iam
```

Delete the persistent volume claims:
```shell
kubectl delete pvc -n tck8s-iam --all
```

Delete the persistent volumes:
```shell
kubectl delete pv tck8s-iam-db-data && \
kubectl delete pv tck8s-iam-tc-iam-backup && \
kubectl delete pv tck8s-iam-tc-iam-conf && \
kubectl delete pv tck8s-iam-tc-iam-logs && \
kubectl delete pv tck8s-iam-tc-iam-secrets && \
kubectl delete pv tck8s-iam-tc-iam-webapps 
```

```shell
export PROJECT_ROOT=/home/mkonrad/Development/source/iam-learning-lab/src/tck8s-iam
```

```shell
envsubst < pvs.yaml | kubectl apply -f -
```

```shell
helm install tck8s-iam ./ -f values.yaml -f values-local.yaml --namespace tck8s-iam
```


### Appendix

**List secrets:**
```shell
kubectl get secrets -n tck8s-iam
```

**View logs from app init containers:**
```shell
kubectl logs <pod> -c volume-permissions
```

```shell
kubectl logs <pod> -c schema-init   
```

**Check db connectivity:**
Change `<your-app-pod-name>` to the name of the database pod.

```shell
kubectl exec -it <your-app-pod-name> -n tck8s-iam -- nc -zv tck8s-iam-db 5432
```

**View endpoints via kubectl:**

```shell
kubectl get endpointslice -n tck8s-iam
```

Specific to the database service:

```shell
kubectl get endpointslice -n tck8s-iam -l app=tck8s-iam-db
```



### A. Logging & Observability                                                                                                                                
*   **Oversight:** There is no unified logging strategy. The Python scripts use a `logging` module, while the PowerShell scripts use a custom `Write-Log` util
ity.                                                                                                                                                          
*   **Improvement:** Standardize on a structured logging format (e.g., JSON) across all scripts to allow for easier log aggregation in a Kubernetes environmen
t (e.g., via Fluentd or Loki). 