#!/bin/bash
# Cloud-Native Gauntlet: Day 1-2 Complete Setup
# This script implements the assignment requirements for Days 1-2

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if running on supported OS
check_os() {
    log_step "Checking operating system..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        log_info "Linux detected - proceeding with setup"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        log_info "macOS detected - proceeding with setup"
    else
        log_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    local missing_tools=()
    
    if ! command -v vagrant &> /dev/null; then
        missing_tools+=("vagrant")
    fi
    
    if ! command -v terraform &> /dev/null; then
        missing_tools+=("terraform")
    fi
    
    if ! command -v ansible &> /dev/null; then
        missing_tools+=("ansible")
    fi
    
    if ! command -v docker &> /dev/null; then
        missing_tools+=("docker")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Please install the missing tools and run this script again"
        exit 1
    fi
    
    log_info "All prerequisites satisfied"
}

# Clean up previous runs
cleanup() {
    log_step "Cleaning up previous runs..."
    
    if [ -d ".vagrant" ]; then
        log_info "Destroying existing Vagrant VMs..."
        vagrant destroy -f
    fi
    
    if [ -d "terraform/.terraform" ]; then
        log_info "Cleaning Terraform state..."
        cd terraform && terraform destroy -auto-approve 2>/dev/null || true
        cd ..
    fi
    
    log_info "Cleanup complete"
}

# Generate configuration files
generate_configs() {
    log_step "Generating configuration files with Terraform..."
    
    cd terraform
    terraform init
    terraform apply -auto-approve
    cd ..
    
    log_info "Configuration files generated:"
    log_info "  - Ansible inventory: ansible/inventory.ini"
    log_info "  - Hosts file: scripts/hosts"
    log_info "  - Image pull script: scripts/pull-images.sh"
    log_info "  - Bootstrap script: scripts/bootstrap.sh"
}

# Setup local DNS
setup_dns() {
    log_step "Setting up local DNS..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        log_warn "macOS detected. Please manually add the following to /etc/hosts:"
        echo ""
        cat scripts/hosts
        echo ""
        log_warn "Run: sudo nano /etc/hosts"
        read -p "Press Enter after adding the hosts entries..."
    else
        log_info "Adding entries to /etc/hosts (requires sudo)..."
        if sudo cp scripts/hosts /etc/hosts.d/cloud-native-gauntlet 2>/dev/null; then
            log_info "DNS configuration added to /etc/hosts.d/"
        else
            log_warn "Could not add to /etc/hosts.d/, please manually add:"
            cat scripts/hosts
        fi
    fi
}

# Pull required images
pull_images() {
    log_step "Pulling required images for offline deployment..."
    
    if [ ! -f "scripts/pull-images.sh" ]; then
        log_error "Image pull script not found. Run Terraform first."
        exit 1
    fi
    
    chmod +x scripts/pull-images.sh
    ./scripts/pull-images.sh
    
    log_info "Images pulled and saved to ./images/ directory"
}

# Start VMs
start_vms() {
    log_step "Starting Vagrant VMs..."
    
    vagrant up
    
    log_info "VMs started successfully:"
    vagrant status
}

# Deploy base system
deploy_base() {
    log_step "Deploying base system with Ansible..."
    
    cd ansible
    ansible-playbook -i inventory.ini playbooks/base.yml
    cd ..
    
    log_info "Base system deployment complete"
}

# Deploy K3s
deploy_k3s() {
    log_step "Deploying K3s cluster..."
    
    cd ansible
    ansible-playbook -i inventory.ini playbooks/k3s.yml
    cd ..
    
    log_info "K3s cluster deployment complete"
}

# Verify cluster
verify_cluster() {
    log_step "Verifying K3s cluster..."
    
    vagrant ssh cn-master -- "kubectl get nodes"
    
    log_info "Cluster verification complete"
}

# Setup local registry
setup_registry() {
    log_step "Setting up local Docker registry..."
    
    vagrant ssh cn-master -- "docker run -d -p 5000:5000 --restart=always --name registry registry:2"
    
    log_info "Local registry running on cn-master:5000"
}

# Main execution
main() {
    echo "=========================================="
    echo "  Cloud-Native Gauntlet: Day 1-2 Setup"
    echo "=========================================="
    echo ""
    
    check_os
    check_prerequisites
    
    read -p "This will destroy any existing VMs. Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Setup cancelled"
        exit 0
    fi
    
    cleanup
    generate_configs
    setup_dns
    pull_images
    start_vms
    deploy_base
    deploy_k3s
    verify_cluster
    setup_registry
    
    echo ""
    echo "=========================================="
    echo "  Day 1-2 Setup Complete!"
    echo "=========================================="
    echo ""
    log_info "Your Cloud-Native Gauntlet infrastructure is ready!"
    echo ""
    log_info "Access your cluster:"
    log_info "  vagrant ssh cn-master"
    log_info "  kubectl get nodes"
    echo ""
    log_info "Next steps (Day 3-4):"
    log_info "  - Build your Rust application"
    log_info "  - Create Docker images"
    log_info "  - Deploy to K3s"
    echo ""
    log_info "Service endpoints (after Day 8):"
    log_info "  - Keycloak: http://keycloak.local"
    log_info "  - Gitea: http://gitea.local"
    log_info "  - Registry: http://registry.local"
    echo ""
}

# Run main function
main "$@"
