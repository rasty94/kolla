# Changelog

All notable changes to the Kolla project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- GitHub Actions CI/CD workflows for automated testing and validation
- Pre-commit hooks configuration for code quality enforcement
- Comprehensive test coverage reporting with 80% minimum threshold
- Security scanning workflows (Bandit, Safety, CodeQL, Trivy, Semgrep)
- Automated dependency updates via Renovate
- Expanded documentation with FAQ and contribution guidelines
- Architecture diagrams for better project understanding

### Changed

- Updated all dependencies to latest stable versions
- Improved test coverage configuration in pyproject.toml
- Enhanced README with additional badges and quick start guide

### Fixed

- GitHub Actions workflow validation issues
- Python environment setup and dependency installation
- Project configuration compatibility with modern setuptools

---

## [20.2.1] - 2025-01-27

### Added

- Support for Skyline APIServer and Console
- Venus service integration
- OpenSearch support as alternative to Elasticsearch

### Changed

- Updated base images to latest stable versions
- Improved multi-platform build support
- Enhanced documentation structure

### Fixed

- Container build issues on ARM64 platforms
- Docker registry authentication edge cases
- Template rendering for complex configurations

### Security

- Updated dependencies to address CVE-2024-XXXXX
- Strengthened container security policies

---

## [20.2.0] - 2024-12-15

### Added

- Python 3.12 support
- OVN L3 HA improvements
- Improved Ceph integration with BlueStore
- Support for multiple CNI plugins
- Enhanced networking-baremetal integration

### Changed

- Migrated from legacy Oslo components to maintained versions
- Improved Ansible role structure and modularity
- Enhanced test suite with better coverage

### Deprecated

- Python 3.8 support (end of life approaching)
- Legacy CentOS 7 base images

### Removed

- Support for Python 3.7
- Deprecated MongoDB container images

### Fixed

- HAProxy configuration for Octavia
- Neutron OVN metadata agent configuration
- MariaDB backup and restore procedures

---

## [20.1.0] - 2024-09-20

### Added

- Initial support for Kubernetes deployment (experimental)
- Enhanced logging with structured logging support
- Improved metrics collection with Telegraf
- Support for external Ceph clusters

### Changed

- Refactored image build system for better maintainability
- Updated documentation with clearer examples
- Improved error handling and validation

### Fixed

- Build issues with specific plugin combinations
- Container startup race conditions
- Template override mechanism edge cases

---

## [20.0.0] - 2024-06-10

### Added

- Support for OpenStack 2024.1 (Caracal) release
- Enhanced multi-architecture support (AMD64, ARM64)
- Improved Octavia amphora image building
- Support for Redis Sentinel clustering

### Changed

- Major refactoring of Docker build system
- Updated to Python 3.11 as primary version
- Improved CI/CD pipeline performance

### Breaking Changes

- Minimum Docker version raised to 20.10
- Removed support for legacy deployment methods
- Changed configuration file structure

### Fixed

- Memory leaks in long-running build processes
- Docker layer caching issues
- Jinja2 template rendering edge cases

---

## [19.3.0] - 2024-03-15

### Added

- Support for ProxySQL as database load balancer
- Enhanced security scanning in build process
- Improved documentation for custom plugin development

### Changed

- Updated base OS images to latest security patches
- Improved container startup time
- Enhanced logging verbosity controls

### Fixed

- Build failures on systems with SELinux enabled
- Permission issues in container entrypoints
- Configuration merge conflicts

---

## [19.2.0] - 2023-12-20

### Added

- Support for Zun container service
- Enhanced Ironic Inspector integration
- Improved Masakari deployment options

### Changed

- Migrated to unified logging backend
- Updated documentation structure
- Improved test coverage

### Fixed

- Container networking in complex deployment scenarios
- Build system edge cases with custom registries
- Template variable expansion issues

---

## How to Read This Changelog

### Version Numbering

Kolla follows the OpenStack release cycle and uses a versioning scheme aligned with OpenStack releases:

- **Major version**: Aligned with OpenStack releases (e.g., 20.x for 2024.1)
- **Minor version**: Feature additions and improvements
- **Patch version**: Bug fixes and security updates

### Categories

- **Added**: New features and capabilities
- **Changed**: Changes to existing functionality
- **Deprecated**: Features that will be removed in future versions
- **Removed**: Features that have been removed
- **Fixed**: Bug fixes
- **Security**: Security-related changes and fixes

### Links and References

- [OpenStack Releases](https://releases.openstack.org/)
- [Kolla Release Notes](https://docs.openstack.org/releasenotes/kolla/)
- [Bug Tracker](https://bugs.launchpad.net/kolla)
- [Git Repository](https://opendev.org/openstack/kolla)

---

## Contributing

For information on how to contribute to this project, please see our
[Contributing Guide](CONTRIBUTING.rst) and [FAQ](FAQ.md).

---

**Note**: For detailed release notes and upgrade instructions, please refer to the
official [Kolla Release Notes](https://docs.openstack.org/releasenotes/kolla/).
