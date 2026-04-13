#!/bin/bash
# install.sh - Bootstrap installer for my-ai-tools
# Usage: curl -fsSL https://raw.githubusercontent.com/dinesh-nimmagadda3/my-ai-tools/main/install.sh | bash

set -e

REPO_URL="https://github.com/dinesh-nimmagadda3/my-ai-tools.git"
TEMP_DIR=$(mktemp -d -t my-ai-tools-install-XXXXXXXXXX)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}==>${NC} Bootstrapping my-ai-tools setup ecosystem..."

if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git is strictly required for this installation.${NC}" >&2
    exit 1
fi

# Ensure complete cleanup on exit (even if user uses Ctrl+C)
trap 'echo -e "${BLUE}==>${NC} Removing temporary installation files..."; rm -rf "$TEMP_DIR"' EXIT

echo -e "${BLUE}==>${NC} Downloading latest framework..."
if git clone --quiet --depth 1 "$REPO_URL" "$TEMP_DIR"; then
    echo -e "${GREEN}==>${NC} Framework downloaded successfully to $TEMP_DIR"
else
    echo -e "${RED}Error: Failed to clone repository.${NC}" >&2
    exit 1
fi

echo -e "${BLUE}==>${NC} Starting Interactive Setup Engine..."
cd "$TEMP_DIR"

# Ensure the executable bits are intact on the cloned files
chmod +x cli.sh
./cli.sh "$@"

echo -e "${GREEN}==>${NC} Configuration Wizard finished."
