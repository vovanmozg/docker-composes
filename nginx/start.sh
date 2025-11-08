#!/bin/sh
set -e

echo "=== Nginx + Certbot Auto SSL Setup ==="

# Функция для создания временного сертификата
create_dummy_cert() {
    domain=$1
    cert_path="/etc/letsencrypt/live/$domain"
    
    if [ ! -f "$cert_path/fullchain.pem" ]; then
        echo "📝 Creating temporary certificate for $domain..."
        mkdir -p "$cert_path"
        openssl req -x509 -nodes -days 1 -newkey rsa:2048 \
            -keyout "$cert_path/privkey.pem" \
            -out "$cert_path/fullchain.pem" \
            -subj "/CN=$domain/O=Temporary"
        echo "✓ Temporary certificate created for $domain"
    else
        echo "✓ Certificate already exists for $domain"
    fi
}

# Сканируем конфиги и создаем временные сертификаты
echo ""
echo "🔍 Scanning nginx configs for SSL domains..."
for conf in /etc/nginx/conf.d/*.conf; do
    if [ -f "$conf" ]; then
        domains=$(grep -oP 'ssl_certificate\s+/etc/letsencrypt/live/\K[^/]+' "$conf" 2>/dev/null | sort -u || true)
        for domain in $domains; do
            if [ -n "$domain" ]; then
                create_dummy_cert "$domain"
            fi
        done
    fi
done

# Тестируем конфигурацию nginx
echo ""
echo "🔧 Testing nginx configuration..."
if nginx -t 2>&1; then
    echo "✓ Nginx configuration is valid"
else
    echo "✗ Nginx configuration test failed!"
    exit 1
fi

# Запускаем nginx
echo ""
echo "🚀 Starting nginx..."
nginx

# Функция для получения настоящих сертификатов
obtain_real_certs() {
    sleep 5  # Даем nginx время запуститься
    
    echo ""
    echo "🔐 Checking for real SSL certificates..."
    
    if [ -z "$CERT_EMAIL" ]; then
        echo "⚠️  CERT_EMAIL not set - skipping Let's Encrypt certificate requests"
        echo "   Set CERT_EMAIL environment variable to enable automatic SSL"
        return
    fi
    
    for conf in /etc/nginx/conf.d/*.conf; do
        if [ -f "$conf" ]; then
            domains=$(grep -oP 'ssl_certificate\s+/etc/letsencrypt/live/\K[^/]+' "$conf" 2>/dev/null | sort -u || true)
            for domain in $domains; do
                if [ -z "$domain" ]; then
                    continue
                fi
                
                cert_path="/etc/letsencrypt/live/$domain/fullchain.pem"
                
                # Проверяем, это временный сертификат или настоящий
                if [ -f "$cert_path" ]; then
                    issuer=$(openssl x509 -in "$cert_path" -noout -issuer 2>/dev/null || echo "")
                    
                    # Если это не Let's Encrypt сертификат, получаем настоящий
                    if ! echo "$issuer" | grep -q "Let's Encrypt"; then
                        echo ""
                        echo "📋 Requesting Let's Encrypt certificate for $domain..."
                        
                        if certbot certonly --webroot \
                            --webroot-path=/var/www/certbot \
                            -d "$domain" \
                            --email "$CERT_EMAIL" \
                            --agree-tos \
                            --non-interactive \
                            --keep-until-expiring 2>&1 | grep -v "Hook command"; then
                            echo "✓ Certificate obtained for $domain"
                        else
                            echo "⚠️  Failed to obtain certificate for $domain"
                            echo "   Make sure:"
                            echo "   - Domain $domain points to this server"
                            echo "   - Port 80 is accessible from the internet"
                        fi
                    else
                        echo "✓ Valid Let's Encrypt certificate found for $domain"
                    fi
                fi
            done
        fi
    done
    
    echo ""
    echo "🔄 Reloading nginx with updated certificates..."
    if nginx -s reload 2>&1; then
        echo "✓ Nginx reloaded successfully"
    else
        echo "⚠️  Nginx reload failed"
    fi
}

# Получаем настоящие сертификаты в фоне
obtain_real_certs &

# Автообновление сертификатов каждые 12 часов
echo ""
echo "⏰ Certificate auto-renewal enabled (every 12 hours)"
while :; do
    sleep 12h & wait $!
    echo ""
    echo "🔄 Running certificate renewal check..."
    if certbot renew --quiet 2>&1; then
        echo "✓ Certificate renewal check completed"
        nginx -s reload
    else
        echo "⚠️  Certificate renewal check failed"
    fi
done &

# Главный процесс - nginx в foreground режиме
echo ""
echo "✅ Setup complete! Nginx is running."
echo ""
nginx -g "daemon off;"

