# frozen_string_literal: true

module Super
  module Flux
    class Worker
      class Processor
        include Super::Struct

        attribute :logger
        attribute :task
        attribute :adapter
        attribute :consumer

        def call(message)
          throttle(message)
          return true if execute(message)

          prepare_retry(message)
        end

        private

        def throttle(message)
          raise if Governor.call(
            message,
            stage_for(message.topic),
            wait: task.settings.wait
          )
        end

        def execute(message)
          instrument { task.call(message.value) }
          consumer.mark_message_as_processed(message)
          true
        rescue StandardError => e
          logger.error(e.full_message)
          false
        end

        def prepare_retry(message)
          adapter.deliver_message(message.value, topic: next_topic_for(message.topic))
          consumer.mark_message_as_processed(message)
          true
        rescue StandardError => e
          logger.error(e.full_message)
          false
        end

        def stage_for(topic)
          task.topics.index(topic)
        end

        def next_topic_for(topic)
          task.topics[stage_for(topic) + 1]
        end

        def instrument
          yield
        rescue Exception => e
          NewRelic::Agent.notify_error(e)
          raise(e)
        end
      end
    end
  end
end
