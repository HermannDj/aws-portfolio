# Project 1 – Serverless API

> **AWS Serverless REST API** – API Gateway + Lambda (Python 3.12) + DynamoDB
> Region: `ca-central-1` | IaC: Terraform 1.7+

---

## Architecture

```
Client
  │
  ▼
Amazon API Gateway (REST, Regional)
  │   GET /items  POST /items
  │   GET /items/{id}  PUT /items/{id}  DELETE /items/{id}
  ▼
AWS Lambda  (Python 3.12, X-Ray active tracing)
  │
  ▼
Amazon DynamoDB  (on-demand, SSE, PITR)
  │
  ▼
Amazon CloudWatch Logs  (14-day retention)
```

### Key design decisions

| Concern | Decision |
|---------|----------|
| IAM | Least-privilege role – only the exact DynamoDB actions required; no wildcard resources |
| Observability | X-Ray tracing on Lambda + API Gateway; structured JSON access logs |
| Data durability | DynamoDB point-in-time recovery (PITR) enabled |
| Encryption | DynamoDB SSE enabled (AWS-managed key) |
| Cost | On-demand billing – no idle cost; free-tier eligible for low traffic |

---

## Cost Estimate

| Service | Free Tier | Cost above free tier |
|---------|-----------|----------------------|
| Lambda | 1M requests + 400K GB-s / month | ~$0.20 per 1M requests |
| API Gateway | 1M calls / month (first 12 months) | ~$3.50 per 1M calls |
| DynamoDB | 25 GB storage + 25 RCU/WCU | On-demand: ~$1.25 per 1M writes |
| CloudWatch Logs | 5 GB ingestion / month | ~$0.50 per GB |

**Estimated monthly cost for a demo workload: $0–$2.** This project is safe to leave running.

---

## Prerequisites

- Terraform ≥ 1.7
- AWS CLI v2 configured with sufficient permissions
- Python 3.12 (to run the Lambda locally)

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
cd projects/serverless-api

# 2. Initialise Terraform (downloads providers, sets up state)
terraform init

# 3. Preview changes
terraform plan -var="environment=dev"

# 4. Apply
terraform apply -var="environment=dev" -auto-approve
```

After a successful apply Terraform prints the API URL:

```
Outputs:

api_base_url                 = "https://<id>.execute-api.ca-central-1.amazonaws.com/dev/items"
dynamodb_table_name          = "serverless-api-dev-items"
lambda_function_name         = "serverless-api-dev"
cloudwatch_log_group_lambda  = "/aws/lambda/serverless-api-dev"
```

---

## Smoke Test

```bash
BASE_URL=$(terraform output -raw api_base_url)

# Create an item
curl -sX POST "$BASE_URL" \
  -H "Content-Type: application/json" \
  -d '{"name":"test-item","value":42}' | jq .

# List items
curl -s "$BASE_URL" | jq .

# Get a specific item  (replace <id> with the id returned above)
curl -s "$BASE_URL/<id>" | jq .

# Update an item
curl -sX PUT "$BASE_URL/<id>" \
  -H "Content-Type: application/json" \
  -d '{"value":99}' | jq .

# Delete an item
curl -sX DELETE "$BASE_URL/<id>" | jq .
```

---

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `ca-central-1` | AWS region |
| `project_name` | `serverless-api` | Resource name prefix |
| `environment` | `dev` | Deployment environment (`dev\|staging\|prod`) |
| `owner` | `platform-team` | Owner tag value |
| `log_retention_days` | `14` | CloudWatch log retention (days) |
| `lambda_memory_mb` | `256` | Lambda memory (128–10 240 MB) |
| `lambda_timeout_seconds` | `30` | Lambda timeout (1–900 s) |
| `dynamodb_billing_mode` | `PAY_PER_REQUEST` | DynamoDB billing mode |

---

## Outputs

| Output | Description |
|--------|-------------|
| `api_base_url` | Invoke URL for `/items` |
| `api_id` | API Gateway REST API ID |
| `lambda_function_name` | Lambda function name |
| `lambda_function_arn` | Lambda function ARN |
| `dynamodb_table_name` | DynamoDB table name |
| `dynamodb_table_arn` | DynamoDB table ARN |
| `cloudwatch_log_group_lambda` | Lambda log group name |

---

## Observability

### Lambda logs

```bash
aws logs tail "/aws/lambda/serverless-api-dev" --follow --format short
```

### X-Ray traces

Open the [AWS X-Ray console](https://ca-central-1.console.aws.amazon.com/xray/home?region=ca-central-1)
→ Traces → filter by `serviceName = "serverless-api-dev"`.

### API Gateway access logs

```bash
aws logs tail "/aws/apigateway/serverless-api-dev" --follow --format short
```

---

## Destroy

```bash
cd projects/serverless-api
terraform destroy -var="environment=dev" -auto-approve
```

> All resources (Lambda, API Gateway, DynamoDB table, IAM role, CloudWatch log groups)
> will be permanently deleted.

---

## File Structure

```
projects/serverless-api/
├── versions.tf      # Terraform + provider version pins
├── variables.tf     # Input variables with validations
├── main.tf          # DynamoDB, Lambda, API Gateway, CloudWatch
├── iam.tf           # IAM role + least-privilege policy
├── outputs.tf       # Terraform outputs
└── lambda/
    └── handler.py   # Python 3.12 CRUD handler
```
