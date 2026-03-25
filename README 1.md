
# 🚀 DevOps Infrastructure (Kubernetes + SRV)

## 📌 Описание проекта

В данном репозитории описана инфраструктура для будущего проекта с использованием подхода **Infrastructure as Code (IaC)**.

Инфраструктура разворачивается в облаке с помощью **Terraform**, а настройка серверов автоматизируется через **Ansible**.

## 🧱 Архитектура

Разворачиваются 3 сервера:

|Сервер|Назначение|
|---|---|
|`k8s-master (prod1)`|Master-нода Kubernetes|
|`k8s-app (prod2)`|Worker-нода Kubernetes|
|`k8s-srv (prod3)`|Сервер для CI/CD, мониторинга и логирования|

### 🌐 Сеть

- Одна VPC сеть: `k8s-network`
- Подсеть: `10.0.0.0/24`
- Все серверы находятся в одной сети
- Доступ:
    - SSH (22 порт) — извне
    - Внутренний трафик — полностью разрешён

---

## ⚙️ Используемые технологии

- Terraform — разворачивание инфраструктуры
- Ansible — конфигурация серверов
- Docker / Docker Compose
- Kubernetes (устанавливается позже)
- GitLab Runner (устанавливается позже)

---

## 📂 Структура репозитория

```
.
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── ansible/
│   ├── inventory.ini
│   ├── playbook.yml
│   └── roles/
│
└── README.md
```

---

## 🔐 Требования

Перед началом убедитесь, что у вас установлены:

- Terraform
- Ansible
- SSH ключ (публичный и приватный)
- Аккаунт в Yandex Cloud

---

## ☁️ Развертывание инфраструктуры (Terraform)

### 1. Клонирование репозитория

```bash
git clone <repo_url>
cd terraform
```

### 2. Создание файла переменных

Создайте файл `terraform.tfvars`:

```hcl
ssh_public_key = "ssh-rsa AAAA..."
```

❗ ВАЖНО: не храните приватные ключи и секреты в репозитории.

---

### 3. Инициализация Terraform

```bash
terraform init
```

---

### 4. Проверка плана

```bash
terraform plan
```

---

### 5. Применение конфигурации

```bash
terraform apply
```

После выполнения вы получите:

- External IP адреса серверов
- Internal IP адреса серверов

---

## 🔧 Настройка серверов (Ansible)

После создания серверов необходимо выполнить их настройку.
### 1. Обновите inventory

Файл `ansible/inventory.ini`:

```ini
[master]
<MASTER_IP>

[app]
<APP_IP>

[srv]
<SRV_IP>

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=/root/.ssh/<KEYSSH>
ansible_python_interpreter=/usr/bin/python3
ansible_port=22
ansible_become=true
ansible_become_method=sudo


```

---

### 2. Проверка подключения

```bash
#сначала проверить что Вас пускает на сервер
ssh -i /root/.ssh/<KEYSSH> ubuntu@IP -p 22
#После проверить Ansible
ansible all -i inventory.ini -m ping
```

---

### 3. Запуск playbook

```bash
ansible-playbook -i inventory.ini playbook.yml
```

---

## ⚙️ Что устанавливает Ansible

На серверах автоматически устанавливаются:

- Docker
- Docker Compose
- Git
- Kubernetes зависимости (containerd, kubeadm и др.)
- GitLab Runner (на srv)
- SSH доступ

---

## 🛠️ Ручные действия

Некоторые шаги выполняются вручную:
### 1. Инициализация Kubernetes (на master)

```bash
kubeadm init
```

Скопируйте команду `kubeadm join` для worker-ноды.

---
### 2. Подключение worker-ноды

На `k8s-app`:

```bash
kubeadm join <master_ip> ...
```

---

### 3. Настройка kubectl (на master)

```bash
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
```

---

## 📊 Дальнейшие шаги

В следующих этапах планируется:

- Настройка CI/CD
- Автоматический деплой в Kubernetes
- Мониторинг (Prometheus + Grafana)
- Логирование (ELK/EFK)

---

## ✅ Результат

После выполнения всех шагов:

- Развернута инфраструктура в облаке
- Поднят Kubernetes кластер (1 master + 1 worker)
- Настроен отдельный сервер для DevOps-инструментов
- Автоматизирована базовая конфигурация серверов

---

## 💡 Примечания

- Инфраструктура масштабируема
- Все настройки описаны в коде
- Секреты не хранятся в репозитории

---
