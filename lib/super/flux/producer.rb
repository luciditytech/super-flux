# frozen_string_literal: true

require_relative 'producer/flusher'
require_relative 'producer/buffer'

module Super
  module Flux
    class Producer
      include Super::Component

      inst_writer :producer
      interface :configure, :boot, :produce, :deliver, :shutdown

      %i[max_buffer_size topic].each do |method|
        define_singleton_method(method) do |value|
          configuration.send("#{method}=", value)
        end
      end

      def self.configuration
        @configuration ||= OpenStruct.new
      end

      def initialize
        @lock = Mutex.new
        at_exit { shutdown }
      end

      def max_buffer_size
        @max_buffer_size ||= Super::Flux.configuration.producer_options[:max_buffer_size]
      end

      def configure(&block)
        block.call(self)
      end

      def produce(message, options = {})
        buffer.push(message, { topic: topic }.compact.merge(options))
      end

      def deliver
        buffer.flush
      end

      def shutdown
        buffer.flush
        producer.shutdown
      end

      private

      def configuration
        self.class.configuration
      end

      def topic
        self.class.configuration.topic
      end

      def buffer
        @buffer || bootstrap
      end

      def bootstrap
        @lock.synchronize do
          @buffer ||= Buffer.new(producer, max_size: max_buffer_size)
          @flusher ||= Flusher.new(@buffer)
          @buffer
        end
      end

      def producer
        @producer || Super::Flux.producer
      end
    end
  end
end
