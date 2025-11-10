#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default image name
IMAGE="${1:-terraform-toolkit:local}"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          Terraform Toolkit - Smoke Test Suite                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Testing image: ${IMAGE}${NC}"
echo ""

# Test counter
PASSED=0
FAILED=0

# Function to run a test
test_tool() {
    local tool_name="$1"
    local command="$2"
    local expected_pattern="$3"

    echo -n "Testing ${tool_name}... "

    if output=$(docker run --rm "${IMAGE}" bash -c "${command}" 2>&1); then
        if [[ -n "${expected_pattern}" ]] && ! echo "${output}" | grep -qi "${expected_pattern}"; then
            echo -e "${RED}✗ FAILED${NC} (unexpected output)"
            echo "  Expected pattern: ${expected_pattern}"
            echo "  Got: ${output}"
            ((FAILED++))
            return 1
        fi
        echo -e "${GREEN}✓ PASSED${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "  Error: ${output}"
        ((FAILED++))
        return 1
    fi
}

echo -e "${YELLOW}═══ Version Checks ═══${NC}"
echo ""

test_tool "Terraform" "terraform --version" "Terraform"
test_tool "Terragrunt" "terragrunt --version" "terragrunt"
test_tool "Checkov" "checkov --version" "checkov"
test_tool "terraform-docs" "terraform-docs --version" "terraform-docs"
test_tool "TFLint" "tflint --version" "TFLint"
test_tool "TFSec" "tfsec --version" "tfsec"
test_tool "Trivy" "trivy --version" "Version"
test_tool "AWS CLI" "aws --version" "aws-cli"
test_tool "eksctl" "eksctl version" "eksctl"
test_tool "pre-commit" "pre-commit --version" "pre-commit"

echo ""
echo -e "${YELLOW}═══ Basic Functionality Tests ═══${NC}"
echo ""

# Test Terraform with a simple config
echo -n "Testing Terraform init... "
if docker run --rm "${IMAGE}" bash -c '
    cd /tmp && mkdir -p test-tf && cd test-tf
    cat > main.tf <<EOF
terraform {
  required_version = ">= 1.0"
}

variable "test" {
  default = "hello"
}

output "test" {
  value = var.test
}
EOF
    terraform init -backend=false > /dev/null 2>&1
' 2>&1; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAILED${NC}"
    ((FAILED++))
fi

# Test Terragrunt
echo -n "Testing Terragrunt... "
if docker run --rm "${IMAGE}" bash -c '
    cd /tmp && mkdir -p test-tg && cd test-tg
    cat > terragrunt.hcl <<EOF
terraform {
  source = "."
}
EOF
    cat > main.tf <<EOF
terraform {
  required_version = ">= 1.0"
}
EOF
    terragrunt init -backend=false > /dev/null 2>&1
' 2>&1; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAILED${NC}"
    ((FAILED++))
fi

# Test Checkov
echo -n "Testing Checkov scan... "
if docker run --rm "${IMAGE}" bash -c '
    cd /tmp && mkdir -p test-checkov && cd test-checkov
    cat > main.tf <<EOF
resource "aws_s3_bucket" "test" {
  bucket = "test-bucket"
}
EOF
    checkov -f main.tf --quiet --compact > /dev/null 2>&1
' 2>&1; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAILED${NC}"
    ((FAILED++))
fi

# Test TFLint
echo -n "Testing TFLint... "
if docker run --rm "${IMAGE}" bash -c '
    cd /tmp && mkdir -p test-tflint && cd test-tflint
    cat > main.tf <<EOF
variable "test" {
  default = "value"
}
EOF
    tflint --init > /dev/null 2>&1 && tflint > /dev/null 2>&1
' 2>&1; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAILED${NC}"
    ((FAILED++))
fi

# Test TFSec
echo -n "Testing TFSec scan... "
if docker run --rm "${IMAGE}" bash -c '
    cd /tmp && mkdir -p test-tfsec && cd test-tfsec
    cat > main.tf <<EOF
resource "aws_instance" "test" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
}
EOF
    tfsec . > /dev/null 2>&1
' 2>&1; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAILED${NC}"
    ((FAILED++))
fi

# Test terraform-docs
echo -n "Testing terraform-docs... "
if docker run --rm "${IMAGE}" bash -c '
    cd /tmp && mkdir -p test-tfdocs && cd test-tfdocs
    cat > main.tf <<EOF
variable "test" {
  description = "Test variable"
  type        = string
  default     = "value"
}
EOF
    terraform-docs markdown . > /dev/null 2>&1
' 2>&1; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAILED${NC}"
    ((FAILED++))
fi

echo ""
echo -e "${YELLOW}═══ Environment Tests ═══${NC}"
echo ""

# Test user permissions
test_tool "Non-root user" "id -u" "1000"
test_tool "User home directory" "test -d /home/tf-user && echo 'exists'" "exists"
test_tool "Working directory writable" "touch /tmp/test && rm /tmp/test && echo 'writable'" "writable"

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                         Test Summary                           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${GREEN}Passed: ${PASSED}${NC}"
echo -e "  ${RED}Failed: ${FAILED}${NC}"
echo -e "  Total:  $((PASSED + FAILED))"
echo ""

if [ ${FAILED} -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed!${NC}"
    exit 1
fi
