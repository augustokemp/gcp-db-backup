#!/bin/bash

# Load configuration
CONFIG_FILE="./.env"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[error] Configuration file not found at $CONFIG_FILE"
    exit 1
fi

# Source the configuration file
source "$CONFIG_FILE"

# Function to verify required variables
verify_variables() {
    local required_vars=(
        "LOCAL_PATH"
        "FILE_NAME"
        "REPOSITORY_PATH"
        "STACK_NAME"
        "DB_VOLUME_NAME"
        # "COMPOSE_FILE"
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

# Function to check if local dump is current
check_local_dump() {
    local expected_file="${LOCAL_PATH}/${FILE_NAME}"
    
    # Check if file exists
    if [ ! -f "$expected_file" ]; then
        echo "[info] Local dump file does not exist"
        return 1
    fi

    # Check if file is from today
    local file_date=$(date -r "$expected_file" +%Y%m%d)
    local today=$(date +%Y%m%d)
    
    if [ "$file_date" != "$today" ]; then
        echo "[info] Local dump file is not from today"
        return 1
    fi

    echo "[info] Current local dump file found"
    return 0
}

# Function to refresh database dump
refresh_dump() {
    echo "[info] Starting database dump refresh process"

    # Run local prune
    echo "[info] Running local prune"
    if ! ./prune.sh --local; then
        echo "[error] Local prune failed"
        return 1
    fi

    # Run remote prune
    echo "[info] Running remote prune"
    if ! ./prune.sh --remote; then
        echo "[error] Remote prune failed"
        return 1
    fi

    # Run export
    echo "[info] Running database export"
    if ! ./export.sh; then
        echo "[error] Database export failed"
        return 1
    fi

    # Run download
    echo "[info] Running download"
    if ! ./download.sh; then
        echo "[error] Download failed"
        return 1
    fi

    return 0
}

# Function to handle Docker operations
manage_docker() {
    local action=$1

    # Navigate to repository path
    cd "${REPOSITORY_PATH}" || {
        echo "[error] Failed to navigate to repository path"
        return 1
    }

    case $action in
        "stop")
            echo "[info] Stopping Docker containers for stack ${STACK_NAME}"
            docker compose -p "${STACK_NAME}" down
            ;;
        "start")
            echo "[info] Starting Docker containers for stack ${STACK_NAME}"
            docker compose -p "${STACK_NAME}" up -d
            ;;
        *)
            echo "[error] Invalid Docker action"
            return 1
            ;;
    esac
}

# Function to prune database volume
prune_volume() {
    echo "[info] Checking for database volume ${DB_VOLUME_NAME}"
    
    # Check if volume exists
    if docker volume ls -q | grep -q "^${DB_VOLUME_NAME}$"; then
        echo "[info] Found database volume, removing..."
        if docker volume rm "${DB_VOLUME_NAME}" >/dev/null 2>&1; then
            echo "[info] Successfully removed database volume"
            return 0
        else
            echo "[error] Failed to remove database volume"
            return 1
        fi
    else
        echo "[info] Database volume does not exist, skipping removal"
        return 0
    fi
}

# Main execution
main() {
    # Verify configuration variables
    if ! verify_variables; then
        exit 1
    fi

    # Check if we need to refresh the dump
    if ! check_local_dump; then
        echo "[info] Need to refresh database dump"
        if ! refresh_dump; then
            echo "[error] Failed to refresh database dump"
            exit 1
        fi
    fi

    # Stop Docker containers
    if ! manage_docker "stop"; then
        echo "[error] Failed to stop Docker containers"
        exit 1
    fi

    # Prune database volume
    if ! prune_volume; then
        echo "[error] Failed to prune database volume"
        exit 1
    fi

    # Start Docker containers
    if ! manage_docker "start"; then
        echo "[error] Failed to start Docker containers"
        exit 1
    fi

    echo "[info] Database refresh process completed successfully"
}

# Run main function
main