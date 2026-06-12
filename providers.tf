terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.0" }
    helm = { source = "hashicorp/helm", version = "~> 2.0" }
  }

  backend "azurerm" {
    resource_group_name  = "devops-project-rg"
    storage_account_name = "devopsstateaccount"
    container_name       = "tfstate"
    # KEY IS THE MAGIC PART:
    # Use different keys to separate your projects
    key                  = "monitoring.tfstate" 
  }

}

provider "azurerm" {
  features {}
}

# The data source for AKS authentication lives here so it's globally available
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

provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.aks.kube_config.0.host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
    # THIS LINE WAS LIKELY MISSING THE DECODE FUNCTION:
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
  }
}