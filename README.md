# bashy 🐚

Bash scripting as a backend - making API calls and treating bash like it's a full-fledged backend framework. Because why not? **wink**

## What is this?

An exploration of using bash scripts for API integration, request routing, and backend-like operations. This project demonstrates that bash can be more than just a scripting language - it can be a legitimate way to interact with APIs and build lightweight backend services.

## Features

- **HTTP Client Library** - Complete REST API client with GET, POST, PUT, DELETE, PATCH methods
- **Request Router** - Backend-style routing system with path parameters
- **JSON Utilities** - Parse and manipulate JSON with or without jq
- **Error Handling** - Proper HTTP status codes and error responses
- **Real Examples** - GitHub API, Weather API, and generic REST client examples

## Quick Start

### Prerequisites

```bash
# Required
curl

# Optional (for better JSON handling)
jq
```

### Run the Demo

```bash
chmod +x examples/simple-demo.sh
./examples/simple-demo.sh
```

## Project Structure

```
bashy/
├── api-client.sh          # HTTP client library with REST methods
├── router.sh              # Request routing system
├── json-utils.sh          # JSON parsing and manipulation
└── examples/
    ├── simple-demo.sh     # Quick start demo
    ├── rest-client.sh     # Full REST API client
    ├── github-api.sh      # GitHub API integration
    └── weather-api.sh     # Weather API integration
```

## Usage Examples

### Basic API Calls

```bash
# Source the API client library
source ./api-client.sh

# Make a GET request
api_get "https://api.github.com/users/octocat"

# Make a POST request
api_post "https://jsonplaceholder.typicode.com/posts" '{
  "title": "My Post",
  "body": "Content here",
  "userId": 1
}'

# Make a PUT request
api_put "https://jsonplaceholder.typicode.com/posts/1" '{
  "title": "Updated Title"
}'

# Make a DELETE request
api_delete "https://jsonplaceholder.typicode.com/posts/1"
```

### Using the Router (Backend Style)

```bash
# Source the router
source ./router.sh

# Initialize default routes
init_routes

# Handle requests
handle_request GET /health
handle_request GET /users
handle_request GET /users/123
handle_request POST /users '{"name":"Alice","email":"alice@example.com"}'
handle_request PUT /users/123 '{"name":"Updated Name"}'
handle_request DELETE /users/123
```

### GitHub API Client

```bash
chmod +x examples/github-api.sh

# Get user info
./examples/github-api.sh get_user octocat

# Get user repositories
./examples/github-api.sh get_user_repos torvalds 5

# Get repository info
./examples/github-api.sh get_repo microsoft vscode

# Search repositories
./examples/github-api.sh search_repos "bash scripts" stars

# Get trending repos
./examples/github-api.sh get_trending python weekly
```

### Weather API Client

```bash
chmod +x examples/weather-api.sh

# Get weather for a location
./examples/weather-api.sh get_weather "New York"

# Get current conditions
./examples/weather-api.sh get_current London

# Get forecast
./examples/weather-api.sh get_forecast Tokyo 5

# Compare weather in multiple cities
./examples/weather-api.sh compare_weather Paris Tokyo "New York"

# Show formatted weather card
./examples/weather-api.sh show_weather_card Berlin
```

### REST API Client

```bash
chmod +x examples/rest-client.sh

# List all posts
./examples/rest-client.sh list_posts

# Get specific post
./examples/rest-client.sh get_post 1

# Create a new post
./examples/rest-client.sh create_post "My Title" "Post content here"

# Update a post
./examples/rest-client.sh update_post 1 "New Title" "New content"

# Delete a post
./examples/rest-client.sh delete_post 1

# Full CRUD demo
./examples/rest-client.sh demo_crud
```

### JSON Utilities

```bash
# Source JSON utilities
source ./json-utils.sh

# Build JSON object
json_build "name" "Alice" "age" "30" "active" "true"

# Create JSON array
json_array 1 2 3 4 5

# Parse JSON
data='{"name":"Bob","age":25}'
json_get "$data" "name"

# Pretty print
json_pretty "$data"

# Validate JSON
json_validate "$data"

# Convert query string to JSON
query_to_json "name=Bob&age=25&city=NYC"
```

## Configuration

### Environment Variables

```bash
# API client settings
export API_TIMEOUT=30          # Request timeout in seconds
export API_VERBOSE=true        # Verbose curl output

# GitHub API
export GITHUB_TOKEN="your_token"  # For authenticated requests

# Custom API base URL
export API_BASE_URL="https://your-api.com"
```

## Advanced Features

### Custom Route Handlers

```bash
source ./router.sh

# Define custom handler
my_custom_handler() {
    local body="$1"
    respond 200 '{"message": "Custom handler executed!"}'
}

# Register custom route
register_route GET "/custom" "my_custom_handler"

# Handle the request
handle_request GET /custom
```

### Path Parameters

```bash
# Routes with parameters automatically extract values
register_route GET "/users/:id/posts/:postId" "handle_user_post"

handle_user_post() {
    local user_id="${ROUTE_PARAMS[id]}"
    local post_id="${ROUTE_PARAMS[postId]}"
    respond 200 "{\"userId\": \"$user_id\", \"postId\": \"$post_id\"}"
}
```

### Error Handling

```bash
# API calls return proper status codes
if api_get "https://api.example.com/endpoint"; then
    echo "Success!"
else
    echo "Request failed"
fi

# Check HTTP status
api_get "https://api.example.com/endpoint"
echo "Status code: $HTTP_STATUS"
```

## Why Bash for Backend?

- **Lightweight** - No heavy frameworks or dependencies
- **Universal** - Available on virtually every Unix system
- **Simple** - Easy to understand and modify
- **Fast prototyping** - Quickly test APIs and build integrations
- **Educational** - Learn about HTTP, REST, and API design
- **Fun** - Because experimenting is fun!

## Limitations

- Not suitable for production high-traffic services
- Limited concurrency handling
- No built-in database integration
- Basic JSON parsing without jq
- No complex authentication flows

## Contributing

This is an experimental project. Feel free to fork, modify, and experiment!

## License

MIT License - do whatever you want with this code!

## Inspiration

Because sometimes the best way to learn is to build something ridiculous and have fun with it. 🚀
