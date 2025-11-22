#!/bin/bash

FOLDER_A="/home/karthickraja/Pictures/photo-backup-redmi"
FOLDER_B="/home/karthickraja/Pictures/Camera"

deleted_count=0

# Loop through files without creating a subshell
while IFS= read -r fileA; do
    filename=$(basename "$fileA")

    # Loop through matching files in Folder B
    while IFS= read -r match; do
        echo "Deleting $match"
        rm "$match"
        ((deleted_count++))
    done < <(find "$FOLDER_B" -type f -name "$filename")
done < <(find "$FOLDER_A" -type f)

# Remove empty directories
find "$FOLDER_B" -type d -empty -exec echo "Removing empty folder: {}" \; -exec rmdir {} \;

echo "Total files deleted: $deleted_count"
