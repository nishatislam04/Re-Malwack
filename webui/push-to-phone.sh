#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PHONE_IP="192.168.1.107"  # Change this to your phone's IP
PHONE_PORT="5555"
MODULE_PATH="/storage/emulated/0/Re-malwack-source"  # Internal storage path
WEBROOT_PATH="$MODULE_PATH/webroot"

# Function to connect to phone
connect_adb() {
    echo -e "${YELLOW}Connecting to phone at $PHONE_IP:$PHONE_PORT...${NC}"
    adb connect $PHONE_IP:$PHONE_PORT

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Connected successfully${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to connect. Make sure WiFi ADB is enabled on phone.${NC}"
        return 1
    fi
}

# Function to check if already connected
check_connection() {
    if adb devices | grep -q "$PHONE_IP:$PHONE_PORT.*device"; then
        return 0
    else
        return 1
    fi
}

# Function to build the project
build_project() {
    echo -e "${YELLOW}Building project with pnpm...${NC}"
    pnpm run build

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Build successful${NC}"
        return 0
    else
        echo -e "${RED}✗ Build failed${NC}"
        return 1
    fi
}

# Function to deploy to phone
deploy_to_phone() {
    echo -e "${YELLOW}Deploying to phone...${NC}"

    # Create directories on phone
    adb shell "mkdir -p $WEBROOT_PATH"

    # Push all files from build output
    echo -e "${YELLOW}Pushing files to $WEBROOT_PATH...${NC}"
    adb push ../module/webroot/* $WEBROOT_PATH/

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Files deployed successfully${NC}"

        # Set proper permissions (if needed)
        adb shell "su -c 'chmod -R 755 $MODULE_PATH'"

        # Show deployed files
        echo -e "${GREEN}Deployed files:${NC}"
        adb shell "ls -la $WEBROOT_PATH/"

        return 0
    else
        echo -e "${RED}✗ Deployment failed${NC}"
        return 1
    fi
}

# Main execution
main() {
    echo -e "${GREEN}=== KSU Module Deployment ===${NC}"

    # Check if already connected
    if ! check_connection; then
        if ! connect_adb; then
            exit 1
        fi
    else
        echo -e "${GREEN}✓ Already connected to phone${NC}"
    fi

    # Build the project
    if ! build_project; then
        exit 1
    fi

    # Deploy to phone
    if ! deploy_to_phone; then
        exit 1
    fi

    echo -e "${GREEN}=== Deployment Complete ===${NC}"
}

# Run main function
main
