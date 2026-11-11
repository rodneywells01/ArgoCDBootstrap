#!/usr/bin/env bash
# Read-only selected fields. No Secret-resource reads, logs or mutations.
# Kubernetes RBAC still grants full-object reads for these resource types.
set -euo pipefail
if [[ $# != 1 || -z "$1" ]]; then
  echo "Usage: $0 EXPECTED_KUBE_CONTEXT" >&2
  exit 2
fi
command -v kubectl >/dev/null || { echo 'kubectl is required' >&2; exit 2; }
actual=$(kubectl config current-context)
[[ "$actual" == "$1" ]] || { echo 'Context mismatch; refusing audit.' >&2; exit 2; }
run() { printf '\n== %s ==\n' "$*"; kubectl --context "$1" "${@:2}"; }
context=$1
run "$context" get nodes -o custom-columns=NAME:.metadata.name,CPU:.status.allocatable.cpu,MEMORY:.status.allocatable.memory
run "$context" get deployments,statefulsets -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,REPLICAS:.spec.replicas,IMAGES:.spec.template.spec.containers[*].image,CPU_REQUEST:.spec.template.spec.containers[*].resources.requests.cpu,MEMORY_REQUEST:.spec.template.spec.containers[*].resources.requests.memory,CPU_LIMIT:.spec.template.spec.containers[*].resources.limits.cpu,MEMORY_LIMIT:.spec.template.spec.containers[*].resources.limits.memory
run "$context" get pods -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,NODE:.spec.nodeName,PHASE:.status.phase,CPU_REQUEST:.spec.containers[*].resources.requests.cpu,MEMORY_REQUEST:.spec.containers[*].resources.requests.memory,INIT_CPU:.spec.initContainers[*].resources.requests.cpu,INIT_MEMORY:.spec.initContainers[*].resources.requests.memory,OVERHEAD:.spec.overhead
run "$context" get ingressclass
run "$context" get ingress -A
run "$context" get services -A
run "$context" get storageclass
run "$context" get pvc -A
run "$context" get applications.argoproj.io -A || true
run "$context" top nodes || echo 'Metrics unavailable; do not infer zero usage.'
run "$context" top pods -A --containers || echo 'Pod metrics unavailable.'
