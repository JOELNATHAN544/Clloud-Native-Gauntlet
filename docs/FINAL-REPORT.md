# Cloud‑Native Gauntlet – Final Report (Days 1–12)

## Architecture (high‑level)
- Infra: Vagrant → K3s (single master), local Docker registry, ingress‑nginx
- Identity: Keycloak
- App: Rust API (Axum), health at `/health`, auth middleware guards others
- Git / CI / CD: Gitea (app-source, infra), GitHub Actions (build), ArgoCD (GitOps)
- Mesh / Observability: Linkerd + linkerd‑viz (tap, metrics, dashboard)

See Mermaid diagrams in `docs/diagrams/`.

---

## Day‑by‑Day Outcomes

### Days 1–2: Cluster
- Provisioned Vagrant VM(s) and installed K3s
- Local registry on `cn-master:5000`
- Validation: `kubectl get nodes`

### Days 3–5: App + Image
- Rust API implemented (Axum) with `/health`
- Multi‑stage Docker build

### Days 6–7: K8s Manifests
- Namespace `app`, `Service`, `Deployment`, `Ingress`
- Deploy via `kubectl apply -f k8s/app/`

### Day 8: Keycloak
- Deployed minimal Keycloak
- App middleware: `/health` and `/api/auth/login` open; others 401 without token

### Days 9–10: GitOps
- Gitea repos: `nathan/app-source`, `nathan/infra`
- ArgoCD app `app-gitops` → `infra/k8s/app`
- Ingress‑nginx NodePort 30080; `/health` via Host `api.local` → 200
- CI: GitHub Actions at `apps/rust-api/.github/workflows/ci.yml`

### Day 11: Linkerd
- Installed control plane + viz; checks passed
- Enabled sidecar injection (namespace + deployment annotation)
- Restarted app; `linkerd-proxy` present; `tap` streams requests

### Day 12: Docs + Proofs
- Updated `docs/STEP-BY-STEP.md` (verification & quickstart)
- This report + diagrams

---

## Verification – Copy/Paste Proofs

### Cluster & Pods
```bash
vagrant ssh cn-master -c "kubectl get nodes && kubectl get pods -A"
```

### Gitea Repos
```bash
curl -s http://192.168.56.10:31030/api/v1/users/nathan/repos | jq '.[].full_name'
# Expect: "nathan/app-source", "nathan/infra"
```

### CI (GitHub Actions) Presence
```bash
ls apps/rust-api/.github/workflows/ci.yml
```

### CD (ArgoCD) Status
```bash
vagrant ssh cn-master -c "kubectl -n argocd get application app-gitops -o jsonpath='{.status.sync.status} {.status.health.status}\n'"
# Expect: Synced Healthy (Ingress health override applied)
```

### App Resources
```bash
vagrant ssh cn-master -c "kubectl -n app get deploy,svc,ingress"
```

### Ingress Check (NGINX NodePort 30080)
```bash
curl -I -H "Host: api.local" http://192.168.56.10:30080/health  # Expect 200 OK
```

### Linkerd – viz & Injection
```bash
vagrant ssh cn-master -c "bash -lc 'export PATH=$PATH:/home/vagrant/.linkerd2/bin; linkerd viz check'"
# Expect: all ✓

vagrant ssh cn-master -c "kubectl -n app get pods -o jsonpath='{range .items[*]}{.metadata.name}:{range .spec.containers[*]}{.name},{end}{\n}{end}'"
# Expect: rust-api-…: rust-api,linkerd-proxy,
```

### Linkerd – Tap Some Requests (mTLS telemetry)
```bash
vagrant ssh cn-master -c "bash -lc 'export PATH=$PATH:/home/vagrant/.linkerd2/bin; linkerd viz tap -n app deploy/rust-api --max-rps 1 --output json | head -n 5'"
# Shows JSON lines with request/response metadata; Linkerd defaults to mTLS between meshed workloads
```

### GitOps Scale Proof
```bash
# Change replicas in infra, push, and watch rollout
# (Adjust paths as needed)
```

---

## Idempotence Notes
- Manifests are safe to re‑apply (`kubectl apply -f …`).
- ArgoCD `selfHeal: true` reconciles drift.
- Ingress health override keeps UI green; functional health verified by `/health` and Linkerd checks.

---

## Troubleshooting (Quick)
- Ingress 404: use Host `api.local`; controller service NodePort 30080
- ArgoCD Unknown/OutOfSync: add `argocd.argoproj.io/refresh=hard`; recreate Application; health override
- Linkerd not injecting: label namespace + annotate pod template; restart deployment

---

## Victory Conditions (checked)
- Offline‑first infra ✓  Idempotent configs ✓  GitOps works ✓
- Keycloak protects app (401 on `/`) ✓  Linkerd meshes ✓
- Docs & diagrams included ✓
