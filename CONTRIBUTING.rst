============================
Contributing to Kolla
============================

Thank you for your interest in contributing to Kolla! This guide will help you get started.

🚀 Quick Start for Contributors
================================

The source repository for this project can be found at:

   https://opendev.org/openstack/kolla

Pull requests submitted through GitHub are **not** monitored.

To start contributing to OpenStack, follow the steps in the contribution guide
to set up and use Gerrit:

   https://docs.openstack.org/contributors/code-and-documentation/quick-start.html

Bugs should be filed on Launchpad:

   https://bugs.launchpad.net/kolla

For more specific information about contributing to this repository, see the
Kolla contributor guide:

   https://docs.openstack.org/kolla/latest/contributor/contributing.html

📋 Contribution Workflow
=========================

1. **Setup Development Environment**
   ::

      # Clone the repository
      git clone https://opendev.org/openstack/kolla
      cd kolla

      # Quick setup using Makefile
      make install-dev

   Or manually::

      # Install in development mode with all dependencies
      pip install -e ".[dev,test,docs,lint]"

      # Install pre-commit hooks
      pre-commit install

   **Note**: The project now uses ``pyproject.toml`` for modern Python packaging.
   All configuration is centralized in this file following PEP 517/518/621 standards.

2. **Create a Feature Branch**
   ::

      # Install git-review
      pip install git-review

      # Setup git-review
      git review -s

      # Create a new branch
      git checkout -b bug/123456-fix-nova-build

3. **Make Your Changes**

   - Write clean, readable code
   - Follow PEP 8 style guidelines
   - Add tests for new functionality
   - Update documentation as needed

4. **Test Your Changes**

   Using Makefile (recommended)::

      # Run all tests
      make test

      # Run only linting
      make lint

      # Run tests with coverage
      make coverage

      # Quick check (lint + unit tests)
      make test-quick

   Or using tox directly::

      # Run unit tests
      tox -e py311

      # Run linting
      tox -e pep8

      # Run specific tests
      tox -e py311 -- tests/test_build.py

   Build test images::

      # Using Makefile
      make build-nova

      # Or directly
      kolla-build --debug nova

5. **Commit Your Changes**
   ::

      # Stage your changes
      git add .

      # Commit with a descriptive message
      git commit

   **Commit Message Format:**
   ::

      Short (50 chars or less) summary

      More detailed explanatory text, if necessary. Wrap it to
      about 72 characters. The blank line separating the summary
      from the body is critical.

      Change-Id: I1234567890123456789012345678901234567890
      Closes-Bug: #123456
      Implements: blueprint feature-name

6. **Submit for Review**
   ::

      # Submit to Gerrit
      git review

      # Address review feedback
      git commit --amend
      git review

🧪 Testing Guidelines
======================

Running Tests Locally
---------------------

**Quick Reference - Using Makefile:**

The project includes a comprehensive ``Makefile`` with common development tasks::

   # Show all available commands
   make help

   # Run all tests
   make test

   # Run linters
   make lint

   # Run tests with coverage
   make coverage

   # Auto-format code
   make format

   # Build images
   make build-core

See ``make help`` for the complete list of targets.

**Unit Tests:**

Using Makefile::

   # Run all tests
   make test

   # Run unit tests only
   make test-unit

   # Run with coverage
   make coverage

Or using tox::

   # Run all tests
   tox -e py311

   # Run with coverage
   tox -e cover

   # Run specific test file
   pytest tests/test_build.py

**Linting:**

Using Makefile (recommended)::

   # Run all linters
   make lint

   # Auto-fix lint issues
   make lint-fix

   # Format code with ruff
   make format

Or using tox::

   # Python linting
   tox -e pep8

   # Ansible linting
   tox -e ansible-lint

   # All linting
   tox -e linting

**Building Test Images:**
::

   # Build a single image
   kolla-build --debug --template-only nova

   # Build with specific configuration
   kolla-build --base ubuntu --type binary nova

Writing Tests
-------------

**Example Unit Test:**

.. code-block:: python

   import unittest
   from kolla.image import build

   class TestImageBuild(unittest.TestCase):
       def test_image_name_parsing(self):
           """Test that image names are parsed correctly."""
           result = build.parse_image_name('kolla/nova-compute:latest')
           self.assertEqual(result['namespace'], 'kolla')
           self.assertEqual(result['name'], 'nova-compute')
           self.assertEqual(result['tag'], 'latest')

       def test_invalid_image_name(self):
           """Test that invalid names raise exceptions."""
           with self.assertRaises(ValueError):
               build.parse_image_name('invalid:::name')

**Test Coverage Requirements:**

- All new code must have tests
- Minimum 80% coverage for new files
- Critical paths require 100% coverage
- Include positive and negative test cases

🎨 Code Style Guidelines
=========================

Python Code Style
-----------------

- Follow **PEP 8** strictly
- Use **4 spaces** for indentation (never tabs)
- Maximum line length: **79 characters** for code
- Maximum line length: **72 characters** for docstrings
- Use **double quotes** for strings

**Example:**

.. code-block:: python

   """Module docstring describing the module's purpose.

   This module handles image building operations for Kolla.
   """

   import os
   import logging

   from kolla import exception
   from kolla.common import config


   LOG = logging.getLogger(__name__)


   class ImageBuilder:
       """Builds Docker images for OpenStack services.

       This class handles the entire image building process including
       Jinja2 template rendering, Docker build execution, and image
       tagging.

       Args:
           config: Configuration object with build settings
           base: Base image name (e.g., 'ubuntu', 'rocky')
           type: Build type ('binary' or 'source')

       Example:
           >>> builder = ImageBuilder(config, base='ubuntu', type='binary')
           >>> builder.build_image('nova-compute')
       """

       def __init__(self, config, base='ubuntu', type='binary'):
           self.config = config
           self.base = base
           self.type = type

       def build_image(self, image_name):
           """Build a single Docker image.

           Args:
               image_name: Name of the image to build

           Returns:
               str: Full image name with tag

           Raises:
               BuildException: If build fails
           """
           LOG.info(f"Building image: {image_name}")
           try:
               # Build implementation
               pass
           except Exception as e:
               raise exception.BuildException(
                   f"Failed to build {image_name}: {e}"
               )

Jinja2 Template Style
---------------------

**Example:**

.. code-block:: jinja

   {% extends parent_template %}

   # Header section with metadata
   {% block nova_compute_header %}
   LABEL maintainer="Kolla Team <kolla@lists.openstack.org>"
   LABEL description="OpenStack Nova Compute Service"
   {% endblock %}

   # Main installation block
   {% block nova_compute_install %}
   {{ macros.install_pip_packages(['nova', 'libvirt-python']) }}
   {% endblock %}

   # Configuration block
   {% block nova_compute_config %}
   COPY nova.conf /etc/nova/nova.conf
   RUN chown -R nova:nova /etc/nova
   {% endblock %}

   # Footer for customizations
   {% block nova_compute_footer %}
   # Add custom packages here
   {% endblock %}

🔧 Common Contribution Scenarios
=================================

Adding a New Service
--------------------

1. **Create Dockerfile template** in ``docker/service-name/``
2. **Add parent image** configuration
3. **Create tests** in ``tests/``
4. **Update documentation**
5. **Submit blueprint** if it's a major service

Example structure::

   docker/
   ├── nova/
   │   ├── Dockerfile.j2
   │   ├── nova-api/
   │   │   └── Dockerfile.j2
   │   └── nova-compute/
   │       └── Dockerfile.j2

Fixing a Bug
------------

1. **Reproduce the bug** locally
2. **Write a failing test** that demonstrates the bug
3. **Fix the bug** in the code
4. **Verify test passes**
5. **Submit with bug reference**

Example commit message::

   Fix Nova image build failure on ARM64

   The Nova compute image was failing to build on ARM64
   platforms due to missing libvirt dependencies.

   This patch adds platform-specific package selection
   to ensure the correct libvirt packages are installed
   based on the target architecture.

   Closes-Bug: #123456
   Change-Id: I1234567890123456789012345678901234567890

Adding a Plugin or Extension
-----------------------------

Use template overrides:

.. code-block:: jinja

   {# template-override-networking-plugin.j2 #}
   {% extends parent_template %}

   {% block neutron_server_footer %}
   # Install custom networking plugin
   RUN pip install networking-custom-plugin

   # Add plugin configuration
   COPY plugin.conf /etc/neutron/plugins/custom/
   {% endblock %}

Build with override::

   kolla-build --template-override template-override-networking-plugin.j2 neutron

📚 Additional Resources
========================

Documentation
-------------

- 📖 **Kolla Documentation**: https://docs.openstack.org/kolla/latest/
- 📖 **Contributor Guide**: https://docs.openstack.org/kolla/latest/contributor/
- ❓ **FAQ**: `FAQ.md <FAQ.md>`_
- 📝 **Changelog**: `CHANGELOG.md <CHANGELOG.md>`_

Communication Channels
----------------------

- 💬 **IRC**: #openstack-kolla on OFTC
- 📧 **Mailing List**: openstack-discuss@lists.openstack.org (tag [kolla])
- 🎥 **Meetings**: Weekly on Wednesdays at 15:00 UTC
- 📊 **Meeting Agenda**: https://etherpad.opendev.org/p/KollaMeetingAgenda

Development Tools
-----------------

Project Configuration:

- **pyproject.toml**: Modern Python packaging configuration (PEP 517/518/621)
- **.editorconfig**: Editor settings for consistent code style across IDEs
- **Makefile**: Common development tasks (``make help`` for all commands)
- **.pre-commit-config.yaml**: Pre-commit hooks for code quality

External Services:

- **Gerrit**: https://review.opendev.org/
- **Zuul CI**: https://zuul.opendev.org/
- **Launchpad**: https://launchpad.net/kolla
- **Stackalytics**: https://stackalytics.io/?module=kolla-group

🏆 Recognition
==============

All contributors are recognized in our:

- **Git history**: Your commits are forever part of OpenStack
- **Release notes**: Major contributions are highlighted
- **Stackalytics**: Track your contributions and reviews
- **OpenStack community**: Active contributors can become core reviewers

✅ Review Checklist
====================

Before submitting, ensure:

- [ ] Code follows PEP 8 style guidelines
- [ ] All tests pass locally (``make test`` or ``tox -e py311,pep8``)
- [ ] Linters pass (``make lint`` or ``tox -e pep8``)
- [ ] New functionality includes tests
- [ ] Documentation is updated
- [ ] Commit message follows guidelines
- [ ] Change-Id is present in commit message
- [ ] Pre-commit hooks pass (``make pre-commit``)
- [ ] No secrets or credentials in code
- [ ] .editorconfig settings respected (automatic in most IDEs)

🎓 Learning Resources
======================

New to OpenStack Development?
------------------------------

- `OpenStack Contributor Guide <https://docs.openstack.org/contributors/>`_
- `Gerrit Workflow Tutorial <https://docs.openstack.org/contributors/code-and-documentation/quick-start.html>`_
- `Git Review Documentation <https://docs.openstack.org/infra/git-review/>`_

New to Docker?
--------------

- `Docker Documentation <https://docs.docker.com/>`_
- `Dockerfile Best Practices <https://docs.docker.com/develop/dev-best-practices/>`_
- `Multi-stage Builds <https://docs.docker.com/develop/develop-images/multistage-build/>`_

New to Jinja2?
--------------

- `Jinja2 Documentation <https://jinja.palletsprojects.com/>`_
- `Template Designer Documentation <https://jinja.palletsprojects.com/templates/>`_

🤝 Code of Conduct
==================

Kolla follows the OpenStack Community Code of Conduct:

   https://www.openstack.org/legal/community-code-of-conduct/

We are committed to providing a welcoming and inclusive environment for all contributors.

---

**Questions?** Ask in #openstack-kolla on IRC or the mailing list!

**Ready to contribute?** Start with `good first issues <https://bugs.launchpad.net/kolla/+bugs?field.tag=low-hanging-fruit>`_ on Launchpad.
