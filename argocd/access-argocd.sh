#!/bin/bash
# Script to access ArgoCD UI on each cluster

echo "=========================================="
echo "ArgoCD Access Instructions"
echo "=========================================="
echo ""

# Function to get ArgoCD info for a cluster
get_argocd_info() {
  local ENV=$1
  local RG=$2
  local AKS_NAME=$3

  echo "---------- $ENV Environment ----------"
  echo "Connecting to $AKS_NAME..."

  az aks get-credentials \
    --resource-group $RG \
    --name $AKS_NAME \
    --admin \
    --overwrite-existing

  echo ""
  echo "Waiting for ArgoCD LoadBalancer to get an IP..."
  for i in {1..30}; do
    ARGOCD_IP=$(kubectl get svc argocd-server-lb -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    if [ ! -z "$ARGOCD_IP" ]; then
      break
    fi
    echo "Waiting for LoadBalancer IP... ($i/30)"
    sleep 5
  done

  if [ -z "$ARGOCD_IP" ]; then
    echo "⚠️  LoadBalancer IP not yet assigned. Check back in a few minutes."
    echo "Run: kubectl get svc argocd-server-lb -n argocd"
  else
    echo "✅ ArgoCD UI URL: http://$ARGOCD_IP"
  fi

  echo ""
  echo "Getting ArgoCD admin password..."
  ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d)

  if [ -z "$ARGOCD_PASSWORD" ]; then
    echo "⚠️  Admin password secret not found. ArgoCD may still be initializing."
  else
    echo "✅ Username: admin"
    echo "✅ Password: $ARGOCD_PASSWORD"
  fi

  echo ""
  echo "Checking ArgoCD Applications..."
  kubectl get applications -n argocd

  echo ""
  echo "=========================================="
  echo ""
}

# Uncomment the environments you want to check:

# DEV
get_argocd_info "DEV" "rg-capstone-dev" "aks-capstone-dev"

# QA
# get_argocd_info "QA" "rg-capstone-qa" "aks-capstone-qa"

# PROD
# get_argocd_info "PROD" "rg-capstone-prod" "aks-capstone-prod"

echo "=========================================="
echo "Next Steps:"
echo "1. Open the ArgoCD UI URL in your browser"
echo "2. Login with username: admin and the password above"
echo "3. You should see your 'backends-dev' application"
echo "4. Click on it to see the deployment status"
echo "=========================================="
