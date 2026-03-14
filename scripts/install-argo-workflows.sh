#!/bin/bash

set -euo pipefail

APP_MANIFEST="../argo-workflows/argo-workflows-app.yaml"

echo "======================================"
echo "Installing Argo Workflows"
echo "======================================"

if [[ ! -f "$APP_MANIFEST" ]]; then
  echo "Manifest not found: $APP_MANIFEST"
  exit 1
fi

echo "Applying Argo CD Application manifest..."
kubectl apply -f "$APP_MANIFEST"

echo "Waiting for Argo CD Application to appear..."
kubectl wait --for=condition=Established crd/applications.argoproj.io --timeout=60s >/dev/null 2>&1 || true
kubectl get application -n argocd argo-workflows >/dev/null

echo "Current Argo CD Application status:"
kubectl get application -n argocd argo-workflows

echo ""
echo "Watch rollout:"
echo "  kubectl get application -n argocd argo-workflows -w"
echo "  kubectl get pods -n argo-workflows -w"
