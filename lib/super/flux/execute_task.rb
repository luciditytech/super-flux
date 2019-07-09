# frozen_string_literal: true

module Super
  module Flux
    class ExecuteTask
      include Super::Service
      include LoggerResolver

      def call(task, message, consumer)
        task.call(message.value)
        consumer.mark_message_as_processed(message)
        true
      rescue StandardError => e
        logger.error(e.message)
        false
      end
    end
  end
end
