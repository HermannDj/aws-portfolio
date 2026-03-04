# Security Policy

## Reporting Security Issues

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to the repository owner (see profile).

You should receive a response within 48 hours.

## Security Best Practices Implemented

This repository follows AWS security best practices:

- ✅ No hardcoded credentials (OIDC authentication for GitHub Actions)
- ✅ Encryption at rest (KMS for EKS secrets, Aurora, CloudTrail logs)
- ✅ Encryption in transit (TLS 1.2+ enforced on all services)
- ✅ Least privilege IAM policies (IRSA for EKS pods)
- ✅ GuardDuty threat detection (S3, Kubernetes, malware protection)
- ✅ Security Hub compliance checks (CIS Benchmark v1.4, FSBP)
- ✅ CloudTrail audit logging (multi-region, log file validation)
- ✅ VPC Flow Logs enabled
- ✅ WAF v2 with OWASP managed rules

## Secrets Management

GitHub Secrets used in this repository:
- `AWS_ROLE_ARN` — IAM role ARN for OIDC authentication (no static credentials)
- `TF_STATE_BUCKET` — S3 bucket name for Terraform remote state
- `TF_LOCK_TABLE` — DynamoDB table name for Terraform state locking
- `DOMAIN_NAME` — Route53 hosted zone domain name (optional)

**Never commit secrets or credentials to this repository.**

## Compliance

This architecture is designed to meet:
- CIS AWS Foundations Benchmark v1.4
- AWS Foundational Security Best Practices (FSBP)

For production workloads, additional controls may be required depending on your
compliance framework (HIPAA, PCI DSS, SOC 2, etc.).
