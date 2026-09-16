# 🏗️ Telegram AI Gateway · ARCHITECTURE

Документ описывает архитектуру проекта Telegram AI Gateway.

## 🌐 1. Context Diagram (C4 Level 1)

```mermaid
flowchart TB
    User[Telegram User<br/>читатель статьи]

    subgraph System[Telegram AI Gateway]
        Gateway[n8n-автоматизация:<br/>статья → суммаризация → готовый пост]
    end

    User -->|URL статьи| BotAPI[Telegram Bot API<br/>api.telegram.org:443]
    BotAPI -->|Webhook / Polling| Gateway
    Gateway -->|Результат / User-friendly сообщение об ошибке| BotAPI
    BotAPI -->|Результат / ошибка| User

    Gateway -->|HTTP Request<br/>OAuth + Chat Completions| GigaChatAPI[GigaChat API]
    Gateway -->|HTTP Request<br/>загрузка статьи| ArticleSources[Article Sources<br/>внешние домены]
```

## 📦 2. Container Diagram (C4 Level 2)

```mermaid
flowchart TB
    subgraph DockerCompose[Docker Compose · Telegram AI Gateway]
        N8N[n8n Workflow Engine<br/>n8nio/n8n:2.29.8]
        PG[PostgreSQL 15<br/>postgres:15-alpine<br/>credentials · execution history · workflow_logs]
        LogWriter[Log Writer Workflow<br/>4 nodes · reusable]
    end

    User[Telegram User] -->|URL статьи| BotAPI[Telegram Bot API<br/>api.telegram.org:443]
    BotAPI -->|Webhook / Polling| N8N
    N8N -->|Send Message / Send Error| User

    N8N -->|Execute Workflow| LogWriter
    LogWriter -->|INSERT| PG

    N8N -->|HTTP Request| GigaChatAPI[GigaChat API<br/>OAuth + Chat Completions]
    N8N -->|HTTP Request| ArticleSources[Article Sources<br/>Various domains]
```

### Внутренняя структура основного workflow

```mermaid
flowchart TB
    subgraph Workflow[Workflow Pipeline]
        Trigger[Telegram Trigger] --> Prepare[Prepare Input]
        Prepare --> CheckURL{Check URL}
        CheckURL -->|invalid| ErrorURL[Send Error<br/>Invalid URL]

        CheckURL -->|valid| Load[Load Page]
        Load -->|error| CheckLoad{Check Load Error}
        CheckLoad -->|error| FormatLoad[Format Load Error]
        FormatLoad --> ErrorLoad[Send Error<br/>Load Failed]

        CheckLoad -->|success| Extract[Extract Article]

        Extract --> Clean[Clean Text]
        Clean --> CheckText{Check Text}
        CheckText -->|empty| ErrorExtract[Send Error<br/>Extract Failed]

        CheckText -->|has text| Prompt[Prepare Prompt]
        Prompt --> RqUID[Generate RqUID]
        RqUID --> Token[Get GigaChat Token]
        Token -->|error| CheckToken{Check Token}
        CheckToken -->|invalid| FormatAuth[Format Auth Error]
        FormatAuth --> ErrorAuth[Send Error<br/>Auth Failed]

        CheckToken -->|valid| GigaChat[GigaChat API]
        GigaChat -->|error| CheckResponse{Check Response}
        CheckResponse -->|invalid| FormatAPI[Format API Error]
        FormatAPI --> ErrorAPI[Send Error<br/>API Unavailable]

        CheckResponse -->|valid| Split[Split Message]
        Split --> Send[Send Message]
    end
```

Retry-политики по нодам — [workflow_overview.md](workflow_overview.md); полный разбор ошибок — раздел «Обработка ошибок» ниже.

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

## 🔄 3. Потоки данных

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

## 🚨 4. Обработка ошибок

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

## 🔐 5. Безопасность

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

## 📈 6. Масштабируемость

### Текущие ограничения

- Один workflow instance
- PostgreSQL single instance
- Нет horizontal scaling

### Возможные улучшения

- Redis для кэширования
- PostgreSQL replicas для чтения
- Queue system для высокой нагрузки
- Multiple n8n instances за load balancer

## 📊 7. Мониторинг

Текущий мониторинг (n8n execution history, Docker logs, structured logging) и рекомендуемый (Prometheus + Grafana, log aggregation, alerting) — [deployment_guide.md](deployment_guide.md), раздел «Мониторинг». Журналирование исполнения — [logging-integration-guide.md](logging-integration-guide.md).

## 💾 8. Резервное копирование

Бэкапятся: PostgreSQL data volume, n8n data volume, `.env` (без секретов в git). Команды и процедура — [deployment_guide.md](deployment_guide.md), раздел «Бэкап и восстановление».

---

**Статус:** Актуальна (as-built)
**Последнее обновление:** 2026-09-16
**История изменений:** [📝 CHANGE_LOG.md](CHANGE_LOG.md#-1-история-изменений-документации)
