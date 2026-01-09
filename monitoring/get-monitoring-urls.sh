#!/bin/bash

# Script to retrieve Prometheus and Grafana URLs from all environments
# Run this after the pipeline completes to get the monitoring dashboard URLs

set -e

echo ""
echo "========================================"
echo "🔍 Retrieving Monitoring Dashboard URLs"
echo "========================================"
echo ""

# Function to get monitoring URLs for an environment
get_monitoring_urls() {
  local env_name=$1
  local resource_group=$2
  local aks_name=$3

  echo "----------------------------------------"
  echo "📊 $env_name Environment"
  echo "----------------------------------------"

  # Connect to AKS cluster
  az aks get-credentials \
    --resource-group "$resource_group" \
    --name "$aks_name" \
    --admin \
    --overwrite-existing > /dev/null 2>&1

  # Get Ingress IP (monitoring now uses Ingress instead of separate LoadBalancers)
  INGRESS_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

  # Display results
  if [ ! -z "$INGRESS_IP" ]; then
    echo "🔍 Prometheus: http://$INGRESS_IP/prometheus"
    echo "📈 Grafana: http://$INGRESS_IP/grafana"
    echo "   Username: admin"
    echo "   Password: admin123"
  else
    echo "⚠️  Ingress IP pending"
    echo "   Check status: kubectl get svc ingress-nginx-controller -n ingress-nginx"
  fi

  echo ""
}

# Get URLs from all environments
get_monitoring_urls "DEV" "steven-rg-capstone-dev" "aks-capstone-dev"
get_monitoring_urls "QA" "steven-rg-capstone-qa" "aks-capstone-qa"
get_monitoring_urls "PROD" "steven-rg-capstone-prod" "aks-capstone-prod"

echo "========================================"
echo "✅ Monitoring URLs retrieved"
echo "========================================"
echo ""
echo "Note: If any LoadBalancer IPs are still pending,"
echo "wait a few minutes and run this script again."
echo ""
