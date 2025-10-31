# Renovate Bot Configuration

This repository uses [Renovate Bot](https://docs.renovatebot.com/) to automatically keep dependencies up-to-date.

## What is Renovate?

Renovate is a tool that automatically creates Pull Requests to update your dependencies when new versions are released. It supports Python packages, Docker images, GitHub Actions, and more.

## How it Works

1. **Scheduled Runs**: Renovate runs every Monday before 3am UTC
2. **Dependency Detection**: Automatically detects dependencies in:
   - `requirements.txt`
   - `test-requirements.txt`
   - `doc/requirements.txt`
   - `Dockerfile` files
   - `.github/workflows/*.yml` (GitHub Actions)
   - `.pre-commit-config.yaml`
   - `test-requirements.yml` (Ansible Galaxy)

3. **Pull Request Creation**: Creates PRs with:
   - Clear titles and descriptions
   - Changelog links
   - Version information
   - Merge confidence badges

4. **Auto-merge**: Some updates are automatically merged:
   - Patch updates (e.g., 1.2.3 → 1.2.4)
   - Minor updates for trusted packages
   - GitHub Actions updates

## Configuration Highlights

### Grouped Updates

Dependencies are grouped logically to reduce PR noise:

- **OpenStack Oslo libraries** - All `oslo.*` packages together
- **Testing dependencies** - pytest, coverage, stestr, etc.
- **Linting tools** - flake8, bandit, ansible-lint, etc.
- **Ansible packages** - All `ansible*` packages together

### Security Updates

- **High Priority**: Security updates are processed immediately
- **Labels**: Tagged with `security` and `priority-high`
- **No Schedule**: Security PRs are created at any time

### Manual Review Required

Major version updates require manual review:
- Major version bumps (e.g., 2.x → 3.x)
- Jinja2 updates (template compatibility concerns)
- pbr updates (build system stability)
- Dockerfile base images (testing required)

### Auto-merge Enabled For

✅ Patch updates for all Python packages  
✅ Minor updates for: setuptools, GitPython, docker  
✅ GitHub Actions updates  

## Dashboard

Renovate creates a **Dependency Dashboard** issue that shows:
- All pending updates
- Rate-limited updates
- Updates requiring approval
- Error logs

Look for an issue titled: **🤖 Dependency Updates Dashboard**

## Labels

Renovate automatically adds labels to PRs:

- `dependencies` - All dependency updates
- `automated` - Automated updates
- `major-update` - Major version updates
- `requires-review` - Needs manual review
- `security` - Security-related updates
- `priority-high` - High priority updates
- `github-actions` - GitHub Actions updates
- `docker` - Docker image updates
- `requires-testing` - Needs testing before merge

## Merge Strategy

- **Type**: Pull Request
- **Strategy**: Squash
- **Commit Format**: Semantic commits (e.g., `deps: update package to 1.2.3`)

## Rate Limiting

To avoid overwhelming the project:
- **Concurrent PRs**: Maximum 5 open PRs at a time
- **Hourly Limit**: Maximum 2 PRs per hour
- **Schedule**: Most updates only on Monday mornings

## Customization

The configuration is in `renovate.json`. You can customize:

- Schedule (currently Monday 3am UTC)
- Auto-merge rules
- Grouping of packages
- Labels and reviewers
- Package ignore list

## Enabling Renovate

### On GitHub

1. Install the [Renovate GitHub App](https://github.com/apps/renovate)
2. Grant access to this repository
3. Renovate will automatically detect `renovate.json` and start working

### Self-hosted

If you prefer to run Renovate yourself:

```bash
# Using npx
npx renovate --platform github --token YOUR_GITHUB_TOKEN

# Using Docker
docker run --rm renovate/renovate:latest \
  --platform github \
  --token YOUR_GITHUB_TOKEN \
  rasty94/kolla
```

## Testing Configuration

Test the configuration locally before deploying:

```bash
# Validate configuration
npx renovate-config-validator

# Dry run
npx renovate --platform=github --dry-run=true --token=YOUR_TOKEN
```

## Ignoring Updates

To ignore specific packages or updates, add to `renovate.json`:

```json
{
  "ignoreDeps": [
    "package-name"
  ]
}
```

Or add a comment in the file:

```python
# renovate: ignore
some-package==1.2.3
```

## Pausing Renovate

To pause Renovate temporarily:

1. Add to `renovate.json`:
   ```json
   {
     "enabled": false
   }
   ```

2. Or close the Dependency Dashboard issue

## Troubleshooting

### PR Not Created

- Check the Dependency Dashboard for errors
- Verify package is not in `ignoreDeps`
- Check if rate limits are reached
- Review schedule configuration

### Auto-merge Not Working

- Ensure CI/CD checks are passing
- Verify auto-merge is enabled for that update type
- Check if manual review is required (major updates)
- Confirm GitHub branch protection rules allow auto-merge

### Too Many PRs

Adjust in `renovate.json`:
- Reduce `prConcurrentLimit`
- Increase `prHourlyLimit`
- Add more package grouping

## Resources

- [Renovate Documentation](https://docs.renovatebot.com/)
- [Configuration Options](https://docs.renovatebot.com/configuration-options/)
- [Preset Configs](https://docs.renovatebot.com/presets/)
- [Merge Confidence](https://docs.renovatebot.com/merge-confidence/)

## Questions?

If you have questions about Renovate configuration:
- Open an issue in this repository
- Ask in #openstack-kolla IRC channel
- Email openstack-discuss@lists.openstack.org with [kolla] tag

---

**Last Updated**: October 31, 2025  
**Renovate Version**: Latest
