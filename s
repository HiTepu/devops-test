apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: example-app-slo
  namespace: monitoring
  labels:
    release: monitoring
spec:
  groups:
  # =========================
  # SLI RECORDING RULES
  # =========================
  - name: sloth-slo-sli-recordings-example-app-http-availability
    rules:
    - record: slo:sli_error:ratio_rate5m
      expr: |
        (sum(rate(http_requests_total{status=~"5.."}[5m])))
        /
        (sum(rate(http_requests_total[5m])))
      labels:
        env: dev
        team: devops
        sloth_id: example-app-http-availability
        sloth_service: example-app
        sloth_slo: http-availability
        sloth_window: 5m

    - record: slo:sli_error:ratio_rate30m
      expr: |
        (sum(rate(http_requests_total{status=~"5.."}[30m])))
        /
        (sum(rate(http_requests_total[30m])))
      labels:
        env: dev
        team: devops
        sloth_id: example-app-http-availability
        sloth_service: example-app
        sloth_slo: http-availability
        sloth_window: 30m

    - record: slo:sli_error:ratio_rate1h
      expr: |
        (sum(rate(http_requests_total{status=~"5.."}[1h])))
        /
        (sum(rate(http_requests_total[1h])))
      labels:
        env: dev
        team: devops
        sloth_id: example-app-http-availability
        sloth_service: example-app
        sloth_slo: http-availability
        sloth_window: 1h

    - record: slo:sli_error:ratio_rate2h
      expr: |
        (sum(rate(http_requests_total{status=~"5.."}[2h])))
        /
        (sum(rate(http_requests_total[2h])))
      labels:
        env: dev
        team: devops
        sloth_id: example-app-http-availability
        sloth_service: example-app
        sloth_slo: http-availability
        sloth_window: 2h

    - record: slo:sli_error:ratio_rate6h
      expr: |
        (sum(rate(http_requests_total{status=~"5.."}[6h])))
        /
        (sum(rate(http_requests_total[6h])))
      labels:
        env: dev
        team: devops
        sloth_id: example-app-http-availability
        sloth_service: example-app
        sloth_slo: http-availability
        sloth_window: 6h

    - record: slo:sli_error:ratio_rate1d
      expr: |
        (sum(rate(http_requests_total{status=~"5.."}[1d])))
        /
        (sum(rate(http_requests_total[1d])))
      labels:
        env: dev
        team: devops
        sloth_id: example-app-http-availability
        sloth_service: example-app
        sloth_slo: http-availability
        sloth_window: 1d

    - record: slo:sli_error:ratio_rate3d
      expr: |
        (sum(rate(http_requests_total{status=~"5.."}[3d])))
        /
        (sum(rate(http_requests_total[3d])))
      labels:
        env: dev
        team: devops
        sloth_id: example-app-http-availability
        sloth_service: example-app
        sloth_slo: http-availability
        sloth_window: 3d

    - record: slo:sli_error:ratio_rate30d
      expr: |
        sum_over_time(
          slo:sli_error:ratio_rate5m{
            sloth_id="example-app-http-availability",
            sloth_service="example-app",
            sloth_slo="http-availability"
          }[30d]
        )
        /
        count_over_time(
          slo:sli_error:ratio_rate5m{
            sloth_id="example-app-http-availability",
            sloth_service="example-app",
            sloth_slo="http-availability"
          }[30d]
        )
      labels:
        env: dev
        team: devops
        sloth_id: example-app-http-availability
        sloth_service: example-app
        sloth_slo: http-availability
        sloth_window: 30d

  # =========================
  # META RECORDING RULES
  # =========================
  - name: sloth-slo-meta-recordings-example-app-http-availability
    rules:
    - record: slo:objective:ratio
      expr: vector(0.999)
      labels:
        env: dev
        team: devops
        sloth_id: example-app-http-availability
        sloth_service: example-app
        sloth_slo: http-availability

    - record: slo:error_budget:ratio
      expr: vector(0.001)
      labels:
        env: dev
        team: devops
        sloth_id: example-app-http-availability
        sloth_service: example-app
        sloth_slo: http-availability

    - record: slo:time_period:days
      expr: vector(30)
      labels:
        env: dev
        team: devops
        sloth_id: example-app-http-availability
        sloth_service: example-app
        sloth_slo: http-availability

    - record: slo:current_burn_rate:ratio
      expr: |
        slo:sli_error:ratio_rate5m
        /
        slo:error_budget:ratio
      labels:
        env: dev
        team: devops
        sloth_id: example-app-http-availability
        sloth_service: example-app
        sloth_slo: http-availability

    - record: slo:period_burn_rate:ratio
      expr: |
        slo:sli_error:ratio_rate30d
        /
        slo:error_budget:ratio
      labels:
        env: dev
        team: devops
        sloth_id: example-app-http-availability
        sloth_service: example-app
        sloth_slo: http-availability

    - record: sloth_slo_info
      expr: vector(1)
      labels:
        env: dev
        team: devops
        sloth_id: example-app-http-availability
        sloth_service: example-app
        sloth_slo: http-availability
        sloth_objective: "99.9"
        sloth_spec: prometheus/v1
        sloth_version: v0.11.0

  # =========================
  # ALERT RULES (BURN RATE)
  # =========================
  - name: sloth-slo-alerts-example-app-http-availability
    rules:
    - alert: ExampleAppHighErrorRate
      expr: |
        (
          max(slo:sli_error:ratio_rate5m > (14.4 * 0.001))
          and
          max(slo:sli_error:ratio_rate1h > (14.4 * 0.001))
        )
        or
        (
          max(slo:sli_error:ratio_rate30m > (6 * 0.001))
          and
          max(slo:sli_error:ratio_rate6h > (6 * 0.001))
        )
      for: 2m
      labels:
        severity: warning
        sloth_severity: page
      annotations:
        summary: High error rate for example-app
        description: SLO error budget burn rate is too fast (page alert)

    - alert: ExampleAppHighErrorRate
      expr: |
        (
          max(slo:sli_error:ratio_rate2h > (3 * 0.001))
          and
          max(slo:sli_error:ratio_rate1d > (3 * 0.001))
        )
        or
        (
          max(slo:sli_error:ratio_rate6h > (1 * 0.001))
          and
          max(slo:sli_error:ratio_rate3d > (1 * 0.001))
        )
      for: 10m
      labels:
        severity: warning
        sloth_severity: ticket
      annotations:
        summary: High error rate for example-app
        description: SLO error budget burn rate is too fast (ticket alert)
