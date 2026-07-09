# Telegram AI Gateway

Production-ready Telegram-бот для автоматизированной переработки статей в структурированные посты с использованием n8n и GigaChat API.

[![n8n Version](https://img.shields.io/badge/n8n-2.29.8-blue)](https://docs.n8n.io/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

---

## Версия n8n

**Текущая версия:** n8n 2.29.8 (stable)

**Обоснование:**
- Версия 1.120.x содержит критическую регрессию frontend (ошибка ldap)
- n8n 2.29.8 — production-ready, включает все security patches
- Рекомендуется разработчиками n8n для новых self-hosted проектов

**Docker image:** `docker.n8n.io/n8nio/n8n:2.29.8`

Подробнее: [docs/engineering-investigation-n8n-update.md](docs/engineering-investigation-n8n-update.md)

---

## Возможности

### Основные функции

- ✅ Приём URL статьи из Telegram
- ✅ Загрузка и извлечение текста статьи
- ✅ Очистка текста от мусора
- ✅ Генерация структурированного поста через GigaChat API
- ✅ Отправка результата в Telegram
- ✅ Обработка длинных сообщений (разбиение на части)

### Error Handling

- ✅ Полноценная обработка ошибок на всех этапах
- ✅ Детальные пользовательские сообщения на русском языке
- ✅ Логирование ошибок с контекстом
- ✅ Retry механизмы для сетевых запросов

### Обработка ошибок

**Load Page Errors:**
- DNS errors → "Ошибка DNS. Проверьте правильность домена в URL."
- Timeout → "Превышено время ожидания. Проверьте доступность сайта."
- SSL errors → "Ошибка SSL-сертификата."
- 404 → "Страница не найдена (404). Проверьте правильность URL."
- 403 → "Доступ запрещён (403). Страница недоступна для чтения."
- 500 → "Ошибка сервера (500). Попробуйте позже."
- Connection refused → "Сервер недоступен."

**OAuth Token Errors:**
- 401/403/network → "Ошибка авторизации в сервисе. Обратитесь к администратору."

**GigaChat API Errors:**
- 400 → "Ошибка в запросе к AI-сервису. Попробуйте упростить текст."
- 401 → "Ошибка авторизации в AI-сервисе."
- 429 → "Превышен лимит запросов. Попробуйте через минуту."
- 500+ → "AI-сервис временно недоступен. Попробуйте позже."

**Invalid URL:**
- Не URL → "Пожалуйста, отправьте корректную ссылку на статью."

**Empty Content:**
- Нет текста → "Не удалось извлечь текст из статьи."

### Retry Policy

- Load Page: 3 попытки, интервал 1000ms
- Get GigaChat Token: 2 попытки, интервал 500ms
- GigaChat: 2 попытки, интервал 1000ms

Retry применяется только к сетевым и временным ошибкам, **не** к ошибкам пользователя.

### Логирование

Структурированное логирование через `console.log` в Code нодах:

- `[Clean Text]` — обработка текста
- `[Generate RqUID]` — генерация UUID
- `[Split Message]` — разбиение сообщений
- `[Load Page Error]` — ошибки загрузки
- `[Auth Error]` — ошибки авторизации
- `[GigaChat Error]` — ошибки API

Для включения: `CODE_ENABLE_STDOUT=true` в docker-compose.yml

---

## Быстрый старт

### Требования

- Docker
- Docker Compose
- Telegram Bot Token (от [@BotFather](https://t.me/botfather))
- GigaChat API credentials

### Установка

1. **Клонируйте репозиторий:**

```bash
git clone https://github.com/your-username/telegram-ai-gateway.git
cd telegram-ai-gateway
```

2. **Создайте файл конфигурации:**

```bash
cp .env.example .env
```

3. **Настройте переменные окружения:**

Отредактируйте `.env`:

```env
# n8n credentials
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your_secure_password

# Telegram Bot Token
TELEGRAM_BOT_TOKEN=your_telegram_bot_token

# GigaChat credentials (Base64 encoded: client_id:client_secret)
GIGACHAT_AUTH_BASIC=your_base64_credentials

# Enable logging
CODE_ENABLE_STDOUT=true
```

4. **Запустите проект:**

```bash
docker-compose up -d
```

5. **Откройте n8n:**

```
http://localhost:5678
```

6. **Импортируйте workflow:**

   ```bash
   # Примените миграции БД
   docker exec -i telegram-ai-gateway-postgres psql -U n8n -d n8n < migrations/001_create_workflow_logs.sql
   docker exec -i telegram-ai-gateway-postgres psql -U n8n -d n8n < migrations/002_alter_workflow_logs_created_at.sql
   ```

7. **Настройте credentials:**

   Следуйте инструкциям в [Deployment Guide](docs/deployment_guide.md):

   - Telegram Bot API credential
   - GigaChat Basic Auth credential
   - PostgreSQL credential (для Log Writer)

8. **Активируйте workflow:**

   - Откройте workflow в n8n
   - Нажмите кнопку "Active"

9. **Отправьте URL в Telegram-бота:**

```
https://example.com/article
```

---

## Конфигурация

### Переменные окружения

Полный список переменных в `.env.example`:

| Переменная | Описание | Обязательная |
|-----------|---------|-------------|
| `N8N_BASIC_AUTH_USER` | Логин для n8n | Да |
| `N8N_BASIC_AUTH_PASSWORD` | Пароль для n8n | Да |
| `POSTGRES_PASSWORD` | Пароль PostgreSQL | Да |
| `TELEGRAM_BOT_TOKEN` | Токен Telegram-бота | Да |
| `GIGACHAT_AUTH_KEY` | GigaChat credentials (Base64) | Да |
| `WEBHOOK_URL` | URL для webhook (пусто для polling) | Нет |

**Важно:** Переменные `GIGACHAT_MODEL`, `MAX_TEXT_LENGTH`, `MAX_PROMPT_LENGTH`, `MAX_MESSAGE_LENGTH`, `SYSTEM_PROMPT`, `USER_PROMPT_TEMPLATE` **НЕ ИСПОЛЬЗУЮТСЯ** в текущей версии. Параметры заданы в Code node "Configuration" внутри workflow.

### Workflow Configuration

Все параметры workflow заданы в Code node "Configuration":

- `LLM_MODEL`: GigaChat-2-Max
- `LLM_TEMPERATURE`: 0.1
- `LIMIT_TEXT_LENGTH`: 12000
- `LIMIT_PROMPT_LENGTH`: 5000
- `LIMIT_MESSAGE_LENGTH`: 4096
- `LLM_SYSTEM_PROMPT`: (захардкожен в workflow)
- `LLM_USER_PROMPT`: (захардкожен в workflow)

Для изменения параметров отредактируйте Code node "Configuration" в n8n workflow editor.

### Credentials

Workflow требует три credentials:

1. **Telegram Bot API** — для Telegram Trigger и Send Message
2. **Header Auth** — для GigaChat Basic Auth
3. **PostgreSQL** — для Log Writer (подключение к БД)

См. [Deployment Guide](docs/deployment_guide.md) для детальных инструкций.

### Миграции БД

После первого запуска примените миграции:

```bash
docker exec -i telegram-ai-gateway-postgres psql -U n8n -d n8n < migrations/001_create_workflow_logs.sql
docker exec -i telegram-ai-gateway-postgres psql -U n8n -d n8n < migrations/002_alter_workflow_logs_created_at.sql
```

См. [Deployment Guide](docs/deployment_guide.md) для полного руководства.

---

## Архитектура

```
Telegram User
      │
      ▼
Telegram Bot API
      │
      ▼
n8n Workflow (Docker)
      │
      ├─→ [Telegram Trigger]
      │         │
      │         ▼
      │   [Prepare Input] ──→ извлечение URL
      │         │
      │         ▼
      │   [Check URL] ──[false]──→ [Send Error (Invalid URL)]
      │         │ [true]
      │         ▼
      │   [Load Page] ──[error]──→ [Check Load Error]
      │         │                         │
      │         ▼                         ▼
      │   [Extract Article]          [Format Load Error]
      │         │                         │
      │         ▼                         ▼
      │   [Clean Text]              [Send Error (Load)]
      │         │
      │         ▼
      │   [Check Text] ──[false]──→ [Send Error (Extract)]
      │         │ [true]
      │         ▼
      │   [Prepare Prompt]
      │         │
      │         ▼
      │   [Generate RqUID]
      │         │
      │         ▼
      │   [Get GigaChat Token] ──[error]──→ [Check Token]
      │         │                                │
      │         ▼                                ▼
      │   [Check Token] ──[false]──→      [Format Auth Error]
      │         │ [true]                       │
      │         ▼                              ▼
      │   [GigaChat] ──[error]──→         [Send Error (Auth)]
      │         │                                │
      │         ▼                                ▼
      │   [Check Response] ──[false]──→ [Format API Error]
      │         │ [true]                       │
      │         ▼                              ▼
      │   [Split Message]               [Send Error (API)]
      │         │
      │         ▼
      │   [Send Message]
      │
      ▼
Telegram User
```

Подробнее: [docs/architecture.md](docs/architecture.md)

---

## Workflow

Workflow состоит из 19 основных нод + 9 нод для обработки ошибок = 28 нод.

### Основные ноды

1. **Telegram Trigger** — получение сообщений
2. **Prepare Input** — извлечение URL
3. **Check URL** — валидация URL
4. **Load Page** — загрузка HTML
5. **Check Load Error** — проверка ошибок загрузки
6. **Extract Article** — извлечение текста
7. **Clean Text** — очистка текста
8. **Check Text** — проверка наличия текста
9. **Prepare Prompt** — формирование промпта
10. **Generate RqUID** — генерация UUID
11. **Get GigaChat Token** — получение токена
12. **Check Token** — проверка токена
13. **GigaChat** — генерация поста
14. **Check Response** — проверка ответа
15. **Split Message** — разбиение длинных сообщений
16. **Send Message** — отправка результата

### Ноды обработки ошибок

17. **Send Error (Invalid URL)** — ошибка невалидного URL
18. **Format Load Error** — форматирование ошибки загрузки
19. **Send Error (Load)** — отправка ошибки загрузки
20. **Send Error (Extract)** — отправка ошибки извлечения
21. **Format Auth Error** — форматирование ошибки авторизации
22. **Send Error (Auth)** — отправка ошибки авторизации
23. **Format API Error** — форматирование ошибки API
24. **Send Error (API)** — отправка ошибки API

Подробнее: [docs/workflow_overview.md](docs/workflow_overview.md)

---

## Документация

- [Architecture](docs/architecture.md) — архитектура проекта
- [Setup Guide](docs/setup.md) — инструкция по установке
- [Deployment Guide](docs/deployment_guide.md) — руководство по развёртыванию
- [Credentials Setup](docs/credentials-setup.md) — детальная настройка credentials
- [Workflow Overview](docs/workflow_overview.md) — обзор workflow
- [Logging Integration](docs/logging-integration-guide.md) — интеграция логирования
- [Limitations](docs/limitations.md) — ограничения проекта
- [Known Issues](docs/known_issues.md) — известные проблемы

---

## Ограничения

- Максимальная длина сообщения Telegram: 4096 символов
- Максимальная длина текста статьи: 12000 символов
- Максимальная длина промпта: 5000 символов
- Требуется системный VPN для работы в ограниченных сетях
- GigaChat API token действителен ~30 минут

Подробнее: [docs/limitations.md](docs/limitations.md)

---

## Известные проблемы

- Не все статьи корректно извлекаются (зависит от структуры HTML)
- GigaChat API может возвращать ошибки при высокой нагрузке
- Telegram Bot API имеет лимиты на количество сообщений

Подробнее: [docs/known_issues.md](docs/known_issues.md)

---

## Развитие проекта

### Текущий статус: Production-ready

**Завершено:**
- ✅ Workflow восстановлен и протестирован (E2E)
- ✅ Полноценная обработка ошибок
- ✅ Retry механизмы
- ✅ Логирование
- ✅ Удалена служебная подпись n8n
- ✅ Разбиение длинных сообщений

### Планируемые улучшения

- [ ] Token caching для GigaChat API
- [ ] Structured logging в PostgreSQL
- [ ] Web interface для мониторинга
- [ ] Rate limiting
- [ ] Поддержка нескольких ботов
- [ ] Webhook security (Telegram signature verification)

---

## Статус проекта

**Версия:** 2.0 (GitHub Edition — Error Handling Complete)

**Дата последнего обновления:** 2026-07-08

**Workflow JSON:** `workflows/Telegram AI Gateway.json`

**Backup:** `Telegram AI Gateway.before-error-handling.json`

**Source of Truth:** Workflow экспортирован напрямую из n8n после успешного E2E тестирования

---

## Лицензия

MIT License. См. [LICENSE](LICENSE).

---

## Автор

AI Automation Portfolio Lab

---

**Связь:** Создайте Issue в репозитории для вопросов и предложений.