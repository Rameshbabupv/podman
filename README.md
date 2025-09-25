# Keycloak Setup for Spring Boot + React Application

## Overview
This documentation provides complete setup instructions for integrating Keycloak authentication with a Spring Boot backend and React frontend application.

## Architecture
```
React Frontend (3000/3001) <---> Spring Boot Backend (8080) <---> Keycloak (8090)
```

## Quick Start

### 1. Keycloak Server Management

**Start Keycloak** (runs in background):
```bash
# Make scripts executable (first time only)
chmod +x *.sh

# Start Keycloak server
./start-keycloak.sh
```

**Check Status**:
```bash
# View detailed status and health
./dev-status.sh
```

**Stop Keycloak**:
```bash
# Gracefully stop Keycloak
./stop-keycloak.sh
```

### **🔑 Simple Development Credentials:**
**All services use password: `secret`**

| Service | URL | Username | Password | Notes |
|---------|-----|----------|----------|-------|
| **PostgreSQL** | localhost:5432 | `admin` | `secret` | Database: nexus_app_dev |
| **pgAdmin** | http://localhost:8091 | `admin@systech.com` | `secret` | Database management |
| **Keycloak** | http://localhost:8090 | `admin` | `secret` | Authentication server |

**Easy to remember: admin/secret everywhere!**

**Quick Connection Examples:**
```bash
# PostgreSQL
psql -h localhost -p 5432 -U admin -d nexus_app_dev

# Connection URL
postgresql://admin:secret@localhost:5432/nexus_app_dev
```

### 2. Verify Installation
1. Run `./dev-status.sh` to check if Keycloak is ready
2. Open http://localhost:8090 in browser
3. Click "Administration Console"
4. Login with admin/secret
5. You should see the Keycloak admin dashboard

### 3. Smart Instance Management

The scripts automatically handle:
- ✅ **Duplicate prevention**: Won't start if already running
- 🔄 **Automatic cleanup**: Removes stopped containers before restart
- 🏥 **Health checking**: Waits for Keycloak to be fully ready
- 📊 **Status monitoring**: Detailed status and diagnostic information
- 🛑 **Graceful shutdown**: Safe stop with optional container removal

## Environment Configuration

### Development Environment
- **PostgreSQL**: Port 5432 (persistent data volume)
- **pgAdmin**: Port 8091 (web interface for PostgreSQL)
- **Keycloak**: Port 8090 (H2 database, development mode)
- **Spring Boot**: Port 8080 (your existing application)
- **React Frontend**: Port 3000/3001 (your existing application)

### Prerequisites
- Podman installed and running
- Java 17+ for Spring Boot
- Node.js 16+ for React

## Next Steps
After successful Keycloak startup, follow these guides in order:

1. [Realm Configuration](./realm-configuration.md) - Set up application realm and clients
2. [Spring Boot Integration](./spring-boot-integration.md) - Configure backend authentication
3. [React Integration](./react-integration.md) - Configure frontend authentication
4. [Testing Guide](./testing-troubleshooting.md) - Verify complete setup

## Important Notes
- This setup uses development mode with internal H2 database
- Data is not persistent - restarting container will reset all configurations
- For production, use external database and proper security configurations
- CORS is enabled in development mode by default

## Script Reference

### Available Scripts

| Script | Description | Usage |
|--------|-------------|-------|
| `start-keycloak.sh` | Start Keycloak (port 8090) | `./start-keycloak.sh` |
| `start-postgres.sh` | **NEW!** Start PostgreSQL (port 5432) | `./start-postgres.sh` |
| `start-pgadmin.sh` | **NEW!** Start pgAdmin (port 8091) | `./start-pgadmin.sh` |
| `stop-keycloak.sh` | Stop Keycloak gracefully | `./stop-keycloak.sh` |
| `stop-postgres.sh` | **NEW!** Stop PostgreSQL | `./stop-postgres.sh` |
| `stop-pgadmin.sh` | **NEW!** Stop pgAdmin | `./stop-pgadmin.sh` |
| `dev-status.sh` | Check detailed status and health | `./dev-status.sh` |
| `dev-env.sh` | **ENHANCED!** Complete environment manager | `./dev-env.sh` |

### Script Features

**start-keycloak.sh**:
- ✅ Checks if already running (prevents duplicates)
- 🗑️ Auto-removes stopped containers
- 🚀 Runs in detached (background) mode
- ⏳ Waits for Keycloak to be ready
- 📋 Shows next steps and useful commands

**stop-keycloak.sh**:
- 🛑 Graceful container shutdown
- 🗑️ Optional container removal
- 📊 Interactive prompts for cleanup decisions
- 💡 Helpful status messages

**dev-status.sh**:
- 🐳 Complete development environment overview
- 🖼️ All Podman images with detailed information
- 📊 All containers (PostgreSQL, pgAdmin, Keycloak, etc.)
- 💾 Volume and network management overview
- 🌐 Port usage summary across all services
- 💻 System resource usage and disk analysis
- 🔧 Comprehensive diagnostic information

**start-postgres.sh** *(NEW)*:
- ✅ Instance checking (prevents duplicates)
- 💾 Persistent data volume (pgdata)
- 🗄️ Preconfigured database (testdb) and user (admin)
- ⏳ Health checking with pg_isready
- 📋 Connection examples and credentials

**start-pgadmin.sh** *(NEW)*:
- ✅ Instance checking and smart port allocation (8091)
- 🌐 Web interface ready detection
- 🔗 PostgreSQL connection guidance
- 📋 Preconfigured admin credentials

**stop-postgres.sh** & **stop-pgadmin.sh** *(NEW)*:
- 🛑 Graceful shutdown with interactive prompts
- 🗑️ Optional container and volume cleanup
- 💾 Data preservation options

**dev-env.sh** *(ENHANCED - Complete Environment Manager)*:
- 🐳 Overview of all containers (PostgreSQL, pgAdmin, Keycloak)
- 🚀 Individual service start/stop (1-click operations)
- 🛑 Bulk operations for all containers
- 🗑️ Cleanup stopped containers
- 📋 Log viewing for any container
- 🌐 Port usage analysis with service mapping
- 💡 Interactive menu with organized options

### Manual Container Management

If needed, you can also use direct Podman commands:

```bash
# View container status
podman ps -a

# View logs
podman logs keycloak-dev

# Stop manually
podman stop keycloak-dev

# Remove manually
podman rm keycloak-dev

# Force restart (stop, remove, start fresh)
podman stop keycloak-dev && podman rm keycloak-dev && ./start-keycloak.sh
```