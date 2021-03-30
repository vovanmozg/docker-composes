FROM richarvey/nginx-php-fpm
LABEL maintainer="Vladimir Polukhin <vovanmozg@gmail.com>"

# https://github.com/againstxcurrent/msmtp/blob/master/Dockerfile
# https://gitlab.com/vovanmozg/nginx-php-fpm/blob/master/Dockerfile


RUN set -x \
    && apk add --no-cache --virtual .build-deps curl gcc musl-dev make \
    && cd /tmp \
    && curl -sSL -o msmtp.tar https://marlam.de/msmtp/releases/msmtp-1.8.4.tar.xz \
    && tar -xvf msmtp.tar \
    && cd msmtp-1.8.4 \
    && ./configure --prefix=/usr/local/msmtp \
    && make \
    && make install \
    && rm -rf /tmp/msmtp-1.8.4 msmtp.tar \
    && touch /var/log/msmtp.log \
    && chmod 777 /var/log/msmtp.log \
    && apk del .build-deps


