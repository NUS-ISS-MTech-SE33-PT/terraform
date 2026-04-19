# C-16 — File header validation (spot-submission-service)
# Verifies the backend rejects uploaded files whose bytes do not match the declared image type.

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
POST {{api_base_url}}/prod/spots/submissions/photos/presign
Authorization: Bearer {{token}}
Content-Type: application/json
{
  "fileName": "invalid.jpg",
  "contentType": "image/jpeg"
}

HTTP 200
[Captures]
upload_url: jsonpath "$.uploadUrl"
photo_url: jsonpath "$.photoUrl"
storage_key: jsonpath "$.storageKey"
upload_key: jsonpath "$.uploadFields.key"
content_type_field: jsonpath "$.uploadFields['Content-Type']"
policy: jsonpath "$.uploadFields.policy"
x_amz_algorithm: jsonpath "$.uploadFields['x-amz-algorithm']"
x_amz_credential: jsonpath "$.uploadFields['x-amz-credential']"
x_amz_date: jsonpath "$.uploadFields['x-amz-date']"
x_amz_signature: jsonpath "$.uploadFields['x-amz-signature']"
x_amz_security_token: jsonpath "$.uploadFields['x-amz-security-token']"

###

# Step 3 — Upload a fake JPEG payload that still satisfies the S3 POST policy
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
file: file,fixtures/invalid.jpg; image/jpeg

HTTP 204

###

# Assert — submission is rejected because the uploaded bytes are not a real image
POST {{api_base_url}}/prod/spots/submissions
Authorization: Bearer {{token}}
Content-Type: application/json
{
  "name": "C-16 Header Validation Test Spot",
  "address": "123 Test Street, Singapore",
  "placeType": "Restaurant",
  "foodType": "Chinese",
  "openingHours": "9am-9pm",
  "district": "Tampines",
  "latitude": 1.3521,
  "longitude": 103.8198,
  "isCenter": false,
  "photoUrls": ["{{photo_url}}"],
  "photoStorageKeys": ["{{storage_key}}"]
}

HTTP 400
[Asserts]
header "Content-Type" contains "application/json"
jsonpath "$.message" == "Unsupported file header."

