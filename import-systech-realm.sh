#!/bin/bash

# Systech Realm Import Script
# Imports a previously exported systech realm configuration

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

KEYCLOAK_ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-secret}"
IMPORT_FILE="$1"

if [ -z "$IMPORT_FILE" ]; then
    echo "❌ Usage: $0 <realm-export-file.json>"
    echo ""
    echo "📋 Available export files:"
    ls -1 systech-realm-backup-*.json 2>/dev/null || echo "   No backup files found"
    exit 1
fi

if [ ! -f "$IMPORT_FILE" ]; then
    echo "❌ Import file not found: $IMPORT_FILE"
    exit 1
fi

echo "🔄 Importing Systech Realm Configuration..."
echo "📁 Import file: $IMPORT_FILE"

# Validate JSON file
if ! jq . "$IMPORT_FILE" >/dev/null 2>&1; then
    echo "❌ Invalid JSON file: $IMPORT_FILE"
    exit 1
fi

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

# Check if realm already exists
REALM_NAME=$(jq -r '.realm // "systech"' "$IMPORT_FILE")
echo "🔍 Checking if realm '$REALM_NAME' already exists..."

EXISTING_REALM=$(curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8090/admin/realms/$REALM_NAME" 2>/dev/null)

if echo "$EXISTING_REALM" | jq . >/dev/null 2>&1; then
    echo "⚠️  Realm '$REALM_NAME' already exists!"
    echo "❓ Do you want to overwrite it? (y/N): "
    read -r CONFIRM
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
        echo "❌ Import cancelled"
        exit 1
    fi

    echo "🗑️  Deleting existing realm..."
    curl -s -X DELETE -H "Authorization: Bearer $TOKEN" \
      "http://localhost:8090/admin/realms/$REALM_NAME"

    # Wait a moment for deletion to complete
    sleep 2
fi

# Import realm
echo "📤 Importing realm '$REALM_NAME'..."
RESPONSE=$(curl -s -X POST -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d @"$IMPORT_FILE" \
  "http://localhost:8090/admin/realms")

# Check import result
if [ -z "$RESPONSE" ]; then
    echo "✅ Realm imported successfully!"

    # Verify import
    IMPORTED_REALM=$(curl -s -H "Authorization: Bearer $TOKEN" \
      "http://localhost:8090/admin/realms/$REALM_NAME")

    if echo "$IMPORTED_REALM" | jq . >/dev/null 2>&1; then
        echo "✅ Import verification successful!"
        echo ""
        echo "📋 Imported Realm Summary:"
        echo "   Realm: $(echo "$IMPORTED_REALM" | jq -r '.realm // "N/A"')"
        echo "   Display Name: $(echo "$IMPORTED_REALM" | jq -r '.displayName // "N/A"')"
        echo "   Enabled: $(echo "$IMPORTED_REALM" | jq -r '.enabled // "N/A"')"

        echo ""
        echo "🌐 Access URLs:"
        echo "   Admin Console: http://localhost:8090/admin"
        echo "   Realm URL: http://localhost:8090/realms/$REALM_NAME"

        echo ""
        echo "📝 Next steps:"
        echo "   1. Open http://localhost:8090/admin"
        echo "   2. Select '$REALM_NAME' realm"
        echo "   3. Verify users, groups, and clients were imported"

    else
        echo "⚠️  Import completed but verification failed"
    fi

else
    echo "❌ Import failed:"
    echo "$RESPONSE"
    exit 1
fi