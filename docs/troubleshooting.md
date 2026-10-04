# Troubleshooting

## OIDC role assumption fails

Check the OIDC provider, `AWS_ROLE_ARN`, repository name in the role trust policy, current branch, and GitHub Environment.

## Terraform init returns AccessDenied

Verify `TF_STATE_BUCKET`, `AWS_REGION`, the IAM role's S3 permissions, and any bucket policy.

## S3 bucket name already exists

S3 bucket names are globally unique. Choose another `TF_STATE_BUCKET` or `DEMO_BUCKET_NAME`.

Avoid customer, employer, account-number, email, or other sensitive identifiers in public bucket names.

## Terraform reports an existing lock

First confirm that no plan/apply is active. Do not remove a state lock blindly.

Investigate the lock metadata and use Terraform's documented unlock procedure only when you are certain the lock is stale.

## Checkov reports an intentional exception

A small number of omitted production controls have inline skip comments with a reason. Do not add broad global exclusions merely to make CI green.

## CI differs from local validation

Check the Terraform version, formatting, provider initialization, TFLint output, and Checkov output separately.

The workflows currently standardize Terraform on `1.14.6`.
