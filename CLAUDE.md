# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository builds a Docker image (`duyluann/terraform-toolkit`) that bundles Terraform infrastructure tools into a single container. The image includes Terraform, Terragrunt, Checkov, TFSec, TFLint, terraform-docs, Trivy, AWS CLI, eksctl, and pre-commit.

## Architecture

### Core Components

**Dockerfile**: Single-stage build that installs all tools with pinned versions specified as ARG variables at the top of the file. The build process:
- Uses Ubuntu 22.04 as base image
- Supports multi-architecture builds (linux/amd64 and linux/arm64)
- Creates a non-root user (`tf-user`) for security
- Downloads and installs binaries from official release pages
- Verifies all installations at the end

**Version Management**: Tool versions are defined as ARG variables in the Dockerfile (lines 4-12). When updating versions, modify these ARG values at the top of the Dockerfile.

### CI/CD Automation

The repository uses GitHub Actions for automated workflows:

**build-tf-toolkit-image.yaml**: Multi-platform Docker image build
- Builds for both amd64 and arm64 architectures in parallel
- Uses Docker Buildx with digest-based approach for multi-arch manifests
- Pushes to Docker Hub (duyluann/terraform-toolkit)
- Triggered on: version tags (v*), main branch pushes, manual dispatch

**check-tool-updates.yaml**: Automated dependency updates
- Runs weekly (Monday 00:00 UTC) and on main branch pushes
- Fetches latest versions from GitHub releases for all tools
- Automatically creates PR with version updates and changelogs
- Auto-approves and auto-merges the PR using WORKFLOW_TOKEN
- Updates the Dockerfile ARG values using sed commands

**create-release.yaml**: Manual release workflow
- Creates git tags and GitHub releases
- Triggered via workflow_dispatch with version input

**Semantic Release**: Configured via `.releaserc.json`
- Uses conventional commits for versioning
- Generates CHANGELOG.md automatically
- Commits changelog with `[skip ci]` to prevent build loops

### Development Workflow

**Pre-commit Hooks**: Basic checks defined in `.pre-commit-config.yaml`
- trailing-whitespace
- end-of-file-fixer
- check-yaml

## Common Commands

### Building the Docker Image

```bash
# Build for local architecture
docker build -t terraform-toolkit .

# Build for specific platform
docker build --platform linux/amd64 -t terraform-toolkit .
docker build --platform linux/arm64 -t terraform-toolkit .

# Build with custom tool version
docker build --build-arg TERRAFORM_VERSION=1.14.0 -t terraform-toolkit .
```

### Testing the Image

```bash
# Run container interactively
docker run -it terraform-toolkit:latest

# Verify tool versions
docker run terraform-toolkit:latest terraform --version
docker run terraform-toolkit:latest terragrunt --version
docker run terraform-toolkit:latest checkov --version

# Mount workspace and run Terraform
docker run -v $(pwd):/workspace -w /workspace terraform-toolkit:latest terraform init
```

### Updating Tool Versions

1. Edit the ARG variables in Dockerfile (lines 4-12)
2. Tool versions can also be updated automatically via the check-tool-updates workflow
3. The workflow runs weekly and creates PRs with latest versions

### Running Pre-commit Hooks

```bash
# Install hooks
pre-commit install

# Run on all files
pre-commit run --all-files

# Run specific hook
pre-commit run trailing-whitespace --all-files
```

## Important Notes

- **Multi-arch builds**: The build workflow creates separate images for amd64 and arm64, then merges them into a single manifest
- **Registry**: Images are pushed to Docker Hub at `duyluann/terraform-toolkit`
- **Auto-merge**: Tool update PRs are automatically approved and merged using the WORKFLOW_TOKEN secret
- **Version tagging**: Docker images are tagged with git tags (semver pattern) and `latest`
- **Non-root user**: The container runs as `tf-user` (UID 1000) by default for security

## Image Size Optimizations

The Dockerfile has been optimized to minimize image size:

1. **Combined RUN layers**: Tool installations are grouped into fewer RUN commands to reduce layers (from 10+ to 5 layers)
2. **--no-install-recommends**: APT packages installed without recommended packages to save space
3. **--no-cache-dir**: Python pip installations don't cache downloaded packages (saves ~100MB+)
4. **Removed sudo**: The sudo package was removed as it's not needed (~40MB saved)
5. **Single apt-get layer**: User creation and package installation combined into one layer
6. **Quiet downloads**: Using `-q` flags on wget/unzip to reduce build log verbosity
7. **Stream extraction**: eksctl uses piped extraction to avoid temporary files
8. **Cleaned extraction**: tar commands extract only specific binaries, not entire archives

## Security

- Uses Trivy for container vulnerability scanning (trivy-scan.yaml workflow)
- Uses Gitleaks for secret detection (gitleaks.yaml workflow)
- CodeQL analysis for code security (codeql.yaml workflow)
- Dependency review on pull requests (deps-review.yaml workflow)
