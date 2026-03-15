# cert-manager Installation Guide

## Overview
This guide will help you install cert-manager on your Kubernetes cluster with minimal resource impact. cert-manager will automatically provision and manage TLS certificates for your applications using Let's Encrypt.

## What's Included

### 1. cert-manager ArgoCD Application (`cert-manager-app.yaml`)
- Deploys cert-manager v1.19.2 via Helm chart
- **Minimal resource configuration:**
  - Controller: 50m CPU / 64Mi memory (requests), 100m CPU / 128Mi memory (limits)
  - Webhook: 50m CPU / 64Mi memory (requests), 100m CPU / 128Mi memory (limits)
  - CA Injector: 50m CPU / 64Mi memory (requests), 100m CPU / 128Mi memory (limits)
  - Total: ~150m CPU / 192Mi memory (requests), ~300m CPU / 384Mi memory (limits)
- These are 3 small pods that handle certificate management

### 2. ClusterIssuers (`cert-manager-issuers.yaml`)
- **letsencrypt-staging**: For testing (no rate limits)
- **letsencrypt-prod**: For production certificates
- Uses HTTP-01 challenge (works with nginx ingress)

### 3. Installation Script (`scripts/install-cert-manager.sh`)
- Automated installation process
- Waits for pods to be ready
- Provides verification steps

## Installation Steps

### Step 1: Update Email Address
Edit `cert-manager/cert-manager-issuers.yaml` and replace `your-email@example.com` with your actual email address in both ClusterIssuers.

### Step 2: Run Installation Script
```bash
cd /Users/rodneywells/Programs/PyCon/ArgoCDBootstrap/scripts
./install-cert-manager.sh
```

### Step 3: Verify Installation
```bash
# Check cert-manager pods
kubectl get pods -n cert-manager

# Expected output: 3 running pods
# - cert-manager-[hash]
# - cert-manager-webhook-[hash]
# - cert-manager-cainjector-[hash]

# Check ClusterIssuers
kubectl get clusterissuers

# Expected output:
# NAME                   READY   AGE
# letsencrypt-staging    True    1m
# letsencrypt-prod       True    1m
```

## Configuring Your Application

### For KubeMarketApp (or any Ingress)

1. **Add cert-manager annotation to your ingress:**
   ```yaml
   annotations:
     cert-manager.io/cluster-issuer: "letsencrypt-staging"  # Use staging first for testing
   ```

2. **Add TLS configuration:**
   ```yaml
   tls:
     - secretName: your-app-tls  # cert-manager creates this automatically
       hosts:
         - your-domain.com
   ```

3. **Example for KubeMarketApp:**
   See `KubeMarketApp/mychart/values-with-tls.yaml` for a complete example.

### Testing Process

1. **Start with staging** (to avoid rate limits):
   ```yaml
   cert-manager.io/cluster-issuer: "letsencrypt-staging"
   ```

2. **Deploy and verify:**
   ```bash
   helm upgrade --install kubemarketapp ./mychart -f values-with-tls.yaml

   # Check certificate status
   kubectl get certificate
   kubectl describe certificate tradely-live-tls
   ```

3. **Once working, switch to production:**
   ```yaml
   cert-manager.io/cluster-issuer: "letsencrypt-prod"
   ```

## How It Works

1. You create/update an Ingress with cert-manager annotations
2. cert-manager detects the ingress and creates a Certificate resource
3. cert-manager requests a certificate from Let's Encrypt
4. Let's Encrypt issues an HTTP-01 challenge to verify domain ownership
5. cert-manager creates a temporary pod to respond to the challenge
6. Once verified, Let's Encrypt issues the certificate
7. cert-manager stores the certificate in the specified Kubernetes secret
8. Your ingress controller uses the secret for TLS termination
9. cert-manager automatically renews certificates before expiration

## Troubleshooting

### Check Certificate Status
```bash
kubectl get certificate -A
kubectl describe certificate <cert-name> -n <namespace>
```

### Check CertificateRequest
```bash
kubectl get certificaterequest -A
kubectl describe certificaterequest <request-name> -n <namespace>
```

### Check Challenge Status
```bash
kubectl get challenges -A
kubectl describe challenge <challenge-name> -n <namespace>
```

### Common Issues

1. **DNS not pointing to cluster**: Ensure your domain resolves to your cluster's LoadBalancer IP
2. **Ingress class mismatch**: Make sure the ingress class matches your ingress controller
3. **Firewall blocking port 80**: HTTP-01 challenges require port 80 to be accessible
4. **Rate limits**: Use staging issuer for testing to avoid Let's Encrypt rate limits

## Resource Impact

cert-manager runs 3 small pods:
- **cert-manager controller**: Manages certificates (50-100m CPU, 64-128Mi memory)
- **webhook**: Validates cert-manager resources (50-100m CPU, 64-128Mi memory)
- **cainjector**: Injects CA bundles (50-100m CPU, 64-128Mi memory)

**Total cluster impact**: ~150m CPU and ~192Mi memory under normal operation.

## Automatic Renewal

cert-manager automatically renews certificates 30 days before expiration. No manual intervention required!

## Next Steps

1. Install cert-manager using the script
2. Test with staging issuer on a non-critical domain
3. Once verified, switch to production issuer
4. Apply to all your ingresses that need TLS

## Let's Encrypt Rate Limits

- **Staging**: No rate limits (use for testing)
- **Production**:
  - 50 certificates per registered domain per week
  - 5 duplicate certificates per week
  - Always test with staging first!

## Additional Resources

- cert-manager docs: https://cert-manager.io/docs/
- Let's Encrypt docs: https://letsencrypt.org/docs/
