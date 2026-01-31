# vulner

OS and container vulnerability scanner with remediation planning. Single binary, no API keys required.

## What it does

- Scans installed packages for known CVEs via [OSV.dev](https://osv.dev)
- Runs CIS benchmark checks against Linux hosts
- Audits container images and Dockerfiles for misconfigurations
- Generates remediation plans with fix commands
- Outputs results as CLI table, JSON, or HTML report

## Install

```bash
go install github.com/vulner/vulner/cmd/vulner@latest
```

Or build from source:

```bash
git clone https://github.com/aff0gat000/vulner.git
cd vulner
make build
```

## Usage

```bash
# Scan local OS
vulner scan --type os

# JSON output
vulner scan --type os --output json

# HTML report
vulner scan --type os --output html --output-file report.html

# Scan a container image
vulner scan ubuntu:22.04 --type container

# Filter by severity
vulner scan --type os --severity critical,high

# Skip CIS checks
vulner scan --type os --skip-cis

# Offline mode (cached DB only)
vulner scan --type os --offline

# Update local vulnerability DB cache
vulner update-db
```

## Docker

```bash
# Build
docker build -t vulner .

# Scan the host OS from inside the container
docker run --rm -v /:/host:ro vulner scan --type os --rootfs /host
```

## Development

```bash
# Install dev tools (golangci-lint, gosec, govulncheck)
make tools

# Run full local CI pipeline
make check

# Run with security scans + coverage
make check-full

# Run tests
make test

# Coverage report
make coverage-html

# See all targets
make help
```

## Project Structure

```
cmd/vulner/          CLI entrypoint (cobra)
pkg/scanner/         OS detection, package scanning, CIS checks, container checks
pkg/vulndb/          OSV.dev client and local DB cache
pkg/remediation/     Remediation plan generation
pkg/report/          Output formatters (table, JSON, HTML)
pkg/models/          Shared types
benchmarks/          Declarative YAML check definitions
templates/           HTML report template
```

## License

MIT
