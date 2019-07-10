# frozen_string_literal: true

module Super
  module Flux
    class RetryTask
      include Super::Service
      include LoggerResolver
      include AdapterResolver

      def call(message, consumer, next_topic)
        adapter.deliver_message(message.value, topic: next_topic)
        consumer.mark_message_as_processed(message)
        true
      rescue StandardError => e
        logger.error(e.message)
        false
      end
    end
  end
end
