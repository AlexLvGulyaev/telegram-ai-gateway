# PROJECT STATE: Telegram AI Gateway

**Дата:** 2026-07-10
**Статус:** Production Ready
**Этап:** GitHub Publication Complete

---

## Версия n8n

**Текущая версия:** n8n 2.29.8 (stable)

**Docker image:** `docker.n8n.io/n8nio/n8n:2.29.8`

**Обоснование:**
- Версия 1.120.x содержит критическую регрессию frontend (ошибка ldap)
- n8n 2.29.8 — production-ready, включает все security patches
- Рекомендуется разработчиками n8n для новых self-hosted проектов

**Ключевые изменения в n8n 2.x:**
- Task runners включены по умолчанию (Code node изолирован)
- Environment variables заблокированы в Code nodes по умолчанию
- PostgreSQL user default изменился с `root` на `postgres`
- Требуется `CODE_ENABLE_STDOUT=true` для вывода console.log

Подробнее: [engineering-investigation-n8n-update.md](engineering-investigation-n8n-update.md)

---

## Source of Truth

**Основной workflow:** `workflows/Telegram AI Gateway.json`

**Log Writer workflow:** `workflows/Telegram AI Gateway - Log Writer.json`

**Статус:** ✅ Production Ready, GitHub Portfolio Edition

---

## Project Summary

**Название:** Telegram AI Gateway

**Тип:** Engineering-grade Telegram Bot

**Назначение:** Telegram-бот для автоматизированной переработки статей в структурированные посты для Telegram с использованием n8n и GigaChat API.

**Бизнес-идея:** Пользователь отправляет ссылку на статью в Telegram-бота. Бот автоматически загружает статью, очищает текст, формирует промпт, вызывает GigaChat API и возвращает структурированный пост для публикации в Telegram-канале.

**Позиционирование:** GitHub Portfolio Edition с высоким уровнем инженерной зрелости.

**Целевая аудитория:** Контент-менеджеры, редакторы Telegram-каналов, авторы, нуждающиеся в автоматизации переработки длинных статей в формат Telegram-постов.

---

## Current Status

**Статус проекта:** Production Ready (GitHub Edition)

**Текущий этап:** GitHub Publication Complete

**Готовность к публикации:** Deployment Validation пройден, документация актуальна, секреты защищены

---

## Architecture

### Выполненные архитектурные решения

#### 1. Minimal Provider Contract

**Реализовано:**
- Параметр `AI_PROVIDER` в Configuration node (значение: `gigachat`)
- Provider-independent имена параметров (LLM_MODEL, LLM_TEMPERATURE)
- Выделены GigaChat-specific nodes
- Точки подключения для будущих провайдеров

**Provider-specific nodes (GigaChat):**
- Generate RqUID — OAuth requirement
- Get GigaChat Token — OAuth endpoint
- Check Token — error handling
- GigaChat — Chat Completions API
- Check Response — error handling

#### 2. Content Source Abstraction

**Реализовано:**
- Параметр `CONTENT_SOURCE` в Configuration node (значение: `url`)
- Выделены URL-specific nodes

**URL-specific nodes:**
- Check URL (валидация формата URL)
- Load Page (HTTP GET по URL)
- Check Load Error
- Extract Article (HTML extraction)

#### 3. Extraction Strategy с Fallback

**Реализовано:**
- Code node с fallback-стратегией
- Приоритет селекторов: `article, main, .tm-article-body, .tm-content`
- Конфигурация: `EXTRACT_SELECTORS`

#### 4. Request Context / Correlation ID

**Реализовано:**
- Нода `Generate Request ID` после Telegram Trigger
- UUID v4 для каждого запроса
- request_id прокидывается через все ноды
- Используется в логировании и error handling

#### 5. Execution Logging

**Реализовано:**
- Отдельный Log Writer workflow
- PostgreSQL таблица workflow_logs
- Точки логирования на всех критических этапах
- Документация: [logging-integration-guide.md](logging-integration-guide.md)

---

## Configuration Node Structure

**Всего параметров:** 27 (5 групп)

### LLM Configuration (4 параметра)
- `LLM_MODEL` — модель GigaChat (GigaChat-2-Max)
- `LLM_TEMPERATURE` — температура модели (0.1)
- `LLM_SYSTEM_PROMPT` — system prompt
- `LLM_USER_PROMPT` — шаблон user prompt с placeholder {TEXT}

### Limits (3 параметра)
- `LIMIT_TEXT_LENGTH` — максимальная длина текста (12000)
- `LIMIT_PROMPT_LENGTH` — максимальная длина промпта (5000)
- `LIMIT_MESSAGE_LENGTH` — максимальная длина сообщения (4096)

### HTTP Settings (8 параметров)
- `HTTP_LOAD_TIMEOUT` — timeout загрузки страницы (30000ms)
- `HTTP_API_TIMEOUT` — timeout GigaChat API (60000ms)
- `HTTP_LOAD_RETRIES` — попытки загрузки (3)
- `HTTP_LOAD_RETRY_INTERVAL` — интервал retry загрузки (1000ms)
- `HTTP_TOKEN_RETRIES` — попытки токена (2)
- `HTTP_TOKEN_RETRY_INTERVAL` — интервал retry токена (500ms)
- `HTTP_API_RETRIES` — попытки GigaChat API (2)
- `HTTP_API_RETRY_INTERVAL` — интервал retry GigaChat (1000ms)

### Extraction (1 параметр)
- `EXTRACT_SELECTORS` — CSS селекторы для извлечения статьи ("article,main,.tm-article-body,.tm-content")

### User Messages (11 параметров)
- Пользовательские сообщения об ошибках на русском языке

---

## Components

### Workflows

**Main Workflow:** `workflows/Telegram AI Gateway.json`
- 39 nodes (28 основных + 11 Execute Workflow для логирования)
- Типы нод: Code (9), If (7), Telegram (6), HTTP Request (3), Set (2), Telegram Trigger (1), Execute Workflow (11)

**Log Writer Workflow:** `workflows/Telegram AI Gateway - Log Writer.json`
- 4 nodes
- Назначение: Запись логов в PostgreSQL

### Database

**PostgreSQL 15:**
- Хранит credentials n8n
- Хранит execution history
- Хранит workflow definitions
- Хранит таблицу workflow_logs

**Migrations:**
- `migrations/001_create_workflow_logs.sql` — создание таблицы workflow_logs
- `migrations/002_alter_workflow_logs_created_at.sql` — добавление поля created_at

---

## Status History

| Дата | Статус | Комментарий |
|------|--------|--------------|
| 2026-07-08 | Workflow восстановлен | Исходный workflow PEn04 восстановлен по скриншотам и описаниям |
| 2026-07-08 | E2E Testing | Workflow протестирован вручную |
| 2026-07-08 | Error Handling | Добавлена полноценная обработка ошибок |
| 2026-07-08 | Engineering Maturity | Конфигурируемость, стандартизация |
| 2026-07-08 | Architecture Polish | Логическая группировка, терминология |
| 2026-07-08 | Execution Logging | Добавлен Log Writer workflow |
| 2026-07-10 | Deployment Validation | Проект развёрнут и протестирован на чистом окружении |
| 2026-07-10 | GitHub Publication | Документация актуализирована, секреты защищены |

---

## Known Issues and Limitations

См. [known_issues.md](known_issues.md) и [limitations.md](limitations.md)

---

## Market Validation

См. [SPEC.md](SPEC.md) — раздел "Целевая аудитория" и "Позиционирование"

---

## Commercial Assessment

См. [SPEC.md](SPEC.md) — раздел "Бизнес-идея"

---

## Key Technology Areas

- n8n workflow engine (v2.29.8)
- PostgreSQL database (v15)
- Docker Compose deployment
- Telegram Bot API integration
- GigaChat API integration (OAuth + Chat Completions)
- Error handling и retry mechanisms
- Execution logging
- Configuration management

---

## Decision

Проект готов к публикации на GitHub как демонстрационный AI MVP с высоким уровнем инженерной зрелости.

---

## Next Steps

Нет запланированных следующих этапов. Проект в статусе Production Ready.

---

## Documentation

- [SPEC.md](SPEC.md) — Продуктовая спецификация
- [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) — План реализации
- [architecture.md](architecture.md) — Архитектура проекта
- [workflow_overview.md](workflow_overview.md) — Обзор workflow
- [deployment_guide.md](deployment_guide.md) — Руководство по развёртыванию
- [logging-integration-guide.md](logging-integration-guide.md) — Интеграция логирования
- [known_issues.md](known_issues.md) — Известные проблемы
- [limitations.md](limitations.md) — Ограничения проекта