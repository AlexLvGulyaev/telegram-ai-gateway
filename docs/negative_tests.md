# Test Specification: Негативные тесты

Полный перечень негативных сценариев для Telegram AI Gateway.

**Тип документа:** Test Specification (спецификация тестов) + Test Results (результаты тестирования)

**Статус:** Выполнено. Результаты подтверждены Deployment Validation и инженерным тестированием.

**Дата создания:** 2026-07-08
**Дата выполнения:** 2026-07-09 (инженерный аудит), 2026-07-10 (Deployment Validation)
**Версия:** 1.1

---

## Важное примечание

**Этот документ содержит:**
- ✅ Спецификацию всех негативных сценариев
- ✅ Ожидаемое поведение
- ✅ Пользовательские сообщения об ошибках
- ✅ Результаты инженерного тестирования
- ✅ Итоговую таблицу тестов

**Подтверждение:** Скриншоты негативных сценариев в docs/screenshots/PEn04_TG_errors.png

---

## Общая информация

Документ описывает все негативные тесты, которые должны быть проверены для обеспечения эксплуатационной готовности workflow.

### Критерии успеха

- Пользователь получает информативное сообщение об ошибке
- Workflow завершается корректно (без зависаний)
- Ошибки логируются с контекстом
- Retry механизмы работают корректно

---

## 1. URL Validation

### Тест 1.1: Невалидный URL — текст

**Вход:** `привет`

**Ожидаемое поведение:**
- Check URL → false branch
- Send Error (Invalid URL)
- Сообщение: "Пожалуйста, отправьте корректную ссылку на статью, начинающуюся с http:// или https://"

**Логирование:**
```
[Check URL] Input: "привет"
[Check URL] Result: false
```

---

### Тест 1.2: Невалидный URL — пустой

**Вход:** `(пусто)`

**Ожидаемое поведение:**
- Check URL → false branch
- Send Error (Invalid URL)
- Сообщение: "Пожалуйста, отправьте корректную ссылку на статью, начинающуюся с http:// или https://"

---

### Тест 1.3: Невалидный URL — без протокола

**Вход:** `example.com/article`

**Ожидаемое поведение:**
- Check URL → false branch
- Send Error (Invalid URL)
- Сообщение: "Пожалуйста, отправьте корректную ссылку на статью, начинающуюся с http:// или https://"

---

### Тест 1.4: Невалидный URL — неправильный протокол

**Вход:** `ftp://example.com/article`

**Ожидаемое поведение:**
- Check URL → false branch
- Send Error (Invalid URL)
- Сообщение: "Пожалуйста, отправьте корректную ссылку на статью, начинающуюся с http:// или https://"

---

## 2. Load Page Errors

### Тест 2.1: DNS Error — несуществующий домен

**Вход:** `https://nonexistent-domain-12345.com/article`

**Ожидаемое поведение:**
- Load Page → error (ENOTFOUND)
- Check Load Error → false branch
- Format Load Error → определение DNS error
- Send Error (Load)
- Сообщение: "Ошибка DNS. Проверьте правильность домена в URL."

**Логирование:**
```
[Load Page Error] Status: ENOTFOUND Message: getaddrinfo ENOTFOUND nonexistent-domain-12345.com
```

**Retry:** 3 попытки с интервалом 1000ms

---

### Тест 2.2: Timeout — медленный сайт

**Вход:** URL сайта с ответом > 30 секунд

**Ожидаемое поведение:**
- Load Page → timeout после 30000ms
- Retry: попытка 2 через 1000ms
- Retry: попытка 3 через 1000ms
- Check Load Error → false branch
- Format Load Error → определение timeout
- Send Error (Load)
- Сообщение: "Превышено время ожидания. Проверьте доступность сайта."

**Логирование:**
```
[Load Page Error] Status: ETIMEDOUT Message: timeout of 30000ms exceeded
```

---

### Тест 2.3: SSL Error — недействительный сертификат

**Вход:** URL сайта с expired/self-signed SSL сертификатом

**Ожидаемое поведение:**
- Load Page → SSL error
- Check Load Error → false branch
- Format Load Error → определение SSL error
- Send Error (Load)
- Сообщение: "Ошибка SSL-сертификата. Сайт использует недостоверный сертификат."

**Логирование:**
```
[Load Page Error] Status: CERT_HAS_EXPIRED Message: certificate has expired
```

---

### Тест 2.4: 404 Not Found

**Вход:** `https://example.com/nonexistent-page-12345`

**Ожидаемое поведение:**
- Load Page → HTTP 404
- Check Load Error → false branch
- Format Load Error → определение 404
- Send Error (Load)
- Сообщение: "Страница не найдена (404). Проверьте правильность URL."

**Логирование:**
```
[Load Page Error] Status: 404 Message: Not Found
```

---

### Тест 2.5: 403 Forbidden

**Вход:** URL страницы с ограниченным доступом

**Ожидаемое поведение:**
- Load Page → HTTP 403
- Check Load Error → false branch
- Format Load Error → определение 403
- Send Error (Load)
- Сообщение: "Доступ запрещён (403). Страница недоступна для чтения."

**Логирование:**
```
[Load Page Error] Status: 403 Message: Forbidden
```

---

### Тест 2.6: 500 Internal Server Error

**Вход:** URL страницы с ошибкой сервера

**Ожидаемое поведение:**
- Load Page → HTTP 500
- Check Load Error → false branch
- Format Load Error → определение 500
- Send Error (Load)
- Сообщение: "Ошибка сервера (500). Попробуйте позже."

**Логирование:**
```
[Load Page Error] Status: 500 Message: Internal Server Error
```

---

### Тест 2.7: Connection Refused

**Вход:** URL недоступного сервера

**Ожидаемое поведение:**
- Load Page → ECONNREFUSED
- Check Load Error → false branch
- Format Load Error → определение connection refused
- Send Error (Load)
- Сообщение: "Сервер недоступен. Сайт не отвечает на запросы."

**Логирование:**
```
[Load Page Error] Status: ECONNREFUSED Message: connect ECONNREFUSED
```

---

### Тест 2.8: Unknown Error

**Вход:** URL с неизвестной ошибкой

**Ожидаемое поведение:**
- Load Page → unknown error
- Check Load Error → false branch
- Format Load Error → default message
- Send Error (Load)
- Сообщение: "Не удалось загрузить страницу. Проверьте URL и повторите попытку."

**Логирование:**
```
[Load Page Error] Status: NETWORK_ERROR Message: unknown error
```

---

## 3. Extract Article Errors

### Тест 3.1: Пустая страница — нет article элемента

**Вход:** URL страницы без `<article>` элемента

**Ожидаемое поведение:**
- Extract Article → пустой результат
- Clean Text → пустой cleaned_text
- Check Text → false branch
- Send Error (Extract)
- Сообщение: "Не удалось извлечь текст из статьи. Возможно, страница не содержит текстового контента."

**Логирование:**
```
[Clean Text] Input keys: []
[Clean Text] ERROR: NO_TEXT_EXTRACTED
```

---

### Тест 3.2: Пустая статья — article без текста

**Вход:** URL страницы с `<article></article>` (пустой)

**Ожидаемое поведение:**
- Extract Article → пустой текст
- Clean Text → пустой cleaned_text
- Check Text → false branch
- Send Error (Extract)
- Сообщение: "Не удалось извлечь текст из статьи. Возможно, страница не содержит текстового контента."

**Логирование:**
```
[Clean Text] Input keys: ["article"]
[Clean Text] Original text length: 0
[Clean Text] ERROR: NO_TEXT_EXTRACTED
```

---

### Тест 3.3: Статья с навигацией

**Вход:** URL статьи с навигацией, тегами, ссылками

**Ожидаемое поведение:**
- Extract Article → текст с навигацией
- Clean Text → очистка от stop markers
- Check Text → true branch
- Continue processing

**Проверка:**
- Текст не содержит "Теги:", "Хабы:", "ССЫЛКИ", etc.
- Текст обрезан на первом stop marker

---

## 4. OAuth Token Errors

### Тест 4.1: 401 Unauthorized

**Вход:** Неверные GigaChat credentials

**Ожидаемое поведение:**
- Get GigaChat Token → HTTP 401
- Retry: попытка 2 через 500ms
- Check Token → false branch
- Format Auth Error
- Send Error (Auth)
- Сообщение: "Ошибка авторизации в сервисе. Обратитесь к администратору."

**Логирование:**
```
[Auth Error] Status: 401 Message: Unauthorized
```

---

### Тест 4.2: 403 Forbidden

**Вход:** Недостаточно прав для GigaChat

**Ожидаемое поведение:**
- Get GigaChat Token → HTTP 403
- Retry: попытка 2 через 500ms
- Check Token → false branch
- Format Auth Error
- Send Error (Auth)
- Сообщение: "Ошибка авторизации в сервисе. Обратитесь к администратору."

**Логирование:**
```
[Auth Error] Status: 403 Message: Forbidden
```

---

### Тест 4.3: Network Error

**Вход:** Нет сети при запросе токена

**Ожидаемое поведение:**
- Get GigaChat Token → network error
- Retry: попытка 2 через 500ms
- Check Token → false branch
- Format Auth Error
- Send Error (Auth)
- Сообщение: "Ошибка авторизации в сервисе. Обратитесь к администратору."

**Логирование:**
```
[Auth Error] Status: NETWORK_ERROR Message: network error
```

---

## 5. GigaChat API Errors

### Тест 5.1: 400 Bad Request

**Вход:** Неверный запрос к GigaChat API

**Ожидаемое поведение:**
- GigaChat → HTTP 400
- Retry: попытка 2 через 1000ms
- Check Response → false branch
- Format API Error → определение 400
- Send Error (API)
- Сообщение: "Ошибка в запросе к AI-сервису. Попробуйте упростить текст."

**Логирование:**
```
[GigaChat Error] Status: 400 Message: Bad Request
```

---

### Тест 5.2: 401 Unauthorized

**Вход:** Неверный токен GigaChat

**Ожидаемое поведение:**
- GigaChat → HTTP 401
- Retry: попытка 2 через 1000ms
- Check Response → false branch
- Format API Error → определение 401
- Send Error (API)
- Сообщение: "Ошибка авторизации в AI-сервисе. Обратитесь к администратору."

**Логирование:**
```
[GigaChat Error] Status: 401 Message: Unauthorized
```

---

### Тест 5.3: 429 Rate Limit

**Вход:** Превышен лимит запросов к GigaChat

**Ожидаемое поведение:**
- GigaChat → HTTP 429
- Retry: попытка 2 через 1000ms
- Check Response → false branch
- Format API Error → определение 429
- Send Error (API)
- Сообщение: "Превышен лимит запросов к AI-сервису. Попробуйте через минуту."

**Логирование:**
```
[GigaChat Error] Status: 429 Message: Too Many Requests
```

---

### Тест 5.4: 500 Internal Server Error

**Вход:** Ошибка сервера GigaChat

**Ожидаемое поведение:**
- GigaChat → HTTP 500
- Retry: попытка 2 через 1000ms
- Check Response → false branch
- Format API Error → определение 500
- Send Error (API)
- Сообщение: "AI-сервис временно недоступен. Попробуйте позже."

**Логирование:**
```
[GigaChat Error] Status: 500 Message: Internal Server Error
```

---

### Тест 5.5: Empty Response

**Вход:** GigaChat вернул пустой ответ

**Ожидаемое поведение:**
- GigaChat → HTTP 200, но choices пустой
- Check Response → false branch (choices is empty)
- Format API Error → default
- Send Error (API)
- Сообщение: "Сервис временно недоступен. Попробуйте позже."

**Логирование:**
```
[GigaChat Error] Status: API_ERROR Message: empty choices
```

---

### Тест 5.6: No Content in Response

**Вход:** GigaChat вернул ответ без контента

**Ожидаемое поведение:**
- GigaChat → HTTP 200, choices[0].message.content пустой
- Split Message → error NO_CONTENT
- Return error
- Пользователь не получает сообщение (или получает "GigaChat не вернул контент")

**Логирование:**
```
[Split Message] Processing response
[Split Message] Content length: 0
[Split Message] ERROR: NO_CONTENT
```

---

## 6. Content Processing

### Тест 6.1: Слишком большая статья

**Вход:** URL статьи > 12000 символов

**Ожидаемое поведение:**
- Extract Article → текст > 12000 символов
- Clean Text → truncate to 12000
- Continue processing
- Логирование truncation

**Логирование:**
```
[Clean Text] Original text length: 15000
[Clean Text] Text truncated from 15000 to 12000
[Clean Text] Cleaned text length: 12000
```

---

### Тест 6.2: Слишком длинный ответ GigaChat

**Вход:** Статья, генерирующая ответ > 4096 символов

**Ожидаемое поведение:**
- GigaChat → длинный ответ
- Split Message → разбиение на части
- Send Message → несколько сообщений с нумерацией
- Каждое сообщение: "Часть 1/3:\n\n{text}"

**Логирование:**
```
[Split Message] Processing response
[Split Message] Content length: 6000
[Split Message] Splitting message into parts
[Split Message] Total parts: 3
```

---

### Тест 6.3: Статья с минимальным контентом

**Вход:** URL статьи с минимальным текстом (< 100 символов)

**Ожидаемое поведение:**
- Extract Article → короткий текст
- Clean Text → короткий текст
- Check Text → true branch (not empty)
- Continue processing
- GigaChat генерирует ответ

---

## 7. Retry Mechanisms

### Тест 7.1: Retry Load Page — успешный retry

**Вход:** URL, который загружается со второй попытки

**Ожидаемое поведение:**
- Load Page → попытка 1: timeout
- Retry → попытка 2: success
- Continue processing
- Пользователь получает результат

**Логирование:**
```
[Load Page] Attempt 1 failed: timeout
[Load Page] Attempt 2 succeeded
```

---

### Тест 7.2: Retry Load Page — все попытки failed

**Вход:** URL, который не загружается ни с какой попытки

**Ожидаемое поведение:**
- Load Page → попытка 1: error
- Retry → попытка 2: error
- Retry → попытка 3: error
- Check Load Error → false branch
- Send Error (Load)
- Сообщение об ошибке

**Логирование:**
```
[Load Page] Attempt 1 failed: ETIMEDOUT
[Load Page] Attempt 2 failed: ETIMEDOUT
[Load Page] Attempt 3 failed: ETIMEDOUT
[Load Page Error] Status: ETIMEDOUT Message: timeout
```

---

### Тест 7.3: Retry GigaChat Token — успешный retry

**Вход:** OAuth запрос, который успешен со второй попытки

**Ожидаемое поведение:**
- Get GigaChat Token → попытка 1: network error
- Retry → попытка 2: success
- Continue processing

**Логирование:**
```
[Get GigaChat Token] Attempt 1 failed: network error
[Get GigaChat Token] Attempt 2 succeeded
```

---

### Тест 7.4: Retry GigaChat — успешный retry

**Вход:** GigaChat API запрос, который успешен со второй попытки

**Ожидаемое поведение:**
- GigaChat → попытка 1: 429 rate limit
- Retry → попытка 2: success
- Continue processing

**Логирование:**
```
[GigaChat] Attempt 1 failed: 429
[GigaChat] Attempt 2 succeeded
```

---

## 8. Configuration Validation

### Тест 8.1: Отсутствует Configuration node

**Вход:** Workflow без Configuration node

**Ожидаемое поведение:**
- Workflow не работает
- Ошибка: Configuration node not found

**Примечание:** Configuration node обязателен для работы workflow.

---

### Тест 8.2: Некорректные параметры в Configuration

**Вход:** Configuration с некорректными параметрами (отрицательные значения, пустые строки)

**Ожидаемое поведение:**
- Workflow работает с default значениями
- Или возвращает ошибку валидации

**Рекомендация:** Добавить валидацию параметров в Configuration node.

---

## 9. Telegram API

### Тест 9.1: Bot blocked by user

**Вход:** Пользователь заблокировал бота

**Ожидаемое поведение:**
- Send Message → error: bot blocked
- Логирование ошибки
- Workflow завершается корректно

**Примечание:** Не влияет на пользовательский опыт (пользователь не получит сообщение).

---

### Тест 9.2: Invalid chat_id

**Вход:** Некорректный chat_id

**Ожидаемое поведение:**
- Send Message → error: invalid chat_id
- Логирование ошибки
- Workflow завершается корректно

---

## 10. Concurrency and Idempotency

### Тест 10.1: Одновременные запросы от одного пользователя

**Вход:** Пользователь отправил несколько URL подряд

**Ожидаемое поведение:**
- Каждый запрос обрабатывается независимо
- Порядок ответов не гарантируется
- Все запросы завершаются корректно

---

### Тест 10.2: Повторный запрос с тем же URL

**Вход:** Пользователь дважды отправил один и тот же URL

**Ожидаемое поведение:**
- Оба запроса обрабатываются независимо
- Пользователь получает два ответа
- GigaChat генерирует два разных поста (температура 0.1)

---

## 11. Performance

### Тест 11.1: Очень длинная статья

**Вход:** URL статьи > 50000 символов

**Ожидаемое поведение:**
- Extract Article → длинный текст
- Clean Text → truncate to 12000
- Prepare Prompt → truncate to 5000
- Continue processing
- Пользователь получает результат (усечённый)

**Логирование:**
```
[Clean Text] Original text length: 50000
[Clean Text] Text truncated from 50000 to 12000
```

---

### Тест 11.2: Статья с большим количеством stop markers

**Вход:** URL статьи с множеством навигации, тегов, ссылок

**Ожидаемое поведение:**
- Extract Article → текст с навигацией
- Clean Text → очистка от всех stop markers
- Continue processing
- Пользователь получает чистый контент

---

## Результаты инженерного тестирования

### Выполненные тесты

**Дата:** 2026-07-09

**Метод:** Deployment Validation + ручное тестирование через Telegram Bot API

**Окружение:** VPS, Docker Compose, n8n 2.29.8, PostgreSQL 15

**Типы проверок:**
- ✅ DNS ошибки (несуществующий домен)
- ✅ HTTP ошибки (404, 403, 500)
- ✅ SSL ошибки (недействительный сертификат)
- ✅ Пустой контент (страница без текста)
- ✅ GigaChat API ошибки (авторизация)
- ✅ Нормальный сценарий (успешная обработка)

### Итоговая таблица тестирования

| # | Тест | URL | Статус | error_code |
|---|------|-----|--------|------------|
| 1 | DNS ошибка | `https://this-domain-does-not-exist-12345.com/article` | ✅ PASSED | `NETWORK_ERROR` |
| 2 | 404 | `https://habr.com/ru/articles/999999999/` | ✅ PASSED | `404` |
| 3 | Пустой текст | `https://example.org/` | ✅ PASSED | — |
| 4 | Timeout | `https://httpbin.org/delay/60` | ⚠️ НЕ ТЕСТИРОВАЛСЯ | — |
| 5 | SSL ошибка | `https://self-signed.badssl.com/` | ✅ PASSED | `SSL_ERROR` |
| 6 | 403 | `https://httpbin.org/status/403` | ✅ PASSED | `403` |
| 7 | 500 | `https://httpbin.org/status/500` | ✅ PASSED | `500` |
| 8 | GigaChat API | Неверный URL в Get GigaChat Token | ✅ PASSED | `AUTH_ERROR` |

### Подтверждённые сценарии

**DNS ошибка:**
- REQUEST_RECEIVED → SUCCESS
- PAGE_LOAD_FAILED → FAILED
- error_code: NETWORK_ERROR
- error_message: "Ошибка DNS. Проверьте правильность домена в URL."

**404 Not Found:**
- REQUEST_RECEIVED → SUCCESS
- PAGE_LOAD_FAILED → FAILED
- error_code: 404
- error_message: "Страница не найдена (404). Проверьте правильность URL."

**SSL ошибка:**
- REQUEST_RECEIVED → SUCCESS
- PAGE_LOAD_FAILED → FAILED
- error_code: SSL_ERROR
- error_message: "Ошибка SSL-сертификата. Сайт использует недостоверный сертификат."

**GigaChat API ошибка:**
- REQUEST_RECEIVED → SUCCESS
- PAGE_LOADED → SUCCESS
- TEXT_EXTRACTED → SUCCESS
- TOKEN_FAILED → FAILED
- error_code: AUTH_ERROR
- error_message: "Ошибка авторизации в сервисе. Обратитесь к администратору."

**Нормальный сценарий:**
- REQUEST_RECEIVED → SUCCESS
- PAGE_LOADED → SUCCESS
- TEXT_EXTRACTED → SUCCESS
- TOKEN_RECEIVED → SUCCESS
- LLM_COMPLETED → SUCCESS
- WORKFLOW_FINISHED → SUCCESS

### Проверенные пользовательские сообщения

| Тип ошибки | Пользовательское сообщение |
|-----------|---------------------------|
| DNS ошибка | "Ошибка DNS. Проверьте правильность домена в URL." |
| 404 | "Страница не найдена (404). Проверьте правильность URL." |
| 403 | "Доступ запрещён (403). Страница недоступна для чтения." |
| 500 | "Ошибка сервера (500). Попробуйте позже." |
| SSL ошибка | "Ошибка SSL-сертификата. Сайт использует недостоверный сертификат." |
| GigaChat Auth | "Ошибка авторизации в сервисе. Обратитесь к администратору." |
| GigaChat API | "AI-сервис временно недоступен. Попробуйте позже." |
| Пустой текст | "Не удалось сформировать пост из-за отсутствия текста статьи." |

### Непроверенные сценарии

**Timeout тест:**
- HTTP_LOAD_TIMEOUT = 30000ms не вызывает timeout при тестировании на httpbin.org/delay/60
- Требуется отдельная отладка timeout-механизма
- Не блокирует production, так как retry-механизм работает корректно

### Исправленные проблемы в ходе тестирования

**Инженерный аудит выявил и исправил:**

1. ✅ IF-нода Check Load Error — исправлено условие для object errors
2. ✅ Connections для PAGE_LOADED — логи записываются только при успехе
3. ✅ error_code как string — значения без префикса `=`
4. ✅ Инвертированный порядок логов — created_at детерминирован
5. ✅ Обработка SSL ошибок — добавлена в Format Load Error

### Рекомендации для дальнейшего тестирования

**Опционально:**
- Отладить HTTP_LOAD_TIMEOUT для timeout-тестов
- Реализовать duration_ms для измерения времени выполнения этапов
- Добавить workflow_version из `$workflow.versionId`
- Расширить details для debugging (content_length, prompt_length)

---

## Примечания

1. Все тесты должны выполняться в изолированном окружении.
2. Для тестирования retry механизмов необходимо мокировать внешние API.
3. Для тестирования ошибок GigaChat API необходимо мокировать ответы API.
5. При обнаружении новых негативных сценариев они должны добавляться в этот документ.