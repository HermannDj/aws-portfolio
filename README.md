[![Terraform](https://img.shields.io/badge/Terraform-1.7+-623CE4?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Certified-FF9900?logo=amazonaws&logoColor=white)](https://aws.amazon.com/)
[![CI/CD](https://github.com/HermannDj/aws-portfolio/workflows/Architect%20Blueprint%20—%20Terraform%20CI%2FCD/badge.svg)](https://github.com/HermannDj/aws-portfolio/actions)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Security](https://img.shields.io/badge/Security-Best%20Practices-blue)](SECURITY.md)

# 🏗️ AWS Solutions Architect Portfolio

> **Production-grade, multi-region AWS architectures** demonstrating enterprise-level cloud expertise for **AWS Solutions Architect Professional** and **DevOps Engineering** roles.

---

## 👨‍💼 About This Portfolio

This repository showcases **production-ready AWS infrastructure-as-code (IaC)** projects built with **Terraform**, designed to demonstrate:

✅ **Multi-region architecture** with disaster recovery  
✅ **Security-first design** (GuardDuty, Security Hub, WAF, KMS encryption)  
✅ **High availability** (Multi-AZ deployments, Aurora replication)  
✅ **Cost optimization** (reserved instances, spot instances, lifecycle policies)  
✅ **DevOps best practices** (GitOps, OIDC authentication, automated CI/CD)  
✅ **Observability** (CloudWatch dashboards, X-Ray tracing, budget alerts)  

**Target audience:** Hiring managers, technical recruiters, freelance clients looking for AWS expertise.

---

## 🚀 Featured Project

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

**📊 Cost:** ~$330/month (detailed breakdown in README)  
**⏱️ Deployment Time:** ~15 minutes  
**🎯 Skills Demonstrated:** Solutions Architect Professional, Well-Architected Framework, compliance

[**👉 View Project Details**](projects/architect-blueprint/README.md)

---

## 💡 Skills Demonstrated

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

## 🎯 Business Use Cases

This architecture is suitable for:

- **SaaS Applications** requiring global content delivery and multi-tenant isolation
- **E-commerce Platforms** with high availability and PCI DSS compliance requirements
- **Enterprise Applications** needing disaster recovery and audit trails
- **Startups** seeking production-ready infrastructure with cost optimization

---

## 🛠️ Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.7.0
- [AWS CLI](https://aws.amazon.com/cli/) >= 2.x configured with credentials
- An AWS account with appropriate permissions

### Deploy a Project

```bash
# Clone the repository
git clone https://github.com/HermannDj/aws-portfolio.git
cd aws-portfolio/projects/architect-blueprint

# Initialize Terraform
tf init

# Review the execution plan (NO DEPLOYMENT - just preview)
tf plan -var="environment=prod" -var="domain_name=yourdomain.com"

# ⚠️ IMPORTANT: Only apply if you understand the costs (~$330/month)
# tf apply -var="environment=prod" -var="domain_name=yourdomain.com"

# Destroy after demo to avoid charges
# tf destroy -var="environment=prod" -var="domain_name=yourdomain.com"
```

---

## 💰 Cost Transparency

| **Project**           | **Monthly Cost** | **Free Tier Eligible** | **Destroy Instructions**                |
|-----------------------|------------------|------------------------|-----------------------------------------|
| Architect Blueprint   | ~$330/month      | No                     | `tf destroy -var="environment=prod"` |

**💡 Tip:** This portfolio demonstrates architecture skills without actual deployment. Use `tf plan` to explore infrastructure without incurring costs.

---

## 🔐 Security & Best Practices

- ✅ **No hardcoded secrets** — Uses AWS OIDC for GitHub Actions authentication
- ✅ **Encryption at rest** — KMS for EKS secrets, Aurora, CloudTrail logs
- ✅ **Encryption in transit** — TLS 1.2+ enforced on all services
- ✅ **Least privilege IAM** — IRSA for EKS pods, scoped policies
- ✅ **Threat detection** — GuardDuty with S3, Kubernetes, and malware protection
- ✅ **Compliance** — CIS Benchmark v1.4 + AWS Foundational Security Best Practices

[Read full security policy →](SECURITY.md)

---

## 📚 Repository Structure

```
aws-portfolio/
├── projects/
│   └── architect-blueprint/      # Multi-region production architecture
│       ├── modules/              # Reusable Terraform modules
│       ├── main.tf               # Root configuration
│       ├── variables.tf          # Input variables
│       └── README.md             # Project documentation
├── .github/
│   ├── workflows/                # CI/CD pipelines
│   ├── ISSUE_TEMPLATE/           # Issue templates
│   └── PULL_REQUEST_TEMPLATE.md  # PR template
├── SECURITY.md                   # Security policy
├── CODEOWNERS                    # Code ownership
└── README.md                     # This file
```

---

## 💼 Professional Background

I'm a cloud architect specializing in AWS infrastructure and DevOps automation. This portfolio demonstrates hands-on experience with:

- Designing and implementing production-grade AWS architectures
- Writing maintainable, modular Terraform code
- Implementing security best practices and compliance frameworks
- Setting up CI/CD pipelines with GitHub Actions
- Cost optimization and FinOps practices

**Services I provide:**
- ✅ **AWS architecture design & review** (Well-Architected Framework)
- ✅ **Terraform/IaC development** and migration
- ✅ **EKS/Kubernetes deployment** and management
- ✅ **CI/CD pipeline implementation** (GitHub Actions, GitLab CI)
- ✅ **Cloud cost optimization** audits
- ✅ **Security compliance** (CIS, FSBP, SOC 2, HIPAA)

---

## 🤝 Contact & Profiles

- **GitHub:** [@HermannDj](https://github.com/HermannDj)
- **LinkedIn:** [Connect with me](https://linkedin.com/in/hermann-djehoue)
- **Email:** hermann.djehoue@gmail.com

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🌟 Acknowledgments

Built following AWS Well-Architected Framework principles and industry best practices.

---

**⭐ If this portfolio demonstrates the AWS expertise you're looking for, let's connect!**
