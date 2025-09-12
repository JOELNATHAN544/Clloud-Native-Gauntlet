# Cloud-Native Gauntlet: Complete Cloud-Native Stack ⚔️

> **"So you thought LPIX 1xx was 'hard'? 😴 That was baby Linux with juice boxes 🍼 nap time 💤, and a coloring book 🖍️."**

Welcome to the **Cloud-Native Gauntlet** - a complete cloud-native application stack with GitOps, service mesh, and observability running entirely offline on your local machine.

## 🎯 What You Get

A fully automated cloud-native stack that includes:

- **Kubernetes Cluster** (K3s) with 3 nodes
- **GitOps Pipeline** (ArgoCD + Gitea Actions)
- **Service Mesh** (Linkerd with mTLS)
- **Identity Management** (Keycloak)
- **Database** (PostgreSQL)
- **Container Registry** (Local Docker registry)
- **Rust API Application** with JWT authentication
- **Complete Observability** (Linkerd viz dashboard)

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Cloud-Native Gauntlet                    │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   cn-master │  │ cn-worker1  │  │ cn-worker2  │         │
│  │   (K3s)     │  │   (K3s)     │  │   (K3s)     │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
├─────────────────────────────────────────────────────────────┤
│  GitOps: ArgoCD + Gitea Actions | Service Mesh: Linkerd    │
│  Auth: Keycloak | Database: PostgreSQL | Registry: Local   │
│  App: Rust API with JWT Auth + mTLS Encryption             │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 One-Command Complete Setup

### Prerequisites

- **Vagrant** (latest)
- **VirtualBox** (latest)
- **8GB+ RAM** (for VMs)
- **20GB+ free disk space**

### Complete Automated Setup

```bash
# Clone the repository
git clone <your-repo-url>
cd Cloud-Native-Gauntlet

# Run the complete setup script
chmod +x scripts/setup-cluster.sh
./scripts/setup-cluster.sh
```

**That's it!** This single script will:

1. ✅ Start and configure VMs
2. ✅ Deploy K3s cluster
3. ✅ Install PostgreSQL database
4. ✅ Deploy Keycloak for authentication
5. ✅ Setup Gitea with Actions runner
6. ✅ Install ArgoCD for GitOps
7. ✅ Deploy Linkerd service mesh
8. ✅ Build and deploy Rust API application
9. ✅ Configure GitOps pipeline
10. ✅ Setup observability dashboard
11. ✅ Enable mTLS encryption
12. ✅ Provide all access URLs and credentials

## 🎮 Access Your Services

After running the setup script, you'll get all access URLs and credentials. Services will be available at:

- **Gitea**: `http://192.168.56.10:31030` (admin / admin123)
- **ArgoCD**: `http://192.168.56.10:32080` (admin / [generated password])
- **Keycloak**: `http://192.168.56.10:31080` (admin / admin123)
- **Linkerd Dashboard**: `http://192.168.56.10:8084`
- **Rust API**: `http://192.168.56.10:31000`

## 🔧 Quick Commands

```bash
# SSH into the VM
vagrant ssh

# Check all pods
kubectl get pods -A

# Check Linkerd status
export PATH=$PATH:/home/vagrant/.linkerd2/bin && linkerd check

# View ArgoCD applications
kubectl get applications -n argocd

# Check service mesh traffic
linkerd viz stat deployments -n app
```

## 📁 Project Structure

```
Cloud-Native-Gauntlet/
├── ansible/              # Ansible playbooks & roles
│   ├── playbooks/        # Base system & K3s deployment
│   └── roles/           # Reusable Ansible roles
├── apps/                # Application code
│   └── rust-api/        # Rust web API with JWT auth
├── docs/                # Documentation & Mermaid diagrams
├── k8s/                 # Kubernetes manifests
│   ├── app/            # Application deployment
│   ├── keycloak/       # Identity management
│   ├── gitea/          # Git server
│   ├── argocd/         # GitOps controller
│   ├── linkerd/        # Service mesh
│   └── registry/       # Local Docker registry
├── scripts/             # Utility scripts
│   ├── day1-2-setup.sh # Complete Day 1-2 setup
│   ├── bootstrap.sh    # Full bootstrap script
│   └── pull-images.sh  # Offline image preparation
├── terraform/           # Infrastructure as Code
│   ├── main.tf         # Main configuration
│   ├── variables.tf    # Input variables
│   └── *.tmpl          # Template files
└── Vagrantfile         # VM configuration
```

## 🔧 Configuration

### VM Resources

- **Master**: 6GB RAM, 3 CPUs (runs all services)
- **Workers**: 4GB RAM, 2 CPUs each
- **Network**: 192.168.56.0/24

### Services

- **K3s**: v1.28.2+k3s1
- **Keycloak**: 24.0.5
- **PostgreSQL**: 15
- **Gitea**: latest
- **ArgoCD**: latest
- **Linkerd**: stable-2.14.0

## 🎯 Victory Conditions

- [ ] Entire system runs offline
- [ ] Infrastructure is idempotent
- [ ] GitOps pipeline works
- [ ] Keycloak protects application
- [ ] Linkerd meshes services
- [ ] Documentation complete
- [ ] Mermaid diagrams included

## 🆘 Troubleshooting

### Common Issues

**VMs won't start:**

```bash
# Check VirtualBox is running
# Ensure VT-x/AMD-V is enabled in BIOS
vagrant reload
```

**K3s cluster not ready:**

```bash
vagrant ssh cn-master
sudo systemctl status k3s
sudo journalctl -u k3s -f
```

**DNS resolution issues:**

```bash
# Check /etc/hosts entries
cat scripts/hosts
# Add manually if needed
```

### Reset Everything

```bash
# Nuclear option - start over
vagrant destroy -f
rm -rf .vagrant terraform/.terraform
./scripts/day1-2-setup.sh
```

## 📚 Documentation

- [Architecture Overview](docs/architecture.md)
- [Authentication Flow](docs/diagrams/auth-flow.mmd)
- [GitOps Pipeline](docs/diagrams/gitops-pipeline.mmd)

## 🎭 The Suffering

This project is designed to be:

- **Offline-first**: No internet required after setup
- **Idempotent**: Run multiple times safely
- **Educational**: Learn cloud-native patterns
- **Painful**: Because learning should hurt 😈

## 🏆 Epilogue

When (if) you crawl out of this gauntlet, you'll have:

- Scars 💔 from `kubectl describe`
- PTSD 😭 from `docker ps`
- Hatred 😡 of YAML indentation errors
- Respect 🐍 from Python developers

That hatred fuels victory. Enough to conquer LPIC 2XX, CKAD, and maybe the mythical Carrie Anne Certification 👸.

---

**Now go 🙏. May your YAMLs align, may your pods stay Running, and may you forever remember: `kubectl describe` 👷**

**Dismissed. 👊**
