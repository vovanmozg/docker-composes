#!/bin/bash

# Скрипт для ручного получения SSL сертификата Let's Encrypt
# (обычно не нужен, так как сертификаты получаются автоматически)

if [ $# -lt 2 ]; then
    echo "Использование: ./get-ssl-cert.sh <domain> <email> [additional-domains...]"
    echo "Пример: ./get-ssl-cert.sh example.com admin@example.com www.example.com"
    echo ""
    echo "Примечание: При использовании CERT_EMAIL в docker-compose.yml"
    echo "            сертификаты получаются автоматически при запуске!"
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

# Определяем имя контейнера
CONTAINER=$(docker-compose ps -q nginx-ssl 2>/dev/null)
if [ -z "$CONTAINER" ]; then
    CONTAINER=$(docker-compose ps -q nginx 2>/dev/null)
fi

if [ -z "$CONTAINER" ]; then
    echo "✗ Контейнер nginx не запущен"
    echo "  Запустите: docker-compose up -d"
    exit 1
fi

# Запрос сертификата через nginx контейнер
docker-compose exec nginx-ssl certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  $DOMAINS_CMD \
  --email $EMAIL \
  --agree-tos \
  --non-interactive

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Сертификат успешно получен!"
    echo ""
    echo "Используйте в конфиге nginx:"
    echo "  ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;"
    echo "  ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;"
    echo ""
    echo "Перезагрузка nginx..."
    docker-compose exec nginx-ssl nginx -s reload
    echo "✓ Готово!"
else
    echo ""
    echo "✗ Ошибка при получении сертификата"
    exit 1
fi

