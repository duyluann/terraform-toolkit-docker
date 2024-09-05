# Use Ubuntu base image instead of Alpine for better WSL2 compatibility
FROM ubuntu:latest

# Set ARGs for tool versions
ARG TERRAFORM_VERSION=1.5.0
ARG TERRAGRUNT_VERSION=0.67.2
ARG CHECKOV_VERSION=3.2.245
ARG TFDOCS_VERSION=0.18.0
ARG TFLINT_VERSION=0.53.0
ARG TFSEC_VERSION=1.28.10

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    git \
    jq \
    unzip \
    python3 \
    python3-pip \
    python3-venv \
    build-essential \
    libffi-dev \
    openssl \
    && apt-get clean

# Create a Python virtual environment and upgrade pip
RUN python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install --upgrade pip
ENV PATH="/opt/venv/bin:$PATH"

# Install Terraform
RUN curl -LO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && chmod +x terraform \
    && mv terraform /usr/local/bin/ \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Install Terragrunt
RUN curl -LO https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 \
    && chmod +x terragrunt_linux_amd64 \
    && mv terragrunt_linux_amd64 /usr/local/bin/terragrunt

# Install Checkov using pip in the virtual environment
RUN pip install --no-cache-dir checkov==${CHECKOV_VERSION}

# Install Terraform Docs
RUN curl -LO https://github.com/terraform-docs/terraform-docs/releases/download/v${TFDOCS_VERSION}/terraform-docs-v${TFDOCS_VERSION}-linux-amd64.tar.gz \
    && tar -xvzf terraform-docs-v${TFDOCS_VERSION}-linux-amd64.tar.gz \
    && chmod +x terraform-docs \
    && mv terraform-docs /usr/local/bin/ \
    && rm terraform-docs-v${TFDOCS_VERSION}-linux-amd64.tar.gz

# Install TFLint
RUN curl -LO https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip \
    && unzip tflint_linux_amd64.zip \
    && chmod +x tflint \
    && mv tflint /usr/local/bin/ \
    && rm tflint_linux_amd64.zip

# Install TFsec
RUN curl -LO https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-linux-amd64 \
    && chmod +x tfsec-linux-amd64 \
    && mv tfsec-linux-amd64 /usr/local/bin/tfsec

# Verify installations
RUN terraform --version && \
    terragrunt --version && \
    checkov --version && \
    terraform-docs --version && \
    tflint --version && \
    tfsec --version

# Set the default entrypoint
ENTRYPOINT ["/bin/bash"]
