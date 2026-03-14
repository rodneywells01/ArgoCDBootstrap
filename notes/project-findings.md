# ArgoCDBootstrap - Project Findings

Last reviewed: 2026-02-07

## Purpose
This repository bootstraps Kubernetes platform components, primarily:
- Argo CD installation via Helm
- cert-manager deployment via Argo CD `Application`
- Let's Encrypt `ClusterIssuer` resources for TLS automation

## Current Structure
- `scripts/deploy.sh`: Installs/upgrades Argo CD from `argo/argo-cd` chart into `argocd` namespace.
- `cert-manager/cert-manager-app.yaml`: Argo CD application that deploys cert-manager chart (`v1.19.2`) with low resource settings.
- `cert-manager/cert-manager-issuers.yaml`: Defines staging and production ACME cluster issuers.
- `scripts/install-cert-manager.sh`: Applies cert-manager app and issuers with basic readiness waits.
- `update/`: Alternate values and install/update helper scripts for Argo CD.

## Notable Findings
1. Repo is actively being edited (cert-manager manifests + update values).
2. cert-manager config is optimized for lower-resource clusters.
3. `cert-manager-issuers-app.yaml` references a specific GitHub repo URL and may need environment-specific updates.
4. `update/values.yaml` currently includes a hardcoded `server.secretkey` value, which should be treated as sensitive config.
5. Installation scripts rely on local `kubectl`/`helm` context and include hardcoded relative paths.
6. `.vscode/mcp.json` includes kubernetes MCP setup options, indicating local AI-assisted cluster workflows.

## Operational Assumptions
- `kubectl` context points to target cluster.
- NGINX ingress class is present for HTTP-01 challenges.
- DNS is already configured to route to cluster ingress/load balancer.

## Suggested Follow-ups
- Move sensitive values (e.g., secret keys) to Kubernetes secrets or external secret management.
- Parameterize environment-specific values (domains, repo URLs, emails).
- Add repo-level README and runbook for bootstrap order and verification checks.
- Consider adding lint/validation checks for manifests in CI.
