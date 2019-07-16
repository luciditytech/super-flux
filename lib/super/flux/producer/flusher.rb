# frozen_string_literal: true

module Super
  module Flux
    module Producer
      class Flusher
        TASK_OPTIONS = {
          execution_interval: 1,
          run_now: true,
          timeout_interval: 1
        }.freeze

        def initialize(buffer)
          @buffer = buffer

          @task = Concurrent::TimerTask.new(TASK_OPTIONS) do |_task|
            flush
          end
        end

        def flush
          @buffer.flush
        end

        def stop
          @task.stop
        end
      end
    end
  end
end
