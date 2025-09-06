#!/bin/bash
# Cloud-Native Gauntlet: Offline Image Preparation Script
# This script pulls all required images for offline deployment

set -euo pipefail

echo "=== Cloud-Native Gauntlet: Day 1-2 Image Preparation ==="
echo "Pulling required images for offline deployment..."

# Create images directory
mkdir -p ./images

# Images to pull
IMAGES=(
  "rancher/k3s:v1.28.2-k3s1"
  "quay.io/keycloak/keycloak:24.0.5"
  "postgres:15"
  "gitea/gitea:latest"
  "registry:2"
  "ghcr.io/cloudnative-pg/cloudnative-pg:1.26.0"
  "quay.io/argoproj/argocd:latest"
  "gcr.io/linkerd-io/proxy:stable-2.14.0"
  "gcr.io/linkerd-io/controller:stable-2.14.0"
)

for image in "${IMAGES[@]}"; do
    echo "Pulling image: $image"
    docker pull "$image"
    
    # Save image to tar file
    image_name=$(echo "$image" | tr '/' '-' | tr ':' '-')
    docker save "$image" -o "./images/${image_name}.tar"
    echo "Saved: ./images/${image_name}.tar"
done

echo "=== Image preparation complete ==="
echo "Images saved in ./images/ directory"
echo "Total images: ${#IMAGES[@]}"