#!/bin/bash
set -euo pipefail

# ClusterRoleBindings для cluster-level пользователей
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-admin-binding
subjects:
- kind: User
  name: cluster-admin-user
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: analyst-binding
subjects:
- kind: User
  name: analyst-user
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-analyst
  apiGroup: rbac.authorization.k8s.io
EOF

# RoleBindings для namespace-level пользователей
for NS in client tenant; do
  if [ "$NS" = "client" ]; then
    USERS=("client-admin-user" "client-developer-user")
    ROLES=("client-admin" "client-developer")
  else
    USERS=("tenant-admin-user" "tenant-developer-user")
    ROLES=("tenant-admin" "tenant-developer")
  fi

  for i in "${!USERS[@]}"; do
    USER="${USERS[$i]}"
    ROLE="${ROLES[$i]}"
    kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${USER}-binding
  namespace: $NS
subjects:
- kind: User
  name: $USER
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: $ROLE
  apiGroup: rbac.authorization.k8s.io
EOF
  done
done
