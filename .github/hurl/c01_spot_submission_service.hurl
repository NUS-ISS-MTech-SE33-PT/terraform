# C-01 — Server-side ownership validation (spot-submission-service)
# Verifies that a user cannot claim another user's uploaded photo in a submission.

# Step 1 — Obtain token for User A
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
token_a: jsonpath "$.AuthenticationResult.AccessToken"

###

# Step 2 — User A requests a presigned upload URL
POST {{api_base_url}}/spots/submissions/photos/presign
Authorization: Bearer {{token_a}}
Content-Type: application/json
{
  "fileName": "test.jpg",
  "contentType": "image/jpeg"
}

HTTP 200
[Captures]
user_a_storage_key: jsonpath "$.storageKey"
user_a_photo_url: jsonpath "$.photoUrl"

###

# Step 3 — Obtain token for User B
POST https://cognito-idp.ap-southeast-1.amazonaws.com/
X-Amz-Target: AWSCognitoIdentityProviderService.InitiateAuth
Content-Type: application/x-amz-json-1.1
{
  "AuthFlow": "USER_PASSWORD_AUTH",
  "ClientId": "{{cognito_client_id}}",
  "AuthParameters": {
    "USERNAME": "{{test_normal_username_b}}",
    "PASSWORD": "{{test_normal_password_b}}"
  }
}

HTTP 200
[Captures]
token_b: jsonpath "$.AuthenticationResult.AccessToken"

###

# Assert — User B must not be able to submit using User A's storage key
POST {{api_base_url}}/spots/submissions
Authorization: Bearer {{token_b}}
Content-Type: application/json
{
  "name": "C-01 Ownership Test Spot",
  "address": "123 Test Street, Singapore",
  "placeType": "Restaurant",
  "foodType": "Chinese",
  "openingHours": "9am-9pm",
  "district": "Tampines",
  "latitude": 1.3521,
  "longitude": 103.8198,
  "isCenter": false,
  "photoUrls": ["{{user_a_photo_url}}"],
  "photoStorageKeys": ["{{user_a_storage_key}}"]
}

HTTP 400
