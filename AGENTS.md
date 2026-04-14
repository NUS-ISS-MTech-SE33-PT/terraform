# Repository Guidelines

## Project Structure & Ownership
- Shared AWS infrastructure for MakanGo lives here.
- `bootstrap/prod/` provisions Terraform backend and GitHub Actions IAM roles.
- `environments/prod/` owns deployable production resources such as API Gateway, Cognito, CloudFront, ECS, load balancers, DynamoDB, and S3.
- `modules/` contains reusable Terraform modules. Cognito app clients and user-pool outputs are managed under `modules/cognito/`.
- `.github/hurl/` and `.github/scripts/` contain API smoke tests that must stay aligned with route auth and token expectations.

## Build, Validate, and Test Commands
- Run `terraform fmt -recursive` before committing Terraform changes.
- Run `terraform init -backend=false` and `terraform validate` from the affected directory, usually `environments/prod/`.
- When changing protected API routes or Cognito settings, review `.github/hurl/*.hurl` and `.github/scripts/api-tests.sh`.
- Use `hurl --test ...` only when the required secrets and deployed endpoints are available.

## Coding & Review Rules
- Keep Terraform files lowercase and `terraform fmt` clean.
- Prefer updating shared modules and environment wiring here instead of reviving deprecated service-local Terraform folders.
- Keep route auth, Cognito client settings, and downstream service expectations consistent. If you change audiences, token lifetime, or refresh behavior, review `makan_go_app/`, `admin-web/`, `review-service/`, and `spot-submission-service/`.

## Security Notes
- Never commit secrets, test credentials, or populated `.tfvars` files.
- API Gateway and Cognito are the source of truth for edge authentication; services should treat this repo as the authoritative infra definition.
