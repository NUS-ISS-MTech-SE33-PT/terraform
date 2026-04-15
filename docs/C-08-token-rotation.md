# C-08 Token Rotation

## Goal

Enable Cognito refresh-token rotation and align the mobile and admin-web clients with the new rotated refresh-token behavior.

## Architecture Review Impact

- Cognito is now centralized in `terraform/modules/cognito/`, so refresh-token rotation must be enabled there for both app clients.
- There are two active app clients:
  - `android_client`
  - `admin_web_client`
- The mobile and admin-web feature branches already serialize refresh requests locally; the infra branch now needs to rotate refresh tokens for both clients and remove the legacy non-rotating auth flow.

## Functional Design

- Enable Cognito refresh-token rotation for both app clients.
- Use a `10 second` retry grace period to avoid breaking clients during in-flight refresh races.
- Remove `ALLOW_REFRESH_TOKEN_AUTH` from both app clients so refreshes go through the OAuth `refresh_token` grant.
- Keep `enable_token_revocation = true`.

## Test Design

- Terraform:
  - `terraform fmt -check -recursive`
  - `terraform init -backend=false`
  - `terraform validate`
- Client branches that pair with this infra change:
  - Flutter: `flutter analyze`, `flutter test`, `flutter build web --debug --dart-define=USE_MOCK=true`
  - admin-web: `npm run lint`, `npm run build`
- Manual acceptance after deploy:
  - sign in
  - trigger refresh twice in quick succession
  - confirm a new refresh token is persisted
  - confirm the old refresh token stops working after the grace period

## TODO List

- Enable refresh-token rotation for the android app client.
- Enable refresh-token rotation for the admin web app client.
- Remove `ALLOW_REFRESH_TOKEN_AUTH` from both clients.
- Re-run Terraform formatting and validation before commit.
