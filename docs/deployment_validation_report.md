# ✅ Telegram AI Gateway · Deployment Validation Report

Отчёт о фактическом прогоне Deployment Validation. Процедура и чеклист — [Deployment Guide](deployment_guide.md), §8.

> ⚠️ **Актуальность:** прогон выполнен 2026-07-09 по версии пакета до структурной реорганизации документации 2026-09-16. Процедуры развёртывания при реорганизации не изменялись (разделы переехали без правки команд), но по правилу «изменение DEPLOYMENT_GUIDE → повторная Validation» после реорганизации требуется повторный прогон в чистом окружении.

## 📋 1. Сводка

| Параметр | Значение |
|----------|----------|
| Дата | 2026-07-09 |
| Окружение | VPS, Docker Compose, n8n 2.29.8, PostgreSQL 15 |
| Метод | Deployment Validation + ручное тестирование через Telegram Bot API |
| Infrastructure Validation | ✅ PASSED |
| Integration Validation | ✅ PASSED |
| Использованы реальные credentials | Telegram Bot Token, GigaChat credentials (факт, без публикации значений) |

## 🧪 2. Уровни проверки

### Infrastructure Validation — ✅ PASSED

Проверено в изолированном контуре без внешних зависимостей: запуск Docker Compose, healthy-статус контейнеров (PostgreSQL, n8n), применение миграций, импорт workflows, ответы health endpoints. Real credentials не требовались.

### Integration Validation — ✅ PASSED

Проверено с реальными сервисами: создание трёх credentials в n8n (Telegram Bot API, GigaChat Basic Auth, PostgreSQL), активация обоих workflows, работа polling/webhook, ответ GigaChat API, запись журнала в PostgreSQL, полный пользовательский сценарий (URL → пост).

Результаты функционального тестирования (таблица негативных сценариев, подтверждённые маршруты журнала, непроверенный Timeout) — [architecture.md](architecture.md), §8.

## 🧾 3. Наблюдения из прогона

### 3.1. Имена nodes в n8n

**Наблюдение:** на n8n 2.29.8 после импорта workflow через CLI webhook не работал, пока имя Telegram Trigger node содержало пробел («Telegram Trigger»). После переименования без пробела («TelegramTrigger») webhook заработал.

**Статус:** ⚠️ Наблюдение (факт эксперимента, не универсальное правило). Возможная причина — URL-encoding и сопоставление webhook path при CLI-импорте; для подтверждения требуется контролируемый эксперимент.

**Локальная практика:** имена нод, создающих webhook paths, — без пробелов. Проверка:

```bash
docker exec telegram-ai-gateway-postgres psql -U n8n -d n8n -c "SELECT * FROM webhook_entity WHERE \"webhookPath\" LIKE '%\%20%';"
```

Если есть записи с `%20` — рассмотреть переименование node (не считать критической ошибкой без дополнительной проверки).

### 3.2. Docker сеть для Traefik

**Наблюдение:** в этом проекте с Traefik reverse proxy контейнеры не работали без подключения к сети `n8n_default`.

**Статус:** ⚠️ Локальное наблюдение (специфика проектов с Traefik).

**Решение:**

```bash
docker network connect n8n_default telegram-ai-gateway-n8n
docker network connect n8n_default telegram-ai-gateway-postgres
```

### 3.3. Экранирование `$` в Docker Compose

**Наблюдение:** пароль с символами `$` (`$$$`) в .env не работал.

**Статус:** ✅ Подтверждённое правило (только для `$`): значения с `$` в .env для Docker Compose требуют экранирования — `$$` в файле → `$` в контейнере. НЕ является общим запретом на спецсимволы (`\`, `"`, `'` требуют отдельной проверки).

**Рекомендация:**

```env
# Рекомендуется буквенно-цифровой пароль
POSTGRES_PASSWORD=PostgresPass123

# Или корректное экранирование $
POSTGRES_PASSWORD=Pass$$word
```

Если пароль уже содержит спецсимволы: изменить пароль в БД (`ALTER USER n8n WITH PASSWORD '...'`) либо пересоздать volumes (`docker compose down -v` — удаляет все данные).

---

**Статус:** Прогон 2026-07-09 — PASSED; после реорганизации документации 2026-09-16 требуется повторный прогон (чеклист — Deployment Guide §8)
**Последнее обновление:** 2026-09-16
**История изменений:** [📝 CHANGE_LOG.md](CHANGE_LOG.md#-1-история-изменений-документации)