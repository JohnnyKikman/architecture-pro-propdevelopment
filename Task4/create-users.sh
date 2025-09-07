#!/bin/bash
set -euo pipefail

CLUSTER_NAME="minikube"
OUTPUT_DIR="./users"
mkdir -p "$OUTPUT_DIR"

NAMESPACES=("client" "tenant")

# Создаём тестовый CA...
openssl genrsa -out "$OUTPUT_DIR/ca.key" 2048
openssl req -x509 -new -nodes -key "$OUTPUT_DIR/ca.key" -subj "/CN=test-ca" -days 365 -out "$OUTPUT_DIR/ca.crt"

# Создаём namespace, если их нет
for ns in "${NAMESPACES[@]}"; do
  kubectl get ns "$ns" >/dev/null 2>&1 || kubectl create ns "$ns"
done

# Cluster-level пользователи: USER
CLUSTER_USERS=(
  "cluster-admin-user"
  "analyst-user"
)

# Namespace-level пользователи: USER:NAMESPACE
NAMESPACE_USERS=(
  "client-admin-user:client"
  "client-developer-user:client"
  "tenant-admin-user:tenant"
  "tenant-developer-user:tenant"
)

generate_cert() {
  local USERNAME=$1
  openssl genrsa -out "$OUTPUT_DIR/$USERNAME.key" 2048
  openssl req -new -key "$OUTPUT_DIR/$USERNAME.key" -out "$OUTPUT_DIR/$USERNAME.csr" -subj "/CN=$USERNAME/O=$USERNAME"
  openssl x509 -req -in "$OUTPUT_DIR/$USERNAME.csr" -CA "$OUTPUT_DIR/ca.crt" -CAkey "$OUTPUT_DIR/ca.key" -CAcreateserial -out "$OUTPUT_DIR/$USERNAME.crt" -days 365
}

# Создаём cluster-level пользователей
for USERNAME in "${CLUSTER_USERS[@]}"; do
  echo "Creating user $USERNAME"
  generate_cert "$USERNAME"

  kubectl config set-credentials "$USERNAME" \
    --client-certificate="$OUTPUT_DIR/$USERNAME.crt" \
    --client-key="$OUTPUT_DIR/$USERNAME.key"

  kubectl config set-context "$USERNAME-context" \
    --cluster="$CLUSTER_NAME" \
    --user="$USERNAME" \
    --namespace="default"
done

# Создаём namespace-level пользователей
for entry in "${NAMESPACE_USERS[@]}"; do
  USERNAME="${entry%%:*}"
  NAMESPACE="${entry##*:}"
  echo "Creating user $USERNAME for namespace $NAMESPACE"
  generate_cert "$USERNAME"

  kubectl config set-credentials "$USERNAME" \
    --client-certificate="$OUTPUT_DIR/$USERNAME.crt" \
    --client-key="$OUTPUT_DIR/$USERNAME.key"

  kubectl config set-context "$USERNAME-context" \
    --cluster="$CLUSTER_NAME" \
    --user="$USERNAME" \
    --namespace="$NAMESPACE"
done

rm -rf "$OUTPUT_DIR"