FROM alpine:latest

# Set ARGs for tool versions
ARG TERRAFORM_VERSION=1.9.5
ARG TERRAGRUNT_VERSION=0.67.3
ARG CHECKOV_VERSION=3.2.246
ARG TFDOCS_VERSION=0.18.0
ARG TFLINT_VERSION=0.53.0
ARG TFSEC_VERSION=1.28.10
ARG TRIVY_VERSION=0.55.0

# Install necessary dependencies
RUN apk add --no-cache \
    bash \
    curl \
    wget \
    unzip \
    git \
    jq \
    python3 \
    py3-pip \
    vim

# Set PATH to use the virtual environment
ENV PATH="/opt/venv/bin:$PATH"

# Install Checkov in its own layer
RUN python3 -m venv /opt/venv \
    && source /opt/venv/bin/activate \
    && pip install --no-cache-dir checkov==${CHECKOV_VERSION} \
    && apk del py3-pip \
    && rm -rf /var/cache/apk/* /root/.cache

# Install Terraform
RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip -d /usr/local/bin/ \
    && rm terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip

# Install Terragrunt
RUN wget https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_${TARGETARCH} -O /usr/local/bin/terragrunt \
    && chmod +x /usr/local/bin/terragrunt

# Install Terraform Docs
RUN wget https://github.com/terraform-docs/terraform-docs/releases/download/v${TFDOCS_VERSION}/terraform-docs-v${TFDOCS_VERSION}-linux-${TARGETARCH}.tar.gz \
    && tar -xzf terraform-docs-v${TFDOCS_VERSION}-linux-${TARGETARCH}.tar.gz \
    && mv terraform-docs /usr/local/bin/ \
    && rm terraform-docs-v${TFDOCS_VERSION}-linux-${TARGETARCH}.tar.gz

# Install TFLint
RUN wget https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_${TARGETARCH}.zip \
    && unzip tflint_linux_${TARGETARCH}.zip \
    && mv tflint /usr/local/bin/ \
    && rm tflint_linux_${TARGETARCH}.zip

# Install TFsec
RUN wget https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-linux-${TARGETARCH} \
    && mv tfsec-linux-${TARGETARCH} /usr/local/bin/tfsec \
    && chmod +x /usr/local/bin/tfsec

# Install Trivy
RUN wget https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-${TARGETARCH}.tar.gz \
    && tar zxvf trivy_${TRIVY_VERSION}_Linux-${TARGETARCH}.tar.gz \
    && mv trivy /usr/local/bin/ \
    && rm trivy_${TRIVY_VERSION}_Linux-${TARGETARCH}.tar.gz

# Verify installations
RUN terraform --version && \
    terragrunt --version && \
    checkov --version && \
    terraform-docs --version && \
    tflint --version && \
    tfsec --version && \
    trivy --version
