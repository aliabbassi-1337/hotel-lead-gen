#!/bin/bash
# Restart OneDrive to force sync
killall OneDrive 2>/dev/null
sleep 1
open -a OneDrive
echo "OneDrive restarted - syncing..."
