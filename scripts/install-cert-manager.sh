#!/bin/bash

set -e

echo "======================================"
echo "Installing cert-manager with ArgoCD"
echo "======================================"

# Apply the cert-manager ArgoCD application
echo "Deploying cert-manager..."
kubectl apply -f ../cert-manager/cert-manager-app.yaml

# Wait for cert-manager to be ready
echo "Waiting for cert-manager to be ready..."
echo "This may take a few minutes..."

# Wait for the ArgoCD app to sync
sleep 10

# Check if cert-manager namespace exists
kubectl get namespace cert-manager 2>/dev/null || echo "Waiting for namespace creation..."
sleep 5

# Wait for cert-manager pods to be ready
echo "Waiting for cert-manager pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cert-manager -n cert-manager --timeout=300s || echo "Some pods may still be starting..."

# Wait for webhook to be fully operational (critical!)
echo "Waiting additional time for webhook to be fully operational..."
sleep 30

# Verify webhook is ready
echo "Verifying webhook is responding..."
kubectl get validatingwebhookconfigurations cert-manager-webhook &>/dev/null && echo "Webhook is configured"

# Apply the ClusterIssuers
echo ""
echo "======================================"
echo "Applying Let's Encrypt ClusterIssuers"
echo "======================================"
echo "IMPORTANT: Update cert-manager/cert-manager-issuers.yaml with your email address before proceeding!"
read -p "Have you updated the email addresses in cert-manager/cert-manager-issuers.yaml? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    kubectl apply -f ../cert-manager/cert-manager-issuers.yaml
    echo ""
    echo "ClusterIssuers created successfully!"
else
    echo "Please update the email addresses in cert-manager/cert-manager-issuers.yaml and run:"
    echo "  kubectl apply -f cert-manager/cert-manager-issuers.yaml"
fi

echo ""
echo "======================================"
echo "Installation Complete!"
echo "======================================"
echo ""
echo "To verify the installation:"
echo "  kubectl get pods -n cert-manager"
echo "  kubectl get clusterissuers"
echo ""
echo "To configure your ingress for automatic TLS, add these annotations:"
echo '  cert-manager.io/cluster-issuer: "letsencrypt-prod"'
echo ""
echo "And ensure your ingress has a tls section with the desired secretName."
echo ""
echo "Example ingress configuration:"
echo "---"
echo "apiVersion: networking.k8s.io/v1"
echo "kind: Ingress"
echo "metadata:"
echo "  name: example-ingress"
echo "  annotations:"
echo '    cert-manager.io/cluster-issuer: "letsencrypt-prod"'
echo "spec:"
echo "  tls:"
echo "  - hosts:"
echo "    - example.com"
echo "    secretName: example-tls"
echo "  rules:"
echo "  - host: example.com"
echo "    ..."
