# CloudFront & WAF Security Controls

**Source:** `environments/prod/cloudfront.tf`, `environments/prod/waf.tf`

---

## Distribution Comparison

| Setting | spot_submission | admin_web | web_static |
|---------|----------------|-----------|------------|
| **Purpose** | Spot submission photos (S3) | Admin SPA (S3) | Public web SPA (S3) |
| **HTTP version** | HTTP/2 | HTTP/2 | HTTP/2 |
| **IPv6** | Disabled | Disabled | Enabled |
| **Price class** | PriceClass_200 | PriceClass_200 | PriceClass_All |
| **Viewer protocol** | Redirect to HTTPS | Redirect to HTTPS | Redirect to HTTPS |
| **Minimum TLS** | TLSv1.2_2021 | TLSv1.2_2021 | TLSv1.2_2021 |
| **Allowed methods** | GET, HEAD | GET, HEAD | GET, HEAD |
| **OAC (SigV4)** | Yes | Yes | Yes |
| **Response headers policy** | SecurityHeadersPolicy | CORS + SecurityHeadersPolicy | None |
| **WAF** | None | None | Yes (`web_static`) |
| **Geo restriction** | None | None | None |
| **Error response caching TTL** | — | 0 (no caching) | 10s |

---

## Shared Controls (all distributions)

| # | Control | Config | Framework Mapping |
|---|---------|--------|-------------------|
| 1 | **HTTPS enforcement** | `viewer_protocol_policy = "redirect-to-https"` | NIST SP 800-52 Rev 2, PCI DSS 4.0 §6.4.1 |
| 2 | **Minimum TLS 1.2** | `minimum_protocol_version = "TLSv1.2_2021"` | NIST SP 800-52 Rev 2 §3.3, CIS Control 9 |
| 3 | **Origin Access Control (SigV4)** | `signing_behavior = "always"`, `signing_protocol = "sigv4"` | NIST SP 800-57, AWS Well-Architected Security Pillar SEC 5 |
| 4 | **Read-only method restriction** | `allowed_methods = ["GET", "HEAD"]` | Principle of Least Privilege, OWASP ASVS V13.1 |
| 5 | **HTTP/2 only** | `http_version = "http2"` | CIS Control 9 (secure transport) |

## spot_submission Controls

| # | Control | Config | Framework Mapping |
|---|---------|--------|-------------------|
| 1 | **Security response headers** | `response_headers_policy_id = "7770778d-..."` (AWS SecurityHeadersPolicy) | OWASP Secure Headers Project, CIS Control 9 |

## admin_web Controls

| # | Control | Config | Framework Mapping |
|---|---------|--------|-------------------|
| 1 | **Security + CORS response headers** | `response_headers_policy_id = "fe32e02f-..."` (AWS CORS-with-preflight-and-SecurityHeadersPolicy) | OWASP Secure Headers Project, RFC 6454 (CORS), CIS Control 9 |
| 2 | **No error response caching** | `error_caching_min_ttl = 0` on 403/404 | ISO 27001 A.14.2 (prevents stale error state) |

## web_static Controls

| # | Control | Config | Framework Mapping |
|---|---------|--------|-------------------|
| 1 | **WAF attached** | `web_acl_id = aws_wafv2_web_acl.web_static.arn` | NIST SP 800-95, PCI DSS 4.0 §6.4.2, CIS Control 9.3 |
| 2 | **IPv6 enabled** | `is_ipv6_enabled = true` | RFC 8200 (modern transport coverage) |
| 3 | **Global edge coverage** | `price_class = "PriceClass_All"` | Availability / resilience |

---

## WAF Controls (web_static only)

| # | Control | Rule / Config | Framework Mapping |
|---|---------|---------------|-------------------|
| 1 | **IP reputation blocking** | `AWSManagedRulesAmazonIpReputationList` (priority 0, enforced) | CIS Control 9.3, NIST SP 800-83 |
| 2 | **OWASP core rule set** | `AWSManagedRulesCommonRuleSet` (priority 1, enforced) | OWASP Top 10, NIST SP 800-95, PCI DSS 4.0 §6.4.2 |
| 3 | **Known bad inputs blocking** | `AWSManagedRulesKnownBadInputsRuleSet` (priority 2, enforced) | OWASP Top 10 A1 (Injection), CIS Control 9 |
| 4 | **Rate limiting** | 1,000 req / 5 min per IP → block (priority 3) | NIST SP 800-95, OWASP ASVS V13.4, CIS Control 9.2 |
| 5 | **CloudWatch metrics + sampling** | `cloudwatch_metrics_enabled = true`, `sampled_requests_enabled = true` on all rules | NIST SP 800-137, ISO 27001 A.12.4 |

---

## Notable Gaps

| Gap | Applies To | Framework Reference |
|-----|-----------|---------------------|
| **No WAF** | `spot_submission`, `admin_web` | NIST SP 800-95, PCI DSS 4.0 §6.4.2 |
| **No response headers policy** | `web_static` | OWASP Secure Headers Project |
| **No access logging configured** | All distributions | NIST SP 800-137, ISO 27001 A.12.4, PCI DSS 4.0 §10 |
| **CloudFront default certificate** (no custom domain / ACM) | All distributions | CIS Control 9, certificate lifecycle management |
| **No geo restriction** | All distributions | Risk-based access control — acceptable if global audience is intended |
| **IPv6 disabled** | `spot_submission`, `admin_web` | RFC 8200 — low risk but inconsistent with `web_static` |
| **WAF rate limit covers only web_static** | `spot_submission`, `admin_web` | OWASP ASVS V13.4 — S3 origins less exposed, but worth noting |
