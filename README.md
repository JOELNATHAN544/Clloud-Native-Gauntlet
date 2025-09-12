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

## 🔄 Reset Everything

If you need to start over or something goes wrong:

```bash
# Nuclear option - destroy everything and start fresh
vagrant destroy -f
rm -rf .vagrant

# Run the setup script again
./scripts/setup-cluster.sh
```

## 🎯 What You'll Have

After running the setup script, you'll have a complete cloud-native stack with:

- ✅ **Kubernetes cluster** with 3 nodes
- ✅ **GitOps pipeline** (push to git → auto-deploy)
- ✅ **Service mesh** with mTLS encryption
- ✅ **Identity management** with Keycloak
- ✅ **Observability** with Linkerd dashboard
- ✅ **CI/CD** with Gitea Actions
- ✅ **Database** with PostgreSQL
- ✅ **Container registry** for images
- ✅ **Rust API** application deployed and meshed

## 🆘 Troubleshooting

**VMs won't start:**
```bash
# Ensure VirtualBox is running and VT-x/AMD-V is enabled
vagrant reload
```

**Services not accessible:**
```bash
# Check if all pods are running
vagrant ssh -c "kubectl get pods -A"

# Restart the setup script if needed
./scripts/setup-cluster.sh
```

**Dashboard not loading:**
```bash
# The script sets up port forwarding automatically
# Access Linkerd at: http://192.168.56.10:8084
```

## 📚 Documentation

- [Final Report](docs/FINAL-REPORT.md)
- [Step-by-Step Guide](docs/STEP-BY-STEP.md)
- [Architecture Diagrams](docs/diagrams/)

---

## 🏆 The Complete Cloud-Native Experience

This project gives you hands-on experience with:

- **Infrastructure as Code** (Vagrant, Terraform, Ansible)
- **Container Orchestration** (Kubernetes/K3s)
- **GitOps** (ArgoCD + Gitea)
- **Service Mesh** (Linkerd with mTLS)
- **Observability** (Metrics, dashboards, tracing)
- **CI/CD Pipelines** (Gitea Actions)
- **Security** (JWT auth, mTLS, Keycloak)

**Now go forth and conquer the cloud-native world! 🚀**
