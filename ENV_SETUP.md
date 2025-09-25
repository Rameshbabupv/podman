# Environment Variables Setup

## Overview

This project uses environment variables to manage configuration and credentials securely. All sensitive information is stored in `.env` files that are excluded from version control.

## Quick Setup

### 1. Copy the Template
```bash
cp .env.example .env
```

### 2. Update Your Credentials
Edit `.env` and replace placeholder values:
```bash
# Replace these with your actual passwords
KEYCLOAK_ADMIN_PASSWORD=your_secure_password
DB_PASSWORD=your_db_password
PGADMIN_PASSWORD=your_pgadmin_password
```

### 3. Verify Setup
```bash
# Check that environment variables are loaded
source .env
echo "Keycloak Admin Password: $KEYCLOAK_ADMIN_PASSWORD"
```

## Environment Variables Reference

### 🔐 **Security Credentials**
| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `KEYCLOAK_ADMIN_PASSWORD` | Keycloak admin password | `changeme` | `mySecurePass123` |
| `DB_PASSWORD` | PostgreSQL password | `changeme` | `dbSecure456` |
| `PGADMIN_PASSWORD` | pgAdmin password | `changeme` | `adminPass789` |
| `TEST_USER_PASSWORD` | Test user password | `nexus123` | `testUser123` |
| `TEST_ADMIN_PASSWORD` | Test admin password | `admin123` | `testAdmin456` |

### 🌐 **Service Configuration**
| Variable | Description | Default |
|----------|-------------|---------|
| `KEYCLOAK_PORT` | Keycloak server port | `8090` |
| `DB_PORT` | PostgreSQL port | `5432` |
| `PGADMIN_PORT` | pgAdmin web interface port | `8091` |
| `SPRING_BOOT_PORT` | Spring Boot application port | `8080` |

### 🐳 **Container Configuration**
| Variable | Description | Default |
|----------|-------------|---------|
| `KEYCLOAK_CONTAINER_NAME` | Keycloak container name | `keycloak-dev` |
| `POSTGRES_CONTAINER_NAME` | PostgreSQL container name | `postgres-dev` |
| `PGADMIN_CONTAINER_NAME` | pgAdmin container name | `pgadmin-dev` |

## Security Best Practices

### ✅ **Do This:**
- Use strong, unique passwords for each service
- Keep `.env` file permissions restrictive (`chmod 600 .env`)
- Never commit `.env` files to version control
- Use different passwords for development and production
- Regularly rotate credentials

### ❌ **Don't Do This:**
- Don't use default passwords (`secret`, `admin`, etc.)
- Don't share `.env` files via email or messaging
- Don't commit `.env` files to Git
- Don't use the same password for multiple services
- Don't store production credentials in development files

## File Structure

```
podman/
├── .env                 # Your actual credentials (git ignored)
├── .env.example         # Template with placeholders (committed)
├── .gitignore          # Excludes .env from version control
├── start-keycloak.sh   # Loads .env automatically
├── start-postgres.sh   # Loads .env automatically
└── start-pgadmin.sh    # Loads .env automatically
```

## Troubleshooting

### Environment Variables Not Loading
```bash
# Check if .env file exists
ls -la .env

# Verify .env content
cat .env | grep -v '^#'

# Test manual load
source .env && env | grep KEYCLOAK
```

### Permission Issues
```bash
# Fix .env file permissions
chmod 600 .env

# Verify ownership
ls -la .env
```

### Container Connection Issues
```bash
# Verify environment variables are being passed
podman inspect keycloak-dev | grep -i password
```

## Production Deployment

For production environments:

1. **Use Secret Management**: Replace `.env` files with proper secret management systems (AWS Secrets Manager, Azure Key Vault, etc.)
2. **Environment Separation**: Use different credentials for each environment
3. **Automated Rotation**: Implement credential rotation policies
4. **Audit Logging**: Monitor credential access and usage

## Support

If you encounter issues:
1. Check that `.env` file exists and has correct permissions
2. Verify all placeholder values have been replaced
3. Ensure scripts have execute permissions (`chmod +x *.sh`)
4. Check container logs for authentication errors

---

**Security Note**: The `.env` file contains sensitive credentials. Never commit this file to version control or share it publicly.