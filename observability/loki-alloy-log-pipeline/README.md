# Loki and Grafana Alloy Log Pipeline

## What This Does

This implementation demonstrates a centralized logging pipeline using Grafana Loki, Grafana Alloy, LogCLI, and Python.

A Python application generates operational events and writes them to a log file. Grafana Alloy continuously monitors the log file and forwards every new event to Grafana Loki. LogCLI is then used to query, filter, search, and analyze the collected logs using LogQL.

The implementation covers the complete workflow of log generation, collection, aggregation, querying, troubleshooting, and operational verification.

---

## Architecture

```
Python Application
        │
        ▼
   /tmp/app.log
        │
        ▼
 Grafana Alloy
        │
        ▼
 Grafana Loki
        │
        ▼
      LogCLI
```

---

## Technologies Used

- Ubuntu Linux
- Python 3
- Grafana Loki
- Grafana Alloy
- LogCLI
- LogQL
- systemd

---

## Features

- Centralized application logging
- Real-time log collection
- Log aggregation
- LogQL searching
- Error filtering
- Warning filtering
- Connection timeout detection
- Error counting
- Operational troubleshooting

---

## Repository Structure

```
observability/
└── loki-alloy-log-pipeline/
    └── README.md
```

---

## Implementation Workflow

1. Generate application logs using Python.
2. Store logs inside `/tmp/app.log`.
3. Monitor the log file using Grafana Alloy.
4. Forward logs into Grafana Loki.
5. Query logs using LogCLI.
6. Filter INFO, WARNING and ERROR events.
7. Count matching events using LogQL metrics.
8. Verify successful end-to-end log ingestion.

---

## Verification Results

Successfully verified:

- Loki service running
- Grafana Alloy running
- Log forwarding operational
- 22 total log entries
- 13 INFO events
- 5 WARNING events
- 4 ERROR events
- 4 Connection timeout events
- Successful LogQL filtering
- Successful metric queries

---

## Skills Demonstrated

- Centralized logging
- Observability Engineering
- Grafana Loki
- Grafana Alloy
- Linux system administration
- LogQL
- Log analysis
- Production troubleshooting
- Service management
- Operational monitoring

---

## Real-World Applications

This architecture is commonly used for:

- Kubernetes platforms
- Containerized applications
- Platform Engineering
- DevOps
- Site Reliability Engineering
- MLOps
- AI infrastructure
- Backend services
- Internal APIs
- Production monitoring

---

## Lessons Learned

- Build centralized logging pipelines.
- Configure Grafana Loki.
- Configure Grafana Alloy.
- Ship logs securely.
- Query logs using LogQL.
- Filter operational events.
- Count application errors.
- Troubleshoot service failures.
- Resolve Linux permission issues.
- Resolve port conflicts.
- Verify complete log ingestion pipelines.

