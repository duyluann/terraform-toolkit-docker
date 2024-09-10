FROM ubuntu:22.04

# Set ARGs for tool versions
ARG TERRAFORM_VERSION=1.9.5
ARG TERRAGRUNT_VERSION=0.67.3
ARG CHECKOV_VERSION=3.2.249
ARG TFDOCS_VERSION=0.18.0
ARG TFLINT_VERSION=0.53.0
ARG TFSEC_VERSION=1.28.10
ARG TRIVY_VERSION=0.55.0

# Install necessary dependencies
RUN apt-get update -y && \
    apt-get install -y \
    python3 \
    python3-pip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Terraform (based on the architecture)
RUN case $(uname -m) in \
      x86_64) ARCH=amd64 ;; \
      aarch64) ARCH=arm64 ;; \
      *) echo "unsupported architecture"; exit 1 ;; \
    esac && \
    wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip -d /usr/local/bin/ \
    && rm terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip

# Install Terragrunt (based on the architecture)
RUN case $(uname -m) in \
      x86_64) ARCH=amd64 ;; \
      aarch64) ARCH=arm64 ;; \
      *) echo "unsupported architecture"; exit 1 ;; \
    esac && \
    wget https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_${ARCH} -O /usr/local/bin/terragrunt \
    && chmod +x /usr/local/bin/terragrunt

# Install Terraform Docs (based on the architecture)
RUN case $(uname -m) in \
      x86_64) ARCH=amd64 ;; \
      aarch64) ARCH=arm64 ;; \
      *) echo "unsupported architecture"; exit 1 ;; \
    esac && \
    wget https://github.com/terraform-docs/terraform-docs/releases/download/v${TFDOCS_VERSION}/terraform-docs-v${TFDOCS_VERSION}-linux-${ARCH}.tar.gz \
    && tar -xzf terraform-docs-v${TFDOCS_VERSION}-linux-${ARCH}.tar.gz \
    && mv terraform-docs /usr/local/bin/ \
    && rm terraform-docs-v${TFDOCS_VERSION}-linux-${ARCH}.tar.gz

# Install TFLint (based on the architecture)
RUN case $(uname -m) in \
      x86_64) ARCH=amd64 ;; \
      aarch64) ARCH=arm64 ;; \
      *) echo "unsupported architecture"; exit 1 ;; \
    esac && \
    wget https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_${ARCH}.zip \
    && unzip tflint_linux_${ARCH}.zip \
    && mv tflint /usr/local/bin/ \
    && rm tflint_linux_${ARCH}.zip

# Install TFsec (based on the architecture)
RUN case $(uname -m) in \
      x86_64) ARCH=amd64 ;; \
      aarch64) ARCH=arm64 ;; \
      *) echo "unsupported architecture"; exit 1 ;; \
    esac && \
    wget https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-linux-${ARCH} \
    && mv tfsec-linux-${ARCH} /usr/local/bin/tfsec \
    && chmod +x /usr/local/bin/tfsec

# Install Trivy (based on the architecture)
RUN case $(uname -m) in \
      x86_64) ARCH=64bit ;; \
      aarch64) ARCH=ARM64 ;; \
      *) echo "unsupported architecture"; exit 1 ;; \
    esac && \
    wget https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-${ARCH}.tar.gz \
    && tar zxvf trivy_${TRIVY_VERSION}_Linux-${ARCH}.tar.gz \
    && mv trivy /usr/local/bin/ \
    && rm trivy_${TRIVY_VERSION}_Linux-${ARCH}.tar.gz

# Install Checkov
RUN pip3 install checkov==${CHECKOV_VERSION} && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Verify installations
RUN terraform --version && \
    terragrunt --version && \
    checkov --version && \
    terraform-docs --version && \
    tflint --version && \
    tfsec --version && \
    trivy --version
