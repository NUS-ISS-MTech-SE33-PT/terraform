# Public spot routes — no auth required

GET {{api_base_url}}/prod/spots/health

HTTP 200

###

GET {{api_base_url}}/prod/spots

HTTP 200
[Asserts]
header "Content-Type" contains "application/json"

###

GET {{api_base_url}}/prod/spots/{{test_spot_id}}

HTTP 200
[Asserts]
header "Content-Type" contains "application/json"
