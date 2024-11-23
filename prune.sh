#!/bin/bash

# Load configuration
CONFIG_FILE="./.env"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found at $CONFIG_FILE"
    exit 1
fi

# Source the configuration file
source "$CONFIG_FILE"

# Verify required variables are set
check_required_vars() {
    local required_vars=("LOCAL_PATH" "FILE_NAME" "BUCKET_NAME" "REMOTE_PATH")
    local missing_vars=()

    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done

    if [ ${#missing_vars[@]} -ne 0 ]; then
        echo "Error: The following required variables are missing or empty in $CONFIG_FILE:"
        printf '%s\n' "${missing_vars[@]}"
        exit 1
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [--local|--remote]"
    echo "Options:"
    echo "  --local   Clean up local SQL backup files"
    echo "  --remote  Clean up remote SQL backup files from Google Cloud Storage"
    exit 1
}

# Function for local cleanup
cleanup_local() {
    echo -e "[info] Removing old local dumps"
    LOCAL_FILE_PATH="${LOCAL_PATH}/${FILE_NAME}"

    {
        FILES=$(ls $LOCAL_PATH/*.sql) &&
        # Loop through the files and remove old
        for FILE in $FILES; do
            if [[ "$FILE" != "$LOCAL_FILE_PATH" ]]; then
                rm -rf "$FILE" >/dev/null 2>&1 &&
                echo -e "[info] Removed local file: $FILE"
            fi
        done &&
        echo -e "[info] Old DB backups removed successfully"
    } || {
        echo "[info] No .SQL files found. Skipping..."
    }
}

# Function for remote cleanup
cleanup_remote() {
    echo -e "[info] Removing old remote dumps"
    REMOTE_FILE_PATH="${REMOTE_PATH}/${FILE_NAME}"

    # List files in the bucket and filter by creation date
    FILES=$(gsutil ls gs://$BUCKET_NAME/*.sql)

    # Loop through the files and remove old
    for FILE in $FILES; do
        if [[ "${FILE}" != "${REMOTE_FILE_PATH}" ]]; then
            gsutil rm "$FILE" >/dev/null 2>&1 &&
            echo -e "[info] Removed remote file: $FILE"
        fi
    done
    echo -e "[info] Old DB backups removed successfully"
}

# Check configuration before proceeding
check_required_vars

# Check if argument is provided
if [ $# -ne 1 ]; then
    show_usage
fi

# Process command line arguments
case "$1" in
    --local)
        cleanup_local
        ;;
    --remote)
        cleanup_remote
        ;;
    *)
        show_usage
        ;;
esac