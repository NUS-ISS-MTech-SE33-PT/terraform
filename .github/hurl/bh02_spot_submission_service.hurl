# BH-02 — Generic error handling (spot-submission-service)
# Verifies handled validation errors use the standardized API error schema.

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

# Assert — missing presign fields return code/message/traceId without leaking internals
POST {{api_base_url}}/prod/spots/submissions/photos/presign
Authorization: Bearer {{token}}
Content-Type: application/json
{
  "fileName": "",
  "contentType": ""
}

HTTP 400
[Asserts]
header "Content-Type" contains "application/json"
jsonpath "$.code" == "validation_error"
jsonpath "$.message" == "fileName and contentType are required."
jsonpath "$.traceId" exists

