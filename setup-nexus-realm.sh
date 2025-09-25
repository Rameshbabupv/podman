#!/bin/bash

# Modern Nexus Realm Setup Script
# This script configures a modern, industry-standard Keycloak realm for the Nexus application

set -e

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYCLOAK_URL="http://localhost:${KEYCLOAK_PORT:-8090}"
ADMIN_USER="${KEYCLOAK_ADMIN_USER:-admin}"
ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-changeme}"
REALM_NAME="${KEYCLOAK_REALM:-nexus-dev}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_dependencies() {
    log_info "Checking dependencies..."

    if ! command -v curl >/dev/null 2>&1; then
        log_error "curl is required but not installed"
        exit 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        log_error "jq is required but not installed. Please install it: brew install jq"
        exit 1
    fi

    log_success "All dependencies are available"
}

# Wait for Keycloak to be ready
wait_for_keycloak() {
    log_info "Waiting for Keycloak to be ready..."

    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if curl -s "${KEYCLOAK_URL}/health/ready" >/dev/null 2>&1; then
            log_success "Keycloak is ready!"
            return 0
        fi

        log_info "Attempt $attempt/$max_attempts - Keycloak not ready yet..."
        sleep 2
        attempt=$((attempt + 1))
    done

    log_error "Keycloak is not ready after $max_attempts attempts"
    exit 1
}

# Get admin access token
get_admin_token() {
    log_info "Getting admin access token..."

    local response
    response=$(curl -s -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "username=${ADMIN_USER}" \
        -d "password=${ADMIN_PASSWORD}" \
        -d "grant_type=password" \
        -d "client_id=admin-cli")

    if [ $? -ne 0 ]; then
        log_error "Failed to get admin token"
        exit 1
    fi

    ADMIN_TOKEN=$(echo "$response" | jq -r '.access_token')

    if [ "$ADMIN_TOKEN" = "null" ] || [ -z "$ADMIN_TOKEN" ]; then
        log_error "Failed to extract access token from response"
        echo "Response: $response"
        exit 1
    fi

    log_success "Admin token obtained successfully"
}

# Check if realm exists
realm_exists() {
    local realm_name="$1"
    local response

    response=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer ${ADMIN_TOKEN}" \
        "${KEYCLOAK_URL}/admin/realms/${realm_name}")

    [ "$response" = "200" ]
}

# Create realm
create_realm() {
    log_info "Creating realm: ${REALM_NAME}"

    if realm_exists "$REALM_NAME"; then
        log_warning "Realm ${REALM_NAME} already exists. Skipping creation."
        return 0
    fi

    local realm_config=$(cat <<'EOF'
{
  "realm": "nexus-dev",
  "displayName": "Nexus Development Environment",
  "enabled": true,
  "sslRequired": "external",
  "registrationAllowed": false,
  "loginWithEmailAllowed": true,
  "duplicateEmailsAllowed": false,
  "resetPasswordAllowed": true,
  "rememberMe": true,
  "verifyEmail": false,
  "loginTheme": "base",
  "accessTokenLifespan": 1800,
  "refreshTokenMaxReuse": 0,
  "offlineSessionMaxLifespan": 5184000,
  "passwordPolicy": "length(8) and upperCase(1) and lowerCase(1) and digits(1) and !username and passwordHistory(3)",
  "bruteForceProtected": true,
  "failureFactor": 5,
  "waitIncrementSeconds": 60,
  "maxFailureWaitSeconds": 900,
  "maxDeltaTimeSeconds": 43200,
  "attributes": {
    "frontendUrl": "http://localhost:8090",
    "userInfoEndpoint": "http://localhost:8090/realms/nexus-dev/protocol/openid-connect/userinfo"
  }
}
EOF
)

    local response
    response=$(curl -s -X POST "${KEYCLOAK_URL}/admin/realms" \
        -H "Authorization: Bearer ${ADMIN_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$realm_config")

    if [ $? -eq 0 ]; then
        log_success "Realm ${REALM_NAME} created successfully"
    else
        log_error "Failed to create realm ${REALM_NAME}"
        exit 1
    fi
}

# Check if client exists
client_exists() {
    local client_id="$1"
    local response

    response=$(curl -s \
        -H "Authorization: Bearer ${ADMIN_TOKEN}" \
        "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/clients?clientId=${client_id}")

    local count=$(echo "$response" | jq length)
    [ "$count" -gt 0 ]
}

# Create React frontend client
create_frontend_client() {
    log_info "Creating React frontend client: nexus-web-app"

    if client_exists "nexus-web-app"; then
        log_warning "Client nexus-web-app already exists. Skipping creation."
        return 0
    fi

    local client_config=$(cat <<'EOF'
{
  "clientId": "nexus-web-app",
  "name": "Nexus Web Application",
  "description": "React frontend for Nexus application",
  "enabled": true,
  "clientAuthenticatorType": "client-secret",
  "publicClient": true,
  "standardFlowEnabled": true,
  "implicitFlowEnabled": false,
  "directAccessGrantsEnabled": false,
  "serviceAccountsEnabled": false,
  "protocol": "openid-connect",
  "attributes": {
    "pkce.code.challenge.method": "S256",
    "post.logout.redirect.uris": "http://localhost:3000/*",
    "oauth2.device.authorization.grant.enabled": "false",
    "oidc.ciba.grant.enabled": "false"
  },
  "redirectUris": [
    "http://localhost:3000/*",
    "http://localhost:3001/*"
  ],
  "webOrigins": [
    "http://localhost:3000",
    "http://localhost:3001"
  ],
  "defaultClientScopes": [
    "web-origins",
    "profile",
    "roles",
    "email"
  ],
  "optionalClientScopes": [
    "address",
    "phone",
    "offline_access"
  ]
}
EOF
)

    curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/clients" \
        -H "Authorization: Bearer ${ADMIN_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$client_config" >/dev/null

    if [ $? -eq 0 ]; then
        log_success "Frontend client created successfully"
    else
        log_error "Failed to create frontend client"
        exit 1
    fi
}

# Create Spring Boot backend client
create_backend_client() {
    log_info "Creating Spring Boot backend client: nexus-api"

    if client_exists "nexus-api"; then
        log_warning "Client nexus-api already exists. Skipping creation."
        return 0
    fi

    local client_config=$(cat <<'EOF'
{
  "clientId": "nexus-api",
  "name": "Nexus API Server",
  "description": "Spring Boot backend API server",
  "enabled": true,
  "clientAuthenticatorType": "client-secret",
  "publicClient": false,
  "standardFlowEnabled": false,
  "implicitFlowEnabled": false,
  "directAccessGrantsEnabled": false,
  "serviceAccountsEnabled": true,
  "protocol": "openid-connect",
  "bearerOnly": true,
  "attributes": {
    "access.token.lifespan": "1800",
    "oauth2.device.authorization.grant.enabled": "false",
    "oidc.ciba.grant.enabled": "false"
  },
  "defaultClientScopes": [
    "profile",
    "roles",
    "email"
  ]
}
EOF
)

    curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/clients" \
        -H "Authorization: Bearer ${ADMIN_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$client_config" >/dev/null

    if [ $? -eq 0 ]; then
        log_success "Backend client created successfully"
    else
        log_error "Failed to create backend client"
        exit 1
    fi
}

# Create admin client
create_admin_client() {
    log_info "Creating admin client: nexus-admin"

    if client_exists "nexus-admin"; then
        log_warning "Client nexus-admin already exists. Skipping creation."
        return 0
    fi

    local client_config=$(cat <<'EOF'
{
  "clientId": "nexus-admin",
  "name": "Nexus Administration",
  "description": "Administrative interface and tools",
  "enabled": true,
  "clientAuthenticatorType": "client-secret",
  "publicClient": false,
  "standardFlowEnabled": true,
  "serviceAccountsEnabled": true,
  "protocol": "openid-connect",
  "fullScopeAllowed": false,
  "redirectUris": [
    "http://localhost:3000/admin/*"
  ],
  "webOrigins": [
    "http://localhost:3000"
  ],
  "defaultClientScopes": [
    "web-origins",
    "profile",
    "roles",
    "email"
  ],
  "optionalClientScopes": [
    "address",
    "phone",
    "offline_access"
  ]
}
EOF
)

    curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/clients" \
        -H "Authorization: Bearer ${ADMIN_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$client_config" >/dev/null

    if [ $? -eq 0 ]; then
        log_success "Admin client created successfully"
    else
        log_error "Failed to create admin client"
        exit 1
    fi
}

# Check if role exists
role_exists() {
    local role_name="$1"
    local response

    response=$(curl -s \
        -H "Authorization: Bearer ${ADMIN_TOKEN}" \
        "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/roles/${role_name}")

    echo "$response" | jq -e '.name' >/dev/null 2>&1
}

# Create realm roles
create_realm_roles() {
    log_info "Creating realm roles..."

    local roles=(
        "nexus-admin:Full administrative access to Nexus system"
        "nexus-manager:Management level access with user administration"
        "nexus-user:Standard user access to Nexus application"
        "nexus-viewer:Read-only access to Nexus system"
    )

    for role_info in "${roles[@]}"; do
        local role_name="${role_info%%:*}"
        local role_description="${role_info#*:}"

        if role_exists "$role_name"; then
            log_warning "Role $role_name already exists. Skipping."
            continue
        fi

        local role_config=$(cat <<EOF
{
  "name": "$role_name",
  "description": "$role_description",
  "composite": false
}
EOF
)

        curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/roles" \
            -H "Authorization: Bearer ${ADMIN_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "$role_config" >/dev/null

        if [ $? -eq 0 ]; then
            log_success "Role $role_name created successfully"
        else
            log_error "Failed to create role $role_name"
        fi
    done
}

# Get client UUID by client ID
get_client_uuid() {
    local client_id="$1"
    local response

    response=$(curl -s \
        -H "Authorization: Bearer ${ADMIN_TOKEN}" \
        "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/clients?clientId=${client_id}")

    echo "$response" | jq -r '.[0].id'
}

# Create client roles for nexus-api
create_client_roles() {
    log_info "Creating client roles for nexus-api..."

    local client_uuid
    client_uuid=$(get_client_uuid "nexus-api")

    if [ "$client_uuid" = "null" ] || [ -z "$client_uuid" ]; then
        log_error "Could not find nexus-api client UUID"
        return 1
    fi

    local roles=(
        "api-read:Read access to API endpoints"
        "api-write:Write access to API endpoints"
        "api-admin:Administrative access to API endpoints"
    )

    for role_info in "${roles[@]}"; do
        local role_name="${role_info%%:*}"
        local role_description="${role_info#*:}"

        local role_config=$(cat <<EOF
{
  "name": "$role_name",
  "description": "$role_description",
  "composite": false
}
EOF
)

        curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/clients/${client_uuid}/roles" \
            -H "Authorization: Bearer ${ADMIN_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "$role_config" >/dev/null

        if [ $? -eq 0 ]; then
            log_success "Client role $role_name created successfully"
        else
            log_warning "Client role $role_name might already exist"
        fi
    done
}

# Create test user
create_test_user() {
    log_info "Creating test user: nexus-user"

    local user_config=$(cat <<'EOF'
{
  "username": "nexus-user",
  "email": "user@nexus.systech.com",
  "firstName": "Nexus",
  "lastName": "User",
  "enabled": true,
  "emailVerified": true,
  "attributes": {
    "employee_id": ["EMP001"],
    "department": ["Engineering"],
    "location": ["Bangalore"]
  },
  "credentials": [
    {
      "type": "password",
      "value": "nexus123",
      "temporary": false
    }
  ],
  "realmRoles": ["nexus-user"]
}
EOF
)

    curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/users" \
        -H "Authorization: Bearer ${ADMIN_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$user_config" >/dev/null

    if [ $? -eq 0 ]; then
        log_success "Test user created successfully"
        log_info "Username: nexus-user"
        log_info "Password: nexus123"
        log_info "Email: user@nexus.systech.com"
    else
        log_warning "Test user might already exist"
    fi
}

# Create test admin user
create_test_admin() {
    log_info "Creating test admin user: nexus-admin"

    local user_config=$(cat <<'EOF'
{
  "username": "nexus-admin",
  "email": "admin@nexus.systech.com",
  "firstName": "Nexus",
  "lastName": "Administrator",
  "enabled": true,
  "emailVerified": true,
  "attributes": {
    "employee_id": ["ADM001"],
    "department": ["IT"],
    "location": ["Bangalore"]
  },
  "credentials": [
    {
      "type": "password",
      "value": "admin123",
      "temporary": false
    }
  ],
  "realmRoles": ["nexus-admin", "nexus-user"]
}
EOF
)

    curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/users" \
        -H "Authorization: Bearer ${ADMIN_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$user_config" >/dev/null

    if [ $? -eq 0 ]; then
        log_success "Test admin user created successfully"
        log_info "Username: nexus-admin"
        log_info "Password: admin123"
        log_info "Email: admin@nexus.systech.com"
    else
        log_warning "Test admin user might already exist"
    fi
}

# Get backend client secret
get_backend_client_secret() {
    log_info "Getting backend client secret..."

    local client_uuid
    client_uuid=$(get_client_uuid "nexus-api")

    if [ "$client_uuid" = "null" ] || [ -z "$client_uuid" ]; then
        log_error "Could not find nexus-api client UUID"
        return 1
    fi

    local response
    response=$(curl -s \
        -H "Authorization: Bearer ${ADMIN_TOKEN}" \
        "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/clients/${client_uuid}/client-secret")

    local client_secret
    client_secret=$(echo "$response" | jq -r '.value')

    if [ "$client_secret" != "null" ] && [ -n "$client_secret" ]; then
        log_success "Backend client secret: $client_secret"
        echo ""
        log_info "Add this to your Spring Boot application.yml:"
        echo "keycloak:"
        echo "  credentials:"
        echo "    secret: $client_secret"
    else
        log_error "Could not retrieve client secret"
    fi
}

# Display setup summary
display_summary() {
    echo ""
    echo "========================================="
    log_success "Nexus Realm Setup Complete!"
    echo "========================================="
    echo ""

    log_info "Keycloak Configuration:"
    echo "  🌐 Keycloak URL: ${KEYCLOAK_URL}"
    echo "  🏛️  Realm: ${REALM_NAME}"
    echo "  🔗 Admin Console: ${KEYCLOAK_URL}/admin/master/console/#/nexus-dev"
    echo ""

    log_info "Clients Created:"
    echo "  📱 Frontend: nexus-web-app (React SPA)"
    echo "  🔧 Backend: nexus-api (Spring Boot API)"
    echo "  👨‍💼 Admin: nexus-admin (Administrative interface)"
    echo ""

    log_info "Test Users Created:"
    echo "  👤 Username: nexus-user | Password: nexus123 | Role: nexus-user"
    echo "  👨‍💼 Username: nexus-admin | Password: admin123 | Role: nexus-admin"
    echo ""

    log_info "Important URLs:"
    echo "  🔍 Discovery: ${KEYCLOAK_URL}/realms/${REALM_NAME}/.well-known/openid_configuration"
    echo "  🔑 Token: ${KEYCLOAK_URL}/realms/${REALM_NAME}/protocol/openid-connect/token"
    echo "  👤 UserInfo: ${KEYCLOAK_URL}/realms/${REALM_NAME}/protocol/openid-connect/userinfo"
    echo ""

    log_info "Next Steps:"
    echo "  1. Configure your React app with nexus-web-app client"
    echo "  2. Configure your Spring Boot app with nexus-api client"
    echo "  3. Test authentication with the created test users"
    echo "  4. Review documentation in docs/modern/ directory"
    echo ""
}

# Main execution
main() {
    echo "🚀 Modern Nexus Keycloak Realm Setup"
    echo "======================================"
    echo ""

    check_dependencies
    wait_for_keycloak
    get_admin_token

    create_realm
    create_frontend_client
    create_backend_client
    create_admin_client

    create_realm_roles
    create_client_roles

    create_test_user
    create_test_admin

    get_backend_client_secret
    display_summary
}

# Run main function
main "$@"