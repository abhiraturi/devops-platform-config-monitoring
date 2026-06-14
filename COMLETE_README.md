1.  # DevOps Infrastructure Setup

This guide provides a professional, end-to-end roadmap for provisioning an AKS environment using Terraform with automated GitHub Actions CI/CD.

## 1. Prerequisites
* **Active Azure Subscription**[cite: 1, 2]
* **Azure CLI** installed locally[cite: 1, 2]
* **Terraform** installed locally[cite: 1, 2]
* **GitHub Repository** named `devops-infra-cluster`[cite: 1]

---

## 2. Infrastructure Setup Roadmap

### Phase 1: Authentication & Identity
1. **Login to Azure**: `az login`[cite: 1, 2].
2. **Set Subscription**: `az account set --subscription "<YOUR_SUBSCRIPTION_ID>"`[cite: 1, 2].
4. **Create Service Principal**: 
```bash
   az ad sp create-for-rbac --name "github-actions-devops" --role contributor --scopes /subscriptions/<YOUR_SUBSCRIPTION_ID>

CRITICAL: Save the JSON output (Client ID, Secret, and Tenant ID)[cite: 1, 2].

Phase 2: Remote State Backend
Create Storage Resources:

Bash
   az group create --name devops-state-rg --location eastus
   az storage account create --name devopsstateaccount --resource-group devops-state-rg --location eastus --sku Standard_LRS
   az storage container create --name terraform-state --account-name devopsstateaccount --auth-mode login
   ```[cite: 1, 2]
2. **Assign Permissions**:
   * Get App ID: `az ad sp list --display-name "github-actions-devops" --query "[0].appId" -o tsv`[cite: 1, 2].
   * Grant access: `az role assignment create --assignee <YOUR_APP_ID> --role "Storage Blob Data Contributor" --scope /subscriptions/<SUB_ID>/resourceGroups/devops-state-rg/providers/Microsoft.Storage/storageAccounts/devopsstateaccount`[cite: 1, 2].

### Phase 3: GitHub Integration
1. Navigate to **Settings > Secrets and variables > Actions** in your repository[cite: 1, 2].
2. Add the following secrets: `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`[cite: 1, 2].

### Phase 4: Terraform Configuration
1. **Register Provider**: `az provider register --namespace Microsoft.ContainerService`[cite: 1, 2].
2. **Backend Setup**: Configure the `azurerm` backend in `providers.tf` to point to your `devopsstateaccount` storage account[cite: 1, 2].

---

## 3. Daily Workflow
* **Code**: Modify `.tf` files locally[cite: 1, 2].
* **Plan**: Run `terraform plan` to verify changes[cite: 1, 2].
* **Deploy**: Push to `main` to trigger the GitHub Actions pipeline[cite: 1, 2].
* **Cleanup**: Run `terraform destroy -auto-approve` when finished[cite: 1, 2].

---

## 4. Troubleshooting

| Issue | Solution |
| :--- | :--- |
| **Access Denied** | Verify "Storage Blob Data Contributor" role assignment[cite: 1, 2]. |
| **409 Conflict** | Register the `Microsoft.ContainerService` provider[cite: 1, 2]. |
| **400 Bad Request** | Check VM SKU availability against your subscription quota[cite: 1, 2]. |

---

## 5. Cluster Connection
To connect to your cluster once deployed:
```bash
az aks get-credentials --resource-group devops-project-rg --name devops-cluster --overwrite-existing
kubectl get nodes
```[cite: 1]

```</YOUR_SUBSCRIPTION_ID>

==========================================================================================================================================
==========================================================================================================================================



2.  DEPLOY FLAKS APPLICATIOM

Flask Application: DevOps Deployment
This repository contains the source code and deployment configuration for the Flask web application designed for Azure Kubernetes Service (AKS).

🚀 Overview
We have implemented a modern DevOps workflow featuring:

Containerization: Optimized Docker builds.

Orchestration: AKS-based Kubernetes deployment.

CI/CD: Automated pipeline via GitHub Actions.

📂 Project Structure
.github/workflows/deploy-app.yml: The deployment pipeline that triggers on every push to main.

k8s/deployment.yaml: Kubernetes manifests defining the Deployment and Service.

Dockerfile: Instructions to build the application image.

app.py: The main Flask application logic.

🛠 Environment & Dependency Setup
Run these commands in your project root to isolate your environment and prepare the requirements.txt file:

Create the virtual environment:

Bash
python -m venv devops_flask
Activate the venv:

Bash
source devops_flask/bin/activate
Deactivate any active Conda environment (to avoid conflicts):

Bash
conda deactivate
Install required packages:

Bash
pip install flask prometheus-flask-exporter opentelemetry-instrumentation-flask
Lock your dependencies:

Bash
pip freeze > requirements.txt
NOTE: Use port 5001 instead of 6000 (which is blocked by Chrome).

⚙️ Configuration Files
Create the following files to support Dockerization:

.dockerignore
Add this to prevent unnecessary files from bloating your image or leaking secrets:

Plaintext
devops_flask/
__pycache__/
*.pyc
.git/
.DS_Store
.env
docker-compose.yml
Handles the build and network configuration, mapping your app to port 5001.

🚀 Execution & Lifecycle Management
Use these commands to manage your application container:

Build and Start:

Bash
docker compose up --build
Once running, navigate to http://localhost:5001 in your browser.

Stop and Remove:

Bash
docker compose down
📦 Deployment to AKS
1. CI/CD Workflow
The pipeline automates the entire release process:

Login: Authenticates with Azure using GitHub Secrets.

Setup: Configures kubectl to target the devops-cluster.

Namespace: Ensures the production namespace exists.

Deploy: Applies k8s/deployment.yaml to the cluster.

2. Manual Build and Push
If deploying manually to your registry:

Bash
docker build -t raturiabhi/flask-app:latest .
docker login
docker push raturiabhi/flask-app:latest

==========================================================================================================================================

==========================================================================================================================================

3. Monitoring Setup


Markdown# DevOps Monitoring Stack: AKS + Terraform

Automated deployment of the `kube-prometheus-stack` (Prometheus, Grafana, Alertmanager) onto an existing Azure Kubernetes Service (AKS) cluster using Terraform and GitHub Actions.

---

## 🏗️ Architecture Overview

The solution follows an **Infrastructure as Code (IaC)** pattern. Terraform manages Kubernetes resources (Namespaces), while the Helm provider orchestrates the deployment of the monitoring stack.



---

## 🚀 Prerequisites

Before deploying, ensure you have:
* **AKS Cluster:** An existing Azure Kubernetes cluster.
* **Azure Service Principal:** A SPN with `Contributor` access to the resource group containing the AKS cluster.
* **GitHub Secrets:** Configure the following in your repository settings:
    * `AZURE_CREDENTIALS`: A JSON object (output from `az ad sp create-for-rbac`).

---

## ⚙️ Configuration Files

### 1. Variables (`variables.tf`)
```hcl
variable "aks_name" { type = string }
variable "resource_group_name" { type = string }
2. Providers (providers.tf)Terraformprovider "azurerm" { features {} }

data "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  resource_group_name = var.resource_group_name
}

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.aks.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
}
3. Main Logic (main.tf)Terraformresource "kubernetes_namespace" "monitoring" {
  metadata { name = "monitoring" }
}

resource "helm_release" "prometheus" {
  name       = "prometheus-stack"
  repository = "[https://prometheus-community.github.io/helm-charts](https://prometheus-community.github.io/helm-charts)"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
}
🚀 Setup & Initialization StepsLogin to Azure:az loginInitialize Terraform:terraform initImport Existing Infrastructure:If you have already created the resources manually, you must "adopt" them:Bashterraform import kubernetes_namespace.monitoring monitoring
terraform import helm_release.prometheus monitoring/prometheus-stack
Plan & Apply:Bashterraform plan -var="aks_name=YOUR_AKS" -var="resource_group_name=YOUR_RG"
terraform apply -var="aks_name=YOUR_AKS" -var="resource_group_name=YOUR_RG"
🔄 CI/CD Pipeline (.github/workflows/deploy.yml)The pipeline automates planning and applying.YAMLname: Deploy Monitoring Stack
on: [push, workflow_dispatch]

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: azure/login@v2
        with: { creds: ${{ secrets.AZURE_CREDENTIALS }} }
      - uses: hashicorp/setup-terraform@v4
      - name: Terraform Plan
        run: terraform plan -input=false -var="aks_name=..." -var="resource_group_name=..." -out=tfplan
      - name: Terraform Apply
        run: terraform apply -input=false tfplan


🛠️ Troubleshooting & Triage
IssueSolutionAlready Exists ErrorUse terraform import (see Setup Step 3).Certificate ParsingEnsure all cluster_ca_certificate are wrapped in base64decode().Accessing GrafanaUse kubectl port-forward svc/prometheus-stack-grafana 3000:80 -n monitoring.


🔐 Default Grafana Credentials  
Username: admin
Password: Retrieve via:kubectl get secret -n monitoring prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode

