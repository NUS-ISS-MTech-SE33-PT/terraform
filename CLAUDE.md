# Terraform Project Guidelines

## Project Context

This is a **school project** demonstrating microservice architecture on AWS. Two principles govern all infrastructure decisions:

1. **Cost first** — we have a very limited budget and no active users. Always prefer the lowest viable spec (e.g. `t3.micro`, `PAY_PER_REQUEST` billing, minimal NAT, smallest ECS task sizes). Avoid over-provisioning.
2. **Security non-negotiable** — the project's goal is to demonstrate correct security practices. Never cut corners on IAM least-privilege, encryption at rest/in transit, security groups, or WAF. Security correctness takes priority over convenience.

When suggesting resource configurations, default to low-cost options unless there is a specific security or correctness reason to go higher.

## Upcoming Work

- **Add two more microservices** — extend ECS task roles, DynamoDB tables, API Gateway integrations, and GHA policies following existing patterns
- **Destroy-safe config** — see below

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
