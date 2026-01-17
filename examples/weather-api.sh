#!/bin/bash

# Weather API Example - Fetch weather data
# Uses wttr.in - a console-oriented weather service

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../api-client.sh"

WEATHER_API="https://wttr.in"

# Get weather for a location
get_weather() {
    local location="$1"
    local format="${2:-json}"

    if [ -z "$location" ]; then
        log_error "Location required"
        echo "Usage: get_weather <location> [format]"
        echo "Formats: json, text (default: json)"
        return 1
    fi

    log_info "Fetching weather for: $location"

    if [ "$format" = "json" ]; then
        api_get "$WEATHER_API/${location}?format=j1"
    else
        # Text format with ANSI colors
        curl -s "$WEATHER_API/${location}?0"
    fi
}

# Get current conditions only
get_current() {
    local location="$1"

    if [ -z "$location" ]; then
        log_error "Location required"
        return 1
    fi

    log_info "Fetching current conditions for: $location"
    api_get "$WEATHER_API/${location}?format=j1" | \
        jq '.current_condition[0] | {
            temp_C,
            temp_F,
            weatherDesc: .weatherDesc[0].value,
            humidity,
            windspeedKmph,
            windspeedMiles
        }' 2>/dev/null || echo "jq required for parsing"
}

# Get weather forecast
get_forecast() {
    local location="$1"
    local days="${2:-3}"

    if [ -z "$location" ]; then
        log_error "Location required"
        return 1
    fi

    log_info "Fetching ${days}-day forecast for: $location"
    api_get "$WEATHER_API/${location}?format=j1" | \
        jq ".weather[0:${days}] | .[] | {
            date,
            maxtemp_C: .maxtempC,
            mintemp_C: .mintempC,
            avgtemp_C: .avgtempC,
            description: .hourly[4].weatherDesc[0].value
        }" 2>/dev/null || echo "jq required for parsing"
}

# Get simple text weather
get_simple() {
    local location="${1:-}"

    if [ -z "$location" ]; then
        location=$(curl -s "https://ipinfo.io/city" 2>/dev/null || echo "New York")
    fi

    log_info "Quick weather for: $location"
    curl -s "$WEATHER_API/${location}?format=%l:+%C+%t+%h+%w"
    echo ""
}

# Get moon phase
get_moon() {
    log_info "Fetching moon phase"
    curl -s "$WEATHER_API/Moon"
}

# Compare weather in multiple locations
compare_weather() {
    if [ $# -lt 2 ]; then
        log_error "At least 2 locations required"
        echo "Usage: compare_weather <location1> <location2> [location3...]"
        return 1
    fi

    log_info "Comparing weather in multiple locations"
    echo ""

    for location in "$@"; do
        echo "=== $location ==="
        curl -s "$WEATHER_API/${location}?format=%l:+%C+%t+(feels+like+%f)"
        echo ""
    done
}

# Get weather alerts (using a different API - weatherapi.com)
# Note: Requires API key from weatherapi.com
get_alerts() {
    local location="$1"

    if [ -z "$WEATHER_API_KEY" ]; then
        log_warning "WEATHER_API_KEY not set. Using wttr.in instead (no alerts)"
        get_weather "$location"
        return
    fi

    log_info "Fetching weather alerts for: $location"
    api_get "https://api.weatherapi.com/v1/current.json?key=$WEATHER_API_KEY&q=$location&alerts=yes"
}

# Show weather in terminal-friendly format
show_weather_card() {
    local location="$1"

    if [ -z "$location" ]; then
        log_error "Location required"
        return 1
    fi

    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║        Weather for: $location"
    echo "╠════════════════════════════════════════╣"

    local data=$(curl -s "$WEATHER_API/${location}?format=j1")

    if check_jq; then
        local temp=$(echo "$data" | jq -r '.current_condition[0].temp_C')
        local feels=$(echo "$data" | jq -r '.current_condition[0].FeelsLikeC')
        local desc=$(echo "$data" | jq -r '.current_condition[0].weatherDesc[0].value')
        local humidity=$(echo "$data" | jq -r '.current_condition[0].humidity')
        local wind=$(echo "$data" | jq -r '.current_condition[0].windspeedKmph')

        echo "║ Temperature: ${temp}°C (feels like ${feels}°C)"
        echo "║ Conditions: $desc"
        echo "║ Humidity: ${humidity}%"
        echo "║ Wind Speed: ${wind} km/h"
    else
        echo "║ Install jq for detailed weather info"
    fi

    echo "╚════════════════════════════════════════╝"
    echo ""
}

# Main menu
show_menu() {
    echo ""
    echo "=== Weather API Client ==="
    echo ""
    echo "Available commands:"
    echo "  get_weather <location> [format]    - Get full weather (json/text)"
    echo "  get_current <location>             - Get current conditions"
    echo "  get_forecast <location> [days]     - Get forecast (default: 3 days)"
    echo "  get_simple [location]              - Get quick one-line weather"
    echo "  get_moon                           - Get moon phase"
    echo "  compare_weather <loc1> <loc2> ...  - Compare multiple locations"
    echo "  show_weather_card <location>       - Show formatted weather card"
    echo ""
    echo "Examples:"
    echo "  get_weather 'New York'"
    echo "  get_current London"
    echo "  get_forecast Tokyo 5"
    echo "  compare_weather Paris Tokyo 'New York'"
    echo "  show_weather_card Berlin"
    echo ""
}

# Run command if provided, otherwise show menu
if [ $# -gt 0 ]; then
    "$@"
else
    show_menu
fi
