FROM alpine:latest

# Set ARGs for tool versions
ARG TERRAFORM_VERSION=1.9.5
ARG TERRAGRUNT_VERSION=0.67.3
ARG CHECKOV_VERSION=3.2.249
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

# Install Checkov in a separate layer
RUN python3 -m venv /opt/venv \
    && source /opt/venv/bin/activate \
    && pip install --no-cache-dir checkov==${CHECKOV_VERSION} \
    && apk del py3-pip \
    && rm -rf /var/cache/apk/* /root/.cache

# Install Terraform
RUN ARCH=$(case "${TARGETARCH}" in \
            "amd64") echo "amd64" ;; \
            "arm64") echo "arm64" ;; \
            *) echo "unsupported architecture" ;; \
          esac) \
    && wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip -d /usr/local/bin/ \
    && rm terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip

# Install Terragrunt
RUN ARCH=$(case "${TARGETARCH}" in \
            "amd64") echo "amd64" ;; \
            "arm64") echo "arm64" ;; \
            *) echo "unsupported architecture" ;; \
          esac) \
    && wget https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_${ARCH} -O /usr/local/bin/terragrunt \
    && chmod +x /usr/local/bin/terragrunt

# Install Terraform Docs
RUN ARCH=$(case "${TARGETARCH}" in \
            "amd64") echo "amd64" ;; \
            "arm64") echo "arm64" ;; \
            *) echo "unsupported architecture" ;; \
          esac) \
    && wget https://github.com/terraform-docs/terraform-docs/releases/download/v${TFDOCS_VERSION}/terraform-docs-v${TFDOCS_VERSION}-linux-${ARCH}.tar.gz \
    && tar -xzf terraform-docs-v${TFDOCS_VERSION}-linux-${ARCH}.tar.gz \
    && mv terraform-docs /usr/local/bin/ \
    && rm terraform-docs-v${TFDOCS_VERSION}-linux-${ARCH}.tar.gz

# Install TFLint
RUN ARCH=$(case "${TARGETARCH}" in \
            "amd64") echo "amd64" ;; \
            "arm64") echo "arm64" ;; \
            *) echo "unsupported architecture" ;; \
          esac) \
    && wget https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_${ARCH}.zip \
    && unzip tflint_linux_${ARCH}.zip \
    && mv tflint /usr/local/bin/ \
    && rm tflint_linux_${ARCH}.zip

# Install TFsec
RUN ARCH=$(case "${TARGETARCH}" in \
            "amd64") echo "amd64" ;; \
            "arm64") echo "arm64" ;; \
            *) echo "unsupported architecture" ;; \
          esac) \
    && wget https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-linux-${ARCH} \
    && mv tfsec-linux-${ARCH} /usr/local/bin/tfsec \
    && chmod +x /usr/local/bin/tfsec

# Install Trivy
RUN ARCH=$(case "${TARGETARCH}" in \
            "amd64") echo "64bit" ;; \
            "arm64") echo "ARM64" ;; \
            *) echo "unsupported architecture" ;; \
          esac) \
    && wget https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-${ARCH}.tar.gz \
    && tar zxvf trivy_${TRIVY_VERSION}_Linux-${ARCH}.tar.gz \
    && mv trivy /usr/local/bin/ \
    && rm trivy_${TRIVY_VERSION}_Linux-${ARCH}.tar.gz

# Verify installations
RUN terraform --version && \
    terragrunt --version && \
    checkov --version && \
    terraform-docs --version && \
    tflint --version && \
    tfsec --version && \
    trivy --version
