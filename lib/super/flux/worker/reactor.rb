# frozen_string_literal: true

module Super
  module Flux
    class Worker
      class Reactor
        extend Forwardable
        include Super::Struct

        attribute :logger
        attribute :topic
        attribute :task
        attribute :consumer
        attribute :options
        attribute :state

        def initialize(**args)
          super(args)
          self.state = :offline
          self.options ||= {}
          @loops = 0
        end

        def start
          self.state = :online
          consumer.subscribe(topic)
          run while alive?
        end

        def stop
          self.state = :offline
          consumer.stop
        end

        private

        def_delegator :processor, :call, :process

        def alive?
          return false if options[:run_once] && @loops.positive?

          state == :online
        end

        def run
          return unless alive?

          @loops += 1
          consumer.each_batch { |batch| process(batch) }
        rescue Kafka::ProcessingError => e
          reset_consumer(e.topic, e.partition, e.offset)
          return stop unless alive?

          retry
        end

        def process(batch)
          work = []

          batch.messages.each do |message|
            work << Thread.new { Processor.call(task, message) }
            next if work.size <= 10

            work.map(&:join)
            work = []
          end

          work.map(&:join)
          consumer.commit_offsets
        end

        def reset_consumer(topic, partition, offset)
          logger.info("Throttled - #{topic} #{partition} #{offset}")
          consumer.pause(topic, partition, timeout: 10)
          consumer.seek(topic, partition, offset)
        end
      end
    end
  end
end
