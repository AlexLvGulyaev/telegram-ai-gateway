# Setup Guide

Пошаговая инструкция по установке Telegram AI Gateway.

## Системные требования

### Минимальные требования

| Компонент | Требование |
|-----------|-----------|
| CPU | 1 ядро |
| RAM | 1 GB |
| Диск | 10 GB |
| ОС | Linux (Ubuntu 22.04 LTS рекомендуется) |

### Рекомендуемые требования

| Компонент | Требование |
|-----------|-----------|
| CPU | 2 ядра |
| RAM | 2 GB |
| Диск | 20 GB |
| ОС | Linux (Ubuntu 22.04 LTS) |

### Программное обеспечение

| ПО | Версия | Установка |
|----|--------|-----------|
| Docker | 20.10+ | [Инструкция](https://docs.docker.com/engine/install/) |
| Docker Compose | 2.0+ | [Инструкция](https://docs.docker.com/compose/install/) |
| Git | 2.0+ | `apt install git` |

### Версия n8n

**Текущая версия:** n8n 2.29.8 (stable)

**Docker image:** `docker.n8n.io/n8nio/n8n:2.29.8`

**Важно:** Проект использует n8n 2.x. Версия 1.120.x не используется из-за критической регрессии frontend.

Подробнее: [engineering-investigation-n8n-update.md](engineering-investigation-n8n-update.md)

---

### 1. Установка Docker

**Ubuntu/Debian:**

```bash
# Обновите пакеты
sudo apt update

# Установите зависимости
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Добавьте Docker GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Добавьте репозиторий Docker
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Установите Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Добавьте пользователя в группу docker
sudo usermod -aG docker $USER

# Выйдите и войдите снова для применения изменений
```

**Проверка:**

```bash
docker --version
docker compose version
```

### 2. Клонирование репозитория

```bash
# Клонируйте репозиторий
git clone https://github.com/your-username/telegram-ai-gateway.git
cd telegram-ai-gateway
```

### 3. Настройка переменных окружения

```bash
# Скопируйте пример конфигурации
cp .env.example .env

# Отредактируйте файл
nano .env
```

**Обязательные переменные:**

```env
# PostgreSQL
POSTGRES_PASSWORD=your_secure_postgres_password_here

# n8n
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your_secure_n8n_password_here

# Telegram
TELEGRAM_BOT_TOKEN=your_telegram_bot_token_here

# GigaChat
GIGACHAT_AUTH_BASIC=your_base64_credentials_here
```

### 4. Запуск проекта

```bash
# Запустите Docker Compose
docker compose up -d

# Проверьте статус
docker compose ps

# Проверьте логи
docker compose logs -f n8n
```

### 5. Проверка работоспособности

```bash
# Проверьте, что n8n запущен
curl http://localhost:5678/healthz

# Ожидаемый ответ: OK
```

### 6. Первый вход в n8n

1. Откройте браузер: `http://localhost:5678`
2. Войдите с учётными данными из `.env`:
   - Username: значение `N8N_BASIC_AUTH_USER`
   - Password: значение `N8N_BASIC_AUTH_PASSWORD`

## Настройка workflow

### 1. Импорт workflow

1. Откройте n8n: `http://localhost:5678`
2. Перейдите в **Workflows** → **Import from File**
3. Выберите файл: `workflows/Telegram AI Gateway.json`
4. Нажмите **Import**
5. Повторите для `workflows/Telegram AI Gateway - Log Writer.json`

### 2. Настройка credentials

**Важно:** Workflow требует три credentials. Подробные инструкции см. в [Credentials Setup Guide](credentials-setup.md).

#### Краткий обзор:

1. **Telegram Bot API** — для Telegram Trigger и Send Message
2. **Header Auth** — для GigaChat Basic Auth
3. **PostgreSQL** — для Log Writer

**Детальные инструкции:** [docs/credentials-setup.md](credentials-setup.md)

### 3. Применение миграций

**Важно:** После первого запуска примените миграции БД:

```bash
docker exec -i telegram-ai-gateway-postgres psql -U n8n -d n8n < migrations/001_create_workflow_logs.sql
docker exec -i telegram-ai-gateway-postgres psql -U n8n -d n8n < migrations/002_alter_workflow_logs_created_at.sql
```

### 4. Активация workflow

1. Откройте workflow: **Telegram AI Gateway**
2. Нажмите переключатель **Active** в правом верхнем углу
3. Workflow начнёт слушать входящие сообщения от Telegram

## Получение credentials

### Telegram Bot Token

1. Откройте [@BotFather](https://t.me/botfather) в Telegram
2. Отправьте команду `/newbot`
3. Следуйте инструкциям:
   - Введите имя бота (например: `My Article Bot`)
   - Введите username бота (например: `my_article_bot`)
4. Скопируйте полученный токен:
   ```
   1234567890:ABCdefGHIjklMNOpqrsTUVwxyz
   ```
5. Добавьте токен в `.env`:
   ```env
   TELEGRAM_BOT_TOKEN=1234567890:ABCdefGHIjklMNOpqrsTUVwxyz
   ```

### GigaChat API Credentials

1. Зарегистрируйтесь на [developers.sber.ru](https://developers.sber.ru/studio/workspaces)
2. Создайте новый проект
3. Получите credentials:
   - `client_id`
   - `client_secret`
4. Закодируйте в Base64:
   ```bash
   echo -n "client_id:client_secret" | base64
   ```
5. Добавьте в `.env`:
   ```env
   GIGACHAT_AUTH_KEY=<base64_encoded_credentials>
   ```

## Проверка работы

### 1. Отправьте тестовое сообщение

Откройте Telegram и отправьте боту:

```
https://habr.com/ru/articles/example/
```

### 2. Ожидаемый результат

Бот должен ответить структурированным постом:

```
ЗАГОЛОВОК СТАТЬИ

Краткое описание статьи...

• Пункт 1
• Пункт 2
• Пункт 3

Вывод: ...
```

### 3. Проверка ошибок

Отправьте невалидный URL:

```
invalid-url
```

Ожидаемый ответ:

```
Пожалуйста, отправьте корректную ссылку на статью, начинающуюся с http:// или https://
```

## Устранение неполадок

### n8n не запускается

**Проверьте логи:**

```bash
docker compose logs n8n
```

**Частые проблемы:**

- Порт 5678 занят: измените `N8N_PORT` в `.env`
- PostgreSQL не запущен: проверьте статус контейнера
- Ошибка аутентификации: проверьте credentials

### Workflow не активируется

**Проверьте credentials:**

1. Откройте **Credentials** в n8n
2. Убедитесь, что все credentials настроены
3. Проверьте, что токены валидны

**Проверьте Telegram Bot Token:**

```bash
curl "https://api.telegram.org/bot<YOUR_TOKEN>/getMe"
```

Ожидаемый ответ:

```json
{
  "ok": true,
  "result": {
    "id": 1234567890,
    "is_bot": true,
    "first_name": "Your Bot Name",
    "username": "your_bot_username"
  }
}
```

### GigaChat API возвращает ошибку

**Проверьте credentials:**

1. Убедитесь, что `client_id` и `client_secret` валидны
2. Проверьте, что Base64 кодировка правильная
3. Убедитесь, что scope `GIGACHAT_API_PERS` активен

**Проверьте доступ к API:**

```bash
# Получение токена
curl -X POST "https://ngw.devices.sberbank.ru:9443/api/v2/oauth" \
  -H "Authorization: Basic <your_base64_credentials>" \
  -H "RqUID: <uuid>" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "scope=GIGACHAT_API_PERS"
```

## Остановка и перезапуск

### Остановка

```bash
# Остановить все контейнеры
docker compose down

# Остановить и удалить volumes
docker compose down -v
```

### Перезапуск

```bash
# Перезапустить все контейнеры
docker compose restart

# Перезапустить только n8n
docker compose restart n8n
```

## Обновление

```bash
# Остановить контейнеры
docker compose down

# Получить последние изменения
git pull

# Пересоздать контейнеры
docker compose up -d --build
```

## Следующие шаги

После успешной установки:

1. Прочитайте [Workflow Overview](workflow_overview.md)
2. Изучите [Deployment Guide](deployment_guide.md)
3. Ознакомьтесь с [Limitations](limitations.md)