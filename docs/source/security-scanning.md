# Security Scanning Guide

Comprehensive security scanning for Kolla container images using multiple vulnerability scanners and SBOM generation.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Scanners](#scanners)
- [Usage](#usage)
- [Understanding Results](#understanding-results)
- [Remediation](#remediation)
- [Best Practices](#best-practices)
- [CI/CD Integration](#cicd-integration)
- [FAQ](#faq)

---

## Overview

Kolla uses multiple security scanning tools to ensure container images are secure and compliant:

- **Trivy** - Comprehensive vulnerability scanner
- **Grype** - Additional vulnerability detection
- **Syft** - Software Bill of Materials (SBOM) generation
- **GitHub Security** - Centralized vulnerability management

### Coverage

| Scanner | OS Packages | Language Libraries | Configuration | Secrets |
|---------|-------------|-------------------|---------------|---------|
| Trivy | ✅ | ✅ | ✅ | ✅ |
| Grype | ✅ | ✅ | ❌ | ❌ |
| Syft (SBOM) | ✅ | ✅ | ❌ | ❌ |

---

## Quick Start

### Install Tools

```bash
# Install all security tools
make install-security-tools

# Or manually:
# Trivy
wget https://github.com/aquasecurity/trivy/releases/download/v0.48.0/trivy_0.48.0_Linux-64bit.deb
sudo dpkg -i trivy_0.48.0_Linux-64bit.deb

# Syft
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin

# Grype
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
```

### Scan an Image

```bash
# Quick scan with Trivy
make security-scan IMAGE=nova-compute

# Full scan with all tools
make security-scan-full IMAGE=nova-compute

# Generate SBOM
make generate-sbom IMAGE=nova-compute
```

---

## Scanners

### Trivy

**Best for:** Comprehensive vulnerability scanning

**Features:**
- OS package vulnerabilities
- Language-specific vulnerabilities (Python, Node.js, Go, etc.)
- Configuration issues
- Secret detection
- License scanning

**Usage:**

```bash
# Scan with Trivy
trivy image kolla/nova-compute:latest

# Only critical and high
trivy image --severity CRITICAL,HIGH kolla/nova-compute:latest

# JSON output
trivy image --format json -o results.json kolla/nova-compute:latest

# SARIF for GitHub Security
trivy image --format sarif -o results.sarif kolla/nova-compute:latest
```

### Grype

**Best for:** Cross-referencing Trivy results

**Features:**
- Multiple vulnerability databases
- Additional CVE detection
- Fast scanning

**Usage:**

```bash
# Scan with Grype
grype kolla/nova-compute:latest

# Specific severity
grype kolla/nova-compute:latest --fail-on high

# JSON output
grype kolla/nova-compute:latest -o json > results.json
```

### Syft (SBOM)

**Best for:** Software inventory and compliance

**Formats:**
- SPDX (ISO/IEC 5962:2021 standard)
- CycloneDX (OWASP standard)
- Syft JSON

**Usage:**

```bash
# Generate SPDX SBOM
syft kolla/nova-compute:latest -o spdx-json > sbom.spdx.json

# Generate CycloneDX SBOM
syft kolla/nova-compute:latest -o cyclonedx-json > sbom.cyclonedx.json

# All packages with details
syft kolla/nova-compute:latest -o table
```

---

## Usage

### Local Scanning

#### Scan Single Image

```bash
# Quick scan (CRITICAL + HIGH only)
make security-scan IMAGE=keystone

# Example output:
# 🔒 Scanning kolla/keystone:latest for vulnerabilities...
# 
# kolla/keystone:latest (ubuntu 24.04)
# Total: 23 (CRITICAL: 2, HIGH: 21)
# 
# ┌─────────────────────────┬────────────────┬──────────┬────────┐
# │        Library          │ Vulnerability  │ Severity │  Status│
# ├─────────────────────────┼────────────────┼──────────┼────────┤
# │ openssl                 │ CVE-2024-XXXXX │ CRITICAL │ fixed  │
# │ python3.11              │ CVE-2024-YYYYY │ HIGH     │ open   │
# └─────────────────────────┴────────────────┴──────────┴────────┘
```

#### Full Scan with All Tools

```bash
make security-scan-full IMAGE=nova-compute

# Runs:
# 1. Trivy scan (all severities)
# 2. Grype scan (cross-reference)
# 3. SBOM generation (inventory)
```

#### Generate Security Report

```bash
# Report for all images
make security-report

# Output:
# 🛡️  Security Report for Kolla Images
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 
# Scanning: kolla/base:latest
# Total: 45 (CRITICAL: 3, HIGH: 42)
# 
# Scanning: kolla/openstack-base:latest
# Total: 67 (CRITICAL: 5, HIGH: 62)
# ...
```

### CI/CD Integration

The `.github/workflows/security-scan.yml` workflow runs automatically:

**Triggers:**
- Daily at 2 AM UTC (full scan)
- On push to master/stable (core images)
- On pull requests (affected images)
- Manual via workflow_dispatch

**Features:**
- Parallel scanning (faster)
- GitHub Security tab integration
- SBOM artifact storage
- PR comments with results

---

## Understanding Results

### Severity Levels

| Severity | Description | Action Required |
|----------|-------------|-----------------|
| 🔴 **CRITICAL** | Actively exploited, high impact | **Immediate fix** |
| 🟠 **HIGH** | Serious vulnerability, likely exploitable | **Fix within 7 days** |
| 🟡 **MEDIUM** | Moderate risk, may be exploitable | **Fix within 30 days** |
| 🟢 **LOW** | Low risk, unlikely to be exploited | **Fix when convenient** |

### Vulnerability Status

- **fixed**: Patch available, update required
- **will\_not\_fix**: Vendor won't fix (end of life, etc.)
- **affected**: No patch yet, mitigation may be possible

### Example Output

```json
{
  "Target": "kolla/nova-compute:latest",
  "Vulnerabilities": [
    {
      "VulnerabilityID": "CVE-2024-12345",
      "PkgName": "openssl",
      "InstalledVersion": "3.0.2-0ubuntu1.10",
      "FixedVersion": "3.0.2-0ubuntu1.15",
      "Severity": "CRITICAL",
      "Description": "OpenSSL buffer overflow vulnerability...",
      "References": [
        "https://nvd.nist.gov/vuln/detail/CVE-2024-12345"
      ]
    }
  ]
}
```

### GitHub Security Tab

Trivy results are uploaded as SARIF format to GitHub Security:

1. Navigate to **Security > Code scanning alerts**
2. Filter by severity, package, or image
3. View detailed CVE information
4. Track remediation progress

---

## Remediation

### Step 1: Prioritize

Focus on:
1. **CRITICAL** vulnerabilities first
2. Actively exploited CVEs
3. Internet-facing services

### Step 2: Identify Fix

```bash
# Check if fix is available
trivy image --severity CRITICAL kolla/nova-compute:latest | grep "Fixed Version"
```

**Common fixes:**

| Issue | Fix |
|-------|-----|
| OS package | Update base image or package |
| Python library | Update in requirements.txt |
| Node.js package | Update package.json |
| Go module | Update go.mod |

### Step 3: Apply Fix

#### Update Base Image

```dockerfile
# Before
FROM ubuntu:24.04

# After (with updates)
FROM ubuntu:24.04
RUN apt-get update && apt-get upgrade -y
```

#### Update Python Dependencies

```bash
# Update specific package
sed -i 's/package==1.0.0/package==1.1.0/' requirements.txt

# Rebuild
make build-cached IMAGE=nova-compute
```

#### Patch Configuration

```bash
# Apply security patch
COPY security-patch.sh /tmp/
RUN /tmp/security-patch.sh && rm /tmp/security-patch.sh
```

### Step 4: Verify Fix

```bash
# Rebuild and rescan
make build-cached IMAGE=nova-compute
make security-scan IMAGE=nova-compute

# Verify CVE is gone
trivy image kolla/nova-compute:latest | grep CVE-2024-12345
# (should return nothing)
```

### Step 5: Document

```markdown
## Security Fix: CVE-2024-12345

**Issue:** OpenSSL buffer overflow
**Severity:** CRITICAL
**Fix:** Updated openssl from 3.0.2-0ubuntu1.10 to 3.0.2-0ubuntu1.15
**Images affected:** nova-compute, neutron-server, keystone
**Date:** 2025-10-31
```

---

## Best Practices

### 1. Regular Scanning

```yaml
# .github/workflows/security-scan.yml
on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM
```

**Why:** New vulnerabilities are discovered daily

### 2. Scan Before Deployment

```bash
# In deployment pipeline
make security-scan IMAGE=nova-compute || exit 1

# Block deployment if critical issues found
if trivy image --severity CRITICAL kolla/nova-compute:latest; then
  echo "✅ No critical vulnerabilities"
else
  echo "❌ Critical vulnerabilities found!"
  exit 1
fi
```

### 3. Keep Base Images Updated

```bash
# Update base images regularly
docker pull ubuntu:24.04
docker pull python:3.11

# Rebuild all images
make build-cached-multi
```

### 4. Use SBOM for Compliance

```bash
# Generate SBOM for all production images
for image in nova-compute neutron-server keystone; do
  make generate-sbom IMAGE=$image
done

# Store SBOMs with versioned releases
# Required for: SOC2, ISO 27001, NIST SSDF
```

### 5. Automate Updates

```json
// renovate.json
{
  "packageRules": [
    {
      "matchPackagePatterns": ["security"],
      "automerge": true,
      "labels": ["security"]
    }
  ]
}
```

### 6. Layer Security Scanning

```
┌─────────────────────────────────────┐
│   1. Source Code Scanning           │
│   (pre-commit, IDE plugins)         │
├─────────────────────────────────────┤
│   2. Build-time Scanning            │
│   (CI/CD, fail fast)                │
├─────────────────────────────────────┤
│   3. Registry Scanning              │
│   (post-build, continuous)          │
├─────────────────────────────────────┤
│   4. Runtime Scanning               │
│   (production monitoring)           │
└─────────────────────────────────────┘
```

---

## CI/CD Integration

### GitHub Actions Workflow

The security scan workflow provides:

**Daily Scans:**
- All production images
- Full vulnerability database
- SBOM generation
- Results uploaded to Security tab

**PR Scans:**
- Only affected images
- Quick scan (CRITICAL + HIGH)
- PR comments with summary

**Manual Scans:**
- Custom image selection
- Flexible scan types
- On-demand analysis

### Workflow Customization

```yaml
# .github/workflows/security-scan.yml

# Customize image list
inputs:
  images:
    default: 'nova-compute,neutron-server,keystone'

# Customize scan type
inputs:
  scan_type:
    options:
      - quick      # CRITICAL + HIGH only
      - full       # All severities
      - critical-only  # CRITICAL only
```

### Integration with Other Tools

**Slack Notifications:**

```yaml
- name: Notify Slack
  if: failure()
  run: |
    curl -X POST ${{ secrets.SLACK_WEBHOOK }} \
      -d '{"text":"🚨 Security scan failed: ${{ github.sha }}"}'
```

**PagerDuty Alerts:**

```yaml
- name: Alert PagerDuty
  if: steps.check-critical.outputs.count > 0
  run: |
    curl -X POST https://events.pagerduty.com/v2/enqueue \
      -H 'Content-Type: application/json' \
      -d '{"routing_key":"${{ secrets.PAGERDUTY_KEY }}", ...}'
```

---

## FAQ

### Q: How often should I scan?

**A:** 
- **Daily**: Automated scans via cron
- **Before deployment**: Manual verification
- **After incidents**: Immediate scan of affected images

### Q: What do I do about unfixable vulnerabilities?

**A:**

1. Check if vulnerability is actually exploitable in your context
2. Apply mitigation controls (network isolation, WAF rules)
3. Document accepted risk with justification
4. Monitor for future patches

### Q: Can I scan images from other registries?

**A:** Yes!

```bash
# Scan from Docker Hub
trivy image docker.io/library/ubuntu:24.04

# Scan from private registry
trivy image myregistry.com/myorg/myimage:tag --username user --password pass
```

### Q: How do I handle large number of vulnerabilities?

**A:**

1. **Prioritize**: Focus on CRITICAL first
2. **Automate**: Use tools to auto-update dependencies
3. **Deduplicate**: Many CVEs affect multiple images (fix base)
4. **Filter**: Ignore LOW/MEDIUM if resource-constrained

### Q: What's the difference between Trivy and Grype?

**A:**

| Feature | Trivy | Grype |
|---------|-------|-------|
| Database | NVD, OS vendors | Multiple sources |
| Language support | 15+ | 10+ |
| Configuration scan | ✅ | ❌ |
| Secret detection | ✅ | ❌ |
| Speed | Fast | Very fast |
| Accuracy | Very high | High |

**Recommendation:** Use both for maximum coverage!

### Q: Are SBOMs required for compliance?

**A:** Increasingly yes:

- **US Executive Order 14028**: Requires SBOM for federal software
- **SOC 2**: Often requires software inventory
- **ISO 27001**: Asset management includes software components
- **NIST SSDF**: Recommends SBOM for supply chain security

---

## Additional Resources

- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Grype Documentation](https://github.com/anchore/grype)
- [Syft Documentation](https://github.com/anchore/syft)
- [SPDX Specification](https://spdx.dev/)
- [CycloneDX Specification](https://cyclonedx.org/)
- [NIST NVD](https://nvd.nist.gov/)
- [GitHub Security Features](https://docs.github.com/en/code-security)

---

**Last updated:** October 31, 2025
