#!/bin/bash
set -euo pipefail

PASS=0
FAIL=0

# ── Helpers ──────────────────────────────────────────────────────────────────

check() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$actual" = "$expected" ]; then
    echo "  PASS: $desc"
    ((PASS++))
  else
    echo "  FAIL: $desc  (expected HTTP $expected, got $actual)"
    ((FAIL++))
  fi
}

get() {
  curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $TOKEN" \
    "$API_BASE_URL$1"
}

get_unauth() {
  curl -s -o /dev/null -w "%{http_code}" "$API_BASE_URL$1"
}

# ── Fetch Cognito token ───────────────────────────────────────────────────────

echo "==> Authenticating with Cognito..."

COGNITO_RESPONSE=$(curl -s -X POST \
  "https://cognito-idp.ap-southeast-1.amazonaws.com/" \
  -H "X-Amz-Target: AmazonCognitoIdentityProviderService.InitiateAuth" \
  -H "Content-Type: application/x-amz-json-1.1" \
  -d '{
    "AuthFlow": "USER_PASSWORD_AUTH",
    "ClientId": "'"$COGNITO_CLIENT_ID"'",
    "AuthParameters": {
      "USERNAME": "'"$TEST_USERNAME"'",
      "PASSWORD": "'"$TEST_PASSWORD"'"
    }
  }')

TOKEN=$(echo "$COGNITO_RESPONSE" | jq -r '.AuthenticationResult.IdToken')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "ERROR: Failed to obtain Cognito token. Check secrets and Cognito app client config."
  echo "$COGNITO_RESPONSE" | jq .
  exit 1
fi

echo "  Token obtained."

# ── Auth guard tests (run for every protected endpoint) ───────────────────────
# These verify that security config is working — a request with no token must
# be rejected. Add one entry per protected endpoint.

echo ""
echo "==> Auth guard (unauthenticated requests should return 401)"

# TODO: replace with your actual endpoint paths
check "GET /users → 401 without token"   401 "$(get_unauth /users)"
check "GET /orders → 401 without token"  401 "$(get_unauth /orders)"

# ── Happy path tests ──────────────────────────────────────────────────────────
# Verify that a valid token grants access. Extend this section with all ~20
# endpoints. Use check() with the expected HTTP status for each.

echo ""
echo "==> Happy path (authenticated requests)"

# TODO: replace with your actual endpoint paths and expected status codes
check "GET /users"   200 "$(get /users)"
check "GET /orders"  200 "$(get /orders)"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
