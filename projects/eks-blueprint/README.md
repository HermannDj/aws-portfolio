# Project 2 – EKS Blueprint

> **Enterprise-style Amazon EKS cluster** – VPC + EKS 1.29 + managed node group + IRSA
> + AWS Load Balancer Controller + sample workload
> Region: `ca-central-1` | IaC: Terraform 1.7+

---

## ⚠️ Cost Warning

> **This project is NOT free-tier eligible.**
>
> | Resource | Estimated cost |
> |----------|---------------|
> | EKS control plane | ~$72/month |
> | 2× t3.medium nodes (on-demand) | ~$60/month |
> | NAT Gateway | ~$32/month |
> | ALB (sample ingress) | ~$18/month |
> | CloudWatch Logs | ~$2/month |
> | **Total estimate** | **~$180/month** |
>
> **Always run `terraform destroy` after your demo to avoid unexpected charges.**

---

## Architecture

```
                        ┌──────────────────────────────────────────┐
                        │  VPC  10.0.0.0/16  (ca-central-1)        │
                        │                                          │
                        │  ┌─────────────┐  ┌─────────────┐       │
Internet ──► IGW ──────►│  │ Public AZ-a │  │ Public AZ-b │  …    │
                        │  └──────┬──────┘  └─────────────┘       │
                        │         │ NAT GW                         │
                        │  ┌──────▼──────┐  ┌─────────────┐       │
                        │  │Private AZ-a │  │Private AZ-b │  …    │
                        │  │  EKS nodes  │  │  EKS nodes  │       │
                        │  └─────────────┘  └─────────────┘       │
                        └──────────────────────────────────────────┘
                                     │
                              EKS Control Plane
                              (AWS-managed)
                                     │
                         ┌───────────┴───────────┐
                         │  Kubernetes Workloads  │
                         │                        │
                         │  Namespace: kube-system│
                         │  ├─ aws-lbc (Helm)     │
                         │                        │
                         │  Namespace: sample-app │
                         │  ├─ nginx Deployment   │
                         │  ├─ NodePort Service   │
                         │  └─ Ingress (ALB)      │
                         └────────────────────────┘
                                      │
                               Internet-facing ALB
                                      │
                                   Browser
```

### Key design decisions

| Concern | Decision |
|---------|----------|
| Network isolation | Nodes in private subnets; single NAT GW for cost (use one per AZ for HA) |
| Secrets encryption | Customer-managed KMS key for EKS secrets |
| IRSA | OIDC provider + federated trust for LBC service account |
| IAM | AWS-managed policies for cluster/node roles; scoped inline for LBC |
| Ingress | AWS Load Balancer Controller with ALB in internet-facing mode |
| Observability | All five EKS log types forwarded to CloudWatch (30-day retention) |
| Scalability | Managed node group with auto-scaling (1–4 nodes) |

---

## Prerequisites

- Terraform ≥ 1.7
- AWS CLI v2 + profile with EKS/VPC/IAM/EC2 permissions
- kubectl ≥ 1.29
- Helm ≥ 3.x

```bash
aws configure --profile aws-portfolio
export AWS_PROFILE=aws-portfolio
export AWS_DEFAULT_REGION=ca-central-1
aws sts get-caller-identity   # verify
```

---

## Deploy

```bash
# 1. Navigate to the project directory
cd projects/eks-blueprint

# 2. Initialise Terraform
terraform init

# 3. Preview changes (takes ~3-5 seconds)
terraform plan -var="environment=dev"

# 4. Apply  ← ~15-20 minutes
terraform apply -var="environment=dev" -auto-approve
```

### Update kubeconfig

```bash
# Output from terraform:
$(terraform output -raw kubeconfig_command)

# Verify connectivity
kubectl get nodes
kubectl get pods -n kube-system
kubectl get pods -n sample-app
```

### Access the sample application

```bash
# Wait for the ALB to be provisioned (~3-5 minutes)
kubectl get ingress -n sample-app -w

# Copy the ADDRESS column value, then:
curl http://<ALB_HOSTNAME>/
# You should see the nginx welcome page
```

---

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `ca-central-1` | AWS region |
| `project_name` | `eks-blueprint` | Resource name prefix |
| `environment` | `dev` | Deployment environment (`dev\|staging\|prod`) |
| `owner` | `platform-team` | Owner tag value |
| `vpc_cidr` | `10.0.0.0/16` | VPC CIDR block |
| `kubernetes_version` | `1.29` | EKS Kubernetes version |
| `node_instance_type` | `t3.medium` | EC2 instance type for nodes |
| `node_desired_size` | `2` | Desired node count |
| `node_min_size` | `1` | Minimum node count |
| `node_max_size` | `4` | Maximum node count |
| `node_disk_size_gb` | `20` | Node root volume size (GB) |
| `lbc_chart_version` | `1.7.2` | AWS LBC Helm chart version |
| `log_retention_days` | `30` | CloudWatch log retention (days) |

---

## Outputs

| Output | Description |
|--------|-------------|
| `vpc_id` | VPC ID |
| `public_subnet_ids` | Public subnet IDs |
| `private_subnet_ids` | Private subnet IDs |
| `eks_cluster_name` | EKS cluster name |
| `eks_cluster_endpoint` | API server endpoint |
| `eks_cluster_version` | Kubernetes version |
| `eks_oidc_provider_arn` | OIDC provider ARN |
| `lbc_iam_role_arn` | Load Balancer Controller IRSA role ARN |
| `kubeconfig_command` | AWS CLI command to update kubeconfig |
| `sample_ingress_hostname` | ALB hostname for the sample workload |

---

## Observability

### Cluster logs (CloudWatch)

```bash
# API server logs
aws logs tail "/aws/eks/eks-blueprint-dev/cluster" --follow --format short
```

### Node metrics (CloudWatch Container Insights)

Enable in the EKS console → Observability → Enable Container Insights.

### kubectl diagnostics

```bash
kubectl get events -n sample-app --sort-by='.lastTimestamp'
kubectl describe ingress sample-nginx -n sample-app
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

---

## ⚠️ Destroy

```bash
cd projects/eks-blueprint

# Step 1: Remove Kubernetes resources first to allow ALB cleanup
kubectl delete ingress sample-nginx -n sample-app
# Wait ~2 minutes for ALB to be deleted

# Step 2: Destroy all Terraform-managed resources
terraform destroy -var="environment=dev" -auto-approve
```

> **Important:** Always delete the Ingress resource before running `terraform destroy`
> to ensure the ALB created by the AWS Load Balancer Controller is properly cleaned up.
> Leaving it will result in dangling resources not managed by Terraform.

---

## File Structure

```
projects/eks-blueprint/
├── versions.tf      # Terraform + provider version pins
├── variables.tf     # Input variables with validations
├── vpc.tf           # VPC, subnets, IGW, NAT, route tables
├── eks.tf           # EKS cluster, node group, KMS, IAM roles, security groups
├── irsa.tf          # OIDC provider + IRSA role for AWS LBC
├── main.tf          # Helm release (LBC), sample workload, ingress
└── outputs.tf       # Terraform outputs
```
