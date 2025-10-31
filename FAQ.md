# Frequently Asked Questions (FAQ)

This document answers common questions about Kolla, the OpenStack container image building project.

---

## Table of Contents

- [General Questions](#general-questions)
- [Installation & Setup](#installation--setup)
- [Building Images](#building-images)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [Advanced Topics](#advanced-topics)

---

## General Questions

### What is Kolla?

Kolla provides production-ready Docker containers and deployment tools for operating OpenStack clouds. It's part of the OpenStack Big Tent governance and focuses on containerizing OpenStack services.

### What's the difference between Kolla and Kolla-Ansible?

- **Kolla**: Builds Docker images for OpenStack services
- **Kolla-Ansible**: Deploys those images using Ansible playbooks
- **Kayobe**: Provides a more opinionated deployment automation on top of Kolla-Ansible

Think of it as: Kolla builds the containers, Kolla-Ansible deploys them.

### Which OpenStack services does Kolla support?

Kolla supports 30+ OpenStack services including:

- Core: Nova, Neutron, Cinder, Glance, Keystone, Horizon
- Optional: Heat, Octavia, Magnum, Manila, Designate, and many more

See the [README](README.rst) for the complete list.

### What Linux distributions are supported?

Kolla supports multiple base images:

- **Ubuntu** (24.04 Noble, 22.04 Jammy) - Recommended
- **Rocky Linux** 9
- **Debian** 12 (Bookworm)

### What Python versions are supported?

- **Supported**: Python 3.8, 3.9, 3.10, 3.11, 3.12
- **Recommended**: Python 3.11 or 3.12
- **Deprecated**: Python 3.8 (will be removed in future releases)

---

## Installation & Setup

### How do I install Kolla?

**Method 1: Using pip (recommended for users)**

```bash
pip install kolla
```

**Method 2: From source (recommended for developers)**

```bash
git clone https://opendev.org/openstack/kolla
cd kolla
pip install -e .
```

### What are the system requirements?

**Minimum Requirements:**

- 4 CPU cores
- 8 GB RAM
- 50 GB free disk space
- Docker 20.10+ or Podman 3.0+
- Python 3.8+

**Recommended for Production:**

- 8+ CPU cores
- 16+ GB RAM
- 100+ GB SSD storage
- High-speed network connection

### Do I need Docker or can I use Podman?

Both are supported:

- **Docker**: Mature, well-tested
- **Podman**: Rootless support, OCI-compliant, no daemon

To use Podman:

```bash
export DOCKER_CLI='podman'
kolla-build
```

### How do I configure Kolla after installation?

**Step 1:** Generate default configuration:

```bash
mkdir -p /etc/kolla
kolla-genpwd  # If using Kolla-Ansible
```

**Step 2:** Edit `/etc/kolla/kolla-build.conf`:

```ini
[DEFAULT]
base = ubuntu
type = binary
tag = 2025.1
namespace = kolla
registry = docker.io
```

**Step 3:** Customize for your environment:

```bash
# Use a custom registry
[DEFAULT]
registry = registry.example.com:5000
push = true
```

---

## Building Images

### How do I build all images?

```bash
# Build all images
kolla-build

# Build with specific options
kolla-build --base ubuntu --type binary --tag latest
```

### How do I build specific images?

```bash
# Build only Nova images
kolla-build nova

# Build multiple specific services
kolla-build nova neutron glance

# Build with dependencies
kolla-build nova --skip-parents false
```

### What's the difference between binary and source images?

- **Binary** (default): Faster builds, uses distribution packages (apt/dnf)
- **Source**: Builds from OpenStack git repositories, more flexible

**Binary example:**

```bash
kolla-build --type binary nova
```

**Source example:**

```bash
kolla-build --type source nova
```

### How do I customize image builds?

**Method 1: Configuration file** (`/etc/kolla/kolla-build.conf`)

```ini
[nova-base]
type = source
location = https://github.com/openstack/nova.git
reference = stable/2025.1
```

**Method 2: Template overrides** (`/etc/kolla/template-override.j2`)

```jinja2
{% extends parent_template %}

{% block nova_compute_footer %}
RUN pip install my-custom-plugin
{% endblock %}
```

**Method 3: Build arguments**

```bash
kolla-build --template-override template-override.j2 nova
```

### How long does it take to build all images?

Depends on your system, but typical times:

- **First build**: 2-4 hours (downloading base images + layers)
- **Incremental builds**: 30-60 minutes (with Docker cache)
- **Single service**: 5-15 minutes

**Pro tip:** Use `--cache` and `--cache-from` for faster rebuilds.

### How do I speed up builds?

1. **Use Docker layer caching:**

   ```bash
   kolla-build --cache
   ```

2. **Use a local registry mirror:**

   ```bash
   docker pull ubuntu:24.04
   kolla-build --base ubuntu
   ```

3. **Build in parallel:**

   ```bash
   kolla-build --threads 8
   ```

4. **Use binary images:**

   ```bash
   kolla-build --type binary
   ```

### Can I build for ARM64 (Apple Silicon)?

Yes! Kolla supports multi-architecture builds:

```bash
# For ARM64 (Apple Silicon, AWS Graviton)
kolla-build --base ubuntu --platform linux/arm64

# For AMD64 (traditional Intel/AMD)
kolla-build --base ubuntu --platform linux/amd64

# Multi-platform build
docker buildx create --use
kolla-build --platform linux/amd64,linux/arm64 --push
```

---

## Configuration

### Where are the configuration files?

- `/etc/kolla/kolla-build.conf` - Main build configuration
- `/etc/kolla/template-override.j2` - Template customizations
- `~/.docker/config.json` - Docker registry credentials

### How do I use a private Docker registry?

1. **Configure registry:**

   ```bash
   [DEFAULT]
   registry = registry.example.com:5000
   push = true
   ```

2. **Login to registry:**

   ```bash
   docker login registry.example.com:5000
   ```

3. **Build and push:**

   ```bash
   kolla-build --push
   ```

### How do I add custom packages to images?

**Option 1: Template override**

```jinja2
{% extends parent_template %}

{% block {{ image_name }}_footer %}
RUN apt-get update && apt-get install -y my-package
{% endblock %}
```

**Option 2: Build configuration**

```ini
[nova-compute]
packages = my-custom-package another-package
```

### Can I use different versions of OpenStack components?

Yes, for source builds:

```ini
[nova-base]
type = source
location = https://github.com/openstack/nova.git
reference = stable/2024.2

[neutron-base]
type = source
location = https://github.com/openstack/neutron.git
reference = master
```

---

## Troubleshooting

### Build fails with "No space left on device"

**Solution 1: Clean Docker cache**

```bash
docker system prune -a
docker volume prune
```

**Solution 2: Increase Docker storage**

```bash
# Edit /etc/docker/daemon.json
{
  "data-root": "/mnt/large-disk/docker"
}
sudo systemctl restart docker
```

### Build fails with "Connection timeout" or "Network error"

**Solution 1: Configure HTTP proxy**

```bash
export HTTP_PROXY=http://proxy.example.com:8080
export HTTPS_PROXY=http://proxy.example.com:8080
kolla-build
```

**Solution 2: Use a package mirror**

```ini
[DEFAULT]
apt_package_mirrors = http://mirrors.example.com/ubuntu/
```

**Solution 3: Increase timeout**

```bash
export DOCKER_BUILD_TIMEOUT=3600
kolla-build
```

### Build fails with "Permission denied"

**Docker permission issues:**

```bash
# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Or use Podman (rootless)
kolla-build --engine podman
```

**SELinux issues:**

```bash
# Temporarily disable SELinux
sudo setenforce 0

# Or configure SELinux policies
sudo setsebool -P container_manage_cgroup true
```

### Images are too large

Kolla images can be optimized to reduce size by 20-40% typically.

**Quick Wins:**

```bash
# Use binary type (faster, smaller)
kolla-build --type binary

# Check current sizes
make image-sizes

# Analyze specific image
make analyze-image  # Requires dive tool
```

**Solution 1: Use optimized template override**

```jinja2
{% extends parent_template %}

{% block {{ image_name }}_footer %}
# Comprehensive cleanup
RUN apt-get purge -y --auto-remove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/share/doc/* /usr/share/man/* \
    && find /var -type f -name '*.log' -delete \
    && find /usr -type d -name '__pycache__' -exec rm -rf {} + \
    && find /usr -type f -name '*.py[co]' -delete
{% endblock %}
```

**Solution 2: Use new cleanup macros**

```jinja2
{% import "macros.j2" as macros with context %}

RUN {{ macros.install_packages(packages) }} \
    && {{ macros.cleanup_comprehensive() }}
```

**Solution 3: Analyze and optimize**

```bash
# Install dive for layer analysis
wget https://github.com/wagoodman/dive/releases/download/v0.12.0/dive_0.12.0_linux_amd64.deb
sudo dpkg -i dive_0.12.0_linux_amd64.deb

# Analyze image
dive kolla/nova-compute:latest
```

**Expected Savings:**

- Binary vs Source: 20-30% smaller
- With cleanup: Additional 15-25%
- Total potential: 35-55% reduction

See the comprehensive [Image Size Optimization Guide](docs/source/image-size-optimization.md) for detailed strategies.

### How do I debug build failures?

**Method 1: Check build logs**

```bash
kolla-build --debug nova 2>&1 | tee build.log
```

**Method 2: Inspect failed container**

```bash
# Find the failed container
docker ps -a | grep nova

# Inspect the container
docker inspect <container-id>

# Check logs
docker logs <container-id>
```

**Method 3: Build interactively**

```bash
# Get the Dockerfile
kolla-build --template-only nova > Dockerfile.nova

# Build manually
docker build -f Dockerfile.nova -t test-nova .
```

### Registry push fails with authentication error

**Solution:**

```bash
# Login to registry
docker login registry.example.com:5000

# Verify credentials
cat ~/.docker/config.json

# Try push again
kolla-build --push nova
```

---

## Contributing

### How do I contribute to Kolla?

1. **Read the documentation:**

   - [Contributor Guide](https://docs.openstack.org/kolla/latest/contributor/contributing.html)
   - [CONTRIBUTING.rst](CONTRIBUTING.rst)

2. **Set up your development environment:**

   ```bash
   git clone https://opendev.org/openstack/kolla
   cd kolla
   pip install -e .
   pre-commit install
   ```

3. **Make changes and test:**

   ```bash
   # Run tests
   tox -e py311

   # Run linting
   tox -e pep8
   ```

4. **Submit for review:**
   - Follow the [Gerrit workflow](https://docs.openstack.org/contributors/code-and-documentation/quick-start.html)
   - Submit to [Gerrit](https://review.opendev.org/)

### How do I report bugs?

File bugs on Launchpad: https://bugs.launchpad.net/kolla

**Good bug reports include:**

- Clear description of the issue
- Steps to reproduce
- Expected vs actual behavior
- Environment details (OS, Python version, Docker version)
- Relevant logs and error messages

### How do I request new features?

1. **Check existing blueprints:** https://blueprints.launchpad.net/kolla
2. **Create a new blueprint** with:
   - Clear use case
   - Proposed implementation
   - Impact analysis
3. **Discuss in IRC** (#openstack-kolla) or mailing list
4. **Write a spec** if it's a significant change

### What's the code review process?

Kolla uses OpenStack's Gerrit workflow:

1. Submit patch to Gerrit
2. CI runs automated tests (Zuul)
3. Core reviewers provide feedback
4. Iterate based on feedback
5. Two +2 votes from cores → merged

**Pro tip:** Small, focused patches get reviewed faster!

---

## Advanced Topics

### Does Kolla support multiple architectures?

**Yes!** Kolla supports building images for multiple CPU architectures:

- **AMD64/x86_64**: Traditional Intel and AMD processors
- **ARM64/aarch64**: Apple Silicon (M1/M2/M3), AWS Graviton, Ampere Altra

**Quick Start:**

```bash
# Install QEMU for cross-compilation
sudo apt-get install qemu-user-static

# Build for ARM64 on AMD64 host
kolla-build --base-arch aarch64 --base ubuntu

# Build for multiple architectures
docker buildx create --use
docker buildx build --platform linux/amd64,linux/arm64 .
```

**Benefits:**

- **Apple Silicon**: Native builds on M1/M2/M3 Macs (faster development)
- **AWS Graviton**: Better price/performance on ARM instances
- **Mixed Clusters**: Deploy on heterogeneous hardware

**CI/CD Support:**

The repository includes GitHub Actions workflows for automated multi-arch builds:

- Continuous builds on push/PR
- Scheduled weekly builds
- Multi-arch releases with manifest lists

**Performance:**

- Native builds: Same speed as single-arch
- Cross-compilation: 2-3x slower (using QEMU)
- Runtime: ARM64 often 10-30% better efficiency

**Learn More:**

See the comprehensive [Multi-Architecture Guide](docs/source/multi-arch.md) for:

- Detailed build instructions
- Platform-specific considerations
- Troubleshooting common issues
- CI/CD integration examples
- Performance benchmarks

### How do I build with custom plugins?

**Example: Custom Neutron plugin**

1. **Create template override:**

   ```jinja2
   {% extends parent_template %}

   {% block neutron_server_footer %}
   RUN pip install networking-custom-plugin
   {% endblock %}
   ```

2. **Build:**

   ```bash
   kolla-build --template-override custom-plugin.j2 neutron
   ```

### Can I use Kolla in CI/CD pipelines?

Yes! Example GitHub Actions workflow:

```yaml
name: Build Kolla Images

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build images
        run: |
          pip install kolla
          kolla-build --base ubuntu nova neutron
```

### How do I optimize for production?

1. **Use specific tags:**

   ```bash
   kolla-build --tag 2025.1.0
   ```

2. **Enable security scanning:**

   ```bash
   # Use Trivy, Clair, or Anchore
   trivy image kolla/nova-compute:2025.1.0
   ```

3. **Sign images:**

   ```bash
   docker trust sign kolla/nova-compute:2025.1.0
   ```

4. **Use immutable tags:**

   ```bash
   # Tag with SHA
   kolla-build --tag $(git rev-parse --short HEAD)
   ```

### How do I integrate with Kubernetes?

While Kolla images are designed for Kolla-Ansible deployment, they can be used with Kubernetes:

1. **Build images:**

   ```bash
   kolla-build --push --registry registry.k8s.example.com
   ```

2. **Create Kubernetes manifests:**

   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: nova-compute
   spec:
     containers:
       - name: nova-compute
         image: registry.k8s.example.com/kolla/nova-compute:2025.1
   ```

3. **Consider using:**
   - [OpenStack-Helm](https://github.com/openstack/openstack-helm)
   - Custom operators

### How do I optimize image sizes?

Kolla provides several tools and techniques for reducing image sizes:

**1. Analyze current sizes:**

```bash
# Show all Kolla image sizes
make image-sizes

# Total size of all images
make total-image-size

# Analyze specific image layers
make analyze-image  # Interactive - requires dive
```

**2. Build with optimizations:**

```bash
# Use binary type (20-30% smaller)
kolla-build --type binary

# Use template override for cleanup
kolla-build --template-override contrib/template-override/size-optimized.j2
```

**3. Use new cleanup macros:**

```jinja2
{% import "macros.j2" as macros with context %}

{# In your template override #}
RUN {{ macros.cleanup_comprehensive() }}
```

**4. Compare before/after:**

```bash
# Build with and without optimization
kolla-build nova --tag before
kolla-build nova --tag after --template-override optimized.j2

# Compare
make compare-images
# Enter: kolla/nova-compute:before and kolla/nova-compute:after
```

**Available cleanup macros:**

- `{{ macros.cleanup_python_cache() }}` - Remove `__pycache__`, `.pyc` files
- `{{ macros.cleanup_docs() }}` - Remove docs, man pages
- `{{ macros.cleanup_logs() }}` - Remove log files
- `{{ macros.cleanup_comprehensive() }}` - All of the above

**Expected Results:**

- Binary builds: 20-30% smaller than source
- With cleanup: Additional 15-25% reduction
- Total potential: 35-55% size reduction

**Learn More:**

See the comprehensive [Image Size Optimization Guide](docs/source/image-size-optimization.md) with:
- Detailed optimization techniques
- Layer-by-layer analysis
- Multi-stage build examples
- Tool integration (dive, docker-slim)
- Benchmarks and case studies

---

## Still Have Questions?

- 📖 **Documentation**: https://docs.openstack.org/kolla/latest/
- 💬 **IRC**: #openstack-kolla on OFTC
- 📧 **Mailing List**: openstack-discuss@lists.openstack.org (tag [kolla])
- 🐛 **Bug Reports**: https://bugs.launchpad.net/kolla
- 🎥 **Meetings**: [Weekly Meetings](https://docs.openstack.org/kolla/latest/contributor/meeting.html)

---

**Last Updated:** October 31, 2025
**Maintained by:** Kolla Team
