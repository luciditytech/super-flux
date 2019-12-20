# frozen_string_literal: true

module Super
  module Flux
    class Worker
      class ResourceMapFactory
        include Super::Service

        def call(stages:, task:)
          @task = task
          map = {}

          stages.each do |stage|
            map[task.topics[stage]] = {
              consumer: consumer_for(stage)
            }
          end

          map
        end

        private

        def consumer_for(stage)
          Super::Flux.pool.with do |adapter|
            adapter.consumer(
              group_id: group_id_for(stage),
              offset_commit_interval: @task.settings.offset_commit_interval || 5,
              offset_commit_threshold: @task.settings.offset_commit_threshold || 10_000
            )
          end
        end

        def group_id_for(stage)
          base_group_id = @task.settings.group_id
          return base_group_id if stage.zero?

          [base_group_id, stage].join('-')
        end
      end
    end
  end
end
