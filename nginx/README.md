# Nginx Reverse Proxy с SSL

Минималистичная настройка nginx как reverse proxy с поддержкой SSL сертификатов.


## Быстрый старт

### 1. Запуск nginx

```bash
cd tmp/nginx
docker-compose up -d
```

Проверка:
```bash
curl http://localhost
```

### 2. Добавление нового бэкэнда

Создайте новый файл в `conf.d/`:

```bash
nano conf.d/my-app.conf
```

Пример конфигурации:

```nginx
server {
    listen 80;
    server_name myapp.local;

    location / {
        proxy_pass http://host.docker.internal:8080;
    }
}
```

Перезагрузите nginx:

```bash
docker-compose exec nginx nginx -s reload
```

**Важно:** Пересборка образа не требуется! Просто добавьте .conf файл и перезагрузите nginx.

## SSL сертификаты

### Вариант 1: Let's Encrypt (для продакшена)

#### Получение сертификата:

```bash
# Замените example.com на ваш домен
docker-compose run --rm certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  -d example.com \
  -d www.example.com \
  --email your-email@example.com \
  --agree-tos \
  --no-eff-email
```

#### Использование в конфиге:

```nginx
server {
    listen 443 ssl http2;
    server_name example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    location / {
        proxy_pass http://host.docker.internal:3000;
    }
}
```

#### Обновление сертификатов:

Сертификаты обновляются автоматически каждые 12 часов. Для ручного обновления:

```bash
docker-compose run --rm certbot renew
docker-compose exec nginx nginx -s reload
```

### Вариант 2: Самоподписанные сертификаты (для разработки)

```bash
# Генерация самоподписанного сертификата
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ssl/selfsigned.key \
  -out ssl/selfsigned.crt \
  -subj "/CN=localhost"
```

Использование:

```nginx
server {
    listen 443 ssl;
    server_name localhost;

    ssl_certificate /etc/nginx/ssl/selfsigned.crt;
    ssl_certificate_key /etc/nginx/ssl/selfsigned.key;

    location / {
        proxy_pass http://host.docker.internal:3000;
    }
}
```

## Доступ к localhost хоста

Для проксирования к сервисам на хосте используйте:

- **Linux:** `http://172.17.0.1:PORT` (IP docker bridge)
- **Docker Desktop (Mac/Windows):** `http://host.docker.internal:PORT`

Альтернативно, добавьте в `docker-compose.yml`:

```yaml
services:
  nginx:
    extra_hosts:
      - "host.docker.internal:host-gateway"
```

## Полезные команды

```bash
# Запуск
docker-compose up -d

# Остановка
docker-compose down

# Перезагрузка nginx (после изменения конфигов)
docker-compose exec nginx nginx -s reload

# Проверка синтаксиса конфигов
docker-compose exec nginx nginx -t

# Просмотр логов
docker-compose logs -f nginx

# Просмотр логов certbot
docker-compose logs -f certbot
```

## Примеры конфигураций

### Простой HTTP proxy

```nginx
server {
    listen 80;
    server_name api.example.com;

    location / {
        proxy_pass http://host.docker.internal:8080;
    }
}
```

### WebSocket поддержка

```nginx
server {
    listen 80;
    server_name ws.example.com;

    location / {
        proxy_pass http://host.docker.internal:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

### Несколько бэкэндов (по путям)

```nginx
server {
    listen 80;
    server_name app.example.com;

    location /api/ {
        proxy_pass http://host.docker.internal:8080/;
    }

    location /frontend/ {
        proxy_pass http://host.docker.internal:3000/;
    }
}
```

### HTTP -> HTTPS редирект с SSL

```nginx
server {
    listen 80;
    server_name secure.example.com;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name secure.example.com;

    ssl_certificate /etc/letsencrypt/live/secure.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/secure.example.com/privkey.pem;

    location / {
        proxy_pass http://host.docker.internal:5000;
    }
}
```

## Troubleshooting

### Проблема: nginx не видит сервис на localhost хоста

**Решение:** Используйте `host.docker.internal` или `172.17.0.1` вместо `localhost`.

### Проблема: Ошибка "502 Bad Gateway"

**Причины:**
- Бэкэнд не запущен
- Неверный порт
- Проблемы с сетью docker

**Проверка:**
```bash
# Из контейнера nginx
docker-compose exec nginx wget -O- http://host.docker.internal:PORT
```

### Проблема: SSL сертификат не обновляется

**Решение:**
```bash
# Проверка логов certbot
docker-compose logs certbot

# Ручное обновление
docker-compose run --rm certbot renew --dry-run
```

