# ✅ Telegram AI Gateway · Deployment Validation Report

Отчёт о фактическом прогоне Deployment Validation. Процедура и чеклист — [Deployment Guide](deployment_guide.md), §8.

> ⚠️ **Актуальность:** в отчёте три прогона. Повторный прогон 2026-09-16 после правки гайда — **PASSED** (полный цикл URL → пост, GigaChat с включенной проверкой сертификата). Первый прогон 2026-09-16 (после реорганизации документации) — **Integration FAILED**: выявлена неработоспособность polling-режима, DEPLOYMENT_GUIDE правлен по результатам. Прогон 2026-07-09 (исторический) — PASSED.

## ✅ Прогон 2026-09-16 (повторный, после правки DEPLOYMENT_GUIDE) — PASSED

### Сводка

| Параметр | Значение |
|----------|----------|
| Дата | 2026-09-16 (второй виток, после правки гайда и подключения CA Минцифры) |
| Окружение | Отдельный Docker-стек на VPS (compose-проект `taig-dv-r2`, свежий клон коммита 4c1d612 + фикс 766c0cd, чистые volumes), Integration — через HTTPS-домен прода (прод на паузе) |
| Infrastructure Validation | ✅ PASSED |
| Integration Validation | ✅ PASSED — полный пользовательский сценарий URL → пост через Telegram |

### Пройдено

- **Infrastructure:** все проверки первого прогона плюс новые: `NODE_EXTRA_CA_CERTS` установлен из compose, бандл CA (2 сертификата) смонтирован в контейнер, миграции 001/002, импорт обоих workflow (IDs сохранены).
- **Integration:** 3 credentials (CLI), активация обоих workflow — **без «Bad request»** (в отличие от первого прогона: `WEBHOOK_URL` с HTTPS-доменом), webhook зарегистрирован в Telegram (`last_error: none`), полный прогон по тестовому URL: все 6 этапов журнала SUCCESS (REQUEST_RECEIVED → PAGE_LOADED → TEXT_EXTRACTED → TOKEN_RECEIVED → LLM_COMPLETED → WORKFLOW_FINISHED), пост доставлен боту. Вызов GigaChat выполнен **с включенной проверкой сертификата** (`allowUnauthorizedCerts: false` + CA Минцифры) — main-результат витка подключения CA.

### Отклонения от гайда

| № | Действие | Комментарий |
|---|----------|-------------|
| 1 | Credentials и активация через CLI (как в первом прогоне) | Гайдовый UI-путь headless-методикой не проверен; root cause первого прогона устранён правкой гайда |
| 2 | Подключение n8n-контейнера к сети reverse-proxy (`docker network connect n8n_default`) | Известное наблюдение 3.2 (июль): на этом VPS reverse-proxy маршрутизирует через общую сеть. Воспроизвелось на повторном прогоне — кандидат в гайд как environment-specific шаг |
| 3 | `WEBHOOK_URL` = домен прода | Инфраструктура VPS: HTTPS-домен обслуживается reverse-proxy этого хоста; после остановки прода тот же домен ведёт на валидационный экземпляр |

### Наблюдения повторного прогона

- **As-built дрейф №2 — webhookId Telegram Trigger.** В живом прода у триггера задан `webhookId: "telegram-webhook"` (путь без `%20`), в репо-JSON отсутствовал — CLI-импорт строил путь из workflowId/имени ноды с пробелом, Telegram получал 404 (это же объясняет июльское наблюдение 3.1). Репо выровнен под живой workflow (коммит 766c0cd).
- **Compose-проект по имени каталога.** Клон в каталоге `telegram-ai-gateway` подхватывает project name `telegram-ai-gateway` и садится на тома одноимённого прода — изоляция требует `COMPOSE_PROJECT_NAME` (обнаружено по ошибке авторизации БД; тома прода не пострадали). Дополнительно: `COMPOSE_PROJECT_NAME` в `.env` не срабатывает, если строка оказалась приклеена к комментарию (append без перевода строки).
- **`*.pem` в .gitignore** исключил `certs/ca-bundle.pem` из первого коммита; Docker создал пустой каталог вместо отсутствующего файла монтирования. Добавлено исключение `!certs/ca-bundle.pem`.
- **`n8n import:workflow` на запущенном n8n сбрасывает флаг Active** — после реимпорта требуется реактивация + рестарт.
- **healthz отвечает JSON `{"status":"ok"}`**, а не текст «OK» из гайда §4.
- **CLI-пути:** `n8n import:workflow --input` требует путь, видимый внутри контейнера (docker cp в `/tmp`); `--separate` предназначен для каталога, не файла.

## 🔁 Прогон 2026-09-16 (первый, после реорганизации документации) — Integration FAILED

### Сводка первого прогона

| Параметр | Значение |
|----------|----------|
| Дата | 2026-09-16 |
| Основание | Правило «изменение DEPLOYMENT_GUIDE → повторная Validation» после реорганизации (коммиты e20df75, 9d43c14) |
| Окружение | Отдельный Docker-стек на существующем VPS (compose-проект `taig-dv`, свежий клон 9d43c14, чистые volumes, порт 5679) |
| Infrastructure Validation | ✅ PASSED |
| Integration Validation | ❌ FAILED (активация main workflow в polling-режиме) |
| Использованы реальные credentials | Telegram Bot Token, GigaChat credentials (факт, без публикации значений) |

**Примечание об окружении:** правило «Validation в чистом окружении» соблюдено в объёме стека: свежий клон, чистые volumes (`taig-dv_*`), изолированная compose-сеть, отдельный порт — ни одна сущность валидационного экземпляра не пересекалась с продом. VPS при этом не новый: для освобождения фиксированных имён контейнеров (`container_name` в compose) прод-стек был остановлен на время прогона и восстановлен после. Полноценный прогон на новом VPS остаётся критерием для повторного прогона.

### Infrastructure Validation — ✅ PASSED

Выполнено по гайду (§4, чеклист §8) в первом прогоне:

- [x] Клон репозитория, `.env` создан (`cp .env.example .env`; пароли сгенерированы; placeholder-значения Telegram/GigaChat; `N8N_PORT=5679` — документированная переменная, 5678 занят другим стеком хоста)
- [x] `docker compose up -d` — оба контейнера healthy
- [x] `curl localhost:5679/healthz` → OK
- [x] PostgreSQL: `SELECT 1;` через `docker exec`
- [x] `n8n list:workflow` внутри контейнера — доступ к БД подтверждён
- [x] Миграции 001 и 002 применены; `\d workflow_logs` — структура соответствует
- [x] Оба workflow импортированы (`n8n import:workflow`; ID из репозиторийных JSON сохранены — `wW8hk2AUrwFbfRkY`, `ZKavjvDKoohBhWcj` — связи нод с credentials сошлись автоматически)

### Integration Validation — ❌ FAILED

Пройдено в первом прогоне:

- [x] Credentials созданы в n8n: Telegram Bot API, Header Auth (GigaChat), PostgreSQL — через `n8n import:credentials` (см. Отклонение №1); существование и структура проверены `n8n export:credentials --all --decrypted` (значения нигде не выводились)
- [x] Telegram Bot Token валиден (проверка `getMe` через Telegram Bot API — бот отвечает, имя совпадает с задокументированным)
- [x] Оба workflow активированы флагом (`n8n update:workflow --active=true` + restart n8n; см. Отклонение №2) — Log Writer активировался успешно
- [ ] **Активация main workflow — FAIL:** n8n фиксирует активацию в БД (после рестарта — «Activated workflow "Telegram AI Gateway"»), но Telegram Trigger не регистрируется: лог содержит `Bad request - please check your parameters`; сообщения боту не доставляются

**Root cause (доказан):** Telegram Trigger в n8n при активации workflow всегда регистрирует webhook через `setWebhook` (независимо от наличия `WEBHOOK_URL`) и не имеет polling-фоллбэка. Telegram API принимает только HTTPS-адреса — при пустом `WEBHOOK_URL` регистрация отклоняется с ошибкой «An HTTPS URL must be provided for webhook». Root cause установлен по debug-логу n8n (`N8N_LOG_LEVEL=debug`) и воспроизведён прямым вызовом `setWebhook` с http:// и https:// адресами (https принят, http отклонён). **Вывод: описанный в гайде режим polling (`WEBHOOK_URL=` пустое) для данного workflow неработоспособен — активация невозможна.**

GigaChat-путь end-to-end в этом прогоне не проверен: активация main workflow не состоялась, до вызова LLM прогон не дошёл. Боковая проверка TLS из контейнера (node fetch к `ngw.devices.sberbank.ru:9443`) дала `SELF_SIGNED_CERT_IN_CHAIN` — это артефакт методики проверки, а не дефект: в workflow у обеих GigaChat-HTTP-нод включён `allowUnauthorizedCerts: true` (n8n «Allow Unauthorized Certs»), и вызовы n8n проходят без системного доверия к цепочке (прод подтверждает: успешные прогоны в день валидации). Наблюдение безопасности — ниже, 3.4.

### Отклонения от гайда первого прогона (действия вне DEPLOYMENT_GUIDE)

| № | Действие в прогоне | Что вместо этого в гайде | Комментарий |
|---|--------------------|--------------------------|-------------|
| 1 | Credentials созданы CLI: `n8n import:credentials --input=...` | Создание через UI ([credentials-setup.md](credentials-setup.md)) | Гайдовый путь headless-методикой не проверен и не опровергнут; CLI-путь потребовался из-за отсутствия браузера в прогоне |
| 2 | Активация CLI: `n8n update:workflow --active=true` + рестарт n8n | Тумблер **Active** в UI (§4.5, §8) | Аналогично: UI-путь не проверен; но root cause (HTTPS-требование Telegram) от UI не зависит — активация в polling-режиме падает любым способом |
| 3 | `N8N_LOG_LEVEL=debug` в .env | Не описано | Только для диагностики root cause; дефект диагностирован по stack trace в логе |
| 4 | Прямые вызовы `setWebhook` для доказательства root cause | Не описано | Диагностика после FAIL, не часть развёртывания |
| 5 | Публичный REST API n8n (`/api/v1/credentials`) — 401 без `X-N8N-API-KEY` | Не описано | API-ключ создаётся в UI; headless-путь к CLI (Отклонение №1) |
| 6 | Остановка прод-стека (`docker compose down` без `-v`, volumes сохранены) | Не описано | Следствие фиксированных `container_name` в compose: два стека на одном Docker-хосте конфликтуют по именам. Для прогона на том же хосте требуется остановка прода |

### Наблюдения первого прогона 2026-09-16

- **Порт:** при наличии на хосте других n8n-стеков используется документированная переменная `N8N_PORT` (в прогоне — 5679).
- **Log Writer: метка времени.** Все записи прогона (REQUEST_RECEIVED → WORKFLOW_FINISHED) несут одинаковый `created_at`, передаваемый из main workflow, — метки не отражают фактическое время каждого этапа (важно при разборе задержек по журналу).
- **Безопасность TLS:** обе GigaChat-ноды ходят в API Сбера с отключенной проверкой сертификата (`allowUnauthorizedCerts: true`) — трафик уязвим к MITM; системное доверие к цепочке российского корневого CA в контейнере отсутствует. *(Устранено вторым витком того же дня: CA Минцифры через `NODE_EXTRA_CA_CERTS`, `allowUnauthorizedCerts: false`, проверено повторным прогоном.)*

---

## 📋 Прогон 2026-07-09 — PASSED

### Сводка

| Параметр | Значение |
|----------|----------|
| Дата | 2026-07-09 |
| Окружение | VPS, Docker Compose, n8n 2.29.8, PostgreSQL 15 |
| Метод | Deployment Validation + ручное тестирование через Telegram Bot API |
| Infrastructure Validation | ✅ PASSED |
| Integration Validation | ✅ PASSED |
| Использованы реальные credentials | Telegram Bot Token, GigaChat credentials (факт, без публикации значений) |

### Уровни проверки

**Infrastructure Validation — ✅ PASSED**

Проверено в изолированном контуре без внешних зависимостей: запуск Docker Compose, healthy-статус контейнеров (PostgreSQL, n8n), применение миграций, импорт workflows, ответы health endpoints. Real credentials не требовались.

**Integration Validation — ✅ PASSED**

Проверено с реальными сервисами: создание трёх credentials в n8n (Telegram Bot API, GigaChat Basic Auth, PostgreSQL), активация обоих workflows, работа webhook, ответ GigaChat API, запись журнала в PostgreSQL, полный пользовательский сценарий (URL → пост).

Результаты функционального тестирования (таблица негативных сценариев, подтверждённые маршруты журнала, непроверенный Timeout) — [architecture.md](architecture.md), §8.

### Наблюдения из прогона 2026-07-09

#### Имена nodes в n8n

**Наблюдение:** на n8n 2.29.8 после импорта workflow через CLI webhook не работал, пока имя Telegram Trigger node содержало пробел («Telegram Trigger»). После переименования без пробела («TelegramTrigger») webhook заработал.

**Статус:** ⚠️ Наблюдение (факт эксперимента, не универсальное правило). Возможная причина — URL-encoding и сопоставление webhook path при CLI-импорте; для подтверждения требуется контролируемый эксперимент.

**Локальная практика:** имена нод, создающих webhook paths, — без пробелов. Проверка:

```bash
docker exec telegram-ai-gateway-postgres psql -U n8n -d n8n -c "SELECT * FROM webhook_entity WHERE \"webhookPath\" LIKE '%\%20%';"
```

Если есть записи с `%20` — рассмотреть переименование node (не считать критической ошибкой без дополнительной проверки).

#### Docker сеть для Traefik

**Наблюдение:** в этом проекте с Traefik reverse proxy контейнеры не работали без подключения к сети `n8n_default`.

**Статус:** ⚠️ Локальное наблюдение (специфика проектов с Traefik).

**Решение:**

```bash
docker network connect n8n_default telegram-ai-gateway-n8n
docker network connect n8n_default telegram-ai-gateway-postgres
```

#### Экранирование `$` в Docker Compose

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

**Статус:** Повторный прогон 2026-09-16 — PASSED (полный цикл URL → пост, GigaChat с включенной проверкой сертификата); первый прогон 2026-09-16 — Integration FAILED (root cause устранён правкой Deployment Guide); Прогон 2026-07-09 — PASSED (исторический)
**Последнее обновление:** 2026-09-16
**История изменений:** [📝 CHANGE_LOG.md](CHANGE_LOG.md#-1-история-изменений-документации)