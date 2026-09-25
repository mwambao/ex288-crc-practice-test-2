#!/usr/bin/env bash
set -euo pipefail
# Practice Test 2 intentionally does not pre-create exam projects.
# It only prepares shared mock dependency infrastructure.
if ! oc get project lab-infra >/dev/null 2>&1; then oc new-project lab-infra >/dev/null; fi
oc project lab-infra >/dev/null
cat <<'EOF' | oc apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata: {name: nexus-mock}
spec:
  replicas: 1
  selector: {matchLabels: {app: nexus-mock}}
  template:
    metadata: {labels: {app: nexus-mock}}
    spec:
      containers:
      - name: server
        image: python:3.12-alpine
        command: ["/bin/sh","-c"]
        args: ["mkdir -p /data; echo 'artifact supplied by nexus mock' > /data/banner.txt; cd /data; python -m http.server 8080"]
        ports: [{containerPort: 8080}]
---
apiVersion: v1
kind: Service
metadata: {name: nexus-mock}
spec: {selector: {app: nexus-mock}, ports: [{port: 8080, targetPort: 8080}]}
EOF
echo 'Practice Test 2 infrastructure ready.'
echo 'Push each repos/pt2-* directory to Git before starting the timed test.'
