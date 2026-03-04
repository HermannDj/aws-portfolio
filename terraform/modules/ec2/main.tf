# ─────────────────────────────────────────────────────────────────────────────
# modules/ec2/main.tf — Module EC2
# modules/ec2/main.tf — EC2 Module
#
# Ce module crée :
# This module creates:
#   - Source de données AMI Amazon Linux 2 / Amazon Linux 2 AMI data source
#   - Groupe de sécurité (HTTP, HTTPS, SSH) / Security Group (HTTP, HTTPS, SSH)
#   - Rôle IAM + Profil d'instance avec accès SSM / IAM Role + Instance Profile with SSM access
#   - Instance EC2 t2.micro (Free Tier) / EC2 t2.micro instance (Free Tier)
#   - Paire de clés SSH (optionnel) / SSH Key Pair (optional)
# ─────────────────────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────────────────────
# Source de données : AMI Amazon Linux 2
# Data source: Amazon Linux 2 AMI
# Récupère dynamiquement la dernière version d'Amazon Linux 2
# Dynamically fetches the latest version of Amazon Linux 2
# ─────────────────────────────────────────────────────────────────────────────
data "aws_ami" "amazon_linux_2" {
  # Utiliser l'AMI la plus récente disponible
  # Use the most recent available AMI
  most_recent = true

  # Filtrer par nom pour Amazon Linux 2 (HVM avec GP2)
  # Filter by name for Amazon Linux 2 (HVM with GP2)
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  # Filtrer par type de virtualisation (HVM = Hardware Virtual Machine)
  # Filter by virtualization type (HVM = Hardware Virtual Machine)
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  # Filtrer par état : seulement les AMIs disponibles
  # Filter by state: only available AMIs
  filter {
    name   = "state"
    values = ["available"]
  }

  # Propriétaire officiel Amazon (évite les AMIs tierces non fiables)
  # Official Amazon owner (avoids unreliable third-party AMIs)
  owners = ["amazon"]
}

# ─────────────────────────────────────────────────────────────────────────────
# Groupe de sécurité
# Security Group
# Contrôle le trafic entrant et sortant de l'instance EC2
# Controls inbound and outbound traffic for the EC2 instance
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-${var.environment}-ec2-sg"
  description = "Security Group for EC2 instance - allows HTTP, HTTPS, SSH"
  vpc_id      = var.vpc_id

  # ─── Règle entrante : HTTP (port 80) ──────────────────────────────────────
  # Inbound rule: HTTP (port 80)
  # Permet l'accès au serveur web Apache depuis n'importe où
  # Allows access to Apache web server from anywhere
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ─── Règle entrante : HTTPS (port 443) ────────────────────────────────────
  # Inbound rule: HTTPS (port 443)
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ─── Règle entrante : SSH (port 22) ───────────────────────────────────────
  # Inbound rule: SSH (port 22)
  # IMPORTANT : Restreindre à votre IP en production (pas 0.0.0.0/0)
  # IMPORTANT: Restrict to your IP in production (not 0.0.0.0/0)
  ingress {
    description = "SSH access - restrict CIDR in production!"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # ─── Règle sortante : Tout le trafic ──────────────────────────────────────
  # Outbound rule: All traffic
  # Permet à l'instance d'accéder à Internet (téléchargements, mises à jour)
  # Allows the instance to access the Internet (downloads, updates)
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 = tous les protocoles / all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-sg"
  }

  # Si on détruit et recrée le SG, créer le nouveau avant de détruire l'ancien
  # If destroying and recreating the SG, create new before destroying old
  lifecycle {
    create_before_destroy = true
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Rôle IAM pour l'instance EC2
# IAM Role for the EC2 instance
# Permet à l'instance d'assumer des permissions AWS sans credentials statiques
# Allows the instance to assume AWS permissions without static credentials
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_iam_role" "ec2" {
  name        = "${var.project_name}-${var.environment}-ec2-role"
  description = "IAM role for EC2 instance with SSM access"

  # Trust policy : définit qui peut assumer ce rôle (ici, les instances EC2)
  # Trust policy: defines who can assume this role (here, EC2 instances)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-role"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Attachement de la policy SSM au rôle IAM
# SSM policy attachment to IAM role
# AmazonSSMManagedInstanceCore permet d'accéder à l'instance via SSM Session Manager
# AmazonSSMManagedInstanceCore allows accessing the instance via SSM Session Manager
# C'est une alternative plus sécurisée à SSH
# This is a more secure alternative to SSH
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ─────────────────────────────────────────────────────────────────────────────
# Profil d'instance IAM
# IAM Instance Profile
# Le profil d'instance est le "conteneur" qui associe le rôle IAM à l'instance EC2
# The instance profile is the "container" that associates the IAM role with the EC2 instance
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# ─────────────────────────────────────────────────────────────────────────────
# Paire de clés SSH (optionnel)
# SSH Key Pair (optional)
# Désactivé par défaut — utiliser SSM Session Manager à la place
# Disabled by default — use SSM Session Manager instead
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_key_pair" "main" {
  # Créer seulement si explicitement demandé et si une clé est fournie
  # Create only if explicitly requested and a key is provided
  count = var.enable_key_pair && var.public_key_material != "" ? 1 : 0

  key_name   = "${var.project_name}-${var.environment}-key"
  public_key = var.public_key_material

  tags = {
    Name = "${var.project_name}-${var.environment}-key"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Instance EC2
# EC2 Instance
# Instance t2.micro éligible au Free Tier avec Apache préinstallé via user_data
# t2.micro Free Tier eligible instance with Apache pre-installed via user_data
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_instance" "main" {
  # AMI récupérée dynamiquement (Amazon Linux 2)
  # Dynamically fetched AMI (Amazon Linux 2)
  ami = data.aws_ami.amazon_linux_2.id

  # Type d'instance Free Tier / Free Tier instance type
  instance_type = var.instance_type

  # Subnet dans lequel déployer l'instance (subnet public)
  # Subnet in which to deploy the instance (public subnet)
  subnet_id = var.subnet_id

  # Associer une IP publique (défini par le subnet, mais explicite ici)
  # Associate a public IP (defined by subnet, but explicit here)
  associate_public_ip_address = true

  # Associer le groupe de sécurité / Associate the security group
  vpc_security_group_ids = [aws_security_group.ec2.id]

  # Associer le profil d'instance IAM pour l'accès SSM
  # Associate the IAM instance profile for SSM access
  iam_instance_profile = aws_iam_instance_profile.ec2.name

  # Associer la paire de clés SSH si elle est créée
  # Associate SSH key pair if it is created
  key_name = var.enable_key_pair && var.public_key_material != "" ? aws_key_pair.main[0].key_name : null

  # Script d'initialisation exécuté au premier démarrage de l'instance
  # Initialization script executed on first startup of the instance
  # Installe et démarre Apache HTTP Server (serveur web)
  # Installs and starts Apache HTTP Server (web server)
  user_data = <<-EOF
    #!/bin/bash
    # Mise à jour du système / System update
    yum update -y

    # Installation d'Apache HTTP Server / Install Apache HTTP Server
    yum install -y httpd

    # Démarrage du service Apache / Start Apache service
    systemctl start httpd

    # Activer Apache au démarrage du système / Enable Apache at system startup
    systemctl enable httpd

    # Créer une page d'accueil simple / Create a simple welcome page
    cat > /var/www/html/index.html << 'HTML'
    <!DOCTYPE html>
    <html>
    <head><title>AWS Portfolio - HermannDj</title></head>
    <body>
      <h1>🚀 AWS Portfolio</h1>
      <p>Infrastructure déployée avec Terraform par HermannDj</p>
      <p>Infrastructure deployed with Terraform by HermannDj</p>
      <p>Environment: ${var.environment}</p>
    </body>
    </html>
    HTML

    # Installer l'agent SSM pour SSM Session Manager / Install SSM agent for SSM Session Manager
    yum install -y amazon-ssm-agent
    systemctl start amazon-ssm-agent
    systemctl enable amazon-ssm-agent
  EOF

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2"
  }

  # Dépendances explicites pour s'assurer que le réseau est prêt
  # Explicit dependencies to ensure the network is ready
  depends_on = [
    aws_iam_role_policy_attachment.ssm,
    aws_iam_instance_profile.ec2
  ]

  # Options de cycle de vie
  # Lifecycle options
  lifecycle {
    # Ignorer les changements d'AMI lors des futures mises à jour
    # (evite les remplacements d'instances lors des nouvelles AMIs)
    # Ignore AMI changes during future updates
    # (avoids instance replacements when new AMIs are released)
    ignore_changes = [ami, user_data]
  }
}
