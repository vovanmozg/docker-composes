FROM nginx:alpine

# Устанавливаем certbot для SSL сертификатов
RUN apk add --no-cache certbot certbot-nginx

# Копируем базовый конфиг nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Создаем директорию для конфигов бэкэндов
RUN mkdir -p /etc/nginx/conf.d

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]

