# Spring Boot JWT Implementation Checklist

## 📋 **When You're Ready to Add JWT to Spring Boot**

Use this checklist to implement JWT authentication step by step.

---

## 🎯 **Pre-Implementation Checklist**

- [ ] Spring Boot application is working without authentication
- [ ] GraphQL endpoints are functional
- [ ] Ready to add security layer
- [ ] Keycloak server is running (http://localhost:8090)

---

## 🛠️ **Implementation Steps**

### **Step 1: Dependencies**
- [ ] Add `spring-boot-starter-security` to pom.xml
- [ ] Add `spring-boot-starter-oauth2-resource-server` to pom.xml
- [ ] Add `spring-security-oauth2-jose` to pom.xml
- [ ] Run `mvn clean install` to download dependencies

### **Step 2: Configuration Files**
- [ ] Copy `SecurityConfig.java` to your project (adjust package names)
- [ ] Copy `JwtTokenUtil.java` to your project (adjust package names)
- [ ] Update `application.yml` with JWT configuration
- [ ] Add CORS configuration for React frontend

### **Step 3: Test Setup**
- [ ] Copy `TestController.java` for testing (optional)
- [ ] Start your Spring Boot application
- [ ] Verify application starts without errors

### **Step 4: Basic Testing**
- [ ] Test public endpoint: `GET /api/public/health`
- [ ] Get JWT token from Keycloak using curl
- [ ] Test protected endpoint with JWT token
- [ ] Verify role-based access control

### **Step 5: GraphQL Integration**
- [ ] Add `@PreAuthorize` annotations to GraphQL resolvers
- [ ] Test GraphQL with JWT token
- [ ] Verify user context is available in resolvers
- [ ] Test role-based GraphQL access

### **Step 6: React Integration (Later)**
- [ ] Install keycloak-js in React app
- [ ] Configure Keycloak provider
- [ ] Implement login/logout flows
- [ ] Add JWT tokens to API calls

---

## 🧪 **Testing Commands**

### **Get JWT Token**
```bash
curl -X POST http://localhost:8090/realms/nexus-dev/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=nexus-web-app" \
  -d "username=nexus-user" \
  -d "password=nexus123"
```

### **Test Spring Boot Endpoints**
```bash
# Public endpoint (no token needed)
curl http://localhost:8080/api/public/health

# Protected endpoint (with token)
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
     http://localhost:8080/api/user/profile

# GraphQL endpoint (with token)
curl -X POST http://localhost:8080/graphql \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ users { id name } }"}'
```

---

## 🔧 **Troubleshooting Checklist**

### **Common Issues**
- [ ] **App won't start**: Check dependencies in pom.xml
- [ ] **401 Unauthorized**: Verify JWT token is valid and not expired
- [ ] **403 Forbidden**: Check user has required roles
- [ ] **CORS errors**: Verify CORS configuration in SecurityConfig
- [ ] **JWT validation fails**: Check Keycloak issuer-uri in application.yml

### **Debug Steps**
- [ ] Enable debug logging: `logging.level.org.springframework.security: DEBUG`
- [ ] Check JWT token claims using jwt.io
- [ ] Verify Keycloak discovery endpoint is accessible
- [ ] Test with different users (nexus-user vs nexus-admin)

---

## 📊 **Verification Checklist**

After implementation, verify these work:

- [ ] **Authentication**: Users can get JWT tokens from Keycloak
- [ ] **Authorization**: Role-based access control works
- [ ] **GraphQL**: Protected queries require authentication
- [ ] **CORS**: React frontend can make authenticated requests
- [ ] **User Context**: JWT user info is available in your code
- [ ] **Token Refresh**: Handle token expiration gracefully

---

## 🎯 **Success Criteria**

✅ **Implementation Complete When**:
- [ ] Spring Boot validates JWT tokens from Keycloak
- [ ] Role-based access control works for all endpoints
- [ ] GraphQL endpoints are properly secured
- [ ] User information is extractable from JWT tokens
- [ ] No security vulnerabilities in configuration
- [ ] Documentation is updated with new endpoints

---

## 📁 **Reference Files**

| File | Purpose | Location |
|------|---------|----------|
| SecurityConfig.java | Security configuration | spring-boot-config/ |
| JwtTokenUtil.java | JWT utility methods | spring-boot-config/ |
| application.yml | Spring Boot config | spring-boot-config/ |
| TestController.java | Test endpoints | spring-boot-config/ |
| pom.xml | Dependencies | spring-boot-config/ |

---

## 🚀 **Ready to Implement?**

When you're ready to add JWT authentication to your Spring Boot application, work through this checklist step by step. Each step builds on the previous one, making implementation smooth and predictable.

**Current Status**: All configuration files are prepared and ready to use! 🎯