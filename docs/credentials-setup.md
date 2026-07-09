# Credentials Setup Guide

Подробное руководство по настройке credentials для Telegram AI Gateway.

---

## Обзор

Workflow требует три credentials для работы:

| Credential | Тип | Назначение | Используется в |
|-----------|-----|-----------|----------------|
| `telegram-ai-gateway-bot` | Telegram API | Telegram Bot API | Telegram Trigger, Send Message nodes |
| `gigachat-basic-auth` | Header Auth | GigaChat OAuth | Get GigaChat Token node |
| `Telegram AI Gateway PostgreSQL` | PostgreSQL | Log Writer workflow | Insert Log to PostgreSQL node |

---

## 1. Telegram Bot API Credential

### 1.1. Получение Bot Token

1. Откройте [@BotFather](https://t.me/botfather) в Telegram
2. Отправьте `/newbot`
3. Следуйте инструкциям:
   - Введите имя бота (например: `My Article Bot`)
   - Введите username бота (например: `my_article_bot`)
4. Скопируйте полученный токен:
   ```
   1234567890:ABCdefGHIjklMNOpqrsTUVwxyz
   ```

### 1.2. Создание Credential в n8n

1. Откройте n8n UI: `http://localhost:5678`
2. Авторизуйтесь с учётными данными из `.env`
3. Перейдите в **Settings** → **Credentials**
4. Нажмите **Add Credential**
5. Выберите тип: **Telegram API**
6. Введите:
   - **Credential Name:** `telegram-ai-gateway-bot`
   - **Bot Token:** `<TELEGRAM_BOT_TOKEN>` (из `.env`)
7. Нажмите **Save**

### 1.3. Проверка

```bash
# Проверьте токен
curl "https://api.telegram.org/bot<YOUR_TOKEN>/getMe"

# Ожидаемый ответ:
# {
#   "ok": true,
#   "result": {
#     "id": 1234567890,
#     "is_bot": true,
#     "first_name": "Your Bot Name",
#     "username": "your_bot_username"
#   }
# }
```

---

## 2. GigaChat Basic Auth Credential

### 2.1. Получение Credentials

1. Зарегистрируйтесь на [developers.sber.ru](https://developers.sber.ru/studio/workspaces)
2. Создайте новый проект
3. Получите credentials:
   - `client_id`
   - `client_secret`

### 2.2. Кодирование в Base64

```bash
# Закодируйте credentials в Base64
echo -n "client_id:client_secret" | base64

# Пример результата:
# MDE5YzgwMjYtMzBlZS03YWI5LWEzMTMtNThlZGI1YzdlMGJmOmQxZThiNDE4LTNhYTYtNDYzZC1hMjQ0LWQ2ZDU4ODJhMDIyNQ==
```

### 2.3. Создание Credential в n8n

1. Перейдите в **Settings** → **Credentials**
2. Нажмите **Add Credential**
3. Выберите тип: **Header Auth**
4. Введите:
   - **Credential Name:** `gigachat-basic-auth`
   - **Name:** `Authorization`
   - **Value:** `Basic <BASE64_ENCODED_CREDENTIALS>` (замените `<BASE64_ENCODED_CREDENTIALS>` на результат из шага 2.2)
5. Нажмите **Save**

### 2.4. Проверка

```bash
# Получите access token
curl -X POST "https://ngw.devices.sberbank.ru:9443/api/v2/oauth" \
  -H "Authorization: Basic <BASE64_ENCODED_CREDENTIALS>" \
  -H "RqUID: $(uuidgen)" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "scope=GIGACHAT_API_PERS"

# Ожидаемый ответ:
# {
#   "access_token": "...",
#   "expires_in": 1800,
#   "scope": "GIGACHAT_API_PERS"
# }
```

---

## 3. PostgreSQL Credential

### 3.1. Создание Credential в n8n

1. Перейдите в **Settings** → **Credentials**
2. Нажмите **Add Credential**
3. Выберите тип: **PostgreSQL**
4. Введите:
   - **Credential Name:** `Telegram AI Gateway PostgreSQL`
   - **Host:** `postgres` (имя контейнера в Docker сети)
   - **Port:** `5432`
   - **Database:** `n8n` (или значение из `POSTGRES_DB` в `.env`)
   - **User:** `n8n` (или значение из `POSTGRES_USER` в `.env`)
   - **Password:** значение из `POSTGRES_PASSWORD` в `.env`
   - **SSL Mode:** `disable` (для локального развёртывания)
   - **Database Schema:** `public`
5. Нажмите **Save**

### 3.2. Проверка подключения

```bash
# Проверьте подключение к PostgreSQL
docker exec telegram-ai-gateway-postgres psql -U n8n -d n8n -c "\d workflow_logs"

# Ожидаемый результат: описание таблицы workflow_logs
```

---

## 4. Верификация Credentials

### 4.1. Проверка списка credentials

```bash
# Получите список credentials через API
curl -u admin:<N8N_BASIC_AUTH_PASSWORD> http://localhost:5678/api/v1/credentials

# Ожидаемый результат: JSON с тремя credentials
```

### 4.2. Проверка workflow

1. Откройте workflow **Telegram AI Gateway**
2. Нажмите **Execute Workflow**
3. Проверьте, что все nodes успешно подключены к credentials
4. Нет красных иконок "Missing credential"

---

## 5. Troubleshooting

### 5.1. Ошибка: "Credential not found"

**Проблема:** Credential не найден в workflow.

**Решение:**
1. Проверьте точное имя credential (должно совпадать с workflow)
2. Убедитесь, что credential сохранён
3. Перезагрузите страницу n8n

### 5.2. Ошибка: "Invalid Bot Token"

**Проблема:** Telegram Bot Token невалиден.

**Решение:**
1. Проверьте токен через BotFather
2. Убедитесь, что токен не содержит лишних пробелов
3. Создайте нового бота при необходимости

### 5.3. Ошибка: "GigaChat Auth Failed"

**Проблема:** GigaChat credentials невалидны.

**Решение:**
1. Проверьте credentials на developers.sber.ru
2. Убедитесь, что scope `GIGACHAT_API_PERS` активен
3. Перекодируйте в Base64: `echo -n "client_id:client_secret" | base64`

### 5.4. Ошибка: "PostgreSQL Connection Failed"

**Проблема:** Не удаётся подключиться к PostgreSQL.

**Решение:**
1. Проверьте, что PostgreSQL контейнер запущен: `docker compose ps`
2. Проверьте логи: `docker compose logs postgres`
3. Убедитесь, что credential использует `postgres` как host (имя контейнера)
4. Проверьте пароль: `POSTGRES_PASSWORD` в `.env`

---

## 6. Связанные документы

- [Deployment Guide](deployment_guide.md) — полное руководство по развёртыванию
- [Setup Guide](setup.md) — инструкции по установке
- [Workflow Overview](workflow_overview.md) — обзор workflow