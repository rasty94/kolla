# Testing Strategy and Coverage Requirements

This document describes Kolla's testing strategy, coverage requirements, and best practices for writing and running tests.

## Overview

Kolla maintains a **minimum code coverage requirement of 80%** for all Python code. This ensures:

- **Code Quality**: Well-tested code is more reliable
- **Regression Prevention**: Tests catch bugs before they reach production
- **Documentation**: Tests serve as living documentation
- **Confidence**: High coverage enables safe refactoring

## Coverage Requirements

### Minimum Thresholds

| Metric | Requirement | Status |
|--------|-------------|--------|
| **Overall Coverage** | ≥ 80% | ✅ Enforced in CI |
| **Branch Coverage** | ≥ 75% | ✅ Enforced |
| **New Code** | ≥ 90% | ⚠️  Recommended |

### Configuration

Coverage is configured in `pyproject.toml` and `.coveragerc`:

```toml
[tool.coverage.report]
fail_under = 80.0
branch = true
show_missing = true
```

### CI Enforcement

- **GitHub Actions**: Fails if coverage < 80%
- **Pre-commit**: Optional coverage check
- **Renovate**: Coverage reports on dependency PRs

## Test Types

### 1. Unit Tests

**Purpose**: Test individual functions/classes in isolation

**Location**: `tests/unit/`

**Characteristics**:
- Fast execution (< 1 second per test)
- No external dependencies
- Mock all I/O operations
- Test single responsibility

**Example**:
```python
import unittest
from unittest.mock import Mock, patch

class TestKollaBuild(unittest.TestCase):
    def test_parse_config_valid(self):
        """Test configuration parsing with valid input."""
        config = parse_config("valid.conf")
        self.assertEqual(config['base'], 'centos')
    
    @patch('kolla.build.docker')
    def test_build_image_success(self, mock_docker):
        """Test successful image build."""
        mock_docker.build.return_value = Mock(id='sha256:abc123')
        result = build_image('base', 'latest')
        self.assertTrue(result.success)
```

### 2. Integration Tests

**Purpose**: Test interaction between components

**Location**: `tests/integration/`

**Characteristics**:
- Medium execution time (< 10 seconds)
- May use real dependencies (databases, files)
- Test component interactions
- Verify contracts between modules

**Example**:
```python
import pytest
from kolla.image import builder
from kolla.common import config

@pytest.mark.integration
class TestImageBuilder:
    def test_build_with_real_dockerfile(self, tmp_path):
        """Test building an image with actual Dockerfile."""
        dockerfile = tmp_path / "Dockerfile"
        dockerfile.write_text("FROM centos:8\nRUN echo 'test'")
        
        builder_obj = builder.ImageBuilder(str(tmp_path))
        result = builder_obj.build()
        
        assert result.success
        assert result.image_id is not None
```

### 3. Functional Tests

**Purpose**: End-to-end testing of features

**Location**: `tests/functional/`

**Characteristics**:
- Slow execution (> 10 seconds)
- Use actual containers/Docker
- Test complete workflows
- Verify user-facing functionality

**Example**:
```python
import pytest
import subprocess

@pytest.mark.functional
@pytest.mark.slow
class TestKollaBuildCLI:
    def test_build_centos_base_image(self):
        """Test building CentOS base image via CLI."""
        result = subprocess.run(
            ['kolla-build', '--base', 'centos', '--tag', 'test', 'base'],
            capture_output=True,
            text=True,
            timeout=300
        )
        
        assert result.returncode == 0
        assert 'Successfully built' in result.stdout
```

## Running Tests

### Quick Start

```bash
# Run all unit tests with coverage
./tools/run-tests.sh

# Run with pytest directly
pytest

# Run specific test file
pytest tests/unit/test_build.py

# Run specific test
pytest tests/unit/test_build.py::TestKollaBuild::test_parse_config
```

### Common Options

```bash
# Run without coverage
./tools/run-tests.sh --no-coverage

# Run all test types
./tools/run-tests.sh --all

# Run integration tests only
./tools/run-tests.sh --integration

# Verbose output
./tools/run-tests.sh --verbose

# Open HTML coverage report
./tools/run-tests.sh --open

# Require 85% coverage
./tools/run-tests.sh --fail-under 85
```

### Using pytest Markers

```bash
# Run only unit tests
pytest -m unit

# Run only integration tests
pytest -m integration

# Run only functional tests
pytest -m functional

# Skip slow tests
pytest -m "not slow"

# Run specific combination
pytest -m "unit and not slow"
```

### Coverage Reports

```bash
# Generate HTML report
pytest --cov=kolla --cov-report=html
open htmlcov/index.html  # macOS
xdg-open htmlcov/index.html  # Linux

# Generate XML report (for CI)
pytest --cov=kolla --cov-report=xml

# Terminal report with missing lines
pytest --cov=kolla --cov-report=term-missing

# JSON report
pytest --cov=kolla --cov-report=json
```

## Writing Good Tests

### Test Structure (AAA Pattern)

```python
def test_feature():
    # Arrange: Set up test data and conditions
    config = {'base': 'centos', 'tag': 'latest'}
    builder = ImageBuilder(config)
    
    # Act: Execute the code being tested
    result = builder.build()
    
    # Assert: Verify the results
    assert result.success
    assert result.image_id.startswith('sha256:')
```

### Test Naming

- **Descriptive**: `test_build_fails_with_invalid_dockerfile`
- **Not vague**: ~~`test_build`~~
- **Use underscores**: `test_parse_config_with_comments`
- **Start with `test_`**: Required by pytest

### Best Practices

#### 1. One Assert Per Test (When Possible)

```python
# Good: Focused test
def test_config_has_base_image():
    config = parse_config('test.conf')
    assert config['base'] == 'centos'

def test_config_has_tag():
    config = parse_config('test.conf')
    assert config['tag'] == 'latest'

# Acceptable: Related assertions
def test_config_structure():
    config = parse_config('test.conf')
    assert 'base' in config
    assert 'tag' in config
    assert isinstance(config, dict)
```

#### 2. Use Fixtures for Setup

```python
import pytest

@pytest.fixture
def sample_config():
    """Provide a sample configuration for tests."""
    return {
        'base': 'centos',
        'tag': 'latest',
        'namespace': 'kolla'
    }

def test_with_fixture(sample_config):
    builder = ImageBuilder(sample_config)
    assert builder.base == 'centos'
```

#### 3. Mock External Dependencies

```python
from unittest.mock import Mock, patch

@patch('kolla.build.docker.from_env')
def test_docker_connection(mock_docker):
    # Mock Docker client
    mock_client = Mock()
    mock_docker.return_value = mock_client
    
    # Test code that uses Docker
    builder = ImageBuilder()
    builder.connect()
    
    mock_docker.assert_called_once()
```

#### 4. Test Edge Cases

```python
def test_parse_config_empty_file():
    """Test handling of empty configuration file."""
    with pytest.raises(ConfigError):
        parse_config('empty.conf')

def test_parse_config_missing_file():
    """Test handling of missing configuration file."""
    with pytest.raises(FileNotFoundError):
        parse_config('nonexistent.conf')

def test_parse_config_malformed():
    """Test handling of malformed configuration."""
    with pytest.raises(ConfigError):
        parse_config('malformed.conf')
```

#### 5. Use Parametrize for Multiple Inputs

```python
@pytest.mark.parametrize("base,expected", [
    ('centos', 'centos:stream8'),
    ('ubuntu', 'ubuntu:22.04'),
    ('debian', 'debian:12'),
])
def test_resolve_base_image(base, expected):
    """Test base image resolution for different distros."""
    result = resolve_base(base)
    assert result == expected
```

## Coverage Strategies

### What to Cover

✅ **Do Cover**:
- Business logic
- Error handling
- Edge cases
- Public APIs
- Complex algorithms
- Configuration parsing

❌ **Don't Need to Cover**:
- Third-party library code
- Generated code
- Simple property getters/setters
- `__repr__` and `__str__` methods (unless complex)

### Improving Coverage

1. **Identify gaps**:
```bash
pytest --cov=kolla --cov-report=term-missing
```

2. **Focus on untested files**:
```bash
coverage report --skip-covered
```

3. **Generate HTML report**:
```bash
pytest --cov=kolla --cov-report=html
open htmlcov/index.html
```

4. **Add tests incrementally**:
   - Start with critical paths
   - Add edge case tests
   - Test error conditions

### Coverage Pragmas

Use sparingly for truly untestable code:

```python
def debug_function():  # pragma: no cover
    """This function is only used during development."""
    import pdb; pdb.set_trace()

if TYPE_CHECKING:  # pragma: no cover
    from typing import Optional
```

## Test Data

### Using Fixtures

```python
@pytest.fixture
def temp_dockerfile(tmp_path):
    """Create a temporary Dockerfile for testing."""
    dockerfile = tmp_path / "Dockerfile"
    dockerfile.write_text("""
FROM centos:8
RUN yum install -y python3
CMD ["/bin/bash"]
""")
    return dockerfile
```

### Test Data Files

Place test data in `tests/fixtures/`:

```
tests/
├── fixtures/
│   ├── configs/
│   │   ├── valid.conf
│   │   ├── invalid.conf
│   │   └── minimal.conf
│   ├── dockerfiles/
│   │   ├── Dockerfile.centos
│   │   └── Dockerfile.ubuntu
│   └── images/
│       └── sample-image.tar
```

### Loading Test Data

```python
import pathlib

FIXTURES_DIR = pathlib.Path(__file__).parent / 'fixtures'

def load_config(name):
    config_file = FIXTURES_DIR / 'configs' / f'{name}.conf'
    return config_file.read_text()
```

## Continuous Integration

### GitHub Actions

```yaml
- name: Run tests with coverage
  run: |
    pytest --cov=kolla --cov-report=xml --cov-fail-under=80

- name: Upload coverage to Codecov
  uses: codecov/codecov-action@v4
  with:
    files: ./coverage.xml
```

### Zuul

Tests run automatically on:
- Every commit
- Pull requests
- Merge queue

### Pre-commit

Optional coverage check:

```yaml
- repo: local
  hooks:
    - id: pytest-coverage
      name: Check test coverage
      entry: pytest --cov=kolla --cov-fail-under=80
      language: system
      pass_filenames: false
```

## Troubleshooting

### Tests Fail Locally

1. **Clean environment**:
```bash
rm -rf .tox/ .pytest_cache/ htmlcov/ .coverage
```

2. **Reinstall dependencies**:
```bash
pip install -r requirements.txt -r test-requirements.txt
```

3. **Run single test**:
```bash
pytest tests/unit/test_build.py::test_specific -v
```

### Coverage Too Low

1. **Identify uncovered code**:
```bash
coverage report --skip-covered
```

2. **Generate HTML report**:
```bash
coverage html
open htmlcov/index.html
```

3. **Add tests for uncovered lines**

### Flaky Tests

1. **Identify**:
```bash
pytest --count=10  # Run 10 times
```

2. **Fix**:
   - Remove time dependencies
   - Mock external services
   - Use deterministic test data
   - Add proper cleanup

### Slow Tests

1. **Profile tests**:
```bash
pytest --durations=10
```

2. **Optimize**:
   - Use mocks instead of real resources
   - Reduce test data size
   - Mark slow tests: `@pytest.mark.slow`
   - Run in parallel: `pytest -n auto`

## Resources

- [pytest Documentation](https://docs.pytest.org/)
- [coverage.py Documentation](https://coverage.readthedocs.io/)
- [Python Testing Best Practices](https://docs.python-guide.org/writing/tests/)
- [OpenStack Testing Guidelines](https://docs.openstack.org/hacking/latest/user/hacking.html#testing)

## Questions?

- **GitHub Issues**: https://github.com/rasty94/kolla/issues
- **IRC**: #openstack-kolla on OFTC
- **Mailing List**: openstack-discuss@lists.openstack.org

---

Last updated: October 31, 2025
