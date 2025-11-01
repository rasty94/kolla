# Makefile for Kolla OpenStack Deployment
# Provides common development tasks for contributors
#
# Usage: make [target]
# Example: make install test lint

.PHONY: help install install-dev test test-unit test-functional lint format clean build docs check-deps run-tests coverage pre-commit

# Default target - show help
help:  ## Show this help message
	@echo "Kolla - OpenStack Container Image Builder"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Common workflows:"
	@echo "  make install-dev    # Set up development environment"
	@echo "  make test           # Run all tests"
	@echo "  make lint           # Check code quality"
	@echo "  make format         # Auto-format code"
	@echo "  make build          # Build Docker images"
	@echo ""

# Installation targets

install:  ## Install package in production mode
	pip install --upgrade pip setuptools wheel
	pip install .

install-dev:  ## Install package in development mode with all dependencies
	pip install --upgrade pip setuptools wheel
	pip install -e ".[dev,test,docs,lint]"
	pre-commit install

install-test:  ## Install test dependencies only
	pip install --upgrade pip
	pip install -e ".[test]"

install-docs:  ## Install documentation dependencies
	pip install --upgrade pip
	pip install -e ".[docs]"

# Testing targets

test:  ## Run all tests
	stestr run

test-unit:  ## Run unit tests only
	stestr run --test-path ./kolla/tests/unit

test-functional:  ## Run functional tests only
	stestr run --test-path ./kolla/tests/functional

test-parallel:  ## Run tests in parallel
	stestr run --parallel

test-verbose:  ## Run tests with verbose output
	stestr run --verbose

coverage:  ## Run tests with coverage report
	coverage erase
	coverage run -m stestr run
	coverage combine
	coverage report
	coverage html
	@echo "Coverage report generated in htmlcov/index.html"

pytest:  ## Run tests using pytest (alternative)
	pytest -v

pytest-cov:  ## Run pytest with coverage
	pytest --cov=kolla --cov-report=html --cov-report=term

# Code quality targets

lint:  ## Run all linters
	@echo "Running ruff..."
	ruff check kolla/
	@echo "Running flake8/hacking..."
	flake8 kolla/
	@echo "Running bandit (security)..."
	bandit -r kolla/ -ll
	@echo "Running pydocstyle..."
	pydocstyle kolla/
	@echo "Running codespell..."
	codespell kolla/ docs/
	@echo "✓ All linters passed!"

lint-fix:  ## Run linters with auto-fix where possible
	ruff check --fix kolla/
	isort kolla/
	codespell -w kolla/ docs/

format:  ## Auto-format code with ruff
	ruff format kolla/
	ruff check --fix kolla/
	isort kolla/

check-format:  ## Check if code is formatted correctly
	ruff format --check kolla/
	isort --check-only kolla/

# Container/Docker targets

build:  ## Build all Kolla images
	kolla-build

build-nova:  ## Build Nova images
	kolla-build nova

build-neutron:  ## Build Neutron images
	kolla-build neutron

build-core:  ## Build core OpenStack images
	kolla-build keystone glance nova neutron cinder horizon

build-multi-arch:  ## Build multi-architecture images
	docker buildx create --use --name kolla-builder || true
	docker buildx build --platform linux/amd64,linux/arm64 --tag kolla/base:latest .

# Documentation targets

docs:  ## Build documentation
	sphinx-build -W -b html doc/source doc/build/html

docs-clean:  ## Clean documentation build
	rm -rf doc/build/

docs-serve:  ## Build and serve documentation locally
	sphinx-autobuild -b html doc/source doc/build/html

releasenotes:  ## Build release notes
	sphinx-build -a -E -W -d releasenotes/build/doctrees -b html releasenotes/source releasenotes/build/html

# Cleaning targets

clean:  ## Clean build artifacts
	rm -rf build/
	rm -rf dist/
	rm -rf *.egg-info
	rm -rf .eggs/
	rm -rf .tox/
	rm -rf htmlcov/
	rm -rf .coverage
	rm -rf .pytest_cache/
	rm -rf .ruff_cache/
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name '*.py[co]' -delete

clean-docker:  ## Clean Docker images and volumes
	docker system prune -f
	docker volume prune -f

clean-all:  ## Clean everything (build artifacts + Docker)
	$(MAKE) clean
	$(MAKE) clean-docker

# Development tools

pre-commit:  ## Run pre-commit hooks on all files
	pre-commit run --all-files

pre-commit-update:  ## Update pre-commit hooks
	pre-commit autoupdate

tox:  ## Run tox tests
	tox

tox-pep8:  ## Run PEP8 checks via tox
	tox -e pep8

tox-py311:  ## Run tests on Python 3.11
	tox -e py311

# Validation targets

validate-dockerfiles:  ## Validate all Dockerfiles
	./tools/validate-all-dockerfiles.sh

validate-yaml:  ## Validate YAML files
	./tools/validate-all-yaml.sh

validate-all:  ## Run all validation checks
	$(MAKE) validate-dockerfiles
	$(MAKE) validate-yaml
	$(MAKE) lint

# Security targets

security:  ## Run security checks
	bandit -r kolla/ -ll
	safety check --json || true

security-scan:  ## Scan image for vulnerabilities with Trivy (usage: make security-scan IMAGE=base)
	@if [ -z "$(IMAGE)" ]; then \
		echo "❌ Error: IMAGE variable required"; \
		echo "Usage: make security-scan IMAGE=<image-name>"; \
		exit 1; \
	fi
	@if ! command -v trivy &> /dev/null; then \
		echo "❌ Trivy not installed"; \
		echo "Install: https://aquasecurity.github.io/trivy/latest/getting-started/installation/"; \
		exit 1; \
	fi
	@echo "🔒 Scanning kolla/$(IMAGE):latest for vulnerabilities..."
	@trivy image --severity CRITICAL,HIGH,MEDIUM kolla/$(IMAGE):latest

security-scan-full:  ## Full security scan with all scanners (usage: make security-scan-full IMAGE=base)
	@if [ -z "$(IMAGE)" ]; then \
		echo "❌ Error: IMAGE variable required"; \
		exit 1; \
	fi
	@echo "🔒 Running comprehensive security scan..."
	@echo ""
	@echo "1️⃣  Trivy scan..."
	@$(MAKE) security-scan IMAGE=$(IMAGE) || true
	@echo ""
	@echo "2️⃣  Grype scan..."
	@if command -v grype &> /dev/null; then \
		grype kolla/$(IMAGE):latest; \
	else \
		echo "⚠️  Grype not installed (optional)"; \
	fi
	@echo ""
	@echo "3️⃣  SBOM generation..."
	@$(MAKE) generate-sbom IMAGE=$(IMAGE) || true

scan-image:  ## Alias for security-scan
	@$(MAKE) security-scan IMAGE=$(IMAGE)

generate-sbom:  ## Generate Software Bill of Materials (usage: make generate-sbom IMAGE=base)
	@if [ -z "$(IMAGE)" ]; then \
		echo "❌ Error: IMAGE variable required"; \
		exit 1; \
	fi
	@if ! command -v syft &> /dev/null; then \
		echo "❌ Syft not installed"; \
		echo "Install: curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin"; \
		exit 1; \
	fi
	@echo "📦 Generating SBOM for kolla/$(IMAGE):latest..."
	@syft kolla/$(IMAGE):latest -o spdx-json > sbom-$(IMAGE).spdx.json
	@syft kolla/$(IMAGE):latest -o cyclonedx-json > sbom-$(IMAGE).cyclonedx.json
	@echo "✅ SBOM generated:"
	@echo "   - sbom-$(IMAGE).spdx.json"
	@echo "   - sbom-$(IMAGE).cyclonedx.json"

security-report:  ## Generate security report for all images
	@echo "🛡️  Security Report for Kolla Images"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@if ! command -v trivy &> /dev/null; then \
		echo "❌ Trivy required for security reports"; \
		exit 1; \
	fi
	@for image in $$(docker images 'kolla/*' --format '{{.Repository}}:{{.Tag}}' | grep -v '<none>'); do \
		echo ""; \
		echo "Scanning: $$image"; \
		trivy image --severity CRITICAL,HIGH --quiet $$image | head -20 || true; \
	done
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

install-security-tools:  ## Install security scanning tools
	@echo "🔧 Installing security tools..."
	@echo ""
	@echo "1️⃣  Installing Trivy..."
	@if ! command -v trivy &> /dev/null; then \
		wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add - && \
		echo "deb https://aquasecurity.github.io/trivy-repo/deb $$(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list && \
		sudo apt-get update && sudo apt-get install -y trivy; \
	else \
		echo "   ✅ Trivy already installed"; \
	fi
	@echo ""
	@echo "2️⃣  Installing Syft..."
	@if ! command -v syft &> /dev/null; then \
		curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin; \
	else \
		echo "   ✅ Syft already installed"; \
	fi
	@echo ""
	@echo "3️⃣  Installing Grype (optional)..."
	@if ! command -v grype &> /dev/null; then \
		curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin; \
	else \
		echo "   ✅ Grype already installed"; \
	fi
	@echo ""
	@echo "✅ Security tools installed!"

# Dependency management

check-deps:  ## Check for outdated dependencies
	pip list --outdated

update-deps:  ## Update dependencies (requires pip-tools)
	pip-compile --upgrade requirements.txt
	pip-compile --upgrade test-requirements.txt

# Quick shortcuts

.PHONY: dev test-quick check all

dev: install-dev  ## Alias for install-dev

test-quick: lint test-unit  ## Quick test (lint + unit tests only)

check: lint test  ## Check everything (lint + all tests)

all: clean install-dev lint test docs  ## Do everything

# Version info

version:  ## Show version information
	@python -c "import kolla; print(f'Kolla version: {kolla.__version__}')"
	@python --version
	@docker --version
	@echo "Make targets available: run 'make help'"

# Git shortcuts

git-status:  ## Show git status
	git status

git-diff:  ## Show git diff
	git diff

# Info target

info:  ## Show project information
	@echo "Project: Kolla"
	@echo "Description: OpenStack container image builder"
	@echo "Python version: $(shell python --version)"
	@echo "Pip version: $(shell pip --version)"
	@echo "Docker version: $(shell docker --version 2>/dev/null || echo 'Docker not installed')"
	@echo "Current directory: $(shell pwd)"
	@echo ""
	@echo "Run 'make help' for available commands"

# Image analysis and optimization targets

analyze-image:  ## Analyze image size with dive
	@if ! command -v dive &> /dev/null; then \
		echo "❌ dive not installed"; \
		echo "Install: wget https://github.com/wagoodman/dive/releases/download/v0.12.0/dive_0.12.0_linux_amd64.deb && sudo dpkg -i dive_0.12.0_linux_amd64.deb"; \
		exit 1; \
	fi
	@read -p "Enter image name (e.g., kolla/nova-compute:latest): " image; \
	dive $$image

image-sizes:  ## Show sizes of all Kolla images
	@echo "Kolla Image Sizes:"
	@docker images 'kolla/*' --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | sort -k3 -h || echo "No Kolla images found"

image-layers:  ## Show layer information for an image
	@read -p "Enter image name (e.g., kolla/nova-compute:latest): " image; \
	echo "Layer history for $$image:"; \
	docker history $$image --no-trunc

image-inspect:  ## Inspect image details (JSON)
	@read -p "Enter image name (e.g., kolla/nova-compute:latest): " image; \
	docker inspect $$image | jq '.[0] | {Size: .Size, Created: .Created, Architecture: .Architecture, Os: .Os, Layers: .RootFS.Layers | length}'

compare-images:  ## Compare sizes between two images
	@read -p "Enter first image (e.g., kolla/nova-compute:old): " image1; \
	read -p "Enter second image (e.g., kolla/nova-compute:new): " image2; \
	echo "Size comparison:"; \
	docker images $$image1 $$image2 --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

total-image-size:  ## Calculate total size of all Kolla images
	@echo "Total size of all Kolla images:"
	@docker images 'kolla/*' --format "{{.Size}}" | sed 's/GB/*1024/;s/MB//;s/KB/\/1024/' | paste -sd+ | bc | awk '{printf "%.2f GB\n", $$1/1024}'

# Build cache optimization targets

build-cached:  ## Build image with BuildKit cache (usage: make build-cached IMAGE=base)
	@if [ -z "$(IMAGE)" ]; then \
		echo "❌ Error: IMAGE variable required"; \
		echo "Usage: make build-cached IMAGE=<image-name>"; \
		echo "Example: make build-cached IMAGE=base"; \
		exit 1; \
	fi
	@echo "🚀 Building $(IMAGE) with BuildKit cache..."
	@export DOCKER_BUILDKIT=1; \
	docker buildx build \
		--file docker/$(IMAGE)/Dockerfile.j2 \
		--tag kolla/$(IMAGE):cached \
		--cache-from type=local,src=/tmp/buildx-cache-$(IMAGE) \
		--cache-to type=local,dest=/tmp/buildx-cache-$(IMAGE),mode=max \
		--load \
		.
	@echo "✅ Build complete: kolla/$(IMAGE):cached"

build-cached-multi:  ## Build multiple images with cache (usage: make build-cached-multi IMAGES="base,openstack-base,nova-compute")
	@if [ -z "$(IMAGES)" ]; then \
		IMAGES="base,openstack-base,nova-compute,neutron-server,keystone"; \
	fi; \
	echo "🚀 Building images with cache: $$IMAGES"; \
	IFS=',' read -ra IMAGE_LIST <<< "$$IMAGES"; \
	for img in "$${IMAGE_LIST[@]}"; do \
		echo ""; \
		echo "Building $$img..."; \
		$(MAKE) build-cached IMAGE=$$img || true; \
	done; \
	echo ""; \
	echo "✅ All builds complete!"

clean-cache:  ## Clean BuildKit cache
	@echo "🧹 Cleaning BuildKit cache..."
	@rm -rf /tmp/buildx-cache-* 2>/dev/null || true
	@docker buildx prune -f
	@echo "✅ Cache cleaned"

cache-stats:  ## Show cache statistics
	@echo "📊 BuildKit Cache Statistics"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@if [ -d /tmp/buildx-cache-* ]; then \
		echo "Local cache directories:"; \
		du -sh /tmp/buildx-cache-* 2>/dev/null | sed 's|/tmp/buildx-cache-||' | awk '{printf "  %-20s %s\n", $$2, $$1}'; \
		echo ""; \
		echo "Total local cache size:"; \
		du -sh /tmp/buildx-cache-* 2>/dev/null | awk '{sum+=$$1} END {print "  " sum " MB"}'; \
	else \
		echo "  No local cache found"; \
	fi
	@echo ""
	@echo "Docker build cache:"
	@docker buildx du 2>/dev/null || echo "  (buildx not available)"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cache-benchmark:  ## Benchmark build with and without cache
	@if [ -z "$(IMAGE)" ]; then \
		echo "❌ Error: IMAGE variable required"; \
		echo "Usage: make cache-benchmark IMAGE=<image-name>"; \
		exit 1; \
	fi
	@echo "⏱️  Benchmarking build performance for $(IMAGE)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "1️⃣  Cold build (no cache)..."
	@$(MAKE) clean-cache > /dev/null 2>&1
	@TIME_START=$$(date +%s); \
	$(MAKE) build-cached IMAGE=$(IMAGE) > /dev/null 2>&1; \
	TIME_END=$$(date +%s); \
	COLD_TIME=$$((TIME_END - TIME_START)); \
	echo "   Cold build time: $${COLD_TIME}s"
	@echo ""
	@echo "2️⃣  Warm build (with cache)..."
	@TIME_START=$$(date +%s); \
	$(MAKE) build-cached IMAGE=$(IMAGE) > /dev/null 2>&1; \
	TIME_END=$$(date +%s); \
	WARM_TIME=$$((TIME_END - TIME_START)); \
	echo "   Warm build time: $${WARM_TIME}s"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

setup-buildx:  ## Setup Docker Buildx for caching
	@echo "🔧 Setting up Docker Buildx..."
	@docker buildx create --name kolla-builder --driver docker-container --use 2>/dev/null || \
		docker buildx use kolla-builder 2>/dev/null || \
		echo "Buildx already configured"
	@docker buildx inspect --bootstrap
	@echo "✅ Buildx ready for cached builds"
