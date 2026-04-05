#!/bin/sh

# Ensure this file is sourced, not executed
(return 0 2>/dev/null) || {
    echo "[!] common.sh must be sourced, not executed"
    exit 1
}

# Default number of parallel jobs (can be overridden by environment)
: "${JOBS_NUM:=8}"
export JOBS_NUM=8

# Timestamp function
_timestamp() {
    date '+%H:%M:%S'
}

# Logging helpers
log() {
    printf '[%s] %s\n' "$(_timestamp)" "$*"
}

log_info() {
    printf '[%s] [INFO] %s\n' "$(_timestamp)" "$*"
}

log_warn() {
    printf '[%s] [WARN] %s\n' "$(_timestamp)" "$*" >&2
}

log_error() {
    printf '[%s] [ERROR] %s\n' "$(_timestamp)" "$*" >&2
}

# Exit with error message
die() {
    log_error "$*"
    exit 1
}

# Run command with logging
run() {
    log_info "Running: $*"
    "$@" || die "Command failed: $*"
}

# Check required command exists
require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}
