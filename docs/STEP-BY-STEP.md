# Cloud-Native Gauntlet – Step-by-Step (Days 1–10)

This file documents exactly what to do to reproduce the project from scratch on a fresh machine, in the same order we executed it.

## Day 1–2: Cluster Bootstrap (Vagrant + Terraform + Ansible)
1. Prereqs: Vagrant, VirtualBox, Terraform >=1.3, Ansible >=2.9, Docker.
2. One-command setup:
   ```bash
   chmod +x scripts/day1-2-setup.sh
   ./scripts/day1-2-setup.sh
   ```
   What it does:
   - Generates configs (Ansible inventory, hosts, image pull script)
   - Adds local DNS entries for services
   - Pre-pulls container images
   - Starts VMs (master/worker)
   - Installs K3s and kubectl via Ansible
   - Starts a local registry on cn-master:5000

3. Verify:
   ```bash
   vagrant ssh cn-master
   kubectl get nodes
   ```

## Day 3–4: Build the Rust API
1. Code location: `apps/rust-api` (Axum-based with JWT auth scaffolding).
2. Local run (optional):
   ```bash
   cd apps/rust-api
   cargo run
   ```
3. Prepare Docker image (multi-stage Dockerfile in repo).

## Day 5: Containerize
1. Build container image using the provided `Dockerfile`:
   ```bash
   cd apps/rust-api
   docker build -t rust-api:local .
   ```
2. (Optional offline) Tag/push to local registry on cn-master.

## Day 6–7: Database & K8s App Manifests
1. Manifests live in `k8s/app` and `k8s/database` (and CNPG if used).
2. Apply app namespace, service, deployment, and ingress (when ingress is present):
   ```bash
   vagrant ssh cn-master -c "kubectl apply -f /vagrant/k8s/app/"
   ```

## Day 8: Keycloak
1. Keycloak manifests under `k8s/keycloak/` (minimal/simple variants included).
2. Deploy minimal Keycloak and DB (if not already running):
   ```bash
   vagrant ssh cn-master -c "kubectl apply -f /vagrant/k8s/keycloak/keycloak-minimal.yaml"
   ```
3. Verify:
   ```bash
   vagrant ssh cn-master -c "kubectl -n keycloak get pods"
   ```

## Day 9–10: GitOps – Gitea + ArgoCD
1. Gitea (final working approach)
   - Deploy simple manifests:
     ```bash
     vagrant ssh cn-master -c "kubectl apply -f /vagrant/k8s/gitea/namespace.yaml && kubectl apply -f /vagrant/k8s/gitea/deployment.yaml && kubectl apply -f /vagrant/k8s/gitea/service.yaml"
     ```
   - Ensure access via http://192.168.56.10:31030
   - Complete installer, create admin, generate Personal Access Token (PAT).

2. Create repos in Gitea (app-source, infra):
   ```bash
   # Replace TOKEN with your PAT
   GITEA=http://192.168.56.10:31030
   curl -H "Authorization: token TOKEN" -H 'Content-Type: application/json' \
     -X POST $GITEA/api/v1/user/repos -d '{"name":"app-source","auto_init":true}'
   curl -H "Authorization: token TOKEN" -H 'Content-Type: application/json' \
     -X POST $GITEA/api/v1/user/repos -d '{"name":"infra","auto_init":true}'
   ```

3. Push Rust API to app-source:
   ```bash
   cd apps/rust-api
   git init -b main
   git remote add gitea http://USER:TOKEN@192.168.56.10:31030/USER/app-source.git
   git add . && git commit -m "Initial commit"
   git push -u gitea main --force
   ```

4. GitOps repo population:
   ```bash
   git clone http://USER:TOKEN@192.168.56.10:31030/USER/infra.git /tmp/infra
   rsync -a k8s/app/ /tmp/infra/k8s/app/
   cd /tmp/infra && git add . && git commit -m "Add app manifests" && git push
   ```

5. ArgoCD (lightweight server-only demo):
   ```bash
   vagrant ssh cn-master -c "kubectl apply -f /vagrant/k8s/argocd/namespace.yaml && kubectl apply -f /vagrant/k8s/argocd/deployment.yaml"
   vagrant ssh cn-master -c "kubectl -n argocd get pods"
   ```
   - If PVC causes Pending, switch to emptyDir in `k8s/argocd/deployment.yaml` volumes.

6. Create ArgoCD Application (point to infra repo path `k8s/app`) – via UI or manifest.

### CI (GitHub Actions) for app-source
- File: `apps/rust-api/.github/workflows/ci.yml`
- What it does: on push/PR, runs `cargo build --release` and `docker build -t cloud-gauntlet-api:ci .`
- Proof: mirror repo to GitHub (optional) to see green runs, or use the YAML as CI definition evidence.

### Ingress (ingress-nginx) and test
```bash
# Install ingress-nginx for baremetal and expose NodePorts
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.3/deploy/static/provider/baremetal/deploy.yaml
kubectl -n ingress-nginx patch svc ingress-nginx-controller --type='json' \
  -p='[{"op":"replace","path":"/spec/type","value":"NodePort"},
       {"op":"add","path":"/spec/ports/0/nodePort","value":30080},
       {"op":"add","path":"/spec/ports/1/nodePort","value":30443}]'

# Test through ingress
curl -I -H "Host: api.local" http://192.168.56.10:30080/health   # 200 OK
```

### GitOps scale proof
```bash
git clone http://USER:TOKEN@192.168.56.10:31030/USER/infra.git /tmp/infra-scale
sed -i 's/^\s*replicas: .*$/  replicas: 2/' /tmp/infra-scale/k8s/app/deployment.yaml
(cd /tmp/infra-scale && git commit -am "Scale to 2" && git push)
kubectl -n app get deploy rust-api -w    # watch AVAILABLE go to 2
```

---

## Day 11: Enter the Mesh (Linkerd)

### Install Linkerd + Gateway API CRDs
```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml
curl -fsSL https://run.linkerd.io/install | sh
export PATH=$PATH:$HOME/.linkerd2/bin
linkerd check --pre
linkerd install --crds | kubectl apply -f -
linkerd install | kubectl apply -f -
linkerd check
```

### Install linkerd-viz (observability)
```bash
linkerd viz install | kubectl apply -f -
linkerd viz check
```

### Enable namespace injection and redeploy
```bash
kubectl label ns app linkerd.io/inject=enabled --overwrite
# Ensure the deployment template has the annotation (defensive)
kubectl -n app patch deploy rust-api --type='merge' -p '{"spec":{"template":{"metadata":{"annotations":{"linkerd.io/inject":"enabled"}}}}}'
kubectl -n app rollout restart deploy/rust-api
kubectl -n app rollout status deploy/rust-api --timeout=300s
```

### Verify sidecars and mTLS
```bash
# Confirm proxy container is present
kubectl -n app get pods -o jsonpath='{range .items[*]}{.metadata.name}:{range .spec.containers[*]}{.name},{end}{"\n"}{end}'

# Quick tap of requests (shows TLS, paths, etc.)
linkerd viz tap -n app deploy/rust-api --max-rps 1 --output json | head -n 5

# Optional: open viz dashboard
linkerd viz dashboard --address 0.0.0.0 --port 31090
# browse: http://192.168.56.10:31090
```

Expected results:
- `linkerd viz check` passes.
- Pod shows `linkerd-proxy` alongside the app container.
- Tap output streams JSON lines indicating traffic; TLS fields present (mesh encryption on by default).

## Current Status
- K3s cluster up.
- Rust API built & pushed to Gitea.
- Gitea operational and reachable at NodePort (with port-forward fallback).
- Infra repo seeded with app manifests.
- ArgoCD server deployed and being finalized for sync.

## Next Steps
- Finalize ArgoCD Application and verify sync/health.
- Add Linkerd (Day 11) and update manifests.
- Harden Keycloak integration and JWT validation.
- Polish docs and diagrams before submission.
