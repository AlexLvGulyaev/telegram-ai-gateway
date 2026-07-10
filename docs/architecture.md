# Architecture

Документ описывает архитектуру проекта Telegram AI Gateway.

## Высокоуровневая архитектура

```
┌─────────────────────────────────────────────────────────────────┐
│                         Telegram User                           │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ URL статьи
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Telegram Bot API                            │
│                    (api.telegram.org:443)                        │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ Webhook/Polling
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    n8n Workflow (Docker)                          │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    Workflow Pipeline                        │  │
│  │                                                            │  │
│  │  [Telegram Trigger]                                        │  │
│  │         │                                                  │  │
│  │         ▼                                                  │  │
│  │  [Prepare Input]                                          │  │
│  │         │                                                  │  │
│  │         ▼                                                  │  │
│  │  [Check URL] ──────[false]──→ [Send Error]                │  │
│  │         │                                                  │  │
│  │        [true]                                              │  │
│  │         │                                                  │  │
│  │         ▼                                                  │  │
│  │  [Load Page] ────[error]──→ [Send Error]                  │  │
│  │         │                                                  │  │
│  │         ▼                                                  │  │
│  │  [Extract Article] ──[error]──→ [Send Error]              │  │
│  │         │                                                  │  │
│  │         ▼                                                  │  │
│  │  [Clean Text] ─────[error]──→ [Send Error]                │  │
│  │         │                                                  │  │
│  │         ▼                                                  │  │
│  │  [Prepare Prompt]                                          │  │
│  │         │                                                  │  │
│  │         ▼                                                  │  │
│  │  [Generate RqUID]                                          │  │
│  │         │                                                  │  │
│  │         ▼                                                  │  │
│  │  [Get GigaChat Token] ─[error]──→ [Send Error]            │  │
│  │         │                                                  │  │
│  │         ▼                                                  │  │
│  │  [GigaChat] ──────[error]──→ [Send Error]                  │  │
│  │         │                                                  │  │
│  │         ▼                                                  │  │
│  │  [Split Message]                                          │  │
│  │         │                                                  │  │
│  │         ▼                                                  │  │
│  │  [Send Message]                                           │  │
│  │                                                            │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Data: PostgreSQL 15                                            │
│  Logs: PostgreSQL (workflow_logs table) via Log Writer         │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ HTTP Requests
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      External APIs                               │
│                                                                  │
│  ┌─────────────────────┐   ┌─────────────────────────────┐      │
│  │   GigaChat API      │   │   Article Sources          │      │
│  │   (OAuth + Chat)    │   │   (various domains)         │      │
│  └─────────────────────┘   └─────────────────────────────┘      │
└─────────────────────────────────────────────────────────────────┘
```

## Компоненты системы

### Docker Services

| Сервис | Образ | Назначение |
|--------|-------|-----------|
| n8n | n8nio/n8n:2.29.8 | Workflow engine |
| postgres | postgres:15-alpine | База данных n8n |

### n8n Workflows

**Основной workflow:** Telegram AI Gateway

**Тип:** Event-driven workflow с линейной обработкой

**Триггер:** Telegram Trigger (On Message)

**Ноды:** 39 nodes (28 основных + 11 Execute Workflow для логирования)

**Log Writer workflow:** Telegram AI Gateway - Log Writer

**Тип:** Reusable workflow для логирования

**Ноды:** 4 nodes

### База данных

**PostgreSQL 15:**
- Хранит credentials n8n
- Хранит execution history
- Хранит workflow definitions
- Хранит таблицу workflow_logs для журналирования

### Внешние интеграции

**Telegram Bot API:**
- Endpoint: `api.telegram.org`
- Методы: `getMe`, `sendMessage`
- Аутентификация: Bot Token

**GigaChat API:**
- OAuth endpoint: `ngw.devices.sberbank.ru:9443/api/v2/oauth`
- Chat endpoint: `gigachat.devices.sberbank.ru/api/v1/chat/completions`
- Аутентификация: Basic Auth → Bearer Token

## Потоки данных

### Успешный сценарий

```
User → Telegram Bot API → n8n → Load Page → Extract Article → Clean Text
     → Prepare Prompt → GigaChat API → Split Message → Send Message → User
```

### Сценарий с ошибкой

```
User → Telegram Bot API → n8n → Error Node → Send Error Message → User
```

## Обработка ошибок

### Уровни обработки

**1. Node Level:**
- Continue on Fail для HTTP Request нод
- Error output для критических нод

**2. Workflow Level:**
- Error flow для отправки сообщений об ошибках
- User-friendly error messages

**3. Retry Level:**
- Retry для Load Page (3 попытки)
- Retry для Get GigaChat Token (2 попытки)
- Retry для GigaChat (2 попытки)

### Error Flow Diagram

```
[Check URL false]     → [Send Error: Invalid URL]
[Load Page error]     → [Send Error: Load Failed]
[Extract error]        → [Send Error: Extract Failed]
[GigaChat Auth error] → [Send Error: Auth Failed]
[GigaChat API error]   → [Send Error: API Unavailable]
```

## Безопасность

### Секреты

**Хранение:**
- Все секреты в `.env` файле
- `.env` добавлен в `.gitignore`
- n8n credentials в зашифрованном виде в PostgreSQL

**Переменные окружения:**
- `TELEGRAM_BOT_TOKEN` — токен Telegram-бота
- `GIGACHAT_AUTH_BASIC` — Base64-encoded GigaChat credentials
- `N8N_BASIC_AUTH_PASSWORD` — пароль для n8n admin

### Сетевая безопасность

**Требования:**
- HTTPS для webhook (опционально)
- HTTPS для внешних API
- Изоляция в Docker network

**Рекомендации:**
- IP whitelisting для n8n admin interface
- Reverse proxy (Nginx/Caddy) для HTTPS
- Firewall rules для ограничения доступа

## Масштабируемость

### Текущие ограничения

- Один workflow instance
- PostgreSQL single instance
- Нет horizontal scaling

### Возможные улучшения

- Redis для кэширования
- PostgreSQL replicas для чтения
- Queue system для высокой нагрузки
- Multiple n8n instances за load balancer

## Мониторинг

### Текущий мониторинг

- n8n execution history
- Docker logs
- PostgreSQL logs

### Рекомендуемый мониторинг

- Prometheus + Grafana
- Log aggregation (ELK/Loki)
- Alerting на ошибки
- Health checks

## Резервное копирование

### Что бэкапить

- PostgreSQL data volume
- n8n data volume
- `.env` файл (без секретов в git)

### Стратегия бэкапа

```bash
# Бэкап PostgreSQL
docker exec postgres pg_dump -U n8n n8n > backup_$(date +%Y%m%d).sql

# Бэкап n8n data
docker run --rm -v n8n_data:/data -v $(pwd):/backup alpine tar czf /backup/n8n_backup.tar.gz -C /data .
```