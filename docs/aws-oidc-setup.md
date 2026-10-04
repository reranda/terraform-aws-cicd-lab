# AWS OIDC setup for GitHub Actions

## Why OIDC

The workflows do not use long-lived AWS access keys. GitHub receives an OIDC token and AWS IAM exchanges it for short-lived role credentials when the configured trust conditions match.

## Repository identity

This repository was created after GitHub introduced immutable OIDC subject claims for new repositories on July 15, 2026.

Use these immutable identifiers in the AWS trust policy:

- GitHub owner: `reranda`
- GitHub owner ID: `39367723`
- Repository: `terraform-aws-cicd-lab`
- Repository ID: `1404554131`

The repository segment therefore becomes:

`repo:reranda@39367723/terraform-aws-cicd-lab@1404554131`

## 1. Create the GitHub OIDC provider

If the AWS account does not already have it:

- Provider URL: `https://token.actions.githubusercontent.com`
- Audience: `sts.amazonaws.com`

Only one GitHub OIDC provider is needed per AWS account.

## 2. Create a dedicated IAM role

Recommended role name:

`github-terraform-cicd-lab`

Replace `AWS_ACCOUNT_ID` in this trust-policy example:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::AWS_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": [
            "repo:reranda@39367723/terraform-aws-cicd-lab@1404554131:ref:refs/heads/main",
            "repo:reranda@39367723/terraform-aws-cicd-lab@1404554131:environment:dev"
          ]
        }
      }
    }
  ]
}
```

The first subject allows the plan job on `main`. The second allows jobs that use the GitHub Environment named `dev`, which is used by the apply and destroy jobs.

## 3. Give the role deployment permissions

Use a dedicated AWS sandbox account where practical.

The role needs only the permissions required to:

- read/write the Terraform state key and lock file
- manage the lab S3 data bucket
- manage the VPC, subnets, route tables, Internet Gateway, tags, and default security-group rules
- read EC2 metadata required by the Terraform AWS provider

Avoid attaching `AdministratorAccess` merely for convenience.

## 4. Configure GitHub

Create repository secret:

```text
AWS_ROLE_ARN=arn:aws:iam::<account-id>:role/github-terraform-cicd-lab
```

Create repository variables:

```text
AWS_REGION=eu-west-2
TF_STATE_BUCKET=trlab-tf-state-replace-with-unique-f933be14
DEMO_BUCKET_NAME=<globally-unique-demo-bucket>
```

## 5. Configure the dev environment

Create a GitHub Environment named `dev`.

Restrict deployments to the `main` branch where available. Add a required reviewer if your GitHub plan supports it and that control fits the lab.

The deploy and destroy workflows reference this environment before changing AWS resources.
