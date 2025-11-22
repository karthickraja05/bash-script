#!/bin/bash

# Count videos first
COUNT=$(adb shell 'find /storage/emulated/0 -type f \( \
    -iname "*.mp4" -o \
    -iname "*.mov" -o \
    -iname "*.mkv" -o \
    -iname "*.avi" -o \
    -iname "*.3gp" -o \
    -iname "*.webm" \
\)' | wc -l)

echo "🎥 Total videos found: $COUNT"

if [[ "$COUNT" -eq 0 ]]; then
    echo "✅ No videos to delete."
    exit 0
fi

echo "⚠️  WARNING: This will permanently delete ALL $COUNT videos from your phone!"
read -p "Type YES to continue: " CONFIRM

if [[ "$CONFIRM" != "YES" ]]; then
    echo "❌ Cancelled."
    exit 1
fi

echo "🗑️  Deleting videos..."
adb shell 'find /storage/emulated/0 -type f \( \
    -iname "*.mp4" -o \
    -iname "*.mov" -o \
    -iname "*.mkv" -o \
    -iname "*.avi" -o \
    -iname "*.3gp" -o \
    -iname "*.webm" \
\) -delete'

echo "✅ Completed — $COUNT videos deleted."
