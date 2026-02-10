#!/bin/bash
set -e

rm -f /rails/tmp/pids/server.pid

bundle check || bundle install

if [ "$RAILS_ENV" = "development" ] || [ "$RAILS_ENV" = "test" ]; then
  bundle exec rails db:prepare 2>/dev/null || bundle exec rails db:create db:migrate
fi

exec "$@"
