# Architecture Decision Records (ADR)

## ADR-001: Keycloak Authentication System

**Date**: 2025-09-18
**Status**: ✅ Implemented
**Decision Maker**: Development Team

### Context
Need centralized authentication system for Nexus application (React frontend + Spring Boot backend + GraphQL API).

### Decision
- **Chosen**: Keycloak as identity provider
- **Alternative Considered**: Custom JWT implementation
- **Reason**: Industry standard, OAuth2/OIDC compliance, user management UI

---

## ADR-002: Single Client vs Multiple Clients

**Date**: 2025-09-18
**Status**: ✅ Implemented
**Decision Maker**: Development Team

### Context
Initial setup created separate clients for frontend (`nexus-web-app`) and backend (`nexus-api`). Question arose: do we need two clients for one application?

### Decision
- **Chosen**: Single client approach (`nexus-web-app` only)
- **Alternative Rejected**: Separate frontend/backend clients
- **Reason**:
  - Simpler architecture
  - React + Spring Boot = one logical application
  - Frontend gets token, backend validates (no client secret needed)
  - Easier maintenance and testing

### Implementation
- ❌ Deleted: `nexus-api` client
- ✅ Kept: `nexus-web-app` client (public, no client secret)
- ✅ Spring Boot: Uses JWT validation with public keys

---

## ADR-003: Authentication Flow for GraphQL Testing

**Date**: 2025-09-18
**Status**: ✅ Approved
**Decision Maker**: Development Team

### Context
Need way for developers to test GraphQL endpoints during development.

### Decision
- **Testing Flow**:
  1. Get JWT token via REST API call to Keycloak
  2. Use JWT token in Authorization header for GraphQL requests
- **No client secrets**: Spring Boot validates tokens using Keycloak's public keys

### Benefits
- Simple testing workflow
- No secrets to manage for API validation
- Secure: Only Keycloak can create valid tokens

---

## ADR-004: Development Environment Configuration

**Date**: 2025-09-18
**Status**: ✅ Implemented
**Decision Maker**: Development Team

### Configuration
- **Keycloak**: http://localhost:8090
- **Realm**: `nexus-dev`
- **Frontend URLs**: localhost:3000, localhost:3001
- **Backend URL**: localhost:8080
- **Client**: `nexus-web-app` (public client)

### Test Users
- Regular: nexus-user/nexus123 (role: nexus-user)
- Admin: nexus-admin/admin123 (roles: nexus-admin + nexus-user)

---

## Current Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   React     │    │ Spring Boot │    │  Keycloak   │
│  Frontend   │    │   Backend   │    │             │
│             │    │  + GraphQL  │    │             │
│ 1. Login ───┼────┼─────────────┼───→│ nexus-web   │
│ 2. Get JWT  │◄───┼─────────────┼───◄│ (single     │
│ 3. API Call │    │             │    │  client)    │
│   + JWT ────┼───→│ 4. Validate │    │             │
│             │    │    JWT ─────┼───→│ Public Keys │
│ 5. Response │◄───│             │    │             │
└─────────────┘    └─────────────┘    └─────────────┘
```

---

## Decision Status Legend
- ✅ **Implemented**: Decision made and implemented
- ⚠️ **Approved**: Decision made, implementation pending
- ❌ **Rejected**: Decision considered but rejected
- 🔄 **Under Review**: Currently being evaluated

---

## Notes
- Keep ADRs short and focused
- Document WHY decisions were made, not just WHAT
- Update status as implementation progresses
- Review periodically for relevance