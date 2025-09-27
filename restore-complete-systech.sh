#!/bin/bash

# Complete Systech Realm Restore Script
# Restores a comprehensive backup created by backup-complete-systech.sh

echo "🔄 Restoring Complete Systech Realm Backup"
echo "=========================================="

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

KEYCLOAK_ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-secret}"
BACKUP_DIR="$1"

if [ -z "$BACKUP_DIR" ]; then
    echo "❌ Usage: $0 <backup-directory>"
    echo ""
    echo "📋 Available backup directories:"
    ls -1d systech-backup-* 2>/dev/null || echo "   No backup directories found"
    echo ""
    echo "📦 Available backup archives:"
    ls -1 systech-backup-*.tar.gz 2>/dev/null || echo "   No backup archives found"
    echo ""
    echo "💡 If using archive, extract first: tar -xzf backup-file.tar.gz"
    exit 1
fi

# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo "❌ Backup directory not found: $BACKUP_DIR"
    exit 1
fi

# Validate backup directory has required files
REQUIRED_FILES=(
    "realm-config.json"
    "users.json"
    "groups.json"
    "clients.json"
    "user-group-mappings.json"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$BACKUP_DIR/$file" ]; then
        echo "❌ Required backup file missing: $BACKUP_DIR/$file"
        exit 1
    fi
done

echo "✅ Backup directory validated: $BACKUP_DIR"

# Get admin token
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

# Get realm name from backup
REALM_NAME=$(jq -r '.realm // "systech"' "$BACKUP_DIR/realm-config.json")
echo "🎯 Target realm: $REALM_NAME"

# Check if realm already exists
echo "🔍 Checking if realm '$REALM_NAME' already exists..."
EXISTING_REALM=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:8090/admin/realms/$REALM_NAME" 2>/dev/null)

if echo "$EXISTING_REALM" | jq . >/dev/null 2>&1; then
    echo "⚠️  Realm '$REALM_NAME' already exists!"
    echo "❓ Do you want to overwrite it? (y/N): "
    read -r CONFIRM
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
        echo "❌ Restore cancelled"
        exit 1
    fi

    echo "🗑️  Deleting existing realm..."
    curl -s -X DELETE -H "Authorization: Bearer $ADMIN_TOKEN" \
      "http://localhost:8090/admin/realms/$REALM_NAME"

    # Wait for deletion to complete
    sleep 3
fi

# Step 1: Import realm configuration (without users)
echo "📦 Step 1: Importing realm configuration..."
RESPONSE=$(curl -s -X POST -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d @"$BACKUP_DIR/realm-config.json" \
  "http://localhost:8090/admin/realms")

if [ -n "$RESPONSE" ]; then
    echo "❌ Failed to import realm configuration:"
    echo "$RESPONSE"
    exit 1
fi

echo "✅ Realm configuration imported"

# Wait for realm to be ready
sleep 2

# Step 2: Import groups first (users may reference groups)
echo "👥 Step 2: Importing groups..."
GROUP_COUNT=$(jq 'length' "$BACKUP_DIR/groups.json")
if [ "$GROUP_COUNT" -gt 0 ]; then
    jq -c '.[]' "$BACKUP_DIR/groups.json" | while read group; do
        GROUP_NAME=$(echo "$group" | jq -r '.name')
        echo "  📋 Creating group: $GROUP_NAME"

        RESULT=$(curl -s -X POST -H "Authorization: Bearer $ADMIN_TOKEN" \
          -H "Content-Type: application/json" \
          -d "$group" \
          "http://localhost:8090/admin/realms/$REALM_NAME/groups")

        if [ -n "$RESULT" ]; then
            echo "    ⚠️  Warning: $RESULT"
        fi
    done
    echo "✅ Imported $GROUP_COUNT groups"
else
    echo "ℹ️  No groups to import"
fi

# Step 3: Import users
echo "👤 Step 3: Importing users..."
USER_COUNT=$(jq 'length' "$BACKUP_DIR/users.json")
if [ "$USER_COUNT" -gt 0 ]; then
    jq -c '.[]' "$BACKUP_DIR/users.json" | while read user; do
        USERNAME=$(echo "$user" | jq -r '.username')
        echo "  📋 Creating user: $USERNAME"

        # Remove server-generated fields that can't be imported
        CLEAN_USER=$(echo "$user" | jq 'del(.id, .createdTimestamp, .access)')

        RESULT=$(curl -s -X POST -H "Authorization: Bearer $ADMIN_TOKEN" \
          -H "Content-Type: application/json" \
          -d "$CLEAN_USER" \
          "http://localhost:8090/admin/realms/$REALM_NAME/users")

        if [ -n "$RESULT" ]; then
            echo "    ⚠️  Warning: $RESULT"
        fi
    done
    echo "✅ Imported $USER_COUNT users"
else
    echo "ℹ️  No users to import"
fi

# Step 4: Restore user-group mappings
echo "🔗 Step 4: Restoring user-group mappings..."
MAPPING_COUNT=$(jq 'length' "$BACKUP_DIR/user-group-mappings.json")
if [ "$MAPPING_COUNT" -gt 0 ]; then
    jq -c '.[]' "$BACKUP_DIR/user-group-mappings.json" | while read mapping; do
        USERNAME=$(echo "$mapping" | jq -r '.username')
        USER_GROUPS=$(echo "$mapping" | jq -r '.groups[].name' 2>/dev/null)

        if [ -n "$USER_GROUPS" ]; then
            echo "  📋 Restoring groups for user: $USERNAME"

            # Get new user ID
            NEW_USER_ID=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
              "http://localhost:8090/admin/realms/$REALM_NAME/users?username=$USERNAME" | \
              jq -r '.[0].id // empty')

            if [ -n "$NEW_USER_ID" ]; then
                echo "$USER_GROUPS" | while read group_name; do
                    if [ -n "$group_name" ]; then
                        # Get group ID
                        GROUP_ID=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
                          "http://localhost:8090/admin/realms/$REALM_NAME/groups?search=$group_name" | \
                          jq -r '.[] | select(.name == "'$group_name'") | .id // empty')

                        if [ -n "$GROUP_ID" ]; then
                            echo "    ➕ Adding $USERNAME to group: $group_name"
                            curl -s -X PUT -H "Authorization: Bearer $ADMIN_TOKEN" \
                              "http://localhost:8090/admin/realms/$REALM_NAME/users/$NEW_USER_ID/groups/$GROUP_ID"
                        fi
                    fi
                done
            fi
        fi
    done
    echo "✅ User-group mappings restored"
else
    echo "ℹ️  No user-group mappings to restore"
fi

# Step 5: Restore client mappers (if exists)
echo "🗂️  Step 5: Restoring client mappers..."
if [ -f "$BACKUP_DIR/systech-hrms-client-mappers.json" ]; then
    HRMS_CLIENT_ID=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
      "http://localhost:8090/admin/realms/$REALM_NAME/clients?clientId=systech-hrms-client" | \
      jq -r '.[0].id // empty')

    if [ -n "$HRMS_CLIENT_ID" ]; then
        MAPPER_COUNT=$(jq 'length' "$BACKUP_DIR/systech-hrms-client-mappers.json")
        if [ "$MAPPER_COUNT" -gt 0 ]; then
            jq -c '.[]' "$BACKUP_DIR/systech-hrms-client-mappers.json" | while read mapper; do
                MAPPER_NAME=$(echo "$mapper" | jq -r '.name')
                echo "  📋 Creating mapper: $MAPPER_NAME"

                # Remove server-generated fields
                CLEAN_MAPPER=$(echo "$mapper" | jq 'del(.id)')

                RESULT=$(curl -s -X POST -H "Authorization: Bearer $ADMIN_TOKEN" \
                  -H "Content-Type: application/json" \
                  -d "$CLEAN_MAPPER" \
                  "http://localhost:8090/admin/realms/$REALM_NAME/clients/$HRMS_CLIENT_ID/protocol-mappers/models")

                if [ -n "$RESULT" ]; then
                    echo "    ⚠️  Warning: $RESULT"
                fi
            done
            echo "✅ Imported $MAPPER_COUNT client mappers"
        fi
    else
        echo "⚠️  systech-hrms-client not found in restored realm"
    fi
else
    echo "ℹ️  No client mappers to restore"
fi

# Final verification
echo "✅ Step 6: Verifying restore..."
RESTORED_REALM=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:8090/admin/realms/$REALM_NAME")

if echo "$RESTORED_REALM" | jq . >/dev/null 2>&1; then
    # Count restored items
    RESTORED_USERS=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
      "http://localhost:8090/admin/realms/$REALM_NAME/users" | jq 'length' 2>/dev/null || echo "0")

    RESTORED_GROUPS=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
      "http://localhost:8090/admin/realms/$REALM_NAME/groups" | jq 'length' 2>/dev/null || echo "0")

    RESTORED_CLIENTS=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
      "http://localhost:8090/admin/realms/$REALM_NAME/clients" | jq 'length' 2>/dev/null || echo "0")

    echo ""
    echo "🎉 RESTORE COMPLETE!"
    echo "==================="
    echo "📁 Backup Source: $BACKUP_DIR"
    echo "🎯 Realm: $REALM_NAME"
    echo "👤 Users: $RESTORED_USERS"
    echo "👥 Groups: $RESTORED_GROUPS"
    echo "🔧 Clients: $RESTORED_CLIENTS"

    echo ""
    echo "🌐 Access URLs:"
    echo "   Admin Console: http://localhost:8090/admin"
    echo "   Realm URL: http://localhost:8090/realms/$REALM_NAME"

    echo ""
    echo "📝 Next steps:"
    echo "   1. Open http://localhost:8090/admin"
    echo "   2. Select '$REALM_NAME' realm"
    echo "   3. Verify all users, groups, and clients are present"
    echo "   4. Test user authentication"

    # Show backup summary if available
    if [ -f "$BACKUP_DIR/backup-summary.txt" ]; then
        echo ""
        echo "📋 Original Backup Summary:"
        echo "=========================="
        cat "$BACKUP_DIR/backup-summary.txt"
    fi

else
    echo "❌ Restore verification failed"
    exit 1
fi

exit 0