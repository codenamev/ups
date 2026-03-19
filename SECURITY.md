# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| latest  | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in ups, please report it responsibly.

**Do not open a public GitHub issue for security vulnerabilities.**

Instead, please email **security@ups.dev** with:

- A description of the vulnerability
- Steps to reproduce the issue
- The potential impact
- Any suggested fixes (optional)

You should receive an acknowledgment within 48 hours. We will work with you to understand the issue and coordinate a fix before any public disclosure.

## Security Practices

- All dependencies are monitored with `bundler-audit` and `brakeman`
- API tokens are hashed using SHA-256 before storage
- Webhook payloads are signed with HMAC-SHA256
- Authentication uses time-limited magic link tokens
- Rails encrypted credentials are used for secret management
- Docker images run as a non-root user

## Disclosure Timeline

1. Report received — acknowledgment within 48 hours
2. Issue confirmed — fix developed within 7 days for critical issues
3. Fix released — coordinated disclosure after patch is available
