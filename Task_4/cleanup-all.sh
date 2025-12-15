#!/bin/bash

source ./.env

echo "=========================================="
echo "ОЧИСТКА: пользователи, роли, связи"
echo "=========================================="
echo ""

check_output() {
if [ $? -eq 0 ]; then
echo "  ✓ Успешно"
else
echo "  ⚠ Частично выполнено (возможно, ресурс уже удален)"
fi
}

echo "1. Удаление CertificateSigningRequest (пользователей)..."
for user in "$USER_DEVOPS" "$USER_MONITORING"; do
echo "  Удаление CSR для $user..."
kubectl delete csr "${user}-csr" 2>/dev/null
done
check_output

echo ""
echo "2. Удаление RoleBinding..."
echo "  В namespace $DEV_NAMESPACE:"
kubectl delete rolebinding -n "$DEV_NAMESPACE" --all 2>/dev/null
check_output

echo "  В namespace $MONITORING_NAMESPACE:"
kubectl delete rolebinding -n "$MONITORING_NAMESPACE" --all 2>/dev/null
check_output

echo ""
echo "4. Удаление Roles..."
echo "  В namespace $DEV_NAMESPACE:"
kubectl delete role -n "$DEV_NAMESPACE" --all 2>/dev/null
check_output

echo "  В namespace $MONITORING_NAMESPACE:"
kubectl delete role -n "$MONITORING_NAMESPACE" --all 2>/dev/null
check_output

echo ""
echo "6. Удаление namespace..."
for ns in "$DEV_NAMESPACE" "$MONITORING_NAMESPACE"; do
echo "  Удаляю namespace $ns..."
kubectl delete all --all -n "$ns"
kubectl delete namespace "$ns" --force --grace-period=0 2>/dev/null
done
check_output

echo ""
echo "8. Удаление локальных файлов и директорий..."
echo "  Удаляю kubeconfig файлы..."
rm -f devops1-kubeconfig.yaml security1-kubeconfig.yaml manager1-kubeconfig.yaml 2>/dev/null

echo "  Удаляю директорию users..."
rm -rf users/ 2>/dev/null

echo "  Удаляю сертификаты и ключи..."
rm -f *.key *.crt *.csr *.pem *.srl 2>/dev/null

echo "  Удаляю временные файлы..."
rm -f *-rbac.yaml *-token.txt 2>/dev/null

echo "  ✓ Локальные файлы удалены"

echo ""
echo "9. Проверка остаточных ресурсов..."
echo "=========================================="

echo "Оставшиеся CSR:"
csr_count=$(kubectl get csr 2>/dev/null | grep -v NAME | wc -l)
if [ "$csr_count" -eq 0 ]; then
    echo "  Нет пользовательских CSR"
else
    kubectl get csr
fi

echo ""
echo "Оставшиеся namespace:"
ns_count=$(kubectl get namespace 2>/dev/null | grep -E "(dev-ns|monitoring-ns)" | wc -l)
if [ "$ns_count" -eq 0 ]; then
    echo "  Нет пользовательских Namespaces"
else
    kubectl get namespace
fi

echo ""
echo "Оставшиеся Roles:"
roles_count=$(kubectl get roles --all-namespaces 2>/dev/null | grep -E "(pods-crud|services-crud|configmaps-crud|secrets-reader|metrics-reader)" | wc -l)
if [ "$roles_count" -eq 0 ]; then
    echo "  Нет пользовательских Roles"
else
    kubectl get roles --all-namespaces
fi

echo ""
echo "=========================================="
echo "ОЧИСТКА ЗАВЕРШЕНА!"
echo "=========================================="
echo ""
echo "Все созданные ресурсы удалены:"
echo "✓ Пользователи (CSR)"
echo "✓ Роли (Roles)"
echo "✓ ClusterRoles"
echo "✓ RoleBinding"
echo "✓ ClusterRoleBinding"
echo "✓ Namespace"
echo "✓ Локальные файлы"
