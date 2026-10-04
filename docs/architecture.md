# Architecture

## Design goals

This lab is designed to demonstrate more than Terraform syntax. The architecture focuses on five engineering concerns:

1. **Separate validation from privileged deployment.**
2. **Avoid long-lived cloud credentials in CI/CD.**
3. **Keep Terraform state durable and independently managed.**
4. **Make deployment and destruction explicit, reviewable actions.**
5. **Keep the AWS footprint inexpensive enough for repeatable lab testing.**

## Delivery architecture

```mermaid
flowchart TB
    DEV[Engineer]

    subgraph GH["GitHub Repository"]
        PR[Pull Request]
        MAIN[main branch]

        subgraph CI["Unprivileged CI"]
            FMT[terraform fmt]
            VALIDATE[terraform validate]
            LINT[TFLint]
            CHECKOV[Checkov]
        end

        DEPLOY[Manual Deploy Workflow]
        DESTROY[Guarded Destroy Workflow]
        ARTIFACT[(Saved Plan Artifact)]
    end

    DEV --> PR
    PR --> FMT
    FMT --> VALIDATE
    VALIDATE --> LINT
    LINT --> CHECKOV

    DEV --> MAIN
    MAIN --> DEPLOY
    MAIN --> DESTROY

    DEPLOY --> OIDC[GitHub OIDC Token]
    DESTROY --> OIDC

    subgraph AWS["AWS Account"]
        OIDC --> IAM[IAM Deployment Role]
        IAM --> TF[Terraform AWS Provider]

        subgraph STATE["State Layer"]
            S3STATE[(S3 Remote State)]
            LOCK[Native S3 Lock File]
        end

        subgraph LAB["Disposable Lab Infrastructure"]
            VPC[VPC 10.20.0.0/16]
            S3DATA[(Protected S3 Data Bucket)]
        end

        TF <--> S3STATE
        TF <--> LOCK
        TF --> VPC
        TF --> S3DATA
    end

    DEPLOY --> PLAN[terraform plan]
    PLAN --> ARTIFACT
    ARTIFACT --> APPLY[terraform apply saved plan]
    APPLY --> TF
    DESTROY --> DPLAN[terraform plan -destroy]
    DPLAN --> TF
```

### Trust boundary

Normal CI never receives AWS credentials.

Only explicitly invoked deployment/destruction jobs request an OIDC token. AWS validates that token against the IAM role trust policy and returns temporary STS credentials.

This means there are no permanent AWS access keys stored as GitHub secrets.

## AWS infrastructure architecture

```mermaid
flowchart TB
    VPC["VPC 10.20.0.0/16"]

    subgraph AZA["Availability Zone A"]
        PUBA["Public subnet 10.20.10.0/24"]
        PRIA["Private subnet 10.20.110.0/24"]
    end

    subgraph AZB["Availability Zone B"]
        PUBB["Public subnet 10.20.20.0/24"]
        PRIB["Private subnet 10.20.120.0/24"]
    end

    IGW[Internet Gateway]
    PUBRT[Public Route Table]
    PRIVRT[Private Route Table]
    DSG[Restricted Default Security Group]
    DATA[(Encrypted + Versioned S3 Bucket)]

    VPC --> PUBA
    VPC --> PRIA
    VPC --> PUBB
    VPC --> PRIB
    VPC --> DSG

    IGW --> PUBRT
    PUBRT --> PUBA
    PUBRT --> PUBB

    PRIVRT --> PRIA
    PRIVRT --> PRIB

    VPC -. separate AWS service .-> DATA
```

## Networking decisions

The VPC spans two explicitly configured Availability Zones.

Using explicit Availability Zones keeps the topology deterministic if AWS later adds another zone to the region.

### Public subnets

The two public subnets have a default route through the Internet Gateway.

They do **not** automatically assign public IPv4 addresses to launched resources.

### Private subnets

The two private subnets have no Internet default route.

No NAT Gateway is created. This keeps the lab inexpensive and makes the private route-table behavior clear. A production workload requiring outbound Internet access would need an additional egress design.

### Default security group

The VPC default security group is managed with no ingress or egress rules.

Workload-specific security groups should be created explicitly rather than relying on permissive defaults.

## S3 data bucket

The demonstration bucket enables:

- S3 Block Public Access
- object versioning
- server-side encryption with SSE-S3
- non-current version cleanup
- incomplete multipart-upload cleanup

Cross-region replication, a customer-managed KMS key, access logging, and event notifications are intentionally excluded from this small lab. Those decisions are documented rather than hidden behind broad security-scan exclusions.

## Terraform state architecture

The backend is created separately under `backend-bootstrap/`.

That separation means destroying the disposable lab does not destroy the state system used to manage it.

The backend enables:

- versioning
- server-side encryption
- S3 Block Public Access
- native Terraform S3 lock files through `use_lockfile = true`
- incomplete multipart-upload cleanup
- `prevent_destroy = true`

## Deployment lifecycle

```text
Code change
   ↓
CI validation
   ↓
Merge to main
   ↓
Manual plan
   ↓
Saved plan artifact
   ↓
Explicit apply
   ↓
Zero-change verification
   ↓
Guarded destroy (when required)
   ↓
Clean redeploy
```

This lifecycle was exercised end to end during project validation. See [validation.md](validation.md).
