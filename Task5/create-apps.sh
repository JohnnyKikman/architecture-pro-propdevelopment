#!/bin/bash

set -e

# Определим роли
roles=("front-end" "back-end-api" "admin-front-end" "admin-back-end-api")

for role in "${roles[@]}"; do
  app_name="${role}-app"
  cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${app_name}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${app_name}
  template:
    metadata:
      labels:
        app: ${app_name}
        role: ${role}
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: ${app_name}-service
spec:
  selector:
    app: ${app_name}
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
EOF
done
