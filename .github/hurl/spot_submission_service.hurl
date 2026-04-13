# Step 1 — Obtain Cognito token
POST https://cognito-idp.ap-southeast-1.amazonaws.com/
X-Amz-Target: AWSCognitoIdentityProviderService.InitiateAuth
Content-Type: application/x-amz-json-1.1
{
  "AuthFlow": "USER_PASSWORD_AUTH",
  "ClientId": "{{cognito_client_id}}",
  "AuthParameters": {
    "USERNAME": "{{test_username}}",
    "PASSWORD": "{{test_password}}"
  }
}

HTTP 200
[Captures]
token: jsonpath "$.AuthenticationResult.IdToken"

###

# Happy path — GET /spots/submissions/health
GET {{api_base_url}}/prod/spots/submissions/health

HTTP 200

###

# Auth enforced at backend layer — moderation routes require JWT even though API Gateway route is public
GET {{api_base_url}}/prod/moderation/submissions

HTTP 401

###

# POST with empty body — expect 400 (bad request), not 401, confirming auth passed
POST {{api_base_url}}/prod/spots/submissions
Authorization: Bearer {{token}}
Content-Type: application/json
{}

HTTP 400

###

# POST with empty body — expect 400 (bad request), not 401, confirming auth passed
POST {{api_base_url}}/prod/spots/submissions/photos/presign
Authorization: Bearer {{token}}
Content-Type: application/json
{}

HTTP 400
