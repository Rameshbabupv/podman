# CLAUDE.md - Project Context & Commands

## 🎯 **Project Overview**

**Project Name**: Nexus Keycloak Authentication Setup
**Repository**: `git@github.com:Rameshbabupv/podman.git`
**Purpose**: Complete Keycloak authentication system for React + Spring Boot + GraphQL application
**Architecture**: Single client authentication with JWT token validation

## 🏗️ **Project Architecture**

```
React Frontend (3000/3001) <---> Spring Boot Backend (8080) <---> Keycloak (8090)
                                        |
                                 PostgreSQL (5432)
                                        |
                                   pgAdmin (8091)
```

### **Key Design Decisions** (from ADR.md):
1. **Single Client Architecture**: One client (`nexus-web-app`) instead of separate frontend/backend clients
2. **No Client Secrets**: Spring Boot validates JWTs using Keycloak's public keys
3. **Development-First**: H2 database for Keycloak, PostgreSQL for application data
4. **Environment Variables**: All credentials managed through `.env` files

## 🔐 **Security Setup**

### **Credentials Management**:
- **`.env`**: Contains actual development credentials (git ignored)
- **`.env.example`**: Template with placeholders (committed)
- **Default Development Password**: `secret` (should be changed)

### **Test Users**:
- **Regular User**: `nexus-user` / `nexus123` (role: nexus-user)
- **Admin User**: `nexus-admin` / `admin123` (roles: nexus-admin + nexus-user)

## 🐳 **Container Services**

| Service | Port | Container Name | Credentials |
|---------|------|----------------|-------------|
| **Keycloak** | 8090 | `keycloak-dev` | admin / `${KEYCLOAK_ADMIN_PASSWORD}` |
| **PostgreSQL** | 5432 | `postgres-dev` | admin / `${DB_PASSWORD}` |
| **pgAdmin** | 8091 | `pgadmin-dev` | admin@systech.com / `${PGADMIN_PASSWORD}` |

## 🚀 **Essential Commands**

### **Environment Setup**:
```bash
# First time setup
cp .env.example .env
# Edit .env with your passwords

# Check environment status
./dev-status.sh
```

### **Service Management**:
```bash
# Start services
./start-keycloak.sh     # Start Keycloak server
./start-postgres.sh     # Start PostgreSQL database
./start-pgadmin.sh      # Start pgAdmin web interface

# Stop services
./stop-keycloak.sh      # Stop Keycloak
./stop-postgres.sh      # Stop PostgreSQL
./stop-pgadmin.sh       # Stop pgAdmin

# Interactive manager
./dev-env.sh           # Menu-driven service manager
```

### **Keycloak Realm Setup**:
```bash
# Setup complete Keycloak realm
./setup-nexus-realm.sh

# Manually configure realm (if needed)
# 1. Open http://localhost:8090/admin
# 2. Login with admin/${KEYCLOAK_ADMIN_PASSWORD}
# 3. Follow realm-configuration.md
```

### **Authentication Testing**:
```bash
# Get JWT token
curl -X POST http://localhost:8090/realms/nexus-dev/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=nexus-web-app" \
  -d "username=nexus-user" \
  -d "password=nexus123"

# Test Spring Boot endpoint (when implemented)
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
     http://localhost:8080/api/user/profile

# Test GraphQL endpoint (when implemented)
curl -X POST http://localhost:8080/graphql \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ users { id name } }"}'
```

## 📁 **Key Files & Directories**

### **Configuration Files**:
- **`.env`**: Development credentials (git ignored)
- **`.env.example`**: Credential template
- **`.gitignore`**: Security exclusions
- **`nexus-realm.json`**: Keycloak realm export

### **Scripts** (all executable):
- **`start-*.sh`**: Service startup scripts
- **`stop-*.sh`**: Service shutdown scripts
- **`dev-status.sh`**: Environment monitoring
- **`setup-nexus-realm.sh`**: Automated realm configuration

### **Spring Boot Integration**:
- **`spring-boot-config/`**: Ready-to-use Spring Boot files
  - `SecurityConfig.java`: JWT security configuration
  - `JwtTokenUtil.java`: JWT utility methods
  - `application.yml`: Spring Boot configuration
  - `pom.xml`: Required dependencies

### **Documentation**:
- **`README.md`**: Project overview and quick start
- **`ENV_SETUP.md`**: Environment variables guide
- **`ADR.md`**: Architecture Decision Records
- **`CURRENT_STATUS.md`**: Implementation status
- **`IMPLEMENTATION_CHECKLIST.md`**: Spring Boot integration steps
- **`QUICK_REFERENCE.md`**: Developer quick reference

## 🔧 **Development Workflow**

### **New Developer Setup**:
1. Clone repository: `git clone git@github.com:Rameshbabupv/podman.git`
2. Environment setup: `cp .env.example .env` and edit passwords
3. Start Keycloak: `./start-keycloak.sh`
4. Setup realm: `./setup-nexus-realm.sh`
5. Test authentication with curl commands above

### **Daily Development**:
1. Check services: `./dev-status.sh`
2. Start needed services: `./start-keycloak.sh`
3. Develop your Spring Boot/React application
4. Test with JWT tokens from Keycloak
5. Stop services when done: `./stop-keycloak.sh`

### **Adding JWT to Spring Boot**:
1. Follow `IMPLEMENTATION_CHECKLIST.md`
2. Copy files from `spring-boot-config/` to your project
3. Update dependencies in your `pom.xml`
4. Configure `application.yml` with Keycloak settings
5. Test with provided test endpoints

## ⚡ **Quick Troubleshooting**

### **Common Issues**:
- **Port conflicts**: Check if ports 8090, 5432, 8091 are free
- **Podman not running**: Start Podman machine first
- **Authentication failures**: Verify user credentials and token expiration
- **CORS errors**: Check Spring Boot CORS configuration
- **Container won't start**: Check logs with `podman logs container-name`

### **Debug Commands**:
```bash
# Check container status
podman ps -a

# View container logs
podman logs keycloak-dev
podman logs postgres-dev

# Check environment variables
source .env && env | grep -E "(KEYCLOAK|DB_|PGADMIN)"

# Verify Keycloak is ready
curl -s http://localhost:8090/health/ready

# Test database connection
psql -h localhost -p 5432 -U admin -d nexus_app_dev
```

## 🎯 **Implementation Status**

**✅ Completed**:
- Keycloak server setup and configuration
- Realm and client configuration (`nexus-dev`, `nexus-web-app`)
- Test users and roles setup
- Environment variables security setup
- Complete documentation
- Container orchestration scripts
- Spring Boot configuration files prepared

**⏳ Pending** (when you're ready):
- Spring Boot JWT integration
- GraphQL endpoint security
- React frontend authentication
- Production deployment configuration

## 🔗 **Related Projects**

This authentication setup integrates with:
- **nexus-backend**: `git@github.com:Rameshbabupv/nexus-backend.git`
- **nexus-frontend**: `git@github.com:Rameshbabu/nexus-frontend.git`

## 🆘 **Getting Help**

1. **Documentation**: Start with `README.md` and `QUICK_REFERENCE.md`
2. **Implementation Guide**: Follow `IMPLEMENTATION_CHECKLIST.md`
3. **Architecture**: Review `ADR.md` for design decisions
4. **Environment Issues**: Check `ENV_SETUP.md`
5. **Testing**: Use examples in `testing-troubleshooting.md`

## 🎉 **Success Criteria**

You'll know everything is working when:
- ✅ `./dev-status.sh` shows all services healthy
- ✅ You can login to Keycloak admin console
- ✅ JWT tokens are successfully generated via curl
- ✅ Spring Boot validates JWT tokens (when implemented)
- ✅ React app authenticates users (when implemented)

---

**Last Updated**: 2025-09-25
**Created by**: Claude Code
**Maintainer**: Rameshbabu PV