#!/bin/bash

source ./.env

for user in "$USER_DEVOPS" "$USER_SECURITY" "$USER_MONITORING"; do
  for namespace in "$DEV_NAMESPACE" "$MONITORING_NAMESPACE"; do
    kubeconfig="${user}-kubeconfig.yaml"
    if [ -f "$kubeconfig" ]; then
        echo -n "$user: "
        if kubectl --kubeconfig="$kubeconfig" auth can-i get pods -n $namespace 2>/dev/null | grep -q "yes"; then
            echo "✓ get pods - Доступ есть в ${namespace}"
        else
            echo "✗ get pods - Доступа нет в ${namespace}"
        fi
    else
        echo "$user: Kubeconfig не найден"
    fi
  done
done

for user in "$USER_DEVOPS" "$USER_SECURITY" "$USER_MONITORING"; do
  for namespace in "$DEV_NAMESPACE" "$MONITORING_NAMESPACE"; do
    kubeconfig="${user}-kubeconfig.yaml"
    if [ -f "$kubeconfig" ]; then
        echo -n "$user: "
        if kubectl --kubeconfig="$kubeconfig" auth can-i get secrets -n $namespace 2>/dev/null | grep -q "yes"; then
            echo "✓ get secrets - Доступ есть в ${namespace}"
        else
            echo "✗ get secrets - Доступа нет в ${namespace}"
        fi
    else
        echo "$user: Kubeconfig не найден"
    fi
  done
done

for user in "$USER_DEVOPS" "$USER_SECURITY" "$USER_MONITORING"; do
  for namespace in "$DEV_NAMESPACE" "$MONITORING_NAMESPACE"; do
    kubeconfig="${user}-kubeconfig.yaml"
    if [ -f "$kubeconfig" ]; then
        echo -n "$user: "
        if kubectl --kubeconfig="$kubeconfig" auth can-i delete service -n $namespace 2>/dev/null | grep -q "yes"; then
            echo "✓ delete service - Доступ есть в ${namespace}"
        else
            echo "✗ delete service - Доступа нет в ${namespace}"
        fi
    else
        echo "$user: Kubeconfig не найден"
    fi
  done
done