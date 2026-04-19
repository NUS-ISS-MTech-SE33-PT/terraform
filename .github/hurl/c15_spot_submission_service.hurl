# C-15 — Presigned URL constraints (spot-submission-service)
# Verifies presign responses expose multipart upload fields and reject mismatched file metadata.

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

# Assert — valid presign returns multipart POST fields
POST {{api_base_url}}/spots/submissions/photos/presign
Authorization: Bearer {{token}}
Content-Type: application/json
{
  "fileName": "contract.png",
  "contentType": "image/png"
}

HTTP 200
[Asserts]
jsonpath "$.uploadUrl" exists
jsonpath "$.photoUrl" exists
jsonpath "$.storageKey" exists
jsonpath "$.uploadFields.key" exists
jsonpath "$.uploadFields['Content-Type']" == "image/png"
jsonpath "$.uploadFields.policy" exists

###

# Assert — mismatched extension/content type is rejected at presign time
POST {{api_base_url}}/spots/submissions/photos/presign
Authorization: Bearer {{token}}
Content-Type: application/json
{
  "fileName": "mismatch.jpg",
  "contentType": "image/png"
}

HTTP 400
[Asserts]
header "Content-Type" contains "application/json"
jsonpath "$.message" == "File extension does not match content type."

