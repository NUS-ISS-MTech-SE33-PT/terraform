#!/bin/bash
set -euo pipefail

PASS=0
FAIL=0
BODY_FILE=$(mktemp)
trap 'rm -f "$BODY_FILE"' EXIT

# ── Helpers ───────────────────────────────────────────────────────────────────

check() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$actual" = "$expected" ]; then
    echo "  PASS: $desc"
    ((PASS++)) || true
  else
    echo "  FAIL: $desc  (expected HTTP $expected, got $actual)"
    if [ -s "$BODY_FILE" ]; then
      echo "        response: $(cat "$BODY_FILE")"
    fi
    ((FAIL++)) || true
  fi
}

# Authenticated request
req() {
  local method="$1" path="$2"
  shift 2
  curl -s -o "$BODY_FILE" -w "%{http_code}" \
    -X "$method" \
    -H "Authorization: Bearer $TOKEN" \
    "$@" \
    "$API_BASE_URL/prod$path"
}

# Unauthenticated request
req_unauth() {
  local method="$1" path="$2"
  shift 2
  curl -s -o "$BODY_FILE" -w "%{http_code}" \
    -X "$method" \
    "$@" \
    "$API_BASE_URL/prod$path"
}

# ── Fetch Cognito token ───────────────────────────────────────────────────────
# COGNITO_CLIENT_ID must be either android_client_id or admin_web_client_id —
# both are registered as valid audiences on the JWT authorizer.

echo "==> Authenticating with Cognito..."

BODY="{\"AuthFlow\":\"USER_PASSWORD_AUTH\",\"ClientId\":\"$COGNITO_CLIENT_ID\",\"AuthParameters\":{\"USERNAME\":\"$TEST_USERNAME\",\"PASSWORD\":\"$TEST_PASSWORD\"}}"

COGNITO_RESPONSE=$(curl -s -X POST \
  "https://cognito-idp.ap-southeast-1.amazonaws.com/" \
  -H "X-Amz-Target: AWSCognitoIdentityProviderService.InitiateAuth" \
  -H "Content-Type: application/x-amz-json-1.1" \
  -d "$BODY")

TOKEN=$(echo "$COGNITO_RESPONSE" | jq -r '.AuthenticationResult.IdToken')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "ERROR: Failed to obtain Cognito token. Check secrets and Cognito app client config."
  echo "$COGNITO_RESPONSE" | jq .
  exit 1
fi

echo "  Token obtained."

# ── Auth guard — all protected routes must reject requests without a token ────

echo ""
echo "==> Auth guard (no token → 401)"

check "POST /spots/{id}/reviews"    401 "$(req_unauth POST "/spots/$TEST_SPOT_ID/reviews")"
check "GET  /users/me/reviews"      401 "$(req_unauth GET  /users/me/reviews)"
check "GET  /users/me/favorites"    401 "$(req_unauth GET  /users/me/favorites)"
check "GET  /spots/{id}/favorite"   401 "$(req_unauth GET  "/spots/$TEST_SPOT_ID/favorite")"
check "PUT  /spots/{id}/favorite"   401 "$(req_unauth PUT  "/spots/$TEST_SPOT_ID/favorite")"
check "DELETE /spots/{id}/favorite" 401 "$(req_unauth DELETE "/spots/$TEST_SPOT_ID/favorite")"

# ── Happy path — authenticated requests must not return 401/403 ───────────────
# GET endpoints: expect 200.
# Write endpoints (POST/PUT/DELETE): we only verify auth passes (not 401/403).
# Adjust expected codes as your service behaviour is confirmed.

echo ""
echo "==> Happy path (valid token)"

check "GET /users/me/reviews"    200 "$(req GET  /users/me/reviews)"
check "GET /users/me/favorites"  200 "$(req GET  /users/me/favorites)"
check "GET /spots/{id}/favorite" 200 "$(req GET  "/spots/$TEST_SPOT_ID/favorite")"

# POST with an empty body — expect 400 (bad request) rather than 401 (unauth).
# This confirms the request reached the service, meaning auth passed.
check "POST /spots/{id}/reviews passes auth" 400 "$(req POST "/spots/$TEST_SPOT_ID/reviews" -H "Content-Type: application/json" -d '{}')"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
