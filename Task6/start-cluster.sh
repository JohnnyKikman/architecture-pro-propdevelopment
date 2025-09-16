#!/bin/bash
set -euo pipefail

mkdir -p ~/.minikube/files/etc/ssl/certs
cp audit-policy.yaml ~/.minikube/files/etc/ssl/certs/audit-policy.yaml

# Запускаем minikube с нужными параметрами
minikube start \
  --extra-config=apiserver.audit-policy-file=/etc/ssl/certs/audit-policy.yaml \
  --extra-config=apiserver.audit-log-path=-

echo "Сохранение логов: kubectl logs kube-apiserver-minikube -n  kube-system | grep audit.k8s.io/v1 > audit.log"