# Nginx Reverse Proxy с автоматическим SSL

Минималистичная настройка nginx как reverse proxy с **автоматическим** получением и обновлением SSL сертификатов.

## 🎯 Главная фишка

**Создайте конфиг с HTTPS → Запустите контейнер → Всё работает!**

- ✅ Контейнер запускается сразу (даже без сертификатов)
- ✅ Временные сертификаты создаются автоматически
- ✅ Настоящие Let's Encrypt сертификаты получаются в фоне
- ✅ Автообновление каждые 12 часов

## 🚀 Быстрый старт

### 1. Настройте email для Let's Encrypt

Отредактируйте `docker-compose.yml`:

```yaml
environment:
  - CERT_EMAIL=your-email@example.com  # Замените на свой!
```

### 2. Создайте конфиг домена (сразу с HTTPS!)

```bash
cat > conf.d/myapp.conf << 'EOF'
server {
    listen 80;
    server_name example.com;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    location / {
        proxy_pass http://host.docker.internal:3000;
    }
}
EOF
```

### 3. Запустите!

```bash
docker-compose up -d
```

**Что произойдёт:**
1. ⏱️ Контейнер запускается (~5 сек)
2. 🔐 Создаются временные сертификаты
3. ✅ Nginx работает (HTTPS доступен!)
4. 📋 В фоне запрашиваются настоящие сертификаты Let's Encrypt
5. 🔄 Nginx автоматически перезагружается с новыми сертификатами

### 4. Проверка

```bash
# Посмотрите логи
docker-compose logs -f nginx-ssl

# Проверьте HTTPS
curl -I https://example.com
```

## 📋 Требования для Let's Encrypt

Чтобы получить настоящий сертификат:

1. ✅ **Домен настроен:** A-запись указывает на ваш сервер
2. ✅ **Порт 80 открыт:** Let's Encrypt проверяет через HTTP
3. ✅ **CERT_EMAIL указан:** В docker-compose.yml
4. ✅ **Location настроен:** `/.well-known/acme-challenge/` должен быть доступен

## 📦 Публикация образа в Docker Hub

### 1. Отредактируйте build-and-push.sh

```bash
nano build-and-push.sh
# Измените DOCKERHUB_USERNAME на свой
```

### 2. Соберите и опубликуйте

```bash
./build-and-push.sh
```

### 3. На production серверах

В `docker-compose.yml` замените:
```yaml
build: .
```

На:
```yaml
image: your-dockerhub-username/nginx-proxy:latest
```

## 🌍 Использование на новом сервере

Минималистичная структура:

```bash
mkdir -p my-proxy/conf.d
cd my-proxy

# 1. Создайте docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  nginx-ssl:
    image: your-username/nginx-proxy:latest
    container_name: nginx-ssl
    restart: unless-stopped
    ports:
      - '80:80'
      - '443:443'
    volumes:
      - ./conf.d:/etc/nginx/conf.d:ro
      - letsencrypt-certs:/etc/letsencrypt
      - certbot-webroot:/var/www/certbot
      - ssl-certs:/etc/nginx/ssl
    environment:
      - CERT_EMAIL=admin@example.com
    networks:
      - proxy-network

networks:
  proxy-network:
    name: proxy-network

volumes:
  letsencrypt-certs:
  certbot-webroot:
  ssl-certs:
EOF

# 2. Создайте конфиг домена
nano conf.d/myapp.conf

# 3. Запустите
docker-compose up -d
```

**Готово!** Сертификаты получатся автоматически.

## 🔐 Как работает автоматический SSL

### Процесс при первом запуске:

```
1. Контейнер стартует
   ↓
2. Скрипт сканирует conf.d/*.conf
   ↓
3. Находит домены из ssl_certificate директив
   ↓
4. Создаёт временные сертификаты для каждого домена
   ↓
5. Запускает nginx (HTTPS работает с временными сертификатами!)
   ↓
6. В фоне (через 5 сек):
   - Запрашивает настоящие Let's Encrypt сертификаты
   - Заменяет временные на настоящие
   - Перезагружает nginx
   ↓
7. HTTPS работает с настоящими сертификатами!
```

### Автообновление:

Каждые 12 часов:
- Проверяется срок действия сертификатов
- Если < 30 дней до истечения → обновляется
- Nginx автоматически перезагружается

## 🔧 Управление

### Просмотр логов

```bash
# Все логи
docker-compose logs -f nginx-ssl

# Фильтр по SSL
docker-compose logs nginx-ssl | grep -i certificate
```

### Ручное обновление сертификатов

```bash
docker-compose exec nginx-ssl certbot renew
docker-compose exec nginx-ssl nginx -s reload
```

### Добавление нового домена

```bash
# 1. Создайте конфиг с HTTPS
nano conf.d/newdomain.conf

# 2. Перезагрузите nginx
docker-compose exec nginx-ssl nginx -s reload

# Сертификат получится автоматически!
```

### Проверка сертификатов

```bash
# Список сертификатов
docker-compose exec nginx-ssl certbot certificates

# Информация о сертификате
docker-compose exec nginx-ssl openssl x509 -in /etc/letsencrypt/live/example.com/fullchain.pem -noout -text
```

## 💾 Docker Volumes

**Автоматически создаются:**
- `letsencrypt-certs` — SSL сертификаты Let's Encrypt
- `certbot-webroot` — webroot для ACME валидации
- `ssl-certs` — самоподписанные сертификаты (опционально)

**Монтируется только:** `conf.d/` с вашими конфигами

### Управление volumes

```bash
# Просмотр
docker volume ls | grep -E 'letsencrypt|certbot|ssl'

# Бэкап сертификатов
docker run --rm -v letsencrypt-certs:/data -v $(pwd):/backup ubuntu \
  tar czf /backup/certs-backup-$(date +%Y%m%d).tar.gz /data

# Восстановление
docker run --rm -v letsencrypt-certs:/data -v $(pwd):/backup ubuntu \
  tar xzf /backup/certs-backup-*.tar.gz -C /
```

## 📝 Примеры конфигураций

### Простой HTTPS proxy

```nginx
server {
    listen 80;
    server_name api.example.com;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name api.example.com;

    ssl_certificate /etc/letsencrypt/live/api.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.example.com/privkey.pem;

    location / {
        proxy_pass http://host.docker.internal:8080;
    }
}
```

### Несколько доменов

```nginx
server {
    listen 80;
    server_name app1.com app2.com;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name app1.com;

    ssl_certificate /etc/letsencrypt/live/app1.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/app1.com/privkey.pem;

    location / {
        proxy_pass http://host.docker.internal:3000;
    }
}

server {
    listen 443 ssl http2;
    server_name app2.com;

    ssl_certificate /etc/letsencrypt/live/app2.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/app2.com/privkey.pem;

    location / {
        proxy_pass http://host.docker.internal:4000;
    }
}
```

### WebSocket с HTTPS

```nginx
server {
    listen 443 ssl http2;
    server_name ws.example.com;

    ssl_certificate /etc/letsencrypt/live/ws.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/ws.example.com/privkey.pem;

    location / {
        proxy_pass http://host.docker.internal:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## 🐛 Troubleshooting

### Временный сертификат не заменяется на настоящий

**Проверьте логи:**
```bash
docker-compose logs nginx-ssl | grep -i certificate
```

**Возможные причины:**
- `CERT_EMAIL` не указан
- Домен не указывает на сервер
- Порт 80 недоступен извне
- Rate limit Let's Encrypt исчерпан

**Решение:**
```bash
# Проверьте доступность порта 80
curl http://example.com/.well-known/acme-challenge/test

# Проверьте DNS
dig example.com

# Попробуйте получить сертификат вручную
docker-compose exec nginx-ssl certbot certonly \
  --webroot -w /var/www/certbot \
  -d example.com \
  --email admin@example.com \
  --agree-tos \
  --dry-run
```

### Nginx не запускается

**Проверьте конфигурацию:**
```bash
docker-compose exec nginx-ssl nginx -t
```

**Просмотрите логи:**
```bash
docker-compose logs nginx-ssl
```

### Сертификат не обновляется автоматически

**Проверьте процессы:**
```bash
docker-compose exec nginx-ssl ps aux
```

Должны быть процессы `sleep 12h` и `nginx`.

**Проверьте обновление вручную:**
```bash
docker-compose exec nginx-ssl certbot renew --dry-run
```

## 📚 Структура проекта

```
tmp/nginx/
├── Dockerfile                              # Минималистичный образ
├── start.sh                                # Скрипт с авто-SSL логикой
├── docker-compose.yml                      # Конфигурация с CERT_EMAIL
├── nginx.conf                              # Базовая конфигурация
├── build-and-push.sh                       # Публикация в Docker Hub
├── get-ssl-cert.sh                         # Ручное получение сертификата
├── README.md                               # Документация
└── conf.d/                                 # Конфиги доменов
    ├── default.conf                        # Базовая конфигурация
    ├── example-backend.conf.disabled       # Пример без SSL
    └── example-auto-ssl.conf.disabled      # Пример с авто-SSL
```

## 🎯 Преимущества решения

✅ **Максимальная простота** — создал конфиг, запустил, готово  
✅ **Автоматизация** — сертификаты получаются и обновляются сами  
✅ **Нет даунтайма** — nginx работает всегда  
✅ **Один контейнер** — проще управлять  
✅ **Персистентность** — volumes сохраняют данные  
✅ **Production ready** — готово к реальному использованию  

**Готово к production! 🚀**
