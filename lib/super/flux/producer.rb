# frozen_string_literal: true

require_relative 'producer/flusher'
require_relative 'producer/buffer'

module Super
  module Flux
    class Producer
      include Super::Component

      inst_writer :producer
      interface :configure, :boot, :produce, :deliver, :shutdown

      def initialize
        at_exit { shutdown }
      end

      def configure(&block)
        block.call(self)
        @buffer = Buffer.new(producer, max_size: 10000)
        @flusher = Flusher.new(@buffer)
      end

      def produce(message, options = {})
        @buffer.push(message, options)
      end

      def deliver
        @buffer.flush_all
      end

      def shutdown
        @buffer.flush_all
        producer.shutdown
      end

      private

      def producer
        @producer || Super::Flux.producer
      end
    end
  end
end
