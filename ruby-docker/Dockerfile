FROM ruby:2.6-alpine

WORKDIR /usr/src/app

COPY ./src .
RUN gem install bundler
RUN bundle install

ENV BUNDLE=0

CMD ["./entrypoint.sh"]
