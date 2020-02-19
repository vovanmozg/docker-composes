FROM ruby:2.7-alpine

WORKDIR /usr/src/app

#COPY ./src/Gemfile ./
#COPY ./src/Gemfile.lock ./
COPY ./src .
RUN bundle install

ENV BUNDLE=0

CMD ["./entrypoint.sh"]
