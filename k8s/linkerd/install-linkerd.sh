#!/usr/bin/env bash
set -euo pipefail

echo "Installing Linkerd CLI (with retries)..."
curl -fsSL --retry 5 --retry-delay 5 https://run.linkerd.io/install | sh
export PATH=$PATH:$HOME/.linkerd2/bin

echo "Installing Linkerd to K3s cluster..."
linkerd install --crds | kubectl apply -f -
linkerd install | kubectl apply -f -

echo "Installing Linkerd Viz for observability..."
linkerd viz install | kubectl apply -f -

echo "Waiting for Linkerd to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/linkerd-controller -n linkerd-system
kubectl wait --for=condition=available --timeout=300s deployment/linkerd-grafana -n linkerd-viz

echo "Linkerd installation complete!"
echo "Check status with: linkerd check"
echo "Access dashboard with: linkerd viz dashboard"
