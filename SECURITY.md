# Security Policy

## Supported Versions

Kolla follows the OpenStack release cycle and provides security updates for supported versions.

| Version | Supported          | End of Support |
| ------- | ------------------ | -------------- |
| 2025.1  | :white_check_mark: | TBD            |
| 2024.2  | :white_check_mark: | April 2026     |
| 2024.1  | :white_check_mark: | October 2025   |
| < 2024.1| :x:                | Ended          |

For detailed information about OpenStack release cycles, please visit the [OpenStack Releases](https://releases.openstack.org/) page.

## Reporting a Vulnerability

The Kolla project takes security seriously. We appreciate your efforts to responsibly disclose your findings.

### Where to Report

**Please DO NOT report security vulnerabilities through public GitHub issues.**

Instead, please report security vulnerabilities to the OpenStack Vulnerability Management Team (VMT):

- **Email:** [openstack-security@lists.openstack.org](mailto:openstack-security@lists.openstack.org)
- **Process:** Follow the [OpenStack Security reporting process](https://security.openstack.org/vmt-process.html)

For more information about OpenStack security, visit: https://security.openstack.org/

### What to Include

When reporting a vulnerability, please include the following information:

1. **Description** - A clear description of the vulnerability
2. **Impact** - What can an attacker accomplish by exploiting this vulnerability?
3. **Affected Components** - Which parts of Kolla are affected?
4. **Affected Versions** - Which versions are impacted?
5. **Steps to Reproduce** - Detailed steps to reproduce the issue
6. **Proof of Concept** - Sample code or commands demonstrating the vulnerability (if applicable)
7. **Suggested Fix** - If you have ideas on how to fix the issue (optional)
8. **Your Contact Information** - So we can reach you for clarifications

### What to Expect

After submitting a vulnerability report, you can expect:

1. **Acknowledgment** - Within 48 hours, you'll receive confirmation that we received your report
2. **Initial Assessment** - Within 5 business days, we'll provide an initial assessment
3. **Regular Updates** - You'll receive updates on the progress every 5-10 business days
4. **Resolution Timeline:**
   - **Critical vulnerabilities:** Patches within 1-2 weeks
   - **High severity:** Patches within 2-4 weeks
   - **Medium/Low severity:** Patches within 4-8 weeks

### Disclosure Policy

Kolla follows the [OpenStack Vulnerability Management Process](https://security.openstack.org/vmt-process.html):

1. **Coordinated Disclosure** - We believe in responsible disclosure
2. **Embargo Period** - Security issues are kept private until a fix is available
3. **Public Disclosure** - Vulnerabilities are publicly disclosed after patches are released
4. **Credit** - Security researchers who report vulnerabilities responsibly will be credited in the security advisory (unless they prefer to remain anonymous)

## Security Best Practices

When deploying Kolla, we recommend following these security best practices:

### Container Security

- **Keep Images Updated** - Regularly update to the latest Kolla images
- **Scan Images** - Use container scanning tools (e.g., Trivy, Clair) to detect vulnerabilities
- **Minimal Images** - Use minimal base images when possible
- **Read-Only Filesystems** - Configure containers with read-only root filesystems where applicable
- **Non-Root Users** - Run containers as non-root users when possible

### Network Security

- **Firewall Rules** - Configure strict firewall rules between OpenStack components
- **TLS/SSL** - Enable TLS for all API endpoints and internal communication
- **Network Segmentation** - Isolate management, storage, and tenant networks
- **API Rate Limiting** - Implement rate limiting on public-facing APIs

### Access Control

- **Strong Passwords** - Use strong, randomly generated passwords for all services
- **Ansible Vault** - Store sensitive data in Ansible Vault
- **Secrets Management** - Consider using external secrets management (e.g., HashiCorp Vault)
- **Regular Audits** - Regularly audit access logs and service accounts
- **Principle of Least Privilege** - Grant minimum necessary permissions

### Docker/Podman Security

- **Secure Docker Daemon** - Protect the Docker/Podman daemon socket
- **Content Trust** - Enable Docker Content Trust for image verification
- **Security Scanning** - Regularly scan your registry for vulnerabilities
- **Registry Authentication** - Secure your container registry with authentication

### Build-Time Security

- **Verified Sources** - Only use trusted base images and package sources
- **Dependency Checking** - Regularly audit Python and system package dependencies
- **Build Reproducibility** - Ensure builds are reproducible for security audits
- **Supply Chain Security** - Verify signatures of downloaded packages

### Operational Security

- **Regular Updates** - Keep your Kolla deployment updated with security patches
- **Monitoring** - Implement security monitoring and alerting
- **Incident Response** - Have an incident response plan in place
- **Backup & Recovery** - Maintain secure, tested backups
- **Security Scanning** - Regularly scan your deployment for vulnerabilities

## Security Advisories

Security advisories for Kolla are published through:

- **OpenStack Security Advisories (OSSA):** https://security.openstack.org/ossa/
- **Kolla Launchpad:** https://bugs.launchpad.net/kolla/+bugs?field.tag=security
- **OpenStack Mailing Lists:** [openstack-discuss@lists.openstack.org](mailto:openstack-discuss@lists.openstack.org) with `[security]` tag

Subscribe to the [OpenStack Announce mailing list](http://lists.openstack.org/cgi-bin/mailman/listinfo/openstack-announce) to receive security announcements.

## Security Contacts

- **OpenStack Vulnerability Management Team (VMT):** openstack-security@lists.openstack.org
- **Kolla PTL (Project Technical Lead):** See [OpenStack Governance - Kolla](https://governance.openstack.org/tc/reference/projects/kolla.html)
- **OpenStack Security Team:** https://wiki.openstack.org/wiki/Security

## Vulnerability Disclosure Timeline

Our typical vulnerability disclosure process follows this timeline:

```
Day 0:  Vulnerability reported to openstack-security@lists.openstack.org
Day 1-2: VMT acknowledges receipt
Day 2-7: VMT validates and assesses severity
Day 7-14: Fix is developed in private
Day 14+: Coordinated disclosure with downstream distributors
Day X: Public disclosure and patch release
```

The exact timeline may vary depending on the severity and complexity of the vulnerability.

## Known Security Considerations

### Docker Socket Exposure

Kolla requires access to the Docker/Podman socket for container management. This is a privileged operation. Ensure:

- The socket is only accessible to trusted users
- SELinux/AppArmor policies are properly configured
- Consider using Docker socket proxies for additional security

### Privileged Containers

Some Kolla services require privileged containers for network and system operations. Review and minimize the use of privileged containers in production deployments.

### Secrets in Container Images

Kolla builds container images that may contain configuration. Ensure:

- Secrets are injected at runtime, not build time
- Use Ansible Vault or external secrets management
- Regularly rotate secrets and credentials

### Registry Security

When using a private registry:

- Implement authentication and authorization
- Use TLS for registry communication
- Regularly scan images for vulnerabilities
- Implement image signing and verification

## Security Tools and Resources

### Recommended Security Tools

- **Trivy** - Container vulnerability scanner
- **Bandit** - Python security linter (already used in CI)
- **Ansible Lint** - Ansible playbook security checks (already used in CI)
- **Docker Bench Security** - Docker security auditing
- **OpenSCAP** - Security compliance checking
- **Falco** - Runtime security monitoring

### OpenStack Security Resources

- [OpenStack Security Guide](https://docs.openstack.org/security-guide/)
- [OpenStack Security Notes](https://wiki.openstack.org/wiki/Security_Notes)
- [OpenStack Security Project](https://wiki.openstack.org/wiki/Security)
- [OSSN (OpenStack Security Notes)](https://wiki.openstack.org/wiki/Security_Notes)

## Compliance and Certifications

Kolla can be used to build OpenStack deployments that comply with various security standards:

- **PCI DSS** - Payment Card Industry Data Security Standard
- **HIPAA** - Health Insurance Portability and Accountability Act
- **SOC 2** - Service Organization Control 2
- **ISO 27001** - Information Security Management

Achieving compliance requires proper configuration and operational practices beyond Kolla itself.

## Security Updates and Notifications

To stay informed about security updates:

1. **Watch this repository** on GitHub for security advisories
2. **Subscribe to OpenStack security mailing lists**
3. **Follow [@OpenStack on Twitter](https://twitter.com/OpenStack)** for announcements
4. **Join #openstack-security on OFTC IRC**
5. **Monitor [OpenStack Security portal](https://security.openstack.org/)**

## Questions?

If you have questions about this security policy that are not sensitive in nature, please:

- Ask on the [OpenStack mailing list](http://lists.openstack.org/cgi-bin/mailman/listinfo/openstack-discuss) with `[kolla]` tag
- Join #openstack-kolla on OFTC IRC
- Attend the [Kolla team meeting](https://docs.openstack.org/kolla/latest/contributor/meeting.html)

For sensitive security questions, please email openstack-security@lists.openstack.org.

---

**Last Updated:** October 31, 2025  
**Version:** 1.0.0
