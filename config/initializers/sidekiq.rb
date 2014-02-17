redis_url = YAML::load_file(Rails.root.join("config", "redis.yml"))[Rails.env]

if RUBY_PLATFORM == "java"
  Sidekiq.configure_server do |config|
    config.poll_interval = 10

    config.redis = {:url => redis_url}

    config.server_middleware do |chain|
      chain.add Sidekiq::Plugins::Librato
      chain.remove Sidekiq::Middleware::Server::RetryJobs

      if Rails.env.production?
        chain.remove Sidekiq::Middleware::Server::Logging
        chain.remove Sidekiq::Middleware::Server::ActiveRecord
      end
    end
  end

  Redis.current = Sidekiq::RedisConnection.create(:size => 20, :url => redis_url)
else
  # Make sure server is always the same
  Sidekiq.configure_server do |config|
    config.redis = {:url => redis_url}
  end

  Redis.current = Sidekiq::RedisConnection.create(:size => 1, :url => redis_url)
end

Sidekiq.configure_client do |config|
  config.redis = {:url => redis_url}
end