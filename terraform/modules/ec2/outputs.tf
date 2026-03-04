# ─────────────────────────────────────────────────────────────────────────────
# modules/ec2/outputs.tf — Sorties du module EC2
# modules/ec2/outputs.tf — EC2 module outputs
# ─────────────────────────────────────────────────────────────────────────────

output "instance_id" {
  description = "Identifiant de l'instance EC2 / EC2 instance identifier"
  value       = aws_instance.main.id
}

output "public_ip" {
  description = "Adresse IP publique de l'instance EC2 / Public IP address of the EC2 instance"
  value       = aws_instance.main.public_ip
}

output "public_dns" {
  description = "Nom DNS public de l'instance EC2 / Public DNS name of the EC2 instance"
  value       = aws_instance.main.public_dns
}

output "private_ip" {
  description = "Adresse IP privée de l'instance EC2 / Private IP address of the EC2 instance"
  value       = aws_instance.main.private_ip
}

output "security_group_id" {
  description = "Identifiant du groupe de sécurité EC2 / EC2 security group identifier"
  value       = aws_security_group.ec2.id
}

output "iam_role_arn" {
  description = "ARN du rôle IAM de l'instance EC2 / ARN of the EC2 instance IAM role"
  value       = aws_iam_role.ec2.arn
}

output "iam_instance_profile_name" {
  description = "Nom du profil d'instance IAM / IAM instance profile name"
  value       = aws_iam_instance_profile.ec2.name
}

output "ami_id" {
  description = "Identifiant de l'AMI utilisée / AMI identifier used"
  value       = data.aws_ami.amazon_linux_2.id
}
