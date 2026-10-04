# Deployment Validation

## Purpose

This document records the end-to-end validation performed against the Terraform AWS CI/CD lab.

The objective was to prove that the repository can validate Terraform code, authenticate from GitHub to AWS without long-lived credentials, use remote state safely, deploy the intended infrastructure, recover from a realistic partial failure, destroy the lab cleanly, redeploy from empty state, and converge to a zero-change plan.

## Validation summary

| Test | Result |
| --- | --- |
| Terraform formatting | ✅ Passed |
| Terraform validation | ✅ Passed |
| TFLint | ✅ Passed |
| Checkov | ✅ Passed |
| Pull request CI | ✅ Passed |
| Post-merge CI on `main` | ✅ Passed |
| GitHub OIDC authentication for plan job | ✅ Passed |
| GitHub OIDC authentication for `dev` environment apply job | ✅ Passed |
| S3 remote backend initialization | ✅ Passed |
| Native S3 state locking configuration | ✅ Validated |
| Plan-only workflow | ✅ Passed |
| Saved plan artifact upload/download | ✅ Passed |
| Terraform apply | ✅ Passed |
| Remote-state recovery after partial apply | ✅ Passed |
| Initial idempotency plan | ✅ No changes |
| Guarded destroy workflow | ✅ 18 destroyed |
| Remote infrastructure state after destroy | ✅ Empty |
| Backend state bucket after destroy | ✅ Preserved |
| Clean redeployment from empty state | ✅ 18 added |
| Final idempotency plan | ✅ No changes |

## Tested infrastructure

The successful deployment created the intended lab architecture:

- one VPC
- two public subnets across two Availability Zones
- two private subnets across two Availability Zones
- one Internet Gateway
- separate public and private route tables
- four route-table associations
- a restricted default security group
- one demonstration S3 bucket with:
  - Block Public Access
  - versioning
  - server-side encryption
  - lifecycle cleanup

The lab intentionally does not deploy NAT Gateways, EC2 instances, or load balancers.

## OIDC validation

GitHub Actions successfully exchanged GitHub OIDC tokens for short-lived AWS STS credentials.

Two trust contexts were validated:

1. the `main` branch subject used by the Terraform plan job
2. the `dev` GitHub Environment subject used by Terraform apply and destroy

No long-lived AWS access key or secret access key is stored in GitHub.

## Remote state validation

The infrastructure configuration initialized successfully against the dedicated S3 backend.

The state bucket provides:

- versioning
- server-side encryption
- Block Public Access
- native Terraform S3 lock-file support
- lifecycle cleanup for incomplete multipart uploads

The backend is managed separately from the lab infrastructure and remained available throughout the destroy/redeploy test.

## Partial-apply recovery test

The first apply intentionally exposed a least-privilege IAM gap: the deployment role lacked an S3 metadata read required by the Terraform AWS provider.

The apply failed after the VPC and related networking resources had already been created.

The recovery process was:

1. inspect the GitHub Actions failure
2. identify the missing S3 read permission
3. confirm successfully created resources were present in remote Terraform state
4. update the IAM role without broadening it to administrator access
5. run a **new** Terraform plan rather than reusing the old saved plan
6. allow Terraform to reconcile the remaining work

The network stack was retained. The demonstration S3 bucket was marked tainted by the failed create/read sequence, so Terraform safely replaced that empty lab bucket during recovery.

The following apply completed successfully.

## Initial idempotency test

After the successful deployment, the plan-only workflow was run again without changing the configuration.

Terraform returned:

```text
No changes. Your infrastructure matches the configuration.
```

This confirmed that the deployed infrastructure and Terraform state had converged.

## Destroy validation

The guarded destroy workflow was then run with the exact confirmation value `DESTROY`.

Terraform planned:

```text
Plan: 0 to add, 0 to change, 18 to destroy.
```

and completed with:

```text
Apply complete! Resources: 0 added, 0 changed, 18 destroyed.
```

Afterward:

- `terraform state list` returned no managed infrastructure resources
- the dedicated Terraform backend bucket still existed and remained accessible

This validated the separation between the bootstrap/backend layer and the disposable lab-infrastructure layer.

## Clean redeployment validation

With the infrastructure state empty, the deploy workflow was run again with Apply enabled.

Terraform planned:

```text
Plan: 18 to add, 0 to change, 0 to destroy.
```

and completed with:

```text
Apply complete! Resources: 18 added, 0 changed, 0 destroyed.
```

This demonstrated that the environment could be recreated cleanly from version-controlled Terraform configuration and remote state.

## Final idempotency test

A final plan-only workflow was run after the clean redeployment.

Terraform returned:

```text
No changes. Your infrastructure matches the configuration.
```

The final zero-change plan confirms that the recreated infrastructure converged fully to the declared configuration.

## Lifecycle conclusion

The full lifecycle has now been validated successfully:

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
empty infrastructure state
   ↓
clean redeploy
   ↓
final zero-change verification
```

This project therefore demonstrates not only initial provisioning, but repeatable convergence, controlled teardown, state preservation, failure recovery, and clean reconstruction.
