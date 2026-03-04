# AWS Portfolio – IaC Reference Projects

> **AWS Architect / DevOps portfolio demonstrating production-quality Infrastructure-as-Code
> for serverless and container workloads on AWS (region: `ca-central-1`).**

[![Terraform Lint & Plan](https://github.com/HermannDj/aws-portfolio/actions/workflows/terraform-pr.yml/badge.svg)](https://github.com/HermannDj/aws-portfolio/actions/workflows/terraform-pr.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## Table of Contents

- [Overview](#overview)
- [Repository Layout](#repository-layout)
- [Projects](#projects)
  - [1 · Serverless API](#1--serverless-api)
  - [2 · EKS Blueprint](#2--eks-blueprint)
- [Toolchain & Prerequisites](#toolchain--prerequisites)
- [Common Conventions](#common-conventions)
- [GitHub Actions CI/CD](#github-actions-cicd)
- [Security & Cost Notes](#security--cost-notes)
- [License](#license)

---

## Overview

This repository contains two fully-deployable Terraform projects targeting **AWS `ca-central-1`**.
Each project is self-contained under `projects/` with its own `README.md`, pinned provider
versions, variable validations, IAM least-privilege policies, and destroy instructions.

| # | Project | Key Services | Estimated Cost |
|---|---------|-------------|----------------|
| 1 | [Serverless API](projects/serverless-api/) | API Gateway · Lambda (Python) · DynamoDB · CloudWatch | ~$0–2 / month (free-tier eligible) |
| 2 | [EKS Blueprint](projects/eks-blueprint/) | VPC · EKS · Managed Node Group · ALB Controller | ~$150–200 / month – **destroy when done** |

---

## Repository Layout

```
aws-portfolio/
├── .editorconfig
├── .gitignore
├── .pre-commit-config.yaml      # pre-commit hooks (fmt, validate, tflint, checkov)
├── .tflint.hcl                  # tflint configuration
├── LICENSE
├── README.md                    # ← you are here
├── .github/
│   └── workflows/
│       ├── terraform-pr.yml     # PR gate: fmt · validate · tflint · checkov · plan
│       └── terraform-apply.yml  # Manual apply (workflow_dispatch)
└── projects/
    ├── serverless-api/          # Project 1
    └── eks-blueprint/           # Project 2
```

---

## Projects

### 1 · Serverless API

**Path:** [`projects/serverless-api/`](projects/serverless-api/)

A production-ready REST API built with:

- **API Gateway** (REST, regional) – CRUD endpoints
- **AWS Lambda** (Python 3.12) – business logic with X-Ray tracing
- **DynamoDB** – on-demand, point-in-time recovery enabled
- **IAM** – least-privilege execution role (no wildcards)
- **CloudWatch** – log group with 14-day retention + Lambda Insights

👉 See [projects/serverless-api/README.md](projects/serverless-api/README.md) for full
deploy / destroy instructions.

---

### 2 · EKS Blueprint

**Path:** [`projects/eks-blueprint/`](projects/eks-blueprint/)

An enterprise-style EKS cluster built with:

- **VPC** – 3-AZ public/private subnet layout with NAT gateway
- **EKS 1.29** – managed node group (t3.medium, auto-scaling)
- **OIDC / IRSA** – per-service-account IAM roles
- **AWS Load Balancer Controller** – deployed via Helm with IRSA
- **Sample workload** – nginx Deployment + Service + Ingress (ALB)

> ⚠️ **Cost warning:** EKS control plane + EC2 nodes cost ~$150–200/month.
> Always run `terraform destroy` after your demo.

👉 See [projects/eks-blueprint/README.md](projects/eks-blueprint/README.md) for full
deploy / destroy instructions.

---

## Toolchain & Prerequisites

| Tool | Minimum Version | Install |
|------|----------------|---------|
| [Terraform](https://developer.hashicorp.com/terraform/downloads) | 1.7.x | `brew install terraform` |
| [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) | 2.x | `brew install awscli` |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | 1.29.x | `brew install kubectl` |
| [Helm](https://helm.sh/docs/intro/install/) | 3.x | `brew install helm` |
| [tflint](https://github.com/terraform-linters/tflint) | 0.50.x | `brew install tflint` |
| [checkov](https://www.checkov.io/) | 3.x | `pip install checkov` |
| [pre-commit](https://pre-commit.com/) | 3.x | `pip install pre-commit` |

### AWS credentials

```bash
# Configure a named profile
aws configure --profile aws-portfolio
export AWS_PROFILE=aws-portfolio
export AWS_DEFAULT_REGION=ca-central-1

# Verify
aws sts get-caller-identity
```

### Enable pre-commit hooks (optional but recommended)

```bash
pre-commit install
```

---

## Common Conventions

### Tagging strategy

Every resource receives the following tags (enforced via `locals`):

```hcl
tags = {
  Project     = var.project_name
  Environment = var.environment
  ManagedBy   = "Terraform"
  Owner       = var.owner
  Region      = var.aws_region
}
```

### Naming convention

```
<project_name>-<environment>-<resource_type>
# e.g. serverless-api-dev-lambda
#      eks-blueprint-prod-cluster
```

### Variable validations

All input variables include `validation` blocks to catch misconfiguration early
(e.g. environment must be `dev | staging | prod`).

---

## GitHub Actions CI/CD

Both workflow files live in **this repository** (`HermannDj/aws-portfolio`) under
`.github/workflows/` and run directly against its `projects/` tree.

### PR Gate (`terraform-pr.yml`)

Triggered on every pull request that touches `projects/**`:

1. `terraform fmt -check` – enforces code style
2. `terraform validate` – syntax + provider check
3. `tflint` – opinionated lint rules
4. `checkov` – security/compliance scan (threshold: MEDIUM+)
5. `terraform plan` – creates a plan and posts it as a PR comment (no apply)

### Manual Apply (`terraform-apply.yml`)

Triggered via **Actions → terraform-apply → Run workflow**.

Inputs:
- `project` – which project to apply (`serverless-api` or `eks-blueprint`)
- `environment` – target environment (`dev`, `staging`, `prod`)
- `action` – `plan`, `apply`, or `destroy`

> **Note:** Requires `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` (or OIDC role)
> configured as repository secrets.

### Action Dependencies

The workflows are built on the following publicly maintained GitHub Actions:

| Action | Source Repository | Used in |
|--------|-------------------|---------|
| `actions/checkout@v4` | <https://github.com/actions/checkout> | both workflows |
| `hashicorp/setup-terraform@v3` | <https://github.com/hashicorp/setup-terraform> | both workflows |
| `aws-actions/configure-aws-credentials@v4` | <https://github.com/aws-actions/configure-aws-credentials> | both workflows |
| `terraform-linters/setup-tflint@v4` | <https://github.com/terraform-linters/setup-tflint> | `terraform-pr.yml` |
| `actions/setup-python@v5` | <https://github.com/actions/setup-python> | `terraform-pr.yml` |
| `actions/github-script@v7` | <https://github.com/actions/github-script> | `terraform-pr.yml` |

---

## Security & Cost Notes

- All S3 state buckets (if used) should have versioning + encryption enabled.
- No wildcard IAM actions or resources are used in any project.
- DynamoDB encryption at rest is enabled by default.
- EKS secrets are encrypted via a customer-managed KMS key.
- **Never commit `.tfvars` files** containing real account IDs or secrets.

---

## License

[MIT](LICENSE) © 2024 HermannDj
