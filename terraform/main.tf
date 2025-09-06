terraform {
  required_version = ">= 1.3.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }
    template = {
      source  = "hashicorp/template"
      version = ">= 2.2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.0"
    }
  }
}

# Cloud-Native Gauntlet Infrastructure Configuration
locals {
  network_prefix = var.network_prefix
  master = {
    name = "cn-master"
    ip   = "${local.network_prefix}.10"
    role = "master"
  }
  workers = [for i in range(1, var.num_workers + 1) : {
    name = "cn-worker${i}"
    ip   = "${local.network_prefix}.1${i}"
    role = "worker"
  }]
  all_nodes = concat([local.master], local.workers)
  
  # Offline image list for Day 1-2 preparation
  required_images = [
    "rancher/k3s:v1.28.2-k3s1",
    "rancher/k3s:v1.28.2-k3s1",
    "quay.io/keycloak/keycloak:24.0.5",
    "postgres:15",
    "gitea/gitea:latest",
    "registry:2",
    "ghcr.io/cloudnative-pg/cloudnative-pg:1.26.0",
    "quay.io/argoproj/argocd:latest",
    "gcr.io/linkerd-io/proxy:stable-2.14.0",
    "gcr.io/linkerd-io/controller:stable-2.14.0"
  ]
}

# Generate Ansible inventory
data "template_file" "inventory" {
  template = file("${path.module}/inventory.tmpl")
  vars = {
    master_name = local.master.name
    master_ip   = local.master.ip
    workers     = jsonencode(local.workers)
    network_prefix = local.network_prefix
  }
}

# Generate hosts file for local DNS resolution
data "template_file" "hosts" {
  template = file("${path.module}/hosts.tmpl")
  vars = {
    master_ip = local.master.ip
    network_prefix = local.network_prefix
  }
}

# Generate offline image pull script
data "template_file" "pull_images" {
  template = file("${path.module}/pull-images.tmpl")
  vars = {
    images = jsonencode(local.required_images)
  }
}

# Create Ansible inventory
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory.ini"
  content  = data.template_file.inventory.rendered
}

# Create hosts file for local DNS
resource "local_file" "hosts_file" {
  filename = "${path.module}/../scripts/hosts"
  content  = data.template_file.hosts.rendered
}

# Create image pull script
resource "local_file" "pull_images_script" {
  filename = "${path.module}/../scripts/pull-images.sh"
  content  = data.template_file.pull_images.rendered
  file_permission = "0755"
}

# Create bootstrap script
resource "local_file" "bootstrap_script" {
  filename = "${path.module}/../scripts/bootstrap.sh"
  content = templatefile("${path.module}/bootstrap.tmpl", {
    network_prefix = local.network_prefix
    master_ip = local.master.ip
  })
  file_permission = "0755"
}

output "inventory_path" {
  value = local_file.ansible_inventory.filename
}

output "hosts_file_path" {
  value = local_file.hosts_file.filename
}

output "pull_images_script_path" {
  value = local_file.pull_images_script.filename
}

output "bootstrap_script_path" {
  value = local_file.bootstrap_script.filename
}


