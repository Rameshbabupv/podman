# Nexus Keycloak Documentation

## Overview
Complete documentation for modern Keycloak authentication setup with React frontend and Spring Boot backend integration.

## 📁 Documentation Structure

### [`legacy/`](./legacy/) - Historical Reference
- **[`atex-keycloak-config.md`](./legacy/atex-keycloak-config.md)** - Legacy Atex HRMS configuration (reference only)

### [`modern/`](./modern/) - Current Implementation
- **[`nexus-realm-configuration.md`](./modern/nexus-realm-configuration.md)** - Modern realm setup and configuration
- **[`client-configurations.md`](./modern/client-configurations.md)** - React and Spring Boot client configurations

### [`integration/`](./integration/) - Implementation Guides
- **[`best-practices.md`](./integration/best-practices.md)** - Security best practices and patterns

## 🚀 Quick Start Guide

### 1. **Start Keycloak**
```bash
# Start the Keycloak development environment
./start-keycloak.sh

# Check status
./dev-status.sh
```

### 2. **Setup Modern Realm**
```bash
# Run the automated realm setup script
./setup-nexus-realm.sh
```

This will create:
- ✅ `nexus-dev` realm with modern security settings
- ✅ `nexus-web-app` client (React frontend)
- ✅ `nexus-api` client (Spring Boot backend)
- ✅ `nexus-admin` client (Administrative interface)
- ✅ Modern role-based access control (RBAC)
- ✅ Test users with appropriate roles

### 3. **Configure Your Applications**

#### **React Frontend**
```bash
npm install keycloak-js @types/keycloak-js
```

See [`client-configurations.md`](./modern/client-configurations.md) for complete React setup.

#### **Spring Boot Backend**
Add to `pom.xml`:
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-oauth2-resource-server</artifactId>
</dependency>
```

See [`client-configurations.md`](./modern/client-configurations.md) for complete Spring Boot setup.

## 🏗️ Architecture Overview

### Modern vs Legacy Comparison

| Aspect | Legacy (Atex) | Modern (Nexus) |
|--------|---------------|----------------|
| **URL Structure** | `/auth` path | Direct realm access |
| **Security Flow** | Username/password | OAuth2/OIDC with PKCE |
| **Client Types** | Single HRMS client | Multiple purpose-built clients |
| **Transport** | HTTP | HTTPS (production) |
| **Token Format** | Legacy | JWT with proper claims |
| **Role Management** | Basic | Comprehensive RBAC |

### Client Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   React SPA     │    │  Spring Boot    │    │   Keycloak      │
│  (nexus-web-app)│    │   (nexus-api)   │    │  (nexus-dev)    │
│                 │    │                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │ Auth Code   │ │    │ │ JWT         │ │    │ │ Token       │ │
│ │ + PKCE      │◄┼────┼►│ Validation  │◄┼────┼►│ Management  │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
│                 │    │                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │ Token       │ │    │ │ RBAC        │ │    │ │ User        │ │
│ │ Management  │ │    │ │ Enforcement │ │    │ │ Management  │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
└─────────────────┘    └─────────────────┘    └─────────────────┘
    localhost:3000         localhost:8080        localhost:8090
```

## 🔑 Key Features

### **Security Features**
- ✅ **PKCE (RFC 7636)**: Proof Key for Code Exchange
- ✅ **JWT Tokens**: With proper claims and validation
- ✅ **Role-Based Access Control**: Granular permissions
- ✅ **Token Refresh**: Automatic and secure
- ✅ **CORS Protection**: Proper cross-origin configuration
- ✅ **Session Management**: Secure session handling

### **Development Features**
- ✅ **Environment Separation**: Dev/Staging/Production configs
- ✅ **Hot Reload Support**: Development-friendly setup
- ✅ **Comprehensive Logging**: Security and performance monitoring
- ✅ **Error Handling**: Robust error management
- ✅ **Test Users**: Pre-configured for testing

### **Production Ready**
- ✅ **SSL/TLS Support**: HTTPS in production
- ✅ **High Availability**: Scalable configuration
- ✅ **Monitoring**: Health checks and metrics
- ✅ **Backup/Recovery**: Data persistence strategies

## 🛠️ Available Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| [`start-keycloak.sh`](../start-keycloak.sh) | Start Keycloak server | `./start-keycloak.sh` |
| [`stop-keycloak.sh`](../stop-keycloak.sh) | Stop Keycloak server | `./stop-keycloak.sh` |
| [`dev-status.sh`](../dev-status.sh) | Environment status | `./dev-status.sh` |
| [`setup-nexus-realm.sh`](../setup-nexus-realm.sh) | Setup modern realm | `./setup-nexus-realm.sh` |
| [`dev-env.sh`](../dev-env.sh) | Environment manager | `./dev-env.sh` |

## 🎯 Test Users

After running `setup-nexus-realm.sh`, you can use these test users:

| Username | Password | Role | Description |
|----------|----------|------|-------------|
| `nexus-user` | `nexus123` | `nexus-user` | Standard application user |
| `nexus-admin` | `admin123` | `nexus-admin` | System administrator |

## 🌐 Important URLs

### **Development Environment**
- **Admin Console**: http://localhost:8090/admin/master/console/#/nexus-dev
- **Realm URLs**: http://localhost:8090/realms/nexus-dev
- **Discovery**: http://localhost:8090/realms/nexus-dev/.well-known/openid_configuration

### **API Endpoints**
- **Token**: `POST /realms/nexus-dev/protocol/openid-connect/token`
- **Authorization**: `GET /realms/nexus-dev/protocol/openid-connect/auth`
- **UserInfo**: `GET /realms/nexus-dev/protocol/openid-connect/userinfo`
- **Logout**: `POST /realms/nexus-dev/protocol/openid-connect/logout`

## 📚 Learning Resources

### **External Documentation**
- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [OAuth 2.0 RFC](https://tools.ietf.org/html/rfc6749)
- [PKCE RFC](https://tools.ietf.org/html/rfc7636)
- [JWT RFC](https://tools.ietf.org/html/rfc7519)

### **Framework Integration**
- [Keycloak React Adapter](https://www.keycloak.org/docs/latest/securing_apps/#_javascript_adapter)
- [Spring Security OAuth2](https://docs.spring.io/spring-security/reference/servlet/oauth2/index.html)
- [Spring Boot Keycloak](https://github.com/keycloak/keycloak-documentation/blob/main/securing_apps/topics/oidc/java/spring-boot-adapter.adoc)

## 🔧 Troubleshooting

### **Common Issues**

1. **Keycloak not starting**: Check if ports 8090 is available
2. **CORS errors**: Verify allowed origins in client configuration
3. **Token validation failures**: Ensure JWT issuer matches Keycloak URL
4. **Role access denied**: Check user role assignments in Keycloak admin

### **Debug Commands**
```bash
# Check container status
./dev-status.sh

# View Keycloak logs
podman logs nexus-keycloak-dev

# Test token endpoint
curl -X POST http://localhost:8090/realms/nexus-dev/protocol/openid-connect/token \
  -d "grant_type=password" \
  -d "client_id=nexus-web-app" \
  -d "username=nexus-user" \
  -d "password=nexus123"
```

---

**🎯 Migration Path**: This documentation provides a complete migration path from legacy Atex configuration to modern, industry-standard Keycloak implementation for the Nexus application.