# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in vulner, please report it responsibly:

1. **Do not** open a public GitHub issue.
2. Email the maintainers or use GitHub's private vulnerability reporting feature.
3. Include steps to reproduce, impact assessment, and any suggested fix.

We will acknowledge your report within 48 hours and aim to release a fix promptly.

## Scope

Vulner is a security auditing tool that intentionally reads system files and executes commands (for CIS benchmark checks). This is by design. The following are **not** considered vulnerabilities:

- Reading arbitrary filesystem paths when run as root (required for scanning)
- Executing shell commands defined in benchmark YAML files (these are operator-controlled)
- Network requests to OSV.dev API (required for vulnerability lookups)

## Security Measures in This Project

- Dependencies are scanned with `govulncheck` on every CI run
- Container image is scanned with Trivy in CI
- Static analysis with `gosec` catches common Go security issues
- Minimal Docker image (Alpine-based, non-root user)
- No secrets or API keys required for basic operation
