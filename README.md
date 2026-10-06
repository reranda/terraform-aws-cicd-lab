# Terraform AWS CI/CD Lab

[![Terraform CI](https://github.com/reranda/terraform-aws-cicd-lab/actions/workflows/terraform-ci.yml/badge.svg)](https://github.com/reranda/terraform-aws-cicd-lab/actions/workflows/terraform-ci.yml)
[![Terraform](https://img.shields.io/badge/Terraform-1.14.6-844FBA?logo=terraform&logoColor=white)](https://developer.hashicorp.com/terraform)
[![AWS](https://img.shields.io/badge/AWS-IaC%20Lab-232F3E?logo=amazonwebservices&logoColor=white)](https://aws.amazon.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**Production-style Terraform delivery on AWS with GitHub Actions, OIDC, remote state, policy checks, controlled deployment, guarded teardown, and tested failure recovery.**

This independent lab demonstrates how I approach cloud infrastructure as an engineering system rather than a collection of Terraform files: **validate early, avoid long-lived credentials, separate CI from privileged deployment, preserve state safely, recover cleanly from partial failure, and prove repeatability through lifecycle testing.**

## Highlights

| Capability | Implementation |
| --- | --- |
| Infrastructure as Code | Terraform with AWS provider |
| CI | `fmt`, `validate`, TFLint, Checkov |
| AWS authentication | GitHub OIDC → short-lived STS credentials |
| Terraform state | Private, encrypted, versioned S3 backend |
| State locking | Native S3 lock file |
| Deployment | Manual saved-plan workflow |
| Destruction | Separate guarded workflow requiring `DESTROY` |
| AWS architecture | Multi-AZ VPC + secured S3 data bucket |
| Validation | Create → converge → destroy → redeploy → converge |
| Cost awareness | No NAT Gateway, EC2, or load balancer required |

## Architecture

<img width="612" height="512" alt="Untitled Diagram-Page-2" src="https://github.com/user-attachments/assets/9539e748-34e7-4f85-8b3f-56ee3929a811" />

The infrastructure layer creates a small two-AZ VPC with public and private subnets plus a protected S3 data bucket. The design deliberately avoids continuously billed components such as NAT Gateways, EC2 instances, and load balancers.

For the detailed network and delivery design, see [Architecture](docs/architecture.md).

## What this project proves

This repository has been exercised end to end against a real AWS lab account—not just statically validated.

- ✅ Terraform formatting and validation
- ✅ TFLint
- ✅ Checkov
- ✅ GitHub OIDC authentication
- ✅ Remote S3 state
- ✅ Saved-plan deployment
- ✅ Multi-AZ AWS provisioning
- ✅ Zero-change/idempotency validation
- ✅ Guarded destroy
- ✅ Backend preservation after destroy
- ✅ Clean redeployment from empty state
- ✅ Final zero-change convergence
- ✅ Recovery from a real partial-apply/IAM-permission failure

See [Deployment Validation](docs/validation.md) for the full test record and lessons learned.

## Repository structure

```text
.
├── .github/
│   └── workflows/
│       ├── terraform-ci.yml
│       ├── terraform-deploy.yml
│       └── terraform-destroy.yml
├── backend-bootstrap/
├── infrastructure/
├── docs/
│   ├── architecture.md
│   ├── aws-oidc-setup.md
│   ├── deployment.md
│   ├── security.md
│   ├── troubleshooting.md
│   └── validation.md
├── .gitignore
├── .tflint.hcl
├── LICENSE
└── README.md
```

## Delivery workflow

### CI: no AWS credentials

Pull requests and pushes to `main` run:

1. `terraform fmt -check -recursive`
2. `terraform init -backend=false`
3. `terraform validate`
4. TFLint
5. Checkov

The CI job has no AWS deployment credentials.

### Deploy: short-lived AWS credentials

Deployment is intentionally manual:

1. GitHub requests an OIDC token.
2. AWS validates the repository/workflow identity.
3. STS issues short-lived credentials for a dedicated IAM role.
4. Terraform initializes against the S3 backend.
5. Terraform creates and uploads a saved plan.
6. Apply consumes that exact plan only when explicitly enabled.

### Destroy: separate safety path

Destruction is isolated in its own workflow and requires the exact confirmation value:

```text
DESTROY
```

The disposable infrastructure is removed while the separately managed Terraform backend remains protected.

## Security design

- No static AWS access keys in GitHub.
- OIDC trust is restricted to this repository and approved deployment contexts.
- Deployment uses a dedicated IAM role rather than administrator access.
- Terraform state is private, encrypted, versioned, and lock-protected.
- S3 Block Public Access is enabled.
- The VPC default security group is restricted.
- Apply and destroy are never triggered automatically by pull requests.
- Checkov exceptions are narrow and documented with reasons.
- `.gitignore` excludes state, plans, and normal `.tfvars` files.

See [Security Decisions](docs/security.md).

## Failure recovery demonstrated

During validation, an intentionally narrow IAM policy exposed a missing S3 metadata-read permission during Apply.

Instead of deleting infrastructure manually or abandoning state, the recovery process was:

1. inspect the failed Actions job,
2. identify the missing least-privilege permission,
3. verify already-created resources in remote state,
4. update the IAM role,
5. create a **fresh** Terraform plan,
6. allow Terraform to reconcile the remaining work.

The network stack was preserved, the affected empty lab bucket was safely replaced after being marked tainted, and the final environment converged successfully.

That scenario is documented in [Troubleshooting](docs/troubleshooting.md).

## Documentation

| Document | Purpose |
| --- | --- |
| [Architecture](docs/architecture.md) | Delivery and AWS design |
| [AWS OIDC Setup](docs/aws-oidc-setup.md) | GitHub → AWS trust configuration |
| [Deployment](docs/deployment.md) | Bootstrap, plan, apply, destroy |
| [Security](docs/security.md) | Security decisions and trade-offs |
| [Validation](docs/validation.md) | End-to-end lifecycle test record |
| [Troubleshooting](docs/troubleshooting.md) | Failure modes and recovery guidance |

## Cost-conscious design

The lab intentionally avoids NAT Gateways, EC2 instances, load balancers, and other continuously billed compute/network resources.

The primary recurring usage is small-volume S3 storage/API activity associated with Terraform state and the demonstration bucket. Always review current AWS pricing before running the lab.

## Quick start

```bash
git clone git@github.com:reranda/terraform-aws-cicd-lab.git
cd terraform-aws-cicd-lab
```

Then follow [Deployment](docs/deployment.md).

## Project status

**Full lifecycle validated.**

```text
validate
   ↓
plan
   ↓
apply
   ↓
zero-change verification
   ↓
destroy
   ↓
backend preserved
   ↓
clean redeploy
   ↓
final zero-change verification
```

---

This repository is an independent personal engineering lab. It contains generic lab configuration and does not reproduce employer or client infrastructure.

## Author

Built and maintained by Eranda Welgama as a personal AWS and Terraform engineering lab.