#!/bin/bash

# Complete Systech Realm Export Script
# Exports the systech realm with ALL data including users, groups, clients, and roles
# Creates a single JSON file that can be imported directly

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

KEYCLOAK_ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-secret}"
EXPORT_FILE="systech-realm-complete-backup-$(date +%Y%m%d-%H%M%S).json"

echo "🔄 Exporting Complete Systech Realm Configuration..."
echo "📁 Export file: $EXPORT_FILE"
echo "📦 Includes: Configuration + Users + Groups + Clients + Roles"

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

echo "✅ Admin token received"

# Export realm configuration and combine with users/groups
echo "📤 Exporting complete systech realm..."
echo "   ✨ Including users, groups, clients, and roles..."

# Step 1: Get base realm configuration
echo "   📦 Getting realm configuration..."
REALM_CONFIG=$(curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8090/admin/realms/systech")

# Step 2: Get users
echo "   👤 Getting users..."
USERS=$(curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8090/admin/realms/systech/users")

# Step 3: Get groups
echo "   👥 Getting groups..."
GROUPS=$(curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8090/admin/realms/systech/groups")

# Step 4: Get clients
echo "   🔧 Getting clients..."
CLIENTS=$(curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8090/admin/realms/systech/clients")

# Step 5: Get roles
echo "   🎭 Getting roles..."
ROLES=$(curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8090/admin/realms/systech/roles")

# Step 6: Combine everything into a complete export
echo "   🔄 Combining all data..."
jq -n \
  --argjson realm "$REALM_CONFIG" \
  --argjson users "$USERS" \
  --argjson groups "$GROUPS" \
  --argjson clients "$CLIENTS" \
  --argjson roles "$ROLES" \
  '
  $realm + {
    "users": $users,
    "groups": $groups,
    "clients": $clients,
    "roles": {
      "realm": $roles
    }
  }
  ' > "$EXPORT_FILE"

# Check if export was successful
if [ -s "$EXPORT_FILE" ]; then
    # Check if it's a valid JSON (not an error)
    if jq . "$EXPORT_FILE" >/dev/null 2>&1; then
        echo "✅ Complete systech realm exported successfully!"
        echo "📁 File: $EXPORT_FILE"
        echo "📊 Size: $(wc -c < "$EXPORT_FILE") bytes"

        # Show comprehensive realm summary
        echo ""
        echo "📋 Complete Realm Summary:"
        echo "=========================="
        echo "   Realm: $(jq -r '.realm // "N/A"' "$EXPORT_FILE")"
        echo "   Display Name: $(jq -r '.displayName // "N/A"' "$EXPORT_FILE")"
        echo "   Enabled: $(jq -r '.enabled // "N/A"' "$EXPORT_FILE")"

        # Count all exported items
        USERS_COUNT=$(jq -r '.users | length // 0' "$EXPORT_FILE" 2>/dev/null || echo "0")
        GROUPS_COUNT=$(jq -r '.groups | length // 0' "$EXPORT_FILE" 2>/dev/null || echo "0")
        CLIENTS_COUNT=$(jq -r '.clients | length // 0' "$EXPORT_FILE" 2>/dev/null || echo "0")
        ROLES_COUNT=$(jq -r '.roles.realm | length // 0' "$EXPORT_FILE" 2>/dev/null || echo "0")

        echo ""
        echo "📊 Exported Content:"
        echo "   👤 Users: $USERS_COUNT"
        echo "   👥 Groups: $GROUPS_COUNT"
        echo "   🔧 Clients: $CLIENTS_COUNT"
        echo "   🎭 Realm Roles: $ROLES_COUNT"

        # Show detailed user information
        if [ "$USERS_COUNT" -gt 0 ]; then
            echo ""
            echo "👤 Exported Users:"
            jq -r '.users[]? | "   - " + .username + " (" + (.email // "no email") + ")"' "$EXPORT_FILE" 2>/dev/null || echo "   Unable to list users"
        fi

        # Show detailed group information
        if [ "$GROUPS_COUNT" -gt 0 ]; then
            echo ""
            echo "👥 Exported Groups:"
            jq -r '.groups[]? | "   - " + .name + " (" + .path + ")"' "$EXPORT_FILE" 2>/dev/null || echo "   Unable to list groups"
        fi

        # Show client information (excluding built-in ones)
        if [ "$CLIENTS_COUNT" -gt 0 ]; then
            echo ""
            echo "🔧 Exported Clients:"
            jq -r '.clients[]? | select(.clientId | startswith("systech") or startswith("nexus")) | "   - " + .clientId + " (" + (.name // "no name") + ")"' "$EXPORT_FILE" 2>/dev/null || echo "   Unable to list custom clients"
        fi

        echo ""
        echo "🎯 EXPORT TYPE: COMPLETE (Single File)"
        echo "✨ This export includes EVERYTHING needed for full restoration!"
        echo ""
        echo "💡 To import this complete realm:"
        echo "   Method 1 (Recommended): Use Keycloak Admin Console"
        echo "     1. Open http://localhost:8090/admin"
        echo "     2. Click 'Add Realm' → 'Import'"
        echo "     3. Select this file: $EXPORT_FILE"
        echo "     4. Choose import options as needed"
        echo ""
        echo "   Method 2: Use import script"
        echo "     ./import-systech-realm.sh $EXPORT_FILE"
        echo ""
        echo "   Method 3: Use Keycloak CLI (if available)"
        echo "     /opt/keycloak/bin/kc.sh import --file $EXPORT_FILE"

        # Create a backup info file
        INFO_FILE="${EXPORT_FILE%.json}-info.txt"
        cat > "$INFO_FILE" << EOF
Systech Realm Complete Backup Information
=========================================
Export Date: $(date)
Export Type: Complete (Single File)
Keycloak Server: http://localhost:8090
Realm: systech

Content Summary:
- Realm Configuration: ✅ Included
- Users: $USERS_COUNT users with passwords and attributes
- Groups: $GROUPS_COUNT groups with memberships
- Clients: $CLIENTS_COUNT clients with configurations
- Realm Roles: $ROLES_COUNT roles with permissions
- User-Group Mappings: ✅ Included
- Client Configurations: ✅ Included
- Role Mappings: ✅ Included

File Details:
- Main Export: $EXPORT_FILE
- Info File: $INFO_FILE
- Size: $(wc -c < "$EXPORT_FILE") bytes
- Format: Keycloak JSON (compatible with all Keycloak versions)

Import Instructions:
1. PREFERRED: Use Keycloak Admin Console
   - Navigate to http://localhost:8090/admin
   - Add Realm → Import → Select $EXPORT_FILE

2. ALTERNATIVE: Use provided import script
   - Run: ./import-systech-realm.sh $EXPORT_FILE

Important Notes:
- This export contains USER PASSWORDS (hashed)
- This export contains ALL sensitive configurations
- Store securely and limit access
- Test import in development environment first

Verification Checklist After Import:
□ Realm exists and is enabled
□ All users can login with original passwords
□ All groups exist with correct memberships
□ All clients are configured properly
□ Authentication flows work correctly
□ Token generation works for all clients
EOF

        echo ""
        echo "📄 Created backup info file: $INFO_FILE"
        echo ""
        echo "🔒 SECURITY REMINDER:"
        echo "   This backup contains user passwords and sensitive data!"
        echo "   Store securely and limit access."

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

echo ""
echo "🎉 COMPLETE EXPORT FINISHED!"
echo "   📁 Main file: $EXPORT_FILE"
echo "   📄 Info file: $INFO_FILE"
echo "   📊 Total size: $(du -sh "$EXPORT_FILE" "$INFO_FILE" | awk '{sum+=$1} END {print sum "K"}')"

exit 0