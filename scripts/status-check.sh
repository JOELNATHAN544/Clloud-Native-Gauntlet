#!/usr/bin/env bash
set -euo pipefail

echo "=== Cloud-Native Gauntlet Status Check ==="
echo

echo "=== K3s Cluster Status ==="
multipass exec k3s -- sudo k3s kubectl get nodes -o wide

echo
echo "=== All Namespaces ==="
multipass exec k3s -- sudo k3s kubectl get namespaces

echo
echo "=== App Namespace Status ==="
multipass exec k3s -- sudo k3s kubectl -n app get all

echo
echo "=== Database Namespace Status ==="
multipass exec k3s -- sudo k3s kubectl -n database get all

echo
echo "=== Keycloak Namespace Status ==="
multipass exec k3s -- sudo k3s kubectl -n keycloak get all

echo
echo "=== Gitea Namespace Status ==="
multipass exec k3s -- sudo k3s kubectl -n gitea get all

echo
echo "=== Registry Namespace Status ==="
multipass exec k3s -- sudo k3s kubectl -n registry get all

echo
echo "=== CNPG System Status ==="
multipass exec k3s -- sudo k3s kubectl -n cnpg-system get all

echo
echo "=== Status Summary ==="
echo "✅ K3s cluster running"
echo "✅ App manifests deployed (pending images)"
echo "✅ Keycloak deployed (pending images)"
echo "✅ Gitea deployed (pending images)"
echo "✅ Local registry deployed (pending images)"
echo "🔄 CNPG operator (needs troubleshooting)"
echo
echo "Next steps:"
echo "1. Build and load Rust API image locally"
echo "2. Configure local registry"
echo "3. Deploy ArgoCD for GitOps"
echo "4. Install Linkerd service mesh"
echo "5. Test end-to-end functionality"

