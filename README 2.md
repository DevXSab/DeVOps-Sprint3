
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
