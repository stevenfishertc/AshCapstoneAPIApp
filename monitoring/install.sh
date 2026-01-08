#!/bin/bash
# Script to install Prometheus and Grafana stack using Helm

set -e

echo "=========================================="
echo "Installing Prometheus & Grafana Stack"
echo "=========================================="

# Add Prometheus community Helm repo
echo "Adding Prometheus Helm repository..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install or upgrade the kube-prometheus-stack
echo "Installing kube-prometheus-stack..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values monitoring/prometheus-values.yaml \
  --wait \
  --timeout 10m

echo ""
echo "Waiting for Prometheus and Grafana to be ready..."
kubectl wait --for=condition=ready pod \
  --selector=app.kubernetes.io/name=prometheus \
  --namespace monitoring \
  --timeout=300s || true

kubectl wait --for=condition=ready pod \
  --selector=app.kubernetes.io/name=grafana \
  --namespace monitoring \
  --timeout=300s || true

echo ""
echo "=========================================="
echo "Getting Prometheus UI Access Info..."
echo "=========================================="

# Get Prometheus LoadBalancer IP
for i in {1..60}; do
  PROMETHEUS_IP=$(kubectl get svc prometheus-kube-prometheus-prometheus -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
  if [ ! -z "$PROMETHEUS_IP" ]; then
    echo "✅ Prometheus UI URL: http://$PROMETHEUS_IP:9090"
    break
  fi
  echo "⏳ Waiting for Prometheus LoadBalancer IP... ($i/60)"
  sleep 5
done

echo ""
echo "=========================================="
echo "Getting Grafana UI Access Info..."
echo "=========================================="

# Get Grafana LoadBalancer IP
for i in {1..60}; do
  GRAFANA_IP=$(kubectl get svc prometheus-grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
  if [ ! -z "$GRAFANA_IP" ]; then
    echo "✅ Grafana UI URL: http://$GRAFANA_IP"
    echo "   Username: admin"
    echo "   Password: admin123"
    echo ""
    echo "⚠️  IMPORTANT: Change the default password after first login!"
    break
  fi
  echo "⏳ Waiting for Grafana LoadBalancer IP... ($i/60)"
  sleep 5
done

echo ""
echo "=========================================="
echo "Installing ServiceMonitors for backends..."
echo "=========================================="
kubectl apply -f monitoring/backend-servicemonitors.yaml

echo ""
echo "=========================================="
echo "✅ Installation Complete!"
echo "=========================================="
echo ""
echo "Next Steps:"
echo "1. Access Grafana UI and change the default password"
echo "2. Navigate to Dashboards to view pre-built Kubernetes dashboards"
echo "3. Check Prometheus targets: http://$PROMETHEUS_IP:9090/targets"
echo "=========================================="
