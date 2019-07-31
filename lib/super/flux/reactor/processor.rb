# frozen_string_literal: true

module Super
  module Flux
    class Reactor
      class Processor
        extend Forwardable
        include Super::Struct

        attribute :task
        attribute :logger
        attribute :consumer
        attribute :adapter
        attribute :topic_manager

        def call(message)
          throttle(message)
          return true if execute(message)

          prepare_retry(message)
        end

        private

        def_delegators :topic_manager, :stage_for, :next_topic_for

        def throttle(message)
          raise if Governor.call(message, stage_for(message.topic))
        end

        def execute(message)
          logger.debug(message.value)
          task.call(message.value)
          checkpoint(message)
          true
        rescue StandardError => e
          logger.error(e.full_message)
          false
        end

        def prepare_retry(message)
          adapter.deliver_message(message.value, topic: next_topic_for(message.topic))
          checkpoint(message)
          true
        rescue StandardError => e
          logger.error(e.full_message)
          false
        end

        def checkpoint(message)
          return unless message

          consumer.mark_message_as_processed(message)
        end
      end
    end
  end
end
