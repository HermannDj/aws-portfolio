# aws-portfolio

A collection of production-ready AWS infrastructure projects demonstrating Solutions Architect and DevOps expertise using Terraform.

---

## Projects

## 🏛️ Project 3 — Architect Blueprint (`projects/architect-blueprint/`)

Production-grade multi-region architecture for Solutions Architect portfolios.

| Component | Services | Description |
|-----------|----------|-------------|
| Networking | VPC + Flow Logs + Transit Gateway-ready | Multi-AZ, 3-tier network |
| Container Platform | EKS 1.29 + OIDC + Karpenter-ready | HA Kubernetes cluster |
| Database | Aurora PostgreSQL 15 Multi-AZ | PITR, encryption, IAM auth |
| CDN + Security | CloudFront + WAF v2 + ACM + Route53 | Global delivery + OWASP protection |
| Security | GuardDuty + Security Hub + CloudTrail + Config | Compliance-ready |
| Observability | CloudWatch + X-Ray + Budgets | Full-stack monitoring |

⚠️ **Estimated cost: ~$330/month** — run `terraform destroy` after demo.
