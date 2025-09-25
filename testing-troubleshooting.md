# Testing and Troubleshooting Guide

## Overview
This guide provides comprehensive testing procedures and troubleshooting solutions for your Keycloak + Spring Boot + React setup.

## Complete Setup Verification

### Step 1: Verify Keycloak is Running
```bash
# Check if Keycloak is accessible
curl -s http://localhost:8090/realms/nexus-app/.well-known/openid_configuration | jq .

# Expected: JSON response with configuration details
```

### Step 2: Verify Spring Boot Backend
```bash
# Test public endpoint
curl http://localhost:8080/api/public/health

# Expected: {"status":"UP","message":"Application is running"}
```

### Step 3: Verify React Frontend
```bash
# Check if React app loads
curl -s http://localhost:3000 | grep -i "nexus"

# Or open browser and navigate to http://localhost:3000
```

## Authentication Flow Testing

### Test 1: Get JWT Token via Direct Grant
```bash
# Get token for testuser
TOKEN_RESPONSE=$(curl -s -X POST "http://localhost:8090/realms/nexus-app/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=nexus-backend" \
  -d "client_secret=YOUR_CLIENT_SECRET" \
  -d "username=testuser" \
  -d "password=password123")

echo $TOKEN_RESPONSE | jq .

# Extract access token
ACCESS_TOKEN=$(echo $TOKEN_RESPONSE | jq -r .access_token)
```

### Test 2: Validate Token with Backend
```bash
# Test authenticated endpoint
curl -H "Authorization: Bearer $ACCESS_TOKEN" \
  http://localhost:8080/api/auth/user-info

# Expected: User information JSON
```

### Test 3: Test Role-Based Access
```bash
# Test user endpoint (should work with testuser)
curl -H "Authorization: Bearer $ACCESS_TOKEN" \
  http://localhost:8080/api/user/profile

# Test admin endpoint (should fail with testuser)
curl -H "Authorization: Bearer $ACCESS_TOKEN" \
  http://localhost:8080/api/admin/users

# Expected: 403 Forbidden for admin endpoint
```

### Test 4: Test Admin Access
```bash
# Get token for admin user
ADMIN_TOKEN_RESPONSE=$(curl -s -X POST "http://localhost:8090/realms/nexus-app/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=nexus-backend" \
  -d "client_secret=YOUR_CLIENT_SECRET" \
  -d "username=admin" \
  -d "password=admin123")

ADMIN_TOKEN=$(echo $ADMIN_TOKEN_RESPONSE | jq -r .access_token)

# Test admin endpoint (should work)
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  http://localhost:8080/api/admin/users

# Expected: Admin data JSON
```

## React Frontend Testing

### Test 1: Login Flow
1. Open http://localhost:3000
2. Click "Login" button
3. Should redirect to Keycloak login page
4. Login with `testuser` / `password123`
5. Should redirect back to React app
6. Should show "Welcome, Test!" in navigation

### Test 2: Protected Routes
1. **User Dashboard**: Navigate to `/dashboard`
   - Should be accessible with 'user' role
   - Should display dashboard data from backend

2. **Admin Panel**: Navigate to `/admin`
   - Should be accessible only with 'admin' role
   - Test with `testuser` (should show access denied)
   - Test with `admin` user (should show admin data)

3. **Profile Page**: Navigate to `/profile`
   - Should display user information
   - Should show roles and permissions

### Test 3: API Integration
1. Open browser developer tools
2. Navigate to dashboard
3. Check Network tab for API calls
4. Verify Authorization headers are present
5. Check for successful responses (200 status)

## Token Management Testing

### Test 1: Token Refresh
```javascript
// In browser console on React app
// Check token expiration
console.log('Token expires at:', new Date(keycloak.tokenParsed.exp * 1000));

// Force token refresh
keycloak.updateToken(5).then(refreshed => {
  console.log('Token refreshed:', refreshed);
});
```

### Test 2: Token Validation
```bash
# Decode and validate token structure
echo $ACCESS_TOKEN | cut -d. -f2 | base64 -d | jq .

# Check token claims
echo $ACCESS_TOKEN | cut -d. -f2 | base64 -d | jq .realm_access.roles
```

## CORS Testing

### Test CORS Headers
```bash
# Preflight request
curl -X OPTIONS \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: Authorization" \
  http://localhost:8080/api/auth/user-info

# Check for CORS headers in response
```

## Common Issues and Solutions

### Issue 1: Keycloak Not Starting
**Symptoms**: Container fails to start or exits immediately

**Solutions**:
```bash
# Check if port 8090 is already in use
lsof -i :8090

# Check Podman logs
podman logs keycloak-dev

# Try different port
podman run -p 8091:8080 -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=admin quay.io/keycloak/keycloak:latest start-dev
```

### Issue 2: 401 Unauthorized Errors
**Symptoms**: API calls return 401 status

**Checklist**:
- [ ] Token is present in Authorization header
- [ ] Token is not expired
- [ ] Issuer URI matches in both Spring Boot and Keycloak
- [ ] Client secret is correct in Spring Boot config

**Debug Steps**:
```bash
# Check token validity
curl -X POST "http://localhost:8090/realms/nexus-app/protocol/openid-connect/token/introspect" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=nexus-backend" \
  -d "client_secret=YOUR_CLIENT_SECRET" \
  -d "token=$ACCESS_TOKEN"
```

### Issue 3: 403 Forbidden Errors
**Symptoms**: User authenticated but cannot access certain endpoints

**Solutions**:
- Verify user has required roles in Keycloak
- Check role mapping in Spring Boot Security config
- Ensure roles are properly extracted from JWT token

**Debug**:
```java
// Add to Spring Boot controller for debugging
@GetMapping("/debug/roles")
public Map<String, Object> debugRoles(@AuthenticationPrincipal Jwt jwt) {
    Map<String, Object> debug = new HashMap<>();
    debug.put("allClaims", jwt.getClaims());
    debug.put("realmAccess", jwt.getClaimAsMap("realm_access"));
    debug.put("authorities", SecurityContextHolder.getContext().getAuthentication().getAuthorities());
    return debug;
}
```

### Issue 4: CORS Errors in Browser
**Symptoms**: Browser blocks requests with CORS policy errors

**Solutions**:
```yaml
# Update Spring Boot application.yml
spring:
  web:
    cors:
      allowed-origins: "http://localhost:3000,http://localhost:3001"
      allowed-methods: "*"
      allowed-headers: "*"
      allow-credentials: true
```

**Keycloak CORS Settings**:
1. Go to Keycloak Admin Console
2. Navigate to Clients → nexus-frontend
3. Update "Web Origins" to include:
   - `http://localhost:3000`
   - `http://localhost:3001`

### Issue 5: React App Authentication Loops
**Symptoms**: Infinite redirects or login loops

**Solutions**:
```javascript
// Update keycloak init options
export const keycloakInitOptions = {
  onLoad: 'check-sso',        // Instead of 'login-required'
  silentCheckSsoRedirectUri: window.location.origin + '/silent-check-sso.html',
  checkLoginIframe: false,    // Disable iframe checking
  pkceMethod: 'S256',
};
```

### Issue 6: Token Refresh Failures
**Symptoms**: Users get logged out unexpectedly

**Debug Steps**:
```javascript
// Add detailed logging to React app
keycloak.onTokenExpired = () => {
  console.log('Token expired, attempting refresh...');
  keycloak.updateToken(30).then(refreshed => {
    if (refreshed) {
      console.log('Token successfully refreshed');
    } else {
      console.log('Token is still valid');
    }
  }).catch(error => {
    console.error('Failed to refresh token:', error);
    keycloak.login();
  });
};
```

### Issue 7: Database Connection Errors
**Symptoms**: Keycloak fails to start with H2 database errors

**Solutions**:
```bash
# Check container logs
podman logs keycloak-dev

# Try with fresh container (removes all data)
podman stop keycloak-dev
podman rm keycloak-dev
./start-keycloak.sh
```

## Monitoring and Debugging

### Enable Debug Logging

**Spring Boot** (`application.yml`):
```yaml
logging:
  level:
    org.springframework.security: DEBUG
    org.springframework.security.oauth2: DEBUG
    org.springframework.web.cors: DEBUG
```

**React** (Add to AuthContext):
```javascript
// Enable Keycloak debug logging
keycloak.enableLogging = true;

// Add event listeners for debugging
keycloak.onReady = (authenticated) => {
  console.log('Keycloak ready, authenticated:', authenticated);
};

keycloak.onAuthSuccess = () => {
  console.log('Authentication successful');
};

keycloak.onAuthError = (error) => {
  console.error('Authentication error:', error);
};

keycloak.onTokenExpired = () => {
  console.log('Token expired');
};
```

### Health Check Endpoints

Create these for monitoring:

**Spring Boot** (`HealthController.java`):
```java
@RestController
@RequestMapping("/actuator")
public class HealthController {

    @GetMapping("/keycloak-status")
    public Map<String, Object> keycloakStatus() {
        // Add logic to check Keycloak connectivity
    }
}
```

### Browser Developer Tools

**Check Authentication State**:
```javascript
// In browser console
console.log('Authenticated:', keycloak.authenticated);
console.log('Token:', keycloak.token);
console.log('User roles:', keycloak.tokenParsed?.realm_access?.roles);
console.log('Token expires:', new Date(keycloak.tokenParsed?.exp * 1000));
```

## Performance Testing

### Load Testing Token Generation
```bash
# Simple load test for token endpoint
for i in {1..10}; do
  curl -s -X POST "http://localhost:8090/realms/nexus-app/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password" \
    -d "client_id=nexus-backend" \
    -d "client_secret=YOUR_CLIENT_SECRET" \
    -d "username=testuser" \
    -d "password=password123" &
done
wait
```

## Security Validation

### Test Invalid Tokens
```bash
# Test with invalid token
curl -H "Authorization: Bearer invalid_token" \
  http://localhost:8080/api/auth/user-info

# Should return 401 Unauthorized
```

### Test Expired Tokens
```bash
# Wait for token to expire (default 5 minutes) and test
# Or manually create expired token for testing
```

## Cleanup and Reset

### Reset Keycloak Data
```bash
# Stop and remove container (loses all data)
podman stop keycloak-dev
podman rm keycloak-dev

# Start fresh
./start-keycloak.sh
# Reconfigure realm, clients, and users
```

### Reset React App State
```javascript
// Clear browser storage
localStorage.clear();
sessionStorage.clear();

// Or specifically clear Keycloak state
Object.keys(localStorage)
  .filter(key => key.includes('keycloak'))
  .forEach(key => localStorage.removeItem(key));
```

## Useful Commands Reference

```bash
# View all containers
podman ps -a

# View container logs
podman logs keycloak-dev -f

# Execute command in container
podman exec -it keycloak-dev /bin/bash

# Check Java processes
jps -v

# Monitor network connections
netstat -tulpn | grep :8090

# Check JWT token payload
echo "YOUR_JWT_TOKEN" | cut -d. -f2 | base64 -d | jq .
```

## Next Steps After Successful Testing

1. **Production Setup**: Configure external database, SSL certificates
2. **CI/CD Integration**: Add automated testing for authentication flows
3. **Monitoring**: Set up logging and monitoring for production
4. **Security Hardening**: Review and implement security best practices
5. **User Management**: Implement user registration, password reset flows
6. **Advanced Features**: Add social login, multi-factor authentication

## Support and Documentation

- **Keycloak Documentation**: https://www.keycloak.org/documentation
- **Spring Security OAuth2**: https://spring.io/guides/tutorials/spring-boot-oauth2/
- **React Keycloak**: https://github.com/react-keycloak/react-keycloak

Remember to replace `YOUR_CLIENT_SECRET` with the actual client secret from your Keycloak configuration before running the tests.