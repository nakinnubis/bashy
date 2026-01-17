#!/bin/bash

# Simple Demo - Quick start example showing basic API usage

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../api-client.sh"

echo ""
echo "╔═══════════════════════════════════════════╗"
echo "║   BASHY - Bash as a Backend Demo         ║"
echo "╚═══════════════════════════════════════════╝"
echo ""

log_info "This demo shows how to use bash for API calls"
echo ""

# Demo 1: Simple GET request
echo "━━━ Demo 1: Fetching data from API ━━━"
log_info "Making GET request to fetch a post..."
api_get "https://jsonplaceholder.typicode.com/posts/1"
echo ""

sleep 2

# Demo 2: POST request
echo "━━━ Demo 2: Creating new data ━━━"
log_info "Making POST request to create a post..."
api_post "https://jsonplaceholder.typicode.com/posts" '{
    "title": "My Bash Post",
    "body": "This post was created using bash!",
    "userId": 1
}'
echo ""

sleep 2

# Demo 3: Multiple requests
echo "━━━ Demo 3: Multiple API calls ━━━"
log_info "Fetching first 3 posts..."
for i in 1 2 3; do
    log_info "Fetching post $i..."
    api_get "https://jsonplaceholder.typicode.com/posts/$i" | head -20
    echo ""
done

sleep 2

# Demo 4: Error handling
echo "━━━ Demo 4: Error handling ━━━"
log_info "Attempting to fetch non-existent post..."
api_get "https://jsonplaceholder.typicode.com/posts/99999" || log_warning "Request failed as expected"
echo ""

sleep 2

# Demo 5: Using the router
echo "━━━ Demo 5: Backend-style routing ━━━"
log_info "Loading router and handling requests..."
source "$SCRIPT_DIR/../router.sh" >/dev/null 2>&1
init_routes >/dev/null 2>&1

echo ""
log_info "Handling GET /health"
handle_request GET /health
echo ""

log_info "Handling GET /users"
handle_request GET /users
echo ""

log_info "Handling GET /users/42"
handle_request GET /users/42
echo ""

# Summary
echo ""
echo "╔═══════════════════════════════════════════╗"
echo "║           Demo Complete!                  ║"
echo "╚═══════════════════════════════════════════╝"
echo ""
log_success "You've seen:"
echo "  ✓ Making GET and POST requests"
echo "  ✓ Handling JSON responses"
echo "  ✓ Error handling"
echo "  ✓ Backend-style routing"
echo ""
log_info "Try other examples:"
echo "  ./examples/rest-client.sh demo_crud"
echo "  ./examples/github-api.sh get_user octocat"
echo "  ./examples/weather-api.sh get_weather London"
echo ""
