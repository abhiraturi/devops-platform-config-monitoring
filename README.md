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
