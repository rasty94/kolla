# Docker Image Size Optimization Guide

This guide provides best practices and techniques for optimizing Kolla container image sizes.

---

## Table of Contents

- [Why Optimize Image Size?](#why-optimize-image-size)
- [Current State Analysis](#current-state-analysis)
- [Optimization Techniques](#optimization-techniques)
- [Best Practices](#best-practices)
- [Kolla-Specific Optimizations](#kolla-specific-optimizations)
- [Measurement and Tools](#measurement-and-tools)
- [Examples](#examples)
- [FAQ](#faq)

---

## Why Optimize Image Size?

### Benefits

1. **Faster Downloads**: Smaller images download faster from registries
2. **Reduced Storage**: Less disk space usage on registry and deployment nodes
3. **Security**: Smaller attack surface with fewer packages
4. **Network Efficiency**: Lower bandwidth consumption
5. **Faster Deployments**: Quicker pull and startup times

### Impact Metrics

| Image Size | Download Time (100 Mbps) | Storage (10 nodes) |
|------------|-------------------------|-------------------|
| 500 MB     | 40 seconds              | 5 GB              |
| 250 MB     | 20 seconds              | 2.5 GB            |
| 100 MB     | 8 seconds               | 1 GB              |

**Example Reduction**: Reducing Nova image from 800MB to 400MB saves:
- 32 seconds per deployment
- 4GB across 10 nodes
- 40GB in a 100-node cluster

---

## Current State Analysis

### Typical Kolla Image Sizes

| Image Type          | Typical Size | Optimization Potential |
|--------------------|-------------|----------------------|
| base               | 300-400 MB  | Medium (20-30%)      |
| openstack-base     | 500-700 MB  | High (30-40%)        |
| nova-compute       | 800-1000 MB | High (30-40%)        |
| neutron-server     | 700-900 MB  | High (30-40%)        |
| glance-api         | 500-600 MB  | Medium (20-30%)      |

### Common Bloat Sources

1. **Package Manager Cache**: 50-150 MB
2. **Build Dependencies**: Not cleaned up
3. **Documentation Files**: `/usr/share/doc/*`, `/usr/share/man/*`
4. **Locale Files**: Unnecessary language packs
5. **Python Cache**: `__pycache__`, `.pyc` files
6. **Log Files**: Leftover build logs

---

## Optimization Techniques

### 1. Multi-Stage Builds

**Concept**: Build in one container, copy only artifacts to final image.

**Before**:
```dockerfile
FROM ubuntu:24.04
RUN apt-get update && apt-get install -y build-essential python3-dev
RUN pip install some-package
# build-essential still in image (300MB+)
```

**After**:
```dockerfile
FROM ubuntu:24.04 AS builder
RUN apt-get update && apt-get install -y build-essential python3-dev
RUN pip install --no-cache-dir --target=/packages some-package

FROM ubuntu:24.04
COPY --from=builder /packages /usr/local/lib/python3.12/site-packages
# build-essential not in final image
```

**Savings**: 200-400 MB

### 2. Minimize Layers

**Concept**: Combine RUN commands to reduce layer count.

**Before** (Creates 3 layers):
```dockerfile
RUN apt-get update
RUN apt-get install -y package1
RUN apt-get clean
```

**After** (Creates 1 layer):
```dockerfile
RUN apt-get update \
    && apt-get install -y package1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
```

**Savings**: 10-50 MB (metadata overhead)

### 3. Clean Package Manager Cache

**APT (Debian/Ubuntu)**:
```dockerfile
RUN apt-get update \
    && apt-get install -y package1 package2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/apt/archives/*
```

**DNF/YUM (CentOS/Rocky)**:
```dockerfile
RUN dnf install -y package1 package2 \
    && dnf clean all \
    && rm -rf /var/cache/dnf
```

**Savings**: 50-200 MB

### 4. Remove Build Dependencies

Install build dependencies in the same layer and remove them:

```dockerfile
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        python3-dev \
    && pip install --no-cache-dir package \
    && apt-get purge -y --auto-remove \
        build-essential \
        python3-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
```

**Savings**: 200-500 MB

### 5. Use --no-install-recommends

APT installs recommended packages by default. Disable this:

```dockerfile
RUN apt-get install -y --no-install-recommends package
```

**Savings**: 50-100 MB per large package

### 6. Python Optimization

**Disable pip cache**:
```dockerfile
RUN pip install --no-cache-dir package
```

**Remove bytecode files**:
```dockerfile
RUN find /usr -type d -name '__pycache__' -exec rm -rf {} + \
    && find /usr -type f -name '*.pyc' -delete \
    && find /usr -type f -name '*.pyo' -delete
```

**Set PYTHONDONTWRITEBYTECODE**:
```dockerfile
ENV PYTHONDONTWRITEBYTECODE=1
```

**Savings**: 30-100 MB

### 7. Remove Documentation

```dockerfile
RUN rm -rf /usr/share/doc/* \
    && rm -rf /usr/share/man/* \
    && rm -rf /usr/share/info/* \
    && rm -rf /usr/share/locale/*
```

**Savings**: 50-150 MB

### 8. Minimize Locale Data

Keep only required locales:

```dockerfile
RUN apt-get install -y locales \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen \
    && apt-get purge -y locales \
    && apt-get clean
```

**Savings**: 30-80 MB

---

## Best Practices

### General Guidelines

1. **Order matters**: Place frequently changing commands last
2. **One concern per layer**: Easier to debug and optimize
3. **Explicit is better**: Don't rely on defaults
4. **Test thoroughly**: Ensure functionality after optimization

### Dockerfile Best Practices

```dockerfile
# ✅ GOOD: Combined, ordered, cleaned
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        package1 \
        package2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ❌ BAD: Separate, unordered, not cleaned
RUN apt-get install -y package1
RUN apt-get install -y package2
RUN apt-get update
```

### Template Jinja2 Best Practices

```jinja2
{# ✅ GOOD: Use macros with cleanup #}
{{ macros.install_packages(packages, clean=True) }}

{# ❌ BAD: Manual install without cleanup #}
RUN apt-get install -y {{ packages | join(' ') }}
```

---

## Kolla-Specific Optimizations

### 1. Optimize Macros

The `docker/macros.j2` file already includes cleanup logic. Ensure it's used consistently:

**Current `install_packages` macro** includes cleanup:
```jinja2
{% macro install_packages(packages, chain=False, clean=clean_package_cache) -%}
    {# ... #}
    && {{ distro_package_manager }} clean all && rm -rf /var/cache/{{ distro_package_manager }}
{%- endmacro %}
```

**Always use `clean=True`** (default):
```jinja2
{{ macros.install_packages(base_packages, clean=True) }}
```

### 2. Optimize Base Image

**Current optimizations in `docker/base/Dockerfile.j2`**:
- ✅ Installs `--no-install-recommends` for APT
- ✅ Uses macros with cleanup
- ✅ Combines RUN commands

**Additional opportunities**:
```dockerfile
# Remove unnecessary files after package installation
RUN rm -rf /usr/share/doc/* \
    && rm -rf /usr/share/man/* \
    && find /var -name '*.log' -delete
```

### 3. Template Overrides for Optimization

Create `template-override-optimized.j2`:

```jinja2
{% extends parent_template %}

{% block {{ image_name }}_footer %}
# Additional cleanup after service installation
RUN apt-get purge -y --auto-remove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/share/doc/* /usr/share/man/* \
    && find /var -type f -name '*.log' -delete \
    && find /usr -type d -name '__pycache__' -exec rm -rf {} + \
    && find /usr -type f -name '*.py[co]' -delete
{% endblock %}
```

**Usage**:
```bash
kolla-build --template-override template-override-optimized.j2
```

### 4. Distroless Consideration

**Current**: Kolla uses full OS images (Ubuntu, Rocky Linux)
**Alternative**: Distroless images (Google/Chainguard)

**Pros**:
- Smaller size (30-100 MB vs 200-400 MB)
- Better security (minimal attack surface)

**Cons**:
- No shell (harder to debug)
- No package manager (harder to customize)
- Requires significant refactoring

**Recommendation**: Consider for production-critical, security-focused deployments after thorough testing.

---

## Measurement and Tools

### Built-in Tools

**1. docker images**
```bash
docker images kolla/nova-compute --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
```

**2. docker history**
```bash
docker history kolla/nova-compute:latest --no-trunc
```

**3. docker inspect**
```bash
docker inspect kolla/nova-compute:latest | jq '.[0].Size'
```

### Advanced Analysis Tools

**1. dive** (Layer-by-layer analysis)
```bash
# Install
wget https://github.com/wagoodman/dive/releases/download/v0.12.0/dive_0.12.0_linux_amd64.deb
sudo dpkg -i dive_0.12.0_linux_amd64.deb

# Analyze
dive kolla/nova-compute:latest
```

**Features**:
- Shows wasted space per layer
- Highlights inefficiencies
- Interactive layer exploration

**2. docker-slim** (Automated optimization)
```bash
# Install
curl -L https://github.com/slimtoolkit/slim/releases/download/1.40.11/dist_linux.tar.gz | tar -xz
sudo mv dist_linux/docker-slim /usr/local/bin/

# Optimize
docker-slim build --target kolla/nova-compute:latest \
    --tag kolla/nova-compute:slim
```

**Warning**: May break Kolla images due to aggressive optimization. Use with caution and test thoroughly.

**3. Container Diff**
```bash
# Install
curl -LO https://storage.googleapis.com/container-diff/latest/container-diff-linux-amd64
chmod +x container-diff-linux-amd64
sudo mv container-diff-linux-amd64 /usr/local/bin/container-diff

# Compare
container-diff diff daemon://kolla/nova-compute:old daemon://kolla/nova-compute:new
```

### Makefile Integration

Add to `Makefile`:
```makefile
analyze-image:  ## Analyze image size with dive
	@if ! command -v dive &> /dev/null; then \
		echo "dive not installed. Install: https://github.com/wagoodman/dive"; \
		exit 1; \
	fi
	@read -p "Enter image name (e.g., kolla/nova-compute:latest): " image; \
	dive $$image

image-sizes:  ## Show sizes of all Kolla images
	docker images 'kolla/*' --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | sort -k3 -h
```

---

## Examples

### Example 1: Optimize Nova Compute

**Before** (1000 MB):
```dockerfile
FROM kolla/openstack-base:latest
RUN apt-get install -y nova-compute
```

**After** (600 MB):
```dockerfile
FROM kolla/openstack-base:latest
RUN apt-get update \
    && apt-get install -y --no-install-recommends nova-compute \
    && apt-get purge -y --auto-remove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/share/doc/* /usr/share/man/* \
    && find /var -type f -name '*.log' -delete \
    && find /usr -type d -name '__pycache__' -exec rm -rf {} +
```

**Savings**: 400 MB (40%)

### Example 2: Optimize Python Service

**Before** (800 MB):
```dockerfile
FROM kolla/openstack-base:latest
RUN pip install openstack-service
```

**After** (500 MB):
```dockerfile
FROM kolla/openstack-base:latest
ENV PYTHONDONTWRITEBYTECODE=1
RUN pip install --no-cache-dir openstack-service \
    && find /usr -type d -name '__pycache__' -exec rm -rf {} + \
    && find /usr -type f -name '*.py[co]' -delete
```

**Savings**: 300 MB (37.5%)

### Example 3: Multi-Stage Build

**Before** (900 MB):
```dockerfile
FROM ubuntu:24.04
RUN apt-get update && apt-get install -y build-essential python3-dev
COPY . /app
RUN cd /app && python3 setup.py install
```

**After** (300 MB):
```dockerfile
FROM ubuntu:24.04 AS builder
RUN apt-get update && apt-get install -y build-essential python3-dev
COPY . /app
RUN cd /app && python3 setup.py install --root=/install

FROM ubuntu:24.04
COPY --from=builder /install /
RUN apt-get update && apt-get install -y python3 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
```

**Savings**: 600 MB (66%)

---

## FAQ

### How much can I realistically save?

**Typical savings**: 20-40% for most Kolla images with low effort
**Aggressive savings**: 50-70% with multi-stage builds and distroless

### Will optimization break my deployments?

No, if you follow these guidelines:
- Test thoroughly before production
- Use `--no-install-recommends` carefully (may miss dependencies)
- Keep debugging tools in development images
- Use CI/CD to validate optimized images

### Should I optimize base images or service images?

**Both**, but prioritize:
1. **Base images first**: Benefits cascade to all services
2. **Large services**: Nova, Neutron (biggest impact)
3. **Frequently pulled**: Images pulled often benefit most

### Can I use distroless images?

**Not recommended currently**. Kolla's architecture assumes:
- Shell for scripting
- Package manager for customization
- Debugging tools

Consider distroless for:
- Security-critical production deployments
- After significant refactoring effort
- With proper testing infrastructure

### How do I measure optimization impact?

```bash
# Before
docker images kolla/nova-compute:old --format "{{.Size}}"

# After
docker images kolla/nova-compute:new --format "{{.Size}}"

# Calculate savings
echo "$(docker images kolla/nova-compute:old --format '{{.Size}}') -> $(docker images kolla/nova-compute:new --format '{{.Size}}')"
```

### What about build time?

Optimization may **increase build time** slightly:
- More cleanup operations
- More complex RUN commands

**Solution**: Use Docker layer caching and multi-stage builds.

---

## Additional Resources

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [dive - Image Analysis](https://github.com/wagoodman/dive)
- [docker-slim - Optimization](https://github.com/slimtoolkit/slim)
- [OpenStack Kolla Architecture](https://docs.openstack.org/kolla/latest/admin/image-building.html)

---

**Last Updated**: October 31, 2025  
**Maintainers**: Kolla Team
