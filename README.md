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

The image repository: [terraform-toolkit](https://hub.docker.com/repository/docker/duyluann/terraform-toolkit/general).

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

This command mounts your current working directory (pwd) into the container’s /workspace directory and runs terraform init.

### ⚙️ Continuous Integration / Continuous Delivery
This repository includes several GitHub Actions workflows to automate testing, dependency updates, and release processes.

- 🔨 Build and Test: The build-tf-toolkit-image.yaml workflow builds and tests the Docker image automatically.
- 🔄 Dependency Checks: The check-tool-updates.yaml and deps-review.yaml workflows handle automatic updates and reviews of dependencies.
- 📦 Release Automation: The create-release.yaml workflow automates creating new releases when updates are ready.
- 🔍 Pre-commit Checks: The pre-commit-auto-update.yaml ensures that pre-commit hooks and lints are consistently maintained.

### 🗂️ Project Structure
```bash
├── .editorconfig                 # Editor configuration for consistent coding styles
├── .github/                      # GitHub workflows for CI/CD automation
│   ├── ISSUE_TEMPLATE/           # Templates for GitHub issues
│   ├── workflows/                # CI/CD pipelines (build, release, etc.)
│   ├── dependabot.yml            # Automatic dependency updates
│   └── pull_request_template.md  # Template for pull requests
├── .gitignore                    # Files and directories to ignore in Git
├── .pre-commit-config.yaml       # Pre-commit hooks configuration
├── .vscode/extensions.json       # Recommended extensions for VSCode users
├── CODEOWNERS                    # File to manage repository code owners
├── Dockerfile                    # Dockerfile to build the image with the tools
├── LICENSE                       # License for the project
└── README.md                     # Documentation (you're reading this!)
```

### 🤝 Contributing
We welcome contributions! To get started:

- 🍴 Fork the repository.
- 🛠️ Create a new branch for your feature or bug fix.
- 📥 Submit a pull request when your changes are ready.
Please make sure to follow our coding style guidelines and ensure all tests pass.

### 📄 License
This project is licensed under the terms of the [MIT License](./LICENSE).
