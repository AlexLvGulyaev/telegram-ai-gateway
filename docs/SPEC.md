# SPEC: Telegram AI Gateway

**Версия:** 1.2
**Дата:** 2026-07-08
**Статус:** Draft

---

## Назначение проекта

Telegram AI Gateway — демонстрационный AI MVP, реализующий Telegram-бота для автоматизированной переработки статей в структурированные посты для Telegram.

**Бизнес-идея:** Пользователь отправляет ссылку на статью в Telegram-бота. Бот автоматически загружает статью, очищает текст, формирует промпт, вызывает GigaChat API и возвращает структурированный пост для публикации в Telegram-канале.

**Целевая аудитория:** Контент-менеджеры, редакторы Telegram-каналов, авторы, нуждающиеся в автоматизации переработки длинных статей в формат Telegram-постов.

**Позиционирование:** Учебно-демонстрационный проект для портфолио, иллюстрирующий интеграцию n8n, GigaChat API и Telegram Bot API.

---

## Разделение ответственности

### 1. Что было в исходном проекте

**Архитектура:**
- Линейный workflow из 12 нод
- Отдельная ветка обработки невалидного URL
- Зависимость от системного VPN
- Использование ngrok для webhook

**Реализованный функционал:**
- Приём URL статьи из Telegram
- Валидация URL (regex)
- Загрузка веб-страницы
- Извлечение текста статьи
- Очистка текста от мусора
- Формирование промпта для GigaChat
- Получение токена GigaChat API
- Генерация структурированного поста
- Отправка результата в Telegram

**Ключевые технические решения:**
- Optional chaining и nullish coalescing
- Извлечение текста через Object.values (обход динамических ключей)
- Ограничение длины текста
- Низкая температура модели (0.1)
- System prompt для форматирования

**Известные ограничения:**
- Требуется системный VPN
- Браузерный VPN не работает
- Отсутствует обработка ошибок
- Нет логирования
- Нет retry-механизмов
- Нет ограничения длины сообщений Telegram
- Промпты и параметры захардкожены

### 2. Что должно быть реализовано

**Обязательные компоненты:**
- n8n workflow с полной логикой обработки
- Telegram Trigger (On Message)
- Prepare Input (Set node)
- Check URL (If node)
- Load Page (HTTP Request)
- Extract Article (HTML Extract)
- Clean Text (Code node)
- Prepare Prompt (Set node)
- Generate RqUID (Code node)
- Get GigaChat Token (HTTP Request)
- GigaChat (HTTP Request)
- Send Message (Telegram node)
- Send Error Message (Telegram node)

**Обязательные параметры:**
- Модель: GigaChat-2-Max
- Температура: 0.1
- Формат ответа: Заголовок, Краткое описание, 3-5 пунктов, Вывод
- Stop markers для очистки текста
- Ограничения длины текста

**Обязательный функционал:**
- Валидация URL
- Загрузка страницы
- Извлечение и очистка текста
- Формирование промпта
- Получение токена GigaChat
- Генерация поста
- Отправка в Telegram
- Сообщение об ошибке при невалидном URL

**Обязательные требования к развёртыванию:**
- Docker Compose конфигурация для n8n
- Пример конфигурации окружения
- Документация по настройке credentials
- Указание на необходимость VPN (если применимо)

### 3. Что добавляется в публичную версию

**Требования к обработке ошибок:**
- Обработка ошибки загрузки страницы
- Обработка ошибки извлечения текста
- Обработка ошибки GigaChat API
- Обработка ошибки отправки в Telegram
- Пользовательские сообщения об ошибках

**Требования к retry-механизмам:**
- Retry для Load Page
- Retry для Get GigaChat Token
- Retry для GigaChat API вызова

**Требования к логированию:**
- Логирование входящих запросов
- Логирование успешных генераций
- Логирование ошибок с контекстом

**Требования к ограничению длины сообщений:**
- Проверка длины ответа перед отправкой
- Разбиение длинных сообщений на части
- Обработка ограничения Telegram API (4096 символов)

**Требования к конфигурации:**
- Вынос промптов в переменные
- Вынос параметров в конфигурацию
- Документирование всех секретов

**Требования к документации:**
- README.md
- docs/architecture.md
- docs/setup.md
- docs/workflow_overview.md
- docs/deployment_guide.md
- docs/limitations.md
- docs/known_issues.md

**Требования к воспроизводимости:**
- Валидированный workflow JSON
- Пошаговая инструкция развёртывания
- Deployment Validation на чистом окружении

### 4. Что остаётся в backlog

**Приоритет 1:**

| Требование | Обоснование |
|-----------|-------------|
| Обработка ошибок загрузки страницы | Надёжность |
| Обработка ошибок извлечения текста | Надёжность |
| Обработка ошибок превышения лимитов | Telegram API limits |
| Вынесение промптов в переменные | Поддерживаемость |
| Вынесение ключевых параметров | Поддерживаемость |
| Добавление логирования | Отладка и мониторинг |
| Добавление retry | Надёжность |
| Ограничение длины сообщений | Telegram API limits |

**Приоритет 2:**

| Требование | Обоснование |
|-----------|-------------|
| Проверка и нормализация URL | Усиление сценария |
| Условное форматирование ответа | Улучшение UX |
| Retry для Load Page | Надёжность |
| Retry для GigaChat API | Надёжность |
| Message length splitting | Telegram limits |
| Configuration variables | Поддерживаемость |

**Приоритет 3:**

| Требование | Обоснование |
|-----------|-------------|
| Error Trigger workflow | Централизованная обработка ошибок |
| Structured logging | Мониторинг |
| Token caching | Оптимизация (токен живёт ~30 мин) |
| Execution Logging | Эксплуатационная пригодность, восстановление жизненного цикла запросов |

---

## Execution Logging

### Назначение

Превратить Telegram AI Gateway из просто работающего workflow в эксплуатационно пригодный инженерный сервис.

**Главная цель:** После внедрения должна существовать возможность восстановить полный жизненный цикл любого пользовательского запроса по журналу выполнения.

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

**SQL Migration:**
- Таблица workflow_logs с полями: id, created_at, request_id, workflow_name, workflow_version, stage, event_type, level, status, chat_id, user_id, input_url, duration_ms, message, error_code, error_message, details
- Индексы для быстрого поиска по request_id, created_at, workflow_name, status, level

**Log Writer Workflow:**
- Отдельный reusable workflow
- Принимает событие журналирования
- Записывает в PostgreSQL
- Не знает о Telegram, GigaChat, бизнес-логике

**Logging Points:**

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

### Принципы

**request_id:**
- Создаётся один раз
- Используется во всех точках логирования
- Не добавлять дополнительные Code nodes только ради прокидывания request_id

**Console.log:**
- Может остаться как вспомогательный механизм диагностики
- Основным журналом выполнения считается PostgreSQL

**Log Writer:**
- Не должен знать о Telegram
- Не должен знать о GigaChat
- Ничего не знает о бизнес-логике
- Создан для Telegram AI Gateway, но реализован расширяемо

### Критерий успешности

**После внедрения:**
1. Каждый запрос полностью восстановим по журналу
2. Последовательность событий видна по created_at
3. Ошибки содержат error_code и error_message
4. Успешные выполнения содержат status: SUCCESS
5. Неудачные выполнения содержат status: FAILED

---

## Исходный пользовательский сценарий

**Название:** Генерация Telegram-поста из статьи

**Актёры:**
- Пользователь (автор контента, редактор)
- Telegram-бот
- n8n workflow
- GigaChat API

**Предусловия:**
1. Telegram-бот развёрнут и доступен
2. Пользователь имеет доступ к боту в Telegram
3. Бот имеет валидный Telegram Bot Token
4. Бот имеет валидные GigaChat API credentials
5. Сетевая связность с Telegram API и GigaChat API обеспечена

**Основной поток:**

| Шаг | Действие | Результат |
|-----|----------|-----------|
| 1 | Пользователь отправляет URL статьи | Бот принимает сообщение |
| 2 | Telegram Trigger активирует workflow | Workflow запускается |
| 3 | Prepare Input извлекает URL | URL передаётся далее |
| 4 | Check URL проверяет валидность | Если валиден → переход к шагу 6 |
| 5 | Если URL невалиден → Send Error Message | Пользователь получает сообщение об ошибке |
| 6 | Load Page загружает HTML | HTML получен |
| 7 | Extract Article извлекает текст | Текст статьи извлечён |
| 8 | Clean Text очищает текст | Очищенный текст |
| 9 | Prepare Prompt формирует промпт | Промпт готов |
| 10 | Generate RqUID создаёт UUID | RqUID для запроса |
| 11 | Get GigaChat Token получает токен | access_token получен |
| 12 | GigaChat генерирует пост | JSON с ответом |
| 13 | Send Message отправляет результат | Пользователь получает пост |

**Альтернативные потоки:**

**A1: Страница не загрузилась**
- Workflow перехватывает ошибку
- Пользователь получает сообщение: "Не удалось загрузить страницу. Проверьте URL и повторите попытку."
- Workflow завершается

**A2: Текст не извлечён**
- Пользователь получает сообщение: "Не удалось извлечь текст из статьи."
- Workflow завершается

**A3: GigaChat API недоступен**
- Пользователь получает сообщение: "Сервис временно недоступен. Попробуйте позже."
- Workflow завершается

**Результат:**
- Успех: Пользователь получает структурированный пост
- Неудача: Пользователь получает понятное сообщение об ошибке

---

## Целевой пользовательский сценарий

**Отличия от исходного:**

1. **Обработка ошибок:**
   - Все ошибки перехватываются
   - Пользователь получает информативные сообщения
   - Workflow логирует ошибки

2. **Retry-механизмы:**
   - Сетевые ошибки обрабатываются с retry
   - GigaChat API ошибки обрабатываются с retry

3. **Длинные сообщения:**
   - Сообщения длиннее 4096 символов разбиваются на части
   - Каждая часть отправляется отдельным сообщением

4. **Конфигурация:**
   - Промпты и параметры вынесены в конфигурацию
   - Секреты управляются через переменные окружения

**Сценарий развёртывания:**

| Шаг | Действие | Результат |
|-----|----------|-----------|
| 1 | Клонировать репозиторий | Файлы проекта на диске |
| 2 | Скопировать .env.example в .env | Шаблон конфигурации |
| 3 | Заполнить переменные окружения | Валидная конфигурация |
| 4 | Запустить Docker Compose | Контейнеры запущены |
| 5 | Импортировать workflow | Workflow доступен |
| 6 | Настроить credentials | Telegram и GigaChat подключены |
| 7 | Активировать workflow | Workflow запущен |
| 8 | Отправить тестовый URL | Бот отвечает постом |

---

## Целевая архитектура

### Высокоуровневая схема

```
┌─────────────┐
│   Telegram  │
│   User      │
└──────┬──────┘
       │ URL статьи
       ▼
┌─────────────┐
│  Telegram   │
│  Bot API    │
└──────┬──────┘
       │ Webhook/Polling
       ▼
┌─────────────────────────────────────┐
│              n8n Workflow           │
│                                     │
│  [Trigger] → [Process] → [Response] │
│                                     │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────┐
│  GigaChat   │
│  API        │
└─────────────┘
```

### Инфраструктура

```
┌─────────────────────────────────────┐
│            VPS / Docker Host        │
│                                     │
│  ┌─────────────────────────────┐   │
│  │    Docker Compose           │   │
│  │                             │   │
│  │  ┌───────────────────────┐  │   │
│  │  │   n8n container        │  │   │
│  │  │   - port 5678          │  │   │
│  │  │   - volumes:           │  │   │
│  │  │     - n8n_data         │  │   │
│  │  │     - n8n_files        │  │   │
│  │  └───────────────────────┘  │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘

External dependencies:
- Telegram Bot API
- GigaChat API
```

### Отказ от ngrok

В публичной версии проекта ngrok не используется. Вместо этого:
- Развёртывание на VPS с публичным IP
- HTTPS через reverse proxy или облачный сервис
- Webhook URL настраивается через переменную окружения

---

## Состав n8n Workflow

### Архитектура workflow

Workflow состоит из линейной цепочки обработки с одной веткой обработки ошибки невалидного URL:

```
Telegram Trigger
       │
       ▼
 Prepare Input
       │
       ▼
   Check URL ───────[false]──→ Send Error Message
       │
      [true]
       │
       ▼
   Load Page
       │
       ▼
 Extract Article
       │
       ▼
   Clean Text
       │
       ▼
 Prepare Prompt
       │
       ▼
 Generate RqUID
       │
       ▼
 Get GigaChat Token
       │
       ▼
    GigaChat
       │
       ▼
  Send Message
```

### Ответственность нод

**Telegram Trigger**
- Назначение: Получение сообщений из Telegram
- Вход: Webhook/Polling от Telegram Bot API
- Выход: Message object с текстом и chat ID
- Обработка ошибок: Не требуется (триггер)

**Prepare Input**
- Назначение: Извлечение URL из сообщения
- Вход: Message object
- Выход: URL string
- Обработка ошибок: Валидация пустого сообщения

**Check URL**
- Назначение: Валидация формата URL
- Вход: URL string
- Выход: Boolean (valid/invalid)
- Обработка ошибок: Ветка false → Send Error Message

**Load Page**
- Назначение: Загрузка HTML-страницы
- Вход: URL string
- Выход: HTML content
- Обработка ошибок: Retry, timeout, HTTP errors

**Extract Article**
- Назначение: Извлечение текста статьи из HTML
- Вход: HTML content
- Выход: Article text (возможно с динамическим ключом)
- Обработка ошибок: Проверка пустого результата

**Clean Text**
- Назначение: Очистка текста от мусора, обрезка до лимита
- Вход: Article text
- Выход: Cleaned text
- Обработка ошибок: Проверка пустого результата, truncate

**Prepare Prompt**
- Назначение: Формирование промпта для GigaChat
- Вход: Cleaned text
- Выход: Prompt string
- Обработка ошибок: Не требуется

**Generate RqUID**
- Назначение: Генерация UUID для запроса к GigaChat
- Вход: Prompt string
- Выход: Prompt + RqUID
- Обработка ошибок: Не требуется

**Get GigaChat Token**
- Назначение: Получение access token для GigaChat API
- Вход: RqUID + credentials
- Выход: access_token
- Обработка ошибок: Retry, auth errors

**GigaChat**
- Назначение: Генерация структурированного поста
- Вход: access_token + prompt
- Выход: Generated post
- Обработка ошибок: Retry, API errors, timeout

**Send Message**
- Назначение: Отправка результата в Telegram
- Вход: Generated post + chat ID
- Выход: Success/Failure
- Обработка ошибок: Message length, API errors

**Send Error Message**
- Назначение: Отправка сообщения об ошибке
- Вход: Error message + chat ID
- Выход: Success/Failure
- Обработка ошибок: API errors

---

## Внешние интеграции

### Telegram Bot API

**Требования:**
- Valid Bot Token (от @BotFather)
- HTTPS endpoint для webhook (опционально)
- Или polling mode

**Endpoints:**
- getMe — проверка токена
- sendMessage — отправка сообщения
- setWebhook — установка webhook (опционально)

**Ограничения:**
- Maximum message length: 4096 characters
- Rate limits: 30 msg/sec to same chat

### GigaChat API

**Требования:**
- GigaChat API credentials (client_id, client_secret)
- Scope: GIGACHAT_API_PERS
- Valid RqUID для каждого запроса токена

**Endpoints:**
- /api/v2/oauth — получение access token
- /api/v1/chat/completions — генерация текста

**Параметры модели:**
- Model: GigaChat-2-Max
- Temperature: 0.1 (или из конфигурации)
- Token lifetime: ~30 minutes

---

## Требования к Docker/VPS/HTTPS-развёртыванию

### Docker Compose

**Требования:**
- Конфигурация n8n в Docker Compose
- Persistance данных через volumes
- Конфигурация через environment variables
- Возможность настройки webhook URL

### VPS Requirements

**Минимальные требования:**
- 1 CPU, 1 GB RAM, 10 GB disk
- Public IP
- Docker и Docker Compose установлены

**Рекомендуемые требования:**
- 2 CPU, 2 GB RAM, 20 GB disk
- Ubuntu 22.04 LTS

### HTTPS Setup

**Требования:**
- HTTPS для n8n endpoint
- Reverse proxy (Nginx, Caddy) или облачный сервис
- Let's Encrypt сертификаты

### Network Requirements

**Требования:**
- Outbound HTTPS to api.telegram.org
- Outbound HTTPS to ngw.devices.sberbank.ru:9443
- Outbound HTTPS to gigachat.devices.sberbank.ru
- Outbound HTTP/HTTPS для загрузки статей

**VPN Note:** В ограниченных сетях может потребоваться системный VPN.

---

## Требования к конфигурации и секретам

### Environment Variables

**Обязательные переменные:**
- N8N_BASIC_AUTH_USER — логин для n8n
- N8N_BASIC_AUTH_PASSWORD — пароль для n8n
- TELEGRAM_BOT_TOKEN — токен Telegram-бота
- GIGACHAT_AUTH_BASIC — credentials для GigaChat

**Опциональные переменные:**
- WEBHOOK_URL — публичный URL для webhook
- GIGACHAT_MODEL — название модели
- GIGACHAT_TEMPERATURE — температура модели
- MAX_TEXT_LENGTH — лимит длины текста
- MAX_PROMPT_LENGTH — лимит длины промпта

### n8n Credentials

**Telegram:**
- Credential type: Telegram API
- Required: Bot Token

**GigaChat:**
- Credential type: HTTP Header Auth (custom)
- Required: Authorization header

### Security Requirements

- Никогда не коммитить .env файлы
- Использовать сильные пароли
- Периодически ротировать credentials
- Использовать HTTPS для всех коммуникаций
- Рассмотреть IP whitelisting для admin interface

---

## Требования к обработке ошибок

### Категории ошибок

**1. User Input Errors**
- Invalid URL
- Empty message

**2. Network Errors**
- Page load timeout
- HTTP errors (404, 500)
- Connection errors

**3. Content Errors**
- Empty article
- Text too long

**4. GigaChat API Errors**
- Auth failed
- Token expired
- API unavailable
- Rate limit

**5. Telegram API Errors**
- Invalid chat ID
- Message too long
- Bot blocked

### Требования к сообщениям об ошибках

- Сообщения должны быть понятны пользователю
- Сообщения не должны содержать технические детали
- Сообщения должны предлагать действие (повторить, проверить URL, обратиться к администратору)

---

## Требования к Retry

### Retry Policy

**Load Page:**
- Retry на network errors
- Timeout configuration
- Максимум 3 attempts

**Get GigaChat Token:**
- Retry на auth errors
- Максимум 2 attempts

**GigaChat API:**
- Retry на API errors
- Timeout configuration
- Максимум 2 attempts

### Требования к реализации

- Exponential backoff между попытками
- Логирование retry attempts
- Graceful degradation при исчерпании retry

---

## Требования к логированию

### Log Levels

**INFO:**
- Workflow start/end
- URL received
- Page loaded successfully
- Token obtained
- GigaChat response received
- Message sent

**WARNING:**
- Retrying operation
- Text truncated

**ERROR:**
- Invalid URL
- Page load failed
- Article extraction failed
- GigaChat auth failed
- GigaChat API error
- Telegram send failed

### Требования к логам

- Timestamp
- Log level
- Workflow name
- Node name
- Message
- Context (url, chat_id, execution_id)

### Log Retention

- n8n execution history — configurable
- External logs (если configured) — 30 days
- Error logs — 90 days

---

## Требования к ограничению длины Telegram-сообщений

### Telegram API Limits

- Maximum message length: 4096 characters

### Handling Strategy

**Требования:**
- Проверка длины сообщения перед отправкой
- Разбиение длинных сообщений на части
- Respect word boundaries (не разрезать слова)
- Number parts: "Часть 1/N:", "Часть 2/N:", etc.
- Отправка частей последовательно

---

## Требования к воспроизводимости

### Deployment Validation Checklist

**Prerequisites:**
- Docker and Docker Compose installed
- Git installed
- Access to VPS or local Docker environment
- Telegram Bot Token obtained
- GigaChat API credentials obtained

**Deployment Steps:**
- Clone repository
- Copy .env.example to .env
- Fill environment variables
- Run docker-compose up -d
- Verify n8n is accessible
- Import workflow JSON
- Configure credentials
- Activate workflow
- Send test URL to bot
- Receive structured post

**Validation Tests:**
- Bot responds to valid URL
- Bot responds to invalid URL
- Bot handles page load error
- Bot handles GigaChat error
- Bot handles long article
- Bot handles long response

### Reproducibility Requirements

- Развёртывание на чистом Docker host
- Нет ручных шагов после .env конфигурации
- Нет скрытых зависимостей
- Все secrets в .env
- Все URLs configurable
- Version pinning для n8n

---

## Границы MVP

### Входит в MVP

✅ Telegram Trigger (On Message)
✅ URL validation
✅ Page loading
✅ Article extraction
✅ Text cleaning
✅ Prompt preparation
✅ GigaChat token acquisition
✅ GigaChat chat completion
✅ Telegram message sending
✅ Error message for invalid URL
✅ Docker Compose configuration
✅ .env.example
✅ Basic documentation
✅ Workflow JSON

### Не входит в MVP

❌ Retry mechanisms (кроме basic n8n retry)
❌ Advanced error handling (Error Trigger workflow)
❌ Message splitting для long responses
❌ Logging beyond n8n execution history
❌ Configuration variables для prompts
❌ Token caching
❌ Rate limiting
❌ Web interface
❌ Analytics

---

## Definition of Done

Проект считается завершённым, если выполнены все следующие критерии:

### Functional Requirements

- [ ] Бот принимает URL статьи из Telegram
- [ ] Бот валидирует URL
- [ ] Бот загружает страницу
- [ ] Бот извлекает текст статьи
- [ ] Бот очищает текст от мусора
- [ ] Бот формирует промпт
- [ ] Бот получает токен GigaChat
- [ ] Бот вызывает GigaChat API
- [ ] Бот отправляет результат в Telegram
- [ ] Бот отправляет сообщение об ошибке при невалидном URL
- [ ] Бот обрабатывает ошибки загрузки страницы
- [ ] Бот обрабатывает ошибки GigaChat API
- [ ] Бот разбивает длинные сообщения

### Non-Functional Requirements

- [ ] Workflow воспроизводимо импортируется в n8n
- [ ] Docker Compose конфигурация работает
- [ ] .env.example содержит все необходимые переменные
- [ ] Документация полная и актуальная

### Documentation Requirements

- [ ] README.md описывает проект
- [ ] docs/architecture.md описывает архитектуру
- [ ] docs/setup.md описывает установку
- [ ] docs/deployment_guide.md описывает развёртывание
- [ ] docs/workflow_overview.md описывает workflow
- [ ] docs/limitations.md описывает ограничения
- [ ] docs/known_issues.md описывает известные проблемы

### Deployment Requirements

- [ ] Проект разворачивается на чистом VPS
- [ ] Проект работает без ngrok
- [ ] Проект использует HTTPS
- [ ] Deployment Validation пройден успешно

### Quality Requirements

- [ ] Код соответствует стандартам проекта
- [ ] Документация не содержит ссылок на внутренние артефакты
- [ ] Проект самодостаточен для внешнего пользователя
- [ ] Нет захардкоженных секретов
- [ ] Все параметры документированы

### Delivery Requirements

- [ ] GitHub-репозиторий создан
- [ ] Ветка main содержит стабильную версию
- [ ] Тег v1.0.0 создан
- [ ] README.md содержит badges и описание
- [ ] LICENSE файл добавлен
- [ ] .gitignore настроен

---

## Версионирование SPEC

| Версия | Дата | Изменения |
|--------|------|-----------|
| 1.0 | 2026-07-08 | Начальная версия |
| 1.1 | 2026-07-08 | Переработка по методологии APL: удалены детали реализации, добавлен раздел Engineering Experiment, сокращён backlog |
| 1.2 | 2026-07-08 | Подготовка к публичации: удалены ссылки на внутренние документы, упрощён Definition of Done |

---

**Конец SPEC.md**