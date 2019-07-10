# frozen_string_literal: true

module Super
  module Flux
    class Governor
      include Super::Service
      include LoggerResolver
      include ConsumerResolver

      def call(message, stage)
        return if stage.zero?

        @message = message
        @stage = stage
        return unless early?

        wait
      end

      private

      def now
        Time.now.utc
      end

      def lead_time
        @lead_time ||= @stage**4 + 15 + (rand(30) * (@stage + 1))
      end

      def wait_time
        @wait_time ||= (lead_time - (now - @message.create_time)).to_i
      end

      def early?
        now - @message.create_time < lead_time
      end

      def wait
        logger.info("Early message - waiting #{wait_time} seconds")
        consumer.pause(@message.topic, @message.partition, timeout: wait_time)
      end
    end
  end
end
