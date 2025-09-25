# Modern Client Configurations

## Overview
Detailed client configurations for React frontend and Spring Boot backend integration with Keycloak using modern security standards.

## Frontend Configuration (React + TypeScript)

### 1. Keycloak React Adapter Setup

#### Installation
```bash
npm install keycloak-js @types/keycloak-js
# or
yarn add keycloak-js @types/keycloak-js
```

#### Environment Configuration (.env.development)
```env
# Keycloak Configuration
REACT_APP_KEYCLOAK_URL=http://localhost:8090
REACT_APP_KEYCLOAK_REALM=nexus-dev
REACT_APP_KEYCLOAK_CLIENT_ID=nexus-web-app

# Application Configuration
REACT_APP_API_BASE_URL=http://localhost:8080/api
REACT_APP_ENVIRONMENT=development
```

#### Keycloak Configuration (src/config/keycloak.ts)
```typescript
import Keycloak from 'keycloak-js';

const keycloakConfig = {
  url: process.env.REACT_APP_KEYCLOAK_URL!,
  realm: process.env.REACT_APP_KEYCLOAK_REALM!,
  clientId: process.env.REACT_APP_KEYCLOAK_CLIENT_ID!,
};

const keycloak = new Keycloak(keycloakConfig);

export const initOptions = {
  onLoad: 'check-sso' as const,
  silentCheckSsoRedirectUri: window.location.origin + '/silent-check-sso.html',
  pkceMethod: 'S256' as const,
  enableLogging: process.env.NODE_ENV === 'development',
  checkLoginIframe: false, // Recommended for better performance
  flow: 'standard' as const,
};

export default keycloak;
```

#### React Provider Setup (src/providers/AuthProvider.tsx)
```typescript
import React, { createContext, useContext, useEffect, useState } from 'react';
import { ReactKeycloakProvider } from '@react-keycloak/web';
import keycloak, { initOptions } from '../config/keycloak';

interface AuthContextType {
  isAuthenticated: boolean;
  user: any;
  token: string | undefined;
  hasRole: (role: string) => boolean;
  hasPermission: (permission: string) => boolean;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
};

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [authState, setAuthState] = useState({
    isAuthenticated: false,
    user: null,
    token: undefined,
  });

  const hasRole = (role: string): boolean => {
    return keycloak.hasRealmRole(role) || keycloak.hasResourceRole(role, 'nexus-api');
  };

  const hasPermission = (permission: string): boolean => {
    // Custom permission logic based on roles and user attributes
    const userRoles = keycloak.realmAccess?.roles || [];
    const clientRoles = keycloak.resourceAccess?.['nexus-api']?.roles || [];

    const allRoles = [...userRoles, ...clientRoles];
    return allRoles.includes(permission);
  };

  const logout = () => {
    keycloak.logout({
      redirectUri: window.location.origin,
    });
  };

  const onKeycloakEvent = (event: string, error?: any) => {
    console.log('Keycloak event:', event, error);

    if (event === 'onAuthSuccess') {
      setAuthState({
        isAuthenticated: keycloak.authenticated || false,
        user: keycloak.tokenParsed,
        token: keycloak.token,
      });
    } else if (event === 'onAuthLogout') {
      setAuthState({
        isAuthenticated: false,
        user: null,
        token: undefined,
      });
    }
  };

  const onKeycloakTokens = (tokens: any) => {
    console.log('Keycloak tokens updated:', tokens);
    setAuthState(prev => ({
      ...prev,
      token: tokens.token,
    }));
  };

  const contextValue: AuthContextType = {
    isAuthenticated: authState.isAuthenticated,
    user: authState.user,
    token: authState.token,
    hasRole,
    hasPermission,
    logout,
  };

  return (
    <ReactKeycloakProvider
      authClient={keycloak}
      initOptions={initOptions}
      onEvent={onKeycloakEvent}
      onTokens={onKeycloakTokens}
      LoadingComponent={<div>Loading authentication...</div>}
    >
      <AuthContext.Provider value={contextValue}>
        {children}
      </AuthContext.Provider>
    </ReactKeycloakProvider>
  );
};
```

#### HTTP Interceptor for API Calls (src/services/api.ts)
```typescript
import axios, { AxiosInstance, AxiosRequestConfig } from 'axios';
import keycloak from '../config/keycloak';

class ApiService {
  private api: AxiosInstance;

  constructor() {
    this.api = axios.create({
      baseURL: process.env.REACT_APP_API_BASE_URL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    this.setupInterceptors();
  }

  private setupInterceptors() {
    // Request interceptor to add auth token
    this.api.interceptors.request.use(
      (config) => {
        if (keycloak.token) {
          config.headers.Authorization = `Bearer ${keycloak.token}`;
        }
        return config;
      },
      (error) => Promise.reject(error)
    );

    // Response interceptor for token refresh
    this.api.interceptors.response.use(
      (response) => response,
      async (error) => {
        const original = error.config;

        if (error.response?.status === 401 && !original._retry) {
          original._retry = true;

          try {
            await keycloak.updateToken(30); // Refresh if expires within 30s
            original.headers.Authorization = `Bearer ${keycloak.token}`;
            return this.api(original);
          } catch (refreshError) {
            console.error('Token refresh failed:', refreshError);
            keycloak.logout();
            return Promise.reject(refreshError);
          }
        }

        return Promise.reject(error);
      }
    );
  }

  // API methods
  public get<T>(url: string, config?: AxiosRequestConfig) {
    return this.api.get<T>(url, config);
  }

  public post<T>(url: string, data?: any, config?: AxiosRequestConfig) {
    return this.api.post<T>(url, data, config);
  }

  public put<T>(url: string, data?: any, config?: AxiosRequestConfig) {
    return this.api.put<T>(url, data, config);
  }

  public delete<T>(url: string, config?: AxiosRequestConfig) {
    return this.api.delete<T>(url, config);
  }
}

export const apiService = new ApiService();
```

#### Protected Route Component (src/components/ProtectedRoute.tsx)
```typescript
import React from 'react';
import { useKeycloak } from '@react-keycloak/web';
import { useAuth } from '../providers/AuthProvider';

interface ProtectedRouteProps {
  children: React.ReactNode;
  roles?: string[];
  permissions?: string[];
  fallback?: React.ReactNode;
}

export const ProtectedRoute: React.FC<ProtectedRouteProps> = ({
  children,
  roles = [],
  permissions = [],
  fallback = <div>Access denied</div>,
}) => {
  const { keycloak } = useKeycloak();
  const { hasRole, hasPermission } = useAuth();

  // Check authentication
  if (!keycloak.authenticated) {
    keycloak.login();
    return <div>Redirecting to login...</div>;
  }

  // Check roles
  if (roles.length > 0 && !roles.some(role => hasRole(role))) {
    return <>{fallback}</>;
  }

  // Check permissions
  if (permissions.length > 0 && !permissions.some(permission => hasPermission(permission))) {
    return <>{fallback}</>;
  }

  return <>{children}</>;
};
```

## Backend Configuration (Spring Boot + Java)

### 1. Dependencies (pom.xml)
```xml
<dependencies>
    <!-- Keycloak Spring Boot Starter -->
    <dependency>
        <groupId>org.keycloak</groupId>
        <artifactId>keycloak-spring-boot-starter</artifactId>
        <version>20.0.0</version>
    </dependency>

    <!-- Spring Security -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-security</artifactId>
    </dependency>

    <!-- OAuth2 Resource Server -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-oauth2-resource-server</artifactId>
    </dependency>

    <!-- JWT -->
    <dependency>
        <groupId>org.springframework.security</groupId>
        <artifactId>spring-security-oauth2-jose</artifactId>
    </dependency>
</dependencies>
```

### 2. Application Configuration (application.yml)
```yaml
spring:
  application:
    name: nexus-api
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: http://localhost:8090/realms/nexus-dev
          jwk-set-uri: http://localhost:8090/realms/nexus-dev/protocol/openid-connect/certs

# Keycloak Configuration
keycloak:
  realm: nexus-dev
  auth-server-url: http://localhost:8090
  resource: nexus-api
  credentials:
    secret: ${KEYCLOAK_CLIENT_SECRET:your-client-secret}
  use-resource-role-mappings: true
  bearer-only: true
  cors: true

# Application Configuration
nexus:
  security:
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
      allowed-headers:
        - Authorization
        - Content-Type
        - X-Requested-With
      max-age: 3600

logging:
  level:
    org.springframework.security: DEBUG
    org.keycloak: DEBUG
```

### 3. Security Configuration (SecurityConfig.java)
```java
package com.systech.nexus.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableGlobalMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.authority.mapping.SimpleAuthorityMapper;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.oauth2.server.resource.authentication.JwtGrantedAuthoritiesConverter;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

@Configuration
@EnableWebSecurity
@EnableGlobalMethodSecurity(prePostEnabled = true)
public class SecurityConfig {

    @Value("${nexus.security.cors.allowed-origins}")
    private List<String> allowedOrigins;

    @Value("${nexus.security.cors.allowed-methods}")
    private List<String> allowedMethods;

    @Value("${nexus.security.cors.allowed-headers}")
    private List<String> allowedHeaders;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .cors().and()
            .csrf().disable()
            .sessionManagement().sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            .and()
            .authorizeHttpRequests(authz -> authz
                .requestMatchers("/api/public/**").permitAll()
                .requestMatchers("/actuator/health").permitAll()
                .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()
                .requestMatchers("/api/admin/**").hasRole("nexus-admin")
                .requestMatchers("/api/manager/**").hasAnyRole("nexus-admin", "nexus-manager")
                .requestMatchers("/api/user/**").hasAnyRole("nexus-admin", "nexus-manager", "nexus-user")
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
    public JwtAuthenticationConverter jwtAuthenticationConverter() {
        JwtGrantedAuthoritiesConverter authoritiesConverter = new JwtGrantedAuthoritiesConverter();
        authoritiesConverter.setAuthorityPrefix("ROLE_");
        authoritiesConverter.setAuthoritiesClaimName("realm_access.roles");

        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(authoritiesConverter);
        return converter;
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(allowedOrigins);
        configuration.setAllowedMethods(allowedMethods);
        configuration.setAllowedHeaders(allowedHeaders);
        configuration.setAllowCredentials(true);
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
```

### 4. JWT Token Utility (JwtTokenUtil.java)
```java
package com.systech.nexus.util;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

@Component
public class JwtTokenUtil {

    public String getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication instanceof JwtAuthenticationToken) {
            Jwt jwt = ((JwtAuthenticationToken) authentication).getToken();
            return jwt.getClaimAsString("sub");
        }
        return null;
    }

    public String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication instanceof JwtAuthenticationToken) {
            Jwt jwt = ((JwtAuthenticationToken) authentication).getToken();
            return jwt.getClaimAsString("preferred_username");
        }
        return null;
    }

    public String getCurrentUserEmail() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication instanceof JwtAuthenticationToken) {
            Jwt jwt = ((JwtAuthenticationToken) authentication).getToken();
            return jwt.getClaimAsString("email");
        }
        return null;
    }

    public List<String> getCurrentUserRoles() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication instanceof JwtAuthenticationToken) {
            Jwt jwt = ((JwtAuthenticationToken) authentication).getToken();
            Map<String, Object> realmAccess = jwt.getClaimAsMap("realm_access");
            if (realmAccess != null) {
                return (List<String>) realmAccess.get("roles");
            }
        }
        return List.of();
    }

    public String getCustomClaim(String claimName) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication instanceof JwtAuthenticationToken) {
            Jwt jwt = ((JwtAuthenticationToken) authentication).getToken();
            return jwt.getClaimAsString(claimName);
        }
        return null;
    }

    public boolean hasRole(String role) {
        return getCurrentUserRoles().contains(role);
    }

    public boolean hasAnyRole(String... roles) {
        List<String> userRoles = getCurrentUserRoles();
        for (String role : roles) {
            if (userRoles.contains(role)) {
                return true;
            }
        }
        return false;
    }
}
```

### 5. Controller Example with Security Annotations
```java
package com.systech.nexus.controller;

import com.systech.nexus.util.JwtTokenUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class UserController {

    @Autowired
    private JwtTokenUtil jwtTokenUtil;

    @GetMapping("/public/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("API is healthy");
    }

    @GetMapping("/user/profile")
    @PreAuthorize("hasRole('nexus-user')")
    public ResponseEntity<Object> getUserProfile() {
        String userId = jwtTokenUtil.getCurrentUserId();
        String email = jwtTokenUtil.getCurrentUserEmail();

        Map<String, Object> profile = Map.of(
            "id", userId,
            "email", email,
            "roles", jwtTokenUtil.getCurrentUserRoles()
        );

        return ResponseEntity.ok(profile);
    }

    @GetMapping("/manager/users")
    @PreAuthorize("hasAnyRole('nexus-admin', 'nexus-manager')")
    public ResponseEntity<String> getUsers() {
        return ResponseEntity.ok("Users list for managers");
    }

    @PostMapping("/admin/system")
    @PreAuthorize("hasRole('nexus-admin')")
    public ResponseEntity<String> adminOperation() {
        return ResponseEntity.ok("Admin operation completed");
    }
}
```

## Environment Configuration Templates

### Development (.env.development)
```env
# Keycloak
REACT_APP_KEYCLOAK_URL=http://localhost:8090
REACT_APP_KEYCLOAK_REALM=nexus-dev
REACT_APP_KEYCLOAK_CLIENT_ID=nexus-web-app

# API
REACT_APP_API_BASE_URL=http://localhost:8080/api
KEYCLOAK_CLIENT_SECRET=your-dev-client-secret
```

### Production (.env.production)
```env
# Keycloak
REACT_APP_KEYCLOAK_URL=https://auth.nexus.systech.com
REACT_APP_KEYCLOAK_REALM=nexus-prod
REACT_APP_KEYCLOAK_CLIENT_ID=nexus-web-app

# API
REACT_APP_API_BASE_URL=https://api.nexus.systech.com/api
KEYCLOAK_CLIENT_SECRET=${KEYCLOAK_CLIENT_SECRET}
```

---

**✅ Modern Implementation**: These configurations implement current best practices for OAuth2/OIDC integration with React and Spring Boot.