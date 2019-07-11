# frozen_string_literal: true

require_relative 'producer/flusher'
require_relative 'producer/buffer'

module Super
  module Flux
    class Producer
      include Super::Component

      inst_writer :producer, :max_buffer_size
      interface :configure, :boot, :produce, :deliver, :shutdown

      def initialize
        at_exit { shutdown }
      end

      def max_buffer_size
        @max_buffer_size ||= Super::Flux.configuration.producer_options[:max_buffer_size]
      end

      def configure(&block)
        block.call(self)
        @buffer = Buffer.new(producer, max_buffer_size: max_buffer_size)
        @flusher = Flusher.new(@buffer)
      end

      def produce(message, options = {})
        @buffer.push(message, options)
      end

      def deliver
        @buffer.flush
      end

      def shutdown
        @buffer.flush
        producer.shutdown
      end

      private

      def producer
        @producer || Super::Flux.producer
      end
    end
  end
end
