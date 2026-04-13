# All protected routes must reject requests without a token

POST {{api_base_url}}/prod/spots/{{test_spot_id}}/reviews
HTTP 401

###

GET {{api_base_url}}/prod/users/me/reviews
HTTP 401

###

GET {{api_base_url}}/prod/users/me/favorites
HTTP 401

###

GET {{api_base_url}}/prod/spots/{{test_spot_id}}/favorite
HTTP 401

###

PUT {{api_base_url}}/prod/spots/{{test_spot_id}}/favorite
HTTP 401

###

DELETE {{api_base_url}}/prod/spots/{{test_spot_id}}/favorite
HTTP 401
