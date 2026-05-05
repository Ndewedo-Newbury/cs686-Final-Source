#!/usr/bin/env bash
# Bootstrap a fitness-tracker EKS cluster with all required components.
# Run once after terraform apply completes.
# Usage: ./bootstrap-cluster.sh [environment]   (default: dev)
#
# Prerequisites:
#   - kubectl, helm, aws CLI installed
#   - Voclabs credentials exported (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN)
#   - terraform apply completed for the target environment

set -euo pipefail

ENV="${1:-dev}"
CLUSTER_NAME="fitness-tracker-${ENV}"
REGION="us-west-2"
ACCOUNT_ID="793012580999"
LAB_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/LabRole"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "==> Bootstrapping ${CLUSTER_NAME} in ${REGION}"

# ── 1. kubectl ────────────────────────────────────────────────────────────────
echo ""
echo "── Step 1: kubectl ──"
aws eks update-kubeconfig --name "${CLUSTER_NAME}" --region "${REGION}"
kubectl cluster-info --context "$(kubectl config current-context)"

VPC_ID=$(aws eks describe-cluster --name "${CLUSTER_NAME}" --region "${REGION}" \
  --query "cluster.resourcesVpcConfig.vpcId" --output text)
echo "    VPC: ${VPC_ID}"

# ── 2. AWS Load Balancer Controller ──────────────────────────────────────────
echo ""
echo "── Step 2: AWS Load Balancer Controller ──"
helm repo add eks https://aws.github.io/eks-charts --force-update
helm repo update eks
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName="${CLUSTER_NAME}" \
  --set region="${REGION}" \
  --set vpcId="${VPC_ID}" \
  --wait --timeout=5m

echo "    Waiting for LBC webhook certificate to propagate..."
kubectl rollout status deployment/aws-load-balancer-controller -n kube-system --timeout=120s
sleep 15

# ── 3. External Secrets Operator ─────────────────────────────────────────────
echo ""
echo "── Step 3: External Secrets Operator ──"
helm repo add external-secrets https://charts.external-secrets.io --force-update
helm repo update external-secrets
helm upgrade --install external-secrets external-secrets/external-secrets \
  -n external-secrets --create-namespace \
  --wait --timeout=5m

echo "    Waiting for ESO CRDs to be established..."
kubectl wait --for=condition=established \
  crd/clustersecretstores.external-secrets.io \
  crd/externalsecrets.external-secrets.io \
  --timeout=60s

echo "    Creating aws-credentials secret for ESO..."
kubectl create secret generic aws-credentials \
  -n external-secrets \
  --from-literal=access-key-id="${AWS_ACCESS_KEY_ID}" \
  --from-literal=secret-access-key="${AWS_SECRET_ACCESS_KEY}" \
  --from-literal=session-token="${AWS_SESSION_TOKEN}" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f "${REPO_ROOT}/DevOps/k8s/argocd/cluster-secret-store.yaml"
echo "    ClusterSecretStore applied."
echo "    NOTE: Run DevOps/scripts/update-eso-creds.sh whenever Voclabs creds expire (~4h)."

# ── 4. ArgoCD ─────────────────────────────────────────────────────────────────
echo ""
echo "── Step 4: ArgoCD ──"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
echo "    Waiting for argocd-server..."
kubectl wait --for=condition=available deployment/argocd-server \
  -n argocd --timeout=300s

# ── 5. ArgoCD Rollouts ────────────────────────────────────────────────────────
echo ""
echo "── Step 5: ArgoCD Rollouts ──"
kubectl create namespace argo-rollouts --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argo-rollouts \
  -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# ── 6. Monitoring stack ───────────────────────────────────────────────────────
echo ""
echo "── Step 6: Monitoring (Prometheus + Grafana + Loki) ──"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update
helm repo add grafana https://grafana.github.io/helm-charts --force-update
helm repo update prometheus-community grafana

helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  --set prometheusOperator.admissionWebhooks.enabled=false \
  --set prometheusOperator.admissionWebhooks.patch.enabled=false \
  --timeout=10m \
  -f "${REPO_ROOT}/DevOps/k8s/monitoring/kube-prometheus-stack-values.yaml" \
  -f "${REPO_ROOT}/DevOps/k8s/monitoring/values-secrets.yaml"

helm upgrade --install loki grafana/loki-stack \
  -n monitoring \
  -f "${REPO_ROOT}/DevOps/k8s/monitoring/loki-values.yaml"

# ── 7. ArgoCD ApplicationSet ─────────────────────────────────────────────────
echo ""
echo "── Step 7: ArgoCD ApplicationSet ──"
for ns in dev qa uat prod; do
  kubectl create namespace "${ns}" --dry-run=client -o yaml | kubectl apply -f -
done
kubectl apply -f "${REPO_ROOT}/DevOps/k8s/argocd/applicationset.yaml"

# ── 8. Apply network policies ─────────────────────────────────────────────────
echo ""
echo "── Step 8: Network policies ──"
for ns in dev qa uat prod; do
  for policy in "${REPO_ROOT}/DevOps/k8s/network-policies/"*.yaml; do
    sed "s/namespace: dev/namespace: ${ns}/g" "${policy}" | kubectl apply -f -
  done
done

# ── Summary ───────────────────────────────────────────────────────────────────
ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Bootstrap complete for ${CLUSTER_NAME}"
echo "════════════════════════════════════════════════════════"
echo ""
echo "  ArgoCD admin password: ${ARGOCD_PASS}"
echo "  Access ArgoCD:  kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "                  https://localhost:8080  (user: admin)"
echo ""
echo "  Next steps:"
echo "    1. Add GitHub secrets (see below)"
echo "    2. Push a commit to main — CI will build images and ArgoCD will sync"
echo "    3. After first sync, get the ALB DNS:"
echo "       kubectl get svc -n ${ENV} -l app.kubernetes.io/name=auth-service"
echo "    4. Re-run terraform apply with -var=alb_dns_name=<ALB_DNS>"
echo ""
echo "  GitHub Secrets to add at github.com/Ndewedo-Newbury/cs686-Final-Source/settings/secrets:"
echo "    AWS_ACCOUNT_ID        = ${ACCOUNT_ID}"
echo "    AWS_ACCESS_KEY_ID     = (from Voclabs — update every 4h)"
echo "    AWS_SECRET_ACCESS_KEY = (from Voclabs — update every 4h)"
echo "    AWS_SESSION_TOKEN     = (from Voclabs — update every 4h)"
echo ""
