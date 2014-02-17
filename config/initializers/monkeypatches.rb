class Base77
  BASE_10 = "0123456789"
  BASE_77 = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

  def self.encode(src)
    convert(src, BASE_10, BASE_77)
  end

  def self.decode(src)
    convert(src, BASE_77, BASE_10)
  end

  private
  def self.convert(src, srcAlphabet, dstAlphabet)
    srcBase = srcAlphabet.length
    dstBase = dstAlphabet.length

    wet, val, mlt = src, 0, 1

    while wet.length > 0 do
      digit  = wet[wet.length - 1]
      val += mlt * srcAlphabet.index(digit)
      wet = wet[0, wet.length - 1]
      mlt *= srcBase
    end

    wet, ret = val, ""

    while wet >= dstBase do
      digitVal = wet % dstBase
      digit = dstAlphabet[digitVal]
      ret = digit + ret
      wet /= dstBase
    end

    dstAlphabet[wet] + ret
  end
end

# Mongo Instrumentation originally contributed by Alexey Palazhchenko
DependencyDetection.defer do
  @name = :mongodb

  depends_on do
    defined?(::Mongo) and not NewRelic::Control.instance['disable_mongodb']
  end

  executes do
    NewRelic::Agent.logger.debug 'Installing mongo-ruby-driver instrumentation'
  end

  executes do
    ::Mongo::Logging.class_eval do
      include NewRelic::Agent::MethodTracer

      def instrument_with_newrelic_trace(name, payload = {}, &blk)
        payload = {} if payload.nil?
        collection = payload[:collection]
        if collection == '$cmd'
          f = payload[:selector].first
          name, collection = f if f
        end

        trace_execution_scoped("Database/#{collection}/#{name}") do
          t0 = Time.now
          res = instrument_without_newrelic_trace(name, payload, &blk)
          NewRelic::Agent.instance.transaction_sampler.notice_sql(payload.inspect, nil, (Time.now - t0).to_f)
          res
        end
      end

      alias_method :instrument_without_newrelic_trace, :instrument
      alias_method :instrument, :instrument_with_newrelic_trace
    end
    class Mongo::Collection; include Mongo::Logging end
    class Mongo::Connection; include Mongo::Logging end
    class Mongo::Cursor; include Mongo::Logging end

    # cursor refresh is not currently instrumented in mongo driver, so not picked up by above - have to add our own here
    ::Mongo::Cursor.class_eval do
      include NewRelic::Agent::MethodTracer

      def send_get_more_with_newrelic_trace
        trace_execution_scoped(["ActiveRecord/all", "ActiveRecord/find", "Database/#{collection.name}/refresh"]) do
          send_get_more_without_newrelic_trace
        end
      end
      alias_method :send_get_more_without_newrelic_trace, :send_get_more
      alias_method :send_get_more, :send_get_more_with_newrelic_trace
      add_method_tracer :close, 'Database/#{collection.name}/close'
    end
  end
end


module Sprockets
  class StaticCompiler
    def write_asset(asset)
      path_for(asset).tap do |path|
        filename = File.join(target, path)
        FileUtils.mkdir_p File.dirname(filename)
        asset.write_to(filename)
        asset.write_to("#{filename}.gz") if filename.to_s =~ /\.(css|js|eot|ttf|woff)$/
      end
    end
  end
end

module Sprockets
  module Helpers
    module RailsHelper
      class AssetPaths
        def digest_for(logical_path)
          if digest_assets && asset_digests && (digest = asset_digests[logical_path])
            #return Thread.current[:use_webp] && WEBP_ASSETS[digest] || digest
            return digest
          end

          if compile_assets
            if digest_assets && asset = asset_environment[logical_path]
              return asset.digest_path
            end
            return logical_path
          elsif logical_path =~ /^cards\//i
            path = logical_path.gsub(/[0-9]+/, "none")
            asset_digests[path] ? asset_digests[path] : path
          else
            raise AssetNotPrecompiledError.new("#{logical_path} isn't precompiled")
          end
        end
      end
    end
  end
end

class Redis
  def ext_set(key, value, options={})
    cmd = [:set, key, value.to_s]
    cmd.push("EX", options[:ex]) if options[:ex]
    cmd.push("PX", options[:px]) if options[:px]
    cmd.push("NX") if options[:nx]
    cmd.push("XX") if options[:xx]

    synchronize do |client|
      client.call(cmd)
    end
  end
end

module Plucky
  class Query
    def find_and_modify(options={})
      hash = self.options_hash
      hash.delete(:transformer)
      hash[:query] = self.criteria_hash

      retries = 0

      begin
        self.collection.find_and_modify(options.merge(hash))

      rescue Mongo::ConnectionFailure => ex
        if (retries += 1) <= 4
          Sidekiq.logger.info "Retry ##{retries} (#{ex.class}: #{ex.message})"
          sleep 0.25

          MongoMapper.database.connection.close
          MongoMapper.database.connection.reconnect
          retry
        end

        raise

      rescue Mongo::OperationFailure => ex
        if ex.message =~ /not master/
          if (retries += 1) <= 4
            Sidekiq.logger.info "Retry ##{retries} (#{ex.class}: #{ex.message})"
            sleep 0.25

            MongoMapper.database.connection.close
            MongoMapper.database.connection.connect
            retry
          end
        end

        raise
      end
    end
  end
end

module MongoMapper
  module Plugins
    module Modifiers
      module ClassMethods
        def raw_update(id, changes, options={})
          collection.update({:_id => id}, changes, options)
        end
      end

      def raw_update(changes, options={})
        collection.update({:_id => id}, changes, options)
      end
    end
  end
end

class BSON::ObjectId
  # This is the most efficient case insensitive storage of ObjectId at 19 chars
  def base36_encode
    to_s.to_i(18).to_s(36)
  end

  def self.base36_decode(str)
    str = str.to_s.to_i(36).to_s(18)
    self.legal?(str) ? self.from_string(str) : nil
  end

  # And if we don't care about case,
  def compress
    Base64.strict_encode64(self.data.pack("c*"))
  end

  def self.decompress(str)
    data = Base64.strict_decode64(str).unpack("c*")
    self.new(data)
  end
end

if defined?(Sidekiq::CLI)
  module Sidekiq
    class CLI
      alias_method :orig_run, :run

      def run(*args)
        trap("TTOU") do
          Sidekiq.logger.info "Received TTOU, no longer accepting new work"
          launcher.manager.async.stop
        end

        orig_run(*args)
      end
    end
  end
end

if defined?(Sidekiq::Launcher)
  module Sidekiq
    class Launcher
      alias_method :orig_stop, :stop

      def stop(*args)
        orig_stop(*args)

        StatTracker.flush
      end
    end
  end
end

if defined?(Sidekiq::Processor)
  module Sidekiq
    class Processor
      def stats(worker, msg, queue)
        yield
      end
    end
  end
end

# Silence the annoying asset log messages
Rails::Rack::Logger.class_eval do
  def call_with_quiet_assets(env)
    previous_level = Rails.logger.level
    if env['PATH_INFO'].index("/assets/") == 0 or env["PATH_INFO"].index("/ping") == 0
      Rails.logger.level = Logger::ERROR
    end

    call_without_quiet_assets(env).tap do
      Rails.logger.level = previous_level
    end
  end

  alias_method_chain :call, :quiet_assets
end