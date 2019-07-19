# frozen_string_literal: true

require_relative 'producer/flusher'
require_relative 'producer/buffer'
require_relative 'producer/dsl'

module Super
  module Flux
    module Producer
      def self.included(base)
        base.include(Super::Component)
        base.include(DSL)
        base.extend(ClassMethods)
        base.include(InstanceMethods)

        base.class_eval do
          inst_writer :producer
          interface :configure, :boot, :produce, :deliver, :shutdown
        end
      end

      module ClassMethods
        def configuration
          @configuration ||= OpenStruct.new
        end
      end

      module InstanceMethods
        def initialize
          @lock = Mutex.new
          at_exit { shutdown } unless testing?
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
          flusher.stop
          producer.shutdown
        end

        private

        def configuration
          self.class.configuration
        end

        def topic
          configuration.topic
        end

        def max_buffer_size
          configuration.max_buffer_size ||=
            Super::Flux.configuration.producer_options[:max_buffer_size]
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

        def testing?
          Super::Flux.environment == 'test'
        end
      end
    end
  end
end
