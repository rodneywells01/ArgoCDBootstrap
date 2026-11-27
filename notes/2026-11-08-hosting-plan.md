# Shared, cost-conscious application hosting

## What was verified from the cloud

The public bootstrap repo was cloned and inspected. Its root currently manages
cert-manager, issuers, Argo Workflows, Image Updater, and KubeMarketApp. Existing
manifests refer to the `nginx` ingress class and `tradely.live`; they do not prove
what is currently running. KubeMarketApp already builds in GitHub Actions and uses
GHCR plus Argo CD Image Updater. No separate domain or load balancer is necessary
for every app.

At the initial audit the cloud had no kubeconfig, kubectl, doctl, Helm installation, or
DigitalOcean credentials. Helm was downloaded from its official distribution for
offline validation only. The GitHub connector can read private source; a direct
private git clone is not authenticated. No cluster, DNS, account, or billing
changes have been made.

## Target architecture

- Reuse one existing domain; prefer `review.<domain>` and `app.<domain>` over
  subpaths because apps often assume their own root URL. DNS names need final
  verification/approval; the example deliberately uses `.invalid`.
- Reuse the existing shared ingress/load balancer **after verifying its controller,
  supported version, TLS behavior and capacity**. Do not install a second load
  balancer speculatively. Community ingress-nginx and F5 NGINX Ingress Controller
  are different products; the class name alone cannot establish which is running
  or whether it is supported. The community ingress-nginx project retired in March
  2026 ([Kubernetes announcement](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/)).
  Do not deploy it as a new foundation. If the running controller is that retired
  project, plan a supported-controller migration before exposing additional apps.
- Use cert-manager and an existing supported solver for per-host certificates.
  The current manifests assume nginx HTTP-01; do not replace that solver or the
  live ingress controller without a separate migration review.
- Authenticate before routing to private application handlers. The generic chart
  includes an OAuth2 Proxy with an explicit email allowlist stored in a Secret.
  GitHub OAuth app registration, account sharing scopes, and credentials require
  a separately approved setup; no credentials or allowlist are in this repo.
- Keep one canonical persistent runtime and one writer. Both browsers access the
  same service; this is shared application state, not periodic desktop Git sync.
- Use app-repo CI to build/test an immutable image in GHCR. Argo CD pulls desired
  state; CI never needs a cluster-admin kubeconfig or DigitalOcean token.

## Safe foundation supplied in this change

`charts/private-web-app` is an opt-in scaffold, **not a deployable AI Project Review
release**. It is absent from the root application's include patterns. Defaults
render nothing. Enabled configurations require an image digest, preexisting OAuth
Secret and callback hostname. The only Service endpoint is the auth proxy, not
the app. Ingress stays disabled unless explicitly configured with a class,
certificate and controller namespace labels. A NetworkPolicy restricts inbound
traffic to the proxy from that namespace; confirm the cluster CNI enforces it.
Cluster-internal clients and port-forward tests require deliberate access setup.

The chart does not create DNS records, OAuth registrations, Secrets, PVCs, nodes,
load balancers, or autoscalers. App images must support non-root execution and the
configured persistent mount. The proxy image tag is pinned as a starting baseline;
review upstream security releases and pin its tested digest before production.

Public exposure additionally requires testing controller HTTP-to-HTTPS redirect,
forwarded-header trust, OAuth callback and cookie behavior, unauthenticated API
requests, CSRF, logout/session expiry, and denied-account flows. Static rendering
is not evidence these controls work live.

## AI Project Review blockers before cutover

Current main is deliberately local-only: loopback binding and Host/Origin checks,
no authenticated network-user model, and local source/agent/workspace actions.
Do not bypass these controls by spoofing loopback headers at ingress.

Required application work in a separate PR:

1. Explicit hosted mode with one validated HTTPS origin and authentication on
   every browser/API route, CSRF checks, and narrow machine/bookmark credentials.
2. Disable desktop workspace launching and local agent/source capabilities until
   their cloud/remote-worker authority is deliberately configured. Never mount
   arbitrary desktop directories or broad credentials into a public web pod.
3. Configurable runtime root; persist **all `.runtime/v2`**, including registry,
   conversations, run state and bookmark configuration, not registry alone.
4. Container-safe lock recovery. Current PID-only lock can confuse a reused
   container PID with a live previous process. Test crash/restart and recovery.
5. Configurable HTTPS extension endpoint and per-device pairing/receipts. Today's
   localhost-only extension plus one receipt is not multi-device hosted sync.
6. Production container, graceful shutdown, bounded health checks, backup and
   restore tests, and two-browser consistency testing. Single replica/Recreate
   trades brief restart downtime for safe filesystem ownership initially.

PR #20 is separate explicit interface publish/pull tooling; it is not this hosted
mode and need not be rewritten by the platform scaffold.

## CPU, memory and costs

Tentative per-app request budget: app 100m CPU/256Mi + proxy 10m/32Mi = **110m CPU,
288Mi requested**. Limits total 600m CPU/640Mi. These are hypotheses, not measured
requirements or usage. No AI inference runs in this pod. Profile representative
idle/use/startup workloads and OOM behavior before adopting them. Kubernetes
requests reserve scheduling capacity; limits do not reserve capacity or prove
that billing cannot grow.

No infrastructure has been provisioned. Incremental recurring cost is **not yet
known**. Read-only audit must establish existing node headroom, current load
balancer count, metrics, volume class/size, backup storage, egress and registry/CI
usage. Reusing domain and gateway avoids extra per-app purchases, but a new volume
or exhausted node capacity can still add charges. Report a monthly delta and seek
approval before new billable resources. Do not enable node autoscaling or create
managed databases by default.

## Read-only access and rollout gates

Run `scripts/audit-hosting.sh EXPECTED_CONTEXT` with selected-resource read-only Kubernetes access. It deliberately never reads Secrets or logs. A DigitalOcean token is not
needed if a scoped kubeconfig is supplied securely. Do not paste tokens into chat
or commit kubeconfig; do not copy broad desktop credentials into the cloud.

1. Audit actual ingress/version, TLS, headroom, volumes, Argo state and DNS.
2. Confirm hostnames, authentication method, minimal access and recurring costs.
3. Complete/test hosted app changes and migrate a stopped-runtime copy into a
   disposable environment. Retain an untouched backup and test restoration.
4. Approve creation of necessary Secrets/volume and public network exposure.
5. Review app image build and digest; create an explicit app Application with no
   automatic prune until migration is verified. Adding it to the root include
   list is a deployment-affecting change, not merely documentation.
6. Verify login/denial/CSRF, persistence across restart, concurrent browser edits,
   extension authentication, disabled local capabilities, metrics and rollback.

## GitHub-to-Argo workflow for the next app

App PR: test and build only, no publishing from untrusted pull requests. On reviewed
merge: build and publish GHCR using repository-scoped `GITHUB_TOKEN` with packages
write, not a personal DigitalOcean token. Record the immutable digest. Update the
app's reviewed values to that digest through a GitOps PR; merging it lets Argo
reconcile. Roll back by reverting the digest/config, after considering data schema
compatibility. Automated digest PRs can be added later with narrowly scoped repo
access; do not grant broad admin credentials just to avoid a manual approval.

## Credential handoff status

The current cloud task exposes no verified secure secret-intake tool. Do not paste
a DigitalOcean token, kubeconfig or OAuth secret into chat, Obsidian or Git. A
configured Codex cloud environment can support its own Personal Vault, but injection
into this existing dot computer has not been verified. Until that is established,
the owner can run the read-only audit and share its metadata output instead.

DigitalOcean [connection instructions](https://docs.digitalocean.com/products/kubernetes/how-to/connect-to-cluster/)
explain kubeconfig retrieval. The [kubernetes:read scope](https://docs.digitalocean.com/reference/api/scopes/kubernetes/read/)
excludes cluster credentials; obtaining a kubeconfig is not the same as granting
least-privilege Kubernetes RBAC. Prefer a short-lived audit identity with only
get/list on the resources in `examples/audit-reader-role.yaml`, no Secrets, logs,
exec or mutation. An administrator must approve/install that RBAC; this repo does
not install it automatically.

RBAC caveat: Kubernetes get/list permission applies to whole objects, not selected
fields. Even without Secret-resource permission, Pod/Deployment specs can contain
literal environment values or sensitive annotations. The script prints only
chosen fields; the credential itself is not a field-level metadata sandbox.
Scope namespaces where feasible and review literal credentials before sharing
access. Pod requests, init-container requests and overhead must be considered
alongside metrics; low instantaneous usage alone does not establish headroom.
