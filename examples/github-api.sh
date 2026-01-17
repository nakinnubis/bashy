#!/bin/bash

# GitHub API Example - Interact with GitHub's REST API
# Demonstrates real-world API integration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../api-client.sh"

GITHUB_API="https://api.github.com"

# Get user information
get_user() {
    local username="$1"

    if [ -z "$username" ]; then
        log_error "Username required"
        echo "Usage: get_user <username>"
        return 1
    fi

    log_info "Fetching GitHub user: $username"
    api_get "$GITHUB_API/users/$username"
}

# Get user repositories
get_user_repos() {
    local username="$1"
    local per_page="${2:-10}"

    if [ -z "$username" ]; then
        log_error "Username required"
        echo "Usage: get_user_repos <username> [per_page]"
        return 1
    fi

    log_info "Fetching repositories for: $username"
    api_get "$GITHUB_API/users/$username/repos?per_page=$per_page&sort=updated"
}

# Get repository information
get_repo() {
    local owner="$1"
    local repo="$2"

    if [ -z "$owner" ] || [ -z "$repo" ]; then
        log_error "Owner and repo required"
        echo "Usage: get_repo <owner> <repo>"
        return 1
    fi

    log_info "Fetching repository: $owner/$repo"
    api_get "$GITHUB_API/repos/$owner/$repo"
}

# Get repository issues
get_repo_issues() {
    local owner="$1"
    local repo="$2"
    local state="${3:-open}"

    if [ -z "$owner" ] || [ -z "$repo" ]; then
        log_error "Owner and repo required"
        echo "Usage: get_repo_issues <owner> <repo> [state]"
        return 1
    fi

    log_info "Fetching issues for: $owner/$repo (state: $state)"
    api_get "$GITHUB_API/repos/$owner/$repo/issues?state=$state"
}

# Search repositories
search_repos() {
    local query="$1"
    local sort="${2:-stars}"

    if [ -z "$query" ]; then
        log_error "Search query required"
        echo "Usage: search_repos <query> [sort]"
        return 1
    fi

    log_info "Searching repositories: $query"
    # URL encode the query
    local encoded_query=$(echo "$query" | sed 's/ /+/g')
    api_get "$GITHUB_API/search/repositories?q=$encoded_query&sort=$sort"
}

# Get trending repositories (using GitHub API)
get_trending() {
    local language="${1:-}"
    local since="${2:-daily}"

    log_info "Fetching trending repositories"

    local query="stars:>1000"
    if [ -n "$language" ]; then
        query="$query+language:$language"
    fi

    # Get repos created in the last week, sorted by stars
    api_get "$GITHUB_API/search/repositories?q=$query&sort=stars&order=desc&per_page=10"
}

# Get authenticated user (requires GITHUB_TOKEN)
get_authenticated_user() {
    if [ -z "$GITHUB_TOKEN" ]; then
        log_error "GITHUB_TOKEN environment variable not set"
        echo "Set your GitHub token: export GITHUB_TOKEN='your_token'"
        return 1
    fi

    log_info "Fetching authenticated user"
    local headers="Authorization: token $GITHUB_TOKEN"
    api_get "$GITHUB_API/user" "$headers"
}

# Create a gist (requires GITHUB_TOKEN)
create_gist() {
    local description="$1"
    local filename="$2"
    local content="$3"
    local public="${4:-false}"

    if [ -z "$GITHUB_TOKEN" ]; then
        log_error "GITHUB_TOKEN environment variable not set"
        return 1
    fi

    if [ -z "$description" ] || [ -z "$filename" ] || [ -z "$content" ]; then
        log_error "Description, filename, and content required"
        echo "Usage: create_gist <description> <filename> <content> [public]"
        return 1
    fi

    log_info "Creating gist: $description"

    local data="{
        \"description\": \"$description\",
        \"public\": $public,
        \"files\": {
            \"$filename\": {
                \"content\": \"$content\"
            }
        }
    }"

    local headers="Authorization: token $GITHUB_TOKEN"
    api_post "$GITHUB_API/gists" "$data" "$headers"
}

# Get repository languages
get_repo_languages() {
    local owner="$1"
    local repo="$2"

    if [ -z "$owner" ] || [ -z "$repo" ]; then
        log_error "Owner and repo required"
        echo "Usage: get_repo_languages <owner> <repo>"
        return 1
    fi

    log_info "Fetching languages for: $owner/$repo"
    api_get "$GITHUB_API/repos/$owner/$repo/languages"
}

# Main menu
show_menu() {
    echo ""
    echo "=== GitHub API Client ==="
    echo ""
    echo "Available commands:"
    echo "  get_user <username>                    - Get user info"
    echo "  get_user_repos <username> [limit]      - Get user repositories"
    echo "  get_repo <owner> <repo>                - Get repository info"
    echo "  get_repo_issues <owner> <repo> [state] - Get repository issues"
    echo "  get_repo_languages <owner> <repo>      - Get repository languages"
    echo "  search_repos <query> [sort]            - Search repositories"
    echo "  get_trending [language] [since]        - Get trending repos"
    echo ""
    echo "Authenticated commands (require GITHUB_TOKEN):"
    echo "  get_authenticated_user                 - Get your user info"
    echo "  create_gist <desc> <file> <content>    - Create a gist"
    echo ""
    echo "Examples:"
    echo "  get_user octocat"
    echo "  get_user_repos torvalds 5"
    echo "  get_repo microsoft vscode"
    echo "  search_repos 'bash scripts' stars"
    echo "  get_trending python weekly"
    echo ""
}

# Run command if provided, otherwise show menu
if [ $# -gt 0 ]; then
    "$@"
else
    show_menu
fi
