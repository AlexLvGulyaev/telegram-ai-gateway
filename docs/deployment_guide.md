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

---

## Deployment Validation

Deployment Validation состоит из двух уровней проверки:

### Infrastructure Validation

**Цель:** Проверить развёртывание инфраструктуры без внешних зависимостей.

**Что проверяется:**
- Docker Compose запускается
- Контейнеры healthy (PostgreSQL, n8n)
- Миграции БД применены
- Workflows импортированы
- Health endpoints отвечают

**Требования:**
- Docker и Docker Compose установлены
- .env файл настроен (допускаются placeholder значения для Telegram и GigaChat)
- PostgreSQL password может быть любым

**Не требует:**
- Реальных Telegram Bot Token
- Реальных GigaChat credentials

**Результат:** Infrastructure PASSED

---

### Integration Validation

**Цель:** Проверить полную работоспособность системы с реальными внешними сервисами.

**Что проверяется:**
- Credentials созданы в n8n
- Workflows активированы
- Telegram polling/webhook работает
- GigaChat API отвечает
- PostgreSQL logging работает
- Полный пользовательский сценарий

**Требования:**
- Реальный Telegram Bot Token (от @BotFather)
- Реальные GigaChat credentials (от developers.sber.ru)
- Реальный PostgreSQL password

**Важно:**
- **Никогда не коммитьте** .env файл
- **Никогда не публикуйте** credentials в логах, отчётах или документации
- В отчётах допускается только **факт использования** реальных credentials
- Конкретные значения секретов остаются только в локальном .env файле

**Результат:** Integration PASSED

---

### Порядок выполнения

1. **Сначала Infrastructure Validation** — проверка инфраструктуры
2. **Затем Integration Validation** — проверка с реальными сервисами

---

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

# Webhook URL (для production)
WEBHOOK_URL=https://your-domain.com
```

**⚠️ ВАЖНО:**

1. **Пароль PostgreSQL должен быть установлен ПЕРЕД первым запуском!**
   - При первом запуске PostgreSQL инициализируется с паролем из .env
   - n8n контейнер подключится к БД с этим же паролем
   - Если изменить пароль в .env после первого запуска, потребуется синхронизация (см. раздел 5)

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

**ВНИМАНИЕ:** Этот раздел нужен ТОЛЬКО если вы изменили пароль в .env после первого запуска!

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
   - **Header Value:** `Basic <GIGACHAT_AUTH_KEY>` (замените `<GIGACHAT_AUTH_KEY>` на значение из `.env`)
4. Нажмите **Save**

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

### Credentials Security

**Критически важно:**

1. **Никогда не коммитьте** .env файл в репозиторий
   - Добавьте `.env` в `.gitignore`
   - Используйте `.env.example` как шаблон

2. **Никогда не публикуйте** credentials:
   - В логах выполнения
   - В отчётах о валидации
   - В документации проекта
   - В скриншотах или примерах

3. **В отчётах о валидации**:
   - Допускается: "Использованы реальные Telegram Bot Token и GigaChat credentials"
   - Недопустимо: Публикация конкретных значений токенов или ключей

4. **Рекомендации по безопасности**:
   - Регулярно ротируйте Telegram Bot Token
   - Используйте разные credentials для dev/prod
   - Ограничьте доступ к .env файлу: `chmod 600 .env`
   - Рассмотрите использование секретов менеджера для production

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

### Проблема: n8n не может подключиться к PostgreSQL

**Симптомы:**
- Ошибка: `Error: getaddrinfo EAI_AGAIN postgres`
- Ошибка: `password authentication failed for user "n8n"`
- n8n не может найти хост `postgres`

**Причины:**

**1. Контейнеры в разных сетях:**

Если n8n контейнер не может найти хост `postgres`, проверьте сети:

```bash
# Проверить сети контейнеров
docker inspect telegram-ai-gateway-postgres --format '{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}'
docker inspect telegram-ai-gateway-n8n --format '{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}'

# Если сети разные, подключите n8n к сети postgres
docker network connect <network_name> telegram-ai-gateway-n8n
docker restart telegram-ai-gateway-n8n
```

**2. Пароль PostgreSQL не синхронизирован:**

См. раздел "5. Синхронизация пароля PostgreSQL".

### Проблема: Telegram не отправляет сообщения

**Решение:**

1. Проверьте токен: `curl https://api.telegram.org/bot<token>/getMe`
2. Убедитесь, что workflow активен
3. Проверьте credentials в n8n
4. Проверьте логи n8n

### Проблема: Webhook не регистрируется (404 Not Found)

**Симптомы:**
- n8n показывает "Activated workflow"
- Webhook возвращает 404: "webhook is not registered"
- Telegram возвращает "Wrong response from the webhook: 404 Not Found"

**Причина:**
- Имя node содержит пробел (например, "Telegram Trigger")
- n8n генерирует webhook path с пробелом: `workflow-id/telegram trigger/webhook`
- В БД сохраняется как: `workflow-id/telegram%20trigger/webhook`
- Telegram отправляет запрос с `%20`, но n8n не находит webhook

**Решение:**
1. Переименовать node: "Telegram Trigger" → "TelegramTrigger" (без пробела)
2. Сохранить workflow (Ctrl+S)
3. Активировать workflow
4. Проверить webhook_entity таблицу:
```sql
SELECT * FROM webhook_entity WHERE "webhookPath" LIKE '%\%20%';
```
Если есть записи с `%20` - переименовать node.

**Профилактика:**
- **Имена nodes в n8n НЕ должны содержать пробелы**
- Это касается всех nodes, которые создают webhook paths

### Проблема: n8n не доступен через Traefik (502 Bad Gateway)

**Симптомы:**
- Health endpoint возвращает 502 Bad Gateway
- Traefik логи: "unable to reach n8n"

**Причина:**
- Контейнер n8n не подключён к сети Traefik (`n8n_default`)
- Traefik не может резолвить hostname

**Решение:**
```bash
docker network connect n8n_default telegram-ai-gateway-n8n
docker network connect n8n_default telegram-ai-gateway-postgres
```

**Профилактика:**
Добавить в docker-compose.yml:
```yaml
networks:
  n8n_default:
    external: true

services:
  n8n:
    networks:
      - telegram-ai-gateway
      - n8n_default
  postgres:
    networks:
      - telegram-ai-gateway
      - n8n_default
```

## Наблюдения из Deployment Validation

### 1. Имена nodes в n8n (наблюдение)

**Наблюдение:** В Deployment Validation этого проекта на n8n 2.29.8 после импорта workflow через CLI webhook не работал, пока имя Telegram Trigger node содержало пробел ("Telegram Trigger"). После переименования node без пробела ("TelegramTrigger") webhook заработал.

**Статус:** ⚠️ Наблюдение (факт эксперимента, не универсальное правило)

**Гипотеза:** Возможная причина связана с URL-encoding и сопоставлением webhook path при импорте через CLI.

**Локальный обходной путь:**
- В этом проекте на n8n 2.29.8 рекомендуется использовать имя node без пробела: "TelegramTrigger"

**Проверка:**
```bash
docker exec telegram-ai-gateway-postgres psql -U n8n -d n8n -c "SELECT * FROM webhook_entity WHERE \"webhookPath\" LIKE '%\%20%';"
```

Если есть записи с `%20`, рассмотреть переименование node. Но не считать это критической ошибкой без дополнительной проверки.

**Требуется:** Контролируемый эксперимент для подтверждения универсальности ограничения.

### 2. Docker сеть для Traefik (специфика проекта)

**Наблюдение:** В этом проекте с Traefik reverse proxy контейнеры не работали без подключения к сети `n8n_default`.

**Статус:** ⚠️ Локальное наблюдение (специфика проекта с Traefik)

**Область применимости:** Только проекты с Traefik reverse proxy.

**Решение:**
```bash
docker network connect n8n_default telegram-ai-gateway-n8n
docker network connect n8n_default telegram-ai-gateway-postgres
```

### 3. Экранирование `$` в Docker Compose

**Наблюдение:** В Deployment Validation этого проекта пароль с символами `$` (`$$$`) не работал.

**Правило:** Значения, содержащие `$` в .env файлах Docker Compose, требуют экранирования: `$$` → `$` в контейнере.

**Область применимости:** Docker Compose, файлы .env, значения с символом `$`.

**Статус:** ✅ Подтверждённое правило (только для `$`)

**Примечание:** НЕ является общим запретом на спецсимволы. Требуется проверка других символов (`\`, `"`, `'`).

**Рекомендация:**
```env
# Рекомендуется использовать буквенно-цифровые пароли
POSTGRES_PASSWORD=PostgresPass123
N8N_BASIC_AUTH_PASSWORD=N8Nbap3hfpf2100

# Или корректно экранировать $
POSTGRES_PASSWORD=Pass$$word
```

**Если пароль уже содержит спецсимволы:**
```bash
# Вариант 1: Изменить пароль в БД
docker exec telegram-ai-gateway-postgres psql -U n8n -d n8n -c "ALTER USER n8n WITH PASSWORD 'PostgresPass123';"

# Вариант 2: Пересоздать volumes (удаляет все данные!)
docker compose down -v
docker compose up -d
```

## Чеклист развёртывания

### Infrastructure Validation

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

### Integration Validation

**Требует реальные credentials:**

- [ ] Реальный Telegram Bot Token (от @BotFather)
- [ ] Реальные GigaChat credentials (от developers.sber.ru)
- [ ] Реальный PostgreSQL password

**Проверки:**

- [ ] Credentials созданы в n8n (без публикации значений)
- [ ] Telegram Bot API credential создан
- [ ] GigaChat Basic Auth credential создан
- [ ] PostgreSQL credential создан
- [ ] Workflow "Telegram AI Gateway" активирован
- [ ] Workflow "Telegram AI Gateway - Log Writer" активирован
- [ ] Telegram polling/webhook работает
- [ ] Тестовый URL отправлен боту
- [ ] Бот вернул корректный ответ
- [ ] Записи появились в workflow_logs таблице

### Production Checklist

- [ ] HTTPS настроен
- [ ] n8n доступен по HTTPS
- [ ] Firewall настроен
- [ ] Бэкапы настроены
- [ ] Мониторинг настроен
- [ ] Credentials безопасно хранятся