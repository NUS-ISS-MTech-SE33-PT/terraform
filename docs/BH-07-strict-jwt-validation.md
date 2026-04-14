# BH-07 Strict JWT Validation

## Goal

Align shared edge auth with the stricter JWT validation already implemented in the backend services.

## Architecture Review Impact

- API Gateway and Cognito are now owned by the shared `terraform/` repo.
- `review-service` and `spot-submission-service` both perform service-side strict JWT validation in their feature branches.
- The remaining gap is edge consistency: moderation routes are still public in shared API Gateway, and the API smoke tests still use Cognito `IdToken` instead of `AccessToken`.

## Functional Design

- Protect moderation routes with the existing shared JWT authorizer in `environments/prod/api_gateway.tf`.
- Keep `/spots/submissions/health` public.
- Continue to allow both Cognito app clients at the edge; downstream services remain responsible for admin-group authorization on moderation endpoints.
- Update Hurl and shell-based API tests to send Cognito access tokens so they match the service-side `token_use == access` requirement.

## Test Design

- `terraform fmt -check -recursive`
- `terraform init -backend=false`
- `terraform validate`
- Static review of `.github/hurl/spot_submission_service_guard.hurl` to confirm moderation routes now expect `401` without a token.
- Static review of `.github/hurl/*.hurl` and `.github/scripts/api-tests.sh` to confirm protected requests use `AccessToken`, not `IdToken`.

## TODO List

- Add JWT authorization to moderation routes in shared API Gateway.
- Keep health routes public.
- Switch API smoke tests from Cognito `IdToken` to `AccessToken`.
- Re-run Terraform formatting and validation before commit.
