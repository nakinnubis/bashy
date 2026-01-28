#!/bin/bash

# REST Client Example - Generic REST API client
# Demonstrates a complete REST client with authentication and error handling

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../api-client.sh"
source "$SCRIPT_DIR/../json-utils.sh"

# Configuration
API_BASE_URL="${API_BASE_URL:-https://jsonplaceholder.typicode.com}"
API_TOKEN="${API_TOKEN:-}"

# Build headers with authentication
build_headers() {
    local headers=""

    if [ -n "$API_TOKEN" ]; then
        headers="Authorization: Bearer $API_TOKEN"
    fi

    echo "$headers"
}

# List all resources
list_posts() {
    log_info "Fetching all posts"
    api_get "$API_BASE_URL/posts" "$(build_headers)"
}

# Get specific resource
get_post() {
    local id="$1"

    if [ -z "$id" ]; then
        log_error "Post ID required"
        echo "Usage: get_post <id>"
        return 1
    fi

    log_info "Fetching post $id"
    api_get "$API_BASE_URL/posts/$id" "$(build_headers)"
}

# Create new resource
create_post() {
    local title="$1"
    local body="$2"
    local userId="${3:-1}"

    if [ -z "$title" ] || [ -z "$body" ]; then
        log_error "Title and body required"
        echo "Usage: create_post <title> <body> [userId]"
        return 1
    fi

    log_info "Creating new post"

    local data=$(json_build "title" "$title" "body" "$body" "userId" "$userId")

    api_post "$API_BASE_URL/posts" "$data" "$(build_headers)"
}

# Update resource
update_post() {
    local id="$1"
    local title="$2"
    local body="$3"

    if [ -z "$id" ] || [ -z "$title" ] || [ -z "$body" ]; then
        log_error "ID, title and body required"
        echo "Usage: update_post <id> <title> <body>"
        return 1
    fi

    log_info "Updating post $id"

    local data=$(json_build "id" "$id" "title" "$title" "body" "$body" "userId" "1")

    api_put "$API_BASE_URL/posts/$id" "$data" "$(build_headers)"
}

# Partially update resource
patch_post() {
    local id="$1"
    local field="$2"
    local value="$3"

    if [ -z "$id" ] || [ -z "$field" ] || [ -z "$value" ]; then
        log_error "ID, field and value required"
        echo "Usage: patch_post <id> <field> <value>"
        return 1
    fi

    log_info "Patching post $id"

    local data=$(json_build "$field" "$value")

    api_patch "$API_BASE_URL/posts/$id" "$data" "$(build_headers)"
}

# Delete resource
delete_post() {
    local id="$1"

    if [ -z "$id" ]; then
        log_error "Post ID required"
        echo "Usage: delete_post <id>"
        return 1
    fi

    log_info "Deleting post $id"
    api_delete "$API_BASE_URL/posts/$id" "$(build_headers)"
}

# Get related resources
get_post_comments() {
    local id="$1"

    if [ -z "$id" ]; then
        log_error "Post ID required"
        echo "Usage: get_post_comments <id>"
        return 1
    fi

    log_info "Fetching comments for post $id"
    api_get "$API_BASE_URL/posts/$id/comments" "$(build_headers)"
}

# List users
list_users() {
    log_info "Fetching all users"
    api_get "$API_BASE_URL/users" "$(build_headers)"
}

# Get user by ID
get_user() {
    local id="$1"

    if [ -z "$id" ]; then
        log_error "User ID required"
        echo "Usage: get_user <id>"
        return 1
    fi

    log_info "Fetching user $id"
    api_get "$API_BASE_URL/users/$id" "$(build_headers)"
}

# Get user's posts
get_user_posts() {
    local userId="$1"

    if [ -z "$userId" ]; then
        log_error "User ID required"
        echo "Usage: get_user_posts <userId>"
        return 1
    fi

    log_info "Fetching posts for user $userId"
    api_get "$API_BASE_URL/posts?userId=$userId" "$(build_headers)"
}

# Search/filter posts
filter_posts() {
    local userId="$1"

    if [ -z "$userId" ]; then
        log_error "User ID required"
        echo "Usage: filter_posts <userId>"
        return 1
    fi

    log_info "Filtering posts by user $userId"
    local response=$(api_get "$API_BASE_URL/posts?userId=$userId" "$(build_headers)")

    if check_jq; then
        echo "$response" | jq '[.[] | {id, title}]'
    else
        echo "$response"
    fi
}

# Batch operations - create multiple posts
batch_create() {
    local count="${1:-3}"

    log_info "Creating $count posts in batch"

    for i in $(seq 1 "$count"); do
        log_info "Creating post $i of $count"
        create_post "Batch Post $i" "This is batch post number $i" "1"
        echo ""
    done

    log_success "Batch creation completed!"
}

# Get and display post with comments
get_post_with_comments() {
    local id="$1"

    if [ -z "$id" ]; then
        log_error "Post ID required"
        return 1
    fi

    log_info "Fetching post $id with comments"

    echo ""
    echo "=== POST ==="
    get_post "$id"

    echo ""
    echo "=== COMMENTS ==="
    get_post_comments "$id"
}

# Demonstrate full CRUD cycle
demo_crud() {
    echo ""
    log_info "Starting CRUD demonstration"
    echo ""

    # CREATE
    log_info "1. CREATE - Creating a new post"
    local create_response=$(create_post "Demo Post" "This is a demo post body")
    local new_id=$(echo "$create_response" | jq -r '.id' 2>/dev/null || echo "101")
    echo ""

    sleep 1

    # READ
    log_info "2. READ - Fetching the created post"
    get_post "$new_id"
    echo ""

    sleep 1

    # UPDATE
    log_info "3. UPDATE - Updating the post"
    update_post "$new_id" "Updated Demo Post" "This is the updated body"
    echo ""

    sleep 1

    # PATCH
    log_info "4. PATCH - Partially updating the post"
    patch_post "$new_id" "title" "Patched Demo Post"
    echo ""

    sleep 1

    # DELETE
    log_info "5. DELETE - Deleting the post"
    delete_post "$new_id"
    echo ""

    log_success "CRUD demonstration completed!"
}

# Main menu
show_menu() {
    echo ""
    echo "=== REST API Client ==="
    echo "Base URL: $API_BASE_URL"
    echo ""
    echo "Post Operations:"
    echo "  list_posts                              - List all posts"
    echo "  get_post <id>                           - Get specific post"
    echo "  create_post <title> <body> [userId]     - Create new post"
    echo "  update_post <id> <title> <body>         - Update post"
    echo "  patch_post <id> <field> <value>         - Partially update"
    echo "  delete_post <id>                        - Delete post"
    echo "  get_post_comments <id>                  - Get post comments"
    echo "  get_post_with_comments <id>             - Get post with comments"
    echo ""
    echo "User Operations:"
    echo "  list_users                              - List all users"
    echo "  get_user <id>                           - Get specific user"
    echo "  get_user_posts <userId>                 - Get user's posts"
    echo "  filter_posts <userId>                   - Filter posts by user"
    echo ""
    echo "Batch Operations:"
    echo "  batch_create [count]                    - Create multiple posts"
    echo ""
    echo "Demonstrations:"
    echo "  demo_crud                               - Full CRUD cycle demo"
    echo ""
    echo "Examples:"
    echo "  list_posts"
    echo "  get_post 1"
    echo "  create_post 'My Title' 'My post content'"
    echo "  get_user_posts 1"
    echo "  demo_crud"
    echo ""
}

# Run command if provided, otherwise show menu
if [ $# -gt 0 ]; then
    "$@"
else
    show_menu
fi
