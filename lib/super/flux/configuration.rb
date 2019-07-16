# frozen_string_literal: true

module Super
  module Flux
    class Configuration < OpenStruct
      DEFAULT_PRODUCER_OPTIONS = {
        max_buffer_size: 1000
      }.freeze

      def logger
        self[:logger] || self.logger = Logger.new(STDOUT)
      end

      def adapter
        self[:adapter] || setup_adapter
      end

      def producer
        self[:producer] || setup_producer
      end

      def producer_options
        self[:producer_options] || DEFAULT_PRODUCER_OPTIONS
      end

      def environment
        self[:environment] ||= ENV.fetch('RUBY_ENV', 'development')
      end

      private

      def setup_adapter
        return unless kafka.is_a?(Hash)

        adapter_options = kafka.reject { |k, _| k == :brokers }
        self.adapter = Kafka.new(kafka[:brokers], adapter_options)
      end

      def setup_producer
        return unless adapter

        self.producer = adapter.producer(producer_options || {})
      end
    end
  end
end
