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
          message = [e.message, *e.backtrace].join("\n")
          logger.error(message)
          false
        end
      end
    end
  end
end
