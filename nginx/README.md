# Nginx Reverse Proxy with automatic SSL generating

This is minimal nginx docker image with supporting ssl-sertificates.

## 🚀 Quick start

Put your email to `docker-compose.yml`:

```yaml
environment:
  - CERT_EMAIL=your-email@example.com
```

### 2. Create nginx config

```bash
copy data/conf.d/example-auto-ssl.conf.disabled data/conf.d/your-domain.com.conf
```

Change every example.com with your-domain.com.
Set proxy_pass to your backend server.

### 3. Run!

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
# Check logs
docker-compose logs -f nginx-ssl

# Check https
curl -I https://example.com
```

## 📋 Требования для Let's Encrypt

Чтобы получить настоящий сертификат:

1. ✅ **Домен настроен:** A-запись указывает на ваш сервер
2. ✅ **Порт 80 открыт:** Let's Encrypt проверяет через HTTP
3. ✅ **CERT_EMAIL указан:** В docker-compose.yml
4. ✅ **Location настроен:** `/.well-known/acme-challenge/` должен быть доступен

### Автообновление:

Каждые 12 часов:

- Проверяется срок действия сертификатов
- Если < 30 дней до истечения → обновляется
- Nginx автоматически перезагружается внутри контейнера

### Добавление нового домена

```bash
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

## 🎯 Преимущества решения

✅ **Максимальная простота** — создал конфиг, запустил, готово  
✅ **Автоматизация** — сертификаты получаются и обновляются сами  
✅ **Нет даунтайма** — nginx работает всегда  
✅ **Персистентность** — все конфиги и данные находятся в папах рядом с docker-compose.yml
