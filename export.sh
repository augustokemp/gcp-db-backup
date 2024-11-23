#!/bin/bash

# Load configuration
CONFIG_FILE="./.env"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[error] Configuration file not found at $CONFIG_FILE"
    exit 1
fi

# Source the configuration file
source "$CONFIG_FILE"

# Function to verify SQL instance access
verify_sql_access() {
    local instance_id="$1"
    local project_id="$2"

    echo "[info] Checking user permissions to access GCloud SQL instance"
    if gcloud sql instances describe "${instance_id}" --project "${project_id}" >/dev/null 2>&1; then
        return 0
    else
        echo "[error] User does not have permission to access the Cloud SQL instance."
        return 1
    fi
}

# Function to verify bucket access
verify_bucket_access() {
    local bucket_name="$1"

    if gcloud storage ls "gs://${bucket_name}" >/dev/null 2>&1; then
        return 0
    else
        echo "[error] User does not have permission to export the Cloud SQL instance to the Cloud Storage bucket."
        return 1
    fi
}

# Function to check if file exists in bucket
check_file_exists() {
    local bucket_name="$1"
    local file_name="$2"

    if gcloud storage ls "gs://${bucket_name}/${file_name}" >/dev/null 2>&1; then
        echo "[info] File ${file_name} already exists on bucket ${bucket_name}"
        return 0
    else
        return 1
    fi
}

# Function to export SQL database
export_database() {
    local instance_id="$1"
    local bucket_name="$2"
    local file_name="$3"
    local db_name="$4"
    local project_id="$5"

    echo "[info] Starting export: DB ${instance_id}/${db_name}"
    
    if gcloud sql export sql "${instance_id}" "gs://${bucket_name}/${file_name}" \
        --database "${db_name}" \
        --project="${project_id}"; then
        echo "[info] Finished exporting"
        return 0
    else
        echo "[error] Unable to finish export"
        return 1
    fi
}

# Function to verify required variables
verify_variables() {
    local required_vars=(
        "INSTANCE_ID"
        "PROJECT_ID"
        "BUCKET_NAME"
        "FILE_NAME"
        "DB_NAME"
    )
    local missing_vars=()

    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done

    if [ ${#missing_vars[@]} -ne 0 ]; then
        echo "[error] The following required variables are missing in $CONFIG_FILE:"
        printf '%s\n' "${missing_vars[@]}"
        return 1
    fi
    return 0
}

# Main execution
main() {
    # Verify configuration variables
    if ! verify_variables; then
        exit 1
    fi

    # Verify SQL instance access
    if ! verify_sql_access "${INSTANCE_ID}" "${PROJECT_ID}"; then
        exit 1
    fi

    # Verify bucket access
    if ! verify_bucket_access "${BUCKET_NAME}"; then
        exit 1
    fi

    # Check if file already exists
    if check_file_exists "${BUCKET_NAME}" "${FILE_NAME}"; then
        exit 0
    fi

    # Export database
    if ! export_database "${INSTANCE_ID}" "${BUCKET_NAME}" "${FILE_NAME}" "${DB_NAME}" "${PROJECT_ID}"; then
        exit 1
    fi
}

# Run main function
main