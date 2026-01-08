# Prometheus & Grafana Monitoring Setup

This directory contains configuration for deploying Prometheus and Grafana monitoring stack to your AKS clusters.

## What Gets Installed?

The **kube-prometheus-stack** Helm chart installs:
- ✅ **Prometheus** - Metrics collection and storage
- ✅ **Grafana** - Pre-configured dashboards and visualization
- ✅ **Alertmanager** - Alert routing and management
- ✅ **Node Exporter** - Node-level metrics (CPU, memory, disk, network)
- ✅ **kube-state-metrics** - Kubernetes resource metrics (pods, deployments, etc.)
- ✅ **Pre-built dashboards** - Ready-to-use Kubernetes monitoring dashboards

## Files

- `prometheus-values.yaml` - Helm values configuration
- `backend-servicemonitors.yaml` - ServiceMonitors for backend-a and backend-b
- `install.sh` - Manual installation script (if not using pipeline)

## Pipeline Deployment

The Azure Pipeline automatically deploys the monitoring stack to all three environments (DEV, QA, PROD).

After the pipeline runs, check the logs for access information:

```
==========================================
📊 Monitoring DEV Environment
==========================================
🔍 Prometheus: http://20.123.45.67:9090
📈 Grafana: http://20.234.56.78
   Username: admin | Password: admin123
==========================================
```

## Accessing Grafana

### 1. Login
- **URL**: `http://<GRAFANA_IP>` (from pipeline logs)
- **Username**: `admin`
- **Password**: `admin123`

⚠️ **IMPORTANT**: Change the default password after first login!

### 2. Change Password
1. Click on the profile icon (bottom left)
2. Select **Preferences**
3. Go to **Change Password**
4. Enter current password: `admin123`
5. Enter your new password

### 3. View Dashboards

Click on **Dashboards** → **Browse** to see pre-built dashboards:

**Kubernetes Dashboards**:
- **Kubernetes / Compute Resources / Cluster** - Overall cluster metrics
- **Kubernetes / Compute Resources / Namespace (Pods)** - Per-namespace metrics
- **Kubernetes / Compute Resources / Pod** - Individual pod metrics
- **Kubernetes / Networking / Cluster** - Network traffic
- **Node Exporter / Nodes** - Node-level system metrics

**Application Dashboards**:
- Your backend-a and backend-b services will appear in pod dashboards
- Filter by namespace: `default`
- Filter by app: `backend-a` or `backend-b`

## Accessing Prometheus

### 1. Prometheus UI
- **URL**: `http://<PROMETHEUS_IP>:9090` (from pipeline logs)

### 2. Check Targets
Navigate to **Status** → **Targets** to see all services Prometheus is scraping:
- ✅ `serviceMonitor/default/backend-a-monitor/0` - backend-a metrics
- ✅ `serviceMonitor/default/backend-b-monitor/0` - backend-b metrics
- ✅ Node exporter targets
- ✅ Kube-state-metrics
- ✅ Kubernetes API server

### 3. Query Metrics

Example PromQL queries:

```promql
# CPU usage by pod
rate(container_cpu_usage_seconds_total{pod=~"backend-a.*"}[5m])

# Memory usage by pod
container_memory_working_set_bytes{pod=~"backend-a.*"}

# HTTP request rate (if your app exposes /metrics endpoint)
rate(http_requests_total{app="backend-a"}[5m])

# Pod restart count
kube_pod_container_status_restarts_total{pod=~"backend-.*"}
```

## What Metrics Are Collected?

### Kubernetes Metrics (Automatic)
- ✅ CPU usage per pod/node
- ✅ Memory usage per pod/node
- ✅ Disk I/O and usage
- ✅ Network traffic
- ✅ Pod status and restarts
- ✅ Deployment status
- ✅ Service endpoints

### Application Metrics (Requires /metrics endpoint)
Your backend applications need to expose a `/metrics` endpoint in Prometheus format.

**For Node.js/Express apps**, add the `prom-client` library:

```bash
npm install prom-client
```

Then in your app:

```javascript
const promClient = require('prom-client');

// Create a Registry
const register = new promClient.Registry();

// Add default metrics (CPU, memory, event loop, etc.)
promClient.collectDefaultMetrics({ register });

// Custom metrics example
const httpRequestCounter = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register]
});

// Increment on each request
app.use((req, res, next) => {
  res.on('finish', () => {
    httpRequestCounter.inc({
      method: req.method,
      route: req.route?.path || req.path,
      status_code: res.statusCode
    });
  });
  next();
});

// Expose /metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});
```

## ServiceMonitors

The `backend-servicemonitors.yaml` file tells Prometheus to scrape your backend services.

It looks for:
- Services with label `app: backend-a` or `app: backend-b`
- Port named `http`
- Path `/metrics`
- Scrape interval: 30 seconds

If your services match these criteria, Prometheus will automatically collect metrics.

## Storage

Prometheus and Grafana both use persistent volumes:
- **Prometheus**: 10Gi storage, 7 days retention
- **Grafana**: 5Gi storage for dashboards
- **Alertmanager**: 5Gi storage for alert history

Data persists across pod restarts.

## Alerting

Alertmanager is included but not configured yet. To set up alerts:

1. Create PrometheusRule resources
2. Configure Alertmanager receivers (email, Slack, PagerDuty, etc.)
3. Define alert routing rules

Example alert rule:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: backend-alerts
  namespace: monitoring
spec:
  groups:
  - name: backend
    interval: 30s
    rules:
    - alert: HighErrorRate
      expr: rate(http_requests_total{status_code=~"5.."}[5m]) > 0.05
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High HTTP error rate on {{ $labels.app }}"
```

## Troubleshooting

### Grafana LoadBalancer IP not assigned
```bash
kubectl get svc prometheus-grafana -n monitoring -w
```
Wait for Azure to provision the LoadBalancer (2-5 minutes).

### Prometheus not scraping backends
Check ServiceMonitor status:
```bash
kubectl get servicemonitor -n default
kubectl describe servicemonitor backend-a-monitor
```

Verify service labels:
```bash
kubectl get svc backend-a -o yaml | grep -A5 labels
```

### View Prometheus logs
```bash
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus
```

### View Grafana logs
```bash
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana
```

## Manual Installation

If not using the pipeline, run:

```bash
chmod +x monitoring/install.sh
./monitoring/install.sh
```

## Uninstall

To remove monitoring stack:

```bash
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring
```

## Next Steps

1. ✅ Access Grafana UI and change default password
2. ✅ Browse pre-built Kubernetes dashboards
3. ✅ Add `/metrics` endpoint to your backend applications
4. ✅ Create custom dashboards for your application metrics
5. ✅ Set up alerting rules for critical metrics
