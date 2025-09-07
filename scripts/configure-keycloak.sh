#!/bin/bash

# Configure Keycloak for Cloud-Native Gauntlet
KEYCLOAK_URL="http://10.43.86.103:8080"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin123"

echo "Configuring Keycloak..."

# Wait for Keycloak to be ready
echo "Waiting for Keycloak to be ready..."
until curl -s "$KEYCLOAK_URL/realms/master" > /dev/null; do
    echo "Waiting for Keycloak..."
    sleep 5
done

echo "Keycloak is ready!"

# Get admin token
echo "Getting admin token..."
ADMIN_TOKEN=$(curl -s -X POST "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=$ADMIN_USER" \
    -d "password=$ADMIN_PASSWORD" \
    -d "grant_type=password" \
    -d "client_id=admin-cli" | jq -r '.access_token')

if [ "$ADMIN_TOKEN" = "null" ] || [ -z "$ADMIN_TOKEN" ]; then
    echo "Failed to get admin token"
    exit 1
fi

echo "Admin token obtained"

# Create realm
echo "Creating cloud-gauntlet realm..."
curl -s -X POST "$KEYCLOAK_URL/admin/realms" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "realm": "cloud-gauntlet",
        "enabled": true,
        "displayName": "Cloud-Native Gauntlet",
        "loginWithEmailAllowed": true,
        "duplicateEmailsAllowed": false,
        "resetPasswordAllowed": true,
        "editUsernameAllowed": false,
        "bruteForceProtected": true
    }'

echo "Realm created"

# Create client
echo "Creating rust-api client..."
curl -s -X POST "$KEYCLOAK_URL/admin/realms/cloud-gauntlet/clients" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "clientId": "rust-api",
        "enabled": true,
        "publicClient": true,
        "standardFlowEnabled": true,
        "implicitFlowEnabled": false,
        "directAccessGrantsEnabled": true,
        "serviceAccountsEnabled": false,
        "redirectUris": ["http://api.local/*", "http://localhost:3000/*"],
        "webOrigins": ["http://api.local", "http://localhost:3000"],
        "protocol": "openid-connect"
    }'

echo "Client created"

# Create test user
echo "Creating test user..."
curl -s -X POST "$KEYCLOAK_URL/admin/realms/cloud-gauntlet/users" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "username": "testuser",
        "enabled": true,
        "email": "testuser@example.com",
        "firstName": "Test",
        "lastName": "User",
        "credentials": [{
            "type": "password",
            "value": "testpass123",
            "temporary": false
        }]
    }'

echo "Test user created"

echo "Keycloak configuration completed!"
echo "Admin Console: $KEYCLOAK_URL/admin"
echo "Realm: cloud-gauntlet"
echo "Client: rust-api"
echo "Test User: testuser / testpass123"
