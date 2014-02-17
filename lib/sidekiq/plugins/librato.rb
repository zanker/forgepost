module Sidekiq
  module Plugins
    class Librato
      def initialize(options={})
      end

      def call(worker_instance, msg, queue)
        start = Time.now.to_f
        yield

        Sidekiq.logger.info "#{msg["class"]} JID-#{msg["jid"]}, took #{(Time.now.to_f - start).round(4)}"

        StatTracker.batch.increment("sidekiq.processed/#{msg["class"].gsub("::", "-")}")
        StatTracker.flush
      end
    end
  end
end