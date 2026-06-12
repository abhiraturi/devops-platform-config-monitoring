terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.14.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.31.0"
    }
  }
}

# These providers will automatically pick up the credentials 
# from the 'az aks get-credentials' command in your GitHub Action.
provider "helm" {
  kubernetes {}
}

provider "kubernetes" {}