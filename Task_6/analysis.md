# Отчёт по результатам анализа Kubernetes Audit Log

## Подозрительные события

#### 1. Доступ к секретам:
```bash
   ВРЕМЯ: 2025-12-11T21:26:35.858985Z
   ПОЛЬЗОВАТЕЛЬ: system:serviceaccount:secure-ops:monitoring
   ДЕЙСТВИЕ: list
   РЕСУРС: secrets
   NAMESPACE: kube-system
   СТАТУС: 403 (Forbidden)
   СООБЩЕНИЕ: secrets is forbidden: User "system:serviceaccount:secure-ops:monitoring" cannot list resource "secrets" in API group "" in the namespace "kube-system"
   ИСТОЧНИК: 127.0.0.1
   USER AGENT: kubectl/v1.34.1 (linux/amd64) kubernetes/93248f9
   ЗАПРОС: /api/v1/namespaces/kube-system/secrets?limit=500
```
Проверяем доступ к секретам системного неймспейса.

Скрипт ```./simulate-incident.sh``` выдает ошибку:

```Error from server (Forbidden): secrets is forbidden: User "system:serviceaccount:secure-ops:monitoring" cannot list resource "secrets" in API group "" in the namespace "kube-system"```

Доступ запрещен, потому что по-умолчанию RBAC предполагает _принцип наименьших привилегий_: новому сервис-аккаунту необходимо явно выдавать разрешения на ресурсы.

#### 2. Привилегированные поды:
```bash
   ВРЕМЯ: 2025-12-11T21:26:02.658249Z
   ПОЛЬЗОВАТЕЛЬ: system:node:ct
   ДЕЙСТВИЕ: get
   РЕСУРС: pods
   NAMESPACE: secure-ops
   ИМЯ ПОДА: privileged-pod
   СТАТУС: 200
   СООБЩЕНИЕ:
   ИСТОЧНИК: 127.0.0.1
   USER AGENT: k3s/v1.33.6+k3s1 (linux/amd64) kubernetes/b584767
   ЗАПРОС: /api/v1/namespaces/secure-ops/pods/privileged-pod
```

Проверяем события создания привилегированного пода.

Скрипт ```./simulate-incident.sh``` успешно создает под:

```pod/privileged-pod created```

Такой под имеет доступ root на хост, что является критической уязвимостью.
Необходимо рассмотреть способы запрета создания привилегированных подов.

#### 3. Использование kubectl exec в чужом поде:

```bash
   ВРЕМЯ: 2025-12-11T21:26:36.150546Z
   ПОЛЬЗОВАТЕЛЬ: system:admin
   Pod: coredns-6d668d687-vgf47
   ЗАПРОС: /api/v1/namespaces/kube-system/pods/coredns-6d668d687-vgf47/exec?command=cat&command=/etc/resolv.conf&container=coredns&stderr=true&stdout=true
   СТАТУС: 0
   СООБЩЕНИЕ: нет сообщения
   USER AGENT: kubectl/v1.34.1 (linux/amd64) kubernetes/93248f9
```

Отслеживаем попытки выполнения утилит на системном поде.

Скрипт ```./simulate-incident.sh``` выдает ошибку
```bash
error: Internal error occurred: Internal error occurred: error executing command in container: failed to exec in container: failed to start exec "6e5689a3050d77d5f3fbe4840d698bfd3d167adad478aa77641108ca775580d0": OCI runtime exec failed: exec failed: unable to start container process: exec: "cat": executable file not found in $PATH
```

Системные *контейнеры минималистичны*, и это хорошо: чем меньше утилит - тем меньше векторов опасности.

#### 4. Создание RoleBinding с правами cluster-admin:
  
Скрипт ```./simulate-incident.sh``` выдает роль с широкими привилегиями cluster-admin сервис-аккаунту monitoring.

```rolebinding.rbac.authorization.k8s.io/escalate-binding created```

В логах аудита ничего не вижу по этому событию.
Возможно, стоит усилить политики безопасности.

#### 5. Удаление audit-policy.yaml:

Скрипт ```./simulate-incident.sh``` выдает ошибку при попытке удаления политики безопасности Kubernetes.
```bash
error: the path "/var/lib/rancher/k3s/server/audit.yaml" cannot be accessed: stat /var/lib/rancher/k3s/server/audit.yaml: permission denied
```