#!/bin/bash

DEST="$HOME/Pictures/photo-backup-oneplus_test"
LOG_FILE="$DEST/copied-files.log"
ERR_LOG="$DEST/failed-files.log"
SKIP_LOG="$DEST/skip-files.log"

mkdir -p "$DEST"
> "$LOG_FILE"
> "$ERR_LOG"
> "$SKIP_LOG"

echo "📱 Starting Android → Ubuntu image backup..."
echo "----------------------------------------------"

TOTAL=0
COPIED=0
SKIPPED=0
FAILED=0
IGNORE=0

while read -r FILE; do
    [[ -z "$FILE" ]] && continue
    
    # Stop after 100 files for testing
    # if [[ $TOTAL -gt 10 ]]; then
    #     echo "🛑 Test limit reached: $TOTAL files processed"
    #     break
    # fi

    TOTAL=$((TOTAL + 1))

    BASENAME=$(basename "$FILE")

    # Define an array of skip patterns
    SKIP_PATTERNS=(
        ".trashed-"
        "en_US_fonts"
        # Add more patterns here as needed
    )

    # Inside your while loop, after getting BASENAME
    for PATTERN in "${SKIP_PATTERNS[@]}"; do
        if [[ "$FILE" == *"$PATTERN"* ]]; then
            echo "🗑️  Skipping file due to pattern '$PATTERN': $BASENAME"
            # Add to skip log
            echo "$FILE" >> "$SKIP_LOG"
            IGNORED=$((IGNORED + 1))
            continue 2   # Skip to next file in the while loop
        fi
    done
    
    echo
    echo "👉 Processing: $FILE"

    DATE_FOUND=""

    # -----------------------------------
    # Pattern 1 — IMG_20250112_141335.jpg
    # -----------------------------------
    if [[ $BASENAME =~ IMG[_-]([0-9]{4})([0-9]{2})([0-9]{2}) ]]; then
        DATE_FOUND="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
    fi

    # -----------------------------------
    # Pattern 2 — IMG-20181013-WA0017.jpg (WhatsApp)
    # -----------------------------------
    if [[ -z "$DATE_FOUND" ]]; then
        if [[ $BASENAME =~ IMG-([0-9]{8})-WA ]]; then
            yyyy=${BASH_REMATCH[1]:0:4}
            mm=${BASH_REMATCH[1]:4:2}
            dd=${BASH_REMATCH[1]:6:2}
            DATE_FOUND="$yyyy-$mm-$dd"
        fi
    fi

    # -----------------------------------
    # Pattern 3 — Screenshot_20200215.jpg
    # -----------------------------------
    if [[ -z "$DATE_FOUND" ]]; then
        if [[ $BASENAME =~ Screenshot[_-]([0-9]{4})([0-9]{2})([0-9]{2}) ]]; then
            DATE_FOUND="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
        fi
    fi

    # -----------------------------------
    # Pattern 4 — 20220507_153021.jpg (Samsung)
    # -----------------------------------
    if [[ -z "$DATE_FOUND" ]]; then
        if [[ $BASENAME =~ ^([0-9]{4})([0-9]{2})([0-9]{2})_ ]]; then
            DATE_FOUND="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
        fi
    fi

    # -----------------------------------
    # Pattern 5 — PXL_20230621_123456789.jpg
    # -----------------------------------
    if [[ -z "$DATE_FOUND" ]]; then
        if [[ $BASENAME =~ PXL_([0-9]{4})([0-9]{2})([0-9]{2}) ]]; then
            DATE_FOUND="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
        fi
    fi

    # -----------------------------------
    # Pattern 6 — 2019-11-26-09-02-33.jpg
    # -----------------------------------
    if [[ -z "$DATE_FOUND" ]]; then
        if [[ $BASENAME =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2}) ]]; then
            DATE_FOUND="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
        fi
    fi

    # -----------------------------------
    # Pattern 7 — Pure numbers: 10-digit or 13-digit timestamps
    # -----------------------------------
    if [[ -z "$DATE_FOUND" ]]; then
        NUM_ONLY=$(echo "$BASENAME" | grep -o '^[0-9]\{10,13\}')
        if [[ ! -z "$NUM_ONLY" ]]; then
            
            # If 13-digit → convert ms → seconds
            if [[ ${#NUM_ONLY} -eq 13 ]]; then
                NUM=$(( NUM_ONLY / 1000 ))
            else
                NUM=$NUM_ONLY
            fi
            
            # Convert timestamp → date
            DATE_FROM_NUM=$(date -d "@$NUM" +"%Y-%m-%d" 2>/dev/null)

            if [[ $? -eq 0 ]]; then
                DATE_FOUND="$DATE_FROM_NUM"
            fi
        fi
    fi

    # -----------------------------------
    # Pattern 8 — VID_20240727_171919_1761388896634.jpg
    # -----------------------------------
    if [[ -z "$DATE_FOUND" ]]; then
        if [[ $BASENAME =~ VID[_-]?([0-9]{4})([0-9]{2})([0-9]{2})[_-]?([0-9]{6}) ]]; then
            YEAR="${BASH_REMATCH[1]}"
            MONTH="${BASH_REMATCH[2]}"
            DAY="${BASH_REMATCH[3]}"
            DATE_FOUND="$YEAR-$MONTH-$DAY"
        fi
    fi

    # -----------------------------------
    # Pattern 9 — P_YYYYMMDD_HHMMSS_*.jpg (Pixel/MI)
    # -----------------------------------
    if [[ -z "$DATE_FOUND" ]]; then
        if [[ $BASENAME =~ P_([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{6}) ]]; then
            YEAR="${BASH_REMATCH[1]}"
            MONTH="${BASH_REMATCH[2]}"
            DAY="${BASH_REMATCH[3]}"
            DATE_FOUND="$YEAR-$MONTH-$DAY"
        fi
    fi

    # -----------------------------------
    # Pattern 10 — IMGYYYYMMDDHHMMSS.jpg
    # Example: IMG20230502114649.jpg
    # -----------------------------------
    if [[ -z "$DATE_FOUND" ]]; then
        if [[ $BASENAME =~ IMG([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2}) ]]; then
            YEAR="${BASH_REMATCH[1]}"
            MONTH="${BASH_REMATCH[2]}"
            DAY="${BASH_REMATCH[3]}"
            DATE_FOUND="$YEAR-$MONTH-$DAY"
        fi
    fi

    # -----------------------------------
    # Move all Screenshots to Screenshots folder
    # -----------------------------------
    if [[ "$BASENAME" == Screenshot_* ]]; then
        TARGET="$DEST/Screenshots"
        mkdir -p "$TARGET"
        echo "📸 Screenshot detected → Saving to: $TARGET"
        if adb pull "$FILE" "$TARGET/" >/dev/null 2>>"$ERR_LOG"; then
            echo "$BASENAME" >> "$LOG_FILE"
            echo "✅ Copied!"
            COPIED=$((COPIED + 1))
        else
            echo "$BASENAME" >> "$ERR_LOG"
            echo "❌ Failed!"
            FAILED=$((FAILED + 1))
        fi
        continue  # skip further pattern checks
    fi

    # -----------------------------------
    # No date found → Unknown folder
    # -----------------------------------
    if [[ -z "$DATE_FOUND" ]]; then
        echo "⚠️  No date found → Moving to Unknown/"
        TARGET="$DEST/Unknown"
        mkdir -p "$TARGET"
        adb pull "$FILE" "$TARGET/" >/dev/null 2>>"$ERR_LOG"
        # adb pull "$FILE" "$TARGET/" >> "$LOG_FILE" 2>>"$ERR_LOG"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    echo "📆 Extracted: $DATE_FOUND"

    YEAR=${DATE_FOUND:0:4}
    MONTH=${DATE_FOUND:5:2}

    # Convert to Month name
    MONTH_NAME=$(date -d "$YEAR-$MONTH-01" +"%B")

    TARGET="$DEST/$MONTH_NAME $YEAR"
    mkdir -p "$TARGET"

    echo "📂 Saving into: $TARGET"
    if adb pull "$FILE" "$TARGET/" >/dev/null 2>>"$ERR_LOG"; then
        echo "$BASENAME" >> "$LOG_FILE"
        echo "✅ Copied!"
        COPIED=$((COPIED + 1))
    else
        echo "$BASENAME" >> "$ERR_LOG"
        echo "❌ Failed!"
        FAILED=$((FAILED + 1))
    fi

done < <(adb shell 'find /storage/emulated/0 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.heic" \)')


echo "----------------------------------------------"
echo "✔ Backup completed!"
echo "Summary:"
echo "  Total found ..........: $TOTAL"
echo "  Copied ...............: $COPIED"
echo "  Skipped (Unknown) ....: $SKIPPED"
echo "  Failed ...............: $FAILED"
echo "  IGNORED ...............: $IGNORED"
echo "Log file: $LOG_FILE"
echo "Error log: $ERR_LOG"



# Copy all images from android to laptop with single script , data moved folder wise