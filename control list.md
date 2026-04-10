# Cognito Security Controls

**Source:** `modules/cognito/`

---

## Client Comparison: Admin Web vs Android (Mobile)

| Setting | Admin Web | Android (Mobile) |
|---------|-----------|------------------|
| **OAuth flow** | Authorization Code | Authorization Code |
| **SRP auth** | Yes | Yes |
| **Token revocation** | Yes | Yes |
| **Client secret** | None | None |
| **Access token validity** | 60 minutes | Not set (default) |
| **ID token validity** | 60 minutes | Not set (default) |
| **Refresh token validity** | 5 days | 30 days |
| **Auth session validity** | 3 minutes | 3 minutes |
| **Allowed auth flows** | `ALLOW_REFRESH_TOKEN_AUTH`, `ALLOW_USER_AUTH`, `ALLOW_USER_SRP_AUTH` | `ALLOW_ADMIN_USER_PASSWORD_AUTH`, `ALLOW_REFRESH_TOKEN_AUTH`, `ALLOW_USER_PASSWORD_AUTH`, `ALLOW_USER_SRP_AUTH` |
| **Prevent user existence errors** | Yes | No |
| **Propagate additional user context** | No | No |
| **OAuth scopes** | email, openid, phone, profile | email, openid, phone, profile |

> **Key differences:** The admin web client has explicit token expiry, user existence error prevention (anti-enumeration), and a more restricted auth flow set. The Android client allows `ALLOW_ADMIN_USER_PASSWORD_AUTH` and `ALLOW_USER_PASSWORD_AUTH`, which are less secure flows, and has a longer refresh token lifetime (30 days vs 5 days).

---

## User Pool Level Controls (applies to all clients)

| # | Control | Config | Framework Mapping |
|---|---------|--------|-------------------|
| 1 | **Email verification** | `auto_verified_attributes = ["email"]`, `CONFIRM_WITH_CODE` | NIST SP 800-63B (Identity Proofing), ISO 27001 A.9.4 |
| 2 | **Account recovery via verified channel** | Email (priority 1), Phone (priority 2) | NIST SP 800-63B §6.1, CIS Control 5 |

## Admin Web Client Controls

| # | Control | Config | Framework Mapping |
|---|---------|--------|-------------------|
| 1 | **OAuth 2.0 Authorization Code flow** | `allowed_oauth_flows = ["code"]` | NIST SP 800-63C, RFC 6749 §4.1 |
| 2 | **Token revocation** | `enable_token_revocation = true` | NIST SP 800-63C §5.3, RFC 7009 |
| 3 | **SRP authentication** | `ALLOW_USER_SRP_AUTH` | NIST SP 800-63B (zero-knowledge password proofs) |
| 4 | **Short-lived access & ID tokens** | `access_token_validity = 60` min, `id_token_validity = 60` min | NIST SP 800-63C §4.1, ISO 27001 A.9.4 |
| 5 | **User existence error prevention** | `prevent_user_existence_errors = "ENABLED"` | OWASP ASVS V2.2 |
| 6 | **Restricted auth flows** | `ALLOW_REFRESH_TOKEN_AUTH`, `ALLOW_USER_AUTH`, `ALLOW_USER_SRP_AUTH` only | CIS Control 5, Principle of Least Privilege |
| 7 | **Restricted OAuth scopes** | `email`, `openid`, `phone`, `profile` | OWASP ASVS V6.2, Principle of Least Privilege |

## Android (Mobile) Client Controls

| # | Control | Config | Framework Mapping |
|---|---------|--------|-------------------|
| 1 | **OAuth 2.0 Authorization Code flow** | `allowed_oauth_flows = ["code"]` | NIST SP 800-63C, RFC 6749 §4.1 |
| 2 | **Token revocation** | `enable_token_revocation = true` | NIST SP 800-63C §5.3, RFC 7009 |
| 3 | **SRP authentication** | `ALLOW_USER_SRP_AUTH` | NIST SP 800-63B (zero-knowledge password proofs) |
| 4 | **Restricted OAuth scopes** | `email`, `openid`, `phone`, `profile` | OWASP ASVS V6.2, Principle of Least Privilege |

---

## Notable Gaps

| Gap | Framework Reference |
|-----|---------------------|
| **MFA is OFF** | NIST SP 800-63B AAL2, CIS Control 5.3 |
| **Weak password policy** (min 6 chars, no complexity) | NIST SP 800-63B §5.1.1, CIS Control 5.2 |
| **No password history** (`password_history_size = 0`) | NIST SP 800-63B §5.1.1 |
| **Deletion protection inactive** | ISO 27001 A.12.3 (availability) |
| **Android client has no secret** (`generate_secret = null`) | Expected for mobile, but worth noting |
