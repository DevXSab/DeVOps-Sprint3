
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
