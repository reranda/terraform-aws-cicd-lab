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

## 4. Validate through CI

Open or update a pull request. CI runs formatting, validation, TFLint, and Checkov without AWS credentials.

## 5. Run a plan only

After merging to `main`, open **Actions > Terraform Deploy > Run workflow** and leave **Apply the saved Terraform plan** disabled.

Review the plan output.

## 6. Apply

Run **Terraform Deploy** again with **Apply the saved Terraform plan** enabled.

The apply job uses the saved plan from that workflow run.

## Destroy

Run **Terraform Destroy** and type:

```text
DESTROY
```

The backend bucket is not removed by this workflow. It has `prevent_destroy = true`.
