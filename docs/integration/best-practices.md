# Integration Best Practices

## Overview
This document outlines modern security best practices for integrating React frontend and Spring Boot backend with Keycloak authentication.

## Security Best Practices

### 1. Authentication Flow Recommendations

#### ✅ **Recommended: Authorization Code Flow with PKCE**
- **For SPAs (React)**: Use Authorization Code Flow with PKCE (RFC 7636)
- **Why**: Most secure flow for public clients
- **Implementation**: Enable PKCE in Keycloak client settings

```javascript
// React - Correct PKCE implementation
const initOptions = {
  onLoad: 'check-sso',
  pkceMethod: 'S256',
  flow: 'standard',
  checkLoginIframe: false, // Better performance
};
```

#### ❌ **Avoid: Implicit Flow**
- **Why**: Tokens in URL fragments, security vulnerabilities
- **Alternative**: Use Authorization Code Flow with PKCE instead

#### ❌ **Avoid: Resource Owner Password Credentials**
- **Why**: Requires exposing user credentials to application
- **Alternative**: Use standard OAuth2 flows

### 2. Token Management

#### **Access Token Security**
```javascript
// ✅ Correct: Store tokens in memory
class TokenManager {
  private accessToken: string | null = null;
  private refreshToken: string | null = null;

  // ❌ Don't store in localStorage or sessionStorage
  // localStorage.setItem('token', token); // AVOID THIS
}
```

#### **Token Refresh Strategy**
```javascript
// ✅ Automatic token refresh before expiration
api.interceptors.request.use(async (config) => {
  // Refresh token if expires within 30 seconds
  if (keycloak.isTokenExpired(30)) {
    try {
      await keycloak.updateToken(30);
      config.headers.Authorization = `Bearer ${keycloak.token}`;
    } catch (error) {
      keycloak.logout();
      throw error;
    }
  }
  return config;
});
```

#### **Token Validation**
```java
// Spring Boot - Validate token claims
@Component
public class TokenValidator {

    public boolean validateToken(Jwt jwt) {
        // Check token expiration
        if (jwt.getExpiresAt().isBefore(Instant.now())) {
            return false;
        }

        // Validate issuer
        if (!jwt.getIssuer().toString().equals(expectedIssuer)) {
            return false;
        }

        // Validate audience
        List<String> audiences = jwt.getAudience();
        if (!audiences.contains(expectedAudience)) {
            return false;
        }

        return true;
    }
}
```

### 3. CORS Configuration

#### **Frontend Configuration**
```javascript
// ✅ Specific origins, not wildcards
const corsConfig = {
  allowedOrigins: [
    'http://localhost:3000',
    'https://nexus.systech.com'
  ],
  credentials: true, // Required for auth cookies
  allowedHeaders: ['Authorization', 'Content-Type']
};
```

#### **Backend Configuration**
```java
// ✅ Explicit CORS configuration
@Bean
public CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration configuration = new CorsConfiguration();

    // ❌ Don't use: configuration.setAllowedOrigins(Arrays.asList("*"));
    configuration.setAllowedOriginPatterns(Arrays.asList(
        "http://localhost:3000",
        "https://*.systech.com"
    ));

    configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE"));
    configuration.setAllowedHeaders(Arrays.asList("*"));
    configuration.setAllowCredentials(true);

    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/**", configuration);
    return source;
}
```

### 4. Role-Based Access Control (RBAC)

#### **Frontend Route Protection**
```typescript
// ✅ Granular route protection
interface ProtectedRouteProps {
  requiredRoles?: string[];
  requiredPermissions?: string[];
  fallback?: React.ComponentType;
}

const ProtectedRoute: React.FC<ProtectedRouteProps> = ({
  children,
  requiredRoles = [],
  requiredPermissions = [],
  fallback: Fallback = AccessDenied
}) => {
  const { hasRole, hasPermission } = useAuth();

  // Check roles
  const hasRequiredRole = requiredRoles.length === 0 ||
    requiredRoles.some(role => hasRole(role));

  // Check permissions
  const hasRequiredPermission = requiredPermissions.length === 0 ||
    requiredPermissions.some(permission => hasPermission(permission));

  if (!hasRequiredRole || !hasRequiredPermission) {
    return <Fallback />;
  }

  return <>{children}</>;
};

// Usage
<ProtectedRoute requiredRoles={['nexus-admin']}>
  <AdminPanel />
</ProtectedRoute>
```

#### **Backend Method Security**
```java
// ✅ Method-level security
@RestController
@RequestMapping("/api")
public class UserController {

    @GetMapping("/users")
    @PreAuthorize("hasRole('nexus-manager') or hasRole('nexus-admin')")
    public ResponseEntity<List<User>> getUsers() {
        // Implementation
    }

    @PostMapping("/users")
    @PreAuthorize("hasRole('nexus-admin')")
    public ResponseEntity<User> createUser(@RequestBody User user) {
        // Implementation
    }

    @GetMapping("/users/{id}")
    @PreAuthorize("hasRole('nexus-user') and (#id == authentication.name or hasRole('nexus-manager'))")
    public ResponseEntity<User> getUser(@PathVariable String id) {
        // Users can only access their own data unless they're managers
    }
}
```

### 5. Environment Configuration

#### **Development vs Production**
```typescript
// ✅ Environment-specific configuration
interface KeycloakConfig {
  url: string;
  realm: string;
  clientId: string;
  redirectUri: string;
}

const getKeycloakConfig = (): KeycloakConfig => {
  const env = process.env.NODE_ENV;

  switch (env) {
    case 'development':
      return {
        url: 'http://localhost:8090',
        realm: 'nexus-dev',
        clientId: 'nexus-web-app',
        redirectUri: 'http://localhost:3000'
      };
    case 'staging':
      return {
        url: 'https://auth-staging.nexus.systech.com',
        realm: 'nexus-staging',
        clientId: 'nexus-web-app',
        redirectUri: 'https://staging.nexus.systech.com'
      };
    case 'production':
      return {
        url: 'https://auth.nexus.systech.com',
        realm: 'nexus-prod',
        clientId: 'nexus-web-app',
        redirectUri: 'https://nexus.systech.com'
      };
    default:
      throw new Error(`Unknown environment: ${env}`);
  }
};
```

### 6. Error Handling

#### **Frontend Error Handling**
```typescript
// ✅ Comprehensive error handling
class AuthErrorHandler {
  static handle(error: any) {
    switch (error.error) {
      case 'invalid_grant':
        // Refresh token expired
        AuthService.logout();
        break;
      case 'access_denied':
        // User denied authorization
        NotificationService.error('Access denied');
        break;
      case 'invalid_client':
        // Client configuration error
        console.error('Client configuration error:', error);
        break;
      default:
        console.error('Unknown auth error:', error);
    }
  }
}

// Usage in interceptor
api.interceptors.response.use(
  response => response,
  error => {
    if (error.response?.status === 401) {
      AuthErrorHandler.handle(error.response.data);
    }
    return Promise.reject(error);
  }
);
```

#### **Backend Error Handling**
```java
// ✅ Custom exception handling
@ControllerAdvice
public class AuthExceptionHandler {

    @ExceptionHandler(JwtValidationException.class)
    public ResponseEntity<ErrorResponse> handleJwtValidation(JwtValidationException ex) {
        ErrorResponse error = new ErrorResponse(
            "INVALID_TOKEN",
            "The provided token is invalid or expired",
            HttpStatus.UNAUTHORIZED.value()
        );
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error);
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ErrorResponse> handleAccessDenied(AccessDeniedException ex) {
        ErrorResponse error = new ErrorResponse(
            "ACCESS_DENIED",
            "Insufficient permissions to access this resource",
            HttpStatus.FORBIDDEN.value()
        );
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(error);
    }
}
```

### 7. Logging and Monitoring

#### **Security Event Logging**
```java
// ✅ Audit logging
@Component
public class SecurityAuditLogger {

    private static final Logger logger = LoggerFactory.getLogger(SecurityAuditLogger.class);

    public void logAuthenticationSuccess(String username, String ip) {
        logger.info("Authentication successful - User: {}, IP: {}", username, ip);
    }

    public void logAuthenticationFailure(String username, String ip, String reason) {
        logger.warn("Authentication failed - User: {}, IP: {}, Reason: {}", username, ip, reason);
    }

    public void logAuthorizationFailure(String username, String resource, String action) {
        logger.warn("Authorization denied - User: {}, Resource: {}, Action: {}", username, resource, action);
    }
}
```

#### **Performance Monitoring**
```typescript
// ✅ Auth performance tracking
class AuthMetrics {
  static trackTokenRefresh(startTime: number) {
    const duration = Date.now() - startTime;
    console.log(`Token refresh took ${duration}ms`);

    // Send to monitoring service
    if (duration > 5000) {
      console.warn('Slow token refresh detected');
    }
  }

  static trackLoginFlow(startTime: number) {
    const duration = Date.now() - startTime;
    console.log(`Login flow completed in ${duration}ms`);
  }
}
```

## Common Security Pitfalls to Avoid

### ❌ **Don't Store Sensitive Data in Frontend**
```javascript
// ❌ NEVER do this
localStorage.setItem('access_token', token);
localStorage.setItem('user_password', password);
localStorage.setItem('client_secret', secret);

// ✅ Instead, let Keycloak manage tokens
// Tokens should only exist in memory or secure HTTP-only cookies
```

### ❌ **Don't Use Weak CORS Policies**
```java
// ❌ NEVER do this
configuration.setAllowedOrigins(Arrays.asList("*"));
configuration.setAllowCredentials(true); // This combination is dangerous

// ✅ Use specific origins
configuration.setAllowedOriginPatterns(Arrays.asList("https://*.systech.com"));
```

### ❌ **Don't Ignore Token Validation**
```java
// ❌ NEVER skip validation
@GetMapping("/api/user")
public User getUser(@RequestHeader("Authorization") String token) {
    // Don't just decode without validation
    String payload = Base64.decode(token.split("\\.")[1]);
    return parseUser(payload); // DANGEROUS!
}

// ✅ Use Spring Security's JWT validation
@GetMapping("/api/user")
@PreAuthorize("hasRole('USER')")
public User getUser(Authentication auth) {
    // Spring Security handles validation
    return userService.findByUsername(auth.getName());
}
```

### ❌ **Don't Use Implicit Flow for SPAs**
```javascript
// ❌ Deprecated and insecure
const keycloak = new Keycloak(config);
keycloak.init({
  onLoad: 'login-required',
  flow: 'implicit' // DON'T USE THIS
});

// ✅ Use Authorization Code Flow with PKCE
keycloak.init({
  onLoad: 'check-sso',
  flow: 'standard',
  pkceMethod: 'S256'
});
```

## Testing Security

### **Security Test Checklist**
```typescript
// ✅ Security test scenarios
describe('Security Tests', () => {
  test('should reject expired tokens', async () => {
    const expiredToken = generateExpiredToken();
    const response = await api.get('/protected', {
      headers: { Authorization: `Bearer ${expiredToken}` }
    });
    expect(response.status).toBe(401);
  });

  test('should enforce role-based access', async () => {
    const userToken = generateUserToken(); // Without admin role
    const response = await api.get('/admin-only', {
      headers: { Authorization: `Bearer ${userToken}` }
    });
    expect(response.status).toBe(403);
  });

  test('should handle token refresh gracefully', async () => {
    // Mock token about to expire
    mockTokenExpiry(30); // 30 seconds

    const response = await api.get('/protected');
    expect(response.status).toBe(200);
    expect(mockTokenRefresh).toHaveBeenCalled();
  });
});
```

---

**🔒 Security First**: Always prioritize security over convenience. These practices ensure robust, maintainable authentication and authorization in your Nexus application.