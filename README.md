
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



# 🚀 Sprint 2: CI/CD и деплой в Kubernetes

## 📌 Описание

На этом этапе реализуется полный цикл доставки приложения:

1. Сборка Docker-образа на сервере `srv`
2. Публикация образа в Docker Registry
3. Описание приложения через Helm
4. Автоматический деплой в Kubernetes
    

---

## 🧩 Архитектура пайплайна

```id="pipeline"
Git → CI/CD (GitLab) → Docker Registry → Helm → Kubernetes
```

---

## 📦 1. Сборка приложения и настройка CI/CD

### 🔹 Клонирование приложения

```bash
git clone <your_repo_with_app>
cd <repo>
```

---

### 🔹 Настройка CI/CD (GitLab)

Создаём файл `.gitlab-ci.yml`:

```yaml
stages:
  - build
  - deploy

variables:
  IMAGE_NAME: registry.example.com/myapp

build:
  stage: build
  script:
    - docker build -t $IMAGE_NAME:$CI_COMMIT_TAG .
    - docker push $IMAGE_NAME:$CI_COMMIT_TAG
  only:
    - tags

deploy:
  stage: deploy
  script:
    - helm upgrade --install myapp ./helm \
        --set image.tag=$CI_COMMIT_TAG
  only:
    - tags
```

---

### 🔐 Настройка Docker Registry

Можно использовать:

- Docker Hub
- GitLab Container Registry

Необходимо:

```bash
docker login
```

И добавить переменные в CI:

- `CI_REGISTRY_USER`
- `CI_REGISTRY_PASSWORD`

---

### 🏷️ Сборка по тегам

Пайплайн запускается при создании тега:

```bash
git tag 1.0.0
git push origin 1.0.0
```

➡️ В результате создается образ:

```
registry.example.com/myapp:1.0.0
```

---

## ⚓ 2. Helm-чарт приложения

Структура:

```id="helm"
helm/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── postgres.yaml
│   └── pvc.yaml
```

---

### 🔹 Основные компоненты

#### 1. Deployment (приложение)

- Django контейнер
- Использует образ из registry
- Получает переменные окружения

#### 2. PostgreSQL

- Отдельный pod
- Использует PVC

#### 3. PVC (Persistent Volume Claim)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

---

### 🔹 values.yaml

```yaml
image:
  repository: registry.example.com/myapp
  tag: latest

postgres:
  db: mydb
  user: user
  password: password
```

❗ Пароли лучше передавать через Kubernetes Secrets

---

## 🚀 3. Деплой в Kubernetes

### 🔹 Подключение к кластеру

На сервере `srv`:

```bash
export KUBECONFIG=~/.kube/config
```

---

### 🔹 Установка Helm-чарта

```bash
helm upgrade --install myapp ./helm
```

---

### 🔹 Проверка

```bash
kubectl get pods
kubectl get svc
```

---

## 🌍 Доступ к приложению

Возможные варианты:

### 🔹 NodePort

```yaml
type: NodePort
```

Доступ:

```
http://<NODE_IP>:<PORT>
```

---

### 🔹 Через внешний IP (рекомендуется)

Можно использовать:

- Ingress Controller
- Или прямой доступ через NodePort

---

## 🔄 Автоматический деплой

Теперь полный цикл выглядит так:

1. Создаём тег:
    
    ```bash
    git tag 2.0.3
    git push origin 2.0.3
    ```
    
2. CI/CD:
    - собирает образ
    - пушит в registry
    - деплоит через Helm


---

## ✅ Результат

После выполнения:

- Настроен CI/CD пайплайн
- Образы автоматически собираются
- Приложение автоматически деплоится в Kubernetes
- Используется Helm для управления релизами
- Данные PostgreSQL сохраняются через PVC
    

---



---

# 📊 Sprint 3: Мониторинг, логирование и алертинг

## 📌 Описание

На данном этапе реализована система наблюдаемости (Observability) для приложения:

- 📥 Сбор логов из Kubernetes
- 📈 Мониторинг состояния приложения и серверов
- 📊 Визуализация метрик
- 🚨 Алертинг в мессенджер

❗ ВАЖНО: Все компоненты мониторинга размещены на сервере `srv`, чтобы система оставалась доступной даже при падении Kubernetes-кластера.

---

## 🧱 Архитектура

```id="obs"
Kubernetes → Logs → Loki → Grafana
           → Metrics → Prometheus → Grafana → Alerts → Telegram
srv → Node Exporter → Prometheus
```

---

## 📥 1. Сбор логов

### 🔧 Выбранный стек

- **Loki** — хранение логов
- **Promtail** — сбор логов из Kubernetes
- **Grafana** — просмотр логов

---

### 🔹 Установка Loki (на srv)

```bash
docker run -d \
  --name loki \
  -p 3100:3100 \
  grafana/loki
```

---

### 🔹 Установка Promtail (в Kubernetes)

Promtail собирает логи подов и отправляет их в Loki.

Пример конфигурации:

```yaml
server:
  http_listen_port: 9080

clients:
  - url: http://<SRV_IP>:3100/loki/api/v1/push

positions:
  filename: /tmp/positions.yaml

scrape_configs:
  - job_name: kubernetes-pods
    static_configs:
      - targets:
          - localhost
        labels:
          job: pod-logs
          __path__: /var/log/pods/*/*/*.log
```

---

### 🔹 Результат

Теперь можно:

- Смотреть логи всех pod'ов
- Фильтровать по namespace / pod / уровню логов

---

## 📈 2. Мониторинг

### 🔧 Выбранный стек

- **Prometheus** — сбор метрик
- **Node Exporter** — метрики сервера `srv`
- **Blackbox Exporter** — проверка доступности приложения
- **Grafana** — визуализация

---

### 🔹 Метрики приложения

Мы отслеживаем:

- ⏱ Время отклика (response time)
- 🌐 Доступность (HTTP status code)
- 🔒 SSL сертификат
- ❌ Ошибки (5xx)

---

### 🔹 Blackbox Exporter

Проверяет доступность приложения:

```yaml
modules:
  http_2xx:
    prober: http
    timeout: 5s
```

---

### 🔹 Prometheus config

```yaml
scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']

  - job_name: 'blackbox'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
          - http://<APP_IP>:<PORT>
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - target_label: __address__
        replacement: localhost:9115
```

---

### 🔹 Мониторинг srv сервера

Контролируем:

- 💾 Использование диска
- 🧠 RAM
- ⚙️ CPU

---

## 📊 3. Дашборды (Grafana)

### 🔧 Установка Grafana

```bash
docker run -d \
  -p 3000:3000 \
  grafana/grafana
```

---

### 🔹 Подключение источников

В Grafana добавляем:

- Prometheus → `http://localhost:9090`
- Loki → `http://localhost:3100`

---

### 🔹 Дашборды

Создаем или импортируем:

- 📊 Kubernetes Pods
- 📈 HTTP availability
- 💾 Disk usage (srv)
- 📥 Logs (Loki)

---

## 🚨 4. Алертинг

### 🔧 Инструменты

- Prometheus Alertmanager
- Telegram Bot

---

### 🔹 Пример алерта

```yaml
groups:
- name: app-alerts
  rules:
  - alert: AppDown
    expr: probe_success == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      description: "Application is down"
```

---

### 🔹 Alertmanager (Telegram)

```yaml
receivers:
- name: telegram
  telegram_configs:
  - bot_token: <TOKEN>
    chat_id: <CHAT_ID>
```

---

### 🔹 Проверка алертов

1. Остановить приложение:

```bash
kubectl delete pod <app-pod>
```

2. Засечь время до уведомления

✅ Нормально: 30–90 секунд

---

## ✅ Результат

После выполнения:

- Логи собираются централизованно (Loki)
- Метрики доступны через Prometheus
- Grafana отображает дашборды
- Настроен алертинг в Telegram
- Мониторинг работает независимо от Kubernetes

---

## 📊 Что мы контролируем

|Категория|Метрика|
|---|---|
|Доступность|HTTP 200|
|Ошибки|5xx|
|Производительность|Response time|
|Инфраструктура|CPU / RAM / Disk|
|Логи|Ошибки приложения|

## 🏁 Итог проекта

В рамках всех спринтов:

✅ Развернута инфраструктура (Terraform)  
✅ Настроена конфигурация серверов (Ansible)  
✅ Реализован CI/CD pipeline  
✅ Приложение деплоится в Kubernetes  
✅ Настроены мониторинг, логирование и алертинг


