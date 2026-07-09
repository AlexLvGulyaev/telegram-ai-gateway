# Architecture Decisions: Telegram AI Gateway

**Версия:** 1.0
**Дата:** 2026-07-08
**Статус:** В разработке

---

## Цель документа

Зафиксировать архитектурные решения с обоснованием для будущего развития проекта.

---

## Решение 1: Minimal Provider Contract

### Проблема

Текущая реализация жёстко привязана к GigaChat. Добавление новых провайдеров требует дублирования workflow.

### Варианты

#### Вариант A: Полная абстракция с Provider Adapter Pattern

**Описание:**
Создать абстрактный Provider Interface и отдельные adapter для каждого провайдера.

**Структура:**
```
[Provider Interface]
├── prepare_request(text, config) → request
├── execute_request(request) → response
├── parse_response(response) → content
└── handle_error(error) → user_message

[Provider Adapters]
├── GigaChat Adapter
├── OpenAI Adapter
└── Anthropic Adapter
```

**Преимущества:**
- Полная абстракция
- Легко добавлять новых провайдеров
- Изолированная логика каждого провайдера

**Недостатки:**
- Сложная реализация в n8n
- Требует создания нескольких sub-workflows
- Усложняет debugging

**Почему отклонён:**
- Избыточная сложность для текущего состояния проекта
- n8n не поддерживает полиморфизм нативно
- Требует значительной перестройки workflow

---

#### Вариант B: Minimal Provider Contract ✅

**Описание:**
Определить минимальный контракт и точки подключения, не создавая полной абстракции.

**Контракт AI Provider:**

**Вход (Provider-Independent):**
```json
{
  "cleaned_text": "string",
  "request_id": "uuid",
  "configuration": {
    "ai_provider": "string",
    "llm_model": "string",
    "llm_temperature": "number",
    "llm_system_prompt": "string",
    "llm_user_prompt": "string"
  }
}
```

**Выход (Provider-Independent):**
```json
{
  "generated_content": "string",
  "provider_used": "string",
  "request_id": "uuid"
}
```

**Точки подключения:**
- Before Provider: Prepare Prompt node
- Provider Entry: Если-Then-Else по AI_PROVIDER
- Provider Exit: После Check Response
- After Provider: Split Message node

**Provider-Specific Nodes:**

**GigaChat (current):**
- Generate RqUID — OAuth requirement
- Get GigaChat Token — OAuth
- Check Token — error handling
- GigaChat — Chat Completions API
- Check Response — error handling

**OpenAI (future):**
- OpenAI Auth — API key auth (simpler)
- OpenAI Chat Completions — Chat API
- Check Response — error handling

**Anthropic (future):**
- Anthropic Auth — API key auth
- Anthropic Messages — Messages API
- Check Response — error handling

**Преимущества:**
- Минимальные изменения в текущем workflow
- Чёткие границы между слоями
- Понятная точка расширения
- Легко добавить нового провайдера

**Недостатки:**
- Требует дублирования веток для разных провайдеров
- Нет полной абстракции

**Почему выбран:**
- Баланс между абстракцией и сложностью
- Минимальные изменения в workflow
- Понятная точка расширения для будущих провайдеров
- Не нарушает текущий E2E сценарий

---

### Преимущества через 6 месяцев

**Через 6 месяцев:**

1. **Добавление OpenAI:**
   - Добавить branch после Provider Entry Point
   - Реализовать OpenAI-specific nodes
   - Не менять остальной workflow

2. **Добавление Anthropic:**
   - Аналогично OpenAI
   - Не менять GigaChat branch

3. **Смена провайдера:**
   - Изменить `AI_PROVIDER` в Configuration
   - Не менять workflow nodes

4. **A/B Testing:**
   - Добавить logic для выбора провайдера по критериям
   - Не менять provider branches

5. **Fallback Logic:**
   - Добавить fallback с одного провайдера на другой
   - Провайдерно-независимая обработка ошибок

---

## Решение 2: Source-Independent Content Processing

### Проблема

Текущая цепочка Load → Extract → Clean → Prompt не чётко разделена на слои.

Непонятно:
- Какие этапы зависят от источника
- Какие этапы можно переиспользовать
- Как добавить новые источники

### Варианты

#### Вариант A: Source-Independent Content Processing ✅

**Описание:**
Разделить на два слоя:
1. Source Acquisition (source-specific)
2. Content Processing (source-independent)

**Структура:**
```
[Content Source Layer] — Source-specific
├── Content Source Detection
│   └── Input: { "content_source": "url | text | pdf | file" }
│
├── URL Source Branch
│   ├── Load Page (HTTP GET)
│   └── Extract Article (HTML extraction)
│
├── Text Source Branch (future)
│   └── Validate Text
│
├── PDF Source Branch (future)
│   └── Extract PDF
│
└── File Source Branch (future)
    └── Extract File

[Content Processing Layer] — Source-independent
├── Clean Text
├── Check Text
└── Prepare Prompt
```

**Вход Content Source Layer:**
```json
{
  "request_id": "uuid",
  "content_source": "url | text | pdf | file",
  "content_data": "string (URL or text) | binary (file)"
}
```

**Выход Content Source Layer:**
```json
{
  "request_id": "uuid",
  "raw_content": "string (HTML or text)",
  "content_source": "string",
  "metadata": {
    "source_type": "url | text | pdf | file",
    "acquisition_time_ms": "number"
  }
}
```

**Вход Content Processing Layer:**
```json
{
  "request_id": "uuid",
  "raw_content": "string",
  "configuration": { ... }
}
```

**Выход Content Processing Layer:**
```json
{
  "request_id": "uuid",
  "cleaned_text": "string",
  "prompt": "string",
  "metadata": {
    "original_length": "number",
    "cleaned_length": "number",
    "truncated": "boolean"
  }
}
```

**Reusable компоненты:**

**Полностью reusable:**
- Clean Text — не зависит от источника
- Check Text — не зависит от источника
- Prepare Prompt — не зависит от источника

**Source-specific:**
- Load Page — только для URL
- Extract Article — только для HTML (URL)

**Для будущих источников:**
- Validate Text — для Text source
- Extract PDF — для PDF source
- Extract File — для File source

**Преимущества:**
- Чёткое разделение ответственности
- Source-independent processing
- Легко добавлять новые источники

**Недостатки:**
- Требует переработки Extract node
- Может нарушить текущий E2E сценарий

---

#### Вариант B: Unified Pipeline с Conditional Stages

**Описание:**
Единая цепочка, где некоторые этапы условные.

**Структура:**
```
[Input]
    ↓
[Content Source Detection]
    ↓
[Source Acquisition Branch]
├── URL Branch (Load → Extract)
├── Text Branch (Validate)
├── PDF Branch (Extract)
└── File Branch (Extract)
    ↓
[Unified Content Processing]
├── Clean Text
├── Check Text
└── Prepare Prompt
```

**Преимущества:**
- Минимальные изменения в workflow
- Чёткие границы
- Понятные точки расширения

**Недостатки:**
- Требует условной логики
- Может усложнить workflow

---

### Выбранное решение: Source-Independent Content Processing

**Почему выбрано:**
- Чёткое разделение ответственности
- Лучшая архитектура для расширения
- Понятные точки подключения

**Почему отклонён Unified Pipeline:**
- Менее чёткое разделение ответственности
- Source-Independent даёт лучшую архитектуру для расширения

---

### Преимущества через 6 месяцев

**Через 6 месяцев:**

1. **Добавление Text Source:**
   - Добавить branch после Content Source Detection
   - Реализовать Validate Text node
   - Не менять Content Processing Layer

2. **Добавление PDF Source:**
   - Добавить branch
   - Реализовать Extract PDF node
   - Не менять Content Processing Layer

3. **Улучшение Extract Article:**
   - Добавить новые fallback selectors
   - Не менять остальной workflow

4. **Изменение Clean Text:**
   - Улучшить алгоритм очистки
   - Применяется ко всем источникам
   - Не менять source-specific nodes

---

## Решение 3: Workflow Layering (8 слоёв)

### Проблема

Workflow растёт, становится сложнее понимать архитектуру и сопровождать.

### Варианты

#### Вариант A: 8 слоёв ✅

**Структура:**

1. **Input Layer** — получение входящих данных и подготовка контекста
2. **Configuration Layer** — предоставление конфигурации для всех слоёв
3. **Validation Layer** — валидация входящих данных
4. **Content Acquisition Layer** — получение контента из источника
5. **Content Processing Layer** — преобразование raw content в обработанный текст
6. **AI Provider Layer** — генерация контента через AI API
7. **Response Handling Layer** — подготовка и отправка ответа пользователю
8. **Error Handling Layer** — обработка ошибок на всех слоях

**Преимущества:**
- Чёткое разделение ответственности
- Понятные точки расширения
- Локализация изменений
- Reusable components на границах слоёв

**Недостатки:**
- Может показаться избыточным для малого проекта

---

#### Вариант B: 4 слоя

**Структура:**

1. **Input Layer**
2. **Processing Layer**
3. **AI Layer**
4. **Output Layer**

**Преимущества:**
- Простота
- Меньше слоёв

**Недостатки:**
- Слишком грубое разделение
- Не отражает реальную структуру
- Сложнее локализовать изменения

---

### Выбранное решение: 8 слоёв

**Почему выбрано:**
- Чёткое разделение ответственности
- Отражает реальную структуру workflow
- Понятные точки расширения

**Почему отклонён 4 слоя:**
- Слишком грубые, не отражают реальную структуру
- 8 слоёв дают чёткое разделение ответственности

---

### Преимущества через 6 месяцев

**Через 6 месяцев:**

1. **Понимание архитектуры новыми разработчиками:**
   - Чёткие границы между слоями
   - Понятные точки расширения
   - Локализация изменений

2. **Чёткие точки расширения:**
   - Каждый слой имеет понятные входы и выходы
   - Добавление функциональности в одном слое не затрагивает другие

3. **Локализация изменений:**
   - Изменения в Content Processing не затрагивают AI Provider
   - Изменения в Error Handling не затрагивают Input Layer

4. **Reusable components на границах слоёв:**
   - Prompt Builder — между Content Processing и AI Provider
   - Split Message — между AI Provider и Response Handling
   - Error Formatter — в Error Handling Layer

---

## Решение 4: Reusable Components Identification

### Проблема

Необходимо определить, какие части workflow разумно превратить в reusable components.

### Варианты

#### Вариант A: Вынести все компоненты сразу

**Преимущества:**
- Максимальное переиспользование
- Чёткая модуляризация

**Недостатки:**
- Преждевременная абстракция
- Усложнение без реальной потребности
- Может создать ненужные зависимости

**Почему отклонён:**
- Преждевременная абстракция — зло
- Необходимо понять реальные потребности переиспользования
- Усложняет текущую архитектуру без необходимости

---

#### Вариант B: Определить кандидатов, но не выносить ✅

**Преимущества:**
- Понимание reusable потенциала без усложнения
- Гибкость для будущих решений
- Не усложнённая текущая архитектура

**Недостатки:**
- Требует ручного копирования пока
- Нет немедленного переиспользования

**Почему выбран:**
- Преждевременная абстракция — зло
- Необходимо понять реальные потребности переиспользования
- Гибкость для будущих решений

---

### Выбранное решение: Определить кандидатов, но не выносить

**Кандидаты для future reusable components:**

#### 1. Prompt Builder Component

**Текущее место:** Prepare Prompt node

**Функция:** Формирование промпта из шаблона и текста

**Reusable потенциал:** ✅ Высокий

**Обоснование:**
- Провайдерно-независимый
- Не зависит от источника контента
- Может использоваться в других workflow

---

#### 2. Split Message Component

**Текущее место:** Split Message node

**Функция:** Разбиение длинного текста на части по границам слов

**Reusable потенциал:** ✅ Высокий

**Обоснование:**
- Не зависит от провайдера
- Не зависит от источника
- Не зависит от frontend (Telegram)
- Может использоваться в других workflow с другими ограничениями длины

---

#### 3. Error Formatter Component

**Текущее место:** Format Load Error, Format Auth Error, Format API Error nodes

**Функция:** Преобразование ошибки в пользовательское сообщение

**Reusable потенциал:** ✅ Высокий

**Обоснование:**
- Провайдерно-независимый
- Не зависит от источника
- Может использоваться в других workflow
- Конфигурируемые сообщения

---

#### 4. Load Strategy Component

**Текущее место:** Load Page node

**Функция:** Загрузка контента с retry и error handling

**Reusable потенциал:** ⚠️ Средний

**Обоснование:**
- Специфичен для HTTP загрузки
- Может использоваться в других workflow с HTTP
- Не зависит от провайдера и источника

---

#### 5. Extraction Strategy Component

**Текущее место:** Extract Article node

**Функция:** Извлечение текста из HTML с fallback selectors

**Reusable потенциал:** ⚠️ Средний

**Обоснование:**
- Специфичен для HTML
- Может использоваться в других workflow с HTML extraction
- Fallback strategy полезна в других контекстах

---

#### 6. Provider Adapter Pattern (future)

**Потенциальное место:** AI Provider Layer

**Функция:** Унифицированный интерфейс для разных AI провайдеров

**Reusable потенциал:** ✅ Высокий

**Обоснование:**
- Полностью абстрагирует провайдера
- Может использоваться в любом workflow с AI
- Легко добавлять новых провайдеров

**Статус:** ⏳ Future candidate (требует реализации)

---

### Преимущества через 6 месяцев

**Через 6 месяцев:**

1. **Понимание reusable потенциала:**
   - Чётко определены кандидаты
   - Понятны границы каждого компонента
   - Известны зависимости

2. **Готовые кандидаты для выноса:**
   - Prompt Builder — для других AI workflow
   - Split Message — для других Telegram bots
   - Error Formatter — для других workflow с ошибками

3. **Не усложнённая текущая архитектура:**
   - Нет преждевременной абстракции
   - Гибкость для будущих решений
   - Возможность пересмотреть кандидатов

---

## Отложенные решения

### 1. Реализация Provider Adapter Pattern

**Отложено до:** Phase 3 или позже

**Обоснование:**
- Требует появления реальной потребности в новых провайдерах
- Преждевременная абстракция без реальной потребности
- Minimal Provider Contract достаточен для текущих задач

---

### 2. Вынос Reusable Components

**Отложено до:** Появления второго workflow с потребностью в reuse

**Обоснование:**
- Преждевременная абстракция — зло
- Необходимо понять реальные потребности переиспользования
- Может создать ненужные зависимости

---

### 3. Реализация новых Content Sources

**Отложено до:** Появления реальной потребности

**Обоснование:**
- Сначала необходимо протестировать архитектуру на URL source
- Добавлять новые источники только при реальной потребности
- Архитектура подготовлена для расширения

---

## Предложения по следующему инженерному спринту

### Предложение 1: Provider Interface Refinement

**Цель:** Уточнить контракт AI Provider перед реализацией новых провайдеров.

**Задачи:**
1. Документировать точный контракт GigaChat provider
2. Определить точки расширения для OpenAI
3. Определить точки расширения для Anthropic
4. Создать Provider Interface Specification

**Результат:** Provider Interface Specification документ

---

### Предложение 2: Content Source Interface Refinement

**Цель:** Уточнить контракт Content Source перед реализацией новых источников.

**Задачи:**
1. Документировать точный контракт URL source
2. Определить точки расширения для Text source
3. Определить точки расширения для PDF source
4. Создать Content Source Interface Specification

**Результат:** Content Source Interface Specification документ

---

### Предложение 3: Error Handling Architecture

**Цель:** Улучшить архитектуру обработки ошибок.

**Задачи:**
1. Проанализировать текущую обработку ошибок
2. Определить error categories
3. Определить error recovery strategies
4. Создать Error Handling Architecture документ

**Результат:** Error Handling Architecture документ

---

### Предложение 4: Logging & Monitoring Architecture

**Цель:** Улучшить логирование и мониторинг.

**Задачи:**
1. Определить logging levels
2. Определить monitoring metrics
3. Определить alerting rules
4. Создать Logging & Monitoring Architecture документ

**Результат:** Logging & Monitoring Architecture документ

---

## Заключение

Архитектура Telegram AI Gateway спроектирована для:

✅ Масштабирования без усложнения сопровождения
✅ Добавления новых AI-провайдеров
✅ Добавления новых источников контента
✅ Повторного использования компонентов
✅ Понимания архитектуры новыми разработчиками

Существующий E2E-сценарий остаётся полностью работоспособным.

---

**Документ создан:** 2026-07-08
**Версия:** 1.0
**Статус:** Architecture Sprint Complete