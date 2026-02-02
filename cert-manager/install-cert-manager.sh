#!/bin/bash
# Script to install cert-manager and configure ClusterIssuers
set -e

echo "=== Installing cert-manager ==="

# Add Jetstack Helm repo
helm repo add jetstack https://charts.jetstack.io || true
helm repo update

# Install cert-manager with CRDs
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true \
  --wait

echo "=== Waiting for cert-manager pods to be ready ==="
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=120s

echo "=== Applying ClusterIssuers ==="
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Apply staging issuer first
kubectl apply -f "$SCRIPT_DIR/cluster-issuer-staging.yaml"

# Apply production issuer
kubectl apply -f "$SCRIPT_DIR/cluster-issuer-prod.yaml"

echo "=== Verifying ClusterIssuers ==="
kubectl get clusterissuers

echo ""
echo "=== cert-manager installation complete! ==="
echo ""
echo "NEXT STEPS:"
echo "1. Update the email address in the ClusterIssuer files"
echo "2. Ensure your DNS (tradely.live) points to your cluster's load balancer IP"
echo "3. Redeploy your application to trigger certificate issuance"
echo "4. Once staging works, switch to letsencrypt-prod in your values.yaml"
