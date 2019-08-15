# frozen_string_literal: true

module Super
  module Flux
    class Reactor
      class TopicManager
        def initialize(settings, stages: nil)
          @settings = settings
          @active_stages = stages || (0..settings.retries)
          raise Errors::StageRangeInvalid unless valid_stage_range?

          setup_topics
        end

        def stage_for(topic)
          @topics.index(topic)
        end

        def next_topic_for(topic)
          @topics[stage_for(topic) + 1]
        end

        def active_topics
          @topics[@active_stages]
        end

        private

        def valid_stage_range?
          task_stages.cover?(@active_stages)
        end

        def task_stages
          (0..(@settings.retries + 1))
        end

        def setup_topics
          @topics = task_stages.map { |stage| TopicNameFactory.call(@settings, stage) }
        end
      end
    end
  end
end
