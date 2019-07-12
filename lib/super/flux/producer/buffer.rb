# frozen_string_literal: true

module Super
  module Flux
    class Producer
      class Buffer
        def initialize(producer, max_size: 1)
          @producer = producer
          @max_size = max_size
          @lock = Mutex.new
        end

        def push(message, options = {})
          @lock.synchronize do
            @producer.produce(message, options)
            return if @producer.buffer_size < @max_size

            @producer.deliver_messages
          end
        end

        def flush
          @lock.synchronize { @producer.deliver_messages }
        end
      end
    end
  end
end
