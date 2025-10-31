# Multi-Architecture Support in Kolla

Kolla provides comprehensive support for building container images across multiple CPU architectures, enabling deployment on diverse hardware platforms including traditional x86_64 servers, ARM-based systems (Apple Silicon, AWS Graviton), and edge devices.

---

## Table of Contents

- [Overview](#overview)
- [Supported Architectures](#supported-architectures)
- [Building Multi-Architecture Images](#building-multi-architecture-images)
- [Using Pre-built Multi-Architecture Images](#using-pre-built-multi-architecture-images)
- [CI/CD Integration](#cicd-integration)
- [Platform-Specific Considerations](#platform-specific-considerations)
- [Troubleshooting](#troubleshooting)
- [Performance Considerations](#performance-considerations)
- [Examples](#examples)

---

## Overview

Multi-architecture support allows Kolla to:

- **Build images natively** on the target architecture
- **Cross-compile images** from one architecture to another
- **Create unified manifests** that automatically select the correct image for the platform
- **Support heterogeneous deployments** with mixed architecture nodes

### Architecture Support Status

| Architecture | Status | Use Cases |
|--------------|--------|-----------|
| **linux/amd64** | ✅ Fully Supported | Traditional servers, cloud VMs (AWS EC2, Azure, GCP) |
| **linux/arm64** | ✅ Fully Supported | Apple Silicon (M1/M2/M3), AWS Graviton, Raspberry Pi 4+ |
| **linux/arm/v7** | ⚠️ Experimental | Raspberry Pi 3, older ARM devices |

---

## Supported Architectures

### AMD64 (x86_64)

**Primary architecture** for OpenStack deployments.

```bash
# Build for AMD64
kolla-build --base ubuntu --platform linux/amd64 --base-arch x86_64
```

**Compatible Platforms:**
- Intel Xeon servers
- AMD EPYC servers
- Most cloud VMs (AWS, Azure, GCP, DigitalOcean)
- Traditional bare-metal servers

### ARM64 (aarch64)

**Growing adoption** in cloud and edge computing.

```bash
# Build for ARM64
kolla-build --base ubuntu --platform linux/arm64 --base-arch aarch64
```

**Compatible Platforms:**
- **Apple Silicon**: MacBook Pro/Air M1/M2/M3
- **AWS Graviton**: Graviton2, Graviton3 instances
- **Oracle Cloud**: Ampere Altra processors
- **Raspberry Pi**: Pi 4, Pi 5 (8GB RAM recommended)
- **NVIDIA Jetson**: AGX, Xavier, Orin

### ARMv7 (32-bit ARM)

**Experimental support** for legacy devices.

```bash
# Build for ARMv7 (experimental)
kolla-build --base ubuntu --platform linux/arm/v7 --base-arch armv7l
```

**Compatible Platforms:**
- Raspberry Pi 3
- Older ARM development boards
- **Note**: Limited OpenStack service support due to resource constraints

---

## Building Multi-Architecture Images

### Local Builds

#### Prerequisites

**For AMD64 host building ARM64:**

```bash
# Ubuntu/Debian
sudo apt-get install qemu-user-static binfmt-support

# macOS (using Docker Desktop)
# QEMU is included, no additional setup needed

# Verify QEMU setup
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

**For ARM64 host building AMD64:**

```bash
# macOS Apple Silicon (using Docker Desktop or Podman)
# Cross-compilation supported out of the box

# Linux ARM64
sudo apt-get install qemu-user-static binfmt-support
```

#### Basic Cross-Compilation

**Build single image for ARM64 on AMD64 host:**

```bash
kolla-build \
  --base ubuntu \
  --type binary \
  --platform linux/arm64 \
  --base-arch aarch64 \
  nova-compute
```

**Build single image for AMD64 on ARM64 host:**

```bash
kolla-build \
  --base ubuntu \
  --type binary \
  --platform linux/amd64 \
  --base-arch x86_64 \
  nova-compute
```

#### Building for Multiple Architectures

**Build and tag for both architectures:**

```bash
#!/bin/bash
# build-multi-arch.sh

set -e

IMAGE="nova-compute"
TAG="2025.1"
REGISTRY="my-registry.example.com"

for ARCH in amd64 arm64; do
  if [ "$ARCH" = "amd64" ]; then
    BASE_ARCH="x86_64"
  else
    BASE_ARCH="aarch64"
  fi
  
  echo "Building for ${ARCH}..."
  
  kolla-build \
    --base ubuntu \
    --type binary \
    --platform "linux/${ARCH}" \
    --base-arch "${BASE_ARCH}" \
    --tag "${TAG}-${ARCH}" \
    --registry "${REGISTRY}" \
    --push \
    "${IMAGE}"
done

# Create manifest
docker manifest create "${REGISTRY}/kolla/${IMAGE}:${TAG}" \
  --amend "${REGISTRY}/kolla/${IMAGE}:${TAG}-amd64" \
  --amend "${REGISTRY}/kolla/${IMAGE}:${TAG}-arm64"

docker manifest push "${REGISTRY}/kolla/${IMAGE}:${TAG}"

echo "✅ Multi-arch image created: ${REGISTRY}/kolla/${IMAGE}:${TAG}"
```

### Using Docker Buildx

**Setup Buildx (one-time):**

```bash
# Create new builder
docker buildx create --name kolla-builder --use

# Bootstrap builder
docker buildx inspect --bootstrap

# Verify platforms
docker buildx ls
```

**Build for multiple platforms simultaneously:**

```bash
kolla-build \
  --base ubuntu \
  --type binary \
  --tag 2025.1 \
  --platform linux/amd64,linux/arm64 \
  --push \
  --registry my-registry.example.com \
  nova
```

**Note:** Building for multiple platforms simultaneously requires Docker Buildx and pushes to a registry.

---

## Using Pre-built Multi-Architecture Images

### Pull Multi-Arch Images

Docker/Podman automatically selects the correct architecture:

```bash
# Pulls AMD64 on Intel/AMD hosts, ARM64 on ARM hosts
docker pull ghcr.io/rasty94/kolla/nova-compute:2025.1

# Force specific architecture
docker pull --platform linux/arm64 ghcr.io/rasty94/kolla/nova-compute:2025.1
```

### Inspect Multi-Arch Manifests

```bash
# View manifest
docker manifest inspect ghcr.io/rasty94/kolla/nova-compute:2025.1

# Example output:
# {
#   "manifests": [
#     {
#       "platform": {
#         "architecture": "amd64",
#         "os": "linux"
#       }
#     },
#     {
#       "platform": {
#         "architecture": "arm64",
#         "os": "linux"
#       }
#     }
#   ]
# }
```

### Deploy with Kolla-Ansible

Kolla-Ansible automatically uses the correct architecture images:

```yaml
# globals.yml
kolla_base_distro: "ubuntu"
kolla_install_type: "binary"
docker_registry: "ghcr.io/rasty94"
openstack_release: "2025.1"
```

Deploy normally - images will be pulled for the node's architecture:

```bash
kolla-ansible deploy
```

---

## CI/CD Integration

### GitHub Actions

Kolla includes GitHub Actions workflows for multi-arch builds:

**1. Continuous Multi-Arch Builds** (`.github/workflows/build-multi-arch.yml`)

Triggers on:
- Push to `master` or `stable/*` branches
- Changes to `docker/` or `kolla/` directories
- Weekly schedule (Mondays 3 AM UTC)
- Manual dispatch with custom images/architectures

**2. Release Multi-Arch Builds** (`.github/workflows/release.yml`)

Builds and publishes multi-arch images on release tags:
- Creates architecture-specific tags (`2025.1-amd64`, `2025.1-arm64`)
- Generates multi-arch manifests (`2025.1`, `latest`)
- Publishes to GitHub Container Registry

**3. Multi-Arch Tests** (`.github/workflows/tests.yml`)

Runs build verification tests for both architectures on PRs.

### Manual Workflow Dispatch

```bash
# Trigger multi-arch build via GitHub CLI
gh workflow run build-multi-arch.yml \
  -f images="nova,neutron,glance" \
  -f architectures="amd64,arm64"
```

---

## Platform-Specific Considerations

### AMD64 (Intel/AMD)

**Advantages:**
- Widest software compatibility
- Mature toolchain and ecosystem
- Best performance for x86-optimized code

**Considerations:**
- Higher power consumption than ARM64
- Larger cloud compute costs

### ARM64

**Advantages:**
- Excellent power efficiency
- Cost-effective (AWS Graviton up to 40% cheaper)
- Native performance on Apple Silicon

**Considerations:**
- Some packages may require architecture-specific builds
- QEMU emulation adds overhead when cross-compiling

### Platform-Specific Package Selection

Kolla templates handle architecture differences automatically:

```jinja2
{# Example from docker/nova/nova-compute/Dockerfile.j2 #}
{% if base_arch == 'x86_64' %}
  {% set nova_compute_packages = nova_compute_packages + [
    'daxio',  # x86_64 only
    'edk2-ovmf'
  ] %}
{% elif base_arch == 'aarch64' %}
  {% set nova_compute_packages = nova_compute_packages + [
    'edk2-aarch64'  # ARM64 specific
  ] %}
{% endif %}
```

### Unbuildable Images

Some images cannot be built on certain architectures. Check `kolla/image/unbuildable.py`:

```python
UNBUILDABLE_IMAGES = {
    'aarch64': {
        "bifrost-base",  # Dependency issues
    },
    # ...
}
```

---

## Troubleshooting

### Build Failures

**Issue:** `exec format error`

```
standard_init_linux.go:228: exec user process caused: exec format error
```

**Solution:** QEMU not configured properly

```bash
# Reset QEMU binfmt
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# Verify
docker run --rm --platform linux/arm64 ubuntu uname -m
# Should output: aarch64
```

---

**Issue:** `unknown/unsupported platform`

**Solution:** Enable buildx and target platform

```bash
docker buildx create --use
docker buildx inspect --bootstrap
```

---

**Issue:** Slow cross-compilation builds

**Solution:** This is expected with QEMU emulation. Options:

1. **Use native builders:**
   ```bash
   # Build ARM64 images on ARM64 host
   # Build AMD64 images on AMD64 host
   ```

2. **Use build cache:**
   ```bash
   kolla-build --cache --cache-from my-registry.example.com/kolla/base:latest
   ```

3. **Use binary builds** (faster than source builds):
   ```bash
   kolla-build --type binary
   ```

---

### Deployment Issues

**Issue:** Wrong architecture image pulled

**Solution:** Check Docker/Podman platform

```bash
# Force architecture
docker pull --platform linux/arm64 kolla/nova-compute:2025.1

# Inspect running container
docker inspect <container> | jq '.[0].Architecture'
```

---

**Issue:** Container fails to start on ARM64

**Solution:** Check unbuildable images list

```bash
# Some services don't support ARM64 yet
# Check kolla/image/unbuildable.py
python -c "from kolla.image.unbuildable import UNBUILDABLE_IMAGES; print(UNBUILDABLE_IMAGES.get('aarch64', set()))"
```

---

### Performance Issues

**Issue:** Slow performance in QEMU-emulated containers

**Solution:** Use native architecture builds

```bash
# Don't run AMD64 images on ARM64 via emulation for production
# Build/use ARM64 images natively on ARM64 hosts
```

---

## Performance Considerations

### Build Time Comparison

| Scenario | AMD64 Native | ARM64 Native | AMD64→ARM64 (QEMU) | ARM64→AMD64 (QEMU) |
|----------|--------------|--------------|--------------------|--------------------|
| **Small image** (base) | 2-3 min | 2-4 min | 5-8 min | 6-10 min |
| **Medium image** (nova) | 8-12 min | 10-15 min | 25-40 min | 30-50 min |
| **Full build** (all) | 2-3 hours | 2.5-4 hours | 6-10 hours | 7-12 hours |

**Recommendations:**
- Use native builds for production
- Use cross-compilation for testing and CI/CD
- Enable caching to speed up rebuilds

### Runtime Performance

**ARM64 vs AMD64:**
- ARM64 (Graviton3): ~10-20% more energy efficient
- AMD64 (Xeon): ~5-10% better single-thread performance
- Network and I/O: comparable
- OpenStack workloads: architecture difference <5% in most cases

**Recommendation:** Choose based on availability, cost, and power requirements rather than raw performance.

---

## Examples

### Example 1: Build Core Services for Apple Silicon

```bash
#!/bin/bash
# build-for-apple-silicon.sh

SERVICES="base openstack-base nova neutron glance keystone horizon"

for SERVICE in ${SERVICES}; do
  echo "Building ${SERVICE} for ARM64..."
  kolla-build \
    --base ubuntu \
    --type binary \
    --platform linux/arm64 \
    --base-arch aarch64 \
    --tag macos-dev \
    "${SERVICE}"
done

echo "✅ All services built for Apple Silicon"
```

### Example 2: Deploy Mixed Architecture Cluster

**Scenario:** AMD64 control plane, ARM64 compute nodes

```yaml
# inventory/multinode

[control]
control01 ansible_host=10.0.1.10  # AMD64

[compute]
compute01 ansible_host=10.0.2.10  # ARM64 (Graviton)
compute02 ansible_host=10.0.2.11  # ARM64 (Graviton)
compute03 ansible_host=10.0.2.12  # AMD64 (Xeon)
```

```yaml
# globals.yml
docker_registry: "ghcr.io/rasty94"
openstack_release: "2025.1"

# Images will auto-select architecture per node
```

### Example 3: CI/CD Pipeline with Multi-Arch

```yaml
# .gitlab-ci.yml (example)
build:multi-arch:
  stage: build
  script:
    - kolla-build --base ubuntu --platform linux/amd64 --tag ${CI_COMMIT_SHORT_SHA}-amd64 nova
    - kolla-build --base ubuntu --platform linux/arm64 --tag ${CI_COMMIT_SHORT_SHA}-arm64 nova
    - docker manifest create my-registry/kolla/nova:${CI_COMMIT_SHORT_SHA}
        --amend my-registry/kolla/nova:${CI_COMMIT_SHORT_SHA}-amd64
        --amend my-registry/kolla/nova:${CI_COMMIT_SHORT_SHA}-arm64
    - docker manifest push my-registry/kolla/nova:${CI_COMMIT_SHORT_SHA}
```

---

## Additional Resources

- **Kolla Documentation**: https://docs.openstack.org/kolla/latest/
- **Docker Multi-Platform**: https://docs.docker.com/build/building/multi-platform/
- **QEMU User Emulation**: https://github.com/multiarch/qemu-user-static
- **AWS Graviton**: https://aws.amazon.com/ec2/graviton/
- **Apple Silicon**: https://developer.apple.com/documentation/apple-silicon

---

## FAQ

**Q: Can I mix AMD64 and ARM64 nodes in the same cluster?**  
A: Yes! OpenStack services are architecture-agnostic. Use multi-arch images and they'll automatically work.

**Q: Which architecture should I choose?**  
A: For new deployments: ARM64 (cost, efficiency). For existing infrastructure: AMD64 (compatibility).

**Q: Do I need to rebuild images for each architecture?**  
A: With multi-arch manifests, no. Build once, use Docker's automatic platform selection.

**Q: Can I run AMD64 images on ARM64 with QEMU?**  
A: Yes for testing, but not recommended for production due to performance overhead.

**Q: Does Kolla-Ansible support mixed architectures?**  
A: Yes, it's transparent. Each node pulls the correct image for its architecture.

---

**Last Updated:** October 31, 2025  
**Maintained by:** Kolla Team
