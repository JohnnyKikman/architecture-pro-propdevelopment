#!/bin/bash
set -e

echo "[*] Запуск Minikube..."
minikube start

echo "[*] Создание namespace audit-zone..."
kubectl apply -f ../01-create-namespace.yaml

echo "[*] Пробуем создать Pod с privileged контейнером..."
kubectl apply -f ../insecure-manifests/01-privileged-pod.yaml || true

echo "[*] Пробуем создать Pod с hostPath..."
kubectl apply -f ../insecure-manifests/02-hostpath-pod.yaml || true

echo "[*] Пробуем создать Pod от root (uid 0)..."
kubectl apply -f ../insecure-manifests/03-root-user-pod.yaml || true

echo "[*] Проверяем события в namespace audit-zone..."
kubectl get events -n audit-zone --sort-by=.lastTimestamp | tail -n 20