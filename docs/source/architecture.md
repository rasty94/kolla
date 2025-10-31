# Kolla Architecture Diagrams

This document contains visual diagrams to help understand Kolla's architecture and workflows.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Image Build Flow](#image-build-flow)
- [Project Structure](#project-structure)
- [Deployment Architecture](#deployment-architecture)
- [Development Workflow](#development-workflow)

---

## Project Overview

```mermaid
graph TB
    subgraph "Kolla Project Ecosystem"
        K[Kolla<br/>Image Builder]
        KA[Kolla-Ansible<br/>Deployment Tool]
        KB[Kayobe<br/>Automation Layer]
    end

    subgraph "Outputs"
        DI[Docker Images]
        AP[Ansible Playbooks]
        CF[Config Files]
    end

    subgraph "Targets"
        BM[Baremetal]
        VM[Virtual Machines]
        CL[Cloud Instances]
    end

    K -->|Builds| DI
    KA -->|Uses| DI
    KA -->|Generates| AP
    KA -->|Manages| CF
    KB -->|Orchestrates| KA

    KA -->|Deploys to| BM
    KA -->|Deploys to| VM
    KA -->|Deploys to| CL

    style K fill:#e1f5ff
    style KA fill:#fff3e0
    style KB fill:#f3e5f5
```

**Description:**

- **Kolla**: Builds Docker images for OpenStack services
- **Kolla-Ansible**: Deploys those images using Ansible
- **Kayobe**: Provides higher-level automation on top of Kolla-Ansible

---

## Image Build Flow

```mermaid
flowchart TD
    Start([User runs kolla-build]) --> Config[Load Configuration<br/>kolla-build.conf]
    Config --> Parse[Parse CLI Arguments<br/>--base, --type, --tag]
    Parse --> Template[Load Jinja2 Templates<br/>docker/*/Dockerfile.j2]
    Template --> Override{Template<br/>Overrides?}

    Override -->|Yes| Apply[Apply Overrides<br/>template-override.j2]
    Override -->|No| Render
    Apply --> Render[Render Dockerfiles]

    Render --> Deps[Resolve Dependencies<br/>Parent Images]
    Deps --> Build{Build Type?}

    Build -->|Binary| BinPkg[Install from<br/>Distro Packages]
    Build -->|Source| SrcGit[Clone from<br/>Git Repositories]

    BinPkg --> Docker[Docker Build Process]
    SrcGit --> Docker

    Docker --> Layer[Layer Caching]
    Layer --> Test{Run Tests?}

    Test -->|Yes| TestImg[Test Image]
    Test -->|No| Tag
    TestImg --> Tag[Tag Image<br/>namespace/name:tag]

    Tag --> Push{Push to<br/>Registry?}

    Push -->|Yes| Registry[Push to Registry<br/>docker.io, quay.io]
    Push -->|No| Local[Store Locally]

    Registry --> End([Build Complete])
    Local --> End

    style Start fill:#4caf50
    style End fill:#4caf50
    style Build fill:#ff9800
    style Push fill:#2196f3
```

**Build Process Stages:**

1. Configuration loading and CLI parsing
2. Jinja2 template processing with optional overrides
3. Dependency resolution (parent images)
4. Binary or source-based installation
5. Docker layer building with caching
6. Image tagging and optional registry push

---

## Project Structure

```mermaid
graph TB
    subgraph "Kolla Repository"
        direction TB

        subgraph "Core Components"
            Python[kolla/<br/>Python Modules]
            Docker[docker/<br/>Jinja2 Templates]
            Config[etc/kolla/<br/>Configuration]
        end

        subgraph "Development"
            Tests[tests/<br/>Test Suite]
            Tools[tools/<br/>Build Scripts]
            Roles[roles/<br/>Ansible Roles]
        end

        subgraph "Documentation"
            Docs[doc/source/<br/>Sphinx Docs]
            Release[releasenotes/<br/>Release Notes]
            Specs[specs/<br/>Design Specs]
        end

        subgraph "Support Files"
            Contrib[contrib/<br/>Templates & Plugins]
            CI[.github/workflows/<br/>CI/CD]
        end
    end

    Python -.->|Uses| Docker
    Python -.->|Reads| Config
    Tests -.->|Validates| Python
    Tools -.->|Builds| Docker
    CI -.->|Runs| Tests

    style Python fill:#42a5f5
    style Docker fill:#66bb6a
    style Tests fill:#ffa726
```

**Directory Structure:**

- **kolla/**: Core Python code for image building

  - `cmd/`: Command-line interface
  - `image/`: Image building logic
  - `template/`: Template processing
  - `common/`: Shared utilities

- **docker/**: Service-specific Dockerfile templates

  - One directory per OpenStack service
  - Hierarchical parent-child relationships

- **etc/kolla/**: Configuration files

  - Default configurations
  - Example templates

- **tests/**: Testing infrastructure
  - Unit tests
  - Functional tests
  - Integration tests

---

## Deployment Architecture

```mermaid
graph TB
    subgraph "Control Plane"
        HAProxy[HAProxy<br/>Load Balancer]
        Keystone[Keystone<br/>Identity]
        Glance[Glance<br/>Image Service]
        Nova-API[Nova API<br/>Compute API]
        Neutron-API[Neutron API<br/>Network API]
        Cinder-API[Cinder API<br/>Block Storage API]
        Horizon[Horizon<br/>Dashboard]
    end

    subgraph "Data Plane"
        MariaDB[(MariaDB<br/>Database)]
        RabbitMQ[RabbitMQ<br/>Message Queue]
        Memcached[Memcached<br/>Cache]
    end

    subgraph "Compute Nodes"
        Nova-Compute[Nova Compute<br/>Hypervisor]
        Neutron-Agent[Neutron Agent<br/>Network]
        OVS[Open vSwitch<br/>Virtual Switch]
    end

    subgraph "Storage Nodes"
        Cinder-Volume[Cinder Volume<br/>Block Storage]
        Ceph[Ceph<br/>Object Storage]
    end

    HAProxy --> Keystone
    HAProxy --> Glance
    HAProxy --> Nova-API
    HAProxy --> Neutron-API
    HAProxy --> Cinder-API
    HAProxy --> Horizon

    Keystone --> MariaDB
    Nova-API --> RabbitMQ
    Nova-API --> MariaDB
    Neutron-API --> RabbitMQ
    Neutron-API --> MariaDB

    Nova-API -.->|Manages| Nova-Compute
    Neutron-API -.->|Manages| Neutron-Agent
    Cinder-API -.->|Manages| Cinder-Volume

    Neutron-Agent --> OVS
    Cinder-Volume --> Ceph
    Glance --> Ceph

    Nova-API --> Memcached

    style HAProxy fill:#f44336
    style MariaDB fill:#2196f3
    style RabbitMQ fill:#ff9800
    style Ceph fill:#9c27b0
```

**Architecture Layers:**

1. **Control Plane**: API services, dashboard, identity
2. **Data Plane**: Database, message queue, caching
3. **Compute Nodes**: Hypervisors and networking agents
4. **Storage Nodes**: Block and object storage

---

## Development Workflow

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant Local as Local Git
    participant Gerrit as Gerrit Review
    participant Zuul as Zuul CI
    participant Core as Core Reviewers
    participant Merge as Auto Merge

    Dev->>Local: git clone kolla
    Dev->>Local: Make changes
    Dev->>Local: git commit

    Note over Dev,Local: Pre-commit hooks run

    Dev->>Local: git review
    Local->>Gerrit: Push for review

    Gerrit->>Zuul: Trigger CI
    activate Zuul

    Zuul->>Zuul: Run unit tests
    Zuul->>Zuul: Run linting
    Zuul->>Zuul: Build test images
    Zuul->>Zuul: Run integration tests

    Zuul-->>Gerrit: Post results (+1/-1)
    deactivate Zuul

    Core->>Gerrit: Code review

    alt Changes requested
        Core-->>Dev: Request changes
        Dev->>Local: git commit --amend
        Dev->>Gerrit: git review
        Gerrit->>Zuul: Trigger CI again
    else Approved
        Core-->>Gerrit: +2 vote
        Core-->>Gerrit: Approve
        Gerrit->>Merge: Auto-merge
        Merge-->>Gerrit: Merged!
    end

    Note over Merge: Change is now in master
```

**Workflow Steps:**

1. **Clone & Setup**: Clone repository and setup git-review
2. **Develop**: Make changes, write tests, update docs
3. **Commit**: Create commit with proper message format
4. **Review**: Submit to Gerrit with `git review`
5. **CI**: Zuul runs automated tests
6. **Code Review**: Core reviewers provide feedback
7. **Iterate**: Address feedback and resubmit
8. **Merge**: After approval, change is auto-merged

---

## Image Hierarchy

```mermaid
graph TD
    Base[Base Image<br/>Ubuntu/Rocky/Debian]
    OpenStackBase[openstack-base<br/>Common OpenStack Deps]

    Base --> OpenStackBase

    OpenStackBase --> NovaBase[nova-base]
    OpenStackBase --> NeutronBase[neutron-base]
    OpenStackBase --> CinderBase[cinder-base]
    OpenStackBase --> GlanceBase[glance-base]

    NovaBase --> NovaAPI[nova-api]
    NovaBase --> NovaScheduler[nova-scheduler]
    NovaBase --> NovaCompute[nova-compute]
    NovaBase --> NovaConductor[nova-conductor]

    NeutronBase --> NeutronServer[neutron-server]
    NeutronBase --> NeutronAgent[neutron-openvswitch-agent]
    NeutronBase --> NeutronL3[neutron-l3-agent]
    NeutronBase --> NeutronDHCP[neutron-dhcp-agent]

    CinderBase --> CinderAPI[cinder-api]
    CinderBase --> CinderScheduler[cinder-scheduler]
    CinderBase --> CinderVolume[cinder-volume]

    GlanceBase --> GlanceAPI[glance-api]

    style Base fill:#1976d2
    style OpenStackBase fill:#388e3c
    style NovaBase fill:#f57c00
    style NeutronBase fill:#7b1fa2
    style CinderBase fill:#c62828
    style GlanceBase fill:#0097a7
```

**Image Hierarchy Benefits:**

- **Efficient Builds**: Shared layers reduce build time
- **Consistency**: All services share common dependencies
- **Maintainability**: Changes to base propagate to children
- **Storage**: Docker layer caching minimizes storage

---

## CI/CD Pipeline

```mermaid
flowchart LR
    subgraph "GitHub Actions"
        direction TB

        PR[Pull Request/Push] --> Tests[Tests Workflow]
        PR --> Lint[Linting Workflow]
        PR --> Security[Security Workflow]
        PR --> Docs[Docs Workflow]

        Tests --> UT[Unit Tests<br/>py3.8-3.12]
        Tests --> Coverage[Coverage Report<br/>80% minimum]

        Lint --> Ruff[Ruff Linter]
        Lint --> Bandit[Bandit Security]
        Lint --> Yamllint[YAML Lint]
        Lint --> Ansible[Ansible Lint]

        Security --> Safety[Safety Check]
        Security --> Trivy[Trivy Scan]
        Security --> CodeQL[CodeQL Analysis]

        Docs --> Sphinx[Sphinx Build]
        Docs --> Links[Link Check]
    end

    subgraph "Zuul CI"
        direction TB

        ZPR[Gerrit Review] --> ZTests[Test Suite]
        ZTests --> ZBuild[Image Builds]
        ZBuild --> ZDeploy[Test Deployment]
        ZDeploy --> ZValidate[Validation]
    end

    subgraph "Release"
        Tag[Git Tag] --> Release[Release Workflow]
        Release --> Notes[Generate Release Notes]
        Release --> Publish[Publish to Registries]
        Publish --> DockerHub[Docker Hub]
        Publish --> Quay[Quay.io]
    end

    style Tests fill:#4caf50
    style Lint fill:#ff9800
    style Security fill:#f44336
    style Release fill:#2196f3
```

**CI/CD Stages:**

1. **Continuous Integration**: Automated testing on every change
2. **Security Scanning**: Vulnerability detection and compliance
3. **Documentation**: Automated doc builds and validation
4. **Release**: Automated image publishing and release notes

---

## Multi-Architecture Support

```mermaid
graph TB
    subgraph "Build Platform"
        Builder[kolla-build<br/>with buildx]
    end

    subgraph "Target Platforms"
        AMD64[linux/amd64<br/>Intel/AMD x86_64]
        ARM64[linux/arm64<br/>ARM 64-bit]
        ARMv7[linux/arm/v7<br/>ARM 32-bit]
    end

    subgraph "Use Cases"
        Cloud[Cloud VMs<br/>AWS, GCP, Azure]
        Bare[Baremetal<br/>Traditional Servers]
        Edge[Edge Devices<br/>ARM SBCs]
        Mac[Apple Silicon<br/>M1/M2/M3]
    end

    Builder -->|Build for| AMD64
    Builder -->|Build for| ARM64
    Builder -->|Build for| ARMv7

    AMD64 -.-> Cloud
    AMD64 -.-> Bare
    ARM64 -.-> Edge
    ARM64 -.-> Mac
    ARM64 -.-> Cloud
    ARMv7 -.-> Edge

    style Builder fill:#2196f3
    style AMD64 fill:#4caf50
    style ARM64 fill:#ff9800
```

**Multi-Architecture Benefits:**

- **AMD64**: Traditional x86_64 servers and cloud instances
- **ARM64**: Modern ARM processors (Apple Silicon, AWS Graviton)
- **ARMv7**: Edge computing and IoT devices
- **Flexibility**: Deploy on diverse hardware platforms

---

## Container Security Layers

```mermaid
graph TB
    subgraph "Security Measures"
        direction TB

        Base[Minimal Base Image<br/>Reduced Attack Surface]
        Scan[Security Scanning<br/>Trivy, Clair]
        User[Non-Root User<br/>Privilege Separation]
        Caps[Capability Dropping<br/>Minimal Permissions]

        Base --> Scan
        Scan --> User
        User --> Caps

        Caps --> Runtime[Runtime Security]

        subgraph Runtime
            SELinux[SELinux/AppArmor<br/>Mandatory Access Control]
            Seccomp[Seccomp Profiles<br/>Syscall Filtering]
            Network[Network Policies<br/>Traffic Isolation]
        end
    end

    subgraph "Monitoring"
        Audit[Audit Logging]
        Metrics[Security Metrics]
        Alerts[Alert System]

        SELinux -.-> Audit
        Seccomp -.-> Metrics
        Network -.-> Alerts
    end

    style Base fill:#4caf50
    style Scan fill:#ff9800
    style Runtime fill:#f44336
```

---

## Template Override System

```mermaid
flowchart TB
    Start([Custom Build Required]) --> Base[Base Template<br/>docker/nova/Dockerfile.j2]
    Base --> Override{Need<br/>Override?}

    Override -->|No| Standard[Standard Build]
    Override -->|Yes| Custom[Create Override Template]

    Custom --> Blocks{Override<br/>Type?}

    Blocks -->|Header| Header[Modify Labels/Metadata]
    Blocks -->|Install| Install[Add Custom Packages]
    Blocks -->|Config| Config[Inject Configuration]
    Blocks -->|Footer| Footer[Post-Install Scripts]

    Header --> Merge[Merge with Base]
    Install --> Merge
    Config --> Merge
    Footer --> Merge

    Merge --> Render[Render Final Dockerfile]
    Standard --> Render

    Render --> Build([Build Custom Image])

    style Override fill:#ff9800
    style Merge fill:#2196f3
    style Build fill:#4caf50
```

**Override Example:**

```jinja2
{# template-override.j2 #}
{% extends parent_template %}

{% block nova_compute_footer %}
# Install custom driver
RUN pip install custom-virt-driver

# Add configuration
COPY custom-nova.conf /etc/nova/nova.conf.d/
{% endblock %}
```

---

## Useful Links

- 📖 **Documentation**: https://docs.openstack.org/kolla/latest/
- ❓ **FAQ**: [FAQ.md](FAQ.md)
- 📝 **Contributing**: [CONTRIBUTING.rst](CONTRIBUTING.rst)
- 📋 **Changelog**: [CHANGELOG.md](CHANGELOG.md)

---

**Note**: These diagrams use [Mermaid](https://mermaid.js.org/) syntax and can be rendered in:

- GitHub (native support)
- GitLab (native support)
- VS Code (with Mermaid extension)
- Documentation sites (Sphinx with mermaid extension)
