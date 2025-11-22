#!/bin/bash

echo "⚠️  WARNING: This will permanently delete ALL images from your phone!"
read -p "Type YES to continue: " CONFIRM

if [[ "$CONFIRM" != "YES" ]]; then
    echo "❌ Cancelled."
    exit 1
fi

echo "🗑️  Deleting images from Android..."
adb shell 'find /storage/emulated/0 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.heic" \) -delete'

echo "✅ Completed — all matching images removed."
