# Terraform Project Guidelines

## Project Context

This is a **school project** demonstrating microservice architecture on AWS. Two principles govern all infrastructure decisions:

1. **Cost first** — we have a very limited budget and no active users. Always prefer the lowest viable spec (e.g. `t3.micro`, `PAY_PER_REQUEST` billing, minimal NAT, smallest ECS task sizes). Avoid over-provisioning.
2. **Security non-negotiable** — the project's goal is to demonstrate correct security practices. Never cut corners on IAM least-privilege, encryption at rest/in transit, security groups, or WAF. Security correctness takes priority over convenience.

When suggesting resource configurations, default to low-cost options unless there is a specific security or correctness reason to go higher.

## Reminders

- **Tag promote in deploy workflow** — `deploy-prod.yml` creates a `vX.Y.Z-prod` git tag after a successful `terraform apply`. This works for CI-triggered deploys but fails with a duplicate tag error when the workflow is manually re-triggered (same RC tag, prod tag already exists). Fix: force-update the tag (`git tag -f` + `git push --force`) so the prod tag always reflects the latest deploy. **Deferred — to be replaced by the new tag-based promotion strategy below.**

## Tag-Based Promotion Strategy (Proposed)

This section describes the agreed target state for how code moves from development to production. Not yet fully implemented.

### Core Principle

**Branches handle code collaboration. Tags handle environment promotion.**

- A push to `main` (no tag) is always safe — nothing deploys, no ambiguity.
- Tags are evidence that a gate has been passed. A deployment can only happen when the right tags exist.
- Direct pushes to `main` are prohibited for all team members. All changes go through PRs.
- Repo admins have a bypass rule for emergency/quick iterations (pragmatic escape hatch for a small team).

### Promotion Flow

```
feature/* branch
    │
    └─► PR to main (required, no direct push)
            │
            ▼
        PR merged → merge commit on main
            │
            ▼
        CI pipeline runs on merge commit
        ├─ unit tests pass  → auto-create tag: ci-passed/vX.Y.Z
        └─ (future) API tests pass → consolidated into ci-passed/vX.Y.Z
            │
            ▼
        Developer pushes tag: rc/vX.Y.Z
        (manual step — developer decides major/minor/patch)
            │
            ▼
        Gate check: does ci-passed/vX.Y.Z exist on this commit?
            │  yes
            ▼
        GitHub Environment "prod" — two approval layers:
        ├─ Auto: ci-passed tag verified ✓
        └─ Manual: required reviewer approves (manager/lead in GitHub UI)
            │
            ▼
        deploy-prod.yml runs → terraform apply
            │
            ▼
        Deploy succeeds → force-update tag: live
        (live always points to the commit currently running in prod)
```

### Tag Naming Convention

| Tag | Created by | Meaning |
|---|---|---|
| `ci-passed/vX.Y.Z` | CI (automated) | All checks passed on this commit |
| `rc/vX.Y.Z` | Developer (manual) | Release candidate — intent to deploy |
| `live` | CI (automated, force-updated) | Currently deployed commit in prod |

### Design Decisions

- **Tags generated on merge to main only** — not on feature branch commits. Feature branch CI runs for early feedback but produces no tags. The merge commit is the canonical promotion point.
- **`ci-passed` consolidates all gates** — unit tests and API tests both contribute; a single tag keeps the gate check simple.
- **`live` is a mutable tag** — always force-updated to reflect current prod. Anyone can run `git show live` to see exactly what is deployed.
- **Version semantics owned by the developer** — the developer decides major/minor/patch when pushing `rc/vX.Y.Z`. This is the primary advantage of manual tagging over auto-incrementing.
- **GitHub tag protection rules** — `rc/*` and `ci-passed/*` tags should be protected so only CI and authorised users can create/delete them.

### What This Replaces

The current `deploy-prod.yml` triggers on `v*-rc.*` tags and creates a `vX.Y.Z-prod` tag post-deploy. Under the new strategy:
- Trigger changes from `v*-rc.*` to `rc/vX.Y.Z`
- Post-deploy tag changes from `vX.Y.Z-prod` to force-updating `live`

## Destroy-Safe Design

The team are part-time students who develop in free time. To control AWS costs, expensive runtime resources can be shut down via a **manually triggered GitHub Actions workflow** when not in use.

### Principle
Resources are split into two tiers:

**Tier 1 — Always-on (never destroyed)**
Persistent or foundational resources that are either free, cheap, or dangerous/expensive to recreate:
- VPC, subnets, security groups
- IAM roles and policies
- S3 buckets, DynamoDB tables
- ECR repositories
- Cognito user pools
- ACM certificates
- CloudFront distributions (free — covered by CloudFront Free Tier plan)
- WAF WebACLs (free — bundled in CloudFront Free Tier plan alongside CloudFront)
- API Gateway stages (~$0/month fixed, pay-per-request only)

**Tier 2 — Destroyable (shut down when idle)**
Resources with meaningful fixed monthly costs regardless of traffic:
- ECS services and task definitions
- Load balancers (NLB/ALB)

### Implementation
Tier 2 resources should be gated so a GitHub Actions workflow can destroy and recreate them independently without touching Tier 1. This is typically done by isolating Tier 2 into a separate Terraform target group or workspace, or using `count`/`var.enabled` flags.

## IAM Policy Strategy (bootstrap/prod)

AWS limits managed policies attached to a single IAM role to **10** (soft limit, increasable via AWS Support).

### Convention
- **Managed policies** (`aws_iam_policy` + `aws_iam_role_policy_attachment`): use for general infra permissions that are likely to be reused across roles (e.g. networking, compute, storage primitives).
- **Inline policies** (`aws_iam_role_policy`): use for service-specific permissions that are unlikely to be reused (e.g. DynamoDB access scoped to a single service).

### Current split
The 10 managed policy slots are occupied by `gha_policy_*.tf` files (one per AWS service). Any new service-specific permissions (e.g. per-service DB access) should be added as inline policies.
