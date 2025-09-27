#!/bin/bash

# Complete Systech Realm Backup Script
# Creates comprehensive backup including users, groups, clients, and configuration

echo "🔄 Creating Complete Systech Realm Backup"
echo "========================================"

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

KEYCLOAK_ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-secret}"
BACKUP_DIR="systech-backup-$(date +%Y%m%d-%H%M%S)"

echo "📁 Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

echo "🔑 Getting admin token..."
ADMIN_TOKEN=$(curl -s -X POST http://localhost:8090/realms/master/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" \
  -d "username=admin" \
  -d "password=$KEYCLOAK_ADMIN_PASSWORD" | jq -r '.access_token')

if [ "$ADMIN_TOKEN" = "null" ] || [ -z "$ADMIN_TOKEN" ]; then
    echo "❌ Failed to get admin token"
    exit 1
fi

echo "✅ Admin token received"

# 1. Export Realm Configuration
echo "📦 Exporting realm configuration..."
curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:8090/admin/realms/systech" > "$BACKUP_DIR/realm-config.json"

if [ -s "$BACKUP_DIR/realm-config.json" ]; then
    echo "✅ Realm configuration exported"
else
    echo "❌ Failed to export realm configuration"
    exit 1
fi

# 2. Export Users
echo "👥 Exporting users..."
curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:8090/admin/realms/systech/users" > "$BACKUP_DIR/users.json"

USER_COUNT=$(jq 'length' "$BACKUP_DIR/users.json" 2>/dev/null || echo "0")
echo "✅ Exported $USER_COUNT users"

# 3. Export Groups
echo "👥 Exporting groups..."
curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:8090/admin/realms/systech/groups" > "$BACKUP_DIR/groups.json"

GROUP_COUNT=$(jq 'length' "$BACKUP_DIR/groups.json" 2>/dev/null || echo "0")
echo "✅ Exported $GROUP_COUNT groups"

# 4. Export Clients
echo "🔧 Exporting clients..."
curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:8090/admin/realms/systech/clients" > "$BACKUP_DIR/clients.json"

CLIENT_COUNT=$(jq 'length' "$BACKUP_DIR/clients.json" 2>/dev/null || echo "0")
echo "✅ Exported $CLIENT_COUNT clients"

# 5. Export User-Group Mappings
echo "🔗 Exporting user-group mappings..."
echo "[]" > "$BACKUP_DIR/user-group-mappings.json"

if [ "$USER_COUNT" -gt 0 ]; then
    jq -c '.[]' "$BACKUP_DIR/users.json" | while read user; do
        USER_ID=$(echo "$user" | jq -r '.id')
        USERNAME=$(echo "$user" | jq -r '.username')

        echo "  📋 Getting groups for user: $USERNAME"
        USER_GROUPS=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
          "http://localhost:8090/admin/realms/systech/users/$USER_ID/groups")

        # Create mapping object
        MAPPING=$(jq -n --arg userId "$USER_ID" --arg username "$USERNAME" --argjson groups "$USER_GROUPS" \
          '{userId: $userId, username: $username, groups: $groups}')

        # Append to mappings file
        jq --argjson mapping "$MAPPING" '. += [$mapping]' "$BACKUP_DIR/user-group-mappings.json" > \
          "$BACKUP_DIR/user-group-mappings.tmp" && mv "$BACKUP_DIR/user-group-mappings.tmp" "$BACKUP_DIR/user-group-mappings.json"
    done
fi

echo "✅ User-group mappings exported"

# 6. Export Client Mappers (for systech-hrms-client)
echo "🗂️  Exporting client mappers..."
HRMS_CLIENT_ID=$(jq -r '.[] | select(.clientId == "systech-hrms-client") | .id' "$BACKUP_DIR/clients.json" 2>/dev/null)

if [ -n "$HRMS_CLIENT_ID" ] && [ "$HRMS_CLIENT_ID" != "null" ]; then
    echo "  📋 Exporting mappers for systech-hrms-client..."
    curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
      "http://localhost:8090/admin/realms/systech/clients/$HRMS_CLIENT_ID/protocol-mappers/models" > \
      "$BACKUP_DIR/systech-hrms-client-mappers.json"

    MAPPER_COUNT=$(jq 'length' "$BACKUP_DIR/systech-hrms-client-mappers.json" 2>/dev/null || echo "0")
    echo "✅ Exported $MAPPER_COUNT client mappers"
else
    echo "⚠️  systech-hrms-client not found"
    echo "[]" > "$BACKUP_DIR/systech-hrms-client-mappers.json"
fi

# 7. Create Backup Summary
echo "📋 Creating backup summary..."
cat > "$BACKUP_DIR/backup-summary.txt" << EOF
Systech Realm Backup Summary
============================
Created: $(date)
Keycloak Server: http://localhost:8090
Realm: systech

Contents:
- Realm Configuration: $(if [ -s "$BACKUP_DIR/realm-config.json" ]; then echo "✅ Included"; else echo "❌ Missing"; fi)
- Users: $USER_COUNT users
- Groups: $GROUP_COUNT groups
- Clients: $CLIENT_COUNT clients
- User-Group Mappings: ✅ Included
- Client Mappers: $MAPPER_COUNT mappers for systech-hrms-client

Files:
- realm-config.json: Realm settings and configuration
- users.json: All users in the realm
- groups.json: All groups in the realm
- clients.json: All clients in the realm
- user-group-mappings.json: User to group assignments
- systech-hrms-client-mappers.json: Protocol mappers for HRMS client
- backup-summary.txt: This summary file

Key Users:
$(jq -r '.[] | "- " + .username + " (" + .email + ")"' "$BACKUP_DIR/users.json" 2>/dev/null || echo "No users found")

Key Groups:
$(jq -r '.[] | "- " + .name + " (" + .path + ")"' "$BACKUP_DIR/groups.json" 2>/dev/null || echo "No groups found")

Key Clients:
$(jq -r '.[] | "- " + .clientId + " (" + .name + ")"' "$BACKUP_DIR/clients.json" 2>/dev/null || echo "No clients found")

To restore this backup:
1. Import realm: Use backup-restore-systech.sh (if available)
2. Or manually import each component via Keycloak Admin Console
EOF

# 8. Create single-file export for easy sharing
echo "📦 Creating single-file backup..."
tar -czf "$BACKUP_DIR.tar.gz" "$BACKUP_DIR"

echo ""
echo "🎉 BACKUP COMPLETE!"
echo "=================="
echo "📁 Backup Directory: $BACKUP_DIR"
echo "📦 Archive File: $BACKUP_DIR.tar.gz"
echo "📊 Total Size: $(du -sh "$BACKUP_DIR.tar.gz" | cut -f1)"

echo ""
echo "📋 BACKUP CONTENTS:"
echo "==================="
cat "$BACKUP_DIR/backup-summary.txt"

echo ""
echo "💡 To view backup:"
echo "   cat $BACKUP_DIR/backup-summary.txt"
echo "   ls -la $BACKUP_DIR/"

echo ""
echo "📤 To share backup:"
echo "   Archive: $BACKUP_DIR.tar.gz"
echo "   Extract: tar -xzf $BACKUP_DIR.tar.gz"

exit 0