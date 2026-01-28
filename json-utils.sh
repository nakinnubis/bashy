#!/bin/bash

# JSON Utilities - Parse and manipulate JSON without jq dependency
# Provides basic JSON operations with fallback for systems without jq

# Check if jq is available
has_jq() {
    command -v jq &> /dev/null
}

# Extract value from JSON (simple key-value extraction)
json_get() {
    local json="$1"
    local key="$2"

    if has_jq; then
        echo "$json" | jq -r ".$key // empty" 2>/dev/null
    else
        # Fallback: simple regex-based extraction
        echo "$json" | grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed 's/.*"\([^"]*\)"$/\1/'
    fi
}

# Extract nested value from JSON path
json_get_path() {
    local json="$1"
    local path="$2"

    if has_jq; then
        echo "$json" | jq -r "$path // empty" 2>/dev/null
    else
        echo "Error: jq required for nested path queries" >&2
        return 1
    fi
}

# Check if JSON is valid
json_validate() {
    local json="$1"

    if has_jq; then
        echo "$json" | jq empty 2>/dev/null
        return $?
    else
        # Basic validation: check for matching braces
        local open=$(echo "$json" | tr -cd '{' | wc -c)
        local close=$(echo "$json" | tr -cd '}' | wc -c)
        [ "$open" -eq "$close" ]
    fi
}

# Pretty print JSON
json_pretty() {
    local json="$1"

    if has_jq; then
        echo "$json" | jq '.'
    else
        # Basic pretty print
        echo "$json" | sed 's/,/,\n/g' | sed 's/{/{\n/g' | sed 's/}/\n}/g'
    fi
}

# Minify JSON
json_minify() {
    local json="$1"

    if has_jq; then
        echo "$json" | jq -c '.'
    else
        echo "$json" | tr -d '\n' | tr -s ' ' | sed 's/{ /{/g' | sed 's/ }/}/g'
    fi
}

# Create JSON object from key-value pairs
json_build() {
    local output="{"
    local first=true

    while [ $# -gt 0 ]; do
        local key="$1"
        local value="$2"
        shift 2

        if [ "$first" = true ]; then
            first=false
        else
            output+=","
        fi

        # Detect if value is a number or boolean
        if [[ "$value" =~ ^[0-9]+$ ]] || [[ "$value" =~ ^(true|false|null)$ ]]; then
            output+="\"$key\":$value"
        else
            output+="\"$key\":\"$value\""
        fi
    done

    output+="}"
    echo "$output"
}

# Merge two JSON objects
json_merge() {
    local json1="$1"
    local json2="$2"

    if has_jq; then
        jq -s '.[0] * .[1]' <(echo "$json1") <(echo "$json2")
    else
        echo "Error: jq required for merging JSON" >&2
        return 1
    fi
}

# Get array length
json_array_length() {
    local json="$1"

    if has_jq; then
        echo "$json" | jq 'length'
    else
        # Count commas + 1 (very basic)
        local count=$(echo "$json" | tr -cd ',' | wc -c)
        echo $((count + 1))
    fi
}

# Get array element at index
json_array_get() {
    local json="$1"
    local index="$2"

    if has_jq; then
        echo "$json" | jq ".[$index]"
    else
        echo "Error: jq required for array operations" >&2
        return 1
    fi
}

# Filter array by condition
json_array_filter() {
    local json="$1"
    local condition="$2"

    if has_jq; then
        echo "$json" | jq "[.[] | select($condition)]"
    else
        echo "Error: jq required for array filtering" >&2
        return 1
    fi
}

# Map over array
json_array_map() {
    local json="$1"
    local expression="$2"

    if has_jq; then
        echo "$json" | jq "[.[] | $expression]"
    else
        echo "Error: jq required for array mapping" >&2
        return 1
    fi
}

# Extract all keys from JSON object
json_keys() {
    local json="$1"

    if has_jq; then
        echo "$json" | jq -r 'keys[]'
    else
        echo "$json" | grep -o '"[^"]*"[[:space:]]*:' | sed 's/"//g' | sed 's/://'
    fi
}

# Convert JSON to URL query string
json_to_query() {
    local json="$1"

    if has_jq; then
        echo "$json" | jq -r 'to_entries | map("\(.key)=\(.value | @uri)") | join("&")'
    else
        echo "Error: jq required for query string conversion" >&2
        return 1
    fi
}

# Parse URL query string to JSON
query_to_json() {
    local query="$1"

    if has_jq; then
        echo "$query" | awk -F'&' '{for(i=1;i<=NF;i++){split($i,a,"="); print a[1], a[2]}}' | \
        jq -R 'split(" ") | {(.[0]): .[1]}' | jq -s 'add'
    else
        local output="{"
        local first=true
        IFS='&' read -ra pairs <<< "$query"

        for pair in "${pairs[@]}"; do
            IFS='=' read -r key value <<< "$pair"
            if [ "$first" = true ]; then
                first=false
            else
                output+=","
            fi
            output+="\"$key\":\"$value\""
        done

        output+="}"
        echo "$output"
    fi
}

# Create JSON array from arguments
json_array() {
    local output="["
    local first=true

    for item in "$@"; do
        if [ "$first" = true ]; then
            first=false
        else
            output+=","
        fi

        # Detect if value is a number or boolean
        if [[ "$item" =~ ^[0-9]+$ ]] || [[ "$item" =~ ^(true|false|null)$ ]]; then
            output+="$item"
        else
            output+="\"$item\""
        fi
    done

    output+="]"
    echo "$output"
}

# Escape string for JSON
json_escape() {
    local str="$1"
    # Escape special characters
    str="${str//\\/\\\\}"  # Backslash
    str="${str//\"/\\\"}"  # Quote
    str="${str//$'\n'/\\n}"  # Newline
    str="${str//$'\r'/\\r}"  # Carriage return
    str="${str//$'\t'/\\t}"  # Tab
    echo "$str"
}

# Main demonstration
demo() {
    echo "=== JSON Utils Demo ==="
    echo ""

    # Build JSON
    echo "Building JSON object:"
    local user=$(json_build "name" "Alice" "age" "30" "active" "true")
    echo "$user"
    echo ""

    # Pretty print
    echo "Pretty print:"
    json_pretty "$user"
    echo ""

    # Extract values
    echo "Extract name:"
    json_get "$user" "name"
    echo ""

    # Create array
    echo "Creating JSON array:"
    local numbers=$(json_array 1 2 3 4 5)
    echo "$numbers"
    echo ""

    # Validate JSON
    echo "Validating JSON:"
    if json_validate "$user"; then
        echo "Valid JSON!"
    else
        echo "Invalid JSON!"
    fi
    echo ""

    # Query to JSON
    echo "Converting query string to JSON:"
    query_to_json "name=Bob&age=25&city=NYC"
    echo ""

    if has_jq; then
        echo "jq is available - all features enabled!"
    else
        echo "jq not available - some features limited"
    fi
}

# Run demo if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    demo
fi
