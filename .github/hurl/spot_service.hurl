# Public spot routes — no auth required

GET {{api_base_url}}/spots/health

HTTP 200

###

GET {{api_base_url}}/spots

HTTP 200
[Asserts]
header "Content-Type" contains "application/json"

###

GET {{api_base_url}}/spots/{{test_spot_id}}

HTTP 200
[Asserts]
header "Content-Type" contains "application/json"
