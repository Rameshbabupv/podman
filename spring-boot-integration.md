# Spring Boot Integration with Keycloak

## Overview
This guide configures your Spring Boot application to authenticate with Keycloak using OAuth2/OpenID Connect.

## Prerequisites
- Keycloak running on port 8090
- Realm `nexus-app` configured with `nexus-backend` client
- Client secret from Keycloak admin console

## Step 1: Add Dependencies

Add these dependencies to your `pom.xml`:

```xml
<dependencies>
    <!-- Existing dependencies -->

    <!-- Spring Security OAuth2 Client -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-oauth2-client</artifactId>
    </dependency>

    <!-- Spring Security OAuth2 Resource Server -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-oauth2-resource-server</artifactId>
    </dependency>

    <!-- Spring Boot Web (if not already included) -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
</dependencies>
```

For Gradle (`build.gradle`):
```gradle
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-oauth2-client'
    implementation 'org.springframework.boot:spring-boot-starter-oauth2-resource-server'
    implementation 'org.springframework.boot:spring-boot-starter-web'
}
```

## Step 2: Configure Application Properties

Add to your `application.yml`:

```yaml
spring:
  security:
    oauth2:
      client:
        registration:
          keycloak:
            client-id: nexus-backend
            client-secret: YOUR_CLIENT_SECRET_FROM_KEYCLOAK
            scope: openid, profile, email
            authorization-grant-type: authorization_code
            redirect-uri: "{baseUrl}/login/oauth2/code/{registrationId}"
        provider:
          keycloak:
            issuer-uri: http://localhost:8090/realms/nexus-app
            user-name-attribute: preferred_username
      resourceserver:
        jwt:
          issuer-uri: http://localhost:8090/realms/nexus-app

# CORS Configuration for development
management:
  endpoints:
    web:
      cors:
        allowed-origins: "http://localhost:3000,http://localhost:3001"
        allowed-methods: GET,POST,PUT,DELETE,OPTIONS
        allowed-headers: "*"
        allow-credentials: true

# Logging for debugging
logging:
  level:
    org.springframework.security: DEBUG
    org.springframework.security.oauth2: DEBUG
```

Or in `application.properties`:
```properties
# OAuth2 Client Configuration
spring.security.oauth2.client.registration.keycloak.client-id=nexus-backend
spring.security.oauth2.client.registration.keycloak.client-secret=YOUR_CLIENT_SECRET_FROM_KEYCLOAK
spring.security.oauth2.client.registration.keycloak.scope=openid,profile,email
spring.security.oauth2.client.registration.keycloak.authorization-grant-type=authorization_code
spring.security.oauth2.client.registration.keycloak.redirect-uri={baseUrl}/login/oauth2/code/{registrationId}

# OAuth2 Provider Configuration
spring.security.oauth2.client.provider.keycloak.issuer-uri=http://localhost:8090/realms/nexus-app
spring.security.oauth2.client.provider.keycloak.user-name-attribute=preferred_username

# Resource Server Configuration
spring.security.oauth2.resourceserver.jwt.issuer-uri=http://localhost:8090/realms/nexus-app

# CORS Configuration
management.endpoints.web.cors.allowed-origins=http://localhost:3000,http://localhost:3001
management.endpoints.web.cors.allowed-methods=GET,POST,PUT,DELETE,OPTIONS
management.endpoints.web.cors.allowed-headers=*
management.endpoints.web.cors.allow-credentials=true
```

## Step 3: Create Security Configuration

Create `SecurityConfig.java`:

```java
package com.yourcompany.nexus.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = true)
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .csrf(csrf -> csrf.disable())
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(authz -> authz
                // Public endpoints
                .requestMatchers("/api/public/**").permitAll()
                .requestMatchers("/health", "/actuator/health").permitAll()

                // Protected endpoints
                .requestMatchers("/api/admin/**").hasRole("admin")
                .requestMatchers("/api/user/**").hasAnyRole("user", "admin")
                .requestMatchers("/api/**").authenticated()

                // All other requests require authentication
                .anyRequest().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt
                    .jwtAuthenticationConverter(jwtAuthenticationConverter())
                )
            );

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(Arrays.asList("http://localhost:3000", "http://localhost:3001"));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(Arrays.asList("*"));
        configuration.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

    @Bean
    public JwtAuthenticationConverter jwtAuthenticationConverter() {
        JwtGrantedAuthoritiesConverter authoritiesConverter = new JwtGrantedAuthoritiesConverter();
        authoritiesConverter.setAuthorityPrefix("ROLE_");
        authoritiesConverter.setAuthoritiesClaimName("realm_access.roles");

        JwtAuthenticationConverter authenticationConverter = new JwtAuthenticationConverter();
        authenticationConverter.setJwtGrantedAuthoritiesConverter(authoritiesConverter);
        return authenticationConverter;
    }
}
```

## Step 4: Create Authentication Controller

Create `AuthController.java` for authentication endpoints:

```java
package com.yourcompany.nexus.controller;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @GetMapping("/user-info")
    public Map<String, Object> getUserInfo(@AuthenticationPrincipal Jwt jwt) {
        Map<String, Object> userInfo = new HashMap<>();
        userInfo.put("username", jwt.getClaimAsString("preferred_username"));
        userInfo.put("email", jwt.getClaimAsString("email"));
        userInfo.put("firstName", jwt.getClaimAsString("given_name"));
        userInfo.put("lastName", jwt.getClaimAsString("family_name"));
        userInfo.put("roles", jwt.getClaimAsStringList("realm_access.roles"));
        userInfo.put("sub", jwt.getSubject());
        return userInfo;
    }

    @GetMapping("/validate-token")
    public Map<String, Object> validateToken(@AuthenticationPrincipal Jwt jwt) {
        Map<String, Object> response = new HashMap<>();
        response.put("valid", true);
        response.put("username", jwt.getClaimAsString("preferred_username"));
        response.put("exp", jwt.getExpiresAt());
        return response;
    }
}
```

## Step 5: Create Protected Controllers

Create `UserController.java`:

```java
package com.yourcompany.nexus.controller;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/user")
public class UserController {

    @GetMapping("/profile")
    @PreAuthorize("hasRole('user')")
    public Map<String, Object> getUserProfile(@AuthenticationPrincipal Jwt jwt) {
        Map<String, Object> profile = new HashMap<>();
        profile.put("message", "User profile data");
        profile.put("username", jwt.getClaimAsString("preferred_username"));
        profile.put("email", jwt.getClaimAsString("email"));
        return profile;
    }

    @GetMapping("/dashboard")
    @PreAuthorize("hasRole('user')")
    public Map<String, String> getUserDashboard() {
        Map<String, String> response = new HashMap<>();
        response.put("message", "Welcome to user dashboard");
        response.put("data", "User specific data here");
        return response;
    }
}
```

Create `AdminController.java`:

```java
package com.yourcompany.nexus.controller;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
public class AdminController {

    @GetMapping("/users")
    @PreAuthorize("hasRole('admin')")
    public Map<String, String> getAllUsers() {
        Map<String, String> response = new HashMap<>();
        response.put("message", "Admin: List of all users");
        response.put("data", "Admin specific data here");
        return response;
    }

    @GetMapping("/system-info")
    @PreAuthorize("hasRole('admin')")
    public Map<String, String> getSystemInfo() {
        Map<String, String> response = new HashMap<>();
        response.put("message", "Admin: System information");
        response.put("status", "All systems operational");
        return response;
    }
}
```

## Step 6: Create Public Controller

Create `PublicController.java` for non-authenticated endpoints:

```java
package com.yourcompany.nexus.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/public")
public class PublicController {

    @GetMapping("/health")
    public Map<String, String> health() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "UP");
        response.put("message", "Application is running");
        return response;
    }

    @GetMapping("/info")
    public Map<String, String> info() {
        Map<String, String> response = new HashMap<>();
        response.put("app", "Nexus Application");
        response.put("version", "1.0.0");
        response.put("auth", "Keycloak OpenID Connect");
        return response;
    }
}
```

## Step 7: Add Missing Import

Add this import to `SecurityConfig.java`:

```java
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.oauth2.server.resource.authentication.JwtGrantedAuthoritiesConverter;
```

## Step 8: Test Endpoints

After starting your Spring Boot application, test these endpoints:

**Public Endpoints** (No authentication required):
- `GET http://localhost:8080/api/public/health`
- `GET http://localhost:8080/api/public/info`

**Protected Endpoints** (Require JWT token):
- `GET http://localhost:8080/api/auth/user-info`
- `GET http://localhost:8080/api/user/profile`
- `GET http://localhost:8080/api/admin/users` (admin role required)

## Step 9: Getting JWT Token for Testing

### Option 1: Direct Token Request (for testing)
```bash
curl -X POST "http://localhost:8090/realms/nexus-app/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=nexus-backend" \
  -d "client_secret=YOUR_CLIENT_SECRET" \
  -d "username=testuser" \
  -d "password=password123"
```

### Option 2: Use the Token in API Calls
```bash
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:8080/api/auth/user-info
```

## Configuration Notes

1. **Replace `YOUR_CLIENT_SECRET_FROM_KEYCLOAK`** with the actual client secret from Keycloak admin console
2. **CORS** is configured for development with React running on ports 3000/3001
3. **Role mapping** expects roles in `realm_access.roles` claim from Keycloak
4. **Session management** is stateless using JWT tokens

## Troubleshooting

- **401 Unauthorized**: Check JWT token validity and issuer URI
- **403 Forbidden**: Verify user has required roles
- **CORS errors**: Ensure CORS configuration matches your React app ports
- **Token validation errors**: Check Keycloak realm and client configuration

## Next Steps
- Proceed to [React Integration](./react-integration.md)
- Test the complete authentication flow
- Review [Testing Guide](./testing-troubleshooting.md) for verification