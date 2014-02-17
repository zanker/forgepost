# Pulled from http://rxr.whitequark.org/jruby/source/src/jruby/kernel19/gc.rb
if RUBY_PLATFORM == "java"
  module GC
    module Profiler
      def self.enabled?
        !!@gc_beans
      end

      def self.enable
        @gc_beans ||= java.lang.management.ManagementFactory.garbage_collector_mx_beans
        clear
      end

      def self.disable
        @gc_beans = nil
      end

      def self.clear
        return unless @gc_beans

        time = 0
        @gc_beans.each do |bean|
          time += bean.collection_time
        end

        @start_time = time
      end

      def self.result
        nil
      end

      def self.report
        nil
      end

      def self.total_time
        time = 0
        @gc_beans.each do |bean|
          time += bean.collection_time
        end

        (time - @start_time) / 1000.0
      end

      def self.total_time_and_reset
        time = 0
        @gc_beans.each do |bean|
          time += bean.collection_time
        end

        total = (time - @start_time) / 1000.0
        @start_time = time

        total
      end
    end
  end
end