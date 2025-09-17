#!/bin/bash
set -e

echo "[*] Запуск Minikube..."
minikube start

echo "[*] Подключение gatekeeper"
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.16/deploy/gatekeeper.yaml

echo "[*] Ждём, пока поды Gatekeeper будут готовы..."
kubectl -n gatekeeper-system rollout status deployment gatekeeper-controller-manager

echo "[*] Ждём, пока появится CRD ConstraintTemplate..."
until kubectl get crd constrainttemplates.templates.gatekeeper.sh >/dev/null 2>&1; do
  echo "  ... ждём CRD constrainttemplates ..."
  sleep 2
done

echo "[*] Создание namespace audit-zone..."
kubectl apply -f ../01-create-namespace.yaml

echo "[*] Применяем ConstraintTemplates..."
kubectl apply -f ../gatekeeper/constraint-templates/privileged.yaml
kubectl apply -f ../gatekeeper/constraint-templates/runasnonroot.yaml
kubectl apply -f ../gatekeeper/constraint-templates/readonly.yaml
kubectl apply -f ../gatekeeper/constraint-templates/hostpath.yaml

echo "[*] Ждём, пока Gatekeeper зарегистрирует новые Kind для constraints..."
until kubectl get crd | grep -q k8sprivileged.constraints.gatekeeper.sh; do
  echo "  ... ждём K8sPrivileged ..."
  sleep 2
done
until kubectl get crd | grep -q k8srunasnonroot.constraints.gatekeeper.sh; do
  echo "  ... ждём K8sRunAsNonRoot ..."
  sleep 2
done
until kubectl get crd | grep -q k8sreadonlyfs.constraints.gatekeeper.sh; do
  echo "  ... ждём K8sReadOnlyFS ..."
  sleep 2
done
until kubectl get crd | grep -q k8shostpath.constraints.gatekeeper.sh; do
  echo "  ... ждём K8sHostPath ..."
  sleep 2
done

echo "[*] Применяем Constraints..."
kubectl apply -f ../gatekeeper/constraints/privileged.yaml
kubectl apply -f ../gatekeeper/constraints/runasnonroot.yaml
kubectl apply -f ../gatekeeper/constraints/readonly.yaml
kubectl apply -f ../gatekeeper/constraints/hostpath.yaml

echo "[*] Проверяем, что объекты создались..."
kubectl get constrainttemplates
kubectl get constraints

echo "[*] Пробуем создать Pod с privileged контейнером..."
kubectl apply -f ../secure-manifests/01-secure.yaml

echo "[*] Пробуем создать Pod с hostPath..."
kubectl apply -f ../secure-manifests/02-secure.yaml

echo "[*] Пробуем создать Pod от root (uid 0)..."
kubectl apply -f ../secure-manifests/03-secure.yaml

echo "[*] Проверяем события в namespace audit-zone..."
kubectl get events -n audit-zone --sort-by=.lastTimestamp | tail -n 20