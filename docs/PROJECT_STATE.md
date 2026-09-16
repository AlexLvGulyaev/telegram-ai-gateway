# 📊 Telegram AI Gateway · PROJECT_STATE

Паспорт состояния проекта. Точка входа для любого агента, который начинает работу с кейсом.

---

## 🎯 1. Project Summary

**Название:** Telegram AI Gateway

**Тип:** Engineering-grade Telegram Bot (n8n workflow, Docker Compose, PostgreSQL)

**Назначение:** Telegram-бот для автоматизированной переработки статей в структурированные посты для Telegram с использованием n8n и GigaChat API.

**Бизнес-идея:** Пользователь отправляет ссылку на статью в Telegram-бота. Бот автоматически загружает статью, очищает текст, формирует промпт, вызывает GigaChat API и возвращает структированный пост для публикации в Telegram-канале.

**Позиционирование:** GitHub Portfolio Edition с высоким уровнем инженерной зрелости.

---

## 📊 2. Current Status

**Статус проекта:** Production Ready (GitHub Edition)

**Текущий этап:** GitHub Publication Complete

**Готовность:** Deployment Validation пройдена, документация актуальна, секреты защищены.

**Source of Truth:**
- Основной workflow: `workflows/Telegram AI Gateway.json` (39 nodes: 28 основных + 11 Execute Workflow для логирования)
- Log Writer workflow: `workflows/Telegram AI Gateway - Log Writer.json` (4 nodes)

**Известные проблемы и ограничения:** [limitations.md](limitations.md)

---

## 🔍 3. Market Validation

Рыночная валидация внешними заказчиками не проводилась: проект создавался как учебно-демонстрационный для портфолио, а не под конкретный заказ.

Рыночный сигнал, на который опирается кейс: автоматизация переработки статей в посты — типовой запрос контент-менеджеров, редакторов Telegram-каналов и авторов (позиционирование и аудитория — [SPEC.md](SPEC.md)).

---

## 💰 4. Commercial Assessment

Коммерческая оценка не проводилась: кейс позиционирован как учебно-демонстрационный (см. [SPEC.md](SPEC.md) — раздел «Бизнес-идея»).

Портфельная ценность: демонстрация компетенций интеграции n8n, GigaChat API и Telegram Bot API, включая обработку ошибок, retry-механизмы и журналирование исполнения в PostgreSQL.

---

## 🏗️ 5. Architecture

Реализованные архитектурные решения (суть, обоснования и отклонённые альтернативы — [architecture.md](architecture.md), §7):

1. **Minimal Provider Contract** — параметр `AI_PROVIDER`, provider-independent имена параметров, выделенные GigaChat-specific nodes.
2. **Content Source Abstraction** — параметр `CONTENT_SOURCE`, выделенные URL-specific nodes.
3. **Extraction Strategy с Fallback** — приоритет CSS-селекторов, конфигурация `EXTRACT_SELECTORS`.
4. **Request Context / Correlation ID** — `request_id` (UUID v4) прокидывается через все ноды.
5. **Execution Logging** — отдельный Log Writer workflow, таблица `workflow_logs` в PostgreSQL ([architecture.md](architecture.md), §6).

---

## 🧮 6. Configuration Node Structure

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

## 🧩 7. Components

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

## 🔧 8. Key Technology Areas

- n8n workflow engine (v2.29.8, stable)
- PostgreSQL database (v15)
- Docker Compose deployment
- Telegram Bot API integration
- GigaChat API integration (OAuth + Chat Completions)
- Error handling и retry mechanisms
- Execution logging
- Configuration management

---

## ✅ 9. Decision

Проект готов к публикации на GitHub как демонстрационный AI MVP с высоким уровнем инженерной зрелости. Публикация выполнена 2026-07-10.

---

## 🚀 10. Next Steps

Нет запланированных этапов развития: проект в статусе Production Ready. Кандидаты на будущие улучшения (принимаются по мере потребности):

**Ближайшие:** улучшение извлечения текста для разных сайтов (селекторы, stop markers); задержка между отправками частей сообщения.

**Следующие версии:** token caching для GigaChat; rate limiting для пользователей; мониторинг и alerting; поддержка нескольких ботов.

**Долгосрочные:** JavaScript-рендеринг для сложных сайтов; queue system для высокой нагрузки; web interface для мониторинга; webhook security (Telegram signature verification).

---

## 📜 11. Status History

| Дата | Статус | Комментарий |
|------|--------|--------------|
| 2026-07-08 | Workflow восстановлен | Исходный workflow восстановлен по скриншотам и описаниям |
| 2026-07-08 | E2E Testing | Workflow протестирован вручную |
| 2026-07-08 | Error Handling | Добавлена полная обработка ошибок |
| 2026-07-08 | Engineering Maturity | Конфигурируемость, стандартизация |
| 2026-07-08 | Architecture Polish | Логическая группировка, терминология |
| 2026-07-08 | Execution Logging | Добавлен Log Writer workflow |
| 2026-07-10 | Deployment Validation | Проект развёрнут и протестирован на чистом окружении |
| 2026-07-10 | GitHub Publication | Документация актуализирована, секреты защищены |

---

## 📚 12. Documentation

Маршрут по документации: [README.md](../README.md) — карта «какой документ для какого вопроса».

---

**Статус:** Production Ready
**Последнее обновление:** 2026-09-16
**История изменений:** [📝 CHANGE_LOG.md](CHANGE_LOG.md#-1-история-изменений-документации)