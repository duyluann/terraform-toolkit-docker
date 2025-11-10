#!/bin/bash
set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default values
IMAGE_NAME="${IMAGE_NAME:-terraform-toolkit}"
IMAGE_TAG="${IMAGE_TAG:-local}"
PLATFORM="${PLATFORM:-$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')}"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          Terraform Toolkit - Local Build Script               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "📦 Image: ${GREEN}${IMAGE_NAME}:${IMAGE_TAG}${NC}"
echo -e "🖥️  Platform: ${GREEN}linux/${PLATFORM}${NC}"
echo ""

# Check if buildx is available
if ! docker buildx version > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Docker Buildx not found. Using standard docker build...${NC}"
    BUILD_CMD="docker build"
    PLATFORM_FLAG="--platform linux/${PLATFORM}"
else
    BUILD_CMD="docker buildx build"
    PLATFORM_FLAG="--platform linux/${PLATFORM}"
fi

# Show build context
echo -e "${YELLOW}🔍 Build context:${NC}"
echo "  Working directory: $(pwd)"
echo "  Dockerfile: $(pwd)/Dockerfile"
echo ""

# Build the image
echo -e "${BLUE}🔨 Building image...${NC}"
START_TIME=$(date +%s)

${BUILD_CMD} \
    ${PLATFORM_FLAG} \
    -t "${IMAGE_NAME}:${IMAGE_TAG}" \
    --load \
    .

END_TIME=$(date +%s)
BUILD_DURATION=$((END_TIME - START_TIME))

echo ""
echo -e "${GREEN}✅ Build completed in ${BUILD_DURATION}s${NC}"
echo ""

# Show image info
echo -e "${BLUE}📊 Image details:${NC}"
docker images "${IMAGE_NAME}:${IMAGE_TAG}" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
echo ""

# Verify tools
echo -e "${BLUE}🔧 Verifying tools...${NC}"
if docker run --rm "${IMAGE_NAME}:${IMAGE_TAG}" bash -c 'terraform --version && terragrunt --version' > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Core tools verified${NC}"
else
    echo -e "${YELLOW}⚠️  Warning: Could not verify tools${NC}"
fi
echo ""

echo -e "${GREEN}🎉 Build successful!${NC}"
echo ""
echo -e "Next steps:"
echo -e "  ${YELLOW}make test${NC}       - Run smoke tests"
echo -e "  ${YELLOW}make shell${NC}      - Launch interactive shell"
echo -e "  ${YELLOW}make scan${NC}       - Run security scan"
