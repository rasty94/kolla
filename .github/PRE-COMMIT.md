# Pre-commit Hooks Guide

This repository uses [pre-commit](https://pre-commit.com/) to automatically validate and fix code before commits.

## What is Pre-commit?

Pre-commit is a framework for managing and maintaining multi-language pre-commit hooks. It runs checks on your code before you commit, ensuring code quality and consistency.

## Installation

### 1. Install pre-commit

```bash
# Using pip
pip install pre-commit

# Using homebrew (macOS)
brew install pre-commit

# Using apt (Debian/Ubuntu)
sudo apt install pre-commit
```

### 2. Install the git hooks

```bash
# From the repository root
cd /path/to/kolla
pre-commit install
```

This will install the pre-commit hook into your `.git/hooks/` directory.

### 3. (Optional) Install for commit messages

```bash
pre-commit install --hook-type commit-msg
```

## Usage

### Automatic Mode (Recommended)

Once installed, pre-commit will **automatically run** every time you try to commit:

```bash
git add file.py
git commit -m "Your commit message"
# Pre-commit hooks will run automatically
```

If any hook fails:
- Files will be automatically fixed (when possible)
- You'll need to review changes and `git add` them again
- Then retry the commit

### Manual Mode

Run on all files:

```bash
pre-commit run --all-files
```

Run on specific files:

```bash
pre-commit run --files file1.py file2.py
```

Run a specific hook:

```bash
pre-commit run ruff --all-files
pre-commit run bandit --all-files
```

### Bypass Pre-commit (Use with Caution)

If you need to bypass pre-commit temporarily:

```bash
git commit --no-verify -m "Emergency commit"
```

⚠️ **Warning:** Use `--no-verify` sparingly. It's better to fix issues than skip checks.

## Hooks Configured

### General File Checks
- **trailing-whitespace**: Remove trailing whitespace
- **end-of-file-fixer**: Ensure files end with a newline
- **check-yaml**: Validate YAML syntax
- **check-json**: Validate JSON syntax
- **check-added-large-files**: Prevent large files (>1MB) from being committed
- **check-merge-conflict**: Check for merge conflict markers
- **detect-private-key**: Detect private keys in code
- **mixed-line-ending**: Fix mixed line endings

### Python Code Quality
- **ruff**: Fast Python linter (replaces flake8, isort, etc.)
- **ruff-format**: Python code formatter (Black-compatible)
- **isort**: Sort Python imports
- **bandit**: Security vulnerability scanner
- **pydocstyle**: Docstring style checker

### Infrastructure as Code
- **hadolint**: Dockerfile linter
- **shellcheck**: Shell script linter
- **yamllint**: YAML linter
- **ansible-lint**: Ansible playbook linter

### Documentation
- **markdownlint**: Markdown linter and formatter
- **rst-backticks**: RST validation
- **codespell**: Spell checker

### Security
- **detect-secrets**: Scan for secrets/credentials

## Configuration

### Main Configuration

The main configuration is in `.pre-commit-config.yaml`. You can customize:

```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.6.9
    hooks:
      - id: ruff
        args: [--fix, --exit-non-zero-on-fix]  # Customize args here
```

### Tool-Specific Configuration

Individual tools are configured in `pyproject.toml`:

```toml
[tool.ruff]
line-length = 88
target-version = "py38"

[tool.bandit]
exclude_dirs = ["tests"]
```

## Updating Hooks

Pre-commit hooks should be updated regularly:

```bash
# Update to latest versions
pre-commit autoupdate

# Update specific hooks
pre-commit autoupdate --repo https://github.com/astral-sh/ruff-pre-commit
```

## CI Integration

Pre-commit runs automatically in CI via:
- **Zuul/Gerrit**: Configured in `.zuul.d/`
- **GitHub Actions**: If using GitHub workflows
- **Pre-commit.ci**: Optional service for automatic updates

## Common Issues and Solutions

### Issue: "Command not found" errors

**Solution:** Install missing dependencies:

```bash
# For Python hooks
pip install -r requirements.txt -r test-requirements.txt

# For system tools
sudo apt install shellcheck  # Debian/Ubuntu
brew install shellcheck      # macOS
```

### Issue: Hooks are too slow

**Solution 1:** Run only fast hooks on commit:

```bash
# Skip slow hooks
SKIP=ansible-lint,hadolint-docker git commit -m "message"
```

**Solution 2:** Run slow hooks manually:

```bash
pre-commit run ansible-lint --all-files
```

### Issue: Ruff/Black formatting conflicts

**Solution:** Ruff uses Black-compatible formatting. Ensure you're using the latest versions:

```bash
pre-commit autoupdate
pre-commit run --all-files
```

### Issue: Can't commit due to pre-existing issues

**Solution:** Fix all files first:

```bash
# Auto-fix what can be fixed
pre-commit run --all-files

# Review changes
git diff

# Add fixed files
git add -u

# Commit
git commit -m "Apply pre-commit fixes"
```

## Skipping Specific Hooks

### Temporarily skip a hook

```bash
SKIP=bandit git commit -m "Skip bandit for this commit"
```

### Skip multiple hooks

```bash
SKIP=bandit,shellcheck git commit -m "Skip multiple hooks"
```

### Disable a hook permanently

Edit `.pre-commit-config.yaml` and comment out the hook:

```yaml
# - repo: https://github.com/PyCQA/bandit
#   rev: '1.7.10'
#   hooks:
#     - id: bandit
```

## Best Practices

### 1. Install Early
Install pre-commit when you first clone the repository:
```bash
git clone <repo>
cd <repo>
pre-commit install
```

### 2. Run Before Push
Before pushing, run all hooks:
```bash
pre-commit run --all-files
```

### 3. Keep Updated
Update hooks monthly:
```bash
pre-commit autoupdate
```

### 4. Fix Incrementally
If many files have issues:
```bash
# Fix one type at a time
pre-commit run trailing-whitespace --all-files
pre-commit run ruff --all-files
```

### 5. Review Auto-fixes
Always review what pre-commit changed:
```bash
git diff
```

## Hook Execution Order

Hooks run in this order:
1. **Fast checks** (whitespace, line endings)
2. **Syntax validation** (YAML, JSON)
3. **Formatting** (ruff-format, prettier)
4. **Linting** (ruff, shellcheck)
5. **Security** (bandit, detect-secrets)
6. **Slow checks** (ansible-lint, hadolint)

## Performance Tips

### Use `--files` for Large Repos

```bash
# Only check modified files
git diff --name-only | xargs pre-commit run --files
```

### Parallelize Checks

Pre-commit runs hooks in parallel by default. No configuration needed!

### Cache Results

Pre-commit caches results. Clear cache if needed:

```bash
pre-commit clean
```

## Integration with IDEs

### VS Code

Install the [pre-commit extension](https://marketplace.visualstudio.com/items?itemName=elagil.pre-commit-helper):

```json
{
  "python.linting.enabled": true,
  "python.formatting.provider": "ruff"
}
```

### PyCharm

1. Go to: Preferences → Tools → External Tools
2. Add pre-commit as an external tool
3. Set up a keyboard shortcut

### Vim/Neovim

Use [ALE](https://github.com/dense-analysis/ale) or [null-ls](https://github.com/jose-elias-alvarez/null-ls.nvim) for integration.

## Troubleshooting

### Check Hook Status

```bash
pre-commit run --all-files --verbose
```

### Debug a Specific Hook

```bash
pre-commit run bandit --all-files --verbose
```

### Reinstall Hooks

```bash
pre-commit uninstall
pre-commit install
```

### Clear Cache

```bash
pre-commit clean
```

## Resources

- [Pre-commit Documentation](https://pre-commit.com/)
- [Supported Hooks](https://pre-commit.com/hooks.html)
- [Ruff Documentation](https://docs.astral.sh/ruff/)
- [Bandit Documentation](https://bandit.readthedocs.io/)

## Questions?

If you have questions about pre-commit:
- Open an issue in the repository
- Ask in #openstack-kolla IRC channel
- Email openstack-discuss@lists.openstack.org with [kolla] tag

---

**Last Updated:** October 31, 2025  
**Version:** 1.0.0
