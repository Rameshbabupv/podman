#!/bin/bash

# Verify Systech Realm Setup Script
# Checks if realm, groups, roles, and client are properly configured

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

KEYCLOAK_ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-secret}"
REALM_NAME="systech"
CLIENT_ID="systech-hrms-client"

echo "🔍 Verifying Systech Realm Setup"
echo "================================"

# Get admin token
echo "🔑 Getting admin token..."
TOKEN=$(curl -s -X POST http://localhost:8090/realms/master/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" \
  -d "username=admin" \
  -d "password=$KEYCLOAK_ADMIN_PASSWORD" | jq -r '.access_token')

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
    echo "❌ Failed to get admin token"
    exit 1
fi

echo "✅ Admin token received"

# Check realm exists
echo ""
echo "🏛️  Checking Realm Configuration..."
REALM_INFO=$(curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8090/admin/realms/$REALM_NAME")

if echo "$REALM_INFO" | jq . >/dev/null 2>&1; then
    REALM_DISPLAY_NAME=$(echo "$REALM_INFO" | jq -r '.displayName // "N/A"')
    REALM_ENABLED=$(echo "$REALM_INFO" | jq -r '.enabled // false')
    echo "✅ Realm exists: $REALM_NAME"
    echo "   Display Name: $REALM_DISPLAY_NAME"
    echo "   Enabled: $REALM_ENABLED"
else
    echo "❌ Realm '$REALM_NAME' not found"
    exit 1
fi

# Check client exists
echo ""
echo "🔧 Checking Client Configuration..."
CLIENT_INFO=$(curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8090/admin/realms/$REALM_NAME/clients?clientId=$CLIENT_ID")

CLIENT_COUNT=$(echo "$CLIENT_INFO" | jq 'length // 0' 2>/dev/null)
if [ "$CLIENT_COUNT" -gt 0 ]; then
    CLIENT_NAME=$(echo "$CLIENT_INFO" | jq -r '.[0].name // "N/A"')
    CLIENT_ACCESS_TYPE=$(echo "$CLIENT_INFO" | jq -r '.[0].publicClient // false')
    echo "✅ Client exists: $CLIENT_ID"
    echo "   Name: $CLIENT_NAME"
    echo "   Public Client: $CLIENT_ACCESS_TYPE"
else
    echo "❌ Client '$CLIENT_ID' not found"
fi

# Check roles
echo ""
echo "🎭 Checking Realm Roles..."
ROLES=$(curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8090/admin/realms/$REALM_NAME/roles")

EXPECTED_ROLES=("systech-admin" "systech-manager" "systech-user")
for role in "${EXPECTED_ROLES[@]}"; do
    if echo "$ROLES" | jq -e --arg role "$role" '.[] | select(.name == $role)' >/dev/null; then
        echo "✅ Role exists: $role"
    else
        echo "❌ Role missing: $role"
    fi
done

# Check groups
echo ""
echo "👥 Checking Groups..."
GROUPS=$(curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8090/admin/realms/$REALM_NAME/groups")

EXPECTED_GROUPS=("IT" "HR" "Finance" "Operations" "Admin-Access" "Manager-Access" "User-Access")
GROUP_COUNT=$(echo "$GROUPS" | jq 'length // 0' 2>/dev/null)
echo "📊 Total Groups Found: $GROUP_COUNT"

for group in "${EXPECTED_GROUPS[@]}"; do
    if echo "$GROUPS" | jq -e --arg group "$group" '.[] | select(.name == $group)' >/dev/null; then
        echo "✅ Group exists: $group"
    else
        echo "❌ Group missing: $group"
    fi
done

# Check client mappers
echo ""
echo "🗂️  Checking Client Mappers..."
if [ "$CLIENT_COUNT" -gt 0 ]; then
    CLIENT_UUID=$(echo "$CLIENT_INFO" | jq -r '.[0].id')
    MAPPERS=$(curl -s -H "Authorization: Bearer $TOKEN" \
      "http://localhost:8090/admin/realms/$REALM_NAME/clients/$CLIENT_UUID/protocol-mappers/models")

    EXPECTED_MAPPERS=("group-membership" "user-roles" "username" "email" "full-name")
    MAPPER_COUNT=$(echo "$MAPPERS" | jq 'length // 0' 2>/dev/null)
    echo "📊 Total Mappers Found: $MAPPER_COUNT"

    for mapper in "${EXPECTED_MAPPERS[@]}"; do
        if echo "$MAPPERS" | jq -e --arg mapper "$mapper" '.[] | select(.name == $mapper)' >/dev/null; then
            echo "✅ Mapper exists: $mapper"
        else
            echo "❌ Mapper missing: $mapper"
        fi
    done
else
    echo "⚠️  Cannot check mappers - client not found"
fi

# Check users
echo ""
echo "👤 Checking Users..."
USERS=$(curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8090/admin/realms/$REALM_NAME/users")

USER_COUNT=$(echo "$USERS" | jq 'length // 0' 2>/dev/null)
echo "📊 Total Users: $USER_COUNT"

if [ "$USER_COUNT" -gt 0 ]; then
    echo "👤 Users found:"
    echo "$USERS" | jq -r '.[] | "   - " + .username + " (" + (.email // "no email") + ")"' 2>/dev/null
else
    echo "ℹ️  No users found - you can create them manually"
fi

# Test realm endpoint
echo ""
echo "🌐 Testing Realm Endpoints..."
REALM_ENDPOINT=$(curl -s "http://localhost:8090/realms/$REALM_NAME" | jq -r '.realm // "error"')
if [ "$REALM_ENDPOINT" = "$REALM_NAME" ]; then
    echo "✅ Realm endpoint accessible: http://localhost:8090/realms/$REALM_NAME"
else
    echo "❌ Realm endpoint not accessible"
fi

# Token endpoint test
TOKEN_ENDPOINT_TEST=$(curl -s -o /dev/null -w "%{http_code}" \
  "http://localhost:8090/realms/$REALM_NAME/protocol/openid-connect/token")
if [ "$TOKEN_ENDPOINT_TEST" = "405" ] || [ "$TOKEN_ENDPOINT_TEST" = "400" ]; then
    echo "✅ Token endpoint accessible (HTTP $TOKEN_ENDPOINT_TEST - expected for GET request)"
else
    echo "⚠️  Token endpoint response: HTTP $TOKEN_ENDPOINT_TEST"
fi

# Summary
echo ""
echo "📋 SETUP VERIFICATION SUMMARY"
echo "============================="

# Calculate completion percentage
CHECKS=0
PASSED=0

# Realm check
CHECKS=$((CHECKS + 1))
if echo "$REALM_INFO" | jq . >/dev/null 2>&1; then
    PASSED=$((PASSED + 1))
fi

# Client check
CHECKS=$((CHECKS + 1))
if [ "$CLIENT_COUNT" -gt 0 ]; then
    PASSED=$((PASSED + 1))
fi

# Roles check
CHECKS=$((CHECKS + 3))  # 3 expected roles
for role in "${EXPECTED_ROLES[@]}"; do
    if echo "$ROLES" | jq -e --arg role "$role" '.[] | select(.name == $role)' >/dev/null; then
        PASSED=$((PASSED + 1))
    fi
done

# Groups check
CHECKS=$((CHECKS + 7))  # 7 expected groups
for group in "${EXPECTED_GROUPS[@]}"; do
    if echo "$GROUPS" | jq -e --arg group "$group" '.[] | select(.name == $group)' >/dev/null; then
        PASSED=$((PASSED + 1))
    fi
done

# Mappers check
if [ "$CLIENT_COUNT" -gt 0 ]; then
    CHECKS=$((CHECKS + 5))  # 5 expected mappers
    for mapper in "${EXPECTED_MAPPERS[@]}"; do
        if echo "$MAPPERS" | jq -e --arg mapper "$mapper" '.[] | select(.name == $mapper)' >/dev/null; then
            PASSED=$((PASSED + 1))
        fi
    done
fi

PERCENTAGE=$((PASSED * 100 / CHECKS))

echo "📊 Completion: $PASSED/$CHECKS checks passed ($PERCENTAGE%)"

if [ "$PERCENTAGE" -ge 90 ]; then
    echo "🎉 Excellent! Your realm setup is nearly complete."
elif [ "$PERCENTAGE" -ge 70 ]; then
    echo "👍 Good! Most components are configured correctly."
elif [ "$PERCENTAGE" -ge 50 ]; then
    echo "⚠️  Partial setup - some components need attention."
else
    echo "❌ Setup incomplete - please review the manual setup guide."
fi

echo ""
echo "📝 Next Steps:"
echo "1. Create users in the Keycloak admin console"
echo "2. Assign users to appropriate groups"
echo "3. Test authentication with a user"
echo "4. Verify JWT tokens contain expected claims"

echo ""
echo "🧪 Test Authentication:"
echo "curl -X POST http://localhost:8090/realms/$REALM_NAME/protocol/openid-connect/token \\"
echo "  -H \"Content-Type: application/x-www-form-urlencoded\" \\"
echo "  -d \"grant_type=password\" \\"
echo "  -d \"client_id=$CLIENT_ID\" \\"
echo "  -d \"username=YOUR_USERNAME\" \\"
echo "  -d \"password=YOUR_PASSWORD\""

exit 0