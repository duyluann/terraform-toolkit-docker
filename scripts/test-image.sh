#!/bin/bash
set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

IMAGE="${1:-terraform-toolkit:local}"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        Terraform Toolkit - Quick Image Validation             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Testing: ${GREEN}${IMAGE}${NC}"
echo ""

# Check if image exists
if ! docker image inspect "${IMAGE}" > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Image '${IMAGE}' not found${NC}"
    echo "Run 'make build' first to create the image"
    exit 1
fi

echo -e "${YELLOW}1. Checking image size...${NC}"
SIZE=$(docker images "${IMAGE}" --format "{{.Size}}")
echo -e "   Size: ${GREEN}${SIZE}${NC}"
echo ""

echo -e "${YELLOW}2. Testing basic functionality...${NC}"
TESTS=0
PASSED=0

# Test Terraform
echo -n "   Terraform... "
if docker run --rm "${IMAGE}" terraform --version > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗${NC}"
fi
((TESTS++))

# Test Terragrunt
echo -n "   Terragrunt... "
if docker run --rm "${IMAGE}" terragrunt --version > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗${NC}"
fi
((TESTS++))

# Test Checkov
echo -n "   Checkov... "
if docker run --rm "${IMAGE}" checkov --version > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗${NC}"
fi
((TESTS++))

# Test AWS CLI
echo -n "   AWS CLI... "
if docker run --rm "${IMAGE}" aws --version > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗${NC}"
fi
((TESTS++))

echo ""
echo -e "${YELLOW}3. Testing user permissions...${NC}"
echo -n "   Non-root user... "
if [ "$(docker run --rm "${IMAGE}" id -u)" == "1000" ]; then
    echo -e "${GREEN}✓${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗${NC}"
fi
((TESTS++))

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "Results: ${GREEN}${PASSED}${NC}/${TESTS} tests passed"

if [ ${PASSED} -eq ${TESTS} ]; then
    echo -e "${GREEN}✅ Image validation successful!${NC}"
    echo ""
    echo "Ready to push or use in production"
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    echo ""
    echo "Run 'make test' for detailed test results"
    exit 1
fi
