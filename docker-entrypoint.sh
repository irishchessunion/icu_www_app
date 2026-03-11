#!/bin/bash
set -e

rm -f /rails/tmp/pids/server.pid

# Copy example config files if they don't exist
if [ ! -f /rails/config/secrets.yml ]; then
  echo "Copying example secrets.yml..."
  cp /rails/config/examples/secrets.yml /rails/config/secrets.yml
fi

if [ ! -f /rails/config/database.yml ]; then
  echo "Copying example database.yml..."
  cp /rails/config/examples/database-docker.yml /rails/config/database.yml
fi

bundle check || bundle install

if [ "$RAILS_ENV" = "development" ] || [ "$RAILS_ENV" = "test" ]; then
  bundle exec rails db:prepare 2>/dev/null || bundle exec rails db:create db:migrate
fi

exec "$@"
