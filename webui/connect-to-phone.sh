#!/bin/bash

PHONE_IP="192.168.1.107"  # Change this to your phone's IP
PHONE_PORT="5555"

echo "Connecting to phone at $PHONE_IP:$PHONE_PORT..."
adb connect $PHONE_IP:$PHONE_PORT

if [ $? -eq 0 ]; then
    echo "✓ Connected successfully"
    echo "Connected devices:"
    adb devices
else
    echo "✗ Failed to connect"
    echo "Make sure:"
    echo "1. Phone is on same WiFi network"
    echo "2. WiFi ADB is enabled (run on phone: su -c 'setprop service.adb.tcp.port 5555 && stop adbd && start adbd')"
    echo "3. No firewall blocking port 5555"
fi
