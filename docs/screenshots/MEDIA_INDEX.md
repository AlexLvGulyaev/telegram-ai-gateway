# 🖼️ Telegram AI Gateway · MEDIA_INDEX

> 📌 **SOT:** Архитектурные схемы реализуются в Mermaid внутри Markdown (см.
> [architecture.md](../architecture.md)) — это не изображения и здесь не
> каталогируются. Здесь — только растровые медиа (скриншоты Telegram-диалогов,
> workflow в n8n, витринные иллюстрации).

> ⚠️ **Публичный ресурс:** эти скриншоты публикуются в репозитории. Персональных
> данных не содержат: диалоги показывают обработку публичных ссылок на статьи.

---

## 🎯 1. Назначение

MEDIA_INDEX — единый каталог медиаматериалов проекта. Каждое изображение
объясняет конкретный тезис документа; скриншоты не вставляются «потому что есть».

---

## 📐 2. Схема нейминга

Формат: `TGW_{CATEGORY}_{DESCRIPTION}.{ext}` — для скриншотов продукта;
`taig-portfolio-{light|dark}.png` — для витринных hero-иллюстраций.

Префикс `TGW` — Telegram AI Gateway (workflow).

| Категория | Назначение | Пример |
|-----------|------------|--------|
| `tg` | Диалог в Telegram (успех, ошибки) | `TGW_tg_valid.png` |
| `flow` | Workflow в n8n (основной, Log Writer) | `TGW_main_workflow.png` |
| `portfolio` | Витринные hero-иллюстрации ai-portfolio | `taig-portfolio-light.png` |

> ❌ Архитектурные схемы (`arch`) — в Mermaid внутри Markdown, не PNG.
> См. [architecture.md](../architecture.md) §1–2.

---

## 🗂️ 3. Размещение

```text
docs/
└── screenshots/
    ├── MEDIA_INDEX.md              # Этот каталог
    ├── TGW_tg_*.png                # Диалоги Telegram: успех, ошибки
    ├── TGW_main_workflow.png       # Основной workflow (39 нод)
    ├── TGW_log_workflow.png        # Log Writer workflow (4 ноды)
    └── taig-portfolio-*.png        # Витринные hero-иллюстрации
```

Каталог `docs/screenshots/` — публичный, входит в репозиторий и публикуется на
GitHub.

---

## 📋 4. Каталог изображений

| ID | Файл | Категория | Тезис | Используется в |
|----|------|-----------|-------|----------------|
| 1 | `TGW_tg_valid.png` | `tg` | Успешная обработка: пользователь отправляет ссылку на статью — бот возвращает структурированный пост, готовый к публикации | `README.md` (Демо), `docs/user_guide.md` (Как пользоваться) |
| 2 | `TGW_tg_errors.png` | `tg` | Обработка ошибок: внятные сообщения на русском — система различает DNS-ошибки, HTTP-статусы (404, 403, 500), SSL-проблемы и ошибки AI-сервиса | `README.md` (Демо), `docs/user_guide.md` (Сообщения об ошибках) |
| 3 | `TGW_main_workflow.png` | `flow` | Основной workflow в n8n (39 нод): маршрут Telegram Trigger → Load Page → Extract Article → Clean Text → GigaChat → Split Message → Send Message с Check-нодами ошибок | Служебное свидетельство (см. §5) |
| 4 | `TGW_log_workflow.png` | `flow` | Log Writer workflow (4 ноды): Execute Workflow → Log Writer → PostgreSQL; каждый этап с `request_id` | Служебное свидетельство (см. §5) |
| 5 | `taig-portfolio-light.png` | `portfolio` | Витрина кейса LIGHT (1672×941) — hero-иллюстрация README и карточки кейса на витрине ai-portfolio | `README.md` (hero LIGHT), Витрина ai-portfolio |
| 6 | `taig-portfolio-dark.png` | `portfolio` | Та же витрина DARK — hero-иллюстрация architecture и тёмная тема карточки кейса | `docs/architecture.md` (hero DARK), Витрина ai-portfolio |

---

## 🧩 5. Матрица использования по документам

| Документ | Категории медиа |
|----------|-----------------|
| `README.md` | `portfolio` (hero LIGHT), `tg` — витрина, диалоги успеха и ошибок (Демо) |
| `docs/architecture.md` | `portfolio` (hero DARK) — архитектурная витрина |
| `docs/user_guide.md` | `tg` — шаги пользователя и сообщения об ошибках |
| Витрина ai-portfolio | `portfolio` — hero-иллюстрация карточки кейса |
| `flow`-скриншоты | Служебные свидетельства реализации: не привязаны к текущим документам слоя 1–2 (в README не используются по решению владельца) |

> Принцип: изображения в слоях 1–2 — только продуктовые (`tg`, `portfolio`).
> `flow`-скриншоты — инженерные доказательства; они остаются в каталоге, но
> вставляются в документ только если документ объясняет тезис «как устроено
> внутри» (см. [architecture.md](../architecture.md), §3).

---

## ✅ 6. Принцип выбора изображений

1. Определить тезис документа/раздела.
2. Определить, что требует визуализации.
3. Подобрать изображение, максимально помогающее понять тезис.
4. Если подходящего изображения нет — **не вставлять**.

---

## 📚 7. Связанные документы

- [🌐 `README.md`](../../README.md)
- [📖 `docs/user_guide.md`](../user_guide.md)
- [🏗️ `docs/architecture.md`](../architecture.md) — архитектурные схемы в Mermaid.

---

**Статус:** актуален; скриншоты — human-in-the-loop, соответствие подписям проверяет человек
**Последнее обновление:** 2026-09-16
**История изменений:** [📝 CHANGE_LOG.md](../CHANGE_LOG.md#-1-история-изменений-документации)