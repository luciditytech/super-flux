# frozen_string_literal: true

require_relative 'worker/reactor'
require_relative 'worker/governor'
require_relative 'worker/processor'

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
        setup_resource_map
        setup_reactors

        Signal.trap('INT') { stop }
        Signal.trap('TERM') { stop }
      end

      def start
        logger.info('Starting Flux Processor!')

        @workers = @reactors.map do |reactor|
          Thread.new { reactor.start }
        end

        @workers.map(&:join)
      end

      def stop
        @reactors.map(&:stop)
      end

      private

      def active_stages
        (stages || (0..task.settings.retries))
      end

      def setup_resource_map
        @resource_map = {}

        active_stages.each do |stage|
          adapter = Kafka.new(**options.fetch(:kafka, {}))
          @resource_map[task.topics[stage]] = [adapter, consumer_for(adapter, stage)]
        end
      end

      def setup_reactors
        @reactors = @resource_map.map do |topic, (adapter, consumer)|
          Reactor.new(
            logger: logger,
            topic: topic,
            consumer: consumer,
            processor: processor_for(adapter, consumer),
            options: options
          )
        end
      end

      def consumer_for(adapter, stage)
        adapter.consumer(
          group_id: [task.settings.group_id, stage].join('-'),
          offset_commit_interval: task.settings.offset_commit_interval || 5,
          offset_commit_threshold: task.settings.offset_commit_threshold || 10_000
        )
      end

      def processor_for(adapter, consumer)
        Processor.new(
          task: task,
          adapter: adapter,
          consumer: consumer,
          logger: logger
        )
      end
    end
  end
end
