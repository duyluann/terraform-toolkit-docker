FROM public.ecr.aws/ubuntu/ubuntu:22.04

# Set ARGs for tool versions
ARG TERRAFORM_VERSION=1.9.5
ARG TERRAGRUNT_VERSION=0.67.2
ARG CHECKOV_VERSION=3.2.245
ARG TFDOCS_VERSION=0.18.0
ARG TFLINT_VERSION=0.53.0
ARG TFSEC_VERSION=1.28.10

USER root

# Install necessary dependencies
RUN apt-get update -y && \
    apt-get install -y \
    unzip \
    wget \
    vim \
    git \
    curl \
    jq \
    python3 \
    python3-pip && \
    python3 -m pip install --upgrade pip

# Install Terraform
RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin/

# Install Terragrunt
RUN wget https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 -O /usr/local/bin/terragrunt \
    && chmod +x /usr/local/bin/terragrunt

# Install Checkov using pip in the virtual environment
RUN pip3 install --no-cache-dir checkov==${CHECKOV_VERSION}

# Install Terraform Docs
RUN curl -LO https://github.com/terraform-docs/terraform-docs/releases/download/v${TFDOCS_VERSION}/terraform-docs-v${TFDOCS_VERSION}-linux-amd64.tar.gz \
    && tar -xvzf terraform-docs-v${TFDOCS_VERSION}-linux-amd64.tar.gz \
    && chmod u+x terraform-docs \
    && mv terraform-docs /usr/local/bin/ \
    && rm terraform-docs-v${TFDOCS_VERSION}-linux-amd64.tar.gz

# Install TFLint
RUN curl -LO https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip \
    && unzip tflint_linux_amd64.zip \
    && chmod u+x tflint \
    && mv tflint /usr/local/bin/ \
    && rm tflint_linux_amd64.zip

# Install TFsec
RUN curl -LO https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-linux-amd64 \
    && chmod u+x tfsec-linux-amd64 \
    && mv tfsec-linux-amd64 /usr/local/bin/tfsec

# Verify installations
RUN terraform --version && \
    terragrunt --version && \
    /opt/venv/bin/checkov --version && \
    terraform-docs --version && \
    tflint --version && \
    tfsec --version

# Set the default entrypoint
ENTRYPOINT ["/bin/bash"]
