variable "aws_region" {
  description = "AWS region in which the Terraform backend bucket will be created."
  type        = string
  default     = "eu-west-2"
}

variable "backend_bucket_name" {
  description = "Globally unique S3 bucket name used for Terraform remote state."
  type        = string

  validation {
    condition     = length(var.backend_bucket_name) >= 3 && length(var.backend_bucket_name) <= 63
    error_message = "backend_bucket_name must be between 3 and 63 characters."
  }
}
