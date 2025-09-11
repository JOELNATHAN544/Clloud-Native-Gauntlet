# Cloud-Native Gauntlet: Your Two-Week Ordeal ⚔️

> **"So you thought LPIX 1xx was 'hard'? 😴 That was baby Linux with juice boxes 🍼 nap time 💤, and a coloring book 🖍️."**

Welcome to the **Cloud-Native Gauntlet** - the challenge nobody asked for but everybody deserves! This project implements a complete cloud-native application stack running entirely offline on your local machine.

## 🎯 Objective

Build, from scratch, a full-stack cloud-native monstrosity that will:

- Make Kubernetes weep 😭
- Make Docker question its career 💼
- Make your laptop beg for early retirement 👵

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
│  Services: Keycloak | Gitea | ArgoCD | Linkerd | Registry  │
│  Database: PostgreSQL (CloudNativePG)                      │
│  App: Rust API with JWT Auth                               │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start (Day 1-2)

### Prerequisites

- **Vagrant** (latest)
- **VirtualBox** (latest)
- **Terraform** (>= 1.3.0)
- **Ansible** (>= 2.9)
- **Docker** (latest)
- **8GB+ RAM** (for VMs)

### One-Command Setup

```bash
# Make it executable and run
chmod +x scripts/day1-2-setup.sh
./scripts/day1-2-setup.sh
```

This script will:

1. ✅ Check prerequisites
2. ✅ Generate configuration files
3. ✅ Setup local DNS
4. ✅ Pull required images
5. ✅ Start Vagrant VMs
6. ✅ Deploy K3s cluster
7. ✅ Setup local registry

### Manual Setup (if you prefer suffering)

```bash
# 1. Generate configs
cd terraform && terraform init && terraform apply

# 2. Start VMs
vagrant up

# 3. Deploy base system
cd ansible
ansible-playbook -i inventory.ini playbooks/base.yml

# 4. Deploy K3s
ansible-playbook -i inventory.ini playbooks/k3s.yml
```

## 📅 The Twelve Trials

| Day  | Task                          | Status     |
| ---- | ----------------------------- | ---------- |
| 1-2  | **Summon the Cluster Beasts** | ✅ Ready   |
| 3-4  | **Forge Your Application**    | 🔄 Next    |
| 5    | **Containerize Your Pain**    | ⏳ Pending |
| 6-7  | **Database & Deployment**     | ⏳ Pending |
| 8    | **Bow Before Keycloak**       | ⏳ Pending |
| 9-10 | **Embrace the GitOps Curse**  | ⏳ Pending |
| 11   | **Enter the Mesh**            | ⏳ Pending |
| 12   | **Write Your Epic**           | ⏳ Pending |

## 🎮 Access Your Cluster

```bash
# SSH into master node
vagrant ssh cn-master

# Check cluster status
kubectl get nodes

# Access services (after Day 8)
curl http://keycloak.local/realms/master
curl http://gitea.local
curl http://registry.local/v2/_catalog
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
