import json

# категории, которые мы ищем
CATEGORIES = {
    "secrets_access": "Доступ к секретам от serviceaccount secure-ops:monitoring",
    "privileged_pod": "Создание privileged пода",
    "kubectl_exec": "Исполнение команды в чужом поде через kubectl exec",
    "audit_policy_delete": "Удаление файла audit-policy.yaml",
    "rolebinding_no_approval": "Создание RoleBinding без согласования",
}

def is_secrets_access(event):
    try:
        user = event.get("user", {}).get("username", "")
        impersonated_user = event.get("impersonatedUser", {}).get("username", "")
        verb = event.get("verb", "")
        obj_ref = event.get("objectRef", {})
        return (
            (user == "system:serviceaccount:secure-ops:monitoring" or impersonated_user == "system:serviceaccount:secure-ops:monitoring")
                and obj_ref.get("resource") == "secrets"
                and verb in ("get", "list", "watch")
        )
    except:
        return False

def is_privileged_pod(event):
    try:
        obj_ref = event.get("objectRef", {})
        verb = event.get("verb", "")
        if obj_ref.get("resource") == "pods" and verb == "create":
            # проверяем, что в объекте есть privileged=true
            req_obj = event.get("requestObject", {})
            containers = req_obj.get("spec", {}).get("containers", [])
            for c in containers:
                sc = c.get("securityContext", {})
                cap = sc.get("privileged", False)
                if cap is True:
                    return True
        return False
    except:
        return False

def is_kubectl_exec(event):
    try:
        obj_ref = event.get("objectRef", {})
        verb = event.get("verb", "")
        subresource = obj_ref.get("subresource", "")
        return (
                obj_ref.get("resource") == "pods"
                and subresource == "exec"
                and verb in ("create", "get", "list", "watch")
        )
    except:
        return False

def is_audit_policy_delete(event):
    try:
        obj_ref = event.get("objectRef", {})
        verb = event.get("verb", "")
        return (
                obj_ref.get("resource") == "files"
                and obj_ref.get("name") == "audit-policy.yaml"
                and verb == "delete"
        )
    except:
        return False

def is_rolebinding_no_approval(event):
    try:
        obj_ref = event.get("objectRef", {})
        verb = event.get("verb", "")
        return obj_ref.get("resource") == "rolebindings" and verb == "create"
        # в реальности "без согласования" не проверишь по логу,
        # но я оставила здесь простую проверку на создание
    except:
        return False

CHECKS = {
    "secrets_access": is_secrets_access,
    "privileged_pod": is_privileged_pod,
    "kubectl_exec": is_kubectl_exec,
    "audit_policy_delete": is_audit_policy_delete,
    "rolebinding_no_approval": is_rolebinding_no_approval,
}

def main():
    suspicious = {k: [] for k in CATEGORIES}
    with open("audit.log", "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue
            for key, check in CHECKS.items():
                if check(event):
                    suspicious[key].append(event)

    # вывод статистики
    for key, desc in CATEGORIES.items():
        print(f"{desc}: {len(suspicious[key])}")

    # сохранить в файл
    with open("audit-extract.json", "w") as out:
        json.dump(suspicious, out, indent=2)

if __name__ == "__main__":
    main()
