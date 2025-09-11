#!/bin/bash

set -e

# Все сервисы
services=("front-end" "back-end-api" "admin-front-end" "admin-back-end-api")

echo "Проверка сетевого доступа между сервисами:"
echo

for src in "${services[@]}"; do
  for dst in "${services[@]}"; do
    if [ "$src" == "$dst" ]; then
      continue
    fi
    echo -n "Из $src → $dst: "
    # Узнаем имя DNS-адреса
    srcPod=$(kubectl get pods -l role=$src -o name |  sed "s/^.\{4\}//")
    dstHost=$(kubectl get pod -l role=$dst -o jsonpath='{.items[0].status.podIP}')
    # curl с таймаутом
    if kubectl exec $srcPod -- curl -s --connect-timeout 3 http://$dstHost:80 >/dev/null; then
      echo "ДОСТУПЕН"
    else
      echo "ЗАБЛОКИРОВАН"
    fi
  done
done
