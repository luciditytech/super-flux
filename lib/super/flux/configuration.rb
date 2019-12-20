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

      def pool
        self[:pool] || setup_pool
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

      def setup_pool
        return unless kafka.is_a?(Hash)

        self.pool = Super::ResourcePool.new(size: 8) do
          Kafka.new(**{ seed_brokers: kafka[:brokers] }.merge(kafka))
        end
      end

      def setup_adapter
        return unless kafka.is_a?(Hash)

        self.adapter = Kafka.new(**{ seed_brokers: kafka[:brokers] }.merge(kafka))
      end

      def setup_producer
        return unless adapter

        self.producer = adapter.producer(producer_options || {})
      end
    end
  end
end
