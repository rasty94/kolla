# 🔒 Container Security Scanning Guide

> **Coverage:** Multiple CVE databases  
> **Scanners:** Trivy + Grype + SBOM  
> **Status:** Production Ready  
> **Last Updated:** November 1, 2025

## Table of Contents

- [Overview](#overview)
- [Scanners & Tools](#scanners--tools)
- [Setup & Configuration](#setup--configuration)
- [Usage](#usage)
- [Understanding Results](#understanding-results)
- [Remediation](#remediation)
- [CI/CD Integration](#cicd-integration)
- [Best Practices](#best-practices)
- [FAQ](#faq)

---

## Overview

Comprehensive container security scanning provides multiple layers of vulnerability detection to ensure production-ready images.

### Security Pipeline

```
┌─────────────────────────────────────────────────┐
│            Code Commit to Repository            │
└─────────────────┬───────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────┐
│          Docker Image Build                     │
│  • Dockerfile validation                        │
│  • Base image selection                         │
│  • Dependency management                        │
└─────────────────┬───────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────┐
│          Automated Security Scanning            │
│  ┌─────────────┐  ┌────────────┐  ┌──────────┐ │
│  │   Trivy     │  │   Grype    │  │   SBOM   │ │
│  │ CVE Scanner │  │  Analyzer  │  │ Generator│ │
│  └─────────────┘  └────────────┘  └──────────┘ │
└─────────────────┬───────────────────────────────┘
                  │
                  ▼
        ┌─────────────────────────┐
        │  GitHub Security Tab    │
        │  • SARIF Upload         │
        │  • Code Scanning        │
        │  • Dependency Review    │
        └────────────┬────────────┘
                     │
           ┌─────────┴──────────┐
           │                    │
           ▼                    ▼
      ✅ PASS          ❌ FAIL (Review)
   Ready for          Action Required
   Production
```

### Three-Tier Security Scanning

| Tier | Scanner | Database | Strength |
|------|---------|----------|----------|
| **1** | Trivy | NVD, Ghsa, Oval | Comprehensive CVE coverage |
| **2** | Grype | Anchore data | High-confidence detections |
| **3** | SBOM | Syft analysis | Supply chain visibility |

---

## Scanners & Tools

### 1. Trivy (Aqua Security)

**Purpose:** Fast, accurate vulnerability scanning  
**Database:** NVD + GitHub Advisory + OSV + Advisories

```bash
# Scan image for all severities
trivy image kolla/nova-compute:latest

# Scan with specific severity
trivy image --severity CRITICAL,HIGH kolla/nova-compute:latest

# JSON output
trivy image --format json kolla/nova-compute:latest

# SARIF for GitHub
trivy image --format sarif kolla/nova-compute:latest
```

**Strengths:**
- ✅ Fastest scanner
- ✅ Minimal setup
- ✅ Large CVE database
- ✅ Multi-format output

### 2. Grype (Anchore)

**Purpose:** High-confidence vulnerability detection  
**Database:** Multiple aggregated sources

```bash
# Scan image
grype kolla/nova-compute:latest

# With failing threshold
grype kolla/nova-compute:latest -f high

# SARIF output
grype kolla/nova-compute:latest -o sarif
```

**Strengths:**
- ✅ Different vulnerability source
- ✅ Catches what Trivy might miss
- ✅ Very accurate
- ✅ Supply chain awareness

### 3. Syft (SBOM Generator)

**Purpose:** Software Bill of Materials generation  
**Output:** SPDX, CycloneDX formats

```bash
# Generate SPDX JSON SBOM
syft kolla/nova-compute:latest -o spdx-json > sbom.spdx.json

# Generate CycloneDX JSON
syft kolla/nova-compute:latest -o cyclonedx-json > sbom.cyclonedx.json

# View in table format
syft kolla/nova-compute:latest
```

**What's in SBOM:**
- Package inventory
- Dependency tree
- License information
- Component versions

---

## Setup & Configuration

### Prerequisites

```bash
# Install tools locally
make install-security-tools

# Or manually:

# Trivy
wget https://github.com/aquasecurity/trivy/releases/download/v0.48.0/trivy_0.48.0_Linux-64bit.deb
sudo dpkg -i trivy_0.48.0_Linux-64bit.deb

# Grype
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

# Syft
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
```

### 1. Local Setup

```bash
# Install tools
make install-security-tools

# Verify installation
trivy version
grype version
syft version
```

### 2. GitHub Actions Setup

The workflow `.github/workflows/security-scan.yml` provides:

- ✅ Automatic daily scans
- ✅ PR vulnerability checks
- ✅ SARIF upload to Security tab
- ✅ SBOM generation and storage
- ✅ Severity-based filtering

### 3. Configure Severity Thresholds

```yaml
# In .github/workflows/security-scan.yml

# High severity only (blocking)
severity: 'CRITICAL,HIGH'

# All findings (informational)
severity: 'CRITICAL,HIGH,MEDIUM,LOW'

# Critical only (very strict)
severity: 'CRITICAL'
```

### 4. Setup Notifications

```yaml
# Add to workflow for alerts
security-notifications:
  runs-on: ubuntu-latest
  if: failure()
  steps:
    - name: Slack notification
      run: |
        curl -X POST ${{ secrets.SLACK_WEBHOOK }} \
          -d '{"text": "Security scan found vulnerabilities"}'
```

---

## Usage

### Makefile Commands

```bash
# Run comprehensive scan
make security-scan

# Scan specific image
make scan-image
# → Prompts for image name

# Generate SBOM
make generate-sbom

# Full security report
make security-report

# Install tools
make install-security-tools
```

### Local Scanning

```bash
# Scan base image
trivy image kolla/base:latest

# With JSON output
trivy image --format json kolla/nova-compute:latest > results.json

# High severity only
trivy image --severity HIGH,CRITICAL kolla/nova-compute:latest

# Generate SBOM
syft kolla/nova-compute:latest -o spdx-json > sbom.json

# Check with Grype too
grype kolla/nova-compute:latest
```

### CI/CD Scanning

```bash
# Triggered automatically on:
# 1. Push to master/stable/* branches
# 2. Pull requests
# 3. Daily schedule (2 AM UTC)

# Results appear in:
# 1. GitHub Security tab
# 2. PR checks
# 3. SARIF artifacts
```

---

## Understanding Results

### Severity Levels

| Level | Impact | Action |
|-------|--------|--------|
| **CRITICAL** | Immediate threat | Block deployment, fix now |
| **HIGH** | Important | Fix before release |
| **MEDIUM** | Moderate | Plan remediation |
| **LOW** | Minor | Monitor |
| **INFO** | Informational | Note for records |

### Reading Trivy Output

```
kolla/nova-compute:latest (debian 12.1)

Found 23 vulnerabilities

┌────────────────────┬──────────┬───────────┐
│ Library            │ Severity │ Fixed In  │
├────────────────────┼──────────┼───────────┤
│ openssl/1.1.1k-1   │ HIGH     │ 1.1.1l-1  │
│ curl/7.68.0-1      │ MEDIUM   │ 7.68.0-2  │
│ bash/5.0-4         │ CRITICAL │ 5.0-5     │
└────────────────────┴──────────┴───────────┘

Passed checks: 12
Failed checks: 3
```

### SARIF Report

```json
{
  "version": "2.1.0",
  "runs": [
    {
      "tool": {"driver": {"name": "Trivy"}},
      "results": [
        {
          "ruleId": "CVE-2024-1234",
          "message": {"text": "OpenSSL vulnerability"},
          "level": "error",
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {"uri": "debian:12"}
              }
            }
          ]
        }
      ]
    }
  ]
}
```

### SBOM Contents

```json
{
  "SPDXID": "SPDXRef-DOCUMENT",
  "spdxVersion": "SPDX-2.3",
  "creationInfo": {
    "created": "2024-11-01T10:30:00Z",
    "creators": ["Tool: syft"]
  },
  "packages": [
    {
      "SPDXID": "SPDXRef-Package-openssl",
      "name": "openssl",
      "versionInfo": "1.1.1k-1+deb11u1",
      "downloadLocation": "NOASSERTION",
      "filesAnalyzed": false
    }
  ]
}
```

---

## Remediation

### Fix Critical Vulnerabilities

```bash
# Step 1: Identify package
trivy image --format json kolla/nova-compute:latest | \
  jq '.Results[] | select(.Severity=="CRITICAL")'

# Step 2: Update in Dockerfile
# Change: RUN apt-get install openssl=1.1.1k-1
# To:     RUN apt-get install openssl=1.1.1l-1

# Step 3: Rebuild image
make build-cached

# Step 4: Rescan
make scan-image
```

### Remediation Strategy

```
Vulnerability Found
        │
        ▼
   ┌─────────────────────┐
   │ Severity Check      │
   └──────┬──────────────┘
          │
    ┌─────┴─────────┐
    │               │
    ▼               ▼
CRITICAL        MEDIUM/LOW
    │               │
    │               ▼
    │          ┌──────────────┐
    │          │ File Issue?  │
    │          └──┬───────┬───┘
    │             │       │
    │             ▼       ▼
    │           Yes      Skip
    │             │       │
    │             ▼       ▼
    ▼        Plan Fix   Review
 BLOCK       Track      Later
  Build
```

### Common Fixes

```bash
# Update base image
# Before: FROM ubuntu:22.04
# After:  FROM ubuntu:24.04

# Update packages
apt-get update && apt-get upgrade

# Remove vulnerable component
# If not needed, just remove it!

# Use alternative
# If package vulnerable, find alternative

# Pin to fixed version
pip install package==1.2.3  # With fix
```

---

## CI/CD Integration

### GitHub Actions Workflow

The `.github/workflows/security-scan.yml` provides:

```yaml
on:
  schedule:
    - cron: '0 2 * * *'  # Daily 2 AM
  push:
    branches: [master, stable/*]
  pull_request:
    branches: [master, stable/*]

jobs:
  trivy-scan:
    # Matrix of images
    # SARIF upload
    # Detailed reporting
  
  grype-scan:
    # Alternative scanner
    # Secondary validation
  
  sbom-generation:
    # SPDX format
    # CycloneDX format
    # Artifact storage
  
  security-report:
    # Summary generation
    # Notifications
```

### PR Integration

When security scan runs on PR:

1. ✅ Scans all images
2. ✅ Reports findings in checks
3. ✅ Blocks merge if CRITICAL/HIGH
4. ✅ Shows in PR timeline

### Block Deployments on Critical Vulns

```yaml
enforce-security:
  if: github.ref == 'refs/heads/master'
  steps:
    - name: Check for critical vulns
      run: |
        # Fail if CRITICAL/HIGH found
        trivy image --severity CRITICAL,HIGH \
          --exit-code 1 \
          kolla/nova-compute:latest
```

---

## Best Practices

### 1. Regular Scanning

```bash
# Daily automated scans
schedule:
  - cron: '0 2 * * *'

# PR scanning
on: [pull_request]

# On-demand local scans
make security-scan
```

### 2. Keep Base Images Updated

```dockerfile
# ❌ Outdated base
FROM ubuntu:20.04

# ✅ Latest LTS
FROM ubuntu:24.04

# ✅ Specific secure version
FROM ubuntu:24.04@sha256:abcd1234...
```

### 3. Minimal Dependencies

```dockerfile
# ❌ All possible packages
RUN apt-get install python3 python3-dev \
    build-essential gcc g++ make git curl wget

# ✅ Only what you need
RUN apt-get install python3 \
    && apt-get install --no-install-recommends \
       python3-pip
```

### 4. Keep Dockerfile Clean

```dockerfile
# ❌ Multiple RUN commands
RUN apt-get update
RUN apt-get install python3
RUN apt-get clean

# ✅ Single RUN command
RUN apt-get update && \
    apt-get install python3 && \
    apt-get clean
```

### 5. Use Distroless Images

```dockerfile
# ❌ Full OS with vulnerabilities
FROM ubuntu:24.04
RUN apt-get install python3
COPY app /app

# ✅ Minimal attack surface
FROM python:3.11-slim
COPY app /app
```

### 6. Document SBOM

```bash
# Store SBOM in repository
sbom/
  ├── nova-compute-sbom.spdx.json
  ├── neutron-server-sbom.spdx.json
  └── keystone-sbom.spdx.json

# Version with releases
git tag -a v2025.1 \
  -m "Release with SBOM: nova-compute-sbom.spdx.json"
```

---

## FAQ

### Q: How often are CVE databases updated?

A: Trivy updates daily, Grype updates multiple times daily. Latest scan reflects current data.

### Q: What if scanner finds false positives?

A: Review the CVE details. False positives are rare but can happen. You can:

```bash
# Skip specific CVE
trivy image --skip-cve CVE-2024-1234 \
  kolla/nova-compute:latest

# Or ignore in config
~/.trivy/trivy.yaml:
  skip-cves:
    - CVE-2024-1234
```

### Q: Should I fail on MEDIUM severity?

A: Depends on your risk tolerance:

```
Strict:  CRITICAL (immediately block)
Medium:  CRITICAL + HIGH (security-focused)
Loose:   All (informational)
```

### Q: Can I use just one scanner?

A: Yes, but multiple scanners are better:
- Trivy: Fastest, most comprehensive
- Grype: High-confidence alternative
- Using both catches more vulns

### Q: How do I generate SBOM for compliance?

```bash
# Generate SPDX format (common for compliance)
make generate-sbom

# Store with release
git tag v2025.1 && \
  push sbom/ to artifact storage

# Use for supply chain verification
```

### Q: What about container runtime vulnerabilities?

A: This covers image content only. For runtime security, use:
- Falco (runtime monitoring)
- Kyverno (policy enforcement)
- AppArmor/SELinux (kernel security)

### Q: Can I scan private registries?

A: Yes, with authentication:

```bash
# Trivy with Docker auth
trivy image --registry-token $TOKEN \
  private.registry/kolla/nova-compute:latest
```

### Q: How do I track vulnerability trends?

A: Save scan results:

```bash
# Store timestamped results
trivy image --format json \
  kolla/nova-compute:latest > \
  results/$(date +%Y-%m-%d).json

# Compare over time
jq '.Results | length' results/*.json
```

---

## Integration with Build Cache

Both features work together perfectly:

```bash
# Build with optimization
make build-cached

# Scan the built image
make security-scan

# Both complete in <10 minutes total
```

See [build-cache.md](./build-cache.md) for details.

---

## Further Reading

- 🔗 [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- 🔗 [Grype Documentation](https://github.com/anchore/grype)
- 🔗 [SPDX Specification](https://spdx.dev/)
- 🔗 [CycloneDX Format](https://cyclonedx.org/)
- 🔗 [NIST NVD](https://nvd.nist.gov/)

---

**Last Updated:** November 1, 2025  
**Maintainer:** Kolla Security Team  
**License:** Apache 2.0
