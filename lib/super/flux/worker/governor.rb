# frozen_string_literal: true

module Super
  module Flux
    class Worker
      class Governor
        include Super::Service

        def call(message, stage, wait: nil)
          @message = message
          @stage = stage
          @wait = wait
          return false if @stage.zero?

          early?
        end

        private

        # The minimum amount of time retries at this stage should wait.
        def wait_time
          return @wait_time if defined?(@wait_time)

          @wait_time = if @wait
                         @wait.is_a?(Proc) ? @wait.call(@stage) : @wait
                       else
                         @stage**4 + 15 + (rand(30) * (@stage + 1))
                       end
        end

        # Time that has already passed since the message was first created.
        def elapsed_time
          @elapsed_time ||= (Time.now.utc - @message.create_time).to_i
        end

        # The minimum remaining time the consumer should wait before processing
        # more messages from this topic and partition.
        def timeout
          @timeout ||= (wait_time - elapsed_time).to_i
        end

        def early?
          timeout.positive?
        end
      end
    end
  end
end
