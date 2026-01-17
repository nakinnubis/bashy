#!/bin/bash

# Request Router - Bash-based backend routing system
# Simulates a backend router that handles different routes and methods

source "$(dirname "$0")/api-client.sh"

# Route registry (associative arrays)
declare -A ROUTES_GET
declare -A ROUTES_POST
declare -A ROUTES_PUT
declare -A ROUTES_DELETE

# Register a route handler
register_route() {
    local method="$1"
    local path="$2"
    local handler="$3"

    case "$method" in
        GET)
            ROUTES_GET["$path"]="$handler"
            ;;
        POST)
            ROUTES_POST["$path"]="$handler"
            ;;
        PUT)
            ROUTES_PUT["$path"]="$handler"
            ;;
        DELETE)
            ROUTES_DELETE["$path"]="$handler"
            ;;
        *)
            log_error "Unsupported method: $method"
            return 1
            ;;
    esac
    log_info "Registered $method $path -> $handler"
}

# Match route with path parameters
match_route() {
    local path="$1"
    local pattern="$2"

    # Convert route pattern to regex
    # /users/:id -> /users/[^/]+
    local regex=$(echo "$pattern" | sed 's|:[^/]*|[^/]+|g')
    regex="^${regex}$"

    if [[ "$path" =~ $regex ]]; then
        return 0
    fi
    return 1
}

# Extract path parameters
extract_params() {
    local path="$1"
    local pattern="$2"

    declare -gA ROUTE_PARAMS

    # Split path and pattern into arrays
    IFS='/' read -ra path_parts <<< "$path"
    IFS='/' read -ra pattern_parts <<< "$pattern"

    for i in "${!pattern_parts[@]}"; do
        if [[ "${pattern_parts[$i]}" =~ ^: ]]; then
            local param_name="${pattern_parts[$i]:1}"
            ROUTE_PARAMS["$param_name"]="${path_parts[$i]}"
        fi
    done
}

# Handle incoming request
handle_request() {
    local method="$1"
    local path="$2"
    local body="$3"

    log_info "Incoming request: $method $path"

    # Select appropriate route map
    local -n routes
    case "$method" in
        GET) routes=ROUTES_GET ;;
        POST) routes=ROUTES_POST ;;
        PUT) routes=ROUTES_PUT ;;
        DELETE) routes=ROUTES_DELETE ;;
        *)
            respond 405 '{"error": "Method not allowed"}'
            return 1
            ;;
    esac

    # Find matching route
    for pattern in "${!routes[@]}"; do
        if match_route "$path" "$pattern"; then
            extract_params "$path" "$pattern"
            local handler="${routes[$pattern]}"

            # Call handler function
            if type "$handler" &> /dev/null; then
                "$handler" "$body"
                return $?
            else
                log_error "Handler function '$handler' not found"
                respond 500 '{"error": "Internal server error"}'
                return 1
            fi
        fi
    done

    # No route found
    respond 404 '{"error": "Route not found"}'
    return 1
}

# Send response
respond() {
    local status="$1"
    local body="$2"
    local content_type="${3:-application/json}"

    echo "HTTP/1.1 $status"
    echo "Content-Type: $content_type"
    echo "Content-Length: ${#body}"
    echo ""
    echo "$body"
}

# Example route handlers
handle_users_list() {
    log_success "Handling GET /users"
    respond 200 '{
        "users": [
            {"id": 1, "name": "Alice", "email": "alice@example.com"},
            {"id": 2, "name": "Bob", "email": "bob@example.com"},
            {"id": 3, "name": "Charlie", "email": "charlie@example.com"}
        ]
    }'
}

handle_user_get() {
    local user_id="${ROUTE_PARAMS[id]}"
    log_success "Handling GET /users/$user_id"
    respond 200 "{
        \"id\": $user_id,
        \"name\": \"User $user_id\",
        \"email\": \"user${user_id}@example.com\"
    }"
}

handle_user_create() {
    local body="$1"
    log_success "Handling POST /users"
    log_info "Request body: $body"

    # Parse JSON and create response
    local name=$(echo "$body" | jq -r '.name // "Unknown"' 2>/dev/null || echo "Unknown")
    local email=$(echo "$body" | jq -r '.email // "unknown@example.com"' 2>/dev/null || echo "unknown@example.com")

    respond 201 "{
        \"id\": $(date +%s),
        \"name\": \"$name\",
        \"email\": \"$email\",
        \"created_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
    }"
}

handle_user_update() {
    local body="$1"
    local user_id="${ROUTE_PARAMS[id]}"
    log_success "Handling PUT /users/$user_id"
    log_info "Request body: $body"

    respond 200 "{
        \"id\": $user_id,
        \"updated\": true,
        \"updated_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
    }"
}

handle_user_delete() {
    local user_id="${ROUTE_PARAMS[id]}"
    log_success "Handling DELETE /users/$user_id"

    respond 200 "{
        \"id\": $user_id,
        \"deleted\": true,
        \"deleted_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
    }"
}

handle_health() {
    log_success "Handling GET /health"
    respond 200 "{
        \"status\": \"healthy\",
        \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\",
        \"uptime\": \"$(uptime -p)\"
    }"
}

# Initialize default routes
init_routes() {
    register_route GET "/health" "handle_health"
    register_route GET "/users" "handle_users_list"
    register_route GET "/users/:id" "handle_user_get"
    register_route POST "/users" "handle_user_create"
    register_route PUT "/users/:id" "handle_user_update"
    register_route DELETE "/users/:id" "handle_user_delete"
}

# Main entry point
main() {
    log_info "Initializing router..."
    init_routes

    echo ""
    log_info "Router ready! Example usage:"
    echo ""
    echo "  # Handle a GET request"
    echo "  handle_request GET /users"
    echo ""
    echo "  # Handle a GET with parameter"
    echo "  handle_request GET /users/123"
    echo ""
    echo "  # Handle a POST with body"
    echo "  handle_request POST /users '{\"name\":\"Dave\",\"email\":\"dave@example.com\"}'"
    echo ""
    echo "  # Handle PUT request"
    echo "  handle_request PUT /users/123 '{\"name\":\"Updated Name\"}'"
    echo ""
    echo "  # Handle DELETE request"
    echo "  handle_request DELETE /users/123"
    echo ""
    echo "  # Check health"
    echo "  handle_request GET /health"
    echo ""
}

# Run main if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main
fi
