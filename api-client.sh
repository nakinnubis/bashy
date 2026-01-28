#!/bin/bash

# API Client Library - HTTP methods wrapper for curl
# Usage: source this file to get HTTP helper functions

# Color codes for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default settings
API_TIMEOUT=${API_TIMEOUT:-30}
API_VERBOSE=${API_VERBOSE:-false}

# Print colored messages
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Helper function to check if jq is available
check_jq() {
    if ! command -v jq &> /dev/null; then
        log_warning "jq is not installed. JSON formatting will be limited."
        return 1
    fi
    return 0
}

# Pretty print JSON response
pretty_json() {
    local response="$1"
    if check_jq; then
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
    else
        echo "$response"
    fi
}

# Parse response and extract status code, headers, and body
parse_response() {
    local response="$1"
    local temp_file=$(mktemp)

    # Write response to temp file
    echo "$response" > "$temp_file"

    # Extract HTTP status code from last line containing HTTP/
    HTTP_STATUS=$(grep "HTTP/" "$temp_file" | tail -1 | awk '{print $2}')

    # Extract headers (everything before empty line)
    HTTP_HEADERS=$(awk '/^HTTP\//,/^\r?$/{print}' "$temp_file" | sed '/^\r?$/d')

    # Extract body (everything after first empty line)
    HTTP_BODY=$(awk '/^\r?$/,0' "$temp_file" | tail -n +2)

    rm -f "$temp_file"
}

# GET request
api_get() {
    local url="$1"
    local headers="$2"

    log_info "GET $url"

    local curl_opts=(-s -i -X GET --max-time "$API_TIMEOUT")

    if [ -n "$headers" ]; then
        while IFS= read -r header; do
            curl_opts+=(-H "$header")
        done <<< "$headers"
    fi

    if [ "$API_VERBOSE" = "true" ]; then
        curl_opts+=(-v)
    fi

    local response=$(curl "${curl_opts[@]}" "$url" 2>&1)
    parse_response "$response"

    if [ -n "$HTTP_STATUS" ] && [ "$HTTP_STATUS" -ge 200 ] && [ "$HTTP_STATUS" -lt 300 ]; then
        log_success "Status: $HTTP_STATUS"
        pretty_json "$HTTP_BODY"
        return 0
    else
        log_error "Status: ${HTTP_STATUS:-Connection failed}"
        echo "$HTTP_BODY"
        return 1
    fi
}

# POST request
api_post() {
    local url="$1"
    local data="$2"
    local headers="$3"

    log_info "POST $url"

    local curl_opts=(-s -i -X POST --max-time "$API_TIMEOUT")

    if [ -n "$data" ]; then
        curl_opts+=(-d "$data")
    fi

    # Default to JSON content type
    curl_opts+=(-H "Content-Type: application/json")

    if [ -n "$headers" ]; then
        while IFS= read -r header; do
            curl_opts+=(-H "$header")
        done <<< "$headers"
    fi

    if [ "$API_VERBOSE" = "true" ]; then
        curl_opts+=(-v)
    fi

    local response=$(curl "${curl_opts[@]}" "$url" 2>&1)
    parse_response "$response"

    if [ -n "$HTTP_STATUS" ] && [ "$HTTP_STATUS" -ge 200 ] && [ "$HTTP_STATUS" -lt 300 ]; then
        log_success "Status: $HTTP_STATUS"
        pretty_json "$HTTP_BODY"
        return 0
    else
        log_error "Status: ${HTTP_STATUS:-Connection failed}"
        echo "$HTTP_BODY"
        return 1
    fi
}

# PUT request
api_put() {
    local url="$1"
    local data="$2"
    local headers="$3"

    log_info "PUT $url"

    local curl_opts=(-s -i -X PUT --max-time "$API_TIMEOUT")

    if [ -n "$data" ]; then
        curl_opts+=(-d "$data")
    fi

    curl_opts+=(-H "Content-Type: application/json")

    if [ -n "$headers" ]; then
        while IFS= read -r header; do
            curl_opts+=(-H "$header")
        done <<< "$headers"
    fi

    if [ "$API_VERBOSE" = "true" ]; then
        curl_opts+=(-v)
    fi

    local response=$(curl "${curl_opts[@]}" "$url" 2>&1)
    parse_response "$response"

    if [ -n "$HTTP_STATUS" ] && [ "$HTTP_STATUS" -ge 200 ] && [ "$HTTP_STATUS" -lt 300 ]; then
        log_success "Status: $HTTP_STATUS"
        pretty_json "$HTTP_BODY"
        return 0
    else
        log_error "Status: ${HTTP_STATUS:-Connection failed}"
        echo "$HTTP_BODY"
        return 1
    fi
}

# DELETE request
api_delete() {
    local url="$1"
    local headers="$2"

    log_info "DELETE $url"

    local curl_opts=(-s -i -X DELETE --max-time "$API_TIMEOUT")

    if [ -n "$headers" ]; then
        while IFS= read -r header; do
            curl_opts+=(-H "$header")
        done <<< "$headers"
    fi

    if [ "$API_VERBOSE" = "true" ]; then
        curl_opts+=(-v)
    fi

    local response=$(curl "${curl_opts[@]}" "$url" 2>&1)
    parse_response "$response"

    if [ -n "$HTTP_STATUS" ] && [ "$HTTP_STATUS" -ge 200 ] && [ "$HTTP_STATUS" -lt 300 ]; then
        log_success "Status: $HTTP_STATUS"
        pretty_json "$HTTP_BODY"
        return 0
    else
        log_error "Status: ${HTTP_STATUS:-Connection failed}"
        echo "$HTTP_BODY"
        return 1
    fi
}

# PATCH request
api_patch() {
    local url="$1"
    local data="$2"
    local headers="$3"

    log_info "PATCH $url"

    local curl_opts=(-s -i -X PATCH --max-time "$API_TIMEOUT")

    if [ -n "$data" ]; then
        curl_opts+=(-d "$data")
    fi

    curl_opts+=(-H "Content-Type: application/json")

    if [ -n "$headers" ]; then
        while IFS= read -r header; do
            curl_opts+=(-H "$header")
        done <<< "$headers"
    fi

    if [ "$API_VERBOSE" = "true" ]; then
        curl_opts+=(-v)
    fi

    local response=$(curl "${curl_opts[@]}" "$url" 2>&1)
    parse_response "$response"

    if [ -n "$HTTP_STATUS" ] && [ "$HTTP_STATUS" -ge 200 ] && [ "$HTTP_STATUS" -lt 300 ]; then
        log_success "Status: $HTTP_STATUS"
        pretty_json "$HTTP_BODY"
        return 0
    else
        log_error "Status: ${HTTP_STATUS:-Connection failed}"
        echo "$HTTP_BODY"
        return 1
    fi
}

# Export functions if sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    export -f api_get api_post api_put api_delete api_patch
    export -f log_info log_success log_error log_warning
    export -f pretty_json parse_response check_jq
    log_success "API client library loaded!"
fi
