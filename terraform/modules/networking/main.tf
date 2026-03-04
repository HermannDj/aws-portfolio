# ─────────────────────────────────────────────────────────────────────────────
# modules/networking/main.tf — Module Réseau AWS
# modules/networking/main.tf — AWS Networking Module
#
# Ce module crée l'infrastructure réseau complète :
# This module creates the complete network infrastructure:
#   - VPC (Virtual Private Cloud)
#   - Subnets publics et privés / Public and private subnets
#   - Internet Gateway (IGW)
#   - NAT Gateway (optionnel / optional)
#   - Tables de routage / Route tables
#   - Associations des tables de routage / Route table associations
# ─────────────────────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────────────────────
# Source de données : Zones de disponibilité AWS disponibles dans la région
# Data source: Available AWS Availability Zones in the region
# Permet de distribuer les subnets sur plusieurs AZ pour la haute disponibilité
# Allows distributing subnets across multiple AZs for high availability
# ─────────────────────────────────────────────────────────────────────────────
data "aws_availability_zones" "available" {
  # Seulement les AZ disponibles (pas celles en état "impaired")
  # Only available AZs (not those in "impaired" state)
  state = "available"
}

# ─────────────────────────────────────────────────────────────────────────────
# VPC — Virtual Private Cloud
# Réseau virtuel isolé dans le cloud AWS
# Isolated virtual network in the AWS cloud
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_vpc" "main" {
  # Bloc CIDR définissant l'espace d'adressage IP du VPC
  # CIDR block defining the IP address space of the VPC
  cidr_block = var.vpc_cidr

  # Activation du support DNS (requis pour les noms d'hôtes EC2)
  # Enable DNS support (required for EC2 hostnames)
  enable_dns_support = true

  # Activation des noms d'hôtes DNS pour les instances EC2
  # Enable DNS hostnames for EC2 instances
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }

  # Empêche la destruction accidentelle du VPC (ressource critique)
  # Prevents accidental destruction of the VPC (critical resource)
  lifecycle {
    prevent_destroy = false # Mettre à true en production / Set to true in production
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Subnets publics — Accessibles depuis Internet
# Public subnets — Accessible from the Internet
# Les instances dans ces subnets reçoivent une IP publique automatiquement
# Instances in these subnets automatically receive a public IP
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_subnet" "public" {
  # Créer un subnet par CIDR fourni / Create one subnet per provided CIDR
  count = length(var.public_subnet_cidrs)

  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidrs[count.index]

  # Distribution sur les zones de disponibilité disponibles
  # Distribution across available availability zones
  # L'opérateur modulo (%) permet de cycler si plus de subnets que d'AZ
  # The modulo operator (%) allows cycling if more subnets than AZs
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]

  # Assigner automatiquement une IP publique aux instances lancées dans ce subnet
  # Automatically assign a public IP to instances launched in this subnet
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-public-subnet-${count.index + 1}"
    Type = "Public"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Subnets privés — Non accessibles directement depuis Internet
# Private subnets — Not directly accessible from the Internet
# Les instances dans ces subnets n'ont pas d'IP publique
# Instances in these subnets do not have a public IP
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_subnet" "private" {
  # Créer un subnet par CIDR fourni / Create one subnet per provided CIDR
  count = length(var.private_subnet_cidrs)

  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidrs[count.index]

  # Distribution sur les zones de disponibilité disponibles
  # Distribution across available availability zones
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]

  # Pas d'IP publique pour les subnets privés
  # No public IP for private subnets
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${var.environment}-private-subnet-${count.index + 1}"
    Type = "Private"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Internet Gateway — Passerelle vers Internet
# Internet Gateway — Gateway to the Internet
# Permet aux ressources du VPC d'accéder à Internet et d'être accessibles
# Allows VPC resources to access the Internet and be accessible
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_internet_gateway" "main" {
  # Attacher l'IGW au VPC principal / Attach IGW to the main VPC
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Elastic IP pour la NAT Gateway (conditionnel)
# Elastic IP for NAT Gateway (conditional)
# Une IP fixe publique requise par la NAT Gateway
# A fixed public IP required by the NAT Gateway
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_eip" "nat" {
  # Créer seulement si la NAT Gateway est activée / Create only if NAT Gateway is enabled
  count = var.enable_nat_gateway ? 1 : 0

  # L'EIP est dans le domaine VPC (pas "standard")
  # EIP is in VPC domain (not "standard")
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-eip"
  }

  # L'EIP doit être créée après l'IGW
  # EIP must be created after the IGW
  depends_on = [aws_internet_gateway.main]
}

# ─────────────────────────────────────────────────────────────────────────────
# NAT Gateway (conditionnel)
# NAT Gateway (conditional)
# Permet aux ressources des subnets privés d'accéder à Internet (sortant seulement)
# Allows resources in private subnets to access the Internet (outbound only)
# ATTENTION : ~$32/mois de coût ! Désactivé par défaut.
# WARNING: ~$32/month cost! Disabled by default.
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_nat_gateway" "main" {
  # Créer seulement si activée / Create only if enabled
  count = var.enable_nat_gateway ? 1 : 0

  # L'Elastic IP associée à cette NAT Gateway
  # The Elastic IP associated with this NAT Gateway
  allocation_id = aws_eip.nat[0].id

  # La NAT Gateway doit être dans un subnet PUBLIC pour accéder à Internet
  # NAT Gateway must be in a PUBLIC subnet to access the Internet
  subnet_id = aws_subnet.public[0].id

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-gw"
  }

  # La NAT Gateway nécessite l'IGW / NAT Gateway requires IGW
  depends_on = [aws_internet_gateway.main]
}

# ─────────────────────────────────────────────────────────────────────────────
# Table de routage publique
# Public route table
# Dirige le trafic sortant vers Internet via l'IGW
# Routes outbound traffic to the Internet via IGW
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # Route par défaut : tout le trafic (0.0.0.0/0) va vers l'Internet Gateway
  # Default route: all traffic (0.0.0.0/0) goes to the Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
    Type = "Public"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Table de routage privée (avec NAT Gateway si activée)
# Private route table (with NAT Gateway if enabled)
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  # Route vers Internet via NAT Gateway si activée
  # Route to Internet via NAT Gateway if enabled
  # La NAT Gateway permet un accès sortant sans exposer les instances privées
  # NAT Gateway allows outbound access without exposing private instances
  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-private-rt"
    Type = "Private"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Associations table de routage publique ↔ subnets publics
# Public route table ↔ public subnets associations
# Chaque subnet public doit être associé à la table de routage publique
# Each public subnet must be associated with the public route table
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ─────────────────────────────────────────────────────────────────────────────
# Associations table de routage privée ↔ subnets privés
# Private route table ↔ private subnets associations
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
