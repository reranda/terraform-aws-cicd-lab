provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "terraform-aws-cicd-lab"
      ManagedBy = "Terraform"
      Purpose   = "terraform-backend"
    }
  }
}
