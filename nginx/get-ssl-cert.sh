#!/bin/bash

# Скрипт для получения SSL сертификата Let's Encrypt

if [ $# -lt 2 ]; then
    echo "Использование: ./get-ssl-cert.sh <domain> <email> [additional-domains...]"
    echo "Пример: ./get-ssl-cert.sh example.com admin@example.com www.example.com"
    exit 1
fi

DOMAIN=$1
EMAIL=$2
shift 2
ADDITIONAL_DOMAINS=$@

# Формируем команду с дополнительными доменами
DOMAINS_CMD="-d $DOMAIN"
for ADDITIONAL in $ADDITIONAL_DOMAINS; do
    DOMAINS_CMD="$DOMAINS_CMD -d $ADDITIONAL"
done

echo "Получение SSL сертификата для: $DOMAIN"
echo "Дополнительные домены: $ADDITIONAL_DOMAINS"
echo "Email: $EMAIL"
echo ""

# Запрос сертификата
docker-compose run --rm certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  $DOMAINS_CMD \
  --email $EMAIL \
  --agree-tos \
  --no-eff-email

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Сертификат успешно получен!"
    echo ""
    echo "Используйте в конфиге nginx:"
    echo "  ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;"
    echo "  ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;"
    echo ""
    echo "Не забудьте перезагрузить nginx:"
    echo "  docker-compose exec nginx nginx -s reload"
else
    echo ""
    echo "✗ Ошибка при получении сертификата"
    exit 1
fi

