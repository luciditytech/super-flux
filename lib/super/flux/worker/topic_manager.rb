# frozen_string_literal: true

module Super
  module Flux
    class Worker
      class TopicManager
        extend Forwardable

        def initialize(task, stages: nil)
          @task = task
          @active_stages = stages || (0..@task.settings.retries)
          raise Errors::StageRangeInvalid unless valid_stage_range?
        end

        def stage_for(topic)
          topics.index(topic)
        end

        def next_topic_for(topic)
          topics[stage_for(topic) + 1]
        end

        def active_topics
          topics[@active_stages]
        end

        private

        def_delegators :task, :topics

        def valid_stage_range?
          task_stages.cover?(@active_stages)
        end

        def task_stages
          (0..(@settings.retries + 1))
        end
      end
    end
  end
end
