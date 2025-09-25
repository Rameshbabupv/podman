package com.systech.nexus.controller;

import com.systech.nexus.util.JwtTokenUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * Test Controller for verifying Keycloak integration
 *
 * Single Client Architecture:
 * - All requests validated against nexus-web-app client tokens
 * - Role-based access control using Keycloak roles
 */
@RestController
@RequestMapping("/api")
@CrossOrigin(origins = {"http://localhost:3000", "http://localhost:3001"})
public class TestController {

    @Autowired
    private JwtTokenUtil jwtTokenUtil;

    /**
     * Public endpoint - no authentication required
     */
    @GetMapping("/public/health")
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "healthy");
        response.put("service", "nexus-api");
        response.put("authentication", "keycloak");
        response.put("client", "nexus-web-app");
        return ResponseEntity.ok(response);
    }

    /**
     * Get current user profile - requires authentication
     */
    @GetMapping("/user/profile")
    @PreAuthorize("hasRole('nexus-user')")
    public ResponseEntity<Map<String, Object>> getUserProfile() {
        Map<String, Object> profile = new HashMap<>();
        profile.put("userId", jwtTokenUtil.getCurrentUserId());
        profile.put("username", jwtTokenUtil.getCurrentUsername());
        profile.put("email", jwtTokenUtil.getCurrentUserEmail());
        profile.put("fullName", jwtTokenUtil.getCurrentUserFullName());
        profile.put("roles", jwtTokenUtil.getCurrentUserRoles());
        profile.put("isAdmin", jwtTokenUtil.isAdmin());
        profile.put("isManager", jwtTokenUtil.isManagerOrAdmin());

        return ResponseEntity.ok(profile);
    }

    /**
     * Manager-only endpoint
     */
    @GetMapping("/manager/users")
    @PreAuthorize("hasAnyRole('nexus-admin', 'nexus-manager')")
    public ResponseEntity<Map<String, Object>> getUsers() {
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Users list accessible to managers and admins");
        response.put("currentUser", jwtTokenUtil.getCurrentUsername());
        response.put("userRoles", jwtTokenUtil.getCurrentUserRoles());
        return ResponseEntity.ok(response);
    }

    /**
     * Admin-only endpoint
     */
    @PostMapping("/admin/system")
    @PreAuthorize("hasRole('nexus-admin')")
    public ResponseEntity<Map<String, Object>> adminOperation() {
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Admin operation completed successfully");
        response.put("performedBy", jwtTokenUtil.getCurrentUsername());
        response.put("adminRoles", jwtTokenUtil.getCurrentUserRoles());
        return ResponseEntity.ok(response);
    }

    /**
     * Token validation test endpoint
     */
    @GetMapping("/test/token")
    public ResponseEntity<Map<String, Object>> testToken() {
        Map<String, Object> tokenInfo = new HashMap<>();
        tokenInfo.put("valid", true);
        tokenInfo.put("userId", jwtTokenUtil.getCurrentUserId());
        tokenInfo.put("username", jwtTokenUtil.getCurrentUsername());
        tokenInfo.put("email", jwtTokenUtil.getCurrentUserEmail());
        tokenInfo.put("roles", jwtTokenUtil.getCurrentUserRoles());

        // Token details (for debugging)
        var jwt = jwtTokenUtil.getCurrentJwtToken();
        if (jwt != null) {
            tokenInfo.put("issuer", jwt.getIssuer());
            tokenInfo.put("audience", jwt.getAudience());
            tokenInfo.put("issuedAt", jwt.getIssuedAt());
            tokenInfo.put("expiresAt", jwt.getExpiresAt());
        }

        return ResponseEntity.ok(tokenInfo);
    }
}