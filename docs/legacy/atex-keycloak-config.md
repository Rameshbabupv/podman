# Legacy Atex Keycloak Configuration

## Overview
This document captures the legacy Keycloak configuration used in the Atex HRMS system for reference purposes. This setup is being migrated to a modern, industry-standard configuration.

## Production Environment Details

### Keycloak Server Configuration
- **Server URL**: `http://erp.atex.in:8080/auth`
- **Realm**: `Atex`
- **Client ID**: `HRMS`
- **Admin Realm**: `master`
- **Admin Client**: `admin-cli`

### Frontend Configuration (React/JavaScript)
```javascript
KEYCLOCK: {
    realm: 'Atex',
    url: 'http://erp.atex.in:8080/auth',
    clientId: 'HRMS'
}
```

### Backend Configuration (Node.js)
```javascript
KEYCLOCK_SOS: {
    CONFIG: {
        URL: 'http://erp.atex.in:8080/auth',
        USERNAME: "systech",
        PASSWORD: "systech",
        REALM: 'Atex',
        CLIENT_ID: "HRMS",
        OPEN_CLIENT_ID_URL: "http://erp.atex.in:8080/auth/realms/master",
        OPEN_CLIENT_ID: 'admin-cli'
    }
}
```

## Infrastructure Dependencies

### Database Servers
- **MySQL Server**:
  - Host: `192.168.1.45:3306`
  - Database: `manju_db_2021`
  - Credentials: `systech/systech`

- **MongoDB**:
  - URL: `mongodb://localhost:27017/Atexnew`

### Email Service
- **SMTP Server**: `mail.atex.in:465`
- **Email**: `itsupport@atex.in`
- **Password**: `Sana@atex`

### Application Configuration
- **Application Port**: 6070
- **Punch System**:
  - In: `"in"`
  - Out: `"out"`

## Legacy Architecture Characteristics

### Security Concerns (Historical Reference)
⚠️ **Note**: These practices are documented for reference only and should NOT be used in modern development:

1. **Hardcoded Credentials**: Plain text passwords in configuration files
2. **Weak Authentication**: Simple username/password combinations
3. **Insecure Transport**: HTTP instead of HTTPS for authentication
4. **Legacy URL Structure**: Uses `/auth` path (Keycloak < v17)
5. **Mixed Database Architecture**: MySQL + MongoDB without clear separation

### Authentication Flow (Legacy)
1. Frontend connects to Keycloak at `erp.atex.in:8080/auth`
2. Uses `Atex` realm with `HRMS` client
3. Backend uses admin-cli for administrative operations
4. No modern OAuth2/OIDC flows implemented

## Migration Considerations

### Why We're Moving Away
- **Security**: Hardcoded credentials and HTTP transport
- **Scalability**: Monolithic configuration without environment separation
- **Maintainability**: Mixed database architecture
- **Modern Standards**: Lacks OIDC, PKCE, and JWT best practices

### Modern Replacement
The new development setup uses:
- Local Keycloak with HTTPS
- Environment-based configuration
- Modern authentication flows
- Separated concerns (PostgreSQL for auth, application DBs separate)
- Industry-standard security practices

## Historical Context
- **Company**: Atex Systems
- **System**: HRMS (Human Resource Management System)
- **Environment**: Production server at `erp.atex.in`
- **Database**: Year 2021 database (`manju_db_2021`)

---

**⚠️ IMPORTANT**: This configuration is for historical reference only. Use the modern configuration documented in `/docs/modern/` for new development.