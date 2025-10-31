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
