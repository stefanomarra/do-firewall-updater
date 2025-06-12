#!/bin/bash

# Default values
CACHE_FILE="$HOME/.do_last_ip"
API_TOKEN=""
FIREWALL_ID=""

# Help message
show_help() {
cat << EOF
Usage: $0 --token=YOUR_DIGITALOCEAN_TOKEN --firewall-id=YOUR_FIREWALL_ID [--cache-file=/custom/path]

Options:
  --token=           DigitalOcean API token (required)
  --firewall-id=     Firewall ID to update (required)
  --cache-file=      Optional path to IP cache file (default: ~/.do_last_ip)
  --help             Show this help message
EOF
}

# Parse CLI arguments
for arg in "$@"; do
  case $arg in
    --token=*)
      API_TOKEN="${arg#*=}"
      ;;
    --firewall-id=*)
      FIREWALL_ID="${arg#*=}"
      ;;
    --cache-file=*)
      CACHE_FILE="${arg#*=}"
      ;;
    --help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg"
      show_help
      exit 1
      ;;
  esac
done

# Validate required args
if [ -z "$API_TOKEN" ] || [ -z "$FIREWALL_ID" ]; then
  echo "Error: --token and --firewall-id are required"
  show_help
  exit 1
fi

# Get current IP
CURRENT_IP=$(curl -s https://api.ipify.org)
if [ -z "$CURRENT_IP" ]; then
  echo "Failed to retrieve current IP"
  exit 1
fi

# Load previous IP if available
[ -f "$CACHE_FILE" ] && LAST_IP=$(cat "$CACHE_FILE") || LAST_IP=""

# Exit if IP hasn't changed
if [ "$CURRENT_IP" = "$LAST_IP" ]; then
  echo "IP unchanged: $CURRENT_IP"
  exit 0
fi

echo "Updating IP from $LAST_IP to $CURRENT_IP"

# Fetch firewall config
FIREWALL=$(curl -s -X GET \
  -H "Authorization: Bearer $API_TOKEN" \
  "https://api.digitalocean.com/v2/firewalls/$FIREWALL_ID")

# Extract inner firewall object
INNER_FIREWALL=$(echo "$FIREWALL" | sed -n 's/.*"firewall":\({.*}\)}/\1/p')

# Load old IP if exists
if [ -f "$CACHE_FILE" ]; then
  OLD_IP=$(cat "$CACHE_FILE")
else
  OLD_IP=""
fi

# Replace old IP in the full firewall JSON if needed
if [ -n "$OLD_IP" ] && [ "$OLD_IP" != "$CURRENT_IP" ]; then
  MODIFIED_FIREWALL=$(echo "$INNER_FIREWALL" | sed "s/$OLD_IP/$CURRENT_IP/g")
else
  MODIFIED_FIREWALL="$INNER_FIREWALL"
fi

# Remove read-only fields: "id", "created_at", "status", etc.
UPDATE_PAYLOAD=$(echo "$MODIFIED_FIREWALL" | \
  sed -E 's/"id":"[^"]*",//g' | \
  sed -E 's/"created_at":"[^"]*",//g' | \
  sed -E 's/"status":"[^"]*",//g')

RESPONSE=$(curl -s -X PUT \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$UPDATE_PAYLOAD" \
  "https://api.digitalocean.com/v2/firewalls/$FIREWALL_ID")

if echo "$RESPONSE" | grep -q '"firewall"'; then
  echo "$CURRENT_IP" > "$CACHE_FILE"
  echo "Firewall updated successfully."
else
  echo "Failed to update firewall:"
  echo "$RESPONSE"
  exit 1
fi
