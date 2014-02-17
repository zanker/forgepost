if defined?(Sidekiq::CLI)
  require "./lib/stat_tracker.rb"
  require "./lib/monkeypatches/jruby_gc.rb"
  GC::Profiler.enable

  Sidekiq.logger.info "Loaded rufus scheduler"

  scheduler = Rufus::Scheduler.start_new

  scheduler.every "3h" do
    SyncStoreProducts.perform_async
  end

  scheduler.in "15s" do
    SyncStoreProducts.perform_async
  end
end