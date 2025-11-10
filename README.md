# 🛠️ Terraform Toolkit Docker Image

[![Build Terraform Toolkit Image](https://github.com/duyluann/terraform-toolkit-docker/actions/workflows/build-tf-toolkit-image.yaml/badge.svg?branch=main)](https://github.com/duyluann/terraform-toolkit-docker/actions/workflows/build-tf-toolkit-image.yaml)

This repository provides a Docker image for a comprehensive Terraform toolkit. It bundles essential Terraform-related tools such as Terraform, Terragrunt, Checkov, TFSec, TFDoc, and TFLint to streamline infrastructure management, security checks, and linting.

## 🧰 Tools Included
The Docker image includes the following tools:

- 🌍 [Terraform](https://www.terraform.io/): Infrastructure as Code (IaC) tool to manage cloud and on-prem resources.
- 🚜 [Terragrunt](https://terragrunt.gruntwork.io/): A thin wrapper for Terraform that provides extra tools for keeping your configurations DRY.
- 🔍 [Checkov](https://www.checkov.io/): Static code analysis tool for infrastructure-as-code to detect cloud misconfigurations.
- 📄 [terraform-docs](https://terraform-docs.io/): Generate documentation for your Terraform modules in various output formats.
- 🔐 [TFSec](https://github.com/aquasecurity/tfsec): A security scanner for your Terraform code.
- 🔧 [TFLint](https://github.com/terraform-linters/tflint): A linter for Terraform code to detect potential errors and enforce best practices.

## 🚀 Getting Started

### ✅ Prerequisites
Make sure you have Docker installed on your system before using this image.

#### Install Docker
📥 Pulling the Docker Image

The image repository: [terraform-toolkit](https://hub.docker.com/r/duyluann/terraform-toolkit) 📦

To pull the pre-built Docker image from Docker Hub:

```bash
docker pull duyluann/terraform-toolkit:latest
```

#### 🏃 Usage
To run the container:

```bash
docker run -it duyluann/terraform-toolkit:latest
```

You can then use the following tools from within the container:

- terraform
- terragrunt
- checkov
- terraform-docs
- tfsec
- tflint
- trivy
- eksctl
- pre-commit

### 💡 Example
Run Terraform commands inside the container:

```bash
docker run -v $(pwd):/workspace -w /workspace duyluann/terraform-toolkit:latest terraform init
```

This command mounts your current working directory (pwd) into the container's /workspace directory and runs terraform init.

## 🛠️ Local Development

This repository includes a comprehensive local development toolkit to help you build, test, and validate changes before pushing to CI.

### Quick Start

```bash
# Show all available commands
make help

# Build the image locally
make build

# Run smoke tests
make test

# Launch interactive shell
make shell

# Run security scan
make scan
```

### Available Make Targets

| Command | Description |
|---------|-------------|
| `make help` | Show all available commands with descriptions |
| `make build` | Build Docker image for current platform |
| `make build-amd64` | Build Docker image for amd64 architecture |
| `make build-arm64` | Build Docker image for arm64 architecture |
| `make test` | Run comprehensive smoke tests on all tools |
| `make shell` | Launch interactive shell in container |
| `make scan` | Run Trivy security scan |
| `make compare-sizes` | Compare image sizes between different versions |
| `make clean` | Remove local test images |
| `make quick-test` | Quick build and test cycle |
| `make ci-test` | Run CI-like tests locally (build + test + scan) |
| `make version` | Show all tool versions in the image |

### Helper Scripts

The repository includes several helper scripts in the `scripts/` directory:

#### `scripts/test-tools.sh`
Comprehensive test suite that validates:
- All tools are installed and accessible
- Basic functionality of each tool (init, plan, scan, etc.)
- Tool interoperability (Terraform + Terragrunt)
- User permissions and environment setup

```bash
# Run tests on default image
./scripts/test-tools.sh

# Run tests on specific image
./scripts/test-tools.sh terraform-toolkit:custom-tag
```

#### `scripts/local-build.sh`
Smart build script with timing and verification:
```bash
# Build with defaults
./scripts/local-build.sh

# Build with custom settings
IMAGE_NAME=my-toolkit IMAGE_TAG=dev ./scripts/local-build.sh
```

#### `scripts/test-image.sh`
Quick validation before pushing:
```bash
# Validate default image
./scripts/test-image.sh

# Validate specific image
./scripts/test-image.sh terraform-toolkit:v1.0.0
```

#### `scripts/compare-sizes.sh`
Compare image sizes and layer counts:
```bash
./scripts/compare-sizes.sh
```

### Docker Compose Setup

For local testing with your actual Terraform projects:

1. **Copy the environment file:**
   ```bash
   cp .env.example .env
   # Edit .env with your AWS credentials and preferences
   ```

2. **Start interactive session:**
   ```bash
   docker-compose up -d terraform-toolkit
   docker-compose exec terraform-toolkit bash
   ```

3. **Run Terraform commands:**
   ```bash
   # In your workspace directory
   docker-compose run --rm terraform-toolkit terraform init
   docker-compose run --rm terraform-toolkit terraform plan
   ```

4. **Run security scans:**
   ```bash
   docker-compose --profile security run --rm security-scan
   ```

5. **Run linting:**
   ```bash
   docker-compose --profile lint run --rm tflint
   ```

6. **Clean up:**
   ```bash
   docker-compose down -v
   ```

### Customization

You can customize the build using environment variables:

```bash
# Build for specific platform
PLATFORM=arm64 make build

# Use custom image name and tag
IMAGE_NAME=my-toolkit IMAGE_TAG=dev make build

# Build with specific tool version
docker build --build-arg TERRAFORM_VERSION=1.14.0 -t terraform-toolkit:custom .
```

### Testing Your Changes

Before submitting a pull request:

```bash
# Run the full CI test suite locally
make ci-test

# Or run individual steps
make build
make test
make scan
```

### Troubleshooting

**Build fails with "no space left on device":**
```bash
# Clean up Docker resources
docker system prune -a
make clean-all
```

**Tools not found in container:**
```bash
# Verify installation
make version

# Check specific tool
docker run --rm terraform-toolkit:local which terraform
```

**Permission issues with mounted volumes:**
```bash
# The container runs as user ID 1000
# Ensure your local files have appropriate permissions
ls -la workspace/
```

### ⚙️ Continuous Integration / Continuous Delivery
This repository includes several GitHub Actions workflows to automate testing, dependency updates, and release processes.

- 🔨 Build and Test: The build-tf-toolkit-image.yaml workflow builds and tests the Docker image automatically.
- 🔄 Dependency Checks: The check-tool-updates.yaml and deps-review.yaml workflows handle automatic updates and reviews of dependencies.
- 📦 Release Automation: The create-release.yaml workflow automates creating new releases when updates are ready.
- 🔍 Pre-commit Checks: The pre-commit-auto-update.yaml ensures that pre-commit hooks and lints are consistently maintained.

### 🗂️ Project Structure
```bash
├── .editorconfig                 # Editor configuration for consistent coding styles
├── .env.example                  # Example environment variables for docker-compose
├── .github/                      # GitHub workflows for CI/CD automation
│   ├── ISSUE_TEMPLATE/           # Templates for GitHub issues
│   ├── workflows/                # CI/CD pipelines (build, release, etc.)
│   ├── dependabot.yml            # Automatic dependency updates
│   └── pull_request_template.md  # Template for pull requests
├── .gitignore                    # Files and directories to ignore in Git
├── .pre-commit-config.yaml       # Pre-commit hooks configuration
├── .vscode/extensions.json       # Recommended extensions for VSCode users
├── CLAUDE.md                     # Project guidance for Claude Code
├── CODEOWNERS                    # File to manage repository code owners
├── docker-compose.yml            # Docker Compose configuration for local development
├── Dockerfile                    # Dockerfile to build the image with the tools
├── LICENSE                       # License for the project
├── Makefile                      # Development commands and automation
├── README.md                     # Documentation (you're reading this!)
└── scripts/                      # Helper scripts for development
    ├── compare-sizes.sh          # Compare Docker image sizes
    ├── local-build.sh            # Smart local build script
    ├── test-image.sh             # Quick image validation
    └── test-tools.sh             # Comprehensive test suite
```

### 🤝 Contributing
We welcome contributions! To get started:

- 🍴 Fork the repository.
- 🛠️ Create a new branch for your feature or bug fix.
- 📥 Submit a pull request when your changes are ready.
Please make sure to follow our coding style guidelines and ensure all tests pass.

### 📄 License
This project is licensed under the terms of the [MIT License](./LICENSE).
