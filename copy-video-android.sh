#!/bin/bash

DEST="$HOME/Videos/video-backup-oneplus-video"
LOG_FILE="$DEST/copied-videos.log"
ERR_LOG="$DEST/failed-videos.log"

mkdir -p "$DEST"
> "$LOG_FILE"
> "$ERR_LOG"

echo "🎬 Starting Android → Ubuntu video backup..."
echo "----------------------------------------------"

TOTAL=0
COPIED=0
FAILED=0

# Supported video extensions — add more if needed
VIDEO_EXTS='\( -iname "*.mp4" -o -iname "*.mov" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.3gp" \)'

while read -r FILE; do
    [[ -z "$FILE" ]] && continue

    TOTAL=$((TOTAL + 1))
    BASENAME=$(basename "$FILE")

    echo "👉 Copying: $FILE"

    if adb pull "$FILE" "$DEST/" >/dev/null 2>>"$ERR_LOG"; then
        echo "$BASENAME" >> "$LOG_FILE"
        echo "✅ Copied!"
        COPIED=$((COPIED + 1))
    else
        echo "$BASENAME" >> "$ERR_LOG"
        echo "❌ Failed!"
        FAILED=$((FAILED + 1))
    fi

done < <(adb shell "find /storage/emulated/0 -type f $VIDEO_EXTS")

echo "----------------------------------------------"
echo "✔ Video backup completed!"
echo "Summary:"
echo "  Total found .........: $TOTAL"
echo "  Copied ..............: $COPIED"
echo "  Failed ..............: $FAILED"
echo "Saved to: $DEST"
echo "Logs:"
echo "  Success — $LOG_FILE"
echo "  Errors  — $ERR_LOG"
