# 🚀 Nexus Keycloak - Quick Reference Guide

## 📱 **One-Page Reference for Developers**

---

## 🔗 **Essential URLs**
| Service | URL | Credentials |
|---------|-----|-------------|
| **Keycloak Admin** | http://localhost:8090/admin | admin / secret |
| **User Account** | http://localhost:8090/realms/nexus-dev/account | See users below |
| **Auth Endpoint** | http://localhost:8090/realms/nexus-dev/protocol/openid-connect/auth | - |
| **Token Endpoint** | http://localhost:8090/realms/nexus-dev/protocol/openid-connect/token | - |

---

## 👥 **Test Users**
| Username | Password | Role | Email |
|----------|----------|------|-------|
| `nexus-user` | `nexus123` | nexus-user | user@nexus.systech.com |
| `nexus-admin` | `admin123` | nexus-admin + nexus-user | admin@nexus.systech.com |

---

## 📱 **Client Configuration**

### **React Frontend: `nexus-web-app`**
```javascript
const keycloakConfig = {
  url: 'http://localhost:8090',
  realm: 'nexus-dev',
  clientId: 'nexus-web-app'
};
```

### **Spring Boot Backend: `nexus-api`**
```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: http://localhost:8090/realms/nexus-dev
```

---

## 🧪 **Quick Test Commands**

### **Test User Login**
```bash
curl -X POST http://localhost:8090/realms/nexus-dev/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=nexus-web-app" \
  -d "username=nexus-user" \
  -d "password=nexus123"
```

### **Test Admin Login**
```bash
curl -X POST http://localhost:8090/realms/nexus-dev/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=nexus-web-app" \
  -d "username=nexus-admin" \
  -d "password=admin123"
```

---

## 🛠️ **Server Commands**
```bash
# Start Keycloak
./start-keycloak.sh

# Check status
./dev-status.sh

# Stop Keycloak
./stop-keycloak.sh
```

---

## 🔑 **Roles & Permissions**
- **nexus-admin**: Full system access
- **nexus-manager**: User management
- **nexus-user**: Standard app usage
- **nexus-viewer**: Read-only access

---

## 🚨 **Need Client Secret?**
1. Admin Console → Clients → nexus-api → Credentials tab
2. Copy "Client secret" value
3. Use in Spring Boot application.yml

---

## ✅ **Status: Ready for Development**
- ✅ Server running on port 8090
- ✅ nexus-dev realm configured
- ✅ 2 clients ready (React + Spring Boot)
- ✅ Test users created
- ✅ Authentication tested and working