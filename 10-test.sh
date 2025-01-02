#!/bin/bash

# ANSI color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 01. Setup and Preparation
echo -e "${YELLOW}01. Copy environment variables locally to Github environments${NC}"

# Read the variables from the .env file
set -a # Enable export of all variables
source .env # Source the .env file
set +a # Disable export of all variables

if [ -f ".env" ]; then
    if [ -z "$GITHUB_USERNAME" ]; then
        echo -e "${RED}Failed to read the first variable,GITHUB_USERNAME, from .env.${NC}"
        exit 1
    else
        echo -e "${GREEN}Successfully read the first variable GITHUB_USERNAME=${GITHUB_USERNAME}, from .env file${NC}"
    fi
else
    echo -e "${RED}.env file does not exist.${NC}"
    exit 1
fi
