# frozen_string_literal: true

module Super
  module Flux
    class Reactor
      class ExecuteTask
        include Super::Service
        include LoggerResolver
        include ConsumerResolver

        def call(task, message)
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
end
