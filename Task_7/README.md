# Test Pod Security Admission

```bash
kubectl apply -f ./01-create-namespace-audit-zone.yaml
```

### Unsuccessful pods
```bash
kubectl apply -f ./insecure-manifests/01-privileged-pod.yaml
kubectl apply -f ./insecure-manifests/02-hostpath-pod.yaml 
kubectl apply -f ./insecure-manifests/03-root-user-pod.yaml
```

Вы должны увидеть ошибки вида:

```Error from server (Forbidden): error when creating "./insecure-manifests/01-privileged-pod.yaml": pods "privileged-pod" is forbidden```

```bash
kubectl get pods -n audit-zone
```

Небезопасные поды не созданы:

```No resources found in audit-zone namespace.```

### Happy pod
```bash
kubectl apply -f ./secure-manifests/secure-pod.yaml
```

```bash
kubectl get pods -n audit-zone
```

Вы должны увидеть ```secure-pod``` в статусе ```Running```

# Install Gatekeeper
```bash
helm repo add gatekeeper https://open-policy-agent.github.io/gatekeeper/charts
helm repo update

helm install gatekeeper gatekeeper/gatekeeper \
  --namespace gatekeeper-system \
  --create-namespace \
  --version 3.12.0  

kubectl get pods -n gatekeeper-system
```

# Test Gatekeeper constraints

```bash
kubectl apply -f ./02-create-namespace-gatekeeper-zone.yaml
```

### Unsuccessful pods
```bash
kubectl apply -f ./insecure-manifests/gatekeeper/01-privileged-pod.yaml
kubectl apply -f ./insecure-manifests/gatekeeper/02-hostpath-pod.yaml 
kubectl apply -f ./insecure-manifests/gatekeeper/03-root-user-pod.yaml
```

Вы должны увидеть ошибки вида:

```Error from server (Forbidden): error when creating "./insecure-manifests/gatekeeper/01-privileged-pod.yaml": admission webhook "validation.gatekeeper.sh" denied the request```

```bash
kubectl get pods -n gatekeeper-zone
```

Небезопасные поды не созданы:

```No resources found in gatekeeper-zone namespace.```

### Happy pod
```bash
kubectl apply -f ./secure-manifests/gatekeeper/secure-pod.yaml
```

```bash
kubectl get pods -n gatekeeper-zone
```

Вы должны увидеть ```secure-pod``` в статусе ```Running```