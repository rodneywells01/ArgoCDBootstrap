# AGENTS.md

## Purpose
This file guides coding agents working in `ArgoCDBootstrap`.
Use it to keep agent behavior consistent, safe, and aligned to this repo's deployment model.

## Repo Scope
- Bootstrap Argo CD on Kubernetes using Helm.
- Manage cert-manager installation and issuer manifests.
- Provide helper scripts for install/update/reset operations.

## People And Ownership
- Rodney Wells is the likely primary maintainer for this repo and should be treated as the default reviewer for bootstrap, ingress, and certificate-flow changes.
- Assume platform ownership lives here: edits in this repo can affect other application repos that depend on shared ingress, TLS, or Argo CD availability.

## Environment Assumptions
- `kubectl`, `helm`, and cluster credentials are already available.
- Current kube context points at the intended target cluster before running scripts.
- NGINX ingress controller exists when using HTTP-01 ACME challenges.

## Agent Operating Rules
1. Do not apply manifests to a live cluster unless explicitly asked.
2. Prefer editing manifests/scripts in-place and showing a clear diff summary.
3. Preserve existing user changes; never revert unrelated modifications.
4. Treat secrets and tokens as sensitive; do not introduce hardcoded credentials.
5. Keep resource settings conservative unless asked to scale up.
6. Flag any change that alters public DNS names, ACME email addresses, or Git repo source URLs before considering it safe.

## Validation Workflow (when changing manifests/scripts)
1. Run YAML and shell sanity checks where possible.
2. Verify relative file paths used by scripts.
3. Confirm Argo CD Application sources/destinations are still correct.
4. If cert-manager or issuer files change, call out rollout order in notes.

## High-Risk Areas
- `update/values.yaml`: contains security-sensitive Argo CD config.
- `cert-manager/cert-manager-issuers.yaml`: production certificate authority settings.
- `scripts/install-cert-manager.sh`: timing/readiness assumptions can fail on slower clusters.

## Coordination Notes
- Changes under `cert-manager/` or `update/` can have downstream impact on `KubeMarketApp/` and other ingress-enabled workloads in this workspace.
- If a task spans both app deployment settings and cluster bootstrap settings, document the dependency order in the final handoff.

## Documentation Convention
- Keep persistent discoveries in `notes/`.
- Add dated notes entries when architecture assumptions or operational runbooks change.
