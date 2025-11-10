#!/bin/bash

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      Terraform Toolkit - Image Size Comparison                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to convert size to bytes for comparison
size_to_bytes() {
    local size=$1
    local num=$(echo $size | sed 's/[^0-9.]//g')
    local unit=$(echo $size | sed 's/[0-9.]//g')

    case $unit in
        GB) echo "$(echo "$num * 1073741824" | bc | cut -d. -f1)" ;;
        MB) echo "$(echo "$num * 1048576" | bc | cut -d. -f1)" ;;
        KB) echo "$(echo "$num * 1024" | bc | cut -d. -f1)" ;;
        B|*) echo "${num%.*}" ;;
    esac
}

# Get all terraform-toolkit images
echo -e "${YELLOW}Searching for terraform-toolkit images...${NC}"
echo ""

IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "terraform-toolkit|duyluann/terraform-toolkit" | grep -v "<none>")

if [ -z "$IMAGES" ]; then
    echo -e "${RED}No terraform-toolkit images found${NC}"
    echo "Run 'make build' to create an image"
    exit 1
fi

# Display images in a table
printf "%-50s %-15s %-20s\n" "IMAGE" "SIZE" "CREATED"
echo "─────────────────────────────────────────────────────────────────────────────────────"

while IFS= read -r image; do
    size=$(docker images "${image}" --format "{{.Size}}")
    created=$(docker images "${image}" --format "{{.CreatedSince}}")
    printf "%-50s %-15s %-20s\n" "${image}" "${size}" "${created}"
done <<< "$IMAGES"

echo ""

# Compare with baseline if exists
BASELINE="duyluann/terraform-toolkit:latest"
LOCAL="terraform-toolkit:local"

if docker image inspect "${BASELINE}" > /dev/null 2>&1 && docker image inspect "${LOCAL}" > /dev/null 2>&1; then
    echo -e "${BLUE}═══ Comparison with baseline ═══${NC}"
    echo ""

    BASELINE_SIZE=$(docker images "${BASELINE}" --format "{{.Size}}")
    LOCAL_SIZE=$(docker images "${LOCAL}" --format "{{.Size}}")

    BASELINE_BYTES=$(size_to_bytes "$BASELINE_SIZE")
    LOCAL_BYTES=$(size_to_bytes "$LOCAL_SIZE")

    if [ "$BASELINE_BYTES" -gt 0 ]; then
        DIFF_BYTES=$((LOCAL_BYTES - BASELINE_BYTES))
        DIFF_PERCENT=$(echo "scale=2; ($DIFF_BYTES * 100) / $BASELINE_BYTES" | bc)

        echo "  Baseline (${BASELINE}): ${BASELINE_SIZE}"
        echo "  Local (${LOCAL}):       ${LOCAL_SIZE}"
        echo ""

        if [ "$DIFF_BYTES" -lt 0 ]; then
            ABS_DIFF=${DIFF_BYTES#-}
            ABS_PERCENT=${DIFF_PERCENT#-}
            HUMAN_DIFF=$(numfmt --to=iec-i --suffix=B $ABS_DIFF 2>/dev/null || echo "${ABS_DIFF}B")
            echo -e "  ${GREEN}✓ Smaller by ${HUMAN_DIFF} (${ABS_PERCENT}% reduction)${NC}"
        elif [ "$DIFF_BYTES" -gt 0 ]; then
            HUMAN_DIFF=$(numfmt --to=iec-i --suffix=B $DIFF_BYTES 2>/dev/null || echo "${DIFF_BYTES}B")
            echo -e "  ${RED}⚠ Larger by ${HUMAN_DIFF} (+${DIFF_PERCENT}% increase)${NC}"
        else
            echo -e "  ${YELLOW}= Same size${NC}"
        fi
    fi
    echo ""
fi

# Show layer count
echo -e "${BLUE}═══ Layer Information ═══${NC}"
echo ""

for image in $IMAGES; do
    if [ -n "$image" ]; then
        LAYERS=$(docker history "${image}" --no-trunc 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
        echo "  ${image}: ${LAYERS} layers"
    fi
done

echo ""
echo -e "${YELLOW}💡 Tip: Use 'docker history <image>' to see detailed layer breakdown${NC}"
