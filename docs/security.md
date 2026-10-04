# Security decisions

## Authentication

GitHub Actions authenticates to AWS with OIDC. No permanent AWS access key or secret key is required in the repository.

## CI versus deployment

Normal CI has no AWS credentials. AWS credentials are requested only by explicitly invoked deploy or destroy workflows.

## Terraform state

The backend bucket enables public-access blocking, server-side encryption, versioning, and Terraform native S3 lock files.

Terraform state can contain sensitive infrastructure metadata and should be treated as sensitive even when the source code is public.

## S3 data bucket

The demo data bucket enables public-access blocking, versioning, SSE-S3 encryption, and lifecycle cleanup.

Controls such as a customer-managed KMS key, S3 access logging, event notifications, and cross-region replication are intentionally omitted from this small cost-conscious lab and documented as Checkov exceptions.

## Networking

- Public subnets do not automatically assign public IPv4 addresses.
- Private subnets have no Internet route.
- No NAT Gateway is created.
- The default security group is emptied.

VPC Flow Logs are deferred to a later observability iteration.

## Destructive operations

Destroy is a separate manual workflow and requires the exact confirmation value `DESTROY`.

## Repository hygiene

Never commit AWS keys, Terraform state, sensitive `.tfvars`, private keys, customer information, or employer-specific infrastructure details.
