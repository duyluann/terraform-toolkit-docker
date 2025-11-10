FROM ubuntu:22.04

# Set ARGs for tool versions
ARG TERRAFORM_VERSION=1.13.5
ARG TERRAGRUNT_VERSION=0.93.3
ARG CHECKOV_VERSION=3.2.491
ARG TFDOCS_VERSION=0.20.0
ARG TFLINT_VERSION=0.59.1
ARG TFSEC_VERSION=1.28.14
ARG TRIVY_VERSION=0.67.2
ARG EKSCTL_VERSION=0.216.0
ARG PRE_COMMIT_VERSION=4.4.0

# Add a non-root user
ARG USERNAME=tf-user
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Install dependencies and create user in single layer
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    git \
    unzip \
    wget \
    curl \
    python3 \
    python3-pip \
    ca-certificates && \
    groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -m $USERNAME && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install all tools in combined layers to reduce image size
RUN case $(uname -m) in \
      x86_64) ARCH=amd64 ;; \
      aarch64) ARCH=arm64 ;; \
      *) echo "unsupported architecture"; exit 1 ;; \
    esac && \
    # Install Terraform
    wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip && \
    unzip -q terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip -d /usr/local/bin/ && \
    rm terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip && \
    # Install Terragrunt
    wget -q https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_${ARCH} -O /usr/local/bin/terragrunt && \
    chmod +x /usr/local/bin/terragrunt && \
    # Install Terraform Docs
    wget -q https://github.com/terraform-docs/terraform-docs/releases/download/v${TFDOCS_VERSION}/terraform-docs-v${TFDOCS_VERSION}-linux-${ARCH}.tar.gz && \
    tar -xzf terraform-docs-v${TFDOCS_VERSION}-linux-${ARCH}.tar.gz -C /usr/local/bin terraform-docs && \
    rm terraform-docs-v${TFDOCS_VERSION}-linux-${ARCH}.tar.gz && \
    # Install TFLint
    wget -q https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_${ARCH}.zip && \
    unzip -q tflint_linux_${ARCH}.zip -d /usr/local/bin/ && \
    rm tflint_linux_${ARCH}.zip && \
    # Install TFsec
    wget -q https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-linux-${ARCH} -O /usr/local/bin/tfsec && \
    chmod +x /usr/local/bin/tfsec

# Install Trivy (separate layer due to different ARCH naming)
RUN case $(uname -m) in \
      x86_64) ARCH=64bit ;; \
      aarch64) ARCH=ARM64 ;; \
      *) echo "unsupported architecture"; exit 1 ;; \
    esac && \
    wget -q https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-${ARCH}.tar.gz && \
    tar -xzf trivy_${TRIVY_VERSION}_Linux-${ARCH}.tar.gz -C /usr/local/bin trivy && \
    rm trivy_${TRIVY_VERSION}_Linux-${ARCH}.tar.gz

# Install Python packages and AWS CLI
RUN case $(uname -m) in \
      x86_64) ARCH=x86_64 ;; \
      aarch64) ARCH=aarch64 ;; \
      *) echo "unsupported architecture"; exit 1 ;; \
    esac && \
    # Install Python packages with no cache
    pip3 install --no-cache-dir checkov==${CHECKOV_VERSION} pre-commit==${PRE_COMMIT_VERSION} && \
    # Install AWS CLI
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}.zip" -o "awscliv2.zip" && \
    unzip -q awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws

# Install eksctl
RUN case $(uname -m) in \
      x86_64) ARCH=amd64 ;; \
      aarch64) ARCH=arm64 ;; \
      *) echo "unsupported architecture"; exit 1 ;; \
    esac && \
    PLATFORM=Linux_$ARCH && \
    curl -sL "https://github.com/eksctl-io/eksctl/releases/download/v${EKSCTL_VERSION}/eksctl_${PLATFORM}.tar.gz" | \
    tar -xz -C /usr/local/bin

# Switch to non-root user
USER $USERNAME

# Verify installations
RUN terraform --version && \
    terragrunt --version && \
    checkov --version && \
    terraform-docs --version && \
    tflint --version && \
    tfsec --version && \
    trivy --version && \
    aws --version && \
    eksctl version && \
    pre-commit --version

# Set default user working directory
WORKDIR /home/$USERNAME
