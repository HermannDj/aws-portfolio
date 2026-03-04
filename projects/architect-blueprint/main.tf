# --- Module 1: Primary VPC — multi-AZ networking foundation
module "networking" {
  source = "./modules/networking"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  enable_nat_gateway = true
}

# --- Module 2: DR VPC (us-west-2) — disaster recovery network, uses alias provider
module "networking_dr" {
  source = "./modules/networking"

  providers = {
    aws = aws.dr
  }

  project_name       = "${var.project_name}-dr"
  environment        = var.environment
  vpc_cidr           = var.dr_vpc_cidr
  enable_nat_gateway = true
}

# --- Module 3: EKS HA — highly available Kubernetes cluster across 3 AZs
# SECURITY: Override eks_public_access_cidrs with your IP in production
# e.g., cluster_endpoint_public_access_cidrs = ["YOUR_IP/32"]
module "eks_ha" {
  source = "./modules/eks-ha"

  project_name         = var.project_name
  environment          = var.environment
  cluster_version      = var.eks_cluster_version
  private_subnet_ids   = module.networking.private_subnet_ids
  node_instance_types  = var.eks_node_instance_types
  node_min_size        = var.eks_node_min_size
  node_max_size        = var.eks_node_max_size
  node_desired_size    = var.eks_node_desired_size
  allowed_cidr_blocks  = var.eks_public_access_cidrs

  depends_on = [module.networking]
}

# --- Module 4: Aurora PostgreSQL — Multi-AZ managed database with encryption and PITR
module "rds_aurora" {
  source = "./modules/rds-aurora"

  project_name         = var.project_name
  environment          = var.environment
  aurora_instance_class = var.aurora_instance_class
  aurora_engine_version = var.aurora_engine_version
  backup_retention_days = var.aurora_backup_retention_days
  database_subnet_ids  = module.networking.database_subnet_ids
  eks_security_group_id = module.eks_ha.node_security_group_id
  vpc_id               = module.networking.vpc_id

  depends_on = [module.networking, module.eks_ha]
}

# --- Module 5: CloudFront + WAF — global CDN with OWASP protection and ACM certificate
module "cdn_waf" {
  source = "./modules/cdn-waf"

  project_name  = var.project_name
  environment   = var.environment
  domain_name   = var.domain_name
  enable_waf    = var.enable_waf

  depends_on = [module.networking]
}

# --- Module 6: Security — GuardDuty, Security Hub, CloudTrail, Config, KMS
module "security" {
  source = "./modules/security"

  project_name         = var.project_name
  environment          = var.environment
  enable_guardduty     = var.enable_guardduty
  enable_security_hub  = var.enable_security_hub
  enable_cloudtrail    = var.enable_cloudtrail
}

# --- Module 7: Observability — CloudWatch dashboards, alarms, X-Ray, budgets
module "observability" {
  source = "./modules/observability"

  project_name          = var.project_name
  environment           = var.environment
  alert_email           = var.alert_email
  cost_alert_threshold  = var.cost_alert_threshold
  eks_cluster_name      = module.eks_ha.cluster_name
  aurora_cluster_id     = module.rds_aurora.cluster_id
  cloudfront_distribution_id = module.cdn_waf.distribution_id

  depends_on = [module.eks_ha, module.rds_aurora, module.cdn_waf]
}
