FROM litaio/ruby:2.3.0
RUN gem install bundler && mkdir /app
COPY ./* /app/
WORKDIR /app
RUN bundle install --path /var/bundle --without development test --jobs $(nproc) --clean
COPY start /start
COPY ./* /app/
WORKDIR /app
CMD ["/start"]
