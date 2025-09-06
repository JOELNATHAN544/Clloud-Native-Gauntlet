# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

# Cloud-Native Gauntlet Configuration - Single VM Setup
NUM_WORKERS = 0  # Start with just one VM
MASTER_MEM_MB = 6144  # 6GB for master (K3s + all services)
WORKER_MEM_MB = 4096  # 4GB for workers (not used yet)
MASTER_CPUS = 3
WORKER_CPUS = 2
BOX_NAME = "ubuntu/jammy64"
NETWORK_PREFIX = "192.168.56"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = BOX_NAME
  config.vm.synced_folder ".", "/vagrant"

  # Common provisioning: ensure Python for Ansible
  common_provision = <<-SHELL
    set -euo pipefail
    echo "=== Cloud-Native Gauntlet: Day 1-2 Setup ==="
    echo "Updating system packages..."
    sudo apt-get update -y
    sudo apt-get install -y python3 python3-apt python3-distutils apt-transport-https ca-certificates curl gnupg lsb-release
    
    # Set hostname resolution
    echo "127.0.0.1 localhost" | sudo tee -a /etc/hosts
    echo "=== Base system ready for Ansible ==="
  SHELL

  # Master node (K3s control plane + all services)
  config.vm.define "cn-master" do |master|
    master.vm.hostname = "cn-master"
    master.vm.network :private_network, ip: "#{NETWORK_PREFIX}.10"
    master.vm.provider :virtualbox do |vb|
      vb.memory = MASTER_MEM_MB
      vb.cpus = MASTER_CPUS
      vb.name = "Cloud-Native-Gauntlet-Master"
    end
    master.vm.provision "shell", inline: common_provision
    
    # Additional master-specific setup
    master.vm.provision "shell", inline: <<-SHELL
      echo "=== Master node specific setup ==="
      # Install Docker for local registry and image management
      curl -fsSL https://get.docker.com -o get-docker.sh
      sudo sh get-docker.sh
      sudo usermod -aG docker vagrant
      
      # Create local registry directory
      sudo mkdir -p /opt/registry/data
      sudo chown -R vagrant:vagrant /opt/registry
      
      echo "=== Master node ready ==="
    SHELL
  end

  # Worker nodes
  (1..NUM_WORKERS).each do |i|
    config.vm.define "cn-worker#{i}" do |node|
      node.vm.hostname = "cn-worker#{i}"
      node.vm.network :private_network, ip: "#{NETWORK_PREFIX}.1#{i}"
      node.vm.provider :virtualbox do |vb|
        vb.memory = WORKER_MEM_MB
        vb.cpus = WORKER_CPUS
        vb.name = "Cloud-Native-Gauntlet-Worker#{i}"
      end
      node.vm.provision "shell", inline: common_provision
    end
  end
end


