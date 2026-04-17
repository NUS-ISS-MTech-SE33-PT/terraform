# Auth-required user routes must reject requests without a token
# Moderation endpoint auth tests live in c02_spot_submission_service.hurl

POST {{api_base_url}}/prod/spots/submissions
HTTP 401

###

POST {{api_base_url}}/prod/spots/submissions/photos/presign
HTTP 401
