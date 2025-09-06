#!/bin/bash
# Cloud-Native Gauntlet: Complete Bootstrap Script
# This script sets up the entire environment from scratch

set -euo pipefail

echo "=== Cloud-Native Gauntlet: Complete Bootstrap ==="
echo "Starting Day 1-2 setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "\033[0;32m[INFO]\033[0m $1"
}

log_warn() {
    echo -e "\033[1;33m[WARN]\033[0m $1"
}

log_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v vagrant &> /dev/null; then
        log_error "Vagrant is not installed. Please install Vagrant first."
        exit 1
    fi
    
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    if ! command -v ansible &> /dev/null; then
        log_error "Ansible is not installed. Please install Ansible first."
        exit 1
    fi
    
    log_info "All prerequisites satisfied"
}

# Generate configuration files
generate_configs() {
    log_info "Generating configuration files with Terraform..."
    cd terraform
    terraform init
    terraform apply -auto-approve
    cd ..
    log_info "Configuration files generated"
}

# Start VMs
start_vms() {
    log_info "Starting Vagrant VMs..."
    vagrant up
    log_info "VMs started successfully"
}

# Setup local DNS
setup_dns() {
    log_info "Setting up local DNS..."
    
    # Check if running on macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        log_warn "macOS detected. Please manually add the following to /etc/hosts:"
        cat scripts/hosts
        echo ""
        log_warn "Run: sudo nano /etc/hosts"
    else
        log_info "Adding entries to /etc/hosts (requires sudo)..."
        sudo cp scripts/hosts /etc/hosts.d/cloud-native-gauntlet
        log_info "DNS configuration added"
    fi
}

# Pull images
pull_images() {
    log_info "Pulling required images..."
    ./scripts/pull-images.sh
    log_info "Images pulled successfully"
}

# Deploy with Ansible
deploy_with_ansible() {
    log_info "Deploying with Ansible..."
    cd ansible
    ansible-playbook -i inventory.ini playbooks/base.yml
    ansible-playbook -i inventory.ini playbooks/k3s.yml
    cd ..
    log_info "Ansible deployment complete"
}

# Main execution
main() {
    log_info "Starting Cloud-Native Gauntlet bootstrap..."
    
    check_prerequisites
    generate_configs
    start_vms
    setup_dns
    pull_images
    deploy_with_ansible
    
    log_info "=== Bootstrap Complete ==="
    log_info "Your Cloud-Native Gauntlet is ready!"
    log_info "Master node: 192.168.56.10"
    log_info "Access your services at:"
    log_info "  - K3s Dashboard: https://192.168.56.10:6443"
    log_info "  - Keycloak: http://keycloak.local"
    log_info "  - Gitea: http://gitea.local"
    log_info "  - Registry: http://registry.local"
}

# Run main function
main "$@"
