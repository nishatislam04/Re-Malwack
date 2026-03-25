#!/bin/bash

# Configuration
PHONE_IP="192.168.1.106"
PHONE_PORT="5555"
PHONE_TARGET="/sdcard/Re-Malwack/webroot/"  # Non-root location
LOCAL_SOURCE="../module/webroot"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}📱 Manual Sync to Phone${NC}"
echo -e "${BLUE}================================${NC}"

# Step 1: Build the project
echo -e "${YELLOW}🔨 Building project with Vite...${NC}"
pnpm run build

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Build failed. Aborting sync.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Build completed${NC}"

# Step 2: Check if ADB is installed
if ! command -v adb &> /dev/null; then
    echo -e "${RED}✗ ADB not found. Please install android-tools: sudo pacman -S android-tools${NC}"
    exit 1
fi

# Step 3: Connect to phone via Wi-Fi
echo -e "${YELLOW}📱 Connecting to phone at ${PHONE_IP}:${PHONE_PORT}...${NC}"
adb connect ${PHONE_IP}:${PHONE_PORT} 2>/dev/null

sleep 1

# Verify connection
DEVICE_CHECK=$(adb devices | grep "${PHONE_IP}:${PHONE_PORT}" | grep "device")
if [ -z "$DEVICE_CHECK" ]; then
    echo -e "${RED}✗ Failed to connect to phone.${NC}"
    echo -e "${YELLOW}Make sure your phone is on the same Wi-Fi network and IP is correct.${NC}"
    echo -e "${YELLOW}Current IP: ${PHONE_IP}:${PHONE_PORT}${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Connected to phone${NC}"

# Step 4: Create target directory
echo -e "${YELLOW}📁 Creating target directory on phone...${NC}"
adb shell "mkdir -p ${PHONE_TARGET}" 2>/dev/null

# Step 5: Push files
echo -e "${YELLOW}📤 Pushing files to ${PHONE_TARGET}...${NC}"
adb push ${LOCAL_SOURCE}/. ${PHONE_TARGET}

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Files synced successfully!${NC}"

    # Optional: Show where files were copied
    echo -e "${YELLOW}📂 Files copied to: ${PHONE_TARGET}${NC}"

    # Try to refresh if there's a browser/webview open
    adb shell input keyevent KEYCODE_F5 2>/dev/null

    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}✓ Sync complete!${NC}"
    echo -e "${GREEN}================================${NC}"
else
    echo -e "${RED}✗ Push failed.${NC}"
    exit 1
fi
