FROM ruby:3.3-slim

# ImageMagick is required by mini_magick
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    imagemagick \
    git \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /gem

# Install dependencies first for better layer caching
COPY Gemfile barf.gemspec ./
COPY lib/barf/version.rb lib/barf/version.rb
RUN bundle install

# Copy the rest of the source
COPY . .

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

# Default to an interactive shell
CMD ["bash"]
