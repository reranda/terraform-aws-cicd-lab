# Deployment

## Prerequisites

- Git
- Terraform 1.11 or newer
- AWS CLI authenticated to your own AWS sandbox/lab account
- Permission to create the backend S3 bucket
- A GitHub-to-AWS OIDC role

## 1. Bootstrap the state bucket

```bash
cd backend-bootstrap
cp terraform.tfvars.example terraform.tfvars
```

Edit the bucket name, then:

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

Record the `backend_bucket_name` output.

## 2. Configure OIDC

Follow [aws-oidc-setup.md](aws-oidc-setup.md).

## 3. Configure GitHub

Repository variables:

```text
AWS_REGION=eu-west-2
TF_STATE_BUCKET=<backend bucket>
DEMO_BUCKET_NAME=<unique demo bucket>
```

Repository secret:

```text
AWS_ROLE_ARN=<OIDC role ARN>
```

Create a GitHub Environment named `dev` and restrict deployments to the `main` branch.

## 4. Validate through CI

Open or update a pull request. CI runs formatting, validation, TFLint, and Checkov without AWS credentials.

## 5. Run a plan only

After merging to `main`, open **Actions > Terraform Deploy > Run workflow** and leave **Apply the saved Terraform plan** disabled.

Review the plan output.

## 6. Apply

Run **Terraform Deploy** again with **Apply the saved Terraform plan** enabled.

The workflow produces a fresh plan, uploads that plan as a short-lived artifact, and the apply job consumes that exact saved plan.

## 7. Verify idempotency

After a successful deployment, run **Terraform Deploy** again with Apply disabled.

The expected result is:

```text
No changes. Your infrastructure matches the configuration.
```

A zero-change plan confirms that the deployed AWS resources and Terraform state have converged.

## Tested deployment result

The workflow has been validated end to end in a real AWS lab account:

- GitHub OIDC role assumption succeeded for both the `main` branch plan job and the `dev` environment apply job.
- Terraform initialized successfully against the S3 remote backend.
- The saved-plan artifact was downloaded and applied successfully.
- The VPC, four subnets, route tables, Internet Gateway, restricted default security group, and protected S3 bucket were deployed.
- A subsequent plan returned **No changes**, confirming idempotency.

During testing, an initially too-narrow IAM policy caused a partial apply when the AWS provider attempted an S3 bucket-policy read. Remote state preserved the resources that had already been created. After adding the required read permission and running a new plan, Terraform reconciled the remaining resources successfully.

See [validation.md](validation.md) for the detailed test record.

## Destroy

Run **Terraform Destroy** and type:

```text
DESTROY
```

The backend bucket is not removed by this workflow. It has `prevent_destroy = true`.

After destroy completes, a clean redeployment can be used to validate the full create/destroy/recreate lifecycle.
