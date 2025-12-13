#!/bin/bash
log_file=${1:-"./audit.log"}

echo "=====Анализ доступа к secrets в kube-system====="
echo "Пользователи из system:serviceaccounts:secure-ops"
echo "----------------------------------------"
echo ""

jq -r --arg group "system:serviceaccounts:secure-ops" '
def get_timestamp(event):
  event.timestamp // event.requestReceivedTimestamp // event.stageTimestamp // "";

[
  select(
    ((.objectRef.resource // "") == "secrets") and
    ((.objectRef.namespace // "") == "kube-system") and
    (
      ((.user.username // "") | startswith("system:serviceaccount:secure-ops:")) or
      ((.impersonatedUser.username // "") | startswith("system:serviceaccount:secure-ops:")) or
      ((.user.groups // []) | index($group) != null) or
      ((.impersonatedUser.groups // []) | index($group) != null)
    )
  )
] | .[] |
"---",
"ВРЕМЯ: " + get_timestamp(.),
"ПОЛЬЗОВАТЕЛЬ: " + (.impersonatedUser.username // .user.username // ""),
"ДЕЙСТВИЕ: " + (.verb // ""),
"РЕСУРС: " + (.objectRef.resource // ""),
"NAMESPACE: " + (.objectRef.namespace // ""),
"СТАТУС: " + (if .responseStatus.code then "\(.responseStatus.code)" else "" end) +
          (if .responseStatus.reason then " (\(.responseStatus.reason))" else "" end),
"СООБЩЕНИЕ: " + (.responseStatus.message // ""),
"ИСТОЧНИК: " + ((.sourceIPs // [])[0] // ""),
"USER AGENT: " + (.userAgent // ""),
"ЗАПРОС: " + (.requestURI // ""),
""' "$log_file"


echo ""
echo "=====Попытки создания pods с privileged=true====="
echo "----------------------------------------"
echo ""

jq -r '
def get_timestamp(event):
  event.timestamp // event.requestReceivedTimestamp // event.stageTimestamp // "";

# Ищем ВСЕ события для privileged-pod
[
  select(
    # Ищем по имени pod
    ((.objectRef.name // "") == "privileged-pod") or
    # Или по имени в request/response объектах
    ((.requestObject?.metadata?.name // "") == "privileged-pod") or
    ((.responseObject?.metadata?.name // "") == "privileged-pod")
  )
] | .[] |
"---",
"ВРЕМЯ: " + get_timestamp(.),
"ПОЛЬЗОВАТЕЛЬ: " + (.impersonatedUser.username // .user.username // ""),
"ДЕЙСТВИЕ: " + (.verb // ""),
"РЕСУРС: " + (.objectRef.resource // ""),
"NAMESPACE: " + (.objectRef.namespace // ""),
"ИМЯ ПОДА: " + (.objectRef.name // ""),
"СТАТУС: " + (if .responseStatus.code then "\(.responseStatus.code)" else "" end) +
          (if .responseStatus.reason then " (\(.responseStatus.reason))" else "" end),
"СООБЩЕНИЕ: " + (.responseStatus.message // ""),
"ИСТОЧНИК: " + ((.sourceIPs // [])[0] // ""),
"USER AGENT: " + (.userAgent // ""),
"ЗАПРОС: " + (.requestURI // ""),
(if .objectRef.subresource then "SUB RESOURCE: " + .objectRef.subresource else "" end),
""' "$log_file"


echo ""
echo "=====Попытка exec на системном поде====="
echo "----------------------------------------"
echo ""

jq -r '
def get_timestamp(event):
  event.timestamp // event.requestReceivedTimestamp // event.stageTimestamp // "";

[
  select(
    ((.objectRef.resource // "") == "pods") and
    ((.objectRef.subresource // "") == "exec") and
    ((.objectRef.namespace // "") == "kube-system")
  )
] | .[] |
"---",
"  ВРЕМЯ: " + get_timestamp(.),
"  ПОЛЬЗОВАТЕЛЬ: " + (.impersonatedUser.username // .user.username // ""),
"  Pod: " + (.objectRef.name // ""),
"  ЗАПРОС: " + (.requestURI // "" | gsub("%2F"; "/")),
"  СТАТУС: " + (.responseStatus.code // 0|tostring),
"  СООБЩЕНИЕ: " + (.responseStatus.message // "нет сообщения"),
"  USER AGENT: " + (.userAgent // ""),
""' "$log_file"



