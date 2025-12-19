# CI/CD Pipeline Documentation

## 📋 Tổng quan

Pipeline CI/CD hoàn chỉnh với các tính năng:
- ✅ **Testing**: Unit tests và integration tests
- 🔒 **Security Scanning**: Trivy vulnerability scanning
- 🐳 **Build & Push**: Docker build và push lên Harbor
- 📊 **Monitoring**: Grafana + Prometheus + Sloth SLO
- 💾 **Backup**: Tự động backup trước mỗi deployment
- ⏮️ **Rollback**: Hỗ trợ rollback tự động và manual

## 🏗️ Kiến trúc

```
┌─────────────┐
│   GitHub    │
│   Actions   │
└──────┬──────┘
       │
       ├─► Test ──────────────┐
       │                      │
       ├─► Security Scan ─────┤
       │   (Trivy)            │
       │                      ├─► Metrics
       ├─► Build & Push ──────┤    Push to
       │   (Harbor)           │    Prometheus
       │                      │
       ├─► Update Manifests ──┤
       │                      │
       └─► Verify ────────────┘
              │
              ▼
       ┌──────────┐
       │  ArgoCD  │
       │   Sync   │
       └────┬─────┘
            │
            ▼
       ┌──────────┐
       │    K8s   │
       │ Cluster  │
       └──────────┘
```

## 🚀 Setup

### 1. GitHub Secrets

Cấu hình các secrets sau trong GitHub repository:

```bash
HARBOR_USERNAME    # Harbor registry username
HARBOR_PASSWORD    # Harbor registry password
GITHUB_TOKEN      # Tự động có sẵn
```

### 2. Prometheus Pushgateway

Deploy Prometheus Pushgateway trong cluster:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus-pushgateway
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus-pushgateway
  template:
    metadata:
      labels:
        app: prometheus-pushgateway
    spec:
      containers:
      - name: pushgateway
        image: prom/pushgateway:latest
        ports:
        - containerPort: 9091
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus-pushgateway
  namespace: monitoring
spec:
  selector:
    app: prometheus-pushgateway
  ports:
  - port: 9091
    targetPort: 9091
```

### 3. Prometheus Configuration

Thêm job scrape trong Prometheus config:

```yaml
scrape_configs:
  - job_name: 'pushgateway'
    honor_labels: true
    static_configs:
      - targets: ['prometheus-pushgateway.monitoring.svc.cluster.local:9091']
```

### 4. Alert Rules

Apply Prometheus alert rules:

```bash
kubectl apply -f prometheus-alerts.yaml -n monitoring
```

### 5. Grafana Dashboard

Import dashboard JSON vào Grafana:
- Go to Dashboards → Import
- Paste JSON content từ `grafana-dashboard.json`
- Select Prometheus datasource

### 6. Sloth Installation

Cài đặt Sloth để generate SLO rules:

```bash
# Download Sloth
wget https://github.com/slok/sloth/releases/download/v0.11.0/sloth-linux-amd64
chmod +x sloth-linux-amd64
sudo mv sloth-linux-amd64 /usr/local/bin/sloth

# Generate SLO rules
sloth generate -i slo-spec.yaml -o prometheus-slo-rules.yaml

# Apply to Prometheus
kubectl apply -f prometheus-slo-rules.yaml -n monitoring
```

## 📊 Monitoring

### Metrics được thu thập

| Metric | Type | Description |
|--------|------|-------------|
| `cicd_build_status` | Gauge | Build status (1=success, 0=failure) |
| `cicd_build_duration_seconds` | Gauge | Build duration in seconds |
| `cicd_test_status` | Gauge | Test execution status |
| `cicd_vulnerabilities_total` | Gauge | Vulnerabilities by severity |
| `cicd_deployment_status` | Gauge | Deployment status |
| `cicd_deployment_timestamp_seconds` | Gauge | Deployment timestamp |
| `cicd_rollback_total` | Counter | Total rollback operations |

### Grafana Dashboards

Dashboard cung cấp các panel:
- ✅ Build Success Rate
- 🚀 Deployment Success Rate  
- 🔒 Security Vulnerabilities
- ⏱️ Build Duration Trends
- 📈 SLO Error Budget
- 🔄 Rollback Count

Access: `http://grafana.monitoring.svc.cluster.local:3000/d/cicd-pipeline`

### Prometheus Alerts

Các alerts được cấu hình:
- `BuildFailureRate`: High build failure rate
- `CriticalVulnerabilitiesDetected`: Critical security issues
- `DeploymentFailure`: Deployment failed
- `ErrorBudgetExhausted`: SLO error budget depleted
- `FrequentRollbacks`: Multiple rollbacks detected

## 🔒 Security Scanning

### Trivy Configuration

Pipeline sử dụng Trivy để scan vulnerabilities:

```yaml
- CRITICAL và HIGH vulnerabilities được upload lên GitHub Security
- CRITICAL vulnerabilities > 0 sẽ block deployment
- Results được push lên Prometheus để monitoring
```

### Vulnerability Thresholds

```yaml
CRITICAL: 0     # Block deployment
HIGH: 10        # Warning alert
MEDIUM: 50      # Informational
```

Có thể điều chỉnh threshold trong workflow file.

## 💾 Backup & Rollback

### Automatic Backup

Mỗi deployment tự động backup deployment.yaml:
- Backup folder: `backups/`
- Format: `deployment-YYYYMMDD-HHMMSS-{TAG}.yaml`
- Retention: 30 days (GitHub Artifacts)

### Manual Rollback

Sử dụng script `rollback.sh`:

```bash
# List available versions
./rollback.sh --list

# Show current version
./rollback.sh --current

# Rollback to previous version
./rollback.sh --previous

# Rollback to specific version
./rollback.sh --tag abc123

# Dry run (preview changes)
./rollback.sh --tag abc123 --dry-run
```

### GitHub Actions Rollback

Trigger manual rollback workflow:

```bash
# Via GitHub UI
Actions → CI/CD Pipeline → Run workflow → Select branch

# Via GitHub CLI
gh workflow run "CI/CD Pipeline" --ref main
```

## 🧪 Testing

### Unit Tests

Thêm unit tests vào job `test`:

```yaml
- name: Run unit tests
  run: |
    npm test              # NodeJS
    # pytest              # Python
    # go test ./...       # Go
    # mvn test            # Java
```

### Integration Tests

Thêm integration tests:

```yaml
- name: Run integration tests
  run: |
    docker-compose -f docker-compose.test.yml up --abort-on-container-exit
```

## 📈 SLO (Service Level Objectives)

### Defined SLOs

1. **Deployment Success Rate**: 99.9%
   - Error budget: 0.1% (43 minutes/month)
   
2. **Build Duration**: 95% under 5 minutes
   - Target: P95 < 300s

### SLO Alerts

- `ErrorBudgetLow`: < 10% remaining
- `ErrorBudgetExhausted`: < 1% remaining

### Error Budget Policy

Khi error budget < 10%:
1. Freeze non-critical deployments
2. Focus on stability improvements
3. Root cause analysis for failures

## 🔄 Workflow Flow

```
1. Code Push
   ↓
2. Run Tests (unit + integration)
   ↓
3. Security Scan (Trivy)
   ↓ (if no critical vulnerabilities)
4. Backup Current State
   ↓
5. Build Docker Image
   ↓
6. Push to Harbor (SHA + latest tags)
   ↓
7. Update Kubernetes Manifests
   ↓
8. Commit & Push Manifests
   ↓
9. ArgoCD Auto-Sync (3 minutes)
   ↓
10. Verify Deployment
    ↓
11. Push Metrics to Prometheus
```

## 🎯 Best Practices

### 1. Commit Messages
- Use `[skip ci]` to skip pipeline execution
- Format: `🚀 Update image to {TAG} [skip ci]`

### 2. Image Tags
- Use SHA tags for traceability: `{GITHUB_SHA}`
- Always update `latest` tag

### 3. Security
- Review Trivy results in GitHub Security tab
- Address CRITICAL vulnerabilities immediately
- Monitor security metrics in Grafana

### 4. Monitoring
- Check Grafana dashboard daily
- Set up Slack/Teams alerts from Prometheus
- Review SLO error budget weekly

### 5. Rollback Strategy
- Always backup before deployment
- Test rollback procedure quarterly
- Document rollback reasons

## 🐛 Troubleshooting

### Pipeline Failures

**Build Failure**
```bash
# Check build logs in GitHub Actions
# Review Docker build output
# Verify Dockerfile syntax
```

**Security Scan Failure**
```bash
# View Trivy results
gh run view --log-failed

# Check specific vulnerability
trivy image {IMAGE}:{TAG} --severity CRITICAL
```

**Deployment Failure**
```bash
# Check ArgoCD sync status
argocd app get {APP_NAME}

# View pod logs
kubectl logs -n demo -l app=nginx

# Rollback if needed
./rollback.sh --previous
```

### Metrics Not Appearing

```bash
# Check Pushgateway
curl http://prometheus-pushgateway.monitoring.svc.cluster.local:9091/metrics

# Verify Prometheus scraping
kubectl logs -n monitoring prometheus-xxx

# Check Prometheus targets
# Prometheus UI → Status → Targets
```

### ArgoCD Not Syncing

```bash
# Check ArgoCD sync status
argocd app sync {APP_NAME}

# Force refresh
argocd app get {APP_NAME} --refresh

# Check ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

## 📚 References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Prometheus Pushgateway](https://github.com/prometheus/pushgateway)
- [Sloth SLO Generator](https://github.com/slok/sloth)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)

## 🤝 Contributing

1. Test changes in feature branch
2. Review security scan results
3. Ensure metrics are being pushed
4. Update documentation
5. Create Pull Request

## 📝 License

MIT License

## 👥 Support

- GitHub Issues: [Create Issue](https://github.com/your-repo/issues)
- Slack: #devops-support
- Email: devops@example.com
