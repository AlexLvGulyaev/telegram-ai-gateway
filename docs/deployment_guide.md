# 🚀 Telegram AI Gateway · Deployment Guide

Руководство по развёртыванию Telegram AI Gateway: локальный Docker-режим и production на VPS с HTTPS. Эксплуатация развёрнутого экземпляра — [Operations Guide](operations.md); отчёт о фактическом прогоне Deployment Validation — [Deployment Validation Report](deployment_validation_report.md).

## ℹ️ 1. Версия n8n

**Текущая версия:** n8n 2.29.8 (stable) — `docker.n8n.io/n8nio/n8n:2.29.8`

Проект использует n8n 2.x с изменениями по сравнению с 1.x:

- Task runners включены по умолчанию (Code node изолирован)
- Environment variables заблокированы в Code nodes по умолчанию
- PostgreSQL user default изменился с `root` на `postgres`
- Требуется `CODE_ENABLE_STDOUT=true` для вывода console.log

Несовместимость с n8n 1.120.x выявлена в ходе инженерного исследования проекта; выбор стабильной версии 2.29.8 зафиксирован в docker-compose.yml. При обновлении n8n — [Operations Guide](operations.md), «Обновление».

## 📋 2. Предпосылки

Для локального развёртывания (§4) достаточно Docker на локальной машине; для production на VPS (§5):

- VPS с публичным IP
- Доменное имя с HTTPS — обязательно для работы бота (см. §3 «Режимы работы»)
- Docker и Docker Compose установлены
- Telegram Bot Token (от @BotFather)
- GigaChat API credentials (client_id и client_secret)

## 🔀 3. Режимы работы

**Единственный работоспособный режим — Webhook.** Telegram Trigger в n8n при активации workflow регистрирует webhook в Telegram API; polling-фоллбэка у триггера нет. Telegram API принимает только HTTPS-адреса: при пустом `WEBHOOK_URL` активация завершается ошибкой «Bad request - please check your parameters» и бот не получает сообщения (подтверждено [Deployment Validation](deployment_validation_report.md), прогон 2026-09-16).

### Webhook (обязательно)
- **Требования:** HTTPS и публичный домен (§6)
- **Конфигурация:** `WEBHOOK_URL=https://your-domain.com`
- **Преимущества:** быстрая реакция, минимальная нагрузка на Telegram API

> ℹ️ Ранее документированный режим polling (`WEBHOOK_URL=` пустое значение) неработоспособен: Telegram отклоняет http://-webhook («An HTTPS URL must be provided for webhook»), поэтому активация workflow невозможна.

## 💻 4. Локальное развёртывание (Docker Compose)

Режим для разработки и тестирования: тот же Docker Compose-стек, только на локальной машине, без VPS и HTTPS. **Ограничение:** без HTTPS активация main workflow невозможна (§3), поэтому локальный стек подходит для проверки инфраструктуры и настройки credentials; полный пользовательский сценарий (сообщения боту) требует развёртывания с HTTPS — VPS по §5 или HTTPS-домен по §6.

### 1. Установка Docker (Ubuntu/Debian)

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

### 2. Клонирование и настройка окружения

```bash
git clone https://github.com/AlexLvGulyaev/telegram-ai-gateway.git
cd telegram-ai-gateway
cp .env.example .env
nano .env
```

**Обязательные переменные** (все — до первого запуска; см. §5.3 о требованиях к паролям):

```env
POSTGRES_PASSWORD=<secure_password>
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=<secure_password>
TELEGRAM_BOT_TOKEN=<your_bot_token>
GIGACHAT_AUTH_KEY=<your_credentials>
```

`WEBHOOK_URL` в локальном режиме остаётся пустым — активация main workflow в этом режиме не выполняется (см. §3 «Режимы работы»).

### 3. Запуск

```bash
docker compose up -d
docker compose ps
docker compose logs -f n8n
```

**Проверка здоровья n8n:**

```bash
curl http://localhost:5678/healthz
# Ожидаемый ответ: OK
```

### 4. Первый вход в n8n

1. Откройте браузер: `http://localhost:5678`
2. Войдите с учётными данными из `.env`:
   - Username: значение `N8N_BASIC_AUTH_USER`
   - Password: значение `N8N_BASIC_AUTH_PASSWORD`

### 5. Настройка workflow

1. **Импорт:** n8n → **Workflows** → **Import from File** → `workflows/Telegram AI Gateway.json`; повторите для `workflows/Telegram AI Gateway - Log Writer.json`.
2. **Credentials:** три credentials (Telegram Bot API, Header Auth для GigaChat, PostgreSQL) — инструкции в [Credentials Setup Guide](credentials-setup.md).
3. **Миграции БД** (после первого запуска):

```bash
docker exec -i telegram-ai-gateway-postgres psql -U n8n -d n8n < migrations/001_create_workflow_logs.sql
docker exec -i telegram-ai-gateway-postgres psql -U n8n -d n8n < migrations/002_alter_workflow_logs_created_at.sql
```

4. **Активация:** откройте workflow **Telegram AI Gateway** и включите переключатель **Active**.

### 6. Проверка работы

Отправьте боту в Telegram тестовый URL:

```
https://habr.com/ru/articles/example/
```

Ожидаемый результат — структурированный пост (заголовок, краткое описание, пункты, вывод).

Проверка валидации ошибок — отправьте `invalid-url`; ожидаемый ответ: «Пожалуйста, отправьте корректную ссылку на статью, начинающуюся с http:// или https://».

### 7. Остановка и перезапуск

```bash
# Остановить все контейнеры
docker compose down

# Остановить и удалить volumes (данные будут потеряны)
docker compose down -v

# Перезапустить все контейнеры / только n8n
docker compose restart
docker compose restart n8n
```

Обновление — в [Operations Guide](operations.md), «Обновление»; одинаково для локального и VPS-окружения.

---

## 🖥️ 5. Развёртывание на VPS

### 1. Подготовка VPS

**Подключитесь к VPS:**

```bash
ssh user@your-vps-ip
```

**Установите Docker:**

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```

**Установите Docker Compose:**

```bash
sudo apt install docker-compose-plugin
```

### 2. Клонирование проекта

```bash
# Создайте директорию для проектов
mkdir -p ~/projects
cd ~/projects

# Клонируйте репозиторий
git clone https://github.com/AlexLvGulyaev/telegram-ai-gateway.git
cd telegram-ai-gateway
```

### 3. Настройка переменных окружения

**КРИТИЧЕСКИ ВАЖНО:** Правильно настройте пароли ПЕРЕД первым запуском!

```bash
# Скопируйте пример конфигурации
cp .env.example .env

# Отредактируйте файл
nano .env
```

**Обязательные переменные:**

```env
# PostgreSQL
POSTGRES_PASSWORD=<secure_password>

# n8n
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=<secure_password>

# Telegram
TELEGRAM_BOT_TOKEN=<your_bot_token>

# GigaChat
GIGACHAT_AUTH_KEY=<your_credentials>

# Webhook URL (обязательно — без него активация workflow невозможна, см. §3)
WEBHOOK_URL=https://your-domain.com
```

**⚠️ ВАЖНО:**

1. **Пароль PostgreSQL должен быть установлен ПЕРЕД первым запуском!**
   - При первом запуске PostgreSQL инициализируется с паролем из .env
   - n8n контейнер подключится к БД с этим же паролем
   - Если изменить пароль в .env после первого запуска, потребуется синхронизация (см. §5.5)

2. **Не используйте специальные символы в пароле PostgreSQL:**
   - Избегайте: `$`, `\`, `"`, `'`
   - Используйте: буквы, цифры, `-`, `_`

3. **Все пароли должны быть установлен ПЕРЕД запуском:**
   - `POSTGRES_PASSWORD`
   - `N8N_BASIC_AUTH_PASSWORD`
   - `TELEGRAM_BOT_TOKEN`
   - `GIGACHAT_AUTH_KEY`

### 4. Первый запуск

**Проверьте конфигурацию:**

```bash
# Убедитесь, что все переменные установлены
grep -E "^(POSTGRES_PASSWORD|N8N_BASIC_AUTH_PASSWORD|TELEGRAM_BOT_TOKEN|GIGACHAT_AUTH_KEY)=" .env
```

**Запустите контейнеры:**

```bash
docker compose up -d
```

**Проверьте статус:**

```bash
docker compose ps
```

Ожидаемый статус: `healthy` для обоих контейнеров.

**Проверьте подключение n8n к БД:**

```bash
docker exec telegram-ai-gateway-n8n n8n list:workflow
```

Ожидаемый результат: список workflows (пустой, если ещё не импортированы).

**Если команда выполняется без ошибок — пароли синхронизированы корректно!**

### 5. Синхронизация пароля PostgreSQL

**Критически важно:** Пароль PostgreSQL в .env должен совпадать с паролем в БД!

docker-compose.yml использует переменную `POSTGRES_PASSWORD` из .env для обоих контейнеров:
- PostgreSQL контейнер: инициализирует БД с этим паролем
- n8n контейнер: подключается к БД с этим паролем

#### Для НОВОГО развёртывания (чистое окружение):

При первом запуске PostgreSQL автоматически инициализируется с паролем из .env. Дополнительных действий не требуется.

```bash
# Проверьте подключение с паролем из .env
docker exec telegram-ai-gateway-postgres psql -U n8n -d n8n -c "SELECT 1;"
```

#### Для СУЩЕСТВУЮЩЕГО развёртывания (уже инициализирован):

Если PostgreSQL уже был инициализирован с другим паролем, есть два варианта:

**Вариант 1: Изменить пароль в БД (сохраняет данные)**

```bash
# Измените пароль в БД на пароль из .env
python3 << 'SCRIPT_END'
import subprocess

with open('.env', 'r') as f:
    for line in f:
        if line.startswith('POSTGRES_PASSWORD='):
            password = line.split('=', 1)[1].strip()
            break

cmd = f"ALTER USER n8n WITH PASSWORD '{password}';"
subprocess.run(
    ['docker', 'exec', '-i', 'telegram-ai-gateway-postgres', 'psql', '-U', 'n8n', '-d', 'n8n'],
    input=cmd.encode()
)
print("✅ Пароль PostgreSQL синхронизирован")
SCRIPT_END

# Перезапустите n8n для применения нового пароля
docker restart telegram-ai-gateway-n8n
```

**Вариант 2: Пересоздать volumes (удаляет все данные!)**

```bash
# ОСТОРОЖНО: Удаляет все данные в БД, включая workflows!
docker compose down -v
docker compose up -d
```

#### Проверка синхронизации:

```bash
# 1. Проверьте подключение PostgreSQL
docker exec telegram-ai-gateway-postgres psql -U n8n -d n8n -c "SELECT 1;"

# 2. Проверьте подключение n8n к БД
docker exec telegram-ai-gateway-n8n n8n list:workflow

# Если команда выполняется без ошибок — пароли синхронизированы
```

### 6. Применение миграций БД

**Важно:** Миграции необходимо применять вручную после первого запуска.

```bash
# Примените миграцию создания таблицы workflow_logs
docker exec -i telegram-ai-gateway-postgres psql -U n8n -d n8n < migrations/001_create_workflow_logs.sql

# Примените миграцию изменения created_at
docker exec -i telegram-ai-gateway-postgres psql -U n8n -d n8n < migrations/002_alter_workflow_logs_created_at.sql
```

**Проверка миграций:**

```bash
# Проверьте создание таблицы
docker exec telegram-ai-gateway-postgres psql -U n8n -d n8n -c "\d workflow_logs"

# Ожидаемый результат: описание таблицы workflow_logs
```

### 7. Импорт workflow

**Вариант 1: Импорт через n8n UI**

1. Откройте n8n: `http://localhost:5678`
2. Авторизуйтесь с учётными данными из `.env`
3. Перейдите в **Workflows** → **Import from File**
4. Выберите `workflows/Telegram AI Gateway.json`
5. Нажмите **Import**
6. Повторите для `workflows/Telegram AI Gateway - Log Writer.json`

**Вариант 2: Импорт через CLI (не рекомендуется)**

CLI импорт workflow технически сложен из-за пробелов в именах файлов. Рекомендуется использовать импорт через n8n UI.

Если необходим CLI импорт:
1. Скопируйте workflow файлы в контейнер: `docker cp workflows/. telegram-ai-gateway-n8n:/tmp/workflows/`
2. Импортируйте: `docker exec telegram-ai-gateway-n8n n8n import:workflow --input=/tmp/workflows/Telegram\ AI\ Gateway.json`
3. Повторите для Log Writer: `docker exec telegram-ai-gateway-n8n n8n import:workflow --input=/tmp/workflows/Telegram\ AI\ Gateway\ -\ Log\ Writer.json`

**Примечание:** Этот метод требует дополнительных шагов и не рекомендуется для повседневного использования.

### 8. Настройка credentials

**Важно:** Workflow требует три credentials для работы.

#### 8.1. Telegram Bot API Credential

**Название в workflow:** `telegram-ai-gateway-bot`

1. Откройте n8n UI: `http://localhost:5678`
2. Перейдите в **Credentials** → **Add Credential**
3. Выберите тип: **Telegram API**
4. Введите:
   - **Credential Name:** `telegram-ai-gateway-bot`
   - **Bot Token:** значение из `TELEGRAM_BOT_TOKEN` в `.env`
5. Нажмите **Save**

#### 8.2. GigaChat Basic Auth Credential

**Название в workflow:** `gigachat-basic-auth`

1. Перейдите в **Credentials** → **Add Credential**
2. Выберите тип: **Header Auth**
3. Введите:
   - **Credential Name:** `gigachat-basic-auth`
   - **Header Name:** `Authorization`
   - **Header Value:** `Basic <GIGACHAT_AUTH_KEY>` (замените `<GIGACHAT_AUTH_KEY>` на значение из `.env`)
4. Нажмите **Save**

#### 8.3. PostgreSQL Credential (для Log Writer)

**Название в workflow:** `Telegram AI Gateway PostgreSQL`

1. Перейдите в **Credentials** → **Add Credential**
2. Выберите тип: **PostgreSQL**
3. Введите:
   - **Credential Name:** `Telegram AI Gateway PostgreSQL`
   - **Host:** `postgres` (имя контейнера в Docker сети)
   - **Port:** `5432`
   - **Database:** `n8n` (или значение из `POSTGRES_DB`)
   - **User:** `n8n` (или значение из `POSTGRES_USER`)
   - **Password:** значение из `POSTGRES_PASSWORD` в `.env`
4. Нажмите **Save**

### 9. Активация workflow

1. Откройте workflow: **Telegram AI Gateway**
2. Нажмите переключатель **Active** в правом верхнем углу
3. Workflow начнёт слушать входящие сообщения от Telegram

**Проверка активации:**

```bash
# Проверьте, что workflow активен
curl -u admin:<N8N_BASIC_AUTH_PASSWORD> http://localhost:5678/api/v1/workflows
```

### 10. Проверка работоспособности

```bash
# Проверьте, что n8n запущен
curl http://localhost:5678/healthz

# Должен вернуться ответ: {"status":"ok"}
```

## 🔐 6. Настройка HTTPS

### Вариант 1: Nginx + Let's Encrypt

**Установите Nginx:**

```bash
sudo apt update
sudo apt install nginx
```

**Установите Certbot:**

```bash
sudo apt install certbot python3-certbot-nginx
```

**Настройте Nginx:**

Создайте `/etc/nginx/sites-available/telegram-ai-gateway`:

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:5678;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**Активируйте конфигурацию:**

```bash
sudo ln -s /etc/nginx/sites-available/telegram-ai-gateway /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

**Получите SSL-сертификат:**

```bash
sudo certbot --nginx -d your-domain.com
```

**Настройте автоматическое обновление:**

```bash
sudo certbot renew --dry-run
```

### Вариант 2: Caddy (автоматический HTTPS)

**Установите Caddy:**

```bash
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy
```

**Создайте Caddyfile:**

```bash
sudo nano /etc/caddy/Caddyfile
```

```caddy
your-domain.com {
    reverse_proxy localhost:5678
}
```

**Перезапустите Caddy:**

```bash
sudo systemctl restart caddy
```

**Caddy автоматически:**
- Получит SSL-сертификат от Let's Encrypt
- Настроит HTTPS
- Будет автоматически обновлять сертификаты

## 📡 7. Настройка Webhook

Webhook — единственный работоспособный режим (§3): Telegram Trigger регистрирует webhook в Telegram API при активации, Telegram принимает только HTTPS-адреса.

### Настройка Webhook

**1. Установите WEBHOOK_URL в .env:**

```env
WEBHOOK_URL=https://your-domain.com
```

**2. Перезапустите n8n:**

```bash
docker compose restart n8n
```

**3. Убедитесь, что n8n доступен по HTTPS:**

```bash
curl https://your-domain.com/healthz
```

**4. Telegram автоматически установит webhook при активации workflow.**

## ✅ 8. Чеклист Deployment Validation

Deployment Validation состоит из двух уровней проверки. Сначала Infrastructure (инфраструктура без внешних зависимостей), затем Integration (полная работоспособность с реальными сервисами). Отчёт о фактическом прогоне — [Deployment Validation Report](deployment_validation_report.md).

### Infrastructure Validation

**Цель:** Проверить развёртывание инфраструктуры без внешних зависимостей. Не требует реальных Telegram Bot Token и GigaChat credentials (.env настраивается с placeholder-значениями).

- [ ] VPS настроен
- [ ] Docker и Docker Compose установлены
- [ ] Проект склонирован
- [ ] .env настроен (допускаются placeholder значения для Telegram и GigaChat)
- [ ] Docker Compose запущен
- [ ] Контейнеры healthy (PostgreSQL, n8n)
- [ ] **Пароль PostgreSQL синхронизирован** (проверка: `docker exec telegram-ai-gateway-postgres psql -U n8n -d n8n -c "SELECT 1;"`)
- [ ] **n8n подключается к БД** (проверка: `docker exec telegram-ai-gateway-n8n n8n list:workflow`)
- [ ] Миграции БД применены
- [ ] Workflows импортированы
- [ ] Health endpoints отвечают

**Результат:** Infrastructure PASSED

### Integration Validation

**Цель:** Проверить полную работоспособность системы с реальными внешними сервисами.

**Требует реальные credentials:**

- [ ] Реальный Telegram Bot Token (от @BotFather)
- [ ] Реальные GigaChat credentials (от developers.sber.ru)
- [ ] Реальный PostgreSQL password

**Проверки:**

- [ ] Credentials созданы в n8n (без публикации значений)
- [ ] Telegram Bot API credential создан
- [ ] GigaChat Basic Auth credential создан
- [ ] PostgreSQL credential создан
- [ ] `WEBHOOK_URL` установлен (HTTPS-домен, §7) — без него активация невозможна
- [ ] Workflow "Telegram AI Gateway" активирован без ошибок (проверка: `docker compose logs n8n` — «Activated workflow ...», без «Bad request»)
- [ ] Workflow "Telegram AI Gateway - Log Writer" активирован без ошибок
- [ ] Тестовый URL отправлен боту
- [ ] Бот вернул корректный ответ
- [ ] Записи появились в workflow_logs таблице

**Важно (credentials policy):**
- **Никогда не коммитьте** .env файл
- **Никогда не публикуйте** credentials в логах, отчётах или документации
- В отчётах допускается только **факт использования** реальных credentials
- Конкретные значения секретов остаются только в локальном .env файле

**Результат:** Integration PASSED

### Production Checklist

- [ ] HTTPS настроен
- [ ] n8n доступен по HTTPS
- [ ] Firewall настроен
- [ ] Бэкапы настроены
- [ ] Мониторинг настроен
- [ ] Credentials безопасно хранятся

---

**Статус:** Правлен по результатам Deployment Validation 2026-09-16 (polling-режим снят; см. [отчёт](deployment_validation_report.md)) — повторный полный прогон Validation запланирован
**Последнее обновление:** 2026-09-16
**История изменений:** [📝 CHANGE_LOG.md](CHANGE_LOG.md#-1-история-изменений-документации)