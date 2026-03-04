# 🏗️ AWS Solutions Architect Portfolio

> **Production-grade, multi-region AWS architectures** demonstrating enterprise-level cloud expertise for **AWS Solutions Architect Professional** and **DevOps Engineering** roles.

[![Terraform](https://img.shields.io/badge/Terraform-1.7+-623CE4?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Certified-FF9900?logo=amazonaws&logoColor=white)](https://aws.amazon.com/)
[![CI/CD](https://github.com/HermannDj/aws-portfolio/actions/workflows/architect-pipeline.yml/badge.svg)](https://github.com/HermannDj/aws-portfolio/actions)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 👨‍💼 About This Portfolio

This repository showcases **production-ready AWS infrastructure-as-code (IaC)** projects built with **Terraform**, designed to demonstrate:

✅ **Multi-region architecture** with disaster recovery  
✅ **Security-first design** (GuardDuty, Security Hub, WAF, KMS encryption)  
✅ **High availability** (Multi-AZ deployments, Aurora replication)  
✅ **Cost optimization** (spot instances, S3 lifecycle policies, budget alerts)  
✅ **DevOps best practices** (GitOps, OIDC authentication, automated CI/CD)  
✅ **Observability** (CloudWatch dashboards, X-Ray tracing, budget alerts)  

**Target audience:** Hiring managers, technical recruiters, and freelance clients looking for AWS expertise.

---

## 🚀 Featured Projects

### 🏛️ [Architect Blueprint](projects/architect-blueprint/) — Multi-Region Production Architecture

**Scenario:** Enterprise-grade infrastructure for a SaaS application requiring global delivery, high availability, and compliance.

| **Component**          | **Services**                                   | **Highlights**                                   |
|------------------------|------------------------------------------------|--------------------------------------------------|
| **Networking**         | VPC, Transit Gateway-ready, Flow Logs          | Multi-AZ, 3-tier network isolation               |
| **Container Platform** | EKS 1.29 + OIDC + Karpenter-ready              | HA Kubernetes, IRSA for pod-level IAM            |
| **Database**           | Aurora PostgreSQL 15 Multi-AZ                  | PITR (35 days), IAM auth, cross-region replicas  |
| **CDN + Security**     | CloudFront + WAF v2 + ACM + Route53            | HTTP/3, OWASP rules, rate limiting               |
| **Security**           | GuardDuty + Security Hub + CloudTrail + Config | CIS Benchmark, FSBP, threat detection            |
| **Observability**      | CloudWatch + X-Ray + Budgets                   | Custom dashboards, distributed tracing, cost alerts |

**📊 Estimated Cost:** ~$330/month (see [Cost Transparency](#-cost-transparency) below)  
**⏱️ Deployment Time:** ~15 minutes  
**🎯 Skills Demonstrated:** Solutions Architect Professional, Well-Architected Framework

[**👉 View Project Details**](projects/architect-blueprint/README.md)

---

## 💼 Skills Demonstrated

| **Category**                | **Technologies & Practices**                                                                 |
|-----------------------------|----------------------------------------------------------------------------------------------|
| **Cloud Platforms**         | AWS (Solutions Architect Professional level)                                                 |
| **Infrastructure as Code**  | Terraform 1.7+, modular design, remote state with S3 + DynamoDB                              |
| **Networking**              | VPC, subnets, NAT Gateway, Transit Gateway, VPC Flow Logs, CloudFront, Route53               |
| **Compute**                 | EKS (Kubernetes 1.29), managed node groups, Fargate-ready, Karpenter autoscaling             |
| **Database**                | Aurora PostgreSQL (Multi-AZ, PITR, read replicas, IAM authentication)                        |
| **Security**                | GuardDuty, Security Hub, CloudTrail, AWS Config, KMS encryption, WAF v2, OIDC/IRSA           |
| **Observability**           | CloudWatch (dashboards, alarms, logs), X-Ray tracing, AWS Budgets                            |
| **CI/CD**                   | GitHub Actions, OIDC authentication (no static keys), automated terraform plan/apply         |
| **Cost Optimization**       | Spot instances, lifecycle policies, S3 Intelligent-Tiering, budget alerts                    |
| **Compliance**              | CIS AWS Foundations Benchmark v1.4, AWS Foundational Security Best Practices                 |

---

## 🛠️ Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.7.0
- [AWS CLI](https://aws.amazon.com/cli/) >= 2.x configured with credentials
- An AWS account with appropriate permissions
- (Optional) [kubectl](https://kubernetes.io/docs/tasks/tools/) for EKS projects

### Deploy a Project

```bash
# Clone the repository
git clone https://github.com/HermannDj/aws-portfolio.git
cd aws-portfolio/projects/architect-blueprint

# Initialize Terraform
terraform init

# Review the execution plan
terraform plan -var="environment=prod" -var="domain_name=yourdomain.com"

# Apply (requires confirmation)
terraform apply -var="environment=prod" -var="domain_name=yourdomain.com"

# ⚠️ IMPORTANT: Destroy after demo to avoid charges
terraform destroy -var="environment=prod" -var="domain_name=yourdomain.com"
```

---

## 💰 Cost Transparency

| **Project**           | **Monthly Cost** | **Free Tier Eligible** | **Destroy Instructions**                              |
|-----------------------|------------------|------------------------|-------------------------------------------------------|
| Architect Blueprint   | ~$330/month      | No                     | `terraform destroy -var="environment=prod" -var="domain_name=yourdomain.com"` |

**💡 Tip:** Use `terraform plan` with cost estimation tools like [Infracost](https://www.infracost.io/) before deploying.

---

## 🔐 Security & Best Practices

- ✅ **No hardcoded secrets** — Uses AWS OIDC for GitHub Actions authentication
- ✅ **Encryption at rest** — KMS for EKS secrets, Aurora, CloudTrail logs
- ✅ **Encryption in transit** — TLS 1.2+ enforced on all services
- ✅ **Least privilege IAM** — IRSA for EKS pods, scoped policies
- ✅ **Threat detection** — GuardDuty with S3, Kubernetes, and malware protection
- ✅ **Compliance** — CIS Benchmark v1.4 + AWS Foundational Security Best Practices

See [SECURITY.md](SECURITY.md) for the full security policy.

---

## 🎓 Certifications & Learning Path

This portfolio was built while pursuing:

- [ ] **AWS Certified Solutions Architect – Professional** *(In Progress)*
- [x] **AWS Certified Solutions Architect – Associate** *(Achieved)*
- [ ] **AWS Certified DevOps Engineer – Professional** *(Planned)*

---

## 💼 Available for Freelance / Contract Work

I'm available for:

- ✅ **AWS architecture design and review** (Well-Architected Framework)
- ✅ **Terraform/IaC development and migration** (AWS, multi-cloud)
- ✅ **EKS/Kubernetes deployment and management**
- ✅ **CI/CD pipeline implementation** (GitHub Actions, GitLab CI)
- ✅ **Cloud cost optimization audits** (FinOps practices)
- ✅ **Security compliance** (CIS, FSBP, SOC 2, HIPAA)

**LinkedIn:** [linkedin.com/in/hermanndj](https://linkedin.com/in/hermanndj)

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

**⭐ If this portfolio demonstrates the AWS expertise you're looking for, let's connect!**
