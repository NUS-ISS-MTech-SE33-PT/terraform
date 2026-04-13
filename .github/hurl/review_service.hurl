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
token: jsonpath "$.AuthenticationResult.AccessToken"

###

# Happy path — GET /users/me/reviews
GET {{api_base_url}}/prod/users/me/reviews
Authorization: Bearer {{token}}

HTTP 200
[Asserts]
header "Content-Type" contains "application/json"

###

# Happy path — GET /users/me/favorites
GET {{api_base_url}}/prod/users/me/favorites
Authorization: Bearer {{token}}

HTTP 200
[Asserts]
header "Content-Type" contains "application/json"

###

# Happy path — GET /spots/{id}/favorite
GET {{api_base_url}}/prod/spots/{{test_spot_id}}/favorite
Authorization: Bearer {{token}}

HTTP 200
[Asserts]
header "Content-Type" contains "application/json"

###

# POST with empty body — expect 400 (bad request), not 401, confirming auth passed
POST {{api_base_url}}/prod/spots/{{test_spot_id}}/reviews
Authorization: Bearer {{token}}
Content-Type: application/json
{}

HTTP 400
