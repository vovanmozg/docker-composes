# Nginx Reverse Proxy with Automatic SSL

Minimal nginx docker image with automatic SSL certificate management.

## 🚀 Quick Start

### 1. Set your email in `docker-compose.yml`

```yaml
environment:
  - CERT_EMAIL=your-email@example.com
```

### 2. Create nginx config

```bash
cp data/conf.d/example-auto-ssl.conf.disabled data/conf.d/your-domain.com.conf
```

Replace every `example.com` with `your-domain.com`.  
Set `proxy_pass` to your backend server.

### 3. Run!

```bash
docker-compose up -d
```

### 4. Verify

```bash
# Check logs
docker-compose logs -f nginx-ssl

# Check HTTPS
curl -I https://example.com
```

## 📋 Requirements for Let's Encrypt

To obtain a real certificate:

1. ✅ **Domain is configured:** A-record points to your server
2. ✅ **Port 80 is open:** Let's Encrypt validates via HTTP
3. ✅ **CERT_EMAIL is set:** In docker-compose.yml

## 🔄 Auto-renewal

Every 12 hours:

- Certificate expiration dates are checked
- If < 30 days until expiration → renewed
- Nginx automatically reloads inside the container

## 📝 Adding a New Domain

```bash
# 1. Create config
nano conf.d/newdomain.conf

# 2. Reload nginx
docker-compose exec nginx-ssl nginx -s reload

# Certificate will be obtained automatically!
```

## 🔍 Certificate Management

```bash
# List certificates
docker-compose exec nginx-ssl certbot certificates

# Certificate information
docker-compose exec nginx-ssl openssl x509 -in /etc/letsencrypt/live/example.com/fullchain.pem -noout -text
```

## 🎯 Key Features

✅ **Maximum simplicity** — create config, run, done  
✅ **Automation** — certificates are obtained and renewed automatically  
✅ **No downtime** — nginx always running  
✅ **Persistence** — all configs and data are stored in folders next to docker-compose.yml

### What happens when you run the container?

1. Container starts (~5 seconds)
2. Temporary certificates are created
3. Nginx is running (HTTPS is available!)
4. Real Let's Encrypt certificates are requested in the background
5. Nginx automatically reloads with new certificates

## 🚀 Production Ready

Ready for production use with automatic SSL certificate management!
