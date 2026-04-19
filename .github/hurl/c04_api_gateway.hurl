# C-04 — Cognito authorizer validation (API Gateway layer)
# Verifies that the AWS API Gateway JWT authorizer rejects requests with a missing
# or invalid token before they reach the backend services.
#
# Covers all protected routes across review-service and spot-submission-service.
# Supersedes the no-token cases previously in:
#   - review_service_guard.hurl
#   - spot_submission_service_guard.hurl
#   - c02_spot_submission_service.hurl (401 block)

# ── No token ─────────────────────────────────────────────────────────────────
# All protected routes must return 401 when the Authorization header is absent.

# review-service

POST {{api_base_url}}/prod/spots/{{test_spot_id}}/reviews
HTTP 401

###

GET {{api_base_url}}/prod/users/me/reviews
HTTP 401

###

GET {{api_base_url}}/prod/users/me/favorites
HTTP 401

###

GET {{api_base_url}}/prod/spots/{{test_spot_id}}/favorite
HTTP 401

###

PUT {{api_base_url}}/prod/spots/{{test_spot_id}}/favorite
HTTP 401

###

DELETE {{api_base_url}}/prod/spots/{{test_spot_id}}/favorite
HTTP 401

###

# spot-submission-service (user routes)

POST {{api_base_url}}/prod/spots/submissions/photos/presign
HTTP 401

###

POST {{api_base_url}}/prod/spots/submissions
HTTP 401

###

# spot-submission-service (moderation routes)

GET {{api_base_url}}/prod/moderation/submissions
HTTP 401

###

POST {{api_base_url}}/prod/moderation/submissions/test-submission-id/approve
HTTP 401

###

POST {{api_base_url}}/prod/moderation/submissions/test-submission-id/reject
HTTP 401

###

# ── Expired token ─────────────────────────────────────────────────────────────
# Replay a previously valid access token after its 15-minute TTL has elapsed.
# Set {{expired_access_token}} to a known-expired Cognito access token before running.

GET {{api_base_url}}/prod/users/me/reviews
Authorization: Bearer {{expired_access_token}}
HTTP 401

###

# ── Tampered signature ────────────────────────────────────────────────────────
# Proves that API Gateway enforces signature validation and does not accept
# arbitrary JWT-structured strings. Uses a hardcoded fake token: valid header +
# payload structure, bogus signature bytes.
#
# Wrong issuer and unknown client_id are NOT tested here. A fake token always
# fails at signature validation before claims are evaluated, so a 401 from a
# fake token cannot prove that either of those specific checks is working. Those
# controls are verified via Terraform config inspection (api.tf:44-47,
# environments/prod/api_gateway.tf:17-18).

GET {{api_base_url}}/prod/users/me/reviews
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ0ZXN0LXVzZXIiLCJleHAiOjk5OTk5OTk5OTl9.dGFtcGVyZWQtc2lnbmF0dXJlYnl0ZXM
HTTP 401
