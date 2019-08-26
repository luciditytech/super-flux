# frozen_string_literal: true

module Super
  module Flux
    class Worker
      class ResourceMapFactory
        include Super::Service

        def call(stages:, kafka: {}, task:)
          @task = task
          map = {}

          stages.each do |stage|
            adapter = Kafka.new(kafka)

            map[task.topics[stage]] = {
              adapter: adapter,
              consumer: consumer_for(adapter, stage)
            }
          end

          map
        end

        private

        def consumer_for(adapter, stage)
          adapter.consumer(
            group_id: [@task.settings.group_id, stage].join('-'),
            offset_commit_interval: @task.settings.offset_commit_interval || 5,
            offset_commit_threshold: @task.settings.offset_commit_threshold || 10_000
          )
        end
      end
    end
  end
end
