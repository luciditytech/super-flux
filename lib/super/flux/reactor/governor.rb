# frozen_string_literal: true

module Super
  module Flux
    class Reactor
      class Governor
        include Super::Service

        def call(message, stage)
          @message = message
          @stage = stage
          return false if @stage.zero?

          early?
        end

        private

        # The minimum amount of time retries at this stage should wait.
        def lead_time
          @lead_time ||= @stage**4 + 15 + (rand(30) * (@stage + 1))
        end

        # Time that has already passed since the message was first created.
        def elapsed_time
          @elapsed_time ||= (Time.now.utc - @message.create_time).to_i
        end

        # The minimum remaining time the consumer should wait before processing
        # more messages from this topic and partition.
        def timeout
          @timeout ||= (lead_time - elapsed_time).to_i
        end

        def early?
          timeout.positive?
        end
      end
    end
  end
end
