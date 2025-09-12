#!/bin/bash

# Cloud-Native Gauntlet - Complete Cluster Setup Script
# This script sets up the entire cluster from scratch

set -e

echo "🚀 Starting Cloud-Native Gauntlet Setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Check if running from correct directory
if [ ! -f "Vagrantfile" ]; then
    error "Please run this script from the Cloud-Native-Gauntlet directory"
fi

# Step 1: Start VM and basic setup
log "Step 1: Starting VM and basic setup..."
vagrant up

# Step 2: Install base packages
log "Step 2: Installing base packages..."
vagrant ssh -c "sudo apt-get update && sudo apt-get install -y curl wget git"

# Step 3: Install Docker registry
log "Step 3: Setting up local Docker registry..."
vagrant ssh -c "
    docker run -d -p 5000:5000 --restart=always --name registry registry:2 || true
    echo 'Local registry started on port 5000'
"

# Step 4: Deploy PostgreSQL
log "Step 4: Deploying PostgreSQL database..."
vagrant ssh -c "kubectl apply -f /vagrant/k8s/database/"

# Step 5: Deploy Keycloak
log "Step 5: Deploying Keycloak..."
vagrant ssh -c "kubectl apply -f /vagrant/k8s/keycloak/"

# Step 6: Deploy Gitea
log "Step 6: Deploying Gitea..."
vagrant ssh -c "kubectl apply -f /vagrant/k8s/gitea/"

# Step 7: Deploy ArgoCD
log "Step 7: Deploying ArgoCD..."
vagrant ssh -c "kubectl apply -f /vagrant/k8s/argocd/"

# Step 8: Install Linkerd
log "Step 8: Installing Linkerd service mesh..."
vagrant ssh -c "
    # Install Linkerd CLI
    curl -sL https://run.linkerd.io/install-edge | sh
    export PATH=\$PATH:/home/vagrant/.linkerd2/bin
    echo 'export PATH=\$PATH:/home/vagrant/.linkerd2/bin' >> ~/.bashrc
    
    # Install Linkerd control plane (if not already installed)
    linkerd check --pre || true
    linkerd install --crds | kubectl apply -f - || true
    linkerd install | kubectl apply -f - || true
    linkerd viz install | kubectl apply -f - || true
    
    # Enable injection for app namespace
    kubectl annotate namespace app linkerd.io/inject=enabled --overwrite
"

# Step 9: Wait for services to be ready
log "Step 9: Waiting for services to be ready..."
vagrant ssh -c "
    echo 'Waiting for PostgreSQL...'
    kubectl wait --for=condition=ready pod -l app=postgres -n database --timeout=300s
    
    echo 'Waiting for Gitea...'
    kubectl wait --for=condition=ready pod -l app=gitea -n gitea --timeout=300s
    
    echo 'Waiting for ArgoCD...'
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
    
    echo 'Waiting for Linkerd...'
    kubectl wait --for=condition=ready pod -l linkerd.io/control-plane-component -n linkerd --timeout=300s
"

# Step 10: Configure Gitea repositories
log "Step 10: Setting up Gitea repositories..."
vagrant ssh -c "
    # Wait for Gitea to be fully ready
    sleep 30
    
    # Fix admin password requirement
    kubectl exec -it \$(kubectl get pods -n gitea -l app=gitea -o jsonpath='{.items[0].metadata.name}') -n gitea -- sqlite3 /data/gitea/gitea.db \"UPDATE user SET must_change_password = 0 WHERE name = 'admin';\" || true
    kubectl exec -it \$(kubectl get pods -n gitea -l app=gitea -o jsonpath='{.items[0].metadata.name}') -n gitea -- sqlite3 /data/gitea/gitea.db \"UPDATE user SET must_change_password = 0 WHERE name = 'argocd';\" || true
"

# Step 11: Deploy application
log "Step 11: Deploying application..."
vagrant ssh -c "kubectl apply -f /vagrant/k8s/app/"

# Step 12: Setup ArgoCD Application
log "Step 12: Setting up ArgoCD GitOps..."
vagrant ssh -c "kubectl apply -f /vagrant/k8s/argocd/application.yaml"

# Step 13: Build and push initial application image
log "Step 13: Building and pushing application image..."
vagrant ssh -c "
    cd /vagrant/apps/rust-api
    docker build -t localhost:5000/cloud-gauntlet-api:v1 .
    docker push localhost:5000/cloud-gauntlet-api:v1
"

# Step 14: Setup Gitea Actions Runner
log "Step 14: Setting up Gitea Actions Runner..."
vagrant ssh -c "kubectl apply -f /vagrant/k8s/gitea/gitea-runner.yaml"

# Step 15: Fix Linkerd viz dashboard access
log "Step 15: Fixing Linkerd viz dashboard access..."
vagrant ssh -c "
    # Restart viz components to fix connectivity
    kubectl rollout restart deployment/metrics-api -n linkerd-viz
    kubectl rollout restart deployment/prometheus -n linkerd-viz
    kubectl rollout restart deployment/web -n linkerd-viz
    
    # Wait for pods to be ready
    kubectl wait --for=condition=ready pod -l app=metrics-api -n linkerd-viz --timeout=120s
    kubectl wait --for=condition=ready pod -l app=prometheus -n linkerd-viz --timeout=120s
    kubectl wait --for=condition=ready pod -l app=web -n linkerd-viz --timeout=120s
    
    # Setup port forward for dashboard access
    nohup kubectl port-forward -n linkerd-viz svc/web 8084:8084 --address=0.0.0.0 > /dev/null 2>&1 &
"

# Step 16: Get access information
log "Step 16: Getting access information..."

VM_IP=\$(vagrant ssh -c "hostname -I | awk '{print \$1}'" 2>/dev/null | tr -d '\r')

echo ""
echo "🎉 Cloud-Native Gauntlet Setup Complete!"
echo ""
echo "📋 Access Information:"
echo "====================="
echo ""
echo "🌐 Services:"
echo "  • Gitea:             http://\${VM_IP}:31030"
echo "  • ArgoCD:            http://\${VM_IP}:32080"
echo "  • Keycloak:          http://\${VM_IP}:31080"
echo "  • Linkerd Dashboard: http://\${VM_IP}:8084"
echo "  • Rust API:          http://\${VM_IP}:31000"
echo ""
echo "🔑 Default Credentials:"
echo "  • Gitea Admin:     admin / admin123"
echo "  • ArgoCD Admin:    admin / \$(vagrant ssh -c \"kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d\" 2>/dev/null)"
echo "  • Keycloak Admin:  admin / admin123"
echo ""
echo "🚀 Quick Commands:"
echo "  • SSH to VM:       vagrant ssh"
echo "  • Check pods:      vagrant ssh -c 'kubectl get pods -A'"
echo "  • Linkerd check:   vagrant ssh -c 'export PATH=\$PATH:/home/vagrant/.linkerd2/bin && linkerd check'"
echo ""
echo "📚 Next Steps:"
echo "  1. Access Gitea and create your repositories"
echo "  2. Configure ArgoCD applications"
echo "  3. Deploy your applications with GitOps"
echo "  4. Monitor with Linkerd dashboard"
echo ""

log "Setup completed successfully! 🎉"
