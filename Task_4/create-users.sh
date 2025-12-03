#!/bin/bash

source ./.env

echo "=== Создание пользователей ==="
echo ""

create_user() {
    local USERNAME=$1
    local GROUP=$2
    local DESCRIPTION=$3

    echo "Создаем пользователя: $USERNAME ($DESCRIPTION)"
    echo "  Группа: $GROUP"

    mkdir -p "users/$USERNAME"
    cd "users/$USERNAME"

    openssl genrsa -out "${USERNAME}.key" 2048 2>/dev/null

    openssl req -new -key "${USERNAME}.key" \
        -out "${USERNAME}.csr" \
        -subj "/CN=${USERNAME}/O=${GROUP}" 2>/dev/null

    local CSR_BASE64=$(cat "${USERNAME}.csr" | base64 | tr -d '\n')

    cat <<EOF | kubectl apply -f - > /dev/null
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${USERNAME}-csr
spec:
  request: ${CSR_BASE64}
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 8640000
  usages: ["client auth"]
  groups: ["${GROUP}"]
EOF

    kubectl certificate approve "${USERNAME}-csr" > /dev/null

    sleep 2
    kubectl get csr "${USERNAME}-csr" -o jsonpath='{.status.certificate}' | base64 -d > "${USERNAME}.crt"

    local CA_DATA=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
    local SERVER=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.server}')

    local CLIENT_CERT_DATA=$(cat "${USERNAME}.crt" | base64 -w0)
    local CLIENT_KEY_DATA=$(cat "${USERNAME}.key" | base64 -w0)

    cat <<EOF > "${USERNAME}-kubeconfig.yaml"
apiVersion: v1
kind: Config
clusters:
- name: ${CLUSTER_NAME}
  cluster:
    certificate-authority-data: ${CA_DATA}
    server: ${SERVER}
contexts:
- name: ${USERNAME}-context
  context:
    cluster: ${CLUSTER_NAME}
    user: ${USERNAME}
current-context: ${USERNAME}-context
users:
- name: ${USERNAME}
  user:
    client-certificate-data: ${CLIENT_CERT_DATA}
    client-key-data: ${CLIENT_KEY_DATA}
EOF

    cd ../..

    cp "users/$USERNAME/${USERNAME}-kubeconfig.yaml" .

    echo "  ✓ Пользователь $USERNAME создан"
    echo "  Kubeconfig: ${USERNAME}-kubeconfig.yaml"
    echo ""
}

create_user "$USER_DEVOPS" "$GROUP_DEVOPS" "DevOps Engineer"
create_user "$USER_SECURITY" "$GROUP_SECURITY" "Security Auditor"
create_user "$USER_MONITORING" "$GROUP_MONITORING" "Home-1 manager"

echo "Все пользователи созданы!"
echo "Список kubeconfig файлов:"
ls -la *.yaml
echo ""