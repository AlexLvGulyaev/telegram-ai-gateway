# IMPLEMENTATION PLAN: Telegram AI Gateway

**Версия:** 1.0
**Дата:** 2026-07-10
**Статус:** Implemented

---

## Цель документа

IMPLEMENTATION_PLAN определяет, как именно будет реализован проект. Если SPEC отвечает на вопрос "что должно быть реализовано", то IMPLEMENTATION_PLAN отвечает на вопрос "как именно это будет реализовано".

Документ содержит конкретные технические решения, структуру проекта, конфигурации и последовательность реализации.

---

## Целевая структура каталогов проекта

```
telegram-ai-gateway/
├── README.md                      # Описание проекта
├── LICENSE                        # Лицензия (MIT)
├── .gitignore                     # Исключения для Git
├── .env.example                   # Пример конфигурации
├── docker-compose.yml             # Docker Compose конфигурация
├── docker-compose.test.yml        # Docker Compose для тестирования
│
├── workflows/
│   ├── Telegram AI Gateway.json            # Основной workflow (39 nodes)
│   └── Telegram AI Gateway - Log Writer.json # Log Writer workflow (4 nodes)
│
├── docs/
│   ├── SPEC.md                    # Продуктовая спецификация
│   ├── PROJECT_STATE.md           # Паспорт состояния проекта
│   ├── IMPLEMENTATION_PLAN.md     # План реализации
│   ├── architecture.md            # Архитектура проекта
│   ├── architecture-decisions.md  # Архитектурные решения
│   ├── setup.md                   # Инструкция по установке
│   ├── deployment_guide.md        # Руководство по развёртыванию
│   ├── workflow_overview.md       # Обзор workflow
│   ├── logging-integration-guide.md # Интеграция логирования
│   ├── credentials-setup.md       # Настройка credentials
│   ├── negative_tests.md          # Спецификация негативных тестов
│   ├── limitations.md             # Ограничения проекта
│   ├── known_issues.md            # Известные проблемы
│   ├── engineering-investigation-n8n-update.md # Исследование n8n версий
│   └── screenshots/                # Скриншоты workflow и работы бота
│       ├── PEn04_main_workflow.png
│       ├── PEn04_log_workflow.png
│       ├── PEn04_TG_valid.png
│       └── PEn04_TG_errors.png
│
├── migrations/
│   ├── 001_create_workflow_logs.sql      # Создание таблицы логов
│   └── 002_alter_workflow_logs_created_at.sql # Добавление created_at
│
└── scripts/
    └── validate-deployment.sh      # Скрипт валидации развёртывания
```

---

## Состав репозитория

### Обязательные файлы

| Файл | Назначение | Формат |
|------|-----------|--------|
| README.md | Описание проекта, quick start, ссылки на документацию | Markdown |
| LICENSE | Лицензия проекта | MIT License |
| .gitignore | Исключения для Git (env files, logs, etc.) | Git ignore |
| .env.example | Пример конфигурации окружения | Environment |
| docker-compose.yml | Docker Compose конфигурация для n8n | YAML |

### Workflow файлы

| Файл | Назначение | Формат |
|------|-----------|--------|
| workflows/Telegram AI Gateway.json | Основной workflow обработки статей (39 nodes) | JSON |
| workflows/Telegram AI Gateway - Log Writer.json | Workflow для записи логов в PostgreSQL (4 nodes) | JSON |

### Документация

| Файл | Назначение | Формат |
|------|-----------|--------|
| docs/SPEC.md | Продуктовая спецификация | Markdown |
| docs/PROJECT_STATE.md | Паспорт состояния проекта | Markdown |
| docs/IMPLEMENTATION_PLAN.md | План реализации (этот документ) | Markdown |
| docs/architecture.md | Описание архитектуры | Markdown |
| docs/architecture-decisions.md | Архитектурные решения | Markdown |
| docs/setup.md | Инструкция по установке | Markdown |
| docs/deployment_guide.md | Руководство по развёртыванию | Markdown |
| docs/workflow_overview.md | Обзор workflow | Markdown |
| docs/logging-integration-guide.md | Интеграция логирования | Markdown |
| docs/credentials-setup.md | Настройка credentials | Markdown |
| docs/negative_tests.md | Спецификация негативных тестов | Markdown |
| docs/limitations.md | Ограничения проекта | Markdown |
| docs/known_issues.md | Известные проблемы | Markdown |
| docs/engineering-investigation-n8n-update.md | Исследование версий n8n | Markdown |

### Скрипты

| Файл | Назначение | Формат |
|------|-----------|--------|
| scripts/validate-deployment.sh | Валидация развёртывания | Bash |

### Миграции базы данных

| Файл | Назначение | Формат |
|------|-----------|--------|
| migrations/001_create_workflow_logs.sql | Создание таблицы workflow_logs | SQL |
| migrations/002_alter_workflow_logs_created_at.sql | Добавление поля created_at | SQL |

### Скриншоты

| Файл | Назначение | Формат |
|------|-----------|--------|
| docs/screenshots/PEn04_main_workflow.png | Общий вид основного workflow | PNG |
| docs/screenshots/PEn04_log_workflow.png | Общий вид Log Writer workflow | PNG |
| docs/screenshots/PEn04_TG_valid.png | Пример работы бота с валидным URL | PNG |
| docs/screenshots/PEn04_TG_errors.png | Пример работы бота с ошибками | PNG |

### Исключённые файлы

**Не включаются в публичный репозиторий:**
- .env файлы с реальными секретами
- Логи выполнения
- Временные файлы
- Файлы .DS_Store
- Файлы IDE настроек

---

## Состав Docker Compose

### docker-compose.yml

```yaml
version: '3.8'

services:
  n8n:
    image: docker.n8n.io/n8nio/n8n:2.29.8
    container_name: telegram-ai-gateway-n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      # Basic Auth
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=${N8N_BASIC_AUTH_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_BASIC_AUTH_PASSWORD}

      # Webhook URL (optional)
      - WEBHOOK_URL=${WEBHOOK_URL}

      # Security
      - N8N_RESTRICT_FILE_ACCESS_TO=/home/node/.n8n-files
      - N8N_BLOCK_FILE_ACCESS_TO_N8N_FILES=false
      - N8N_BLOCK_ENV_ACCESS_IN_NODE=true

      # Code Node (console.log output)
      - CODE_ENABLE_STDOUT=true

      # Timezone
      - GENERIC_TIMEZONE=UTC

      # Logging
      - N8N_LOG_LEVEL=info

      # Executions
      - EXECUTIONS_MODE=regular
      - EXECUTIONS_DATA_SAVE_ON_ERROR=all
      - EXECUTIONS_DATA_SAVE_ON_SUCCESS=all

    volumes:
      - n8n_data:/home/node/.n8n
      - ./n8n_files:/home/node/.n8n-files

    networks:
      - telegram-ai-gateway

    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:5678/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  postgres:
    image: postgres:15-alpine
    container_name: telegram-ai-gateway-postgres
    restart: unless-stopped
    environment:
      - POSTGRES_USER=${POSTGRES_USER:-n8n}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-n8n_password}
      - POSTGRES_DB=${POSTGRES_DB:-n8n}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - telegram-ai-gateway

volumes:
  n8n_data:
    driver: local
  postgres_data:
    driver: local

networks:
  telegram-ai-gateway:
    driver: bridge
```

### Обоснование версий

**n8n: 2.29.8**
- Production-ready stable версия
- Включает все security patches (Feb 25, 2026 Critical CVEs)
- Не содержит критических регрессий
- Рекомендуется разработчиками для новых проектов
- Версия 1.120.x не используется из-за критической регрессии frontend (ошибка ldap)

**Docker image:** `docker.n8n.io/n8nio/n8n:2.29.8`
- Официальный Docker registry n8n
- Тег `:2.29.8` указывает на конкретную версию

**Подробнее:** [engineering-investigation-n8n-update.md](engineering-investigation-n8n-update.md)

---

## Модель конфигурации (.env.example)

### .env.example

```env
# =============================================================================
# Telegram AI Gateway - Environment Configuration
# =============================================================================
# Copy this file to .env and fill in your values
# =============================================================================

# -----------------------------------------------------------------------------
# n8n Configuration
# -----------------------------------------------------------------------------

# n8n admin credentials
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your_secure_password_here

# Public URL for webhook (optional, required for webhook mode)
# Leave empty for polling mode
WEBHOOK_URL=

# Example: https://your-domain.com
# WEBHOOK_URL=https://your-domain.com

# -----------------------------------------------------------------------------
# Telegram Bot Configuration
# -----------------------------------------------------------------------------

# Telegram Bot Token (from @BotFather)
TELEGRAM_BOT_TOKEN=your_telegram_bot_token_here

# -----------------------------------------------------------------------------
# GigaChat API Configuration
# -----------------------------------------------------------------------------

# GigaChat API credentials (Base64 encoded: client_id:client_secret)
GIGACHAT_AUTH_BASIC=your_base64_encoded_credentials_here

# GigaChat model (default: GigaChat-2-Max)
GIGACHAT_MODEL=GigaChat-2-Max

# GigaChat temperature (default: 0.1)
GIGACHAT_TEMPERATURE=0.1

# -----------------------------------------------------------------------------
# Workflow Configuration
# -----------------------------------------------------------------------------

# Maximum text length for cleaning (characters)
MAX_TEXT_LENGTH=12000

# Maximum prompt length (characters)
MAX_PROMPT_LENGTH=5000

# Maximum message length for Telegram (characters)
MAX_MESSAGE_LENGTH=4096

# -----------------------------------------------------------------------------
# Optional: Logging Configuration
# -----------------------------------------------------------------------------

# Log level: info, warn, error
LOG_LEVEL=info
```

### Переменные окружения

| Переменная | Обязательная | Описание | Пример |
|-----------|-------------|----------|--------|
| N8N_BASIC_AUTH_USER | Да | Логин для n8n | admin |
| N8N_BASIC_AUTH_PASSWORD | Да | Пароль для n8n | secure_password |
| WEBHOOK_URL | Нет | Публичный URL для webhook | https://example.com |
| TELEGRAM_BOT_TOKEN | Да | Токен Telegram-бота | 1234567890:ABC... |
| GIGACHAT_AUTH_BASIC | Да | Base64 credentials | base64_string |
| GIGACHAT_MODEL | Нет | Модель GigaChat | GigaChat-2-Max |
| GIGACHAT_TEMPERATURE | Нет | Температура модели | 0.1 |
| MAX_TEXT_LENGTH | Нет | Лимит длины текста | 12000 |
| MAX_PROMPT_LENGTH | Нет | Лимит длины промпта | 5000 |
| MAX_MESSAGE_LENGTH | Нет | Лимит длины сообщения | 4096 |
| LOG_LEVEL | Нет | Уровень логирования | info |

---

## Структура n8n Workflow

### Обзор workflow

**Название:** Telegram AI Gateway

**Тип:** Линейный workflow с одной веткой обработки ошибок

**Триггер:** Telegram Trigger (On Message)

**Количество нод:** 12 основных + 1 для ошибок

### Диаграмма workflow

```
[Telegram Trigger]
         │
         ▼
  [Prepare Input]
         │
         ▼
    [Check URL] ───────[false]──→ [Send Error Message]
         │ [true]
         ▼
    [Load Page]
         │
         ▼
 [Extract Article]
         │
         ▼
   [Clean Text]
         │
         ▼
 [Prepare Prompt]
         │
         ▼
 [Generate RqUID]
         │
         ▼
[Get GigaChat Token]
         │
         ▼
     [GigaChat]
         │
         ▼
  [Send Message]
```

### Детальная структура нод

#### 1. Telegram Trigger

**Тип:** Telegram Trigger

**Настройки:**
- Trigger On: On Message
- Credentials: Telegram Account (Bot Token)

**Output:**
```json
{
  "message": {
    "text": "<URL>",
    "chat": {
      "id": 123456789
    }
  }
}
```

#### 2. Prepare Input

**Тип:** Set

**Настройки:**
- Operation: Edit Fields
- Fields:
  - Name: url
  - Value: `={{ $json?.message?.text ?? "" }}`

**Output:**
```json
{
  "url": "<URL>"
}
```

#### 3. Check URL

**Тип:** If

**Настройки:**
- Condition: `={{ /^https?:\/\//.test($json.url) }}`
- Operator: is true

**Branches:**
- true → Load Page
- false → Send Error Message

#### 4. Load Page

**Тип:** HTTP Request

**Настройки:**
- Method: GET
- URL: `={{ $json.url }}`
- Response Format: String/Text
- Ignore SSL Issues: true

**Error Handling:**
- Continue On Fail: true
- Retry: 3 attempts, exponential backoff

**Output:**
```json
{
  "url": "<URL>",
  "data": "<HTML>"
}
```

#### 5. Extract Article

**Тип:** HTML Extract

**Настройки:**
- Source: Previous Node
- JSON Key: data
- Extraction: Extract HTML Content
- Selector: article, .tm-article-body, .tm-content

**Output:**
```json
{
  "url": "<URL>",
  "<dynamic_key>": "<article_text>"
}
```

#### 6. Clean Text

**Тип:** Code

**Язык:** JavaScript

**Логика:**
1. Извлечь текст из динамического ключа (Object.values)
2. Удалить мусор (regex patterns)
3. Удалить stop markers (Теги:, Хабы:, etc.)
4. Обрезать до MAX_TEXT_LENGTH

**Output:**
```json
{
  "url": "<URL>",
  "cleaned_text": "<text>"
}
```

#### 7. Prepare Prompt

**Тип:** Set

**Настройки:**
- Operation: Edit Fields
- Fields:
  - Name: prompt
  - Value: Динамический промпт с ограничением MAX_PROMPT_LENGTH

**Output:**
```json
{
  "url": "<URL>",
  "cleaned_text": "<text>",
  "prompt": "<prompt>"
}
```

#### 8. Generate RqUID

**Тип:** Code

**Язык:** JavaScript

**Логика:**
- Генерация UUID: `crypto.randomUUID()`
- Сохранение всех предыдущих полей

**Output:**
```json
{
  "url": "<URL>",
  "cleaned_text": "<text>",
  "prompt": "<prompt>",
  "rq_uid": "<uuid>"
}
```

#### 9. Get GigaChat Token

**Тип:** HTTP Request

**Настройки:**
- Method: POST
- URL: https://ngw.devices.sberbank.ru:9443/api/v2/oauth
- Headers:
  - Authorization: Basic {{GIGACHAT_AUTH_BASIC}}
  - RqUID: `={{ $json.rq_uid }}`
  - Content-Type: application/x-www-form-urlencoded
- Body: scope=GIGACHAT_API_PERS

**Error Handling:**
- Retry: 2 attempts, linear backoff

**Output:**
```json
{
  "access_token": "<token>",
  "expires_in": "<seconds>"
}
```

#### 10. GigaChat

**Тип:** HTTP Request

**Настройки:**
- Method: POST
- URL: https://gigachat.devices.sberbank.ru/api/v1/chat/completions
- Headers:
  - Authorization: Bearer `={{ $json.access_token }}`
  - Content-Type: application/json
- Body:
  ```json
  {
    "model": "GigaChat-2-Max",
    "temperature": 0.1,
    "messages": [
      {
        "role": "system",
        "content": "<system_prompt>"
      },
      {
        "role": "user",
        "content": "={{ $('Prepare Prompt').item.json.prompt }}"
      }
    ]
  }
  ```

**Error Handling:**
- Retry: 2 attempts, exponential backoff
- Timeout: 60 seconds

**Output:**
```json
{
  "choices": [{
    "message": {
      "content": "<generated_post>"
    }
  }]
}
```

#### 11. Send Message

**Тип:** Telegram

**Настройки:**
- Operation: Send Message
- Credentials: Telegram Account (Bot Token)
- Chat ID: `={{ $('Telegram Trigger').item.json.message.chat.id }}`
- Text: `={{ $json.choices[0].message.content }}`

**Error Handling:**
- Check message length
- Split if > 4096 characters

#### 12. Send Error Message

**Тип:** Telegram

**Настройки:**
- Operation: Send Message
- Credentials: Telegram Account (Bot Token)
- Chat ID: `={{ $('Telegram Trigger').item.json.message.chat.id }}`
- Text: "Пожалуйста, отправьте корректную ссылку на статью, начинающуюся с http:// или https://"

---

## Состав и назначение workflow

### Основной workflow

**Название:** Telegram AI Gateway

**Назначение:** Обработка URL статьи, генерация структурированного поста через GigaChat, отправка результата в Telegram

**Триггер:** Telegram Message

**Входные данные:**
- URL статьи (текст сообщения в Telegram)

**Выходные данные:**
- Структурированный пост для Telegram
- Или сообщение об ошибке

**Время выполнения:** ~5-30 секунд (зависит от длины статьи и скорости GigaChat API)

---

## Последовательность реализации

### Этап 1: Инфраструктура

**Задачи:**
1. Создать docker-compose.yml
2. Создать .env.example
3. Создать структуру каталогов
4. Добавить .gitignore

**Критерии завершения:**
- ✅ Docker Compose запускается без ошибок
- ✅ n8n доступен по адресу http://localhost:5678
- ✅ Базовая авторизация работает
- ✅ Структура каталогов соответствует плану

### Этап 2: Workflow Core

**Задачи:**
1. Создать workflow JSON
2. Добавить Telegram Trigger
3. Добавить Prepare Input
4. Добавить Check URL
5. Добавить Load Page
6. Добавить Extract Article
7. Добавить Clean Text
8. Добавить Prepare Prompt
9. Добавить Generate RqUID
10. Добавить Get GigaChat Token
11. Добавить GigaChat
12. Добавить Send Message
13. Добавить Send Error Message

**Критерии завершения:**
- ✅ Workflow импортируется в n8n без ошибок
- ✅ Workflow активируется
- ✅ Бот отвечает на валидный URL
- ✅ Бот отвечает на невалидный URL

### Этап 3: Обработка ошибок

**Задачи:**
1. Добавить обработку ошибок Load Page
2. Добавить обработку ошибок Get GigaChat Token
3. Добавить обработку ошибок GigaChat
4. Добавить обработку ошибок Send Message

**Критерии завершения:**
- ✅ Бот отвечает информативным сообщением при ошибке загрузки страницы
- ✅ Бот отвечает информативным сообщением при ошибке GigaChat API
- ✅ Бот отвечает информативным сообщением при ошибке отправки сообщения

### Этап 4: Retry механизмы

**Задачи:**
1. Настроить retry для Load Page (3 попытки)
2. Настроить retry для Get GigaChat Token (2 попытки)
3. Настроить retry для GigaChat (2 попытки)

**Критерии завершения:**
- ✅ Load Page делает 3 попытки при сетевых ошибках
- ✅ Get GigaChat Token делает 2 попытки при ошибках аутентификации
- ✅ GigaChat делает 2 попытки при ошибках API

### Этап 5: Ограничение длины сообщений

**Задачи:**
1. Добавить проверку длины сообщения перед отправкой
2. Добавить разбиение длинных сообщений на части
3. Добавить отправку частей последовательно

**Критерии завершения:**
- ✅ Сообщения длиннее 4096 символов разбиваются на части
- ✅ Части отправляются последовательно
- ✅ Каждая часть имеет номер (Часть 1/N)

### Этап 6: Конфигурация

**Задачи:**
1. Вынести промпты в переменные окружения
2. Вынести параметры модели в переменные окружения
3. Вынести лимиты длины в переменные окружения

**Критерии завершения:**
- ✅ Промпты настраиваются через .env
- ✅ Параметры модели настраиваются через .env
- ✅ Лимиты длины настраиваются через .env

### Этап 7: Документация

**Задачи:**
1. Создать README.md
2. Создать docs/architecture.md
3. Создать docs/setup.md
4. Создать docs/deployment_guide.md
5. Создать docs/workflow_overview.md
6. Создать docs/limitations.md
7. Создать docs/known_issues.md

**Критерии завершения:**
- ✅ README.md описывает проект и quick start
- ✅ Документация полная и актуальная
- ✅ Инструкции воспроизводимы

### Этап 8: Валидация

**Задачи:**
1. Создать scripts/validate-deployment.sh
2. Протестировать на чистом окружении
3. Провести Deployment Validation

**Критерии завершения:**
- ✅ Проект разворачивается на чистом VPS
- ✅ Все тесты проходят
- ✅ Deployment Validation пройден

---

## Порядок восстановления исходного workflow

### Источники для восстановления

| Источник | Содержимое | Использование |
|---------|-----------|--------------|
| docs/SPEC.md | Требования к workflow | Основной источник |
| PEn04_task_SOT.md | Подробное описание нод | Детали реализации |
| Скриншоты workflow | Визуальное представление | Верификация |

### Шаги восстановления

**1. Создание базовой структуры**
- Создать пустой workflow
- Добавить Telegram Trigger
- Настроить credentials

**2. Добавление нод по порядку**
- Добавить каждую ноду согласно диаграмме workflow
- Настроить connections между нодами
- Настроить ветку false для Check URL

**3. Настройка каждой ноды**
- Скопировать параметры из описания
- Настроить expressions
- Настроить error handling

**4. Тестирование базового workflow**
- Протестировать каждую ноду отдельно
- Протестировать полный цикл
- Проверить обработку ошибок

**5. Добавление улучшений**
- Добавить retry механизмы
- Добавить обработку длинных сообщений
- Добавить конфигурационные переменные

---

## Порядок внедрения улучшений

### Приоритет 1: Обязательные улучшения

**1.1. Обработка ошибок**
- Добавить Continue On Fail для Load Page
- Добавить обработку пустого результата Extract Article
- Добавить обработку ошибок GigaChat API

**Время:** 2-3 часа

**1.2. Retry механизмы**
- Настроить retry для Load Page (3 попытки)
- Настроить retry для Get GigaChat Token (2 попытки)
- Настроить retry для GigaChat (2 попытки)

**Время:** 1-2 часа

**1.3. Ограничение длины сообщений**
- Добавить проверку длины в Send Message
- Добавить Code ноду для разбиения сообщения
- Добавить Loop для отправки частей

**Время:** 2-3 часа

### Приоритет 2: Рекомендуемые улучшения

**2.1. Конфигурационные переменные**
- Вынести промпты в .env
- Вынести параметры модели в .env
- Вынести лимиты длины в .env

**Время:** 1 час

**2.2. Логирование**
- Добавить логирование в ключевых нодах
- Настроить уровень логирования через .env

**Время:** 1-2 часа

### Приоритет 3: Опциональные улучшения

**3.1. Token caching**
- Добавить кэширование токена GigaChat
- Добавить проверку expiration time

**Время:** 2 часа

---

## Стратегия обработки ошибок

### Общие принципы

1. **Continue On Fail:** Включить для всех HTTP Request нод
2. **Error Output:** Проверять error output в следующих нодах
3. **User-Friendly Messages:** Отправлять понятные сообщения пользователю
4. **Logging:** Логировать все ошибки с контекстом

### Обработка по типам ошибок

#### User Input Errors

**Check URL:**
- Условие: URL не соответствует regex `^https?://`
- Действие: Отправить сообщение "Пожалуйста, отправьте корректную ссылку на статью, начинающуюся с http:// или https://"
- Workflow: Завершить

#### Network Errors

**Load Page:**
- Условие: Timeout, connection error, HTTP 4xx/5xx
- Действие: Retry 3 раза с exponential backoff
- При неудаче: Отправить сообщение "Не удалось загрузить страницу. Проверьте URL и повторите попытку."
- Workflow: Завершить

#### Content Errors

**Extract Article:**
- Условие: Пустой результат извлечения
- Действие: Отправить сообщение "Не удалось извлечь текст из статьи."
- Workflow: Завершить

**Clean Text:**
- Условие: Пустой результат очистки
- Действие: Отправить сообщение "Текст статьи не содержит полезного содержимого."
- Workflow: Завершить

#### GigaChat API Errors

**Get GigaChat Token:**
- Условие: Authentication error, API error
- Действие: Retry 2 раза
- При неудаче: Отправить сообщение "Ошибка авторизации в сервисе. Обратитесь к администратору."
- Workflow: Завершить

**GigaChat:**
- Условие: API error, timeout, rate limit
- Действие: Retry 2 раза с exponential backoff
- При неудаче: Отправить сообщение "Сервис временно недоступен. Попробуйте позже."
- Workflow: Завершить

#### Telegram API Errors

**Send Message:**
- Условие: Message too long (> 4096 characters)
- Действие: Разбить сообщение на части
- Отправить части последовательно

- Условие: Bot blocked by user
- Действие: Логировать ошибку, не отправлять сообщение

### Error Flow Diagram

```
[Load Page Error]
        │
        ▼
[Send Error Message] → "Не удалось загрузить страницу"

[Extract Article Error]
        │
        ▼
[Send Error Message] → "Не удалось извлечь текст"

[GigaChat Token Error]
        │
        ▼
[Send Error Message] → "Ошибка авторизации"

[GigaChat API Error]
        │
        ▼
[Send Error Message] → "Сервис недоступен"
```

---

## Стратегия retry

### Retry параметры по нодам

| Нода | Max Retries | Delay | Backoff | Conditions |
|------|-------------|-------|---------|------------|
| Load Page | 3 | 1000ms | Exponential (2x) | Network errors, timeouts |
| Get GigaChat Token | 2 | 500ms | Linear | Auth errors, API errors |
| GigaChat | 2 | 1000ms | Exponential (2x) | API errors, timeouts |

### Retry логика

**Load Page:**
- Попытка 1: немедленно
- Попытка 2: через 1 секунду
- Попытка 3: через 2 секунды
- Попытка 4: через 4 секунды

**Get GigaChat Token:**
- Попытка 1: немедленно
- Попытка 2: через 500ms

**GigaChat:**
- Попытка 1: немедленно
- Попытка 2: через 1 секунду
- Попытка 3: через 2 секунды

### Реализация в n8n

**Settings → Workflow Settings → Error Workflow:**
- Включить "Continue on Fail" для нод с retry
- Добавить Error Trigger ноду для перехвата ошибок
- Логировать все retry attempts

---

## Стратегия логирования

### Log Levels

| Level | Events |
|-------|--------|
| INFO | Workflow start, URL received, Page loaded, Token obtained, Message sent |
| WARNING | Retry attempt, Text truncated |
| ERROR | Invalid URL, Page load failed, Auth failed, API error |

### Логируемые события

**INFO:**
- Workflow started (chat_id, url)
- Page loaded successfully (url, size)
- Token obtained (expires_in)
- Message sent successfully (chat_id, message_length)

**WARNING:**
- Retrying Load Page (attempt, url)
- Retrying GigaChat Token (attempt)
- Retrying GigaChat (attempt)
- Text truncated (original_length, truncated_length)

**ERROR:**
- Invalid URL (chat_id, url)
- Page load failed (url, error_code, error_message)
- Article extraction failed (url)
- Auth failed (error_message)
- API error (error_code, error_message)
- Send failed (chat_id, error_message)

### Реализация логирования

**В каждой ноде:**
- Добавить Console.log в Code нодах
- Добавить Set ноду для логирования после ключевых операций
- Использовать n8n execution history для отладки

---

## Стратегия хранения секретов

### Переменные окружения

**Хранение:**
- Все секреты в .env файле
- .env файл добавлен в .gitignore
- .env.example содержит плейсхолдеры

**Переменные:**
- `N8N_BASIC_AUTH_PASSWORD` — пароль для n8n
- `TELEGRAM_BOT_TOKEN` — токен Telegram-бота
- `GIGACHAT_AUTH_BASIC` — Base64 credentials для GigaChat

### n8n Credentials

**Хранение:**
- Credentials сохраняются в n8n data volume
- Не экспортируются в workflow JSON
- Настраиваются через n8n UI при первом запуске

**Типы credentials:**
- Telegram Account (Bot Token)
- HTTP Header Auth (GigaChat Basic Auth)

### Рекомендации по безопасности

1. **Сильные пароли:** Использовать генератор паролей для `N8N_BASIC_AUTH_PASSWORD`
2. **Ротация:** Периодически менять пароли и токены
3. **HTTPS:** Использовать HTTPS для всех внешних коммуникаций
4. **IP Whitelisting:** Рассмотреть ограничение доступа к n8n admin по IP

---

## Стратегия тестирования

### Уровни тестирования

**1. Unit Testing (ноды)**
- Тестирование каждой ноды отдельно
- Проверка input/output
- Проверка error handling

**2. Integration Testing (workflow)**
- Тестирование полного цикла
- Проверка connections между нодами
- Проверка error flow

**3. End-to-End Testing (user scenarios)**
- Тестирование с реальными URL
- Тестирование с реальными статьями
- Тестирование с реальными пользователями

### Тестовые сценарии

| # | Сценарий | Вход | Ожидаемый результат |
|---|----------|------|---------------------|
| 1 | Валидный URL | https://valid-url.com | Структурированный пост |
| 2 | Невалидный URL | invalid-url | Сообщение об ошибке |
| 3 | Пустой URL | (пусто) | Сообщение об ошибке |
| 4 | Несуществующий URL | https://nonexistent.com | Сообщение об ошибке |
| 5 | Страница 404 | https://valid-url.com/404 | Сообщение об ошибке |
| 6 | Страница 500 | https://valid-url.com/500 | Сообщение об ошибке |
| 7 | Длинная статья | URL статьи > 12000 символов | Усечённый пост |
| 8 | Длинный ответ | URL, генерирующий > 4096 символов | Разбитый на части пост |

### Тестовые данные

**Валидные URL:**
- https://habr.com/ru/articles/... (статьи Хабра)
- https://medium.com/... (статьи Medium)
- https://example.com/article (простые статьи)

**Невалидные URL:**
- invalid-url (без протокола)
- ftp://example.com (неправильный протокол)
- (пусто)

---

## Стратегия Deployment Validation

### Deployment Validation Checklist

**Prerequisites:**
- [ ] Docker установлен
- [ ] Docker Compose установлен
- [ ] Git установлен
- [ ] Токены получены: Telegram Bot Token, GigaChat credentials

**Deployment Steps:**
- [ ] Клонировать репозиторий
- [ ] Скопировать .env.example в .env
- [ ] Заполнить переменные окружения
- [ ] Запустить docker-compose up -d
- [ ] Дождаться запуска n8n
- [ ] Открыть http://localhost:5678
- [ ] Войти с credentials из .env
- [ ] Импортировать workflow JSON
- [ ] Настроить Telegram credentials
- [ ] Настроить GigaChat credentials
- [ ] Активировать workflow
- [ ] Отправить тестовый URL в Telegram-бота
- [ ] Получить структурированный пост

**Validation Tests:**
- [ ] Бот отвечает на валидный URL
- [ ] Бот отвечает на невалидный URL
- [ ] Бот обрабатывает ошибку загрузки страницы
- [ ] Бот обрабатывает ошибку GigaChat API
- [ ] Бот обрабатывает длинную статью
- [ ] Бот обрабатывает длинный ответ

**Documentation Validation:**
- [ ] README.md актуален
- [ ] setup.md воспроизводим
- [ ] deployment_guide.md актуален
- [ ] Все ссылки работают
- [ ] Все команды выполняются

### Чистое окружение

**Требование:** Deployment Validation должен проводиться на чистом окружении без остатков предыдущих развёртываний.

**Чистое окружение:**
- Свежий VPS
- Или Docker machine reset
- Или Docker system prune

---

## Состав публичной документации GitHub

### README.md

**Структура:**
1. Название и описание проекта
2. Демо (скриншоты или GIF)
3. Возможности
4. Быстрый старт
5. Требования
6. Установка
7. Конфигурация
8. Использование
9. Архитектура
10. Ограничения
11. Известные проблемы
12. Развитие проекта
13. Лицензия
14. Автор

### docs/architecture.md

**Содержимое:**
- Высокоуровневая архитектура
- Диаграмма workflow
- Описание компонентов
- Внешние интеграции
- Потоки данных

### docs/setup.md

**Содержимое:**
- Требования к системе
- Установка Docker
- Установка Docker Compose
- Клонирование репозитория
- Конфигурация .env
- Запуск проекта
- Первичная настройка

### docs/deployment_guide.md

**Содержимое:**
- Развёртывание на VPS
- Настройка HTTPS (Nginx/Caddy)
- Настройка webhook
- Мониторинг
- Обновление
- Бэкапы

### docs/workflow_overview.md

**Содержимое:**
- Обзор workflow
- Описание каждой ноды
- Обработка ошибок
- Retry механизмы
- Логирование

### docs/limitations.md

**Содержимое:**
- Ограничения Telegram API
- Ограничения GigaChat API
- Ограничения n8n
- Ограничения проекта

### docs/known_issues.md

**Содержимое:**
- Известные проблемы
- Workarounds
- Планы по исправлению

---

## Критерии завершения каждого этапа реализации

### Этап 1: Инфраструктура

**Критерии:**
- ✅ docker-compose.yml создан и работает
- ✅ .env.example создан и содержит все переменные
- ✅ Структура каталогов соответствует плану
- ✅ .gitignore настроен правильно

**Валидация:**
```bash
docker-compose up -d
curl http://localhost:5678/health
# Expected: n8n is running
```

### Этап 2: Workflow Core

**Критерии:**
- ✅ Workflow JSON создан
- ✅ Workflow импортируется без ошибок
- ✅ Workflow активируется
- ✅ Бот отвечает на валидный URL
- ✅ Бот отвечает на невалидный URL

**Валидация:**
```bash
# Send valid URL to bot
# Expected: Structured post

# Send invalid URL to bot
# Expected: Error message
```

### Этап 3: Обработка ошибок

**Критерии:**
- ✅ Load Page ошибки обрабатываются
- ✅ GigaChat Token ошибки обрабатываются
- ✅ GigaChat API ошибки обрабатываются
- ✅ Пользователь получает информативные сообщения

**Валидация:**
```bash
# Send URL to nonexistent page
# Expected: "Не удалось загрузить страницу"

# Send URL to page with no article
# Expected: "Не удалось извлечь текст"
```

### Этап 4: Retry механизмы

**Критерии:**
- ✅ Load Page делает 3 попытки
- ✅ Get GigaChat Token делает 2 попытки
- ✅ GigaChat делает 2 попытки
- ✅ Retry attempts логируются

**Валидация:**
```bash
# Check n8n execution history
# Expected: Retry attempts logged
```

### Этап 5: Ограничение длины сообщений

**Критерии:**
- ✅ Сообщения > 4096 символов разбиваются
- ✅ Части отправляются последовательно
- ✅ Каждая часть имеет номер

**Валидация:**
```bash
# Send URL to article generating long response
# Expected: Multiple messages with "Часть 1/N"
```

### Этап 6: Конфигурация

**Критерии:**
- ✅ Промпты в .env
- ✅ Параметры модели в .env
- ✅ Лимиты длины в .env
- ✅ Workflow использует переменные из .env

**Валидация:**
```bash
# Change MAX_TEXT_LENGTH in .env
# Restart n8n
# Expected: Workflow uses new value
```

### Этап 7: Документация

**Критерии:**
- ✅ README.md создан
- ✅ Все docs/* файлы созданы
- ✅ Инструкции воспроизводимы
- ✅ Все ссылки работают

**Валидация:**
```bash
# Follow setup.md on clean environment
# Expected: Project runs successfully
```

### Этап 8: Валидация

**Критерии:**
- ✅ Проект разворачивается на чистом VPS
- ✅ Все тесты проходят
- ✅ Deployment Validation пройден
- ✅ Документация актуальна

**Валидация:**
```bash
# Run scripts/validate-deployment.sh
# Expected: All checks pass
```

---

## Logging Layer

### Назначение

Превратить Telegram AI Gateway из просто работающего workflow в эксплуатационно пригодный инженерный сервис.

**Главная цель:** После завершения внедрения должна существовать возможность восстановить полный жизненный цикл любого пользовательского запроса по журналу выполнения.

### Архитектура

**Принцип:** Логирование реализуется как отдельный reusable workflow.

**Причины:**
- Основной workflow не должен засоряться PostgreSQL-нодами
- Логика записи журналов должна находиться в одном месте
- Изменение формата логов должно выполняться только в одном workflow
- Основной workflow должен содержать только бизнес-логику

**Структура:**
```
Основной workflow (Telegram AI Gateway)
       ↓
Execute Workflow Node
       ↓
Telegram AI Gateway - Log Writer
       ↓
PostgreSQL (workflow_logs table)
```

### Компоненты

#### SQL Migration

**Файл:** `migrations/001_create_workflow_logs.sql`

**Таблица workflow_logs:**
- id (primary key)
- created_at (timestamp with time zone)
- request_id (uuid, indexed)
- workflow_name (varchar)
- workflow_version (varchar)
- stage (varchar)
- event_type (varchar)
- level (varchar: INFO, WARNING, ERROR)
- status (varchar: SUCCESS, FAILED, IN_PROGRESS)
- chat_id (varchar)
- user_id (varchar)
- input_url (text)
- duration_ms (integer)
- message (text)
- error_code (varchar)
- error_message (text)
- details (jsonb)

**Индексы:**
- idx_workflow_logs_request_id — для поиска по request_id
- idx_workflow_logs_created_at — для time-based queries
- idx_workflow_logs_workflow_name — для multi-workflow support
- idx_workflow_logs_request_created — composite для эффективности
- idx_workflow_logs_status — для error tracking
- idx_workflow_logs_level — для фильтрации по level

#### Log Writer Workflow

**Файл:** `workflows/Telegram AI Gateway - Log Writer.json`

**Ноды:**
1. Prepare Log Entry — валидация входных данных, установка defaults
2. Insert Log to PostgreSQL — запись в БД
3. Finalize Log Entry — подтверждение успешной записи

**Входной контракт:**
- request_id (required)
- workflow_name (required)
- stage (required)
- level (default: INFO)
- status (default: IN_PROGRESS)
- Остальные поля опциональны

#### Основной Workflow

**Точки логирования:**

**Обязательные:**
- REQUEST_RECEIVED — получение запроса от Telegram
- URL_VALIDATED — успешная валидация URL
- PAGE_LOADED / PAGE_LOAD_FAILED — загрузка страницы
- ARTICLE_EXTRACTED / ARTICLE_EXTRACT_FAILED — извлечение статьи
- TOKEN_RECEIVED / TOKEN_FAILED — получение токена GigaChat
- LLM_COMPLETED / LLM_FAILED — генерация поста
- TELEGRAM_SENT — отправка в Telegram
- WORKFLOW_FINISHED / WORKFLOW_FAILED — завершение workflow

**Дополнительные (опционально):**
- PAGE_LOAD_STARTED
- PROMPT_BUILT
- TOKEN_REQUEST_STARTED
- LLM_REQUEST_STARTED
- MESSAGE_SPLIT
- TELEGRAM_SEND_STARTED

**Интеграция:**
- Добавить Execute Workflow nodes в ключевых точках
- Передавать параметры через Expressions
- Использовать Continue On Fail для неблокирующего логирования

### Принципы

**request_id:**
- Создаётся один раз в Generate Request ID node
- Используется во всех точках логирования
- Получение: `$('Generate Request ID').item.json.request_id`
- Не добавлять дополнительные Code nodes только ради прокидывания request_id

**Console.log:**
- Может остаться как вспомогательный механизм диагностики
- Основным журналом выполнения считается PostgreSQL

**Log Writer:**
- Не должен знать о Telegram
- Не должен знать о GigaChat
- Ничего не знает о бизнес-логике
- Создан для Telegram AI Gateway, но реализован расширяемо

### Документация

**Интеграция:** `docs/logging-integration-guide.md`

**Содержимое:**
- Подробное описание точек логирования
- Параметры Execute Workflow nodes
- Примеры конфигурации для каждой точки
- Инструкция по внедрению
- Минимальный набор точек логирования

### Критерий успешности

**После завершения внедрения:**
1. Каждый запрос пользователя полностью восстановим по журналу
2. Последовательность событий видна по created_at
3. Ошибки содержат error_code и error_message
4. Успешные выполнения содержат status: SUCCESS
5. Неудачные выполнения содержат status: FAILED

**SQL для проверки:**
```sql
-- Полный жизненный цикл запроса
SELECT * FROM workflow_logs
WHERE request_id = '<request_id>'
ORDER BY created_at;

-- Все неудачные запросы за 24 часа
SELECT DISTINCT request_id, created_at, error_message
FROM workflow_logs
WHERE status = 'FAILED'
  AND created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;

-- Среднее время обработки
SELECT AVG(duration_ms)
FROM workflow_logs
WHERE stage = 'WORKFLOW_FINISHED'
  AND status = 'SUCCESS';
```

---

## Версионирование IMPLEMENTATION_PLAN

| Версия | Дата | Изменения |
|--------|------|-----------|
| 1.0 | 2026-07-08 | Начальная версия |
| 1.1 | 2026-07-09 | Добавлен раздел Logging Layer |

---

**Конец IMPLEMENTATION_PLAN.md**