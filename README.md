# 🚀 AWS Portfolio — Terraform Infrastructure

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5.0-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?logo=amazonaws)](https://aws.amazon.com/)
[![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-CI%2FCD-2088FF?logo=githubactions)](https://github.com/features/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> Portfolio AWS Terraform démontrant les compétences d'un **DevOps / Cloud Engineer** niveau intermédiaire à professionnel.
> Tout le code est **plannable sans déploiement réel** et compatible avec l'**AWS Free Tier**.

---

## 📐 Architecture

```
                          ┌─────────────────────────────────────────────┐
                          │                  AWS Cloud                   │
                          │                                              │
                          │   ┌──────────────────────────────────┐      │
                          │   │          VPC (10.0.0.0/16)        │      │
                          │   │                                    │      │
                          │   │  ┌──────────────┐                 │      │
                          │   │  │ Public Subnet │  ┌──────────┐  │      │
                          │   │  │ 10.0.1.0/24  │  │    EC2   │  │      │
                          │   │  │ 10.0.2.0/24  │  │ t2.micro │  │      │
                          │   │  └──────┬───────┘  └────┬─────┘  │      │
                          │   │         │               │          │      │
                          │   │         │    IGW        │          │      │
                          │   │         │               │          │      │
                          │   │  ┌──────┴───────┐       │          │      │
                          │   │  │Private Subnet│       │          │      │
                          │   │  │ 10.0.10.0/24 │       │          │      │
                          │   │  │ 10.0.20.0/24 │       │          │      │
                          │   │  └──────────────┘       │          │      │
                          │   └──────────────────────────────────┘      │
                          │                                              │
                          │   ┌──────────────────┐                       │
                          │   │   S3 Bucket       │                       │
                          │   │  (encrypted,      │                       │
                          │   │   versioned)      │                       │
                          │   └──────────────────┘                       │
                          └─────────────────────────────────────────────┘
                                         │
                                         │ GitHub Actions (OIDC)
                                         │
                          ┌──────────────────────────┐
                          │      GitHub Repository    │
                          │   CI/CD Pipeline           │
                          └──────────────────────────┘
```

---

## 📦 Ressources créées

| Module       | Ressource AWS                     | Description                                  |
|--------------|-----------------------------------|----------------------------------------------|
| networking   | `aws_vpc`                         | VPC principal avec DNS activé                |
| networking   | `aws_subnet` (x4)                 | 2 subnets publics + 2 privés sur 2 AZ        |
| networking   | `aws_internet_gateway`            | Passerelle Internet pour les subnets publics |
| networking   | `aws_nat_gateway` (optionnel)     | NAT Gateway (désactivé par défaut)           |
| networking   | `aws_route_table` (x2)            | Tables de routage publique et privée         |
| ec2          | `aws_instance`                    | Instance EC2 t2.micro avec Apache            |
| ec2          | `aws_security_group`              | Règles de sécurité HTTP/HTTPS/SSH            |
| ec2          | `aws_iam_role`                    | Rôle IAM avec accès SSM                      |
| ec2          | `aws_key_pair` (optionnel)        | Paire de clés SSH                            |
| s3           | `aws_s3_bucket`                   | Bucket S3 avec versioning et chiffrement     |
| s3           | `aws_s3_bucket_versioning`        | Versioning activé                            |
| s3           | `aws_s3_bucket_server_side_encryption_configuration` | Chiffrement AES256 |
| s3           | `aws_s3_bucket_lifecycle_configuration` | Cycle de vie des objets              |
| s3           | `aws_s3_bucket_public_access_block` | Blocage accès public                       |

---

## ✅ Prérequis

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5.0
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) v2
- Un compte AWS (compatible Free Tier)
- Configuration OIDC AWS pour GitHub Actions (voir section dédiée)

---

## 🛠️ Utilisation locale

### 1. Cloner le dépôt

```bash
git clone https://github.com/HermannDj/aws-portfolio.git
cd aws-portfolio
```

### 2. Configurer AWS CLI

```bash
aws configure
# AWS Access Key ID: <votre_access_key>
# AWS Secret Access Key: <votre_secret_key>
# Default region name: us-east-1
# Default output format: json
```

### 3. Initialiser Terraform

```bash
cd terraform
terraform init
```

### 4. Planifier l'infrastructure

```bash
terraform plan -var="environment=dev"
```

### 5. Appliquer l'infrastructure

```bash
terraform apply -var="environment=dev"
```

### 6. Détruire l'infrastructure

```bash
terraform destroy -var="environment=dev"
```

---

## ⚙️ Variables importantes

| Variable               | Type         | Défaut                        | Description                                      |
|------------------------|--------------|-------------------------------|--------------------------------------------------|
| `aws_region`           | `string`     | `"us-east-1"`                 | Région AWS cible                                 |
| `environment`          | `string`     | `"dev"`                       | Environnement (dev/staging/prod)                 |
| `project_name`         | `string`     | `"aws-portfolio"`             | Nom du projet (utilisé dans les tags)            |
| `vpc_cidr`             | `string`     | `"10.0.0.0/16"`               | Bloc CIDR du VPC                                 |
| `public_subnet_cidrs`  | `list(string)` | `["10.0.1.0/24","10.0.2.0/24"]` | CIDRs des subnets publics                    |
| `private_subnet_cidrs` | `list(string)` | `["10.0.10.0/24","10.0.20.0/24"]` | CIDRs des subnets privés                 |
| `ec2_instance_type`    | `string`     | `"t2.micro"`                  | Type d'instance EC2 (Free Tier)                  |
| `s3_bucket_name`       | `string`     | `"app-bucket-hermanndj"`      | Nom du bucket S3                                 |
| `enable_nat_gateway`   | `bool`       | `false`                       | Activer la NAT Gateway (coûts supplémentaires)   |
| `allowed_ssh_cidr`     | `string`     | `"0.0.0.0/0"`                 | CIDR autorisé pour SSH (à restreindre en prod)   |
| `enable_key_pair`      | `bool`       | `false`                       | Créer une paire de clés SSH                      |

---

## 🏗️ Modules

### `networking`
Crée le réseau complet : VPC, subnets publics/privés, Internet Gateway, NAT Gateway (optionnel), tables de routage et associations.

### `ec2`
Déploie une instance EC2 t2.micro avec Amazon Linux 2, Apache préinstallé, groupe de sécurité, rôle IAM SSM et profil d'instance.

### `s3`
Crée un bucket S3 sécurisé avec versioning, chiffrement AES256, blocage accès public, politique HTTPS uniquement et règles de cycle de vie.

---

## 🔒 Configuration OIDC AWS pour GitHub Actions

1. **Créer un Identity Provider OIDC dans IAM AWS** :
   ```bash
   aws iam create-open-id-connect-provider \
     --url https://token.actions.githubusercontent.com \
     --client-id-list sts.amazonaws.com \
     --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
   ```

2. **Créer un rôle IAM avec la trust policy** :
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
         },
         "Action": "sts:AssumeRoleWithWebIdentity",
         "Condition": {
           "StringEquals": {
             "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
             "token.actions.githubusercontent.com:sub": "repo:HermannDj/aws-portfolio:ref:refs/heads/main"
           }
         }
       }
     ]
   }
   ```

3. **Configurer les variables GitHub** :
   - `AWS_ACCOUNT_ID` : votre ID de compte AWS
   - `AWS_REGION` : région cible (ex: `us-east-1`)
   - `TF_VAR_environment` : environnement cible

---

## 💰 Compatibilité Free Tier AWS

| Ressource           | Free Tier                          | Configuration dans ce projet        |
|---------------------|------------------------------------|--------------------------------------|
| EC2 t2.micro        | 750h/mois pendant 12 mois          | ✅ Utilisé par défaut                |
| S3                  | 5 GB de stockage, 20K GET, 2K PUT  | ✅ Utilisé                           |
| Data Transfer       | 15 GB/mois sortant                 | ✅ Trafic minimal                    |
| NAT Gateway         | ❌ Non inclus dans Free Tier        | ✅ Désactivé par défaut (`false`)    |
| Elastic IP          | Gratuit si associé à une instance  | ✅ Uniquement si NAT activé          |

---

## 🔐 Considérations de sécurité

1. **SSH** : Restreindre `allowed_ssh_cidr` à votre IP en production (pas `0.0.0.0/0`)
2. **SSM Session Manager** : Accès sans SSH grâce au rôle IAM SSM (méthode recommandée)
3. **S3** : Accès public complètement bloqué, chiffrement AES256, HTTPS uniquement
4. **Secrets** : Authentification OIDC sans secrets statiques AWS
5. **Tags** : Toutes les ressources sont taguées pour la traçabilité et la facturation
6. **State** : Remote state chiffré dans S3 avec verrou DynamoDB

---

## 📁 Structure du projet

```
aws-portfolio/
├── README.md
├── .github/
│   └── workflows/
│       └── terraform-pipeline.yml
└── terraform/
    ├── backend.tf
    ├── provider.tf
    ├── variables.tf
    ├── outputs.tf
    ├── main.tf
    └── modules/
        ├── networking/
        │   ├── main.tf
        │   ├── variables.tf
        │   └── outputs.tf
        ├── ec2/
        │   ├── main.tf
        │   ├── variables.tf
        │   └── outputs.tf
        └── s3/
            ├── main.tf
            ├── variables.tf
            └── outputs.tf
```

---

## 👤 Auteur

**HermannDj** — DevOps / Cloud Engineer

---

## 📄 Licence

MIT License — voir [LICENSE](LICENSE) pour les détails.
