# Logging Integration Guide

## Обзор

Данный документ описывает интеграцию Execution Logging в основной workflow "Telegram AI Gateway".

## Архитектура

```
Основной workflow (Telegram AI Gateway)
       ↓
Execute Workflow Node
       ↓
Telegram AI Gateway - Log Writer
       ↓
PostgreSQL (workflow_logs table)
```

## Log Writer Workflow

**Расположение:** `workflows/Telegram AI Gateway - Log Writer.json`

**Назначение:** Принимает событие журналирования и записывает в PostgreSQL.

**Входной контракт:**
```json
{
  "request_id": "uuid-string",
  "created_at": "2026-07-09T10:00:00.000Z",
  "workflow_name": "Telegram AI Gateway",
  "workflow_version": "phase2-architecture-improvements",
  "stage": "REQUEST_RECEIVED",
  "event_type": "telegram_webhook",
  "level": "INFO",
  "status": "SUCCESS",
  "chat_id": "123456789",
  "user_id": null,
  "input_url": "https://example.com/article",
  "duration_ms": null,
  "message": "Request received from Telegram",
  "error_code": null,
  "error_message": null,
  "details": {}
}
```

**Важно:** `created_at` — обязательное поле, генерируется в Generate Request ID node и прокидывается через весь workflow. Это обеспечивает хронологический порядок логов в рамках одного запроса.

## Точки логирования в основном workflow

### 1. REQUEST_RECEIVED

**После ноды:** Generate Request ID

**Execute Workflow параметры:**
```json
{
  "workflowId": "log-writer-workflow-id",
  "parameters": {
    "request_id": "={{ $('Generate Request ID').item.json.request_id }}",
    "created_at": "={{ $('Generate Request ID').item.json.created_at }}",
    "workflow_name": "Telegram AI Gateway",
    "workflow_version": "={{ $workflow.versionId }}",
    "stage": "REQUEST_RECEIVED",
    "event_type": "telegram_webhook",
    "level": "INFO",
    "status": "SUCCESS",
    "chat_id": "={{ $json.message.chat.id }}",
    "user_id": "={{ $json.message.from.id }}",
    "input_url": "={{ $json.message.text }}",
    "message": "Request received from Telegram"
  }
}
```

### 2. URL_VALIDATED

**После ноды:** Content Source Detection (true branch)

**Execute Workflow параметры:**
```json
{
  "workflowId": "log-writer-workflow-id",
  "parameters": {
    "request_id": "={{ $('Generate Request ID').item.json.request_id }}",
    "created_at": "={{ $('Generate Request ID').item.json.created_at }",
    "workflow_name": "Telegram AI Gateway",
    "workflow_version": "={{ $workflow.versionId }}",
    "stage": "URL_VALIDATED",
    "event_type": "validation",
    "level": "INFO",
    "status": "SUCCESS",
    "chat_id": "={{ $('Telegram Trigger').item.json.message.chat.id }}",
    "input_url": "={{ $json.url }}",
    "message": "URL validated successfully"
  }
}
```

### 3. PAGE_LOADED

**После ноды:** Check Load Error (true branch)

**Execute Workflow параметры:**
```json
{
  "workflowId": "log-writer-workflow-id",
  "parameters": {
    "request_id": "={{ $('Generate Request ID').item.json.request_id }}",
    "created_at": "={{ $('Generate Request ID').item.json.created_at }",
    "workflow_name": "Telegram AI Gateway",
    "workflow_version": "={{ $workflow.versionId }}",
    "stage": "PAGE_LOADED",
    "event_type": "http_request",
    "level": "INFO",
    "status": "SUCCESS",
    "chat_id": "={{ $('Telegram Trigger').item.json.message.chat.id }}",
    "input_url": "={{ $json.url }}",
    "message": "Page loaded successfully",
    "details": {
      "content_length": "={{ $json.data?.length || 0 }}"
    }
  }
}
```

### 4. PAGE_LOAD_FAILED

**После ноды:** Format Load Error

**Execute Workflow параметры:**
```json
{
  "workflowId": "log-writer-workflow-id",
  "parameters": {
    "request_id": "={{ $('Generate Request ID').item.json.request_id }}",
    "created_at": "={{ $('Generate Request ID').item.json.created_at }",
    "workflow_name": "Telegram AI Gateway",
    "workflow_version": "={{ $workflow.versionId }}",
    "stage": "PAGE_LOAD_FAILED",
    "event_type": "http_request",
    "level": "ERROR",
    "status": "FAILED",
    "chat_id": "={{ $json.chat_id }}",
    "input_url": "={{ $('Prepare Input').item.json.url }}",
    "error_code": "={{ $json.error_code }}",
    "error_message": "={{ $json.error_message }}",
    "message": "Page load failed"
  }
}
```

### 5. ARTICLE_EXTRACTED

**После ноды:** Clean Text

**Execute Workflow параметры:**
```json
{
  "workflowId": "log-writer-workflow-id",
  "parameters": {
    "request_id": "={{ $('Generate Request ID').item.json.request_id }}",
    "created_at": "={{ $('Generate Request ID').item.json.created_at }",
    "workflow_name": "Telegram AI Gateway",
    "workflow_version": "={{ $workflow.versionId }}",
    "stage": "ARTICLE_EXTRACTED",
    "event_type": "processing",
    "level": "INFO",
    "status": "SUCCESS",
    "chat_id": "={{ $('Telegram Trigger').item.json.message.chat.id }}",
    "message": "Article extracted and cleaned",
    "details": {
      "cleaned_text_length": "={{ $json.cleaned_text?.length || 0 }}"
    }
  }
}
```

### 6. ARTICLE_EXTRACT_FAILED

**После ноды:** Send Error (Extract)

**Execute Workflow параметры:**
```json
{
  "workflowId": "log-writer-workflow-id",
  "parameters": {
    "request_id": "={{ $('Generate Request ID').item.json.request_id }}",
    "created_at": "={{ $('Generate Request ID').item.json.created_at }",
    "workflow_name": "Telegram AI Gateway",
    "workflow_version": "={{ $workflow.versionId }}",
    "stage": "ARTICLE_EXTRACT_FAILED",
    "event_type": "processing",
    "level": "ERROR",
    "status": "FAILED",
    "chat_id": "={{ $('Telegram Trigger').item.json.message.chat.id }}",
    "error_code": "NO_TEXT_EXTRACTED",
    "error_message": "Failed to extract article text",
    "message": "Article extraction failed"
  }
}
```

### 7. TOKEN_RECEIVED

**После ноды:** Check Token (true branch)

**Execute Workflow параметры:**
```json
{
  "workflowId": "log-writer-workflow-id",
  "parameters": {
    "request_id": "={{ $('Generate Request ID').item.json.request_id }}",
    "created_at": "={{ $('Generate Request ID').item.json.created_at }",
    "workflow_name": "Telegram AI Gateway",
    "workflow_version": "={{ $workflow.versionId }}",
    "stage": "TOKEN_RECEIVED",
    "event_type": "oauth",
    "level": "INFO",
    "status": "SUCCESS",
    "chat_id": "={{ $('Telegram Trigger').item.json.message.chat.id }}",
    "message": "GigaChat token received",
    "details": {
      "expires_in": "={{ $json.expires_in }}"
    }
  }
}
```

### 8. TOKEN_FAILED

**После ноды:** Format Auth Error

**Execute Workflow параметры:**
```json
{
  "workflowId": "log-writer-workflow-id",
  "parameters": {
    "request_id": "={{ $('Generate Request ID').item.json.request_id }}",
    "created_at": "={{ $('Generate Request ID').item.json.created_at }",
    "workflow_name": "Telegram AI Gateway",
    "workflow_version": "={{ $workflow.versionId }}",
    "stage": "TOKEN_FAILED",
    "event_type": "oauth",
    "level": "ERROR",
    "status": "FAILED",
    "chat_id": "={{ $json.chat_id }}",
    "error_code": "={{ $json.error_code }}",
    "error_message": "={{ $json.error_message }}",
    "message": "Failed to get GigaChat token"
  }
}
```

### 9. LLM_COMPLETED

**После ноды:** Check Response (true branch)

**Execute Workflow параметры:**
```json
{
  "workflowId": "log-writer-workflow-id",
  "parameters": {
    "request_id": "={{ $('Generate Request ID').item.json.request_id }}",
    "created_at": "={{ $('Generate Request ID').item.json.created_at }",
    "workflow_name": "Telegram AI Gateway",
    "workflow_version": "={{ $workflow.versionId }}",
    "stage": "LLM_COMPLETED",
    "event_type": "llm_request",
    "level": "INFO",
    "status": "SUCCESS",
    "chat_id": "={{ $('Telegram Trigger').item.json.message.chat.id }}",
    "message": "GigaChat response received",
    "details": {
      "content_length": "={{ $json.choices?.[0]?.message?.content?.length || 0 }}"
    }
  }
}
```

### 10. LLM_FAILED

**После ноды:** Format API Error

**Execute Workflow параметры:**
```json
{
  "workflowId": "log-writer-workflow-id",
  "parameters": {
    "request_id": "={{ $('Generate Request ID').item.json.request_id }}",
    "created_at": "={{ $('Generate Request ID').item.json.created_at }",
    "workflow_name": "Telegram AI Gateway",
    "workflow_version": "={{ $workflow.versionId }}",
    "stage": "LLM_FAILED",
    "event_type": "llm_request",
    "level": "ERROR",
    "status": "FAILED",
    "chat_id": "={{ $json.chat_id }}",
    "error_code": "={{ $json.error_code }}",
    "error_message": "={{ $json.error_message }}",
    "message": "GigaChat API request failed"
  }
}
```

### 11. TELEGRAM_SENT

**После ноды:** Send Message

**Execute Workflow параметры:**
```json
{
  "workflowId": "log-writer-workflow-id",
  "parameters": {
    "request_id": "={{ $('Generate Request ID').item.json.request_id }}",
    "created_at": "={{ $('Generate Request ID').item.json.created_at }",
    "workflow_name": "Telegram AI Gateway",
    "workflow_version": "={{ $workflow.versionId }}",
    "stage": "TELEGRAM_SENT",
    "event_type": "telegram_send",
    "level": "INFO",
    "status": "SUCCESS",
    "chat_id": "={{ $json.chat_id }}",
    "message": "Message sent to Telegram",
    "details": {
      "message_part": "={{ $json.part }}",
      "total_parts": "={{ $json.total }}"
    }
  }
}
```

### 12. WORKFLOW_FAILED

**После ноды:** Send Error (Invalid URL), Send Error (Load), Send Error (Extract), Send Error (Auth), Send Error (API)

**Execute Workflow параметры:**
```json
{
  "workflowId": "log-writer-workflow-id",
  "parameters": {
    "request_id": "={{ $('Generate Request ID').item.json.request_id }}",
    "created_at": "={{ $('Generate Request ID').item.json.created_at }",
    "workflow_name": "Telegram AI Gateway",
    "workflow_version": "={{ $workflow.versionId }}",
    "stage": "WORKFLOW_FAILED",
    "event_type": "workflow",
    "level": "ERROR",
    "status": "FAILED",
    "chat_id": "={{ $('Telegram Trigger').item.json.message.chat.id }}",
    "message": "Workflow execution failed"
  }
}
```

## Дополнительные точки логирования (опционально)

### PAGE_LOAD_STARTED

**Перед нодой:** Load Page

**Execute Workflow параметры:**
```json
{
  "workflowId": "log-writer-workflow-id",
  "parameters": {
    "request_id": "={{ $('Generate Request ID').item.json.request_id }}",
    "created_at": "={{ $('Generate Request ID').item.json.created_at }",
    "workflow_name": "Telegram AI Gateway",
    "workflow_version": "={{ $workflow.versionId }}",
    "stage": "PAGE_LOAD_STARTED",
    "event_type": "http_request",
    "level": "INFO",
    "status": "IN_PROGRESS",
    "chat_id": "={{ $('Telegram Trigger').item.json.message.chat.id }}",
    "input_url": "={{ $json.url }}",
    "message": "Starting page load"
  }
}
```

### PROMPT_BUILT

**После ноды:** Prepare Prompt

**Execute Workflow параметры:**
```json
{
  "workflowId": "log-writer-workflow-id",
  "parameters": {
    "request_id": "={{ $('Generate Request ID').item.json.request_id }}",
    "created_at": "={{ $('Generate Request ID').item.json.created_at }",
    "workflow_name": "Telegram AI Gateway",
    "workflow_version": "={{ $workflow.versionId }}",
    "stage": "PROMPT_BUILT",
    "event_type": "processing",
    "level": "INFO",
    "status": "SUCCESS",
    "chat_id": "={{ $('Telegram Trigger').item.json.message.chat.id }}",
    "message": "Prompt prepared for LLM",
    "details": {
      "prompt_length": "={{ $json.prompt?.length || 0 }}"
    }
  }
}
```

### TOKEN_REQUEST_STARTED

**Перед нодой:** Get GigaChat Token

**Execute Workflow параметры:**
```json
{
  "workflowId": "log-writer-workflow-id",
  "parameters": {
    "request_id": "={{ $('Generate Request ID').item.json.request_id }}",
    "created_at": "={{ $('Generate Request ID').item.json.created_at }",
    "workflow_name": "Telegram AI Gateway",
    "workflow_version": "={{ $workflow.versionId }}",
    "stage": "TOKEN_REQUEST_STARTED",
    "event_type": "oauth",
    "level": "INFO",
    "status": "IN_PROGRESS",
    "chat_id": "={{ $('Telegram Trigger').item.json.message.chat.id }}",
    "message": "Requesting GigaChat token"
  }
}
```

### LLM_REQUEST_STARTED

**Перед нодой:** GigaChat

**Execute Workflow параметры:**
```json
{
  "workflowId": "log-writer-workflow-id",
  "parameters": {
    "request_id": "={{ $('Generate Request ID').item.json.request_id }}",
    "created_at": "={{ $('Generate Request ID').item.json.created_at }",
    "workflow_name": "Telegram AI Gateway",
    "workflow_version": "={{ $workflow.versionId }}",
    "stage": "LLM_REQUEST_STARTED",
    "event_type": "llm_request",
    "level": "INFO",
    "status": "IN_PROGRESS",
    "chat_id": "={{ $('Telegram Trigger').item.json.message.chat.id }}",
    "message": "Sending request to GigaChat"
  }
}
```

### MESSAGE_SPLIT

**После ноды:** Split Message

**Execute Workflow параметры:**
```json
{
  "workflowId": "log-writer-workflow-id",
  "parameters": {
    "request_id": "={{ $('Generate Request ID').item.json.request_id }}",
    "created_at": "={{ $('Generate Request ID').item.json.created_at }",
    "workflow_name": "Telegram AI Gateway",
    "workflow_version": "={{ $workflow.versionId }}",
    "stage": "MESSAGE_SPLIT",
    "event_type": "processing",
    "level": "INFO",
    "status": "SUCCESS",
    "chat_id": "={{ $json.chat_id }}",
    "message": "Message split into parts",
    "details": {
      "total_parts": "={{ $json.total }}"
    }
  }
}
```

### TELEGRAM_SEND_STARTED

**Перед нодой:** Send Message

**Execute Workflow параметры:**
```json
{
  "workflowId": "log-writer-workflow-id",
  "parameters": {
    "request_id": "={{ $('Generate Request ID').item.json.request_id }}",
    "created_at": "={{ $('Generate Request ID').item.json.created_at }",
    "workflow_name": "Telegram AI Gateway",
    "workflow_version": "={{ $workflow.versionId }}",
    "stage": "TELEGRAM_SEND_STARTED",
    "event_type": "telegram_send",
    "level": "INFO",
    "status": "IN_PROGRESS",
    "chat_id": "={{ $json.chat_id }}",
    "message": "Sending message to Telegram",
    "details": {
      "part": "={{ $json.part }}",
      "total": "={{ $json.total }}"
    }
  }
}
```

### WORKFLOW_FINISHED

**После ноды:** Send Message (после успешной отправки)

**Execute Workflow параметры:**
```json
{
  "workflowId": "log-writer-workflow-id",
  "parameters": {
    "request_id": "={{ $('Generate Request ID').item.json.request_id }}",
    "created_at": "={{ $('Generate Request ID').item.json.created_at }",
    "workflow_name": "Telegram AI Gateway",
    "workflow_version": "={{ $workflow.versionId }}",
    "stage": "WORKFLOW_FINISHED",
    "event_type": "workflow",
    "level": "INFO",
    "status": "SUCCESS",
    "chat_id": "={{ $json.chat_id }}",
    "message": "Workflow execution completed successfully"
  }
}
```

## Инструкция по внедрению

### Шаг 1: Импортировать Log Writer workflow

1. Открыть n8n UI
2. Перейти в Workflows
3. Нажать "Import from File"
4. Выбрать `workflows/Telegram AI Gateway - Log Writer.json`
5. Активировать workflow
6. Записать ID импортированного workflow (понадобится для Execute Workflow nodes)

### Шаг 2: Настроить PostgreSQL credentials

1. Открыть Log Writer workflow
2. Настроить PostgreSQL credentials для ноды "Insert Log to PostgreSQL"
3. Убедиться, что таблица `workflow_logs` создана (выполнить SQL migration)

### Шаг 3: Добавить Execute Workflow nodes в основной workflow

Для каждой точки логирования:

1. Открыть основной workflow "Telegram AI Gateway"
2. Добавить Execute Workflow node после указанной ноды
3. Настроить параметры:
   - Workflow: "Telegram AI Gateway - Log Writer"
   - Parameters: согласно конфигурации выше
4. Подключить connections

### Шаг 4: Протестировать

1. Активировать обновлённый workflow
2. Отправить тестовый URL в Telegram-бота
3. Проверить записи в PostgreSQL:
   ```sql
   SELECT * FROM workflow_logs WHERE request_id = '<test_request_id>' ORDER BY created_at;
   ```
4. Убедиться, что все события записаны в правильном порядке

## Минимальный набор точек логирования

Если внедрение всех точек затруднительно, начать с минимального набора:

**Обязательные точки:**
1. REQUEST_RECEIVED (начало)
2. WORKFLOW_FINISHED (успешное завершение)
3. WORKFLOW_FAILED (каждая ошибка)

**Рекомендуемые точки:**
4. PAGE_LOADED / PAGE_LOAD_FAILED
5. TOKEN_RECEIVED / TOKEN_FAILED
6. LLM_COMPLETED / LLM_FAILED

## Критерий успешности

После внедрения логирования:

1. Каждый запрос пользователя полностью восстановим по журналу
2. Последовательность событий видна по `created_at`
3. Ошибки содержат `error_code` и `error_message`
4. Успешные выполнения содержат `status: SUCCESS`
5. Неудачные выполнения содержат `status: FAILED`

## Примечания

- Execute Workflow nodes выполняются асинхронно и не блокируют основной workflow
- Ошибки в Execute Workflow nodes не должны останавливать основной workflow (использовать Continue On Fail)
- `request_id` берётся из `$('Generate Request ID').item.json.request_id` во всех точках
- `chat_id` всегда берётся из `$('Telegram Trigger').item.json.message.chat.id`

---

**Версия:** 1.0
**Дата:** 2026-07-09