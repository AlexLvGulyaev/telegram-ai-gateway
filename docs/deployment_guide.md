# Deployment Guide

Руководство по развёртыванию Telegram AI Gateway на VPS с HTTPS.

## Версия n8n

**Текущая версия:** n8n 2.29.8 (stable)

**Docker image:** `docker.n8n.io/n8nio/n8n:2.29.8`

**Важно:** Проект использует n8n 2.x с изменениями по сравнению с версией 1.x:

- Task runners включены по умолчанию (Code node изолирован)
- Environment variables заблокированы в Code nodes по умолчанию
- PostgreSQL user default изменился с `root` на `postgres`
- Требуется `CODE_ENABLE_STDOUT=true` для вывода console.log

Подробнее: [engineering-investigation-n8n-update.md](engineering-investigation-n8n-update.md)

---

## Предпосылки

- VPS с публичным IP
- Доменное имя (опционально, для webhook режима)
- Docker и Docker Compose установлены
- Telegram Bot Token (от @BotFather)
- GigaChat API credentials (client_id и client_secret)

---

## Режимы работы

Проект поддерживает два режима работы:

### Polling (по умолчанию)
- **Преимущества:** Проще настройка, не требует HTTPS
- **Недостатки:** Большая нагрузка на Telegram API
- **Рекомендуется для:** Разработки и тестирования
- **Конфигурация:** `WEBHOOK_URL=` (пустое значение)

### Webhook
- **Преимущества:** Меньше нагрузка, быстрее реакция
- **Недостатки:** Требует HTTPS и публичного домена
- **Рекомендуется для:** Production
- **Конфигурация:** `WEBHOOK_URL=https://your-domain.com`

## Развёртывание на VPS

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
POSTGRES_PASSWORD=<secure_password>

# n8n
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=<secure_password>

# Telegram
TELEGRAM_BOT_TOKEN=<your_bot_token>

# GigaChat
GIGACHAT_AUTH_BASIC=<your_credentials>

# Webhook URL (для production)
WEBHOOK_URL=https://your-domain.com
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

### 5. Применение миграций БД

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

### 6. Импорт workflow

**Вариант 1: Импорт через n8n UI**

1. Откройте n8n: `http://localhost:5678`
2. Авторизуйтесь с учётными данными из `.env`
3. Перейдите в **Workflows** → **Import from File**
4. Выберите `workflows/Telegram AI Gateway.json`
5. Нажмите **Import**
6. Повторите для `workflows/Telegram AI Gateway - Log Writer.json`

**Вариант 2: Импорт через CLI (рекомендуется для автоматизации)**

```bash
# Импорт основного workflow
docker exec telegram-ai-gateway-n8n n8n import:workflow --input=/home/node/.n8n-files/../workflows/Telegram\ AI\ Gateway.json

# Примечание: путь зависит от способа монтирования volumes
```

### 7. Настройка credentials

**Важно:** Workflow требует три credentials для работы.

#### 7.1. Telegram Bot API Credential

**Название в workflow:** `telegram-ai-gateway-bot`

1. Откройте n8n UI: `http://localhost:5678`
2. Перейдите в **Credentials** → **Add Credential**
3. Выберите тип: **Telegram API**
4. Введите:
   - **Credential Name:** `telegram-ai-gateway-bot`
   - **Bot Token:** значение из `TELEGRAM_BOT_TOKEN` в `.env`
5. Нажмите **Save**

#### 7.2. GigaChat Basic Auth Credential

**Название в workflow:** `gigachat-basic-auth`

1. Перейдите в **Credentials** → **Add Credential**
2. Выберите тип: **Header Auth**
3. Введите:
   - **Credential Name:** `gigachat-basic-auth`
   - **Header Name:** `Authorization`
   - **Header Value:** `Basic <GIGACHAT_AUTH_BASIC>` (замените `<GIGACHAT_AUTH_BASIC>` на значение из `.env`)
4. Нажмите **Save`

#### 7.3. PostgreSQL Credential (для Log Writer)

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

### 8. Активация workflow

1. Откройте workflow: **Telegram AI Gateway**
2. Нажмите переключатель **Active** в правом верхнем углу
3. Workflow начнёт слушать входящие сообщения от Telegram

**Проверка активации:**

```bash
# Проверьте, что workflow активен
curl -u admin:<N8N_BASIC_AUTH_PASSWORD> http://localhost:5678/api/v1/workflows
```

### 9. Проверка работоспособности

```bash
# Проверьте, что n8n запущен
curl http://localhost:5678/healthz

# Должен вернуться ответ: {"status":"ok"}
```

## Настройка HTTPS

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

## Настройка Webhook

### Polling vs Webhook

**Polling (по умолчанию):**
- Проще в настройке
- Не требует HTTPS
- Подходит для разработки
- Установите `WEBHOOK_URL=` (пустое значение)

**Webhook:**
- Быстрее реакция
- Меньше нагрузки на Telegram API
- Требует HTTPS и публичного домена
- Установите `WEBHOOK_URL=https://your-domain.com`

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

## Мониторинг

### Health Checks

**Docker healthcheck:**

```bash
docker compose ps
```

Ожидаемый статус: `healthy`

**n8n health endpoint:**

```bash
curl http://localhost:5678/healthz
```

Ожидаемый ответ: `OK`

### Логи

**Просмотр логов n8n:**

```bash
docker compose logs -f n8n
```

**Просмотр логов PostgreSQL:**

```bash
docker compose logs -f postgres
```

**Экспорт логов в файл:**

```bash
docker compose logs n8n > n8n-$(date +%Y%m%d).log
```

### Метрики

**Docker stats:**

```bash
docker stats
```

**Использование диска:**

```bash
docker system df
```

## Бэкап и восстановление

### Бэкап PostgreSQL

```bash
# Создайте директорию для бэкапов
mkdir -p ~/backups

# Бэкап базы данных
docker exec telegram-ai-gateway-postgres pg_dump -U n8n n8n > ~/backups/n8n-$(date +%Y%m%d).sql

# Бэкап Docker volumes
docker run --rm -v telegram-ai-gateway_n8n_data:/data -v ~/backups:/backup alpine tar czf /backup/n8n-data-$(date +%Y%m%d).tar.gz -C /data .
```

### Автоматический бэкап

**Создайте cron job:**

```bash
crontab -e
```

```cron
# Ежедневный бэкап в 2:00
0 2 * * * cd ~/projects/telegram-ai-gateway && docker exec telegram-ai-gateway-postgres pg_dump -U n8n n8n > ~/backups/n8n-$(date +\%Y\%m\%d).sql
```

### Восстановление

```bash
# Остановите n8n
docker compose stop n8n

# Восстановите базу данных
cat ~/backups/n8n-20260108.sql | docker exec -i telegram-ai-gateway-postgres psql -U n8n n8n

# Запустите n8n
docker compose start n8n
```

## Обновление

### Обновление кода

```bash
# Остановите контейнеры
docker compose down

# Получите последние изменения
git pull

# Запустите контейнеры
docker compose up -d
```

### Обновление Docker образов

```bash
# Остановите контейнеры
docker compose down

# Получите последние образы
docker compose pull

# Запустите контейнеры
docker compose up -d
```

### Обновление n8n workflow

**Вариант 1: Импорт из файла**

1. Откройте n8n UI
2. Workflows → Import from File
3. Выберите `workflows/telegram-ai-gateway.json`

**Вариант 2: Импорт через CLI**

```bash
# Используйте n8n CLI для импорта
docker exec telegram-ai-gateway-n8n n8n import:workflow --input=/home/node/.n8n/workflows/telegram-ai-gateway.json
```

## Безопасность

### Firewall

**UFW (Ubuntu):**

```bash
# Разрешите SSH
sudo ufw allow ssh

# Разрешите HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Запретите всё остальное
sudo ufw enable

# Проверьте статус
sudo ufw status
```

### Fail2ban

**Установка:**

```bash
sudo apt install fail2ban
```

**Конфигурация:**

```bash
sudo nano /etc/fail2ban/jail.local
```

```ini
[sshd]
enabled = true
maxretry = 3
bantime = 1h
```

### SSL/TLS

**Проверка SSL:**

```bash
# Let's Encrypt
sudo certbot certificates

# Проверка SSL
curl -vI https://your-domain.com
```

### Обновление системы

```bash
# Обновите пакеты
sudo apt update
sudo apt upgrade -y

# Очистите старые пакеты
sudo apt autoremove -y
```

## Troubleshooting

### Проблема: n8n не запускается

**Решение:**

```bash
# Проверьте логи
docker compose logs n8n

# Проверьте порты
sudo netstat -tlnp | grep 5678

# Перезапустите
docker compose restart n8n
```

### Проблема: PostgreSQL не запускается

**Решение:**

```bash
# Проверьте логи
docker compose logs postgres

# Проверьте права на volume
ls -la /var/lib/docker/volumes/telegram-ai-gateway_postgres_data

# Пересоздайте volume
docker compose down -v
docker compose up -d
```

### Проблема: Webhook не работает

**Решение:**

1. Убедитесь, что HTTPS настроен правильно
2. Проверьте WEBHOOK_URL в .env
3. Проверьте, что порт 443 открыт в firewall
4. Проверьте логи n8n на ошибки

### Проблема: Telegram не отправляет сообщения

**Решение:**

1. Проверьте токен: `curl https://api.telegram.org/bot<token>/getMe`
2. Убедитесь, что workflow активен
3. Проверьте credentials в n8n
4. Проверьте логи n8n

## Чеклист развёртывания

- [ ] VPS настроен
- [ ] Docker и Docker Compose установлены
- [ ] Проект склонирован
- [ ] .env настроен
- [ ] Docker Compose запущен
- [ ] HTTPS настроен
- [ ] n8n доступен по HTTPS
- [ ] Credentials настроены
- [ ] Workflow активирован
- [ ] Бот отвечает на тестовые сообщения
- [ ] Бэкапы настроены
- [ ] Мониторинг настроен