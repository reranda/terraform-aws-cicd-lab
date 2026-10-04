# Troubleshooting

## OIDC role assumption fails

Check the OIDC provider, `AWS_ROLE_ARN`, repository identity in the role trust policy, current branch, and GitHub Environment.

For repositories using GitHub's immutable OIDC subject format, the subject includes the GitHub owner ID and repository ID. A trust policy written for the older `repo:owner/repository:...` format will fail with:

```text
Not authorized to perform sts:AssumeRoleWithWebIdentity
```

Verify that the IAM trust policy matches the actual subject format documented in [aws-oidc-setup.md](aws-oidc-setup.md).

## Terraform init returns AccessDenied

Verify `TF_STATE_BUCKET`, `AWS_REGION`, the IAM role's S3 permissions, and any bucket policy.

The S3 backend needs access to the state object and, when native S3 locking is enabled, the lock file as well.

## Apply fails after some resources were already created

Terraform apply is not transactional. A later resource failure does not automatically roll back resources that were already created successfully.

Do not delete those resources manually.

First check the remote state:

```bash
terraform state list
```

Then correct the underlying issue and create a **fresh Terraform plan**. Terraform will refresh the real resources against remote state and determine what work remains.

During this lab's validation, an S3 bucket was created successfully but the provider later received:

```text
AccessDenied: not authorized to perform s3:GetBucketPolicy
```

The IAM role was intentionally narrow and was missing a metadata read required by the provider. The S3 read permission was corrected, the existing remote state was retained, and the next fresh plan reconciled the deployment successfully.

## A resource is marked tainted after a failed apply

A failed create/read sequence can leave a resource tainted. On the next plan Terraform may report that the resource must be replaced.

Review the replacement carefully before applying. In this lab, the empty demonstration S3 bucket was tainted during the partial apply and was safely replaced on the recovery run.

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
