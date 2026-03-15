# ArgoCDBootstrap

This repo is the cluster wiring layer for the PyCon workspace.
It owns Argo CD applications, shared platform components, and the bootstrap needed to keep those pieces managed from Git.

## Developer Flow

If you are making a normal application change in `KubeMarketApp`, you do not need to touch this repo.

The steady-state flow is:

1. Make code or Helm changes in `KubeMarketApp`.
2. Push or merge to `master`.
3. The `KubeMarketApp` GitHub Action builds and pushes a new image to GHCR.
4. Argo CD Image Updater detects the new `latest` image digest.
5. Argo CD updates the effective image parameters for `kube-market-app`.
6. Kubernetes rolls the `kube-market-app` Deployment automatically.

Routine app work should "just fly" from the app repo after bootstrap is in place.

## When You Do Need This Repo

You should update `ArgoCDBootstrap` when you need to change cluster-level or Argo-managed wiring, such as:

- adding or changing Argo CD applications
- changing Image Updater behavior
- changing namespaces, ingress, TLS, or cert-manager setup
- changing shared platform components or bootstrap structure

## Bootstrap Once

Argo CD does not automatically watch this repo unless the root app-of-apps is registered first.

The one-time bootstrap step is:

```bash
kubectl apply -f bootstrap-root-application.yaml
```

That root application tells Argo CD to manage the child application manifests in this repo, including:

- `cert-manager`
- `cert-manager-issuers`
- `argo-workflows`
- `argocd-image-updater`
- `kube-market-app`

After that initial apply, ongoing changes in this repo should reconcile through Argo CD without additional manual apply steps.

## Kube Market App Automation

`kube-market-app` is sourced from the `KubeMarketApp` repo, but its cluster wiring is declared here.

Image automation works like this:

- `kube-market-app/kube-market-app-app.yaml` defines the Argo CD application and image updater annotations
- `argocd-image-updater/argocd-image-updater-app.yaml` installs the Image Updater controller
- `argocd-image-updater/kube-market-app-image-updater.yaml` tells the controller to watch the `kube-market-app` Argo application and honor its annotations

## Troubleshooting

If a new `KubeMarketApp` image does not roll out automatically, check:

1. The `KubeMarketApp` GitHub Action finished successfully and pushed the image to GHCR.
2. `argocd app get kube-market-app` shows `Synced` and `Healthy`.
3. `argocd app get argocd-image-updater` shows `Synced` and `Healthy`.
4. `kubectl get imageupdater -n argocd` shows the `kube-market-app` `ImageUpdater` resource.
5. `kubectl logs -n argocd deploy/argocd-image-updater-controller` shows Image Updater reconciling the app.
6. `kubectl get deploy -n kube-market-app kube-market-app-mychart -o jsonpath='{.spec.template.spec.containers[0].image}'` shows the updated image reference.
