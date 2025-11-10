.PHONY: help build build-amd64 build-arm64 test shell scan clean clean-all compare-sizes

# Default target
.DEFAULT_GOAL := help

# Variables
IMAGE_NAME ?= terraform-toolkit
IMAGE_TAG ?= local
PLATFORM ?= $(shell uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
DOCKER_BUILDX ?= docker buildx build

help: ## Show this help message
	@echo "╔════════════════════════════════════════════════════════════════╗"
	@echo "║        Terraform Toolkit - Local Development Toolkit          ║"
	@echo "╚════════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Variables:"
	@echo "  IMAGE_NAME    Current: $(IMAGE_NAME)"
	@echo "  IMAGE_TAG     Current: $(IMAGE_TAG)"
	@echo "  PLATFORM      Current: $(PLATFORM)"
	@echo ""

build: ## Build Docker image for current platform
	@echo "🔨 Building $(IMAGE_NAME):$(IMAGE_TAG) for $(PLATFORM)..."
	@$(DOCKER_BUILDX) \
		--platform linux/$(PLATFORM) \
		-t $(IMAGE_NAME):$(IMAGE_TAG) \
		--load \
		.
	@echo "✅ Build complete: $(IMAGE_NAME):$(IMAGE_TAG)"

build-amd64: ## Build Docker image for amd64
	@$(MAKE) build PLATFORM=amd64 IMAGE_TAG=amd64

build-arm64: ## Build Docker image for arm64
	@$(MAKE) build PLATFORM=arm64 IMAGE_TAG=arm64

build-all: build-amd64 build-arm64 ## Build Docker images for all platforms

test: ## Run smoke tests on all tools
	@echo "🧪 Running tests on $(IMAGE_NAME):$(IMAGE_TAG)..."
	@bash scripts/test-tools.sh $(IMAGE_NAME):$(IMAGE_TAG)

shell: ## Launch interactive shell in container
	@echo "🐚 Starting interactive shell in $(IMAGE_NAME):$(IMAGE_TAG)..."
	@docker run --rm -it \
		-v $(PWD):/workspace \
		-w /workspace \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		/bin/bash

scan: ## Run security scan with Trivy
	@echo "🔍 Running Trivy security scan on $(IMAGE_NAME):$(IMAGE_TAG)..."
	@docker run --rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		aquasec/trivy:latest image \
		--severity HIGH,CRITICAL \
		--exit-code 0 \
		$(IMAGE_NAME):$(IMAGE_TAG)

compare-sizes: ## Compare image sizes
	@echo "📊 Comparing image sizes..."
	@bash scripts/compare-sizes.sh

clean: ## Remove local test images
	@echo "🧹 Cleaning up local images..."
	@docker rmi $(IMAGE_NAME):$(IMAGE_TAG) 2>/dev/null || true
	@docker rmi $(IMAGE_NAME):amd64 2>/dev/null || true
	@docker rmi $(IMAGE_NAME):arm64 2>/dev/null || true
	@echo "✅ Cleanup complete"

clean-all: clean ## Remove all terraform-toolkit images and containers
	@echo "🧹 Deep cleaning all terraform-toolkit resources..."
	@docker ps -a --filter "ancestor=$(IMAGE_NAME)" -q | xargs -r docker rm -f
	@docker images "$(IMAGE_NAME)*" -q | xargs -r docker rmi -f
	@echo "✅ Deep cleanup complete"

quick-test: build test ## Quick build and test cycle
	@echo "✅ Quick test cycle complete!"

ci-test: ## Run CI-like tests locally
	@echo "🚀 Running CI-like tests..."
	@$(MAKE) build
	@$(MAKE) test
	@$(MAKE) scan
	@echo "✅ All CI tests passed!"

size: ## Show image size
	@docker images $(IMAGE_NAME):$(IMAGE_TAG) --format "{{.Repository}}:{{.Tag}} - {{.Size}}"

version: ## Show tool versions in image
	@echo "📦 Tool versions in $(IMAGE_NAME):$(IMAGE_TAG):"
	@docker run --rm $(IMAGE_NAME):$(IMAGE_TAG) bash -c '\
		echo "Terraform:     $$(terraform --version | head -1)"; \
		echo "Terragrunt:    $$(terragrunt --version)"; \
		echo "Checkov:       $$(checkov --version)"; \
		echo "terraform-docs:$$(terraform-docs --version)"; \
		echo "TFLint:        $$(tflint --version)"; \
		echo "TFSec:         $$(tfsec --version)"; \
		echo "Trivy:         $$(trivy --version | head -1)"; \
		echo "AWS CLI:       $$(aws --version)"; \
		echo "eksctl:        $$(eksctl version)"; \
		echo "pre-commit:    $$(pre-commit --version)"; \
	'
