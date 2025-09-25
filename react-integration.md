# React Frontend Integration with Keycloak

## Overview
This guide configures your React application to authenticate with Keycloak using the official Keycloak JavaScript adapter.

## Prerequisites
- Keycloak running on port 8090
- Realm `nexus-app` configured with `nexus-frontend` client
- React application running on port 3000/3001

## Step 1: Install Dependencies

```bash
# Install Keycloak JavaScript adapter
npm install keycloak-js

# Optional: For React context and hooks
npm install @react-keycloak/web

# For HTTP requests with authentication
npm install axios
```

## Step 2: Configure Keycloak Client

Create `src/keycloak.js`:

```javascript
import Keycloak from 'keycloak-js';

// Keycloak configuration
const keycloakConfig = {
  url: 'http://localhost:8090',
  realm: 'nexus-app',
  clientId: 'nexus-frontend',
};

// Initialize Keycloak instance
const keycloak = new Keycloak(keycloakConfig);

// Keycloak initialization options
export const keycloakInitOptions = {
  onLoad: 'check-sso', // or 'login-required'
  silentCheckSsoRedirectUri: window.location.origin + '/silent-check-sso.html',
  checkLoginIframe: false, // Disable for development
  pkceMethod: 'S256',
};

export default keycloak;
```

## Step 3: Create Authentication Context

Create `src/contexts/AuthContext.js`:

```javascript
import React, { createContext, useContext, useEffect, useState } from 'react';
import keycloak, { keycloakInitOptions } from '../keycloak';

const AuthContext = createContext();

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }) => {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(null);

  useEffect(() => {
    const initKeycloak = async () => {
      try {
        const authenticated = await keycloak.init(keycloakInitOptions);

        setIsAuthenticated(authenticated);

        if (authenticated) {
          setToken(keycloak.token);

          // Load user profile
          const profile = await keycloak.loadUserProfile();
          setUser({
            id: keycloak.subject,
            username: keycloak.tokenParsed?.preferred_username,
            email: profile.email,
            firstName: profile.firstName,
            lastName: profile.lastName,
            roles: keycloak.tokenParsed?.realm_access?.roles || [],
          });

          // Set up token refresh
          setInterval(() => {
            keycloak.updateToken(70).then((refreshed) => {
              if (refreshed) {
                setToken(keycloak.token);
                console.log('Token refreshed');
              }
            }).catch(() => {
              console.log('Failed to refresh token');
              logout();
            });
          }, 60000); // Check every minute
        }
      } catch (error) {
        console.error('Keycloak initialization failed:', error);
      } finally {
        setIsLoading(false);
      }
    };

    initKeycloak();
  }, []);

  const login = () => {
    keycloak.login();
  };

  const logout = () => {
    keycloak.logout();
  };

  const hasRole = (role) => {
    return user?.roles?.includes(role) || false;
  };

  const hasAnyRole = (roles) => {
    return roles.some(role => hasRole(role));
  };

  const value = {
    isAuthenticated,
    isLoading,
    user,
    token,
    login,
    logout,
    hasRole,
    hasAnyRole,
    keycloak,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
```

## Step 4: Create HTTP Client with Authentication

Create `src/services/httpClient.js`:

```javascript
import axios from 'axios';
import keycloak from '../keycloak';

// Create axios instance
const httpClient = axios.create({
  baseURL: 'http://localhost:8080/api',
  timeout: 10000,
});

// Request interceptor to add authentication token
httpClient.interceptors.request.use(
  (config) => {
    if (keycloak.token) {
      config.headers.Authorization = `Bearer ${keycloak.token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor to handle token refresh
httpClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    const original = error.config;

    if (error.response?.status === 401 && !original._retry) {
      original._retry = true;

      try {
        // Try to refresh token
        const refreshed = await keycloak.updateToken(5);
        if (refreshed) {
          // Retry the original request with new token
          original.headers.Authorization = `Bearer ${keycloak.token}`;
          return httpClient(original);
        }
      } catch (refreshError) {
        // Refresh failed, redirect to login
        keycloak.login();
        return Promise.reject(refreshError);
      }
    }

    return Promise.reject(error);
  }
);

export default httpClient;
```

## Step 5: Create API Service

Create `src/services/apiService.js`:

```javascript
import httpClient from './httpClient';

class ApiService {
  // Public endpoints
  async getPublicInfo() {
    const response = await httpClient.get('/public/info');
    return response.data;
  }

  async getHealth() {
    const response = await httpClient.get('/public/health');
    return response.data;
  }

  // Authentication endpoints
  async getUserInfo() {
    const response = await httpClient.get('/auth/user-info');
    return response.data;
  }

  async validateToken() {
    const response = await httpClient.get('/auth/validate-token');
    return response.data;
  }

  // User endpoints
  async getUserProfile() {
    const response = await httpClient.get('/user/profile');
    return response.data;
  }

  async getUserDashboard() {
    const response = await httpClient.get('/user/dashboard');
    return response.data;
  }

  // Admin endpoints
  async getAllUsers() {
    const response = await httpClient.get('/admin/users');
    return response.data;
  }

  async getSystemInfo() {
    const response = await httpClient.get('/admin/system-info');
    return response.data;
  }
}

export default new ApiService();
```

## Step 6: Create Protected Route Component

Create `src/components/ProtectedRoute.js`:

```javascript
import React from 'react';
import { useAuth } from '../contexts/AuthContext';

const ProtectedRoute = ({ children, roles = [], requireAuth = true }) => {
  const { isAuthenticated, isLoading, hasAnyRole, login } = useAuth();

  if (isLoading) {
    return (
      <div className="flex justify-center items-center min-h-screen">
        <div className="text-lg">Loading...</div>
      </div>
    );
  }

  if (requireAuth && !isAuthenticated) {
    return (
      <div className="flex flex-col justify-center items-center min-h-screen">
        <h2 className="text-2xl font-bold mb-4">Authentication Required</h2>
        <p className="mb-4">You need to log in to access this page.</p>
        <button
          onClick={login}
          className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
        >
          Login
        </button>
      </div>
    );
  }

  if (roles.length > 0 && !hasAnyRole(roles)) {
    return (
      <div className="flex flex-col justify-center items-center min-h-screen">
        <h2 className="text-2xl font-bold mb-4">Access Denied</h2>
        <p>You don't have permission to access this page.</p>
        <p className="text-sm text-gray-600">Required roles: {roles.join(', ')}</p>
      </div>
    );
  }

  return children;
};

export default ProtectedRoute;
```

## Step 7: Create User Profile Component

Create `src/components/UserProfile.js`:

```javascript
import React from 'react';
import { useAuth } from '../contexts/AuthContext';

const UserProfile = () => {
  const { user, logout, hasRole } = useAuth();

  if (!user) return null;

  return (
    <div className="bg-white shadow rounded-lg p-6">
      <div className="flex justify-between items-start mb-4">
        <h2 className="text-2xl font-bold">User Profile</h2>
        <button
          onClick={logout}
          className="bg-red-500 hover:bg-red-700 text-white font-bold py-2 px-4 rounded"
        >
          Logout
        </button>
      </div>

      <div className="space-y-2">
        <p><strong>Username:</strong> {user.username}</p>
        <p><strong>Email:</strong> {user.email}</p>
        <p><strong>First Name:</strong> {user.firstName}</p>
        <p><strong>Last Name:</strong> {user.lastName}</p>
        <p><strong>User ID:</strong> {user.id}</p>

        <div>
          <strong>Roles:</strong>
          <div className="flex flex-wrap gap-2 mt-1">
            {user.roles?.map((role) => (
              <span
                key={role}
                className={`px-2 py-1 rounded text-sm ${
                  role === 'admin'
                    ? 'bg-red-100 text-red-800'
                    : 'bg-blue-100 text-blue-800'
                }`}
              >
                {role}
              </span>
            ))}
          </div>
        </div>

        <div className="mt-4">
          <h3 className="font-semibold">Permissions:</h3>
          <ul className="list-disc list-inside text-sm">
            <li>Can access user dashboard: {hasRole('user') ? '✅' : '❌'}</li>
            <li>Can access admin panel: {hasRole('admin') ? '✅' : '❌'}</li>
          </ul>
        </div>
      </div>
    </div>
  );
};

export default UserProfile;
```

## Step 8: Create Dashboard Components

Create `src/components/UserDashboard.js`:

```javascript
import React, { useState, useEffect } from 'react';
import { useAuth } from '../contexts/AuthContext';
import apiService from '../services/apiService';

const UserDashboard = () => {
  const { user } = useAuth();
  const [dashboardData, setDashboardData] = useState(null);
  const [userProfile, setUserProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [dashboard, profile] = await Promise.all([
          apiService.getUserDashboard(),
          apiService.getUserProfile(),
        ]);

        setDashboardData(dashboard);
        setUserProfile(profile);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  if (loading) return <div>Loading dashboard...</div>;
  if (error) return <div className="text-red-500">Error: {error}</div>;

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold">Welcome, {user?.firstName || user?.username}!</h1>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-lg shadow">
          <h2 className="text-xl font-semibold mb-4">Dashboard Data</h2>
          <p>{dashboardData?.message}</p>
          <p className="text-sm text-gray-600">{dashboardData?.data}</p>
        </div>

        <div className="bg-white p-6 rounded-lg shadow">
          <h2 className="text-xl font-semibold mb-4">Profile Information</h2>
          <p>{userProfile?.message}</p>
          <p><strong>Username:</strong> {userProfile?.username}</p>
          <p><strong>Email:</strong> {userProfile?.email}</p>
        </div>
      </div>
    </div>
  );
};

export default UserDashboard;
```

Create `src/components/AdminPanel.js`:

```javascript
import React, { useState, useEffect } from 'react';
import { useAuth } from '../contexts/AuthContext';
import apiService from '../services/apiService';

const AdminPanel = () => {
  const { hasRole } = useAuth();
  const [users, setUsers] = useState(null);
  const [systemInfo, setSystemInfo] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (!hasRole('admin')) {
      setError('Access denied: Admin role required');
      setLoading(false);
      return;
    }

    const fetchAdminData = async () => {
      try {
        const [usersData, sysInfo] = await Promise.all([
          apiService.getAllUsers(),
          apiService.getSystemInfo(),
        ]);

        setUsers(usersData);
        setSystemInfo(sysInfo);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchAdminData();
  }, [hasRole]);

  if (loading) return <div>Loading admin panel...</div>;
  if (error) return <div className="text-red-500">Error: {error}</div>;

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold">Admin Panel</h1>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-lg shadow">
          <h2 className="text-xl font-semibold mb-4">User Management</h2>
          <p>{users?.message}</p>
          <p className="text-sm text-gray-600">{users?.data}</p>
        </div>

        <div className="bg-white p-6 rounded-lg shadow">
          <h2 className="text-xl font-semibold mb-4">System Information</h2>
          <p>{systemInfo?.message}</p>
          <p><strong>Status:</strong> {systemInfo?.status}</p>
        </div>
      </div>
    </div>
  );
};

export default AdminPanel;
```

## Step 9: Update Main App Component

Update `src/App.js`:

```javascript
import React from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import ProtectedRoute from './components/ProtectedRoute';
import UserProfile from './components/UserProfile';
import UserDashboard from './components/UserDashboard';
import AdminPanel from './components/AdminPanel';

// Navigation component
const Navigation = () => {
  const { isAuthenticated, user, login, logout, hasRole } = useAuth();

  return (
    <nav className="bg-blue-600 text-white p-4">
      <div className="container mx-auto flex justify-between items-center">
        <Link to="/" className="text-xl font-bold">Nexus App</Link>

        <div className="flex items-center space-x-4">
          {isAuthenticated ? (
            <>
              <span>Welcome, {user?.username}!</span>
              <Link to="/dashboard" className="hover:underline">Dashboard</Link>
              {hasRole('admin') && (
                <Link to="/admin" className="hover:underline">Admin</Link>
              )}
              <Link to="/profile" className="hover:underline">Profile</Link>
              <button onClick={logout} className="hover:underline">Logout</button>
            </>
          ) : (
            <button onClick={login} className="hover:underline">Login</button>
          )}
        </div>
      </div>
    </nav>
  );
};

// Home component
const Home = () => {
  const { isAuthenticated, user } = useAuth();

  return (
    <div className="container mx-auto mt-8 p-4">
      <h1 className="text-4xl font-bold mb-6">Welcome to Nexus Application</h1>

      {isAuthenticated ? (
        <div>
          <p className="text-lg mb-4">Hello, {user?.firstName || user?.username}!</p>
          <p>You are successfully authenticated with Keycloak.</p>
        </div>
      ) : (
        <div>
          <p className="text-lg mb-4">Please log in to access the application.</p>
        </div>
      )}
    </div>
  );
};

// Main App component
const AppContent = () => {
  const { isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className="flex justify-center items-center min-h-screen">
        <div className="text-lg">Initializing...</div>
      </div>
    );
  }

  return (
    <Router>
      <div className="min-h-screen bg-gray-100">
        <Navigation />

        <Routes>
          <Route path="/" element={<Home />} />

          <Route
            path="/profile"
            element={
              <ProtectedRoute>
                <div className="container mx-auto mt-8 p-4">
                  <UserProfile />
                </div>
              </ProtectedRoute>
            }
          />

          <Route
            path="/dashboard"
            element={
              <ProtectedRoute roles={['user']}>
                <div className="container mx-auto mt-8 p-4">
                  <UserDashboard />
                </div>
              </ProtectedRoute>
            }
          />

          <Route
            path="/admin"
            element={
              <ProtectedRoute roles={['admin']}>
                <div className="container mx-auto mt-8 p-4">
                  <AdminPanel />
                </div>
              </ProtectedRoute>
            }
          />
        </Routes>
      </div>
    </Router>
  );
};

function App() {
  return (
    <AuthProvider>
      <AppContent />
    </AuthProvider>
  );
}

export default App;
```

## Step 10: Create Silent Check SSO File

Create `public/silent-check-sso.html`:

```html
<html>
<body>
    <script>
        parent.postMessage(location.href, location.origin);
    </script>
</body>
</html>
```

## Step 11: Update Package.json Scripts (Optional)

Add these scripts to your `package.json`:

```json
{
  "scripts": {
    "start": "react-scripts start",
    "start:3001": "PORT=3001 react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject"
  }
}
```

## Testing the Integration

1. **Start your React app**: `npm start`
2. **Navigate to**: `http://localhost:3000`
3. **Test login flow**:
   - Click "Login" → redirects to Keycloak
   - Login with `testuser` / `password123`
   - Should redirect back to React app authenticated

4. **Test protected routes**:
   - `/dashboard` (requires 'user' role)
   - `/admin` (requires 'admin' role)
   - `/profile` (requires authentication)

## Key Features

- **Automatic token refresh**: Tokens are refreshed automatically
- **Role-based access**: Different components for different roles
- **HTTP interceptors**: Automatic token injection in API calls
- **Protected routes**: Route-level authentication and authorization
- **Error handling**: Graceful handling of authentication errors

## Troubleshooting

- **CORS errors**: Ensure Keycloak client has correct origin URLs
- **Redirect loops**: Check `onLoad` configuration in keycloak init
- **Token issues**: Verify client configuration and realm settings
- **Role access**: Ensure users have proper roles assigned in Keycloak

## Next Steps
- Test the complete authentication flow
- Review [Testing Guide](./testing-troubleshooting.md) for comprehensive testing
- Implement additional features like password reset, profile updates, etc.