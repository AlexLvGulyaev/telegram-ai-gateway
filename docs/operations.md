# 🛠️ Telegram AI Gateway · Operations Guide

Эксплуатация развёрнутого экземпляра Telegram AI Gateway: мониторинг, бэкап, обновление, безопасность, troubleshooting. Развёртывание — [Deployment Guide](deployment_guide.md).

## 📊 1. Мониторинг

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

### Журнал исполнения

Журнал прогонов (`workflow_logs` в PostgreSQL) — схема, точки логирования и запросы к журналу: [architecture.md](architecture.md), §6. Диагностика по `request_id` — разбор конкретного прогона по событиям.

### Метрики

**Docker stats:**

```bash
docker stats
```

**Использование диска:**

```bash
docker system df
```

## 💾 2. Бэкап и восстановление

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

## 🔄 3. Обновление

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

### Обновление n8n

Версия n8n зафиксирована в docker-compose.yml (2.29.8). При обновлении на другую версию учитывайте отличия n8n 2.x от 1.x:

- Task runners включены по умолчанию (Code node изолирован)
- Environment variables заблокированы в Code nodes по умолчанию
- PostgreSQL user default — `postgres` (не `root`)
- Требуется `CODE_ENABLE_STDOUT=true` для вывода console.log

После обновления — прогон [чеклиста Deployment Validation](deployment_guide.md#-8-чеклист-deployment-validation).

### Обновление n8n workflow

**Вариант 1: Импорт из файла**

1. Откройте n8n UI
2. Workflows → Import from File
3. Выберите `workflows/Telegram AI Gateway.json`

**Вариант 2: Импорт через CLI**

```bash
# Файл должен быть виден внутри контейнера (docker cp в /tmp)
docker cp "workflows/Telegram AI Gateway.json" telegram-ai-gateway-n8n:/tmp/wf_main.json
docker exec telegram-ai-gateway-n8n n8n import:workflow --input=/tmp/wf_main.json
docker exec telegram-ai-gateway-n8n rm /tmp/wf_main.json
```

**Важно:** импорт на запущенном n8n сбрасывает флаг Active импортированного workflow — после импорта реактивируйте workflow и перезапустите n8n (перезапуск перерегистрирует Telegram webhook).

## 🛡️ 4. Безопасность

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
   - Допускается: «Использованы реальные Telegram Bot Token и GigaChat credentials»
   - Недопустимо: публикация конкретных значений токенов или ключей

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

## 🚨 5. Troubleshooting

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
- Циклический recovery-loop: `Recovery attempt N failed: password authentication failed`

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

См. [Deployment Guide](deployment_guide.md), §5.5 «Синхронизация пароля PostgreSQL».

**3. Docker DNS-коллизия алиаса `postgres` в общей сети:**

Если n8n подключён к общей сети (например, `n8n_default` — обязательна для Traefik reverse proxy),
а в этой сети **другой** контейнер держит alias `postgres` (compose service name = сетевой alias),
Docker DNS смешивает кандидатов со всех сетей контейнера. n8n может стабильно резолвить
`postgres` на **чужую** БД с другим паролем → бесконечный `password authentication failed`,
хотя пароль правильный и родной postgres healthy.

Диагностика (изнутри контейнера n8n):

```bash
docker exec telegram-ai-gateway-n8n node -e "require('dns').lookup('postgres',(e,a)=>console.log(a||e.code))"
# Ожидание: IP родного postgres (сеть telegram-ai-gateway), а не чужого контейнера
```

Решение — использовать **уникальные имена хостов** вместо имени сервиса:

- в `docker-compose.yml`: `DB_POSTGRESDB_HOST=telegram-ai-gateway-postgres` (не `postgres`);
- в n8n credential `Telegram AI Gateway PostgreSQL`: Host = `telegram-ai-gateway-postgres`
  (Log Writer подключается через credential, а не через переменные окружения!);
- после правки credential перезапустить n8n (`docker restart telegram-ai-gateway-n8n`), чтобы сбросить кеш credentials.

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
Если есть записи с `%20` — переименовать node.

**Профилактика:**
- **Имена nodes в n8n НЕ должны содержать пробелы**
- Это касается всех nodes, которые создают webhook paths

### Проблема: Workflow не активируется

**Проверьте credentials:**

1. Откройте **Credentials** в n8n
2. Убедитесь, что все три credentials настроены (Telegram Bot API, Header Auth, PostgreSQL)
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

### Проблема: GigaChat API возвращает ошибку

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

---

**Статус:** Актуален · Source of Truth эксплуатации
**Последнее обновление:** 2026-09-16
**История изменений:** [📝 CHANGE_LOG.md](CHANGE_LOG.md#-1-история-изменений-документации)