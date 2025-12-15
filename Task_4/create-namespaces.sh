#!/bin/bash

source ./.env

echo "=== Создание namespace ==="
echo ""

for ns in "$DEV_NAMESPACE" "$MONITORING_NAMESPACE"; do
    echo "Создаем namespace: $ns"
    kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -

    if kubectl get namespace "$ns" &> /dev/null; then
        echo "  ✓ Namespace $ns создан успешно"
    else
        echo "  ✗ Ошибка при создании namespace $ns"
    fi
    echo ""
done

echo "Список всех namespace:"
kubectl get namespaces
echo ""