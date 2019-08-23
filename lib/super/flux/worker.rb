# frozen_string_literal: true

require_relative 'worker/reactor'
require_relative 'worker/governor'
require_relative 'worker/processor'
require_relative 'worker/resource_map_factory'
require_relative 'worker/reactor_factory'

module Super
  module Flux
    class Worker
      include Super::Struct

      attribute :task
      attribute :stages
      attribute :logger
      attribute :options

      def initialize(**args)
        super(args)
        self.options ||= {}

        Signal.trap('INT') { stop }
        Signal.trap('TERM') { stop }
      end

      def start
        logger.info('Starting Flux Processor!')
        @threads = reactors.map { |reactor| Thread.new { reactor.start } }
        @threads.map(&:join)
      end

      def stop
        @reactors.map(&:stop)
      end

      private

      def active_stages
        @active_stages ||= (stages || (0..task.settings.retries))
      end

      def resource_map
        @resource_map ||= ResourceMapFactory.call(
          stages: active_stages,
          task: task,
          kafka: options[:kafka]
        )
      end

      def reactors
        @reactors ||= resource_map.map do |topic, resource_options|
          ReactorFactory.call(
            task: task,
            adapter: resource_options[:adapter],
            logger: logger,
            topic: topic,
            consumer: resource_options[:consumer],
            options: options
          )
        end
      end
    end
  end
end
