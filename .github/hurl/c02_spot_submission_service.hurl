# C-02 — RBAC enforcement (spot-submission-service)
# Verifies that moderation endpoints enforce role-based access control:
#   - No token           → 401
#   - Non-admin token    → 403
#   - Admin token        → 404 (nonexistent ID; proves request reached the handler — RBAC passed)

# --- 401: No token ---

# Assert — unauthenticated request to GET /moderation/submissions is rejected
GET {{api_base_url}}/prod/moderation/submissions
HTTP 401

###

# Assert — unauthenticated request to POST .../approve is rejected
POST {{api_base_url}}/prod/moderation/submissions/test-submission-id/approve
HTTP 401

###

# Assert — unauthenticated request to POST .../reject is rejected
POST {{api_base_url}}/prod/moderation/submissions/test-submission-id/reject
HTTP 401

###

# --- 403: Authenticated non-admin user ---

# Step 1 — Obtain token for a regular (non-admin) user
POST https://cognito-idp.ap-southeast-1.amazonaws.com/
X-Amz-Target: AWSCognitoIdentityProviderService.InitiateAuth
Content-Type: application/x-amz-json-1.1
{
  "AuthFlow": "USER_PASSWORD_AUTH",
  "ClientId": "{{cognito_client_id}}",
  "AuthParameters": {
    "USERNAME": "{{test_normal_username_a}}",
    "PASSWORD": "{{test_normal_password_a}}"
  }
}

HTTP 200
[Captures]
user_token: jsonpath "$.AuthenticationResult.AccessToken"

###

# Assert — non-admin token → GET /moderation/submissions must return 403
GET {{api_base_url}}/prod/moderation/submissions
Authorization: Bearer {{user_token}}
HTTP 403

###

# Assert — non-admin token → POST .../approve must return 403
POST {{api_base_url}}/prod/moderation/submissions/test-submission-id/approve
Authorization: Bearer {{user_token}}
HTTP 403

###

# Assert — non-admin token → POST .../reject must return 403
POST {{api_base_url}}/prod/moderation/submissions/test-submission-id/reject
Authorization: Bearer {{user_token}}
HTTP 403

###

# --- Admin token: RBAC passed (handler reached) ---

# Step 2 — Obtain token for an admin user
POST https://cognito-idp.ap-southeast-1.amazonaws.com/
X-Amz-Target: AWSCognitoIdentityProviderService.InitiateAuth
Content-Type: application/x-amz-json-1.1
{
  "AuthFlow": "USER_PASSWORD_AUTH",
  "ClientId": "{{cognito_client_id}}",
  "AuthParameters": {
    "USERNAME": "{{test_admin_username}}",
    "PASSWORD": "{{test_admin_password}}"
  }
}

HTTP 200
[Captures]
admin_token: jsonpath "$.AuthenticationResult.AccessToken"

###

# Assert — admin token → GET /moderation/submissions reaches the handler → 200
GET {{api_base_url}}/prod/moderation/submissions
Authorization: Bearer {{admin_token}}
HTTP 200

###

# Assert — admin token reaches the handler (RBAC passed); nonexistent ID → 404
# A 403 here would mean RBAC is broken
POST {{api_base_url}}/prod/moderation/submissions/nonexistent-submission-id/approve
Authorization: Bearer {{admin_token}}
HTTP 404

###

# Assert — admin token reaches the handler (RBAC passed); nonexistent ID → 404
# A 403 here would mean RBAC is broken
POST {{api_base_url}}/prod/moderation/submissions/nonexistent-submission-id/reject
Authorization: Bearer {{admin_token}}
HTTP 404
