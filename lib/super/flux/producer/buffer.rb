# frozen_string_literal: true

module Super
  module Flux
    class Producer
      class Buffer
        def initialize(producer, max_size: 1)
          @producer = WeakRef.new(producer)
          @max_size = max_size
          @lock = Mutex.new
        end

        def push(message, options = {})
          synchronize do
            @producer.produce(message, options)
            return if size < @max_size

            flush
          end
        end

        def flush
          synchronize { @producer.deliver_messages }
        end

        def size
          @producer.buffer_size
        end

        private

        def synchronize(&block)
          @lock.lock unless @lock.owned?
          block.call
        ensure
          @lock.unlock if @lock.owned? && @lock.locked?
        end
      end
    end
  end
end
