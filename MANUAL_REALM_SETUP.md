# Manual Systech Realm Setup Guide

This guide provides step-by-step instructions to manually create the Systech realm with all groups, roles, and mappers.

## Prerequisites

✅ Keycloak running on http://localhost:8090
✅ Admin access (admin/secret)

---

## Step 1: Create the Realm

1. **Open Keycloak Admin Console**
   - Navigate to: http://localhost:8090/admin
   - Login: `admin` / `secret`

2. **Create Realm**
   - Click **"Add Realm"** (top left dropdown)
   - **Name**: `systech`
   - **Display Name**: `Systech Platform`
   - **Enabled**: ✅ ON
   - Click **"Create"**

3. **Configure Realm Settings**
   - Go to **Realm Settings** → **General**
   - **User-managed access**: ✅ ON
   - **Endpoints**: Note the realm endpoint URL
   - Click **"Save"**

---

## Step 2: Create Client

1. **Navigate to Clients**
   - Click **"Clients"** in left menu
   - Click **"Create"**

2. **Client Configuration**
   - **Client ID**: `systech-hrms-client`
   - **Name**: `Systech HRMS Application`
   - **Description**: `Main client for Systech HRMS platform`
   - **Client Protocol**: `openid-connect`
   - Click **"Save"**

3. **Client Settings**
   - **Access Type**: `public`
   - **Standard Flow Enabled**: ✅ ON
   - **Direct Access Grants Enabled**: ✅ ON
   - **Valid Redirect URIs**:
     ```
     http://localhost:3000/*
     http://localhost:3001/*
     http://localhost:8080/*
     ```
   - **Web Origins**:
     ```
     http://localhost:3000
     http://localhost:3001
     http://localhost:8080
     ```
   - Click **"Save"**

---

## Step 3: Create Realm Roles

1. **Navigate to Roles**
   - Click **"Roles"** in left menu
   - Click **"Add Role"**

2. **Create Admin Role**
   - **Role Name**: `systech-admin`
   - **Description**: `System Administrator with full access`
   - Click **"Save"**

3. **Create User Role**
   - Click **"Add Role"**
   - **Role Name**: `systech-user`
   - **Description**: `Regular system user`
   - Click **"Save"**

4. **Create Manager Role**
   - Click **"Add Role"**
   - **Role Name**: `systech-manager`
   - **Description**: `Department manager with elevated privileges`
   - Click **"Save"**

---

## Step 4: Create Groups Hierarchy

### 4.1 Create Root Groups

1. **Navigate to Groups**
   - Click **"Groups"** in left menu
   - Click **"New"**

2. **Create Department Groups**

**IT Department:**
- **Name**: `IT`
- **Path**: `/IT`
- Click **"Save"**

**HR Department:**
- **Name**: `HR`
- **Path**: `/HR`
- Click **"Save"**

**Finance Department:**
- **Name**: `Finance`
- **Path**: `/Finance`
- Click **"Save"**

**Operations Department:**
- **Name**: `Operations`
- **Path**: `/Operations`
- Click **"Save"**

### 4.2 Create Sub-Groups

**For IT Department:**
1. Click on **"IT"** group
2. Click **"New"** (creates subgroup)
3. Create these subgroups:
   - **Name**: `IT-Admins` → **Path**: `/IT/IT-Admins`
   - **Name**: `IT-Developers` → **Path**: `/IT/IT-Developers`
   - **Name**: `IT-Support` → **Path**: `/IT/IT-Support`

**For HR Department:**
1. Click on **"HR"** group
2. Create subgroups:
   - **Name**: `HR-Managers` → **Path**: `/HR/HR-Managers`
   - **Name**: `HR-Staff` → **Path**: `/HR/HR-Staff`
   - **Name**: `HR-Recruiters` → **Path**: `/HR/HR-Recruiters`

**For Finance Department:**
1. Click on **"Finance"** group
2. Create subgroups:
   - **Name**: `Finance-Managers` → **Path**: `/Finance/Finance-Managers`
   - **Name**: `Finance-Accountants` → **Path**: `/Finance/Finance-Accountants`
   - **Name**: `Finance-Auditors` → **Path**: `/Finance/Finance-Auditors`

**For Operations Department:**
1. Click on **"Operations"** group
2. Create subgroups:
   - **Name**: `Ops-Managers` → **Path**: `/Operations/Ops-Managers`
   - **Name**: `Ops-Staff` → **Path**: `/Operations/Ops-Staff`
   - **Name**: `Ops-Supervisors` → **Path**: `/Operations/Ops-Supervisors`

### 4.3 Create Access Level Groups

1. **Navigate back to main Groups**
2. **Create Access Groups:**

**Admin Access:**
- **Name**: `Admin-Access`
- **Path**: `/Admin-Access`

**Manager Access:**
- **Name**: `Manager-Access`
- **Path**: `/Manager-Access`

**User Access:**
- **Name**: `User-Access`
- **Path**: `/User-Access`

**Read Only Access:**
- **Name**: `ReadOnly-Access`
- **Path**: `/ReadOnly-Access`

---

## Step 5: Assign Roles to Groups

### 5.1 Assign Roles to Access Groups

**Admin-Access Group:**
1. Click **"Admin-Access"** group
2. Go to **"Role Mappings"** tab
3. **Available Roles** → Select `systech-admin`
4. Click **"Add selected"**

**Manager-Access Group:**
1. Click **"Manager-Access"** group
2. Go to **"Role Mappings"** tab
3. **Available Roles** → Select `systech-manager` and `systech-user`
4. Click **"Add selected"**

**User-Access Group:**
1. Click **"User-Access"** group
2. Go to **"Role Mappings"** tab
3. **Available Roles** → Select `systech-user`
4. Click **"Add selected"**

### 5.2 Assign Access to Department Groups

**IT-Admins:**
1. Click **"IT-Admins"** group
2. Go to **"Role Mappings"** tab
3. **Available Roles** → Select `systech-admin`
4. Click **"Add selected"**

**HR-Managers, Finance-Managers, Ops-Managers:**
1. For each manager group, assign `systech-manager` and `systech-user` roles

**All other department sub-groups:**
1. Assign `systech-user` role

---

## Step 6: Create Client Mappers

1. **Navigate to Client**
   - **Clients** → `systech-hrms-client`
   - Click **"Mappers"** tab

2. **Create Group Membership Mapper**
   - Click **"Create"**
   - **Name**: `group-membership`
   - **Mapper Type**: `Group Membership`
   - **Token Claim Name**: `groups`
   - **Full group path**: ✅ ON
   - **Add to ID token**: ✅ ON
   - **Add to access token**: ✅ ON
   - **Add to userinfo**: ✅ ON
   - Click **"Save"**

3. **Create User Roles Mapper**
   - Click **"Create"**
   - **Name**: `user-roles`
   - **Mapper Type**: `User Realm Role`
   - **Token Claim Name**: `roles`
   - **Add to ID token**: ✅ ON
   - **Add to access token**: ✅ ON
   - **Add to userinfo**: ✅ ON
   - Click **"Save"**

4. **Create Username Mapper**
   - Click **"Create"**
   - **Name**: `username`
   - **Mapper Type**: `User Property`
   - **Property**: `username`
   - **Token Claim Name**: `preferred_username`
   - **Add to ID token**: ✅ ON
   - **Add to access token**: ✅ ON
   - **Add to userinfo**: ✅ ON
   - Click **"Save"**

5. **Create Email Mapper**
   - Click **"Create"**
   - **Name**: `email`
   - **Mapper Type**: `User Property`
   - **Property**: `email`
   - **Token Claim Name**: `email`
   - **Add to ID token**: ✅ ON
   - **Add to access token**: ✅ ON
   - **Add to userinfo**: ✅ ON
   - Click **"Save"**

6. **Create Full Name Mapper**
   - Click **"Create"**
   - **Name**: `full-name`
   - **Mapper Type**: `User's full name`
   - **Token Claim Name**: `name`
   - **Add to ID token**: ✅ ON
   - **Add to access token**: ✅ ON
   - **Add to userinfo**: ✅ ON
   - Click **"Save"**

7. **Create Department Mapper (Custom)**
   - Click **"Create"**
   - **Name**: `department`
   - **Mapper Type**: `User Attribute`
   - **User Attribute**: `department`
   - **Token Claim Name**: `department`
   - **Add to ID token**: ✅ ON
   - **Add to access token**: ✅ ON
   - **Add to userinfo**: ✅ ON
   - Click **"Save"**

8. **Create Employee ID Mapper**
   - Click **"Create"**
   - **Name**: `employee-id`
   - **Mapper Type**: `User Attribute`
   - **User Attribute**: `employeeId`
   - **Token Claim Name**: `employee_id`
   - **Add to ID token**: ✅ ON
   - **Add to access token**: ✅ ON
   - **Add to userinfo**: ✅ ON
   - Click **"Save"**

---

## Step 7: Configure Authentication Flow (Optional)

1. **Navigate to Authentication**
   - Click **"Authentication"** in left menu
   - **Flows** tab

2. **Browser Flow Configuration**
   - Select **"Browser"** flow
   - Ensure these are **REQUIRED**:
     - Cookie
     - Username Password Form
   - **Identity Provider Redirector**: ALTERNATIVE

---

## Step 8: Test Configuration

### 8.1 Test Token Generation

```bash
# Test token request
curl -X POST http://localhost:8090/realms/systech/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=systech-hrms-client" \
  -d "username=YOUR_USERNAME" \
  -d "password=YOUR_PASSWORD"
```

### 8.2 Test Token Content

```bash
# Decode JWT token (use jwt.io or similar)
# Verify these claims are present:
# - groups: ["/Department/SubGroup"]
# - roles: ["systech-user"]
# - preferred_username: "username"
# - email: "user@example.com"
# - department: "IT"
# - employee_id: "EMP001"
```

---

## Step 9: User Creation Template

When creating users, include these attributes:

### Required User Attributes:
- **Username**: `firstname.lastname`
- **Email**: `user@systech.com`
- **First Name**: User's first name
- **Last Name**: User's last name
- **Email Verified**: ✅ ON

### Custom Attributes:
- **department**: `IT` | `HR` | `Finance` | `Operations`
- **employeeId**: `EMP001`, `EMP002`, etc.
- **position**: Job title
- **manager**: Manager's username

### Group Membership:
- Assign to appropriate department subgroup
- Assign to access level group

### Example User Creation:
```
Username: john.doe
Email: john.doe@systech.com
First Name: John
Last Name: Doe
Attributes:
  - department: IT
  - employeeId: EMP001
  - position: Senior Developer
Groups:
  - /IT/IT-Developers
  - /User-Access
```

---

## Quick Reference

### Created Groups Structure:
```
/IT
  /IT-Admins
  /IT-Developers
  /IT-Support
/HR
  /HR-Managers
  /HR-Staff
  /HR-Recruiters
/Finance
  /Finance-Managers
  /Finance-Accountants
  /Finance-Auditors
/Operations
  /Ops-Managers
  /Ops-Staff
  /Ops-Supervisors
/Admin-Access
/Manager-Access
/User-Access
/ReadOnly-Access
```

### Created Roles:
- `systech-admin` - Full system access
- `systech-manager` - Department management access
- `systech-user` - Regular user access

### Client Mappers:
- `group-membership` - Maps user groups to JWT
- `user-roles` - Maps user roles to JWT
- `username` - Maps username to preferred_username
- `email` - Maps email to email claim
- `full-name` - Maps full name to name claim
- `department` - Maps department attribute
- `employee-id` - Maps employee ID attribute

---

## Verification Steps

1. ✅ Realm created with proper settings
2. ✅ Client configured with correct redirect URIs
3. ✅ All groups created with proper hierarchy
4. ✅ Roles assigned to groups correctly
5. ✅ Client mappers configured for JWT claims
6. ✅ Token generation works
7. ✅ JWT contains expected claims (groups, roles, attributes)

## Troubleshooting

**Issue**: Token doesn't contain groups
- **Solution**: Check group mappers are enabled and "Add to access token" is ON

**Issue**: Groups appear as IDs instead of names
- **Solution**: Ensure "Full group path" is enabled in group mapper

**Issue**: Custom attributes missing
- **Solution**: Verify user attribute mappers are configured and enabled

**Issue**: Authentication fails
- **Solution**: Check user credentials and ensure user is enabled

---

This manual setup ensures you have complete control over your realm configuration and can verify each step works correctly.