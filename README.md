## www.icu.ie

This is the source code for version 2 of the Irish Chess Union's web site, [www.icu.ie](http://www.icu.ie).

See the [wiki](https://github.com/sanichi/icu_www_app/wiki) for instructions on how to setup and maintain
the server and application software.

### Initial Setup

1. Copy the Docker database configuration:
   ```bash
   cp config/examples/database-docker.yml config/database.yml
   ```

2. Build the Docker images:
   ```bash
   docker-compose build
   ```

3. Create and setup the database:
   ```bash
   docker-compose run --rm web bundle exec rails db:create db:migrate db:seed
   ```

### Running the Application

Start all services (web server, MySQL, Redis):
```bash
docker-compose up
```

The application will be available at http://localhost:3000

To run in detached mode:
```bash
docker-compose up -d
```

To stop services:
```bash
docker-compose down
```

### Running Tests

Run the full test suite:
```bash
docker-compose run --rm test
```

Run specific tests:
```bash
docker-compose run --rm test bundle exec rspec spec/models/
docker-compose run --rm test bundle exec rspec spec/features/some_feature_spec.rb
```

### Useful Commands

Access Rails console:
```bash
docker-compose run --rm web bundle exec rails console
```

Run database migrations:
```bash
docker-compose run --rm web bundle exec rails db:migrate
```

Access bash inside the container:
```bash
docker-compose run --rm web bash
```

View logs:
```bash
docker-compose logs -f web
```

Rebuild after Gemfile changes:
```bash
docker-compose build web
```

### Volumes

The Docker setup uses named volumes to persist data:
- `mysql_data` - MySQL database files
- `redis_data` - Redis data
- `bundle_cache` - Bundled gems (speeds up rebuilds)

To reset the database completely:
```bash
docker-compose down -v
docker-compose up
```
