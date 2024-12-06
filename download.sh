#!/bin/bash

# Load configuration
CONFIG_FILE="./.env"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[error] Configuration file not found at $CONFIG_FILE"
    exit 1
fi

# Source the configuration file
source "$CONFIG_FILE"

# Function to check GCloud permissions and download file
download_from_gcloud() {
    local remote_path="$1"
    local local_path="$2"
    local file_name="$3"

    echo "[info] Checking if user has permission to download from GCloud Bucket"
    
    # Check if the user has permission to access the Cloud Storage bucket
    # Note: Changed from gsutil to gcloud storage
    if gcloud storage ls "${remote_path}" >/dev/null 2>&1; then
        # Check if file already exists locally
        if ls "${local_path}/${file_name}" >/dev/null 2>&1; then
            echo "[info] File ${file_name} already exists on ${local_path}"
            return 0
        else
            echo "[info] Downloading file from GCloud Storage..."
            if gsutil cp "${remote_path}/${file_name}" "${local_path}/${file_name}"; then
                echo "[info] Finished downloading"
                return 0
            else
                echo "[error] Unable to finish download"
                return 1
            fi
        fi
    else
        echo "[error] User does not have permission to access the Cloud Storage bucket."
        return 1
    fi
}

# Function to verify required variables
verify_variables() {
    local required_vars=("REMOTE_PATH" "LOCAL_PATH" "FILE_NAME")
    local missing_vars=()

    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done

    if [ ${#missing_vars[@]} -ne 0 ]; then
        echo "[error] The following required variables are missing in $CONFIG_FILE:"
        printf '%s\n' "${missing_vars[@]}"
        exit 1
    fi
}

# Main execution
main() {
    # Verify configuration variables
    verify_variables

    # Create local directory if it doesn't exist
    mkdir -p "${LOCAL_PATH}"

    # Execute download function
    download_from_gcloud "${REMOTE_PATH}" "${LOCAL_PATH}" "${FILE_NAME}"
    
    # Check the return status
    if [ $? -ne 0 ]; then
        echo "[error] Download process failed"
        exit 1
    fi
}

# Run main function
main