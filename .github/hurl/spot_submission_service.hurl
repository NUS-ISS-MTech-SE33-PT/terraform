# Step 1 — Obtain Cognito token
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
token: jsonpath "$.AuthenticationResult.AccessToken"

###

# Happy path — GET /spots/submissions/health
GET {{api_base_url}}/spots/submissions/health

HTTP 200

###

# Auth enforced at the edge — moderation routes require JWT before the request reaches the service
GET {{api_base_url}}/moderation/submissions

HTTP 401

###

# POST with empty body — expect 400 (bad request), not 401, confirming auth passed
POST {{api_base_url}}/spots/submissions
Authorization: Bearer {{token}}
Content-Type: application/json
{}

HTTP 400

###

# POST with empty body — expect 400 (bad request), not 401, confirming auth passed
POST {{api_base_url}}/spots/submissions/photos/presign
Authorization: Bearer {{token}}
Content-Type: application/json
{}

HTTP 400
