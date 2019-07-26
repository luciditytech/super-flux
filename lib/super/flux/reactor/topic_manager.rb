# frozen_string_literal: true

module Super
  module Flux
    class Reactor
      class TopicManager
        def initialize(settings, stages: nil)
          default_stages = 0..settings.retries
          @stages = stages || default_stages
          valid = @stages.first >= default_stages.first && @stages.last <= default_stages.last
          raise Errors::StageRangeInvalid unless valid

          @topics = create_topics(settings)
        end

        def stage_for(topic)
          @topics.index(topic)
        end

        def next_topic_for(topic)
          @topics[stage_for(topic) + 1]
        end

        def active_topics
          @topics[@stages]
        end

        private

        def create_topics(settings)
          (0..(settings.retries + 1)).map do |stage|
            TopicNameFactory.call(settings, stage)
          end
        end
      end
    end
  end
end
