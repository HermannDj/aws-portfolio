# --- Primary AWS provider (us-east-1) with default tags applied to all resources
provider "aws" {
  region = var.primary_region

  default_tags {
    tags = {
      Project      = var.project_name
      Environment  = var.environment
      ManagedBy    = "Terraform"
      Owner        = "HermannDj"
      Architecture = "multi-region"
    }
  }
}

# --- Disaster Recovery AWS provider (us-west-2) — alias "dr"
provider "aws" {
  alias  = "dr"
  region = var.dr_region

  default_tags {
    tags = {
      Project      = var.project_name
      Environment  = var.environment
      ManagedBy    = "Terraform"
      Owner        = "HermannDj"
      Architecture = "multi-region"
    }
  }
}

# --- Data sources to retrieve EKS cluster info for Helm/Kubernetes providers
# NOTE: On initial apply, run with `-target=module.eks_ha` first to create the
# EKS cluster, then run `terraform apply` without targets to configure the rest.
data "aws_eks_cluster" "main" {
  name       = module.eks_ha.cluster_name
  depends_on = [module.eks_ha]
}

data "aws_eks_cluster_auth" "main" {
  name       = module.eks_ha.cluster_name
  depends_on = [module.eks_ha]
}

# --- Helm provider pointing at the EKS cluster
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}

# --- Kubernetes provider pointing at the EKS cluster
provider "kubernetes" {
  host                   = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}
