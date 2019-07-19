# frozen_string_literal: true

module Super
  module Flux
    class Reactor
      class Governor
        extend Forwardable
        include Super::Service

        def call(message, stage)
          @message = message
          @stage = stage
          return false if @stage.zero?

          early?
        end

        private

        def lead_time
          @lead_time ||= @stage**4 + 15 + (rand(30) * (@stage + 1))
        end

        def timeout
          @timeout ||= (lead_time - elapsed_time).to_i
        end

        def elapsed_time
          @elapsed_time ||= (Time.now.utc - @message.create_time).to_i
        end

        def early?
          timeout.positive?
        end
      end
    end
  end
end
