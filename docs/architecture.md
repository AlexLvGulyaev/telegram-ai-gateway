# Architecture

Документ описывает архитектуру проекта Telegram AI Gateway.

## Высокоуровневая архитектура

```mermaid
flowchart TB
    User[Telegram User] -->|URL статьи| BotAPI[Telegram Bot API<br/>api.telegram.org:443]
    BotAPI -->|Webhook/Polling| N8N[n8n Workflow<br/>Docker Container]

    subgraph Workflow[Workflow Pipeline]
        Trigger[Telegram Trigger] --> Prepare[Prepare Input]
        Prepare --> CheckURL{Check URL}
        CheckURL -->|valid| Load[Load Page]
        CheckURL -->|invalid| ErrorURL[Send Error<br/>Invalid URL]
        Load -->|error| ErrorLoad[Send Error<br/>Load Failed]
        Load -->|success| Extract[Extract Article]
        Extract -->|error| ErrorExtract[Send Error<br/>Extract Failed]
        Extract -->|success| Clean[Clean Text]
        Clean --> Prompt[Prepare Prompt]
        Prompt --> RqUID[Generate RqUID]
        RqUID --> Token[Get GigaChat Token]
        Token -->|error| ErrorAuth[Send Error<br/>Auth Failed]
        Token -->|success| GigaChat[GigaChat API]
        GigaChat -->|error| ErrorAPI[Send Error<br/>API Failed]
        GigaChat -->|success| Split[Split Message]
        Split --> Send[Send Message]
    end

    N8N --> Workflow

    N8N -->|Execute Workflow| LogWriter[Log Writer Workflow]
    LogWriter -->|INSERT| PG[PostgreSQL 15<br/>workflow_logs]

    N8N -->|HTTP Request| GigaChatAPI[GigaChat API<br/>OAuth + Chat Completions]
    N8N -->|HTTP Request| ArticleSources[Article Sources<br/>Various domains]

    Send -->|Result| User
    ErrorURL -->|Error Message| User
    ErrorLoad -->|Error Message| User
    ErrorExtract -->|Error Message| User
    ErrorAuth -->|Error Message| User
    ErrorAPI -->|Error Message| User
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

#### Архитектура данных

```mermaid
erDiagram
    WORKFLOW_LOGS {
        uuid id PK
        uuid request_id "Корреляционный ID"
        timestamp created_at "Время события"
        varchar workflow_name
        varchar workflow_version
        varchar stage "REQUEST_RECEIVED,PAGE_LOADED,..."
        varchar event_type "telegram_webhook,http_request,..."
        varchar level "INFO,WARNING,ERROR"
        varchar status "SUCCESS,FAILED,IN_PROGRESS"
        bigint chat_id
        bigint user_id
        varchar input_url
        int duration_ms
        text message
        varchar error_code "NETWORK_ERROR,404,SSL_ERROR,..."
        text error_message
        jsonb details "Дополнительные данные"
    }
```

#### Поток записи логов

```mermaid
sequenceDiagram
    participant TG as Telegram AI Gateway
    participant EW as Execute Workflow
    participant LW as Log Writer
    participant PG as PostgreSQL

    TG->>TG: Generate Request ID
    TG->>TG: Generate created_at timestamp
    TG->>EW: Execute Workflow (event data)
    EW->>LW: Call Log Writer workflow
    LW->>LW: Prepare Log Entry
    LW->>PG: INSERT INTO workflow_logs
    PG-->>LW: Confirm insert
    LW-->>EW: Return success
    EW-->>TG: Continue execution
```

**Подробности логирования:** [logging-integration-guide.md](logging-integration-guide.md)

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

```mermaid
flowchart LR
    A[User] -->|URL| B[Telegram Bot API]
    B -->|Webhook| C[n8n Workflow]
    C -->|Load Page| D[Extract Article]
    D -->|Clean Text| E[Prepare Prompt]
    E -->|Generate RqUID| F[Get GigaChat Token]
    F -->|OAuth Token| G[GigaChat API]
    G -->|Generated Post| H[Split Message]
    H -->|Parts| I[Send Message]
    I -->|Result| A
```

### Сценарий с ошибкой

```mermaid
flowchart LR
    A[User] -->|URL| B[Telegram Bot API]
    B -->|Webhook| C[n8n Workflow]
    C -->|Error| D[Error Node]
    D -->|Error Message| E[Send Error Message]
    E -->|User-friendly Error| A
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

```mermaid
flowchart TB
    subgraph URL_Validation[URL Validation]
        CheckURL{Check URL} -->|invalid| InvalidURL[Send Error<br/>Invalid URL]
    end

    subgraph Page_Loading[Page Loading]
        Load[Load Page] -->|error| CheckLoad{Check Load Error}
        CheckLoad -->|has error| FormatLoad[Format Load Error]
        FormatLoad --> SendLoad[Send Error<br/>Load Failed]
    end

    subgraph Text_Extraction[Text Extraction]
        Extract[Extract Article] --> CheckText{Check Text}
        CheckText -->|empty| SendExtract[Send Error<br/>Extract Failed]
    end

    subgraph Auth[Authentication]
        GetToken[Get GigaChat Token] --> CheckToken{Check Token}
        CheckToken -->|invalid| FormatAuth[Format Auth Error]
        FormatAuth --> SendAuth[Send Error<br/>Auth Failed]
    end

    subgraph API[API Call]
        GigaChat[GigaChat API Call] --> CheckResponse{Check Response}
        CheckResponse -->|invalid| FormatAPI[Format API Error]
        FormatAPI --> SendAPI[Send Error<br/>API Unavailable]
    end

    InvalidURL --> User[User]
    SendLoad --> User
    SendExtract --> User
    SendAuth --> User
    SendAPI --> User
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