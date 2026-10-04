variable "aws_region" {
  description = "AWS region for the lab resources."
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "Name used to identify the lab resources."
  type        = string
  default     = "terraform-aws-cicd-lab"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test"], var.environment)
    error_message = "environment must be either dev or test."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the lab VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "bucket_name" {
  description = "Globally unique name for the lab S3 data bucket."
  type        = string

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "bucket_name must be between 3 and 63 characters."
  }
}
