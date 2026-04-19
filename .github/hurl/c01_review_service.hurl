# C-01 — Server-side ownership validation (review-service)
# Verifies that GET /users/me/reviews returns only the token owner's reviews.

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

# Step 2 — Create a review as User A
POST {{api_base_url}}/spots/{{test_spot_id}}/reviews
Authorization: Bearer {{token_a}}
Content-Type: application/json
{
  "spotId": "{{test_spot_id}}",
  "tasteRating": 4,
  "environmentRating": 4,
  "serviceRating": 4,
  "pricePerPerson": 10,
  "text": "C-01 ownership test review"
}

HTTP 200
[Captures]
review_id: jsonpath "$.id"

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

# Assert — User B's review list must not contain User A's review
GET {{api_base_url}}/users/me/reviews
Authorization: Bearer {{token_b}}

HTTP 200
[Asserts]
jsonpath "$.items[*].id" not includes {{review_id}}
