FROM ruby:2.7.5

# By default image is built using RAILS_ENV=production.
# You may want to customize it:
#
#   --build-arg RAILS_ENV=development
#
# See https://docs.docker.com/engine/reference/commandline/build/#set-build-time-variables-build-arg
#
ARG RAILS_ENV=production
ENV RAILS_ENV=${RAILS_ENV} APP_HOME=/home/app

# Allow customization of user ID and group ID (it's useful when you use Docker bind mounts)
ARG UID=1000
ARG GID=1000

# Set the TZ variable to avoid perpetual system calls to stat(/etc/localtime)
ENV TZ=UTC

# Create group "app" and user "app".
RUN groupadd -r --gid ${GID} app \
  && useradd --system --create-home --home ${APP_HOME} --shell /sbin/nologin --no-log-init \
  --gid ${GID} --uid ${UID} app

# Install system dependencies.
RUN apt-get update && apt-get upgrade -y

WORKDIR $APP_HOME

# Install dependencies defined in Gemfile.
COPY --chown=app:app Gemfile Gemfile.lock .ruby-version $APP_HOME/
RUN mkdir -p /opt/vendor/bundle \
  && gem install bundler:2.2.33 \
  && chown -R app:app /opt/vendor $APP_HOME \
  && su app -s /bin/bash -c "bundle install --jobs $(nproc) --path /opt/vendor/bundle"

# Copy application sources.
COPY --chown=app:app . $APP_HOME

# Switch to application user.
USER app

# Initialize application configuration & assets.
RUN chmod +x ./bin/logger \
  && bundle exec rake tmp:create

# Expose port 3000 to the Docker host, so we can access it from the outside.
EXPOSE 3000

# The main command to run when the container starts.
CMD ["bundle", "exec", "puma", "--config", "config/puma.rb"]
