# SPEC: Telegram AI Gateway

**Версия:** 1.2
**Дата:** 2026-07-10
**Статус:** Implemented

---

## Назначение проекта

Telegram AI Gateway — демонстрационный AI MVP, реализующий Telegram-бота для автоматизированной переработки статей в структурированные посты для Telegram.

**Бизнес-идея:** Пользователь отправляет ссылку на статью в Telegram-бота. Бот автоматически загружает статью, очищает текст, формирует промпт, вызывает GigaChat API и возвращает структурированный пост для публикации в Telegram-канале.

**Целевая аудитория:** Контент-менеджеры, редакторы Telegram-каналов, авторы, нуждающиеся в автоматизации переработки длинных статей в формат Telegram-постов.

**Позиционирование:** Учебно-демонстрационный проект для портфолио, иллюстрирующий интеграцию n8n, GigaChat API и Telegram Bot API.

---

## Реализованный функционал

### Основной сценарий

**Вход:** Пользователь отправляет URL статьи в Telegram-бота

**Обработка:**
1. Валидация URL (regex)
2. Загрузка веб-страницы (HTTP Request с retry)
3. Извлечение текста статьи (HTML extraction с fallback)
4. Очистка текста от мусора (stop markers)
5. Формирование промпта для GigaChat
6. Получение токена GigaChat API (OAuth)
7. Генерация структурированного поста (Chat Completions)
8. Разбиение длинных сообщений (до 4096 символов)
9. Отправка результата в Telegram

**Выход:** Структурированный пост для Telegram-канала

### Обработка ошибок

**Реализовано:**
- Валидация URL с пользовательским сообщением об ошибке
- Retry-механизмы для HTTP requests (3 попытки для Load Page, 2 для GigaChat)
- Обработка ошибок загрузки страницы (DNS, timeout, SSL, 404, 403, 500)
- Обработка ошибок GigaChat API (400, 401, 429, 500)
- Обработка ошибок извлечения текста
- Пользовательские сообщения об ошибках на русском языке

### Логирование

**Реализовано:**
- Отдельный Log Writer workflow
- PostgreSQL таблица workflow_logs
- Request ID для корреляции логов
- Точки логирования на всех критических этапах
- Документация: [logging-integration-guide.md](logging-integration-guide.md)

### Конфигурация

**Реализовано:**
- Configuration node с параметрами
- Provider-independent именование (LLM_MODEL, LLM_TEMPERATURE)
- Вынос промптов в переменные
- Вынос пользовательских сообщений в переменные

---

## Архитектура

### Workflows

**Main Workflow:** `workflows/Telegram AI Gateway.json`
- 39 nodes (28 основных + 11 Execute Workflow для логирования)
- Триггер: Telegram Trigger (On Message)
- Обработка: линейный pipeline с error handling
- Логирование: Execute Workflow nodes на критических этапах

**Log Writer Workflow:** `workflows/Telegram AI Gateway - Log Writer.json`
- 4 nodes
- Назначение: запись логов в PostgreSQL
- Вход: JSON с данными события
- Выход: подтверждение записи

### Компоненты

**Telegram Integration:**
- Telegram Trigger (On Message)
- Send Message nodes

**GigaChat Integration:**
- Generate RqUID (OAuth requirement)
- Get GigaChat Token (OAuth)
- Check Token (error handling)
- GigaChat (Chat Completions API)
- Check Response (error handling)

**Content Processing:**
- Check URL (validation)
- Load Page (HTTP Request)
- Check Load Error (error handling)
- Extract Article (Code node с fallback)
- Check Text (validation)
- Clean Text (stop markers)
- Prepare Prompt (Set node)

**Message Handling:**
- Split Message (до 4096 символов)
- Send Message (Telegram node)

**Error Handling:**
- Format Load Error
- Format Auth Error
- Format API Error
- Send Error Message

**Logging:**
- Generate Request ID
- Execute Workflow nodes (11 штук)

### База данных

**PostgreSQL 15:**
- Хранит credentials n8n
- Хранит execution history
- Хранит workflow definitions
- Хранит таблицу workflow_logs

**Миграции:**
- `migrations/001_create_workflow_logs.sql`
- `migrations/002_alter_workflow_logs_created_at.sql`

---

## Параметры

### LLM Configuration

| Параметр | Значение | Описание |
|----------|---------|----------|
| `AI_PROVIDER` | `gigachat` | AI провайдер |
| `CONTENT_SOURCE` | `url` | Источник контента |
| `LLM_MODEL` | `GigaChat-2-Max` | Модель GigaChat |
| `LLM_TEMPERATURE` | `0.1` | Температура модели |
| `LLM_SYSTEM_PROMPT` | (см. workflow) | System prompt |
| `LLM_USER_PROMPT` | (см. workflow) | User prompt template |

### Limits

| Параметр | Значение | Описание |
|----------|---------|----------|
| `LIMIT_TEXT_LENGTH` | `12000` | Максимальная длина текста |
| `LIMIT_PROMPT_LENGTH` | `5000` | Максимальная длина промпта |
| `LIMIT_MESSAGE_LENGTH` | `4096` | Максимальная длина сообщения |

### HTTP Settings

| Параметр | Значение | Описание |
|----------|---------|----------|
| `HTTP_LOAD_TIMEOUT` | `30000` | Timeout загрузки страницы (ms) |
| `HTTP_API_TIMEOUT` | `60000` | Timeout GigaChat API (ms) |
| `HTTP_LOAD_RETRIES` | `3` | Попытки загрузки |
| `HTTP_LOAD_RETRY_INTERVAL` | `1000` | Интервал retry загрузки (ms) |
| `HTTP_TOKEN_RETRIES` | `2` | Попытки токена |
| `HTTP_TOKEN_RETRY_INTERVAL` | `500` | Интервал retry токена (ms) |
| `HTTP_API_RETRIES` | `2` | Попытки GigaChat API |
| `HTTP_API_RETRY_INTERVAL` | `1000` | Интервал retry GigaChat (ms) |

### Extraction

| Параметр | Значение | Описание |
|----------|---------|----------|
| `EXTRACT_SELECTORS` | `article,main,.tm-article-body,.tm-content` | CSS селекторы для извлечения |

### User Messages

Все пользовательские сообщения об ошибках на русском языке (см. Configuration node в workflow)

---

## Требования к развёртыванию

### Docker Compose

**Сервисы:**
- n8n (версия 2.29.8)
- PostgreSQL 15

**Переменные окружения:**
- `POSTGRES_PASSWORD` — пароль PostgreSQL
- `N8N_BASIC_AUTH_USER` — пользователь n8n admin
- `N8N_BASIC_AUTH_PASSWORD` — пароль n8n admin
- `TELEGRAM_BOT_TOKEN` — токен Telegram-бота
- `GIGACHAT_AUTH_KEY` — Base64-encoded GigaChat credentials
- `WEBHOOK_URL` — URL для webhook (опционально)

### Credentials

**Telegram Bot API:**
- Bot Token от @BotFather

**GigaChat API:**
- client_id и client_secret от developers.sber.ru
- Base64 encoding: `echo -n "client_id:client_secret" | base64`

**n8n Admin:**
- Basic Auth для доступа к n8n UI

### Миграции

**Применяются автоматически при первом запуске:**
- Создание таблицы workflow_logs
- Добавление поля created_at

---

## Документация

| Документ | Назначение |
|----------|-----------|
| [README.md](../README.md) | Описание проекта, quick start |
| [architecture.md](architecture.md) | Архитектура проекта |
| [workflow_overview.md](workflow_overview.md) | Обзор workflow |
| [deployment_guide.md](deployment_guide.md) | Руководство по развёртыванию |
| [logging-integration-guide.md](logging-integration-guide.md) | Интеграция логирования |
| [known_issues.md](known_issues.md) | Известные проблемы |
| [limitations.md](limitations.md) | Ограничения проекта |
| [credentials-setup.md](credentials-setup.md) | Настройка credentials |

---

## Известные ограничения

См. [limitations.md](limitations.md)

---

## Известные проблемы

См. [known_issues.md](known_issues.md)

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
| 3 | Generate Request ID создаёт UUID | request_id для логирования |
| 4 | Prepare Input извлекает URL | URL передаётся далее |
| 5 | Check URL проверяет валидность | Если валиден → переход к шагу 7 |
| 6 | Если URL невалиден → Send Error Message | Пользователь получает сообщение об ошибке |
| 7 | Load Page загружает HTML | HTML получен (с retry) |
| 8 | Extract Article извлекает текст | Текст статьи извлечён (с fallback) |
| 9 | Check Text проверяет длину | Если текст > 100 символов → переход к шагу 11 |
| 10 | Если текст короткий → Send Error Message | Пользователь получает сообщение об ошибке |
| 11 | Clean Text очищает текст | Очищенный текст |
| 12 | Prepare Prompt формирует промпт | Промпт готов |
| 13 | Generate RqUID создаёт UUID | RqUID для GigaChat |
| 14 | Get GigaChat Token получает токен | access_token получен (с retry) |
| 15 | Check Token проверяет токен | Если токен валиден → переход к шагу 17 |
| 16 | Если токен невалиден → Send Error Message | Пользователь получает сообщение об ошибке |
| 17 | GigaChat генерирует пост | JSON с ответом (с retry) |
| 18 | Check Response проверяет ответ | Если ответ валиден → переход к шагу 20 |
| 19 | Если ответ невалиден → Send Error Message | Пользователь получает сообщение об ошибке |
| 20 | Split Message разбивает ответ | Сообщения до 4096 символов |
| 21 | Send Message отправляет результат | Пользователь получает пост |

**Альтернативные потоки:**

- Ошибка загрузки страницы → Send Error Message с описанием ошибки
- Ошибка извлечения текста → Send Error Message
- Ошибка GigaChat API → Send Error Message с описанием ошибки
- Ошибка отправки в Telegram → логирование ошибки

---

## Метрики успеха

| Метрика | Значение | Критерий |
|---------|----------|----------|
| Время выполнения | 5-30 секунд | Типичное время обработки |
| Успешные запросы | >90% | При корректных URL |
| Retry success rate | >95% | При временных ошибках |
| Message length compliance | 100% | Сообщения ≤4096 символов |
| Logging coverage | 100% | Все критические этапы логируются |

---

## Дальнейшее развитие

**Возможные улучшения (не в текущей версии):**

- Добавление других AI провайдеров (OpenAI, Anthropic)
- Token caching для оптимизации
- Rate limiting по пользователям
- Мониторинг и алертинг
- Horizontal scaling

---

## Критерии готовности

✅ Workflow реализован и протестирован
✅ Обработка ошибок реализована
✅ Retry-механизмы реализованы
✅ Логирование реализовано
✅ Configuration node создана
✅ Документация написана
✅ Deployment Validation пройден
✅ Секреты защищены