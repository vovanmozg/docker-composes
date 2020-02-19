FROM ruby:2.6-alpine

WORKDIR /usr/src/app

# For fix error "Gem::Ext::BuildError: ERROR: Failed to build gem native extension."
RUN apk add --no-cache build-base ruby ruby-dev

COPY ./src .
RUN gem install bundler
RUN bundle install

ENV BUNDLE=0

CMD ["./entrypoint.sh"]
