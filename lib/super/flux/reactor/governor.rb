# frozen_string_literal: true

module Super
  module Flux
    class Reactor
      class Governor
        extend Forwardable
        include Super::Service
        include LoggerResolver
        include ConsumerResolver

        def call(message, stage)
          @message = message
          @stage = stage
          return false if @stage.zero?
          return true if paused?
          return false unless early?

          pause_and_rewind
        end

        private

        def_delegators :@message, :topic, :partition, :offset

        def lead_time
          # @lead_time ||= @stage**4 + 15 + (rand(30) * (@stage + 1))
          @lead_time ||= 5
        end

        def wait_time
          @wait_time ||= (lead_time - elapsed_time).to_i
        end

        def elapsed_time
          @elapsed_time ||= (Time.now.utc - @message.create_time).to_i
        end

        def early?
          wait_time > 0
        end

        def paused?
          consumer.paused?(topic, partition)
        end

        def pause_and_rewind
          logger.info("Early message #{topic} / #{partition} - waiting #{wait_time} seconds")
          consumer.seek(topic, partition, offset)
          consumer.pause(topic, partition, timeout: 1)
          true
        end
      end
    end
  end
end
