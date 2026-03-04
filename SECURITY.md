# Security Policy

## Reporting Security Issues

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to: hermann.djehoue@gmail.com

You should receive a response within 48 hours.

## Security Best Practices Implemented

This repository follows AWS security best practices:

- ✅ No hardcoded credentials (OIDC authentication)
- ✅ Encryption at rest (KMS for EKS, Aurora, CloudTrail)
- ✅ Encryption in transit (TLS 1.2+)
- ✅ Least privilege IAM policies
- ✅ GuardDuty threat detection
- ✅ Security Hub compliance checks (CIS, FSBP)
- ✅ CloudTrail audit logging
- ✅ VPC Flow Logs enabled

## Secrets Management

GitHub Secrets used in this repository:
- `AWS_ROLE_ARN` — IAM role ARN for OIDC authentication
- `TF_STATE_BUCKET` — S3 bucket for Terraform state
- `TF_LOCK_TABLE` — DynamoDB table for state locking
- `DOMAIN_NAME` — Route53 domain (optional)

**Never commit secrets to this repository.**

## Compliance

This architecture is designed to meet:
- CIS AWS Foundations Benchmark v1.4
- AWS Foundational Security Best Practices (FSBP)

For production use, additional controls may be required depending on your compliance framework (HIPAA, PCI DSS, SOC 2, etc.).