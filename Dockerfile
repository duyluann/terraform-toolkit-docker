# syntax=docker/dockerfile:1.7

############################
# Builder: download/install everything
############################
FROM debian:bookworm-slim AS builder

ARG DEBIAN_FRONTEND=noninteractive

# Tool versions
ARG TERRAFORM_VERSION=1.13.4
ARG TERRAGRUNT_VERSION=0.93.0
ARG CHECKOV_VERSION=3.2.489
ARG TFDOCS_VERSION=0.20.0
ARG TFLINT_VERSION=0.59.1
ARG TFSEC_VERSION=1.28.14
ARG TRIVY_VERSION=0.67.2
ARG EKSCTL_VERSION=0.216.0
ARG PRE_COMMIT_VERSION=4.3.0

ARG TARGETARCH
SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl unzip tar xz-utils python3 python3-pip git \
 && rm -rf /var/lib/apt/lists/*

# Arch map
RUN RAW="${TARGETARCH:-$(uname -m)}"; \
    case "$RAW" in \
      amd64|x86_64)  ARCH=amd64;  TIVY=64bit;  AWSA=x86_64 ;; \
      arm64|aarch64) ARCH=arm64;  TIVY=ARM64;  AWSA=aarch64 ;; \
      *) echo "Unsupported arch $RAW"; exit 1 ;; \
    esac; \
    echo "ARCH=$ARCH TIVY=$TIVY AWSA=$AWSA" > /arch.env
ENV $(cat /arch.env | xargs)

# Install Go-based CLIs into /opt/bin
RUN mkdir -p /opt/bin
# Terraform
RUN curl -fsSL -o /tmp/terraform.zip \
      "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip" \
 && unzip -q /tmp/terraform.zip -d /opt/bin \
 && rm -f /tmp/terraform.zip
# Terragrunt
RUN curl -fsSL -o /opt/bin/terragrunt \
      "https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_${ARCH}" \
 && chmod +x /opt/bin/terragrunt
# terraform-docs
RUN curl -fsSL -o /tmp/terraform-docs.tgz \
      "https://github.com/terraform-docs/terraform-docs/releases/download/v${TFDOCS_VERSION}/terraform-docs-v${TFDOCS_VERSION}-linux-${ARCH}.tar.gz" \
 && tar -xzf /tmp/terraform-docs.tgz -C /opt/bin terraform-docs \
 && rm -f /tmp/terraform-docs.tgz
# TFLint
RUN curl -fsSL -o /tmp/tflint.zip \
      "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_${ARCH}.zip" \
 && unzip -q /tmp/tflint.zip -d /opt/bin \
 && rm -f /tmp/tflint.zip
# TFsec
RUN curl -fsSL -o /opt/bin/tfsec \
      "https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-linux-${ARCH}" \
 && chmod +x /opt/bin/tfsec
# Trivy
RUN curl -fsSL -o /tmp/trivy.tgz \
      "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-${TIVY}.tar.gz" \
 && tar -xzf /tmp/trivy.tgz -C /opt/bin trivy \
 && rm -f /tmp/trivy.tgz

# AWS CLI v2
RUN curl -fsSL -o /tmp/awscliv2.zip \
      "https://awscli.amazonaws.com/awscli-exe-linux-${AWSA}.zip" \
 && unzip -q /tmp/awscliv2.zip -d /tmp \
 && /tmp/aws/install -i /opt/aws-cli -b /opt/bin \
 && rm -rf /tmp/aws /tmp/awscliv2.zip \
 && rm -rf /opt/aws-cli/v2/*/dist/awscli/examples || true

# eksctl
RUN curl -fsSL -o /tmp/eksctl.tgz \
      "https://github.com/eksctl-io/eksctl/releases/download/v${EKSCTL_VERSION}/eksctl_Linux_${ARCH}.tar.gz" \
 && tar -xzf /tmp/eksctl.tgz -C /opt/bin eksctl \
 && rm -f /tmp/eksctl.tgz

# Python tools (builder only; copy site-packages later)
RUN python3 -m pip install --no-cache-dir \
      "checkov==${CHECKOV_VERSION}" \
      "pre-commit==${PRE_COMMIT_VERSION}"

# Optional: strip Go binaries where possible (won't harm if already stripped)
RUN set -e; for b in /opt/bin/*; do command -v strip >/dev/null 2>&1 && strip --strip-unneeded "$b" || true; done

############################
# Runtime: tiny base with just what you need
############################
FROM debian:bookworm-slim AS runtime

ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=tf-user
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

# Only the bare runtime deps (no pip, no build tools)
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      python3 \
      git \
 && rm -rf /var/lib/apt/lists/*

# Non-root user (no sudo to keep it lean)
RUN groupadd --gid "${USER_GID}" "${USERNAME}" \
 && useradd  --uid "${USER_UID}" --gid "${USER_GID}" -m "${USERNAME}"

# Copy binaries & AWS CLI from builder
COPY --from=builder /opt/bin/ /usr/local/bin/
COPY --from=builder /opt/aws-cli/ /opt/aws-cli/
RUN ln -sf /opt/aws-cli/v2/current/bin/aws /usr/local/bin/aws

# Copy Python site-packages from builder so we don't keep pip in runtime
# (Detect Python's minor version from runtime and copy matching path)
RUN PYMAJOR=$(python3 -c "import sys;print(f'{sys.version_info.major}.{sys.version_info.minor}')"); \
    mkdir -p "/usr/local/lib/python${PYMAJOR}/dist-packages"
COPY --from=builder /usr/local/lib/python*/dist-packages/ /usr/local/lib/python*/dist-packages/

USER ${USERNAME}
WORKDIR /home/${USERNAME}

# (Optional) quick self-check without bloating layers:
# docker run --rm image terraform --version
