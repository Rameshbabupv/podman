# Keycloak Realm Configuration Guide

## Overview
This guide walks through creating and configuring a Keycloak realm for your Spring Boot + React application.

## Step 1: Create Application Realm

1. **Access Admin Console**
   - Navigate to http://localhost:8090
   - Click "Administration Console"
   - Login with `admin` / `admin`

2. **Create New Realm**
   - Hover over "Master" realm dropdown (top-left)
   - Click "Create Realm"
   - **Realm name**: `nexus-app`
   - **Enabled**: ✅ (checked)
   - Click "Create"

## Step 2: Configure Realm Settings

1. **Navigate to Realm Settings**
   - Click "Realm Settings" in left sidebar
   - Go to "General" tab

2. **Configure Basic Settings**
   - **Display name**: `Nexus Application`
   - **Frontend URL**: Leave empty for development
   - **Require SSL**: `None` (for development)
   - Click "Save"

3. **Configure Login Settings**
   - Go to "Login" tab
   - **User registration**: ✅ (enable for testing)
   - **Forgot password**: ✅ (enable)
   - **Remember me**: ✅ (enable)
   - **Login with email**: ✅ (enable)
   - Click "Save"

## Step 3: Create Spring Boot Client (Backend)

1. **Create Client**
   - Click "Clients" in left sidebar
   - Click "Create client"
   - **Client type**: `OpenID Connect`
   - **Client ID**: `nexus-backend`
   - Click "Next"

2. **Configure Capability**
   - **Client authentication**: ✅ (ON - confidential client)
   - **Authorization**: ❌ (OFF)
   - **Standard flow**: ✅ (ON)
   - **Service accounts roles**: ✅ (ON)
   - Click "Next"

3. **Configure Access Settings**
   - **Root URL**: `http://localhost:8080`
   - **Home URL**: `http://localhost:8080`
   - **Valid redirect URIs**:
     ```
     http://localhost:8080/*
     http://localhost:8080/login/oauth2/code/keycloak
     ```
   - **Valid post logout redirect URIs**: `http://localhost:8080/*`
   - **Web origins**: `http://localhost:8080`
   - Click "Save"

4. **Get Client Secret**
   - Go to "Credentials" tab
   - Copy the **Client secret** (save for Spring Boot configuration)

## Step 4: Create React Client (Frontend)

1. **Create Client**
   - Click "Clients" in left sidebar
   - Click "Create client"
   - **Client type**: `OpenID Connect`
   - **Client ID**: `nexus-frontend`
   - Click "Next"

2. **Configure Capability**
   - **Client authentication**: ❌ (OFF - public client)
   - **Authorization**: ❌ (OFF)
   - **Standard flow**: ✅ (ON)
   - **Implicit flow**: ❌ (OFF)
   - **Direct access grants**: ✅ (ON)
   - Click "Next"

3. **Configure Access Settings**
   - **Root URL**: `http://localhost:3000`
   - **Home URL**: `http://localhost:3000`
   - **Valid redirect URIs**:
     ```
     http://localhost:3000/*
     http://localhost:3001/*
     ```
   - **Valid post logout redirect URIs**:
     ```
     http://localhost:3000/*
     http://localhost:3001/*
     ```
   - **Web origins**:
     ```
     http://localhost:3000
     http://localhost:3001
     ```
   - Click "Save"

## Step 5: Create Roles

1. **Create Realm Roles**
   - Click "Realm roles" in left sidebar
   - Click "Create role"

2. **Create User Role**
   - **Role name**: `user`
   - **Description**: `Standard user access`
   - Click "Save"

3. **Create Admin Role**
   - Click "Create role"
   - **Role name**: `admin`
   - **Description**: `Administrator access`
   - Click "Save"

## Step 6: Create Test Users

1. **Create Standard User**
   - Click "Users" in left sidebar
   - Click "Create new user"
   - **Username**: `testuser`
   - **Email**: `testuser@example.com`
   - **First name**: `Test`
   - **Last name**: `User`
   - **Email verified**: ✅
   - **Enabled**: ✅
   - Click "Create"

2. **Set Password**
   - Go to "Credentials" tab
   - Click "Set password"
   - **Password**: `password123`
   - **Temporary**: ❌ (OFF)
   - Click "Save"

3. **Assign Roles**
   - Go to "Role mapping" tab
   - Click "Assign role"
   - Select `user` role
   - Click "Assign"

4. **Create Admin User**
   - Repeat steps 1-3 with:
     - **Username**: `admin`
     - **Email**: `admin@example.com`
     - **Password**: `admin123`
     - **Roles**: Both `user` and `admin`

## Step 7: Test Configuration

1. **Test User Login**
   - Open new browser tab
   - Navigate to: `http://localhost:8090/realms/nexus-app/account`
   - Login with `testuser` / `password123`
   - Verify successful login

2. **Verify Client Configuration**
   - In admin console, go to "Clients"
   - Check both clients are created and enabled
   - Verify redirect URIs are correct

## Configuration Summary

**Realm**: `nexus-app`
**Clients**:
- `nexus-backend` (confidential) - for Spring Boot
- `nexus-frontend` (public) - for React

**Roles**: `user`, `admin`
**Test Users**:
- `testuser` / `password123` (user role)
- `admin` / `admin123` (user + admin roles)

## Important URLs for Integration

- **Realm URL**: `http://localhost:8090/realms/nexus-app`
- **OpenID Configuration**: `http://localhost:8090/realms/nexus-app/.well-known/openid_configuration`
- **Token Endpoint**: `http://localhost:8090/realms/nexus-app/protocol/openid-connect/token`
- **Auth Endpoint**: `http://localhost:8090/realms/nexus-app/protocol/openid-connect/auth`

## Next Steps
- Proceed to [Spring Boot Integration](./spring-boot-integration.md)
- Then configure [React Integration](./react-integration.md)