# frozen_string_literal: true

module Super
  module Flux
    class WorkerFactory
      include Super::Service

      def call(params = {})
        @params = params

        setup_processor
        setup_consumer_map

        result
      end

      private

      def task
        @params[:task]
      end

      def stages
        @params[:stages] || (0..task.settings.retries)
      end

      def setup_processor
        @processor = Worker::Processor.new(
          task: task,
          adapter: @params[:adapter],
          logger: @params[:logger]
        )
      end

      def setup_consumer_map
        @consumer_map = {}

        stages.each do |stage|
          @consumer_map[task.topics[stage]] = consumer_for(stage)
        end
      end

      def consumer_for(stage)
        @params[:adapter].consumer(
          group_id: [task.settings.group_id, stage].join('-'),
          offset_commit_interval: task.settings.offset_commit_interval || 5,
          offset_commit_threshold: task.settings.offset_commit_threshold || 10_000
        )
      end

      def result
        Worker.new(
          logger: @params[:logger],
          consumer_map: @consumer_map,
          processor: @processor
        )
      end
    end
  end
end
