🧪 Testing Example:

  Step 1: Get Token

  curl -X POST http://localhost:8090/realms/nexus-dev/protocol/openid-connect/token \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password" \
    -d "client_id=nexus-web-app" \
    -d "username=nexus-admin" \
    -d "password=admin123"


    curl -X POST http://localhost:8090/realms/nexus-dev/protocol/openid-connect/token \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password" \
    -d "client_id=nexus-web-app" \
    -d "username=nexus-user" \
    -d "password=nexus123"


  Step 2: Use Token for GraphQL

  curl -X POST http://localhost:8080/graphql \
    -H "Authorization: Bearer <YOUR_JWT_TOKEN>" \
    -H "Content-Type: application/json" \
    -d '{"query": "{ users { id name email } }"}'

  🎯 Spring Boot Configuration (No Secret!):

  spring:
    security:
      oauth2:
        resourceserver:
          jwt:
            issuer-uri: http://localhost:8090/realms/nexus-dev
            # No client secret needed! Spring Boot gets public keys automatically



              Step 1: Test Token Generation (Keycloak)

  curl -X POST http://localhost:8090/realms/nexus-dev/protocol/openid-connect/token \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password" \
    -d "client_id=nexus-web-app" \
    -d "username=nexus-user" \
    -d "password=nexus123"

  Step 2: Test Spring Boot Endpoints (once your Spring Boot is running)

  # Test public endpoint (no token needed)
  curl http://localhost:8080/api/public/health

  # Test user profile (with token)
  curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
       http://localhost:8080/api/user/profile

     /e