#!/bin/bash

source ./.env

echo "=== Привязка пользователей к ролям ==="
echo ""

cat <<EOF | kubectl apply -f -
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: devops-pods-crud-binding-dev
  namespace: ${DEV_NAMESPACE}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pods-crud
subjects:
- kind: User
  name: ${USER_DEVOPS}
  apiGroup: rbac.authorization.k8s.io
- kind: Group
  name: ${GROUP_DEVOPS}
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: devops-services-crud-binding-dev
  namespace: ${DEV_NAMESPACE}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: services-crud
subjects:
- kind: User
  name: ${USER_DEVOPS}
  apiGroup: rbac.authorization.k8s.io
- kind: Group
  name: ${GROUP_DEVOPS}
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: devops-configmaps-crud-binding-dev
  namespace: ${DEV_NAMESPACE}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: configmaps-crud
subjects:
- kind: User
  name: ${USER_DEVOPS}
  apiGroup: rbac.authorization.k8s.io
- kind: Group
  name: ${GROUP_DEVOPS}
  apiGroup: rbac.authorization.k8s.io
EOF
echo "  ✓ dev ops in $DEV_NAMESPACE для $USER_DEVOPS, $GROUP_DEVOPS"

echo ""
cat <<EOF | kubectl apply -f -
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: secrets-reader-binding-dev
  namespace: ${DEV_NAMESPACE}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: secrets-reader
subjects:
- kind: User
  name: ${USER_SECURITY}
  apiGroup: rbac.authorization.k8s.io
EOF
echo "  ✓ Чтение секретов в $DEV_NAMESPACE для $USER_SECURITY"

echo ""
cat <<EOF | kubectl apply -f -
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: metrics-reader-binding-monitoring
  namespace: ${MONITORING_NAMESPACE}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: metrics-reader
subjects:
- kind: Group
  name: ${GROUP_MONITORING}
  apiGroup: rbac.authorization.k8s.io
EOF
echo "  ✓ Доступ к метрикам и логам в $MONITORING_NAMESPACE для $GROUP_MONITORING"

echo ""
echo "Проверка всех RoleBinding:"
echo "=== Namespace RoleBindings ==="
kubectl get rolebindings --all-namespaces | grep -v kube-system | grep -E "(dev|monitoring)"
echo ""
echo "=== ClusterRoleBindings ==="
kubectl get clusterrolebindings | grep -E "(dev|monitoring)"
echo ""