# Security Controls — Presentation Priority

---

## Tier 1 — Will definitely be asked about these

| # | Gap | Where | Why It Matters |
|---|-----|-------|----------------|
| 1 | **MFA is OFF on admin client** | Cognito | Admin panel controls the whole application. A stolen password alone gives full access. Every security framework mandates MFA for privileged accounts. (NIST SP 800-63B AAL2, CIS Control 5.3) |
| 2 | **No WAF on `admin_web`, but WAF on public site** | CloudFront | Priority is backwards — the most sensitive surface has no IP reputation blocking, no OWASP rules, no rate limiting, while the public web does. Looks like an oversight. (NIST SP 800-95, PCI DSS 4.0 §6.4.2) |
| 3 | **No access logging on any CloudFront distribution** | CloudFront | Zero audit trail of who accessed what. If something goes wrong, there is nothing to investigate. Fundamental requirement across ISO 27001 A.12.4, PCI DSS §10, NIST SP 800-137. |

---

## Tier 2 — Noticeable, good to have an answer for

| # | Gap | Where | Why It Matters |
|---|-----|-------|----------------|
| 4 | **Weak password policy** (min 6 chars, no complexity) | Cognito | Six characters is below the NIST SP 800-63B §5.1.1 minimum of 8. Simple and obvious to any reviewer. |
| 5 | **No response headers policy on `web_static`** | CloudFront | The two S3 distributions have AWS security headers policies but the public web app does not. Missing CSP, X-Frame-Options, HSTS. (OWASP Secure Headers Project) |
| 6 | **Android client allows `ALLOW_ADMIN_USER_PASSWORD_AUTH`** | Cognito | Sends raw password to server instead of using SRP (zero-knowledge). Unexpected for a mobile client, which is typically the less-trusted environment. |

---

## Fix Before Presenting

If only two things get fixed, these are the ones that are hardest to explain away as intentional:

1. **Enable MFA on the admin Cognito client**
2. **Attach WAF (or at minimum a security headers policy) to `admin_web`**
