# Argo Workflows (Prod)

## Interfaces

- https://workflows.tradely.live
- https://tradely.live

## Quick References

- Argo CD Application: `argo-workflows`
- Namespace: `argo-workflows`
- Manifest: `argo-workflows/argo-workflows-app.yaml`

## Deployed Application URLs

- Argo Workflows: https://workflows.tradely.live/
- Argo CD: https://tradely.live/
- Kube Market App: https://tradely.live/marketapi

## Quick Checks

```bash
kubectl get application -n argocd argo-workflows
kubectl get ingress -n argo-workflows argo-workflows-server
kubectl get certificate -n argo-workflows argo-workflows-tls
```
