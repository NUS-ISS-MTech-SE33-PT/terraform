# BH-08 — HTTPS / TLS / HSTS (API Gateway entry points)
# Verifies production responses include the HSTS header on public routes.

GET {{api_base_url}}/prod/spots/health
HTTP 200
[Asserts]
header "Strict-Transport-Security" exists
header "Strict-Transport-Security" contains "max-age=31536000"
header "Strict-Transport-Security" contains "includeSubDomains"

###

GET {{api_base_url}}/prod/spots/submissions/health
HTTP 200
[Asserts]
header "Strict-Transport-Security" exists
header "Strict-Transport-Security" contains "max-age=31536000"
header "Strict-Transport-Security" contains "includeSubDomains"

