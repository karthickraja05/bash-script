#!/bin/bash

SRC="/home/karthickraja/Pictures/valparai_trip"       # Folder with existing images
DEST="$HOME/Pictures/photo-backup-redmi"

LOG_FILE="$DEST/copied-files.log"
ERR_LOG="$DEST/failed-files.log"
SKIP_LOG="$DEST/skip-files.log"


# Patterns to skip
SKIP_PATTERNS=(
    ".trashed-"
    "en_US_fonts"
)

TOTAL=0
COPIED=0
SKIPPED=0
FAILED=0

while read -r FILE; do
    [[ -z "$FILE" ]] && continue
    TOTAL=$((TOTAL + 1))
    BASENAME=$(basename "$FILE")

    # Skip unwanted patterns
    for PATTERN in "${SKIP_PATTERNS[@]}"; do
        if [[ "$FILE" == *"$PATTERN"* ]]; then
            echo "🗑️ Skipping $BASENAME due to pattern '$PATTERN'"
            echo "$BASENAME" >> "$SKIP_LOG"
            SKIPPED=$((SKIPPED + 1))
            continue 2
        fi
    done

    DATE_FOUND=""

    # -----------------------------------
    # Pattern 1 — IMG_YYYYMMDD_*.jpg
    if [[ $BASENAME =~ IMG[_-]([0-9]{4})([0-9]{2})([0-9]{2}) ]]; then
        DATE_FOUND="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
    fi

    # Pattern 2 — IMG-YYYYMMDD-WA*.jpg
    if [[ -z "$DATE_FOUND" ]] && [[ $BASENAME =~ IMG-([0-9]{8})-WA ]]; then
        yyyy=${BASH_REMATCH[1]:0:4}
        mm=${BASH_REMATCH[1]:4:2}
        dd=${BASH_REMATCH[1]:6:2}
        DATE_FOUND="$yyyy-$mm-$dd"
    fi

    # Pattern 3 — Screenshot_YYYYMMDD*.jpg
    if [[ -z "$DATE_FOUND" ]] && [[ $BASENAME =~ Screenshot[_-]([0-9]{4})([0-9]{2})([0-9]{2}) ]]; then
        DATE_FOUND="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
    fi

    # Pattern 4 — VID_YYYYMMDD_*.jpg
    if [[ -z "$DATE_FOUND" ]] && [[ $BASENAME =~ VID[_-]?([0-9]{4})([0-9]{2})([0-9]{2}) ]]; then
        DATE_FOUND="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
    fi

    # -----------------------------------
    # If no pattern found → Unknown folder
    if [[ -z "$DATE_FOUND" ]]; then
        TARGET="$DEST/Unknown"
        mkdir -p "$TARGET"
        if mv "$FILE" "$TARGET/"; then
            echo "$BASENAME" >> "$LOG_FILE"
            SKIPPED=$((SKIPPED + 1))
        else
            echo "$BASENAME" >> "$ERR_LOG"
            FAILED=$((FAILED + 1))
        fi
        continue
    fi

    # Convert to Month Year folder
    YEAR=${DATE_FOUND:0:4}
    MONTH=${DATE_FOUND:5:2}
    MONTH_NAME=$(date -d "$YEAR-$MONTH-01" +"%B")
    TARGET="$DEST/$MONTH_NAME $YEAR"
    mkdir -p "$TARGET"

    # Move file
    if mv "$FILE" "$TARGET/"; then
        echo "$BASENAME" >> "$LOG_FILE"
        COPIED=$((COPIED + 1))
    else
        echo "$BASENAME" >> "$ERR_LOG"
        FAILED=$((FAILED + 1))
    fi

done < <(find "$SRC" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.heic" \))

echo "----------------------------------------------"
echo "✔ Backup completed!"
echo "Summary:"
echo "  Total found ..........: $TOTAL"
echo "  Copied ...............: $COPIED"
echo "  Skipped (Unknown) ....: $SKIPPED"
echo "  Failed ...............: $FAILED"
echo "Log file: $LOG_FILE"
echo "Error log: $ERR_LOG"
echo "Skip log: $SKIP_LOG"
