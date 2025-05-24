#!/bin/bash
set -e

NAMESPACE="argocd"
RELEASE_NAME="argocd"
VALUES_FILE="values.yaml"
CHART="argo/argo-cd"

# Add ArgoCD Helm repo if not present
helm repo add argo https://argoproj.github.io/argo-helm || true
helm repo update

# Create namespace if it doesn't exist
kubectl get namespace $NAMESPACE >/dev/null 2>&1 || kubectl create namespace $NAMESPACE

# Install or upgrade ArgoCD
helm upgrade --install $RELEASE_NAME $CHART \
  --namespace $NAMESPACE \
  -f $VALUES_FILE

echo "ArgoCD deployed to namespace '$NAMESPACE'."
