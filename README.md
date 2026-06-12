This README.md is structured to be the primary documentation for your repository. It includes setup instructions, the infrastructure design, and the troubleshooting knowledge we gained during our triage.

DevOps Monitoring Stack: AKS + Terraform + Prometheus
This repository automates the deployment of the kube-prometheus-stack (Prometheus, Grafana, Alertmanager) onto an existing Azure Kubernetes Service (AKS) cluster using Terraform and GitHub Actions.

1. Architecture Overview
The solution follows a standard "Infrastructure as Code" (IaC) pattern. Terraform manages the Kubernetes resources, and the Helm provider acts as the orchestrator to deploy the monitoring stack.

2. Prerequisites
Before deploying, ensure you have:

AKS Cluster: An existing Azure Kubernetes cluster.

Azure Service Principal: A SPN with at least Contributor access to the resource group containing the AKS cluster.

GitHub Secrets: Configure the following in your repository settings:

AZURE_CREDENTIALS: A JSON object (output from az ad sp create-for-rbac).

3. Configuration Files
variables.tf
Define the input variables to keep your code reusable across environments.

Terraform
variable "aks_name" { type = string }
variable "resource_group_name" { type = string }
providers.tf
This file configures the azurerm, kubernetes, and helm providers. Note the critical use of base64decode to transform Azure's certificate strings into a valid format for Kubernetes.

Terraform
provider "azurerm" { features {} }

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
main.tf
Defines the monitoring namespace and deploys the Helm chart.  

Terraform
resource "kubernetes_namespace" "monitoring" {
  metadata { name = "monitoring" }
}

resource "helm_release" "prometheus" {
  name       = "prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
}
4. GitHub Actions CI/CD Pipeline
The pipeline is defined in .github/workflows/deploy.yml. It uses input=false to ensure the process remains non-interactive and fails fast if variables are missing.

YAML
name: Deploy Monitoring Stack
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

        
5. Troubleshooting & Triage
  
"Namespace already exists" Error: This happens if the namespace was created manually. Run terraform import kubernetes_namespace.monitoring monitoring locally and push the state.

Certificate Parsing Error: Ensure every cluster_ca_certificate or client_key entry in providers.tf is wrapped in base64decode().

Accessing Grafana: The service is ClusterIP by default (internal only).

Port-forward for access: kubectl port-forward svc/prometheus-stack-grafana 3000:80 -n monitoring.

Default Login: admin / prom-operator.

Retrieve actual password: kubectl get secret -n monitoring prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode.