# GitHub Actions CI/CD

This document describes the GitHub Actions workflows configured for the Kolla project.

## Overview

Kolla uses GitHub Actions to complement the existing OpenStack CI infrastructure (Zuul/Gerrit). These workflows provide:

- **Fast feedback** on pull requests
- **Visual status badges** in the README
- **Security scanning** and vulnerability detection
- **Multi-platform testing** (Python 3.8-3.12)
- **Automated code quality checks**

## Workflows

### 1. Tests (`tests.yml`)

**Triggers:**
- Push to `master` or `stable/**` branches
- Pull requests
- Manual workflow dispatch

**Jobs:**
- **Unit Tests**: Runs tests on Python 3.8, 3.9, 3.10, 3.11, and 3.12
- **Functional Tests**: Validates Docker image builds
- **Build Verification**: Tests configuration parsing and CLI tools
- **Coverage**: Uploads coverage reports to Codecov (Python 3.11 only)

**Usage:**
```bash
# Workflows run automatically on push/PR
# To run manually: Go to Actions tab → Tests → Run workflow
```

**Status Badge:**
```markdown
![Tests](https://github.com/rasty94/kolla/workflows/Tests/badge.svg)
```

### 2. Linting (`linting.yml`)

**Triggers:**
- Push to `master` or `stable/**` branches
- Pull requests
- Manual workflow dispatch

**Jobs:**
- **Ruff**: Python linting and formatting checks
- **Bandit**: Security vulnerability scanning
- **Pydocstyle**: Docstring style validation
- **Shellcheck**: Shell script analysis
- **Yamllint**: YAML file validation
- **Hadolint**: Dockerfile best practices
- **Ansible-lint**: Ansible playbook validation
- **Codespell**: Spelling error detection
- **Markdownlint**: Markdown formatting

**Usage:**
```bash
# Run linters locally (recommended before pushing):
pre-commit run --all-files

# Or manually:
ruff check .
ruff format --check .
bandit -c pyproject.toml -r kolla/
```

**Status Badge:**
```markdown
![Linting](https://github.com/rasty94/kolla/workflows/Linting/badge.svg)
```

### 3. Documentation (`docs.yml`)

**Triggers:**
- Push/PR with changes to `doc/`, `README.rst`, or `*.md` files
- Manual workflow dispatch

**Jobs:**
- **Build Documentation**: Compiles Sphinx HTML docs
- **Validate RST**: Checks ReStructuredText syntax
- **Check Links**: Validates external URLs
- **Check Spelling**: Scans documentation for typos
- **Release Notes**: Validates reno release notes format

**Usage:**
```bash
# Build docs locally:
cd doc
make html

# Check for broken links:
make linkcheck

# Validate release notes:
reno lint
```

**Artifacts:**
- HTML documentation is uploaded as workflow artifact (7 days retention)

### 4. Security (`security.yml`)

**Triggers:**
- Push to `master` or `stable/**` branches
- Pull requests
- Daily schedule (2 AM UTC)
- Manual workflow dispatch

**Jobs:**
- **Bandit Security**: Python security scanning (SARIF output)
- **Dependency Check**: Vulnerability scanning with `safety` and `pip-audit`
- **Secret Scanning**: Detects leaked credentials with Gitleaks and detect-secrets
- **CodeQL Analysis**: GitHub's semantic code analysis
- **Docker Security**: Scans Dockerfiles with Trivy
- **SAST Analysis**: Static analysis with Semgrep
- **License Compliance**: Validates dependency licenses

**Usage:**
```bash
# Run security checks locally:
bandit -c pyproject.toml -r kolla/
safety check
detect-secrets scan --baseline .secrets.baseline

# Check Docker images:
trivy fs docker/
hadolint docker/base/Dockerfile
```

**Status Badge:**
```markdown
![Security](https://github.com/rasty94/kolla/workflows/Security/badge.svg)
```

## Workflow Configuration

### Concurrency Control

All workflows use concurrency groups to cancel outdated runs:

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

This saves CI resources by canceling superseded workflow runs.

### Caching

Workflows use GitHub Actions caching for faster execution:

```yaml
- name: Set up Python
  uses: actions/setup-python@v5
  with:
    python-version: '3.11'
    cache: 'pip'  # Automatically caches pip dependencies
```

### Matrix Testing

The test workflow uses a matrix strategy for multi-version testing:

```yaml
strategy:
  fail-fast: false
  matrix:
    python-version: ['3.8', '3.9', '3.10', '3.11', '3.12']
```

## Integration with Existing CI

GitHub Actions **complements** (not replaces) OpenStack's Zuul CI:

| CI System | Purpose |
|-----------|---------|
| **Zuul/Gerrit** | Official OpenStack CI, required for merging |
| **GitHub Actions** | Fast feedback, security scanning, visibility |

Both systems run in parallel and provide different benefits:

- **Zuul**: Deep integration with OpenStack infrastructure, required gates
- **GitHub Actions**: Faster feedback, modern UI, security scanning, badges

## Secrets Configuration

Some workflows require GitHub secrets (Settings → Secrets and variables → Actions):

| Secret | Purpose | Required |
|--------|---------|----------|
| `CODECOV_TOKEN` | Upload coverage to Codecov | Optional |
| `GITHUB_TOKEN` | Automatically provided by GitHub | Auto |

## Troubleshooting

### Workflow Failures

1. **Check the logs**: Click on the failed job in the Actions tab
2. **Run locally**: Most checks can be run with `pre-commit run --all-files`
3. **Re-run**: Click "Re-run jobs" in the GitHub UI

### Common Issues

**Issue: "Linting failed"**
- **Solution**: Run `pre-commit run --all-files` and fix reported issues

**Issue: "Tests failed on Python 3.X"**
- **Solution**: Install that Python version and run `tox -e py3X`

**Issue: "Security scan found vulnerabilities"**
- **Solution**: Review the SARIF output in the Security tab
- Update vulnerable dependencies or add exceptions if false positives

**Issue: "Documentation build failed"**
- **Solution**: Run `cd doc && make html` locally to see detailed errors

### Debugging Workflows

To debug a workflow:

1. Add the following step to get a shell:
```yaml
- name: Debug with tmate
  uses: mxschmitt/action-tmate@v3
  if: ${{ failure() }}
```

2. Re-run the workflow
3. Connect to the session using the provided SSH command

## Best Practices

### Before Pushing

Run local checks to catch issues early:

```bash
# Install pre-commit hooks (one-time)
pre-commit install

# Run all checks
pre-commit run --all-files

# Or run specific checks
ruff check .
pytest tests/
```

### Pull Request Workflow

1. **Create a feature branch**: `git checkout -b feature-name`
2. **Make changes** with frequent commits
3. **Run pre-commit**: Automatically runs on `git commit`
4. **Push to GitHub**: GitHub Actions runs automatically
5. **Review results**: Check the "Checks" tab on your PR
6. **Fix issues**: Address any failures reported by workflows
7. **Merge**: Once all checks pass (both GitHub Actions and Zuul)

### Writing Workflow Files

When adding new workflows:

1. Use **descriptive names** for jobs and steps
2. Add **concurrency control** to save resources
3. Use **caching** for dependencies
4. Set **continue-on-error** for non-critical checks
5. Provide **clear error messages** in failure cases
6. Upload **artifacts** for build outputs
7. Add **status badges** to README.rst

### Security Considerations

- **Never commit secrets** to workflow files
- Use **GitHub Secrets** for sensitive values
- Enable **dependency scanning** and review alerts
- Keep **actions versions** up to date
- Use **SARIF uploads** for security tool integration

## Monitoring

### Status Badges

Add badges to your README to show workflow status:

```rst
.. image:: https://github.com/rasty94/kolla/workflows/Tests/badge.svg
    :target: https://github.com/rasty94/kolla/actions/workflows/tests.yml
```

### Notifications

GitHub automatically notifies you about workflow failures:

- **Email**: Sent to commit authors
- **GitHub UI**: Shows in the Actions tab and PR checks
- **Mobile**: GitHub mobile app notifications

## Maintenance

### Updating Workflows

1. Edit workflow files in `.github/workflows/`
2. Test changes on a feature branch
3. Submit PR with workflow updates
4. Review workflow run results before merging

### Action Updates

Dependabot or Renovate can automatically update action versions:

```yaml
# Before
uses: actions/checkout@v3

# After
uses: actions/checkout@v4
```

Review and test updates before merging.

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [OpenStack CI Documentation](https://docs.openstack.org/infra/manual/)
- [Pre-commit Documentation](https://pre-commit.com/)
- [Codecov Documentation](https://docs.codecov.io/)

## Support

For issues with GitHub Actions workflows:

1. **Check this documentation** first
2. **Review workflow logs** in the Actions tab
3. **Search existing issues** on GitHub
4. **Create a new issue** if the problem persists
5. **Ask on IRC**: #openstack-kolla on OFTC

## Related Documentation

- [Pre-commit Hooks](.github/PRE-COMMIT.md)
- [Renovate Configuration](.github/RENOVATE.md)
- [Security Policy](../SECURITY.md)
- [Contributing Guide](../CONTRIBUTING.rst)
