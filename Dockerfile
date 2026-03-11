FROM ruby:3.2.0-bullseye

# Install base dependencies
RUN apt-get update -qq && \
  apt-get install --no-install-recommends -y \
  build-essential \
  default-libmysqlclient-dev \
  default-mysql-client \
  git \
  libvips \
  pkg-config \
  curl \
  nodejs \
  npm \
  imagemagick \
  wget \
  gnupg \
  unzip \
  chromium \
  chromium-driver \
  && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set up chromium for Selenium - create symlinks to standard paths
RUN ln -sf /usr/bin/chromium /usr/bin/google-chrome && \
  ln -sf /usr/bin/chromedriver /usr/bin/chromedriver || true

# Set environment variables for headless Chrome
ENV CHROME_BIN=/usr/bin/chromium \
  CHROMIUM_FLAGS="--no-sandbox --disable-dev-shm-usage"

WORKDIR /rails

ENV BUNDLE_PATH="/usr/local/bundle" \
  BUNDLE_JOBS=4

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

# RUN bundle exec rake assets:precompile

COPY docker-entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
