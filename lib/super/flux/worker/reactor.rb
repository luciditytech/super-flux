# frozen_string_literal: true

module Super
  module Flux
    class Worker
      class Reactor
        extend Forwardable
        include Super::Struct

        attribute :logger
        attribute :topic
        attribute :consumer
        attribute :processor
        attribute :options
        attribute :state

        CONSUMPTION_OPTIONS = {
          automatically_mark_as_processed: false
        }.freeze

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

          consumer.each_message(**CONSUMPTION_OPTIONS) do |message|
            raise unless process(message)
          end
        rescue Kafka::ProcessingError => e
          NewRelic::Agent.notice_error(e)

          reset_consumer(e.topic, e.partition, e.offset)
          return stop unless alive?

          retry
        rescue Exception => e
          NewRelic::Agent.notice_error(e)

          raise
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
