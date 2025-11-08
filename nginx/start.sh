#!/bin/sh
set -e

echo "=== Nginx + Certbot Auto SSL Setup ==="

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

# Create dummy certificates for all SSL domains in nginx configs
echo ""
echo "🔍 Scanning nginx configs for SSL domains..."
for conf in /etc/nginx/conf.d/*.conf; do
    if [ -f "$conf" ]; then
        domains=$(grep 'ssl_certificate' "$conf" 2>/dev/null | sed -n 's|.*ssl_certificate.*/etc/letsencrypt/live/\([^/]*\)/.*|\1|p' | sort -u || true)
        for domain in $domains; do
            if [ -n "$domain" ]; then
                create_dummy_cert "$domain"
            fi
        done
    fi
done

# Create default self-signed certificate for unknown domains if not exists
if [ ! -f /etc/nginx/ssl/default.crt ]; then
    echo ""
    echo "📝 Creating default self-signed certificate..."
    mkdir -p /etc/nginx/ssl
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/default.key \
        -out /etc/nginx/ssl/default.crt \
        -subj "/CN=default/O=Nginx Default" > /dev/null 2>&1
    echo "✓ Default certificate created"
fi

echo ""
echo "🔧 Testing nginx configuration..."
if nginx -t 2>&1; then
    echo "✓ Nginx configuration is valid"
else
    echo "✗ Nginx configuration test failed!"
    exit 1
fi

obtain_real_certs() {
    sleep 5  # Time to wait for nginx to start
    
    echo ""
    echo "🔐 Checking for real SSL certificates..."
    
    if [ -z "$CERT_EMAIL" ]; then
        echo "⚠️  CERT_EMAIL not set - skipping Let's Encrypt certificate requests"
        echo "   Set CERT_EMAIL environment variable to enable automatic SSL"
        return
    fi
    
    for conf in /etc/nginx/conf.d/*.conf; do
        if [ -f "$conf" ]; then
            domains=$(grep 'ssl_certificate' "$conf" 2>/dev/null | sed -n 's|.*ssl_certificate.*/etc/letsencrypt/live/\([^/]*\)/.*|\1|p' | sort -u || true)
            for domain in $domains; do
                if [ -z "$domain" ]; then
                    continue
                fi
                
                cert_path="/etc/letsencrypt/live/$domain/fullchain.pem"
                
                if [ -f "$cert_path" ]; then
                    issuer=$(openssl x509 -in "$cert_path" -noout -issuer 2>/dev/null || echo "")
                    
                    if ! echo "$issuer" | grep -q "Let's Encrypt"; then
                        echo ""
                        echo "📋 Requesting Let's Encrypt certificate for $domain..."
                        
                        echo "   Removing temporary certificate..."
                        rm -rf "/etc/letsencrypt/live/$domain"
                        
                        if certbot certonly --webroot \
                            --webroot-path=/var/www/certbot \
                            -d "$domain" \
                            --email "$CERT_EMAIL" \
                            --agree-tos \
                            --non-interactive; then
                            echo "✓ Certificate obtained for $domain"
                        else
                            echo "⚠️  Failed to obtain certificate for $domain"
                            echo "   Possible reasons:"
                            echo "   - Invalid email address (use real email!)"
                            echo "   - Domain $domain doesn't point to this server"
                            echo "   - Port 80 is not accessible from the internet"
                            echo "   Check logs: docker compose exec nginx-ssl cat /var/log/letsencrypt/letsencrypt.log"
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

obtain_real_certs &

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

echo ""
echo "✅ Setup complete! Nginx is running."
echo ""
nginx -g "daemon off;"

