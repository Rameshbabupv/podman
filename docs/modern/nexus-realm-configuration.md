# Modern Nexus Keycloak Configuration

## Overview
Modern, industry-standard Keycloak setup for the Nexus application ecosystem. This configuration follows current security best practices and supports modern application architectures.

## Modern Architecture Design

### Core Principles
- 🔐 **Security First**: HTTPS, PKCE, JWT with proper claims
- 🌍 **Environment Separation**: Dev/Staging/Production configurations
- 🏗️ **Microservices Ready**: Service accounts and client credentials
- 📱 **Modern Flows**: OIDC, OAuth2, SPA and API patterns
- 🔄 **DevOps Friendly**: Docker, configuration management

## Realm Configuration

### Primary Realm: `nexus-dev`
```json
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
  "verifyEmail": true,
  "loginTheme": "nexus",
  "accessTokenLifespan": 1800,
  "refreshTokenMaxReuse": 0,
  "offlineSessionMaxLifespan": 5184000
}
```

### Security Settings
- **SSL Required**: External requests only (for development)
- **Password Policy**:
  - Minimum 8 characters
  - Must contain uppercase, lowercase, digit
  - No dictionary words
  - Password history: 3
- **Brute Force Protection**: Enabled
  - Max failures: 5
  - Wait increment: 60 seconds
  - Max wait: 900 seconds

## Client Configurations

### 1. React Frontend Client: `nexus-web-app`

```json
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
    "oauth2.device.authorization.grant.enabled": false,
    "oidc.ciba.grant.enabled": false
  },
  "redirectUris": [
    "http://localhost:3000/*",
    "http://localhost:3001/*"
  ],
  "webOrigins": [
    "http://localhost:3000",
    "http://localhost:3001"
  ]
}
```

**Security Features:**
- ✅ **Public Client**: No client secret needed for SPA
- ✅ **PKCE Enabled**: Code challenge with S256 method
- ✅ **Standard Flow Only**: Authorization code flow
- ❌ **Implicit Flow Disabled**: Security best practice
- ❌ **Direct Access Disabled**: No username/password flow

### 2. Spring Boot Backend Client: `nexus-api`

```json
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
    "client.secret.creation.time": "1642781234",
    "oauth2.device.authorization.grant.enabled": false,
    "oidc.ciba.grant.enabled": false
  }
}
```

**Security Features:**
- ✅ **Bearer Only**: API resource server
- ✅ **Service Account**: For server-to-server communication
- ✅ **Client Credentials**: Secure backend authentication
- ❌ **No Browser Flows**: Backend-only client

### 3. Administrative Client: `nexus-admin`

```json
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
  "defaultClientScopes": [
    "web-origins",
    "profile",
    "roles",
    "email"
  ],
  "optionalClientScopes": [
    "address",
    "phone",
    "offline_access",
    "microprofile-jwt"
  ]
}
```

## Role-Based Access Control (RBAC)

### Realm Roles
```json
{
  "roles": {
    "realm": [
      {
        "name": "nexus-admin",
        "description": "Full administrative access to Nexus system"
      },
      {
        "name": "nexus-user",
        "description": "Standard user access to Nexus application"
      },
      {
        "name": "nexus-manager",
        "description": "Management level access with user administration"
      },
      {
        "name": "nexus-viewer",
        "description": "Read-only access to Nexus system"
      }
    ]
  }
}
```

### Client Roles (nexus-api)
```json
{
  "clientRoles": {
    "nexus-api": [
      {
        "name": "api-read",
        "description": "Read access to API endpoints"
      },
      {
        "name": "api-write",
        "description": "Write access to API endpoints"
      },
      {
        "name": "api-admin",
        "description": "Administrative access to API endpoints"
      }
    ]
  }
}
```

## User Federation & Attributes

### User Attributes
- `employee_id`: Unique employee identifier
- `department`: User's department
- `location`: Office location
- `phone_number`: Contact number
- `preferred_language`: UI language preference

### Custom Claims in JWT
```json
{
  "employee_id": "${user.employee_id}",
  "department": "${user.department}",
  "location": "${user.location}",
  "permissions": "${user.realmRoles}",
  "api_roles": "${user.clientRoles.nexus-api}"
}
```

## Environment-Specific Configuration

### Development Environment
- **Realm**: `nexus-dev`
- **Frontend URLs**: `http://localhost:3000`, `http://localhost:3001`
- **Backend URL**: `http://localhost:8080`
- **Keycloak URL**: `http://localhost:8090`

### Staging Environment
- **Realm**: `nexus-staging`
- **Frontend URLs**: `https://staging.nexus.systech.com`
- **Backend URL**: `https://api-staging.nexus.systech.com`
- **Keycloak URL**: `https://auth-staging.nexus.systech.com`

### Production Environment
- **Realm**: `nexus-prod`
- **Frontend URLs**: `https://nexus.systech.com`
- **Backend URL**: `https://api.nexus.systech.com`
- **Keycloak URL**: `https://auth.nexus.systech.com`

## Modern Security Features

### 1. Password Policy
```json
{
  "passwordPolicy": "length(8) and upperCase(1) and lowerCase(1) and digits(1) and !username and !email and passwordHistory(3) and notUsername"
}
```

### 2. Session Management
- **SSO Session Idle**: 30 minutes
- **SSO Session Max**: 8 hours
- **Offline Session Idle**: 30 days
- **Remember Me**: 30 days

### 3. Token Configuration
- **Access Token Lifespan**: 30 minutes
- **Refresh Token Lifespan**: 8 hours
- **Client Session Idle**: 30 minutes
- **Client Session Max**: 8 hours

### 4. CORS Configuration
```json
{
  "corsAllowedOrigins": [
    "http://localhost:3000",
    "http://localhost:3001",
    "https://nexus.systech.com"
  ],
  "corsAllowedMethods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  "corsAllowedHeaders": ["Authorization", "Content-Type", "X-Requested-With"],
  "corsExposedHeaders": ["Location"],
  "corsMaxAge": 3600
}
```

## Integration Endpoints

### Discovery Endpoint
```
http://localhost:8090/realms/nexus-dev/.well-known/openid_configuration
```

### Token Endpoint
```
http://localhost:8090/realms/nexus-dev/protocol/openid-connect/token
```

### Authorization Endpoint
```
http://localhost:8090/realms/nexus-dev/protocol/openid-connect/auth
```

### User Info Endpoint
```
http://localhost:8090/realms/nexus-dev/protocol/openid-connect/userinfo
```

### Logout Endpoint
```
http://localhost:8090/realms/nexus-dev/protocol/openid-connect/logout
```

---

**✅ Modern Standards**: This configuration follows current industry best practices for security, scalability, and maintainability.