FROM nginx:alpine

RUN apk add --no-cache certbot certbot-nginx openssl

COPY nginx.conf /etc/nginx/nginx.conf

# Copy default server config to separate location (not in conf.d)
COPY default.conf /etc/nginx/default.conf

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80 443

CMD ["/start.sh"]

