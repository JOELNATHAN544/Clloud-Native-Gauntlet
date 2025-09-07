#!/bin/bash

GITEA_URL="http://10.43.9.59:3000"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin123"
ADMIN_EMAIL="admin@example.com"

echo "Setting up Gitea..."

# Wait for Gitea to be ready
echo "Waiting for Gitea to be ready..."
until curl -s "$GITEA_URL/api/v1/version" > /dev/null; do
    echo "Waiting for Gitea..."
    sleep 5
done

echo "Gitea is ready!"

# Check if Gitea is already installed
if curl -s "$GITEA_URL/api/v1/version" | grep -q "version"; then
    echo "Gitea is already installed"
else
    echo "Gitea needs initial setup"
    exit 1
fi

# Create admin user and get session
echo "Creating admin user..."
ADMIN_TOKEN=$(curl -s -X POST "$GITEA_URL/api/v1/users" \
    -H "Content-Type: application/json" \
    -d "{
        \"username\": \"$ADMIN_USER\",
        \"email\": \"$ADMIN_EMAIL\",
        \"password\": \"$ADMIN_PASSWORD\",
        \"must_change_password\": false
    }" | jq -r '.id // empty')

if [ -z "$ADMIN_TOKEN" ]; then
    echo "Admin user might already exist, trying to login..."
    # Try to get token via login
    ADMIN_TOKEN=$(curl -s -X POST "$GITEA_URL/api/v1/tokens" \
        -H "Content-Type: application/json" \
        -d "{
            \"username\": \"$ADMIN_USER\",
            \"password\": \"$ADMIN_PASSWORD\"
        }" | jq -r '.sha1 // empty')
fi

if [ -z "$ADMIN_TOKEN" ]; then
    echo "Failed to get admin token"
    exit 1
fi

echo "Admin token obtained: ${ADMIN_TOKEN:0:10}..."

# Create app-source repository
echo "Creating app-source repository..."
curl -s -X POST "$GITEA_URL/api/v1/user/repos" \
    -H "Authorization: token $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"name\": \"app-source\",
        \"description\": \"Application source code repository\",
        \"private\": false,
        \"auto_init\": true
    }" > /dev/null

# Create infra repository
echo "Creating infra repository..."
curl -s -X POST "$GITEA_URL/api/v1/user/repos" \
    -H "Authorization: token $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"name\": \"infra\",
        \"description\": \"Infrastructure as Code repository\",
        \"private\": false,
        \"auto_init\": true
    }" > /dev/null

echo "Repositories created successfully!"
echo "Gitea URL: $GITEA_URL"
echo "Admin: $ADMIN_USER / $ADMIN_PASSWORD"
echo "Repositories: app-source, infra"

