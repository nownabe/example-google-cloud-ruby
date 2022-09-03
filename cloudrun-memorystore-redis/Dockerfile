FROM ruby:3.1.2-slim-bullseye

RUN bundle config --global frozen 1

WORKDIR /app

COPY Gemfile Gemfile.lock /app/

RUN bundle install

COPY . /app/

CMD ["bundle", "exec", "ruby", "main.rb"]
