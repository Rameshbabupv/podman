#!/bin/bash

# Systech Realm Export Script
# Exports the systech realm configuration to a JSON file for backup/import

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

KEYCLOAK_ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-secret}"
EXPORT_FILE="systech-realm-backup-$(date +%Y%m%d-%H%M%S).json"

echo "🔄 Exporting Systech Realm Configuration..."
echo "📁 Export file: $EXPORT_FILE"

# Get admin token
echo "🔑 Getting admin token..."
TOKEN=$(curl -s -X POST http://localhost:8090/realms/master/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" \
  -d "username=admin" \
  -d "password=$KEYCLOAK_ADMIN_PASSWORD" | jq -r '.access_token')

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
    echo "❌ Failed to get admin token. Check Keycloak is running and credentials are correct."
    exit 1
fi

# Export realm
echo "📤 Exporting systech realm..."
curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8090/admin/realms/systech" > "$EXPORT_FILE"

# Check if export was successful
if [ -s "$EXPORT_FILE" ]; then
    # Check if it's a valid JSON (not an error)
    if jq . "$EXPORT_FILE" >/dev/null 2>&1; then
        echo "✅ Systech realm exported successfully!"
        echo "📁 File: $EXPORT_FILE"
        echo "📊 Size: $(wc -c < "$EXPORT_FILE") bytes"

        # Show realm summary
        echo ""
        echo "📋 Realm Summary:"
        echo "   Realm: $(jq -r '.realm // "N/A"' "$EXPORT_FILE")"
        echo "   Display Name: $(jq -r '.displayName // "N/A"' "$EXPORT_FILE")"
        echo "   Enabled: $(jq -r '.enabled // "N/A"' "$EXPORT_FILE")"

        # Count users and groups
        USERS_COUNT=$(jq -r '.users | length // 0' "$EXPORT_FILE" 2>/dev/null || echo "0")
        GROUPS_COUNT=$(jq -r '.groups | length // 0' "$EXPORT_FILE" 2>/dev/null || echo "0")
        CLIENTS_COUNT=$(jq -r '.clients | length // 0' "$EXPORT_FILE" 2>/dev/null || echo "0")

        echo "   Users: $USERS_COUNT"
        echo "   Groups: $GROUPS_COUNT"
        echo "   Clients: $CLIENTS_COUNT"

        echo ""
        echo "💡 To import this realm:"
        echo "   1. Use Keycloak Admin Console > Add Realm > Import"
        echo "   2. Or use: ./import-systech-realm.sh $EXPORT_FILE"

    else
        echo "❌ Export failed - received error response:"
        cat "$EXPORT_FILE"
        rm "$EXPORT_FILE"
        exit 1
    fi
else
    echo "❌ Export failed - no data received"
    rm "$EXPORT_FILE" 2>/dev/null
    exit 1
fi