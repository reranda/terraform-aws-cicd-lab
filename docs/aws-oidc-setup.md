# AWS OIDC setup for GitHub Actions

## Why OIDC

The workflows do not use long-lived AWS access keys. GitHub receives an OIDC token and AWS IAM exchanges it for short-lived role credentials when the configured trust conditions match.

## 1. Create the GitHub OIDC provider

If the AWS account does not already have it:

- Provider URL: `https://token.actions.githubusercontent.com`
- Audience: `sts.amazonaws.com`

## 2. Create a dedicated IAM role

Example role name:

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
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:reranda/terraform-aws-cicd-lab:ref:refs/heads/main",
            "repo:reranda/terraform-aws-cicd-lab:environment:dev"
          ]
        }
      }
    }
  ]
}
```

## 3. Give the role deployment permissions

Use a dedicated AWS sandbox account where practical.

The role needs only the permissions required to:

- read/write the Terraform state key and lock file
- manage the lab S3 data bucket
- manage the VPC, subnets, route tables, Internet Gateway, tags, and default security-group rules
- read Availability Zone and related EC2 metadata

Avoid attaching `AdministratorAccess` merely for convenience.

## 4. Configure GitHub

Create repository secret:

```text
AWS_ROLE_ARN=arn:aws:iam::<account-id>:role/github-terraform-cicd-lab
```

Create repository variables:

```text
AWS_REGION=eu-west-2
TF_STATE_BUCKET=<globally-unique-state-bucket>
DEMO_BUCKET_NAME=<globally-unique-demo-bucket>
```

## 5. Configure the dev environment

Create a GitHub Environment named `dev`.

Where available, restrict deployments to `main` and add a required reviewer. The deploy and destroy workflows reference this environment before changing AWS resources.
