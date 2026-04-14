# Auth-required routes must reject requests without a token

POST {{api_base_url}}/prod/spots/submissions
HTTP 401

###

POST {{api_base_url}}/prod/spots/submissions/photos/presign
HTTP 401

###

GET {{api_base_url}}/prod/moderation/submissions
HTTP 401

###

POST {{api_base_url}}/prod/moderation/submissions/test-submission-id/approve
HTTP 401

###

POST {{api_base_url}}/prod/moderation/submissions/test-submission-id/reject
HTTP 401
