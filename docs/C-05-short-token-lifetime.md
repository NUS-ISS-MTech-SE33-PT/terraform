# C-05 Short Token Lifetime

## Goal

Reduce the exposure window for stolen Cognito access and ID tokens without breaking the existing refresh-token based session flow.

## Architecture Review Impact

- Cognito now lives in the shared `terraform/modules/cognito/` module and is consumed by `terraform/environments/prod/cognito.tf`.
- There are two active app clients, not one:
  - `android_client`
  - `admin_web_client`
- The old `terraform-live` assumption that a single client still needed explicit short token lifetimes is no longer accurate. The admin web client already had explicit `60 minute` access and ID token lifetimes; the android client did not.

## Functional Design

- Set both Cognito app clients to `15 minute` access tokens.
- Set both Cognito app clients to `15 minute` ID tokens.
- Keep each client's refresh-token lifetime unchanged:
  - android: `30 days`
  - admin web: `5 days`
- Make token validity units explicit for both clients so provider defaults do not drift.

## Test Design

- `terraform fmt -check -recursive`
- `terraform init -backend=false`
- `terraform validate`
- Manual acceptance after deploy:
  - sign in with Flutter and admin web
  - inspect newly issued tokens and confirm `exp - iat` is `15 minutes`
  - wait for access-token expiry and confirm refresh still succeeds in both clients

## TODO List

- Add explicit access and ID token validity settings for the android app client.
- Reduce the admin web client access and ID token validity from `60 minutes` to `15 minutes`.
- Keep refresh-token validity unchanged for each client.
- Re-run Terraform formatting and validation before commit.
