![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.7-7B42BC?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-Solutions_Architect-FF9900?logo=amazonaws)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.29-326CE5?logo=kubernetes)
![PostgreSQL](https://img.shields.io/badge/Aurora-PostgreSQL_15-4169E1?logo=postgresql)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-CI%2FCD-2088FF?logo=githubactions)

# Architect Blueprint — Multi-Region AWS Production Architecture

> Multi-region, production-grade AWS architecture showcasing Solutions Architect expertise.
> Features EKS HA cluster, Aurora PostgreSQL Multi-AZ, CloudFront CDN with WAF protection,
> centralized security (GuardDuty, Security Hub, CloudTrail), and full observability stack.

---

## Architecture Diagram

```
                              ┌─────────────────────────────────────────────────┐
                              │              Internet / Users                   │
                              └────────────────────┬────────────────────────────┘
                                                   │
                              ┌────────────────────▼────────────────────────────┐
                              │           Amazon CloudFront (HTTP/3)            │
                              │     PriceClass_100 — US + Europe edge nodes     │
                              │      ┌─────────────────────────────────┐        │
                              │      │   WAF v2 WebACL                 │        │
                              │      │  • OWASP Common Rule Set        │        │
                              │      │  • IP Reputation List           │        │
                              │      │  • Known Bad Inputs             │        │
                              │      │  • Rate Limit (2000 req/5min)   │        │
                              │      └─────────────────────────────────┘        │
                              └──────────┬──────────────────┬────────────────────┘
                                         │                  │
                               /api/*    │                  │   /*
                          (no cache)     │                  │   (cache 24h)
                                         ▼                  ▼
                              ┌──────────────────┐  ┌──────────────────────┐
                              │   ALB (HTTPS)    │  │   S3 Static Website  │
                              └────────┬─────────┘  └──────────────────────┘
                                       │
         ┌─────────────────────────────▼──────────────────────────────────┐
         │                  VPC  10.0.0.0/16  (us-east-1)                 │
         │  ┌─────────────────────────────────────────────────────────┐   │
         │  │               EKS 1.29 — HA Cluster                     │   │
         │  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │   │
         │  │  │  AZ-1        │  │  AZ-2        │  │  AZ-3        │  │   │
         │  │  │ private subnet│  │ private subnet│  │ private subnet│  │   │
         │  │  │  t3.medium   │  │  t3.medium   │  │  t3.medium   │  │   │
         │  │  │  (on-demand) │  │  (on-demand) │  │  (on-demand) │  │   │
         │  │  └──────────────┘  └──────────────┘  └──────────────┘  │   │
         │  │        │  OIDC/IRSA — pods get own IAM roles            │   │
         │  │        │  KMS secrets encryption                        │   │
         │  └────────┼────────────────────────────────────────────────┘   │
         │           │                                                     │
         │  ┌────────▼────────────────────────────────────────────────┐   │
         │  │        Aurora PostgreSQL 15 — Multi-AZ                  │   │
         │  │  ┌─────────────────┐     ┌─────────────────────────┐    │   │
         │  │  │  Writer (AZ-1)  │────▶│  Reader Replica (AZ-2)  │    │   │
         │  │  │  db.t3.medium   │     │  db.t3.medium            │    │   │
         │  │  └─────────────────┘     └─────────────────────────┘    │   │
         │  │        KMS encryption | IAM auth | PITR enabled          │   │
         │  └─────────────────────────────────────────────────────────┘   │
         │                                                                 │
         │  NAT GW × 3 (one per AZ)  |  VPC Flow Logs → CloudWatch        │
         └─────────────────────────────────────────────────────────────────┘

         ┌─────────────────────────────────────────────────────────────────┐
         │                  DR VPC  10.1.0.0/16  (us-west-2)              │
         │              (Transit Gateway-ready for failover)               │
         └─────────────────────────────────────────────────────────────────┘

         ┌─────────────────────────────────────────────────────────────────┐
         │                       Security Layer                            │
         │                                                                 │
         │  GuardDuty ──────┐                                              │
         │  AWS Config ─────┤──▶  Security Hub  ──▶  SNS Alerts           │
         │  CloudTrail ─────┘    (CIS + FSBP)                              │
         │  IAM Password Policy  |  EBS Encryption by Default              │
         └─────────────────────────────────────────────────────────────────┘

         ┌─────────────────────────────────────────────────────────────────┐
         │                     Observability Layer                         │
         │                                                                 │
         │  CloudWatch Dashboards  ◀────  EKS + Aurora + CloudFront        │
         │  CloudWatch Alarms      ──▶   SNS (email/pagerduty)             │
         │  X-Ray Tracing          ◀────  All EKS services                 │
         │  AWS Budgets            ──▶   Cost alerts at 80% + 100%         │
         └─────────────────────────────────────────────────────────────────┘
```

---

## Cost Estimation

> ⚠️ **DESTROY AFTER DEMO** — Run `terraform destroy` when done to avoid charges!
> ```bash
> cd projects/architect-blueprint
> terraform destroy -var="environment=prod"
> ```

| Service              | Monthly Cost (prod) | Free Tier    |
|----------------------|--------------------:|:-------------|
| EKS Cluster          | ~$72                | No           |
| EC2 t3.medium × 3    | ~$93                | No           |
| Aurora t3.medium × 2 | ~$58                | No           |
| CloudFront           | ~$1–10              | Yes (1TB/mo) |
| WAF v2               | ~$5 + $1/rule/mo    | No           |
| NAT Gateway × 3      | ~$99                | No           |
| CloudTrail           | ~$2                 | No           |
| GuardDuty            | ~$4                 | 30-day trial |
| **TOTAL**            | **~$330/month**     |              |

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.7.0
- [AWS CLI](https://aws.amazon.com/cli/) >= 2.x configured with appropriate credentials
- [kubectl](https://kubernetes.io/docs/tasks/tools/) for cluster interaction
- An AWS account with permissions to create all resources
- A registered domain in Route53 (for ACM + CloudFront custom domain)
- An S3 bucket and DynamoDB table for Terraform remote state

---

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/HermannDj/aws-portfolio.git
cd aws-portfolio/projects/architect-blueprint

# 2. Initialize Terraform (update backend.tf with your bucket name first)
terraform init

# 3. Review the plan
terraform plan -var="environment=prod" -var="domain_name=yourdomain.com"

# 4. Apply (requires manual confirmation)
terraform apply -var="environment=prod" -var="domain_name=yourdomain.com"

# 5. Get kubeconfig for EKS
aws eks update-kubeconfig \
  --name $(terraform output -raw eks_cluster_name) \
  --region us-east-1

# 6. CLEANUP when done
terraform destroy -var="environment=prod" -var="domain_name=yourdomain.com"
```

---

## OIDC Setup (GitHub Actions)

To enable the CI/CD pipeline to authenticate with AWS without static credentials:

```bash
# 1. Create an IAM role with OIDC trust for GitHub Actions
aws iam create-role \
  --role-name github-actions-terraform \
  --assume-role-policy-document file://oidc-trust-policy.json

# 2. Add secrets to your GitHub repository
# AWS_ROLE_ARN      = arn:aws:iam::<ACCOUNT_ID>:role/github-actions-terraform
# TF_STATE_BUCKET   = terraform-state-hermanndj
# TF_LOCK_TABLE     = terraform-state-lock
# DOMAIN_NAME       = your-registered-route53-domain.com  (e.g. example.com)
```

Trust policy (`oidc-trust-policy.json`):
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
      },
      "StringLike": {
        "token.actions.githubusercontent.com:sub": "repo:HermannDj/aws-portfolio:*"
      }
    }
  }]
}
```

---

## Module Descriptions

| Module | Purpose | Key Resources |
|--------|---------|---------------|
| `networking` | 3-tier network foundation | VPC, public/private/DB subnets, NAT GW × 3, Flow Logs |
| `eks-ha` | HA Kubernetes cluster | EKS 1.29, managed node groups, OIDC, EBS CSI, KMS |
| `rds-aurora` | Managed PostgreSQL database | Aurora PostgreSQL 15, writer + reader, PITR, KMS |
| `cdn-waf` | Global CDN with security | CloudFront, WAF v2 (OWASP), ACM cert, Route53 |
| `security` | Account-wide security posture | GuardDuty, Security Hub, CloudTrail, Config, KMS |
| `observability` | Monitoring and alerting | CloudWatch dashboards + alarms, X-Ray, Budgets |

---

## Security Posture

| Control | Implementation |
|---------|---------------|
| **Encryption at rest** | KMS for EKS secrets, Aurora storage, CloudTrail logs |
| **Encryption in transit** | TLS 1.2+ enforced on CloudFront, RDS |
| **Identity** | IRSA for pod-level IAM, IAM auth for RDS, no static creds |
| **Network isolation** | Private subnets for EKS + RDS, SGs with least privilege |
| **Threat detection** | GuardDuty with S3 + K8s audit + malware protection |
| **Compliance** | CIS Benchmark v1.4 + AWS FSBP via Security Hub |
| **Audit** | Multi-region CloudTrail with log integrity validation |
| **Cost control** | AWS Budgets with 80% + 100% threshold alerts |

---

## Disaster Recovery Strategy

| Component | RPO | RTO | Strategy |
|-----------|-----|-----|----------|
| Aurora PostgreSQL | < 5 min | < 30 min | Multi-AZ + PITR (35-day window) |
| EKS workloads | < 15 min | < 60 min | GitOps re-deploy to DR region |
| Networking | Immediate | < 30 min | DR VPC pre-provisioned in us-west-2 |
| CloudFront | N/A | N/A | Global CDN — inherently resilient |
| Terraform state | N/A | N/A | S3 versioning + cross-region replication |

---

## LinkedIn / Portfolio Pitch

> **Demonstrates:**
> - 🏗️ Multi-region architecture design (us-east-1 primary + us-west-2 DR)
> - ☸️ Kubernetes (EKS) at scale — HA, IRSA, OIDC, Spot optimization
> - 🗄️ Database HA patterns — Aurora Multi-AZ, PITR, IAM auth
> - 🔒 CDN + WAF security — CloudFront HTTP/3, OWASP rules, rate limiting
> - 📜 IaC best practices — modular Terraform, validated variables, lifecycle rules
> - 🔄 GitOps CI/CD — GitHub Actions with AWS OIDC, multi-stage pipeline
> - 💰 Cost optimization — Spot nodes, PriceClass_100, budget alerts
> - 📊 Observability engineering — CloudWatch dashboards, X-Ray tracing, SNS alerts
