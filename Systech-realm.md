# Systech Realm - Developer Integration Guide

## 🏢 Overview

**Realm Name**: `systech`
**Display Name**: Systech Platform
**Keycloak Server**: http://localhost:8090
**Realm URL**: http://localhost:8090/realms/systech

## 🔐 Authentication Architecture

### **User Groups & Access Levels**

| Group | Purpose | Access Level |
|-------|---------|--------------|
| **platform-admins** | System administrators | Full platform control, user management, system configuration |
| **app-admins** | Application administrators | Application management, user assignment, app configuration |
| **users** | End users | Standard application access, personal profile management |

### **Test Credentials**

| Username | Password | Group | Email |
|----------|----------|-------|-------|
| `babu.systech` | `systech@123` | platform-admins | babu@systech.com |

*Note: Add more test users as needed for your development team*

## 🚀 Integration Endpoints

### **Base URLs**
```
Keycloak Server: http://localhost:8090
Realm Base URL: http://localhost:8090/realms/systech
Admin API: http://localhost:8090/admin/realms/systech
```

### **Authentication Endpoints**
```
Token Endpoint: http://localhost:8090/realms/systech/protocol/openid-connect/token
Authorization: http://localhost:8090/realms/systech/protocol/openid-connect/auth
Userinfo: http://localhost:8090/realms/systech/protocol/openid-connect/userinfo
Logout: http://localhost:8090/realms/systech/protocol/openid-connect/logout
```

### **Configuration Endpoints**
```
Well-known Config: http://localhost:8090/realms/systech/.well-known/openid_configuration
JWKS (Public Keys): http://localhost:8090/realms/systech/protocol/openid-connect/certs
```

## 💻 Development Examples

### **1. Get Access Token (Password Grant)**
```bash
curl -X POST http://localhost:8090/realms/systech/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "username=babu.systech" \
  -d "password=systech@123"
```

### **2. Validate Token & Get User Info**
```bash
curl -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
     http://localhost:8090/realms/systech/protocol/openid-connect/userinfo
```

### **3. Refresh Token**
```bash
curl -X POST http://localhost:8090/realms/systech/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "refresh_token=YOUR_REFRESH_TOKEN"
```

## 🔧 Client Configuration

### **Systech HRMS Application Architecture**

**Single Client Setup (Recommended):**
```
React Frontend (systech-hrms-client) ↔ Spring Boot Backend (Resource Server)
       ↓                                      ↑
   Keycloak                              JWT Validation
 (Auth Server)                         (Public Keys)
```

- **React Frontend**: Keycloak client (handles login/logout)
- **Spring Boot Backend**: Resource server (validates JWT tokens)
- **No backend client needed**: Spring Boot uses public keys for validation

### **HRMS Client Configuration**

**Client Details:**
```json
{
  "clientId": "systech-hrms-client",
  "name": "Systech HRMS Application",
  "description": "Human Resources Management System frontend application",
  "enabled": true,
  "publicClient": true,
  "protocol": "openid-connect",
  "standardFlowEnabled": true,
  "directAccessGrantsEnabled": false,
  "implicitFlowEnabled": false,
  "serviceAccountsEnabled": false,
  "authorizationServicesEnabled": false,
  "redirectUris": [
    "http://localhost:3000/*",
    "http://localhost:3001/*"
  ],
  "webOrigins": [
    "http://localhost:3000",
    "http://localhost:3001"
  ],
  "attributes": {
    "pkce.code.challenge.method": "S256"
  }
}
```

### **How to Create systech-hrms-client**

**Step-by-Step Guide:**

1. **Open Admin Console**: http://localhost:8090/admin
2. **Login**: `admin` / `secret`
3. **Switch Realm**: Select **"systech"** from dropdown (top-left)
4. **Navigate**: Left sidebar → **"Clients"**
5. **Create**: Click **"Create client"** button

**General Settings:**
```
Client type: OpenID Connect
Client ID: systech-hrms-client
Name: Systech HRMS Application
Description: Human Resources Management System frontend
```

**Capability Config:**
```
Client authentication: OFF (public client)
Authorization: OFF
Authentication flow:
  ✅ Standard flow
  ❌ Direct access grants
  ❌ Implicit flow
  ❌ Service accounts roles
  ❌ OAuth 2.0 Device Authorization Grant
```

**Login Settings:**
```
Root URL: http://localhost:3000
Home URL: http://localhost:3000
Valid redirect URIs:
  http://localhost:3000/*
  http://localhost:3001/*
Valid post logout redirect URIs:
  http://localhost:3000
  http://localhost:3001
Web origins:
  http://localhost:3000
  http://localhost:3001
```

**Advanced Settings:**
```
Access Token Lifespan: 5 minutes
Client Session Idle: 30 minutes
Client Session Max: 12 hours
PKCE: S256 (recommended for security)
```

### **🔑 CRITICAL: Configure Group Membership Mapper**

**⚠️ REQUIRED STEP**: Without this mapper, groups won't appear in JWT tokens!

#### **Method 1: Manual Configuration (Admin Console)**

1. **Navigate**: `systech-hrms-client` → **Client mappers** tab
2. **Add Mapper**: **Add mapper** → **By configuration** → **Group Membership**
3. **Configure**:
   ```
   Name: groups
   Token Claim Name: groups
   Full group path: OFF (for clean names like "platform-admins")
   Add to ID token: ON
   Add to access token: ON ✅
   Add to userinfo: ON
   ```
4. **Save**

#### **Method 2: API Configuration (curl)**

```bash
# Get admin token
ADMIN_TOKEN=$(curl -s -X POST http://localhost:8090/realms/master/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" \
  -d "username=admin" \
  -d "password=secret" | jq -r '.access_token')

# Get client ID
CLIENT_ID=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:8090/admin/realms/systech/clients?clientId=systech-hrms-client" | \
  jq -r '.[0].id')

# Create Group Membership mapper
curl -X POST "http://localhost:8090/admin/realms/systech/clients/$CLIENT_ID/protocol-mappers/models" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "groups",
    "protocol": "openid-connect",
    "protocolMapper": "oidc-group-membership-mapper",
    "consentRequired": false,
    "config": {
      "full.path": "false",
      "id.token.claim": "true",
      "access.token.claim": "true",
      "claim.name": "groups",
      "userinfo.token.claim": "true"
    }
  }'
```

#### **Verification Commands**

```bash
# Test token has groups
TOKEN=$(curl -s -X POST http://localhost:8090/realms/systech/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=systech-hrms-client" \
  -d "username=babu.systech" \
  -d "password=systech@123" | jq -r '.access_token')

# Check groups in token
echo $TOKEN | cut -d'.' -f2 | base64 -d | jq '.groups'
# Expected: ["platform-admins"] ✅

# Verify mapper exists
curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:8090/admin/realms/systech/clients/$CLIENT_ID/protocol-mappers/models" | \
  jq -r '.[] | select(.name == "groups") | .name'
# Expected: groups ✅
```

#### **Before vs After Mapper**

**❌ BEFORE (Missing Mapper):**
```json
{
  "preferred_username": "babu.systech",
  "name": "Babu Systech",
  "email": "babu@systech.com"
  // ❌ NO groups field
}
```

**✅ AFTER (With Mapper):**
```json
{
  "preferred_username": "babu.systech",
  "name": "Babu Systech",
  "email": "babu@systech.com",
  "groups": ["platform-admins"]  ✅
}
```

### **Spring Boot Resource Server Configuration**

**Maven Dependencies (pom.xml):**
```xml
<dependencies>
    <!-- Spring Boot Starter Security -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-security</artifactId>
    </dependency>

    <!-- OAuth2 Resource Server -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-oauth2-resource-server</artifactId>
    </dependency>

    <!-- JWT Support -->
    <dependency>
        <groupId>org.springframework.security</groupId>
        <artifactId>spring-security-oauth2-jose</artifactId>
    </dependency>
</dependencies>
```

**Application Configuration (application.yml):**
```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          # Keycloak will provide token validation
          issuer-uri: http://localhost:8090/realms/systech
          jwk-set-uri: http://localhost:8090/realms/systech/protocol/openid-connect/certs

# CORS configuration for React frontend
app:
  cors:
    allowed-origins:
      - http://localhost:3000
      - http://localhost:3001
    allowed-methods:
      - GET
      - POST
      - PUT
      - DELETE
      - OPTIONS
    allowed-headers: "*"
    allow-credentials: true

# Application-specific settings
systech:
  hrms:
    realm: systech
    keycloak-server: http://localhost:8090
```

**Security Configuration:**
```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = true)
public class SecurityConfig {

    @Value("${app.cors.allowed-origins}")
    private List<String> allowedOrigins;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .csrf(csrf -> csrf.disable())
            .sessionManagement(session ->
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            )
            .oauth2ResourceServer(oauth2 ->
                oauth2.jwt(jwt ->
                    jwt.jwtAuthenticationConverter(jwtAuthenticationConverter())
                )
            )
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/public/**").permitAll()
                .requestMatchers("/api/health").permitAll()
                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                .requestMatchers("/api/admin/**").hasRole("platform-admins")
                .requestMatchers("/api/management/**").hasAnyRole("platform-admins", "app-admins")
                .anyRequest().authenticated()
            );

        return http.build();
    }

    @Bean
    public JwtAuthenticationConverter jwtAuthenticationConverter() {
        JwtGrantedAuthoritiesConverter authoritiesConverter = new JwtGrantedAuthoritiesConverter();

        // Convert Keycloak groups to Spring Security roles
        authoritiesConverter.setAuthoritiesClaimName("groups");
        authoritiesConverter.setAuthorityPrefix("ROLE_");

        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(jwt -> {
            Collection<GrantedAuthority> authorities = authoritiesConverter.convert(jwt);

            // Clean up group paths (remove leading slash)
            return authorities.stream()
                .map(authority -> authority.getAuthority().replace("/", ""))
                .map(SimpleGrantedAuthority::new)
                .collect(Collectors.toList());
        });

        return converter;
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOrigins(allowedOrigins);
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(Arrays.asList("*"));
        configuration.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/api/**", configuration);
        return source;
    }
}
```

**HRMS Controller Examples:**
```java
@RestController
@RequestMapping("/api")
public class HRMSController {

    @GetMapping("/employees")
    @PreAuthorize("hasAnyRole('ROLE_platform-admins', 'ROLE_app-admins', 'ROLE_users')")
    public ResponseEntity<List<Employee>> getEmployees(Authentication authentication) {
        // All authenticated users can view employees
        String username = authentication.getName();
        return ResponseEntity.ok(employeeService.getAllEmployees());
    }

    @PostMapping("/employees")
    @PreAuthorize("hasAnyRole('ROLE_platform-admins', 'ROLE_app-admins')")
    public ResponseEntity<Employee> createEmployee(@RequestBody Employee employee) {
        // Only admins can create employees
        Employee created = employeeService.createEmployee(employee);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @GetMapping("/admin/users")
    @PreAuthorize("hasRole('ROLE_platform-admins')")
    public ResponseEntity<List<User>> getUsers() {
        // Only platform admins can manage users
        return ResponseEntity.ok(userService.getAllUsers());
    }

    @GetMapping("/user/profile")
    public ResponseEntity<UserProfile> getUserProfile(Authentication authentication) {
        JwtAuthenticationToken jwt = (JwtAuthenticationToken) authentication;

        UserProfile profile = UserProfile.builder()
            .username(jwt.getName())
            .email(jwt.getToken().getClaimAsString("email"))
            .firstName(jwt.getToken().getClaimAsString("given_name"))
            .lastName(jwt.getToken().getClaimAsString("family_name"))
            .groups(jwt.getToken().getClaimAsStringList("groups"))
            .build();

        return ResponseEntity.ok(profile);
    }
}
```

**JWT Utility Service:**
```java
@Service
public class JwtTokenService {

    public String getCurrentUsername(Authentication authentication) {
        return authentication.getName();
    }

    public List<String> getCurrentUserGroups(Authentication authentication) {
        if (authentication instanceof JwtAuthenticationToken jwtAuth) {
            return jwtAuth.getToken().getClaimAsStringList("groups");
        }
        return Collections.emptyList();
    }

    public boolean hasGroup(Authentication authentication, String group) {
        return getCurrentUserGroups(authentication)
            .contains("/" + group); // Groups in JWT have leading slash
    }

    public boolean isAdmin(Authentication authentication) {
        return hasGroup(authentication, "platform-admins");
    }

    public boolean isAppAdmin(Authentication authentication) {
        return hasGroup(authentication, "platform-admins") ||
               hasGroup(authentication, "app-admins");
    }
}
```

### **React/Frontend Integration**

**Install Keycloak JavaScript Adapter:**
```bash
npm install keycloak-js
# or
yarn add keycloak-js
```

**Basic Setup:**
```javascript
import Keycloak from 'keycloak-js';

// Keycloak configuration
const keycloak = new Keycloak({
  url: 'http://localhost:8090/',
  realm: 'systech',
  clientId: 'systech-hrms-client'
});

// Initialize Keycloak
keycloak.init({
  onLoad: 'login-required',
  checkLoginIframe: false,
  pkceMethod: 'S256'
}).then(authenticated => {
  if (authenticated) {
    console.log('User authenticated');
    console.log('User groups:', keycloak.tokenParsed.groups);
    console.log('Username:', keycloak.tokenParsed.preferred_username);
  }
}).catch(error => {
  console.error('Authentication failed:', error);
});

export default keycloak;
```

**React Context Provider:**
```javascript
import React, { createContext, useContext, useEffect, useState } from 'react';
import keycloak from './keycloak';

const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [authenticated, setAuthenticated] = useState(false);
  const [loading, setLoading] = useState(true);
  const [userInfo, setUserInfo] = useState(null);

  useEffect(() => {
    keycloak.init({ onLoad: 'login-required' })
      .then(authenticated => {
        setAuthenticated(authenticated);
        if (authenticated) {
          setUserInfo({
            username: keycloak.tokenParsed.preferred_username,
            email: keycloak.tokenParsed.email,
            groups: keycloak.tokenParsed.groups || [],
            firstName: keycloak.tokenParsed.given_name,
            lastName: keycloak.tokenParsed.family_name
          });
        }
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, []);

  const login = () => keycloak.login();
  const logout = () => keycloak.logout();

  const hasRole = (role) => {
    return userInfo?.groups?.includes(`/${role}`) || false;
  };

  const isAdmin = () => hasRole('platform-admins');
  const isAppAdmin = () => hasRole('app-admins') || isAdmin();

  return (
    <AuthContext.Provider value={{
      authenticated,
      loading,
      userInfo,
      login,
      logout,
      hasRole,
      isAdmin,
      isAppAdmin,
      token: keycloak.token
    }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);
```

**API Service with Authentication:**
```javascript
import keycloak from './keycloak';

class ApiService {
  constructor() {
    this.baseURL = 'http://localhost:8080/api';
  }

  async request(endpoint, options = {}) {
    const url = `${this.baseURL}${endpoint}`;

    // Ensure token is fresh
    await keycloak.updateToken(30);

    const config = {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${keycloak.token}`,
        ...options.headers
      },
      ...options
    };

    const response = await fetch(url, config);

    if (!response.ok) {
      throw new Error(`API Error: ${response.status}`);
    }

    return response.json();
  }

  // HRMS API methods
  getEmployees() {
    return this.request('/employees');
  }

  getEmployee(id) {
    return this.request(`/employees/${id}`);
  }

  createEmployee(employee) {
    return this.request('/employees', {
      method: 'POST',
      body: JSON.stringify(employee)
    });
  }
}

export default new ApiService();
```

**Component Example:**
```javascript
import React from 'react';
import { useAuth } from './AuthContext';

const HRMSApp = () => {
  const { authenticated, loading, userInfo, logout, isAdmin, isAppAdmin } = useAuth();

  if (loading) return <div>Loading...</div>;
  if (!authenticated) return <div>Please log in</div>;

  return (
    <div>
      <header>
        <h1>Systech HRMS</h1>
        <div>
          Welcome, {userInfo.firstName} {userInfo.lastName}
          <button onClick={logout}>Logout</button>
        </div>
      </header>

      <nav>
        <a href="/dashboard">Dashboard</a>
        <a href="/employees">Employees</a>

        {isAppAdmin() && (
          <>
            <a href="/departments">Departments</a>
            <a href="/reports">Reports</a>
          </>
        )}

        {isAdmin() && (
          <>
            <a href="/admin/users">User Management</a>
            <a href="/admin/settings">System Settings</a>
          </>
        )}
      </nav>

      <main>
        {/* Your HRMS application content */}
      </main>
    </div>
  );
};

export default HRMSApp;
```

## 👥 User Management

### **Group-Based Authorization**

Use JWT token claims to check user groups:

```json
{
  "exp": 1234567890,
  "iat": 1234567890,
  "iss": "http://localhost:8090/realms/systech",
  "sub": "1cef29ef-a6e4-4bc4-9f8a-ec7c6b0a155c",
  "preferred_username": "babu.systech",
  "email": "babu@systech.com",
  "groups": ["/platform-admins"],
  "realm_access": {
    "roles": ["default-roles-systech"]
  }
}
```

### **Authorization Examples**

**Backend (Spring Boot)**:
```java
@PreAuthorize("hasRole('platform-admins')")
@GetMapping("/admin/users")
public List<User> getUsers() {
    // Only platform-admins can access
}

@PreAuthorize("hasAnyRole('platform-admins', 'app-admins')")
@PostMapping("/admin/settings")
public void updateSettings() {
    // Both platform-admins and app-admins can access
}
```

**Frontend (React)**:
```javascript
const isAdmin = keycloak.hasRealmRole('platform-admins');
const canManageApps = keycloak.hasRealmRole('app-admins') ||
                      keycloak.hasRealmRole('platform-admins');

{isAdmin && <AdminPanel />}
{canManageApps && <AppManagement />}
```

## 🔒 Security Best Practices

### **Token Validation**
- Always validate JWT tokens using Keycloak's public keys
- Check token expiration (`exp` claim)
- Verify issuer (`iss` claim) matches your realm
- Validate audience (`aud` claim) if configured

### **Group/Role Checking**
- Use `groups` claim for authorization decisions
- Implement hierarchical permissions (platform-admins > app-admins > users)
- Cache group memberships appropriately

### **CORS Configuration**
- Configure proper CORS settings in Keycloak client
- Match your frontend URLs exactly
- Avoid wildcards in production

## 🧪 Testing & Development

### **Quick Token Test**
```bash
# Test with systech-hrms-client (after creation)
TOKEN=$(curl -s -X POST http://localhost:8090/realms/systech/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=systech-hrms-client" \
  -d "username=babu.systech" \
  -d "password=systech@123" | jq -r '.access_token')

# Test with default account client (for quick testing)
TOKEN=$(curl -s -X POST http://localhost:8090/realms/systech/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=account" \
  -d "username=babu.systech" \
  -d "password=systech@123" | jq -r '.access_token')

# Decode token to see user info
echo $TOKEN | cut -d'.' -f2 | base64 -d | jq .

# Test Spring Boot API endpoints
curl -H "Authorization: Bearer $TOKEN" \
     http://localhost:8080/api/user/profile

curl -H "Authorization: Bearer $TOKEN" \
     http://localhost:8080/api/employees

# Test admin endpoint (only for platform-admins)
curl -H "Authorization: Bearer $TOKEN" \
     http://localhost:8080/api/admin/users
```

### **End-to-End Testing**
```bash
# 1. Check Keycloak health
curl -s http://localhost:8090/health/ready

# 2. Test realm configuration
curl -s http://localhost:8090/realms/systech/.well-known/openid_configuration | jq .

# 3. Test authentication
curl -X POST http://localhost:8090/realms/systech/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=account" \
  -d "username=babu.systech" \
  -d "password=systech@123" | jq .

# 4. Test Spring Boot health (if implemented)
curl http://localhost:8080/api/health

# 5. Test protected endpoint
TOKEN=$(curl -s -X POST http://localhost:8090/realms/systech/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=account" \
  -d "username=babu.systech" \
  -d "password=systech@123" | jq -r '.access_token')

curl -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     http://localhost:8080/api/user/profile
```

### **JWT Debugging**
Use https://jwt.io to decode and inspect your tokens during development.

## 🎉 **Working Example**

### **Complete Authentication Flow**

**1. Frontend React Component:**
```javascript
// App.js
import React, { useEffect, useState } from 'react';
import Keycloak from 'keycloak-js';

const keycloak = new Keycloak({
  url: 'http://localhost:8090/',
  realm: 'systech',
  clientId: 'systech-hrms-client' // or 'account' for testing
});

function App() {
  const [authenticated, setAuthenticated] = useState(false);
  const [userInfo, setUserInfo] = useState(null);

  useEffect(() => {
    keycloak.init({ onLoad: 'login-required' })
      .then(authenticated => {
        setAuthenticated(authenticated);
        if (authenticated) {
          setUserInfo(keycloak.tokenParsed);
        }
      });
  }, []);

  const callAPI = async () => {
    try {
      await keycloak.updateToken(30);
      const response = await fetch('http://localhost:8080/api/user/profile', {
        headers: {
          'Authorization': `Bearer ${keycloak.token}`
        }
      });
      const data = await response.json();
      console.log('API Response:', data);
    } catch (error) {
      console.error('API Error:', error);
    }
  };

  if (!authenticated) return <div>Loading...</div>;

  return (
    <div>
      <h1>Systech HRMS</h1>
      <p>Welcome, {userInfo?.preferred_username}</p>
      <p>Groups: {userInfo?.groups?.join(', ')}</p>
      <button onClick={callAPI}>Test API Call</button>
      <button onClick={() => keycloak.logout()}>Logout</button>
    </div>
  );
}

export default App;
```

**2. Spring Boot Controller:**
```java
@RestController
@RequestMapping("/api")
public class UserController {

    @GetMapping("/user/profile")
    public ResponseEntity<Map<String, Object>> getUserProfile(Authentication authentication) {
        JwtAuthenticationToken jwt = (JwtAuthenticationToken) authentication;

        Map<String, Object> profile = new HashMap<>();
        profile.put("username", jwt.getName());
        profile.put("email", jwt.getToken().getClaimAsString("email"));
        profile.put("groups", jwt.getToken().getClaimAsStringList("groups"));
        profile.put("firstName", jwt.getToken().getClaimAsString("given_name"));
        profile.put("lastName", jwt.getToken().getClaimAsString("family_name"));

        return ResponseEntity.ok(profile);
    }

    @GetMapping("/admin/test")
    @PreAuthorize("hasRole('ROLE_platform-admins')")
    public ResponseEntity<String> adminTest() {
        return ResponseEntity.ok("Admin access granted!");
    }
}
```

**3. Test Commands:**
```bash
# Start Keycloak
./start-keycloak.sh

# Get token for testing
TOKEN=$(curl -s -X POST http://localhost:8090/realms/systech/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=account" \
  -d "username=babu.systech" \
  -d "password=systech@123" | jq -r '.access_token')

# Test API
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/user/profile

# Test admin endpoint
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/admin/test
```

## 📋 Integration Checklist

### **Backend Integration**
- [ ] Add Keycloak dependencies to your project
- [ ] Configure JWT validation with realm public keys
- [ ] Implement group-based authorization
- [ ] Add CORS configuration for your frontend
- [ ] Test protected endpoints with tokens

### **Frontend Integration**
- [ ] Install Keycloak JavaScript adapter
- [ ] Configure realm and client settings
- [ ] Implement login/logout flows
- [ ] Add role-based UI rendering
- [ ] Handle token refresh automatically

### **Client Configuration**
- [ ] Create `systech-hrms-client` in Keycloak admin console
- [ ] Configure redirect URIs: `http://localhost:3000/*`, `http://localhost:3001/*`
- [ ] Set client as public (for React frontend)
- [ ] Enable standard flow, disable direct access grants
- [ ] Configure Web Origins for CORS
- [ ] Enable PKCE (S256) for security
- [ ] **🔑 CRITICAL**: Add Group Membership mapper (name: "groups", claim: "groups")
- [ ] Test JWT token contains groups: `["platform-admins"]`
- [ ] Test authentication flow end-to-end

### **Alternative: Use Default Client for Testing**
- [ ] Use built-in `account` client for quick testing
- [ ] Test authentication with account client
- [ ] Verify JWT token contains correct groups
- [ ] Create custom client when ready for production

## 🆘 Troubleshooting

### **Common Issues**

**CORS Errors**:
- Check Web Origins in client configuration
- Ensure exact URL matches (no trailing slashes)

**Token Validation Failures**:
- Verify issuer URI matches realm URL
- Check system clock synchronization
- Ensure JWK endpoint is accessible

**Role/Group Access Denied**:
- Verify user group assignments
- Check JWT token groups claim
- Confirm authorization logic in your app

**Missing Groups in JWT Token** (COMMON ISSUE):
- **Symptom**: `token.groups = undefined` or `null`
- **Cause**: No Group Membership mapper configured
- **Solution**: Add Group Membership mapper to client (see mapper section above)
- **Quick Test**: `echo $TOKEN | cut -d'.' -f2 | base64 -d | jq '.groups'`
- **Should Return**: `["platform-admins"]` not `null`

### **Debug Commands**
```bash
# Check realm configuration
curl -s http://localhost:8090/realms/systech/.well-known/openid_configuration | jq .

# Check public keys
curl -s http://localhost:8090/realms/systech/protocol/openid-connect/certs | jq .

# Test user authentication
curl -X POST http://localhost:8090/realms/systech/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=account" \
  -d "username=babu.systech" \
  -d "password=systech@123"

# Test with custom client (after creation)
curl -X POST http://localhost:8090/realms/systech/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=systech-hrms-client" \
  -d "username=babu.systech" \
  -d "password=systech@123"

# Inspect JWT token payload
TOKEN="your_jwt_token_here"
echo $TOKEN | cut -d'.' -f2 | base64 -d | jq .

# Test Spring Boot endpoints
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/user/profile
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/employees
```

### **Client Troubleshooting**

**Client Creation Issues**:
- Ensure you're in the `systech` realm (not master)
- Check client ID is exactly `systech-hrms-client`
- Verify redirect URIs match your frontend URLs

**Authentication Flow Issues**:
- Enable browser dev tools → Network tab
- Check for CORS errors in console
- Verify redirect URI in authentication request
- Confirm PKCE is enabled for security

**Token Issues**:
- Check token expiration (5 minutes default)
- Verify issuer matches realm URL
- Ensure groups claim is present in JWT
- Check Spring Boot logs for validation errors

## 📞 Support

**Keycloak Admin Console**: http://localhost:8090/admin
**Realm Management**: Navigate to systech realm in admin console
**User Management**: Users section in systech realm

---

## 🚀 **Quick Start Guide**

### **For Frontend Developers**
1. **Create Client**: Follow manual creation steps above
2. **🔑 CRITICAL**: Add Group Membership mapper (or use curl commands above)
3. **Install Dependencies**: `npm install keycloak-js`
4. **Configure**: Use `systech-hrms-client` as clientId
5. **Test Authentication**: Login with `babu.systech` / `systech@123`
6. **Verify Groups**: Check `keycloak.tokenParsed.groups` contains `["platform-admins"]`

### **For Backend Developers**
1. **Add Dependencies**: Spring Boot OAuth2 Resource Server
2. **Configure**: Set issuer-uri to `http://localhost:8090/realms/systech`
3. **Security**: Enable JWT validation and group mapping
4. **Test**: Use token from frontend in API calls
5. **Authorize**: Use `@PreAuthorize` with group roles

### **For DevOps/Testing**
1. **Export Realm**: Use `./export-systech-realm.sh` for backups
2. **Import Realm**: Use `./import-systech-realm.sh` for deployment
3. **Monitor**: Check container status with `./dev-status.sh`
4. **Debug**: Use curl commands for API testing
5. **Scale**: Add more users/groups as needed

---

**Document Version**: 2.0
**Last Updated**: 2025-09-26
**Created for**: Systech HRMS Development Team
**Realm**: `systech` | **Client**: `systech-hrms-client` | **Test User**: `babu.systech`