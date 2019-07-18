# frozen_string_literal: true

module Super
  module Flux
    module Producer
      class Flusher
        TASK_OPTIONS = {
          execution_interval: 1,
          timeout_interval: 1
        }.freeze

        def initialize(buffer)
          @buffer = buffer

          @task = Concurrent::TimerTask.new(TASK_OPTIONS) do |_task|
            flush
          end
        end

        def start
          @task.execute
        end

        def stop
          @task.shutdown
        end

        def flush
          @buffer.flush
        end
      end
    end
  end
end
