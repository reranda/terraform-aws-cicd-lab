data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  public_subnet_cidrs  = ["10.20.10.0/24", "10.20.20.0/24"]
  private_subnet_cidrs = ["10.20.110.0/24", "10.20.120.0/24"]
}

resource "aws_vpc" "main" {
  #checkov:skip=CKV2_AWS_11:VPC Flow Logs are intentionally deferred to a later observability iteration of this cost-minimized lab.

  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${var.environment}-public-${count.index + 1}"
    Tier = "public"
  }
}

resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-${var.environment}-private-${count.index + 1}"
    Tier = "private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  count = 2

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_default_security_group" "restricted" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-default-sg-restricted"
  }
}

resource "aws_s3_bucket" "lab_data" {
  #checkov:skip=CKV_AWS_18:A second S3 bucket solely for access logs is intentionally omitted from this small personal lab.
  #checkov:skip=CKV_AWS_144:Cross-region replication is outside the scope of this single-region lab.
  #checkov:skip=CKV_AWS_145:SSE-S3 is used to keep the lab free of a continuously billed customer-managed KMS key.
  #checkov:skip=CKV2_AWS_62:Event notifications are not required for the demonstration data bucket.

  bucket = var.bucket_name

  tags = {
    Name = "${var.project_name}-${var.environment}-data"
  }
}

resource "aws_s3_bucket_public_access_block" "lab_data" {
  bucket = aws_s3_bucket.lab_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "lab_data" {
  bucket = aws_s3_bucket.lab_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lab_data" {
  bucket = aws_s3_bucket.lab_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "lab_data" {
  bucket = aws_s3_bucket.lab_data.id

  depends_on = [aws_s3_bucket_versioning.lab_data]

  rule {
    id     = "lab-cleanup"
    status = "Enabled"

    filter {
      prefix = ""
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
