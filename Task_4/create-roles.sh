#!/bin/bash

source ./.env

echo "=== Создание ролей ==="
echo ""

cat <<EOF | kubectl apply -f -
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pods-crud
  namespace: ${DEV_NAMESPACE}
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log", "pods/exec"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: services-crud
  namespace: ${DEV_NAMESPACE}
rules:
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: configmaps-crud
  namespace: ${DEV_NAMESPACE}
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
EOF
echo "✓ Роли pods-crud, services-crud, configmaps-crud созданы в $DEV_NAMESPACE"

cat <<EOF | kubectl apply -f -
---
# Security Role - чтение в dev namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secrets-reader
  namespace: ${DEV_NAMESPACE}
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
EOF
echo "✓ Роль secrets-reader создана в $DEV_NAMESPACE"

cat <<EOF | kubectl apply -f -
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: metrics-reader
  namespace: ${MONITORING_NAMESPACE}
rules:
- apiGroups: [""]
  resources: ["pods", "services", "endpoints"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
- apiGroups: ["apps"]
  resources: ["deployments", "statefulsets"]
  verbs: ["get", "list", "watch"]
EOF
echo "✓ Роль metrics-reader создана в MONITORING_NAMESPACE"

echo ""
echo "Список созданных ролей:"
echo "=== Namespace Roles ==="
kubectl get roles --all-namespaces | grep -E "(dev|monitoring)"
echo ""
echo "=== ClusterRoles ==="
kubectl get clusterroles | grep -E "(dev|monitoring)"
echo ""