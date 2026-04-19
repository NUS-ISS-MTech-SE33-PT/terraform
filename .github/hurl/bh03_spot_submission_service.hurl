# BH-03 — File upload limits (spot-submission-service)
# Verifies that oversized uploads are rejected by S3 at upload time.

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

# Step 2 — Request a valid presigned POST for JPEG uploads
POST {{api_base_url}}/spots/submissions/photos/presign
Authorization: Bearer {{token}}
Content-Type: application/json
{
  "fileName": "oversized.jpg",
  "contentType": "image/jpeg"
}

HTTP 200
[Captures]
upload_url: jsonpath "$.uploadUrl"
upload_key: jsonpath "$.uploadFields.key"
content_type_field: jsonpath "$.uploadFields['Content-Type']"
policy: jsonpath "$.uploadFields.policy"
x_amz_algorithm: jsonpath "$.uploadFields['x-amz-algorithm']"
x_amz_credential: jsonpath "$.uploadFields['x-amz-credential']"
x_amz_date: jsonpath "$.uploadFields['x-amz-date']"
x_amz_signature: jsonpath "$.uploadFields['x-amz-signature']"
x_amz_security_token: jsonpath "$.uploadFields['x-amz-security-token']"
[Asserts]
jsonpath "$.uploadFields.key" exists
jsonpath "$.uploadFields['Content-Type']" == "image/jpeg"
jsonpath "$.uploadFields.policy" exists

###

# Assert — upload larger than 5 MB fails at the S3 upload step
POST {{upload_url}}
[Multipart]
key: {{upload_key}}
Content-Type: {{content_type_field}}
policy: {{policy}}
x-amz-algorithm: {{x_amz_algorithm}}
x-amz-credential: {{x_amz_credential}}
x-amz-date: {{x_amz_date}}
x-amz-signature: {{x_amz_signature}}
x-amz-security-token: {{x_amz_security_token}}
file: file,fixtures/oversized.jpg; image/jpeg

HTTP 400

