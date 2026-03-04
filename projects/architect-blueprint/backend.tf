terraform {
  backend "s3" {
    bucket         = "terraform-state-hermanndj"
    key            = "architect-blueprint/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
    # kms_key_id   = "alias/terraform-state-key"  # Uses SSE-S3 encryption by default
  }
}
